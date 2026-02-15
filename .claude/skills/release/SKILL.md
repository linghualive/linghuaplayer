---
name: release
description: "Flamekit 发布版本流程。当用户说「发布版本」「打包发布」「release」「发版」时触发。执行：提交并推送代码、询问版本号、更新 pubspec.yaml、本地构建签名 APK、git commit + tag + push 触发 GitHub Actions Linux 构建。"
---

# Flamekit 发布流程

## 步骤

### 1. 提交代码并推送

检查工作区是否有未提交的变更（git status + git diff）。
如有变更，暂存所有修改的文件（不包含 .env、密钥等敏感文件），生成提交信息，提交并 push 到远端。
如无变更则跳过。

### 2. 询问版本号

用 AskUserQuestion 询问新版本号，格式 `x.y.z+N`（如 `1.5.0+6`）。
从 `pubspec.yaml` 读取当前 `version:` 行展示给用户参考。

### 3. 更新 pubspec.yaml

将 `pubspec.yaml` 中 `version:` 行改为用户指定的版本号。

### 4. 本地构建签名 APK

```bash
flutter build apk --release
```

产物：`build/app/outputs/flutter-apk/app-release.apk`。
签名由 `android/key.properties` 自动处理，无需额外参数。

### 5. 提交版本号、打 Tag、推送

VERSION 替换为用户指定的版本号。

```bash
git add pubspec.yaml
git commit -m "release: vVERSION"
git tag vVERSION
git push && git push --tags
```

推送 tag 后 `.github/workflows/build-linux.yml` 自动触发 Linux 构建，产物上传到 GitHub Release。

### 6. 汇报结果

- APK 路径：`build/app/outputs/flutter-apk/app-release.apk`
- Tag：`vVERSION`
- GitHub Actions：`https://github.com/linghualive/linghuaplayer/actions`
