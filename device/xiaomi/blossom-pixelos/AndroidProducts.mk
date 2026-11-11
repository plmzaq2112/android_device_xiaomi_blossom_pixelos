#
# PixelOS product entry for blossom.
#
# The build system reads every AndroidProducts.mk found under device/ and
# vendor/, so this file makes "custom_blossom" available even though the
# upstream device tree only declares lineage_blossom.
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/custom_blossom.mk

COMMON_LUNCH_CHOICES := \
    custom_blossom-userdebug \
    custom_blossom-user
