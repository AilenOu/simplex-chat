# SimpleX Chat Android 自动化构建指南

## 📋 概述

本项目现包含两个GitHub Actions工作流用于自动构建Android APK：

### 1. **build-android.yml** - 基础构建工作流
- 自动构建Debug和Release APK
- 支持多个架构（arm64-v8a, armeabi-v7a, x86_64）
- 生成构件供下载使用
- 适合开发和测试

### 2. **build-android-signed.yml** - 签署构建工作流
- 包括APK签署功能（仅限Release标签）
- 自动创建GitHub Release版本
- 生成校验和验证文件
- 适合生产环境发布

## 🚀 快速开始

### 基础构建（无需配置）

工作流自动触发条件：
```yaml
- Push到 master 或 stable 分支
- 创建以 v* 开头的Git标签（例如：v6.4.1）
- 修改 apps/multiplatform/ 目录下的文件
- Pull Request 到 master 或 stable 分支
```

### 构建触发方式

#### 方式1：通过Push事件
```bash
git tag v6.4.1
git push origin v6.4.1
# 工作流将自动开始构建
```

#### 方式2：通过Pull Request
```bash
git push origin feature-branch
# 创建Pull Request到master分支
# 工作流将自动开始构建
```

#### 方式3：手动触发（仅signed工作流）
访问 `.github/workflows/build-android-signed.yml`，点击"Run workflow"按钮。

## 🔑 配置APK签署（生产环境）

### 步骤1：生成签署密钥

```bash
# 生成新的签署密钥库
keytool -genkey -v -keystore simplex-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias simplex-release

# 系统会提示输入：
# 密钥库密码 (keystore password)
# 密钥密码 (key password)
# 其他信息（组织、地点等）
```

### 步骤2：转换为Base64

```bash
# Linux/macOS
cat simplex-release.jks | base64 | pbcopy

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes('simplex-release.jks')) | Set-Clipboard
```

### 步骤3：配置GitHub Secrets

访问仓库设置：**Settings** → **Secrets and variables** → **Actions**

添加以下Secrets：

| Secret名称 | 值 | 说明 |
|-----------|---|------|
| `SIMPLEX_ANDROID_KEYSTORE_BASE64` | (Base64编码的JKS文件) | 签署密钥库文件 |
| `SIMPLEX_ANDROID_KEYSTORE_PASSWORD` | (你的密钥库密码) | 保护密钥库的密码 |
| `SIMPLEX_ANDROID_KEY_PASSWORD` | (你的密钥密码) | 保护密钥的密码 |
| `SIMPLEX_ANDROID_KEY_ALIAS` | `simplex-release` | 密钥别名（可选，使用默认值） |

⚠️ **安全提示**：
- 绝不要在仓库中提交密钥库文件
- 定期轮换签署密钥
- 使用强密码保护密钥库
- 限制Secret的访问权限

### 步骤4：验证签署

创建标签后，工作流会：
1. 自动下载密钥库
2. 使用密钥对APK进行签署
3. 清理临时文件
4. 创建GitHub Release

## 📦 构件和Release

### 构件位置

所有构件保存在GitHub Actions中，保留30天：

**Build APK工作流**：
- `simplex-chat-debug-arm64`
- `simplex-chat-debug-armv7`
- `simplex-chat-debug-x86_64`
- `simplex-chat-release-arm64`
- `simplex-chat-release-armv7`
- `simplex-chat-release-x86_64`

**Signed工作流**：
- `simplex-chat-debug-arm64`
- `simplex-chat-debug-armv7`
- `simplex-chat-debug-x86_64`
- 以及Release版本和GitHub Release

### GitHub Release

当创建以 `v*` 开头的标签时（例如 `v6.4.1`），工作流会自动：

1. 构建所有架构的APK
2. 对APK进行签署（如果配置了密钥）
3. 创建GitHub Release
4. 上传APK和SHA256校验和文件

访问地址：`https://github.com/simplex-chat/simplex-chat/releases`

## 🔍 验证APK完整性

