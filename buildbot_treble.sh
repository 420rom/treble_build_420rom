#!/bin/bash
echo ""
echo "420rom Android 11 Treble Buildbot"
echo "ATTENTION: this script syncs repo on each run"
echo "Executing in 5 seconds - CTRL-C to exit"
echo ""
sleep 5

# Abort early on error
set -eE
trap '(\
echo;\
echo \!\!\! An error happened during script execution;\
echo \!\!\! Please check console output for bad sync,;\
echo \!\!\! failed patch application, etc.;\
echo\
)' ERR

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
BL=$PWD/treble_build_420rom

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/420rom.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Cloning dependecy repos"
[ ! -d ./treble_patches ] && git clone https://github.com/abun880007/treble_patches -b 420rom-11
[ ! -d ./sas-creator ] && git clone https://github.com/AndyCGYan/sas-creator
rm -rf treble_app && git clone https://github.com/420rom/treble_app

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

echo "Reverting LOS FOD implementation"
cd frameworks/base
git am $BL/patches/0001-Squashed-revert-of-LOS-FOD-implementation.patch
cd ../..
cd frameworks/native
git revert cc9bccb92145121a707b9e447b89b825767405f1 --no-edit # surfaceflinger: Add support for extension lib
cd ../..
echo ""

echo "Applying PHH patches"
rm -f device/*/sepolicy/common/private/genfs_contexts
cd device/phh/treble
git clean -fdx
cp $BL/420rom.mk .
bash generate.sh 420rom
cd ../../..
bash ~/treble_experimentations/apply-patches.sh treble_patches
echo ""

echo "Applying universal patches"
cd build/make
git am $BL/patches/0001-Make-broken-copy-headers-the-default.patch
cd ../..
cd frameworks/base
git am $BL/patches/0001-UI-Disable-wallpaper-zoom.patch
git am $BL/patches/0001-Disable-vendor-mismatch-warning.patch
cd ../..
cd vendor/420rom
git am $BL/patches/0001-vendor_420rom-Log-privapp-permissions-whitelist-vio.patch
cd ../..
echo ""

echo "Applying GSI-specific patches"
cd build/make
git am $BL/patches/0001-build-fix-device-name.patch
cd ../..
cd device/phh/treble
git am $BL/patches/0001-Remove-fsck-SELinux-labels.patch
git am $BL/patches/0001-base-provide-libnfc-nci.patch
git am $BL/patches/0001-base-remove-securize-script.patch
git am $BL/patches/0001-board-add-broken-duplicate-rules-flag.patch
git am $BL/patches/0001-rw-system-set-fingerprint-props.patch
git am $BL/patches/0001-add-offline-charger-sepolicy.patch
cd ../../..
cd frameworks/av
git revert 2f03869e1fd4f0f51b5129f150e431c118d67e2f --no-edit # camera: Allow devices to load custom CameraParameter code
cd ../..
cd frameworks/native
git revert c83671c60d0144cb228c3a1b7212c71e3e37ce8e --no-edit # Add suspend_resume trace events to the atrace 'freq' category.
cd ../..
cd packages/apps/Bluetooth
git revert 659f453f2ee6983b3bc115631da4d09af1d3da55 --no-edit # Bluetooth: Reset packages/apps/Bluetooth to upstream
cd ../../..
cd system/core
git am $BL/patches/0001-Revert-init-Add-vendor-specific-initialization-hooks.patch
git am $BL/patches/0001-Panic-into-recovery-rather-than-bootloader.patch
git am $BL/patches/0001-Restore-sbin.patch
git am $BL/patches/0001-fix-offline-charger-v7.patch
cd ../../..
cd system/sepolicy
git am $BL/patches/0001-Revert-sepolicy-Relabel-wifi.-properties-as-wifi_pro.patch
cd ../..
cd vendor/420rom
git am $BL/patches/0001-build_soong-Disable-generated_kernel_headers.patch
git am $BL/patches/0001-build-fix-build-number.patch
cd ../..
echo ""

echo "Applying GSI-specific fixes"
mkdir -p device/generic/common/nfc
curl "https://android.googlesource.com/device/generic/common/+/refs/tags/android-11.0.0_r35/nfc/libnfc-nci.conf?format=TEXT"| base64 --decode > device/generic/common/nfc/libnfc-nci.conf
mkdir -p device/sample/etc
cp vendor/420rom/prebuilt/common/etc/apns-conf.xml device/sample/etc/apns-full-conf.xml
echo ""

echo "CHECK PATCH STATUS NOW!"
sleep 5
echo ""

export WITHOUT_CHECK_API=true
mkdir -p ~/builds

buildVariant() {
    lunch ${1}-userdebug
    make installclean
    make -j$(nproc --all) systemimage
    make vndk-test-sepolicy
    buildSasImage $1
}

buildSasImage() {
    cd sas-creator
    case $1 in
    "treble_a64_bvN")
        bash lite-adapter.sh 32 $OUT/system.img
        xz -c s.img -T0 > ~/builds/420rom_arm32_binder64-ab-vndklite-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/420rom_arm32_binder64-ab-11.0-$BUILD_DATE-UNOFFICIAL.img.xz
        ;;
    "treble_arm_bvN")
        bash run.sh 32 $OUT/system.img
        xz -c s.img -T0 > ~/builds/420rom_arm-aonly-11.0-$BUILD_DATE-OFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/420rom_arm-ab-11.0-$BUILD_DATE-OFFICIAL.img.xz
        ;;
    "treble_arm64_bvN")
        bash run.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/420rom_arm64-aonly-11.0-$BUILD_DATE-OFFICIAL.img.xz
        bash lite-adapter.sh 64 $OUT/system.img
        xz -c s.img -T0 > ~/builds/420rom_arm64-ab-vndklite-11.0-$BUILD_DATE-OFFICIAL.img.xz
        xz -c $OUT/system.img -T0 > ~/builds/420rom_arm64-ab-11.0-$BUILD_DATE-OFFICIAL.img.xz
        ;;
    esac
    rm -rf s.img
    cd ..
}

buildTrebleApp() {
    cd treble_app
    bash build.sh
    cp TrebleApp.apk ../vendor/hardware_overlay/TrebleApp/app.apk
    cd ..
}

buildTrebleApp
buildVariant treble_arm64_bgN
ls ~/builds | grep '420rom'
END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
