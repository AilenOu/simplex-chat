#!/bin/bash
# SimpleX Chat Android 本地构建脚本
# 用于在本地快速构建Android APK

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# 变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ANDROID_DIR="$PROJECT_ROOT/apps/multiplatform"
BUILD_TYPE="${1:-debug}"
ABI_FILTER="${2:-arm64-v8a}"
GRADLE_OPTS="-Dorg.gradle.jvmargs=-Xmx4g -Dorg.gradle.parallel=true -Dorg.gradle.workers.max=4"

# 检查前置条件
check_requirements() {
    print_header "检查环境要求"

    # 检查Java
    if ! command -v java &> /dev/null; then
        print_error "未安装Java，请先安装JDK 17+"
        exit 1
    fi

    java_version=$(java -version 2>&1 | head -1 | grep -oP '(?<=version ")[^"]*' || echo "unknown")
    print_success "Java版本: $java_version"

    # 检查Android SDK
    if [ -z "$ANDROID_SDK_ROOT" ] && [ -z "$ANDROID_HOME" ]; then
        print_warning "ANDROID_SDK_ROOT/ANDROID_HOME未设置"
        print_warning "请运行: export ANDROID_SDK_ROOT=/path/to/android-sdk"
        exit 1
    fi

    ANDROID_SDK="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
    print_success "Android SDK: $ANDROID_SDK"

    # 检查Gradle
    if [ ! -f "$ANDROID_DIR/gradlew" ]; then
        print_error "找不到gradlew脚本"
        exit 1
    fi

    print_success "Gradle: $(cd $ANDROID_DIR && ./gradlew --version | head -2)"

    # 检查项目目录
    if [ ! -d "$ANDROID_DIR" ]; then
        print_error "找不到Android项目目录: $ANDROID_DIR"
        exit 1
    fi

    print_success "项目目录: $ANDROID_DIR"
}

# 清理构建
clean_build() {
    print_header "清理旧构建"

    cd "$ANDROID_DIR"

    ./gradlew clean --quiet

    print_success "构建目录已清理"
}

# 配置本地属性
setup_properties() {
    print_header "配置构建属性"

    cd "$ANDROID_DIR"

    # 检查或创建local.properties
    if [ ! -f "local.properties" ]; then
        print_warning "local.properties不存在，创建新文件"
        cat > local.properties << EOF
# Android SDK路径
sdk.dir=$ANDROID_SDK

# 构建配置
abi_filter=$ABI_FILTER
compression.level=9

# 调试配置
debuggable=true
application_id.suffix=
EOF
    else
        # 更新abi_filter
        sed -i.bak "s/^abi_filter=.*/abi_filter=$ABI_FILTER/" local.properties
        rm -f local.properties.bak
    fi

    print_success "本地属性配置完成"
    echo "配置内容:"
    cat local.properties
}

# 构建APK
build_apk() {
    print_header "构建$BUILD_TYPE APK ($ABI_FILTER)"

    cd "$ANDROID_DIR"

    # 转换构建类型（首字母大写）
    gradle_task=$(echo "assemble$BUILD_TYPE" | sed 's/./\U&/')

    print_warning "执行: ./gradlew $gradle_task $GRADLE_OPTS"
    echo ""

    if ./gradlew $gradle_task $GRADLE_OPTS; then
        print_success "APK构建成功!"
    else
        print_error "APK构建失败"
        exit 1
    fi
}