### 下载后验证

```bash
# 验证SHA256校验和
sha256sum -c SHA256SUMS.txt

# 验证APK签署
jarsigner -verify -verbose -certs simplex-chat-release-arm64.apk

# 查看APK的签署证书信息
keytool -printcert -jarfile simplex-chat-release-arm64.apk
```

## 📊 构建性能优化

工作流已配置以下优化：

```yaml
# Gradle性能优化
-Dorg.gradle.workers.max=4        # 并行Worker数
-Dorg.gradle.parallel=true         # 启用并行构建
-Dorg.gradle.jvmargs="-Xmx4g"     # JVM堆内存
```

## 🐛 故障排除

### 问题1：构建超时

**症状**：工作流在Gradle构建时超时

**解决**：
```yaml
# 在工作流中增加超时时间
timeout-minutes: 120  # 增加到120分钟
```

### 问题2：Gradle缓存问题

**症状**：`Gradle sync issue` 或 `build failure`

**解决**：
```bash
# 清空Gradle缓存
rm -rf ~/.gradle/caches
rm -rf dist-newstyle
```

### 问题3：NDK版本不匹配

**症状**：`CMake error` 或 `NDK not found`

**解决**：
修改工作流中的 `NDK_VERSION` 环境变量，或在 `local.properties` 中指定NDK路径：

```properties
ndk.dir=/path/to/android-ndk
```

### 问题4：签署失败

**症状**：`keystore password was incorrect`

**解决**：
1. 验证Secrets中的密码是否正确
2. 检查JKS文件是否正确Base64编码
3. 确保密钥别名存在

```bash
# 验证JKS文件中的密钥
keytool -list -v -keystore simplex-release.jks
```

## 📝 自定义工作流

### 修改构建架构

编辑 `.github/workflows/build-android.yml`：

```yaml
matrix:
  include:
    - arch: arm64-v8a  # 保留
    # - arch: armeabi-v7a  # 注释掉以禁用
    - arch: x86_64     # 保留
```

### 修改触发条件

编辑工作流文件中的 `on` 部分：

```yaml
on:
  push:
    branches:
      - master
      - develop  # 添加新分支
    paths:
      - 'apps/multiplatform/**'
```

### 添加自定义步骤

在构建步骤中添加自定义命令：

```yaml
- name: 运行自定义脚本
  working-directory: apps/multiplatform
  run: |
    ./scripts/custom-build.sh
```

## 📞 支持

如遇问题，请：

1. 检查GitHub Actions日志：仓库 → Actions → 选择工作流 → 查看详细日志
2. 查看本指南的故障排除部分
3. 提交Issue：提供详细的错误日志和环境信息

## 📚 相关文件

- `.github/workflows/build-android.yml` - 基础构建工作流
- `.github/workflows/build-android-signed.yml` - 签署构建工作流
- `.github/workflows/ANDROID_SIGNING_GUIDE.md` - 签署配置详细指南
- `apps/multiplatform/build.gradle.kts` - Android Gradle配置
- `apps/multiplatform/android/build.gradle.kts` - Android模块配置

## 🎯 最佳实践

1. **定期更新依赖**：保持Gradle、Kotlin和Android Gradle Plugin最新
2. **测试构建**：在创建Release标签前，先Push到develop分支测试
3. **备份密钥**：妥善保管签署密钥库，定期备份
4. **版本管理**：使用语义化版本（SemVer）管理版本号
5. **发布说明**：创建Release时添加详细的变更说明

## ✅ 检查清单

在发布新版本前：

- [ ] 更新版本号 (`apps/multiplatform/build.gradle.kts`)
- [ ] 更新CHANGELOG
- [ ] 在develop分支测试构建
- [ ] 合并到stable分支
- [ ] 创建Release标签 (`git tag v*`)
- [ ] Push标签触发工作流
- [ ] 验证GitHub Release中的APK文件
- [ ] 验证APK签署和校验和
- [ ] 发布Release通知

---

**最后更新**: 2026年4月18日

