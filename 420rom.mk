$(call inherit-product, vendor/420rom/config/common.mk)
$(call inherit-product, device/420rom/sepolicy/common/sepolicy.mk)
-include vendor/420rom/build/core/config.mk

TARGET_BOOT_ANIMATION_RES := 1440

TARGET_GAPPS_ARCH := arm64

# Vendor security patch level
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lineage.build.vendor_security_patch=2021-05-01
	
# Security patch level
PRODUCT_PROPERTY_OVERRIDES += \
    ro.build.version.security_patch=2021-05-01
