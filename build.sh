#!/bin/bash

# 此脚本的一些逻辑是从 [scripts/build_kernel] 复制的。感谢 UtsavBalar1231 和 liyafe1997
# Some logics of this script are copied from [scripts/build_kernel]. Thanks to UtsavBalar1231 and liyafe1997

# 确保脚本在出错时退出
# Ensure the script exits on error
set -e

TOOLCHAIN_PATH=/home/bai/toolchains/clang13/bin/
# aarch64_gcc=/home/bai/toolchains/gcc/gcc-aarch64/bin/
# arm_gcc=/home/bai/toolchains/gcc/gcc-arm/bin/

# 设置编译器后缀，通常为：gnu
# Set compiler suffix, usually: gun
aarch64_Compiler_suffix=gnu

# 设置编译器后缀，通常为：gnueabi
# Set compiler suffix, usually: guneabi
arm_Compiler_suffix=gnueabi

# 使用 ld.lld 链接器 设置为 y
# Use ld.lld linker, set y
USER_VAR=y

# export LLVM=1
# export LLVM_IAS=1

# 如果你需要中文可以设为 y 不需要可以设 n
# If you need Chinese, set y, if not, set n
Chinese=

# 如果手动设置为空，则自动读取当前环境判断是否为中文
# If manually set to empty, automatically read the current environment to determine whether it is Chinese
if [ -z "$Chinese" ]; then
    current_locale=$(echo $LANG)
    if [ "$current_locale" = "zh_CN.UTF-8" ]; then
        echo ""
        echo "检测到当前为中文环境，已经设置为中文"
        echo "Detected that the current environment is Chinese, set to Chinese"
        Chinese=y
    else
        echo ""
        echo "检测到当前为非中文环境，已经设置为英文"
        echo "Detected that the current environment is non-Chinese, set to English"
        Chinese=n
    fi
else
    echo ""
    echo "手动设置了脚本语言"
    echo "Manually set the script language"
    echo ""
fi

TARGET_DEVICE=$1

if [ -z "$1" ]; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "错误：未提供参数，请指定目标设备"
        echo "如果您需要 KernelSU ,请添加 [ksu] 作为第二个参数"
        echo "以下是示例:"
        echo ""
        echo "不带 KernelSU 的 lmi (K30 Pro/POCO F2 Pro)构建:"
        echo "bash build.sh lmi"
        echo ""
        echo "使用 KernelSU 构建umi(Mi10):"
        echo "bash build.sh umi ksu"
        echo ""
    else
        echo ""
        echo "Error: No argument provided, please specific a target device."
        echo "Error: No argument provided, please specific a target device."
        echo "If you need KernelSU, please add [ksu] as the second arg."
        echo "Examples:"
        echo ""
        echo "Build for lmi(K30 Pro/POCO F2 Pro) without KernelSU:"
        echo "    bash build.sh lmi"
        echo ""
        echo "Build for umi(Mi10) with KernelSU:"
        echo "    bash build.sh umi ksu"
        echo ""
    fi
    exit 1
fi

if [ ! -d $TOOLCHAIN_PATH ]; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "TOOLCHAIN_PATH [$TOOLCHAIN_PATH] 不存在"
        echo "请确保工具链存在,或将脚本中的 TOOLCHAIN_PATH 更改为您的工具链路径"
        echo ""
    else
        echo ""
        echo "TOOLCHAIN_PATH [$TOOLCHAIN_PATH] does not exist."
        echo "Please ensure the toolchain is there, or change TOOLCHAIN_PATH in the script to your toolchain path."
        echo ""
    fi
    exit 1
fi

# 将编译器导入PATH
# Import the compiler into PATH
echo "TOOLCHAIN_PATH: [$TOOLCHAIN_PATH]"
export PATH="$TOOLCHAIN_PATH:$aarch64_gcc:$arm_gcc:$PATH"

if ! command -v aarch64-linux-$aarch64_Compiler_suffix-ld >/dev/null 2>&1; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "aarch64-linux-$aarch64_Compiler_suffix-ld 不存在,请检查您的环境"
        echo ""
    else
        echo ""
        echo "aarch64-linux-$aarch64_Compiler_suffix-ld does not exist, please check your environment."
        echo ""
    fi
    exit 1
fi

