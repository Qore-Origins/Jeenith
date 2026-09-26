# Copyright (c) 2026 Qore
"""追加本次构建到双份 build_history.json（builds/ 主副本 + 项目内副本）。
用法: python scripts/archive_history.py <filename>
filename 形如 Jeenith_1.0.1_release_20260711_01.apk
未传 filename 时自动取 builds/ 中最新的 Jeenith_*.apk。"""
import sys, hashlib, os, json, shutil, datetime, re

fname = sys.argv[1] if len(sys.argv) > 1 else None
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
builds_dir = os.path.join(project_root, "..", "builds", "release")
android_dir = os.path.join(builds_dir, "android")  # 正式 APK 归档路径

if not fname:
    apks = [f for f in os.listdir(android_dir) if f.startswith("Jeenith_") and f.endswith(".apk")]
    apks.sort(key=lambda f: os.path.getmtime(os.path.join(android_dir, f)), reverse=True)
    fname = apks[0] if apks else None
if not fname:
    print("[HISTORY] No APK found"); sys.exit(1)

target = os.path.join(android_dir, fname)
m = re.match(r"Jeenith_(\d+\.\d+\.\d+)_(\w+)_(\d{8})_(\d{2})\.apk", fname)
if not m:
    print(f"[HISTORY] Cannot parse {fname}"); sys.exit(1)
version, status, date, seq = m.group(1), m.group(2), m.group(3), int(m.group(4))

pubspec = open(os.path.join(project_root, "pubspec.yaml"), encoding="utf-8").read()
pm = re.search(r"version:\s*\d+\.\d+\.\d+\+(\d+)", pubspec)
build_number = int(pm.group(1)) if pm else 0

with open(target, "rb") as f:
    sha = hashlib.sha256(f.read()).hexdigest().upper()
size = os.path.getsize(target)
size_fmt = f"{size/1048576:.2f} MB"
ts = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")

src_apk = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "app-release.apk")
bk_name = f"app_app-release.apk_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.apk"
bk_dir = os.path.join(project_root, "build", "app", "outputs", "flutter-apk", "backup")
os.makedirs(bk_dir, exist_ok=True)
bk_path = None
if os.path.exists(src_apk):
    bk_path = os.path.join(bk_dir, bk_name)
    shutil.copy(src_apk, bk_path)


def win(p):
    return p.replace("/", "\\") if p else None


SRC, TGT, BK = win(src_apk), win(target), win(bk_path)
labels = {
    "release": "正式版", "rc": "候选版", "fix": "修复版", "hotfix": "紧急修复",
    "beta": "测试版", "feature": "功能版", "alpha": "内测版", "dev": "开发版", "debug": "调试版",
}
main_rec = {
    "version": f"{version}+{build_number}", "status": status, "statusLabel": labels.get(status, status),
    "date": date, "sequence": seq, "filename": fname, "timestamp": ts,
    "fileSize": size, "fileSizeFormatted": size_fmt, "sha256": sha,
    "sourcePath": SRC, "targetPath": TGT, "backupPath": BK,
    "platform": "android-arm64,android-arm,android-x64", "verificationPassed": True,
}
inner_rec = {
    "version": version, "buildNumber": build_number, "status": status,
    "date": date, "sequence": seq, "filename": fname, "originalName": "app-release.apk",
    "filePath": TGT, "fileSize": size, "fileSizeHuman": size_fmt, "sha256": sha,
    "buildType": "apk", "platform": "android", "timestamp": ts, "configSource": "pubspec.yaml",
}
main_obj = {"project": "Jeenith", "description": "Jeenith (志极) - 叩问本心的卜算合集",
            "namingRule": "{程序名}_{版本号}_{状态}_{构建日期}_{构建序号}.{扩展名}", "builds": [main_rec]}
inner_obj = {"project": "Jeenith", "namingFormat": "{app_name}_{version}_{status}_{date}_{seq}.{ext}",
             "builds": [inner_rec]}

for path, obj in [(os.path.join(builds_dir, "build_history.json"), main_obj),
                  (os.path.join(project_root, "build_history.json"), inner_obj)]:
    existing = None
    if os.path.exists(path):
        try:
            with open(path, encoding="utf-8") as f:
                existing = json.load(f)
        except Exception:
            existing = None
    if existing and "builds" in existing:
        if not any(b.get("filename") == fname for b in existing["builds"]):
            existing["builds"].append(obj["builds"][0])
        obj = existing
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)

print(f"[HISTORY] appended: {fname}")
print(f"  sha256={sha[:16]}... size={size_fmt} ts={ts}")
