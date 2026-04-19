#!/bin/bash
# 快速参考 - SimpleX Chat Android CI/CD 系统

cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║        ✅ SimpleX Chat Android 自动化构建系统已完成                      ║
║                                                                            ║
╚════════════════════════════════════════════════════════════════════════════╝

📦 创建的文件：

工作流程:
  ✅ .github/workflows/build-android.yml (6.8 KB)
     └─ 基础构建工作流 (Debug/Release, 多架构)

  ✅ .github/workflows/build-android-signed.yml (8.7 KB)
     └─ 生产构建工作流 (含签署和自动Release)

  ✅ .github/workflows/ANDROID_SIGNING_GUIDE.md
     └─ APK签署配置详细指南

文档:
  ✅ docs/ANDROID_BUILD_GUIDE.md (7.3 KB)
     └─ 完整的使用指南和故障排除

  ✅ ANDROID_BUILD_COMPLETION.md
     └─ 完成总结和详细说明

脚本:
  ✅ scripts/build-android-local.sh (7.9 KB)
     └─ 本地快速构建脚本

════════════════════════════════════════════════════════════════════════════

🚀 快速开始 (仅需一条命令):

本地构建:
  ./scripts/build-android-local.sh              # Debug版本
  ./scripts/build-android-local.sh release      # Release版本
  ./scripts/build-android-local.sh debug -i     # 构建并安装

自动构建:
  git tag v6.4.1                                # 创建标签
  git push origin v6.4.1                        # 推送标签
  # → 自动构建、签署、发布

════════════════════════════════════════════════════════════════════════════

📊 支持的架构:

  ✅ arm64-v8a     (推荐 - 现代Android设备)
  ✅ armeabi-v7a   (向后兼容 - 旧设备)
  ✅ x86_64        (模拟器和x86平板)

════════════════════════════════════════════════════════════════════════════

🔄 工作流对比:

┌─────────────────────┬─────────────┬──────────────┬──────────────┐
│      功能           │   build-    │   build-     │   local.sh   │
│                     │   android   │   signed     │              │
├─────────────────────┼─────────────┼──────────────┼──────────────┤
│ Debug构建           │      ✅     │      ✅      │      ✅      │
│ Release构建         │      ✅     │      ✅      │      ✅      │
│ APK签署             │      ❌     │      ✅      │      ❌      │
│ GitHub Release      │      ❌     │      ✅      │      ❌      │
│ 校验和生成          │      ❌     │      ✅      │      ✅      │
│ 自动触发            │      ✅     │      ✅      │      ❌      │
│ 直接安装到设备      │      ❌     │      ❌      │      ✅      │
│ 本地使用            │      ❌     │      ❌      │      ✅      │
└─────────────────────┴─────────────┴──────────────┴──────────────┘

════════════════════════════════════════════════════════════════════════════

📚 完整文档:

快速参考:
  - 本文件:     此文件
  - 完成总结:   ANDROID_BUILD_COMPLETION.md
  - 脚本帮助:   ./scripts/build-android-local.sh -h

详细指南:
  - 完整指南:   docs/ANDROID_BUILD_GUIDE.md
  - 签署指南:   .github/workflows/ANDROID_SIGNING_GUIDE.md
  - 工作流:     .github/workflows/build-android*.yml

════════════════════════════════════════════════════════════════════════════

🔑 可选配置 - APK签署 (生产环境):

1. 生成签署密钥:
   keytool -genkey -v -keystore simplex-release.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias simplex-release

2. 配置GitHub Secrets:
   Repository Settings → Secrets and variables → Actions

   添加以下Secrets:
   - SIMPLEX_ANDROID_KEYSTORE_BASE64      (JKS文件Base64编码)
   - SIMPLEX_ANDROID_KEYSTORE_PASSWORD    (密钥库密码)
   - SIMPLEX_ANDROID_KEY_PASSWORD         (密钥密码)
   - SIMPLEX_ANDROID_KEY_ALIAS            (可选, 默认值: simplex-release)

3. 创建Release标签:
   git tag v6.4.1
   git push origin v6.4.1
   # → 自动构建、签署、发布

详见: .github/workflows/ANDROID_SIGNING_GUIDE.md

════════════════════════════════════════════════════════════════════════════

✅ 工作流自动触发条件:

build-android.yml:
  ✓ Push到 master/stable 分支
  ✓ 创建任何 Release 标签 (v*)
  ✓ 修改 apps/multiplatform/ 目录
  ✓ Pull Request 到 master/stable
  ✓ 手动 workflow_dispatch

build-android-signed.yml:
  ✓ Push到 master/stable 分支 (构建)
  ✓ 创建 Release 标签 (构建+签署+发布)
  ✓ 手动 workflow_dispatch

════════════════════════════════════════════════════════════════════════════

📥 获取构建产物:

GitHub Actions Artifacts (30天保留):
  1. 访问 Repository → Actions
  2. 选择工作流运行
  3. 下载 "simplex-chat-debug-*" 或 "simplex-chat-release-*"

GitHub Release (永久):
  1. 访问 Repository → Releases
  2. 找到对应版本 (v6.4.1等)
  3. 下载APK和SHA256SUMS.txt

本地构建 (即时):
  ./scripts/build-android-local.sh
  # APK保存在: apps/multiplatform/android/build/outputs/

════════════════════════════════════════════════════════════════════════════

🔍 验证APK完整性:

下载APK后验证:

  # 验证SHA256校验和
  sha256sum -c SHA256SUMS.txt

  # 验证APK签署
  jarsigner -verify -verbose -certs simplex-chat-release-arm64.apk

  # 查看签署证书信息
  keytool -printcert -jarfile simplex-chat-release-arm64.apk

════════════════════════════════════════════════════════════════════════════

🐛 故障排除快速参考:

问题: 构建超时
→ 增加工作流中的 timeout-minutes 值

问题: Gradle缓存问题
→ 运行: rm -rf ~/.gradle/caches

问题: NDK版本不匹配
→ 修改工作流中的 NDK_VERSION 环境变量

问题: 签署失败
→ 验证GitHub Secrets中的密码和JKS文件

完整故障排除: docs/ANDROID_BUILD_GUIDE.md#-故障排除

════════════════════════════════════════════════════════════════════════════

💡 建议和最佳实践:

✅ 在发布前在develop分支测试构建
✅ 使用语义化版本 (SemVer) 管理版本号 (v6.4.1)
✅ 定期更新Gradle和Android Gradle Plugin
✅ 妥善保管签署密钥库，定期备份
✅ 使用强密码保护密钥库和密钥
✅ 创建Release时添加详细的变更说明
✅ 验证APK签署和校验和后再发布

════════════════════════════════════════════════════════════════════════════

📞 需要帮助?

详细步骤说明:
  → 查看 docs/ANDROID_BUILD_GUIDE.md

APK签署配置:
  → 查看 .github/workflows/ANDROID_SIGNING_GUIDE.md

本地脚本帮助:
  → 运行 ./scripts/build-android-local.sh -h

完成总结:
  → 查看 ANDROID_BUILD_COMPLETION.md

════════════════════════════════════════════════════════════════════════════

🎉 系统已准备就绪！

立即开始:
  1. 本地测试: ./scripts/build-android-local.sh
  2. 阅读指南: cat docs/ANDROID_BUILD_GUIDE.md
  3. 配置签署: cat .github/workflows/ANDROID_SIGNING_GUIDE.md

════════════════════════════════════════════════════════════════════════════

创建日期: 2026年4月18日
版本: 1.0.0
EOF

