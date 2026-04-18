# 用于生产环境的Android APK签署指南

## 配置步骤

### 1. 生成签署密钥库

```bash
# 生成新的签署密钥库（仅首次需要）
keytool -genkey -v -keystore simplex-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias simplex-release
```

### 2. 配置GitHub Secrets

在GitHub仓库设置中添加以下Secrets：

| Secret名称 | 说明 |
|-----------|------|
| `SIMPLEX_ANDROID_KEYSTORE_BASE64` | Base64编码的签署密钥库文件内容 |
| `SIMPLEX_ANDROID_KEYSTORE_PASSWORD` | 密钥库密码 |
| `SIMPLEX_ANDROID_KEY_PASSWORD` | 密钥密码 |
| `SIMPLEX_ANDROID_KEY_ALIAS` | 密钥别名（默认：simplex-release） |

### 3. 转换密钥库为Base64

```bash
# 将JKS文件转换为Base64并复制到剪贴板
cat simplex-release.jks | base64 | xclip -selection clipboard
```

### 4. 在构建工作流中使用签署密钥

在GitHub Actions中，使用以下步骤对APK进行签署：

```yaml
- name: 对APK进行签署
  working-directory: apps/multiplatform
  env:
    SIGNING_KEY_ALIAS: ${{ secrets.SIMPLEX_ANDROID_KEY_ALIAS }}
    SIGNING_KEY_PASSWORD: ${{ secrets.SIMPLEX_ANDROID_KEY_PASSWORD }}
    SIGNING_STORE_PASSWORD: ${{ secrets.SIMPLEX_ANDROID_KEYSTORE_PASSWORD }}
  run: |
    # 解码密钥库
    echo "${{ secrets.SIMPLEX_ANDROID_KEYSTORE_BASE64 }}" | base64 -d > signing.jks
    
    # 配置gradle.properties
    cat >> local.properties << EOF
    RELEASE_STORE_FILE=$(pwd)/signing.jks
    RELEASE_STORE_PASSWORD=$SIGNING_STORE_PASSWORD
    RELEASE_KEY_ALIAS=$SIGNING_KEY_ALIAS
    RELEASE_KEY_PASSWORD=$SIGNING_KEY_PASSWORD
    EOF
    
    # 清理敏感文件
    rm -f signing.jks
```

### 5. 更新Android构建配置

在 `apps/multiplatform/android/build.gradle.kts` 中添加签署配置：

```kotlin
android {
    // ... existing config ...
    
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("RELEASE_STORE_FILE") ?: "")
            storePassword = System.getenv("RELEASE_STORE_PASSWORD") ?: ""
            keyAlias = System.getenv("RELEASE_KEY_ALIAS") ?: "simplex-release"
            keyPassword = System.getenv("RELEASE_KEY_PASSWORD") ?: ""
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

## 安全建议

⚠️ **安全提示**：
- 永远不要将签署密钥上传到仓库
- 定期轮换签署密钥
- 限制对GitHub Secrets的访问权限
- 使用强密码保护密钥库和密钥
- 考虑使用Android App Signing by Google Play来管理密钥

## 验证签署

```bash
# 验证APK是否正确签署
jarsigner -verify -verbose -certs app-release.apk

# 查看APK的签署证书信息
keytool -printcert -jarfile app-release.apk
```