if ! command -v arm-linux-$arm_Compiler_suffix-ld >/dev/null 2>&1; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "arm linux-$arm_Compiler_suffix-ld 不存在,请检查您的环境"
        echo ""
    else
        echo ""
        echo "arm-linux-$arm_Compiler_suffix-ld does not exist, please check your environment."
        echo ""
    fi
    exit 1
fi

if ! command -v clang >/dev/null 2>&1; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "[clang] 不存在，请检查您的环境"
        echo ""
    else
        echo ""
        echo "[clang] does not exist, please check your environment."
        echo ""
    fi
    exit 1
fi

# 启用ccache以加快编译速度
# Enable ccache for speed up compiling
export CCACHE_DIR="$HOME/.cache/ccache_mikernel"
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

if [ ! -f "arch/arm64/configs/${TARGET_DEVICE}_defconfig" ]; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo -e " 未找到目标设备 [${TARGET_DEVICE}] \n"
        echo -e " 可用的配置，请从下面选择一个目标：\n"
    else
        echo ""
        echo "No target device [${TARGET_DEVICE}] found."
        echo ""
        echo "Avaliable defconfigs, please choose one target from below down:"
        echo ""
    fi
    ls arch/arm64/configs/*_defconfig
    exit 1
fi

#检查clang是否存在。
# Check clang is existing.
echo "[clang --version]:"
clang --version

# 设置KSU ZIP 包名称
# Set KSU ZIP package name
KSU_ZIP_STR=NoKernelSU
if [ "$2" == "ksu" ]; then
    KSU_ENABLE=1
    KSU_ZIP_STR=KernelSU
else
    KSU_ENABLE=0
fi

echo "TARGET_DEVICE: $TARGET_DEVICE"

if [ $KSU_ENABLE -eq 1 ]; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "KSU 已启用"
        echo ""
    else
        echo ""
        echo "KSU is enabled"
        echo ""
    fi
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v0.9.5
else
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "KSU 已禁用"
    else
        echo ""
        echo "KSU is disabled"
    fi
fi

if [ "$USER_VAR" = "y" ]; then
    export LD=ld.lld
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "LD=ld.lld 已设置"
        echo ""
    else
        echo ""
        echo “LD=ld.lld is set”
        echo ""
    fi
else
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "未设置 LD=ld.lld"
        echo ""
    else
        echo ""
        echo "LD=ld.lld not set"
        echo ""
    fi
fi

MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang CROSS_COMPILE=aarch64-linux-$aarch64_Compiler_suffix- CROSS_COMPILE_ARM32=arm-linux-$arm_Compiler_suffix- CROSS_COMPILE_COMPAT=arm-linux-$arm_Compiler_suffix- CLANG_TRIPLE=aarch64-linux-$aarch64_Compiler_suffix-"

if [ "$Chinese" = "y" ]; then
    echo ""
    echo "正在清洁..."
    echo ""
else
    echo ""
    echo "Cleaning..."
    echo ""
fi

rm -rf out/
rm -rf anykernel/

echo "Clone AnyKernel3 for packing kernel (repo: https://github.com/liyafe1997/AnyKernel3)"
git clone https://github.com/liyafe1997/AnyKernel3 -b kona --single-branch --depth=1 anykernel

# ------------- 开始构建AOSP -------------
# ------------- Building for AOSP -------------

if [ "$Chinese" = "y" ]; then
    echo ""
    echo "开始构建......"
    echo ""
else
    echo ""
    echo "Building......"
    echo ""
fi

make $MAKE_ARGS ${TARGET_DEVICE}_defconfig

if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config -e KSU
else
    scripts/config --file out/.config -d KSU
fi
# bear -- make -j$(nproc --all) CC="ccache clang" O=out ARCH=arm64 ld.lld
bear -- make $MAKE_ARGS -j$(nproc --all)

# make $MAKE_ARGS -j$(nproc)

if [ -f "out/arch/arm64/boot/Image" ]; then
    if [ "$Chinese" = "y" ]; then
        echo "文件 [out/arch/arm64/boot/Image]存在,AOSP构建成功"
        echo ""
    else
        echo ""
        echo "The file [out/arch/arm64/boot/Image] exists. AOSP Build successfully."
        echo ""
    fi
else
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "文件 [out/arch/arm64/boot/Image] 不存在,似乎AOSP构建失败"
        echo ""
    else
        echo ""
        echo "The file [out/arch/arm64/boot/Image] does not exist. Seems AOSP build failed."
        echo ""
    fi
    exit 1
fi
if [ "$Chinese" = "y" ]; then
    echo ""
    echo "正在生成 [out/arch/arm64/boot/dtb]......"
    echo ""
else
    echo ""
    echo "Generating [out/arch/arm64/boot/dtb]......"
    echo ""
fi
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

rm -rf anykernel/kernels/

mkdir -p anykernel/kernels/

cp out/arch/arm64/boot/Image anykernel/kernels/
cp out/arch/arm64/boot/dtb anykernel/kernels/

cd anykernel

ZIP_FILENAME=Kernel_AOSP_${TARGET_DEVICE}_${KSU_ZIP_STR}_$(date +'%Y%m%d_%H%M%S')_anykernel3.zip

zip -r9 $ZIP_FILENAME ./* -x .git .gitignore out/ ./*.zip

mv $ZIP_FILENAME ../

cd ..
if [ "$Chinese" = "y" ]; then
    echo ""
    echo "AOSP构建已完成"
    echo ""
else
    echo ""
    echo "Build for AOSP finished."
    echo ""
fi

# ------------------ 结束AOSP构建 ---------------------
# ------------- End of Building for AOSP -------------
# 如果你不需要AOSP，你可以注释掉上面的内容[为AOSP构建]
#  If you don't need AOSP you can comment out the above block [Building for AOSP]
# ------------------ 为 MIUI 构建 --------------------
# --------------- Building for MIUI ------------------
if [ "$Chinese" = "y" ]; then
    echo ""
    echo "清除[out/]并为MIUI构建....."
    echo ""
else
    echo ""
    echo "Clearning [out/] and build for MIUI....."
    echo ""
fi
rm -rf out/

dts_source=arch/arm64/boot/dts/vendor/qcom

# 备份dts
# Backup dts
cp -a ${dts_source} .dts.bak

# 修正 MIUI 版本的面板尺寸
# Correct panel dimensions on MIUI builds
sed -i 's/<154>/<1537>/g' ${dts_source}/dsi-panel-j1s*
sed -i 's/<154>/<1537>/g' ${dts_source}/dsi-panel-j2*
sed -i 's/<155>/<1544>/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
sed -i 's/<155>/<1545>/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
sed -i 's/<155>/<1546>/g' ${dts_source}/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
sed -i 's/<155>/<1546>/g' ${dts_source}/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
sed -i 's/<70>/<695>/g' ${dts_source}/dsi-panel-l11r-38-08-0a-dsc-cmd.dtsi
sed -i 's/<71>/<710>/g' ${dts_source}/dsi-panel-j1s*
sed -i 's/<71>/<710>/g' ${dts_source}/dsi-panel-j2*

# 启用 back mi smartfps，同时禁用 qsync 最小刷新率
# Enable back mi smartfps while disabling qsync min refresh-rate
sed -i 's/\/\/ mi,mdss-dsi-pan-enable-smart-fps/mi,mdss-dsi-pan-enable-smart-fps/g' ${dts_source}/dsi-panel*
sed -i 's/\/\/ mi,mdss-dsi-smart-fps-max_framerate/mi,mdss-dsi-smart-fps-max_framerate/g' ${dts_source}/dsi-panel*
sed -i 's/\/\/ qcom,mdss-dsi-pan-enable-smart-fps/qcom,mdss-dsi-pan-enable-smart-fps/g' ${dts_source}/dsi-panel*
sed -i 's/qcom,mdss-dsi-qsync-min-refresh-rate/\/\/qcom,mdss-dsi-qsync-min-refresh-rate/g' ${dts_source}/dsi-panel*

# 启用 MIUI 支持的刷新率
# Enable back refresh rates supported on MIUI
sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-36-02-0c-dsc-video.dtsi
sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-37-02-0a-dsc-video.dtsi
sed -i 's/120 90 60/120 90 60 50 30/g' ${dts_source}/dsi-panel-g7a-37-02-0b-dsc-video.dtsi
sed -i 's/144 120 90 60/144 120 90 60 50 48 30/g' ${dts_source}/dsi-panel-j3s-37-02-0a-dsc-video.dtsi

# 从 dtsi 启用背光亮度控制
# Enable back brightness control from dtsi
sed -i 's/\/\/39 00 00 00 00 00 03 51 03 FF/39 00 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
sed -i 's/\/\/39 00 00 00 00 00 03 51 0D FF/39 00 00 00 00 00 03 51 0D FF/g' ${dts_source}/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' ${dts_source}/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' ${dts_source}/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j9-38-0a-0a-fhd-video.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi
sed -i 's/\/\/39 01 00 00 01 00 03 51 03 FF/39 01 00 00 01 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi
sed -i 's/\/\/39 01 00 00 11 00 03 51 03 FF/39 01 00 00 11 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi

make $MAKE_ARGS ${TARGET_DEVICE}_defconfig

if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config -e KSU
else
    scripts/config --file out/.config -d KSU
fi

scripts/config --file out/.config \
    --set-str STATIC_USERMODEHELPER_PATH /system/bin/micd \
    -e ARM_ARCH_TIMER_VCT_ACCESS \
    -e F2FS_UNFAIR_RWSEM \
    -e PERF_CRITICAL_RT_TASK \
    -e SF_BINDER \
    -e OVERLAY_FS \
    -d UNICODE \
    -d DEBUG_FS \
    -e MIGT \
    -e MIGT_ENERGY_MODEL \
    -e MIHW \
    -e PACKAGE_RUNTIME_INFO \
    -e BINDER_OPT \
    -e KPERFEVENTS \
    -e MILLET \
    -e PERF_HUMANTASK \
    -d OSSFOD \
    -d LTO_CLANG \
    -d LOCALVERSION_AUTO \
    -d TOUCHSCREEN_COMMON \
    -e SF_BINDER \
    -e XIAOMI_MIUI \
    -d MI_MEMORY_SYSFS \
    -e TASK_DELAY_ACCT \
    -e MIUI_ZRAM_MEMORY_TRACKING \
    -d CONFIG_MODULE_SIG_SHA512 \
    -d CONFIG_MODULE_SIG_HASH \
    -e MI_FRAGMENTION

make $MAKE_ARGS -j$(nproc)

if [ -f "out/arch/arm64/boot/Image" ]; then
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "文件 [out/arch/arm64/boot/Image] 已存在。MIUI 构建成功"
        echo ""
    else
        echo ""
        echo "The file [out/arch/arm64/boot/Image] exists. MIUI Build successfully."
        echo ""
    fi
else
    if [ "$Chinese" = "y" ]; then
        echo ""
        echo "文件 [out/arch/arm64/boot/Image] 不存在。似乎 MIUI 生成失败"
        echo ""
    else
        echo ""
        echo "The file [out/arch/arm64/boot/Image] does not exist. Seems MIUI build failed."
        echo ""
    fi
    exit 1
fi
if [ "$Chinese" = "y" ]; then
    echo "正在生成 [out/arch/arm64/boot/dtb]......"
else
    echo "Generating [out/arch/arm64/boot/dtb]......"
fi
find out/arch/arm64/boot/dts -name '*.dtb' -exec cat {} + >out/arch/arm64/boot/dtb

# 还原修改过的 dts
# Restore modified dts
rm -rf ${dts_source}
mv .dts.bak ${dts_source}

rm -rf anykernel/kernels/
mkdir -p anykernel/kernels/

cp out/arch/arm64/boot/Image anykernel/kernels/
cp out/arch/arm64/boot/dtb anykernel/kernels/

if [ "$Chinese" = "y" ]; then
    echo ""
    echo "MIUI 的构建工作已完成"
    echo ""
else
    echo ""
    echo "Build for MIUI finished."
    echo ""
fi
# ---------------- 为 MIUI 构建结束 -------------
# ------------- End of Building for MIUI -------------
# 如果不需要 MIUI，可以注释掉上面的内容 [为 MIUI 构建]
#  If you don't need MIUI you can comment out the above block [Building for MIUI]

cd anykernel

ZIP_FILENAME=Kernel_MIUI_${TARGET_DEVICE}_${KSU_ZIP_STR}_$(date +'%Y%m%d_%H%M%S')_anykernel3.zip

zip -r9 $ZIP_FILENAME ./* -x .git .gitignore out/ ./*.zip

mv $ZIP_FILENAME ../

cd ..
if [ "$Chinese" = "y" ]; then
    echo ""
    echo "完成。可刷入的压缩包是 [./$ZIP_FILENAME]"
    echo ""
else
    echo ""
    echo "Done. The flashable zip is: [./$ZIP_FILENAME]"
    echo ""
fi