# 查找生成的APK
find_apk() {
    print_header "查找生成的APK文件"

    cd "$ANDROID_DIR"

    # 根据构建类型查找APK
    if [ "$BUILD_TYPE" = "release" ]; then
        apk_pattern="*release*.apk"
    else
        apk_pattern="*debug*.apk"
    fi

    apk_file=$(find . -name "$apk_pattern" -type f -newer local.properties 2>/dev/null | head -1)

    if [ -z "$apk_file" ]; then
        print_error "找不到APK文件"
        print_warning "查找所有APK文件..."
        find . -name "*.apk" -type f
        exit 1
    fi

    # 获取完整路径
    apk_full_path="$ANDROID_DIR/$apk_file"
    apk_size=$(ls -lh "$apk_full_path" | awk '{print $5}')
    apk_hash=$(sha256sum "$apk_full_path" | cut -d' ' -f1)

    print_success "找到APK文件: $apk_file"
    echo "📦 文件大小: $apk_size"
    echo "🔐 SHA256: $apk_hash"

    echo "$apk_full_path"
}

# 安装到设备
install_apk() {
    local apk_path="$1"

    print_header "安装APK到连接的设备"

    if ! command -v adb &> /dev/null; then
        print_warning "adb未找到，请确保Android SDK已正确安装"
        print_warning "或手动运行: adb install \"$apk_path\""
        return 1
    fi

    # 检查是否有连接的设备
    devices=$(adb devices | tail -n +2 | wc -l)
    if [ "$devices" -lt 1 ]; then
        print_warning "未检测到连接的Android设备或模拟器"
        print_warning "请连接设备后重试或手动安装"
        return 1
    fi

    print_warning "安装中..."
    if adb install -r "$apk_path"; then
        print_success "APK已安装到设备"

        # 启动应用
        read -p "是否要启动应用? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            adb shell am start -n chat.simplex.app/chat.simplex.app.MainActivity
            print_success "应用已启动"
        fi
    else
        print_error "安装失败"
        return 1
    fi
}

# 显示使用方法
show_usage() {
    cat << EOF
${BLUE}SimpleX Chat Android 本地构建脚本${NC}

用法: $0 [构建类型] [ABI架构]

参数:
  构建类型: debug 或 release (默认: debug)
  ABI架构: arm64-v8a, armeabi-v7a, x86_64 (默认: arm64-v8a)

示例:
  $0                          # 构建debug版本 arm64-v8a
  $0 release                  # 构建release版本 arm64-v8a
  $0 debug armeabi-v7a        # 构建debug版本 armeabi-v7a
  $0 release x86_64           # 构建release版本 x86_64

环境变量:
  ANDROID_SDK_ROOT      Android SDK路径
  或 ANDROID_HOME       Android SDK路径

选项:
  -h, --help            显示此帮助信息
  -c, --clean           清理后重新构建
  -i, --install         构建后安装到设备
  -s, --skip-check      跳过环境检查

EOF
}

# 主函数
main() {
    local install_apk_flag=false
    local skip_check=false

    # 解析选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -c|--clean)
                clean_build
                shift
                ;;
            -i|--install)
                install_apk_flag=true
                shift
                ;;
            -s|--skip-check)
                skip_check=true
                shift
                ;;
            debug|release)
                BUILD_TYPE=$1
                shift
                ;;
            arm64-v8a|armeabi-v7a|x86_64|x86)
                ABI_FILTER=$1
                [ "$ABI_FILTER" = "x86" ] && ABI_FILTER="x86"
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # 验证参数
    if [[ ! "$BUILD_TYPE" =~ ^(debug|release)$ ]]; then
        print_error "构建类型必须是 debug 或 release"
        exit 1
    fi

    # 执行构建流程
    echo ""
    print_header "SimpleX Chat Android 构建器"
    echo "构建类型: $BUILD_TYPE"
    echo "ABI架构: $ABI_FILTER"
    echo ""

    [ "$skip_check" = false ] && check_requirements
    setup_properties
    build_apk

    apk_path=$(find_apk)
    echo ""

    if [ "$install_apk_flag" = true ]; then
        install_apk "$apk_path"
    else
        echo ""
        print_header "下一步"
        echo "1. 手动安装: adb install -r \"$apk_path\""
        echo "2. 使用脚本安装: $0 -i"
        echo "3. APK位置: $apk_path"
    fi

    echo ""
    print_success "构建完成!"
}

# 运行主函数
main "$@"

