# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Dank Kernel for the Pixel 3a (XL) by @stebomurkn420
do.devicecheck=1
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=bonito
device.name2=sargo
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak3-core.sh;


## AnyKernel install
dump_boot;


# Warn user of their support status
android_version="$(file_getprop /system/build.prop "ro.build.version.release")";
security_patch="$(file_getprop /system/build.prop "ro.build.version.security_patch")";
version_info="$android_version:$security_patch";
case "$version_info" in
    "9:2019-07-05") support_status="a supported";;
    *) support_status="an unsupported";;
esac;
ui_print " "; ui_print "You are on $android_version with the $security_patch security patch level! This is $support_status configuration..."

# begin ramdisk changes

rm -fr $ramdisk/overlay

patch_cmdline "skip_override" ""

# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.lz4
if [ -f $compressed_image ]; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot --decompress $compressed_image $decompressed_image;
    $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
    $bin/magiskboot --compress=lz4 $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.lz4-dtb;
fi;


# Patch dtbo on custom ROMs
hostname="$(file_getprop /system/build.prop "ro.build.host")"
case "$hostname" in
    *corp.google.com|abfarm*) host=google;;
    *) host=custom;;
esac
if [ "$(file_getprop /system/build.prop "ro.build.user")" != "android-build" -o "$host" == "custom" ]; then
  ui_print " "; ui_print "You are on a custom ROM, patching dtb to remove verity...";
  $bin/magiskboot --dtb-patch /tmp/anykernel/Image.lz4-dtb;
else
  ui_print " "; ui_print "You are on stock, not patching dtb to remove verity!";
fi;

# Clean up files from other kernels
mountpoint -q /data && {
  rm -f /data/adb/magisk_simple/vendor/etc/powerhint.json
  rm -f /data/adb/service.d/95-proton.sh
  rm -f /data/adb/dtbo_a.orig.img /data/adb/dtbo_b.orig.img
}


# Install the boot image
write_boot;
