#!/bin/bash
echo "                                                   "
echo "       420rom Pixel Edition Rom v6.0 Builder       "
echo "   Android Base 11.0.0 r8 - LineageOS Base 18.0    "
echo "                                                   "
echo "              By ExocetDJ & Abun880007             "
echo "                                                   "
echo "          Get the Download links from our          "
echo "        Telegram Group t.me/Home_of_420roms        "
echo "                                                   "
echo "              420rom Treble Buildbot               "
echo "                                                   "
echo "   ATTENTION: this script syncs repo on each run   "
echo "      Executing in 5 seconds - CTRL-C to exit      "
echo "                                                   "
sleep 5

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"
BL=$PWD/treble_build_420rom

echo "Preparing local manifest"
mkdir -p .repo/local_manifests
cp $BL/manifest.xml .repo/local_manifests/manifest.xml
echo ""

echo "Syncing repos"
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)
echo ""

echo "Setting up build environment"
source build/envsetup.sh &> /dev/null
echo ""

export WITHOUT_CHECK_API=true
export WITH_SU=true
mkdir -p ~/build-output/

buildVariant() {
	lunch ${1}-userdebug
	make installclean
	make -j$(nproc --all) systemimage
	make vndk-test-sepolicy
	mv $OUT/system.img ~/build-output/420rom-11-$BUILD_DATE-OFFICIAL-${1}.img
}

buildVariant treble_arm_avN
buildVariant treble_arm_avS
buildVariant treble_arm_bvN
buildVariant treble_arm_bvS
buildVariant treble_a64_avN
buildVariant treble_a64_avS
buildVariant treble_a64_bvN
buildVariant treble_a64_bvS
buildVariant treble_arm64_avN
buildVariant treble_arm64_avS
buildVariant treble_arm64_bvN
buildVariant treble_arm64_bvS
ls ~/build-output | grep '420rom'

echo "                                                   "
echo "   420rom Pixel Edition Rom v6.0 Build Completed   "
echo "                                                   "
END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))
echo "Buildbot completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo ""
