LOCAL_PATH := $(call my-dir)

LIB_PATH := $(PREFIX)/lib
INCLUDE_PATH := $(PREFIX)/include
ANDROID_LIB_DIR := ../libs/$(TARGET_ARCH_ABI)

include $(CLEAR_VARS)
LOCAL_MODULE    := libusb-1.0
LOCAL_SRC_FILES := $(LIB_PATH)/libusb-1.0.so
include $(PREBUILT_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE    := libftdi1
LOCAL_SRC_FILES := $(LIB_PATH)/libftdi1.so
include $(PREBUILT_SHARED_LIBRARY)


