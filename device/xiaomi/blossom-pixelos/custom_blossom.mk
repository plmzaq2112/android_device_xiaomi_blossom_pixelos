#
# PixelOS product definition for the Xiaomi blossom family.
#
# This file intentionally lives outside device/xiaomi/blossom so that the
# upstream crDroid device tree stays untouched (upstream keeps
# lineage_blossom.mk). BoardConfig.mk is still resolved from
# device/xiaomi/blossom because PRODUCT_DEVICE is "blossom".
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/non_ab_device.mk)

# Inherit from the upstream device makefile.
$(call inherit-product, device/xiaomi/blossom/device.mk)

# Inherit common PixelOS configuration (this also pulls vendor/lineage).
$(call inherit-product, vendor/custom/config/common_full_phone.mk)

# Low-RAM device: keep scudo disabled as upstream does.
PRODUCT_DISABLE_SCUDO := true

# 720p panel, used by bootanimation/common config.
scr_resolution := 720

PRODUCT_NAME := custom_blossom
PRODUCT_DEVICE := blossom
PRODUCT_MANUFACTURER := Xiaomi
PRODUCT_BRAND := Redmi
# PRODUCT_MODEL intentionally unset: blossom is a unified device tree.

PRODUCT_GMS_CLIENTID_BASE := android-xiaomi

PRODUCT_BUILD_PROP_OVERRIDES += \
    BuildFingerprint=google/blossom/blossom:17/CP2A.260105.004.E1/14587043:user/release-keys
