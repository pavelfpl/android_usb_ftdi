# android_usb_ftdi
Automatic libusb and libftdi build script for Android (5.x-10.x Android version supported)

# Based on patched libusb and libftdi
- libusb: https://github.com/vianney/libusb
- libftdi: https://github.com/mitchellkline/libftdi

# Requirements
Install recent Android Native Development Kit (NDK), tested with: 21.1.6352462 
Set your NDK path in build_android_usb
Example: export NDK=$HOME/Android/Sdk/ndk/21.1.6352462

# Build
- for armv7a (32-bit) architecture run: ./build_android_usb arm32 
- for armv8 (64-bit) architecture run: ./build_android_usb arm64 
- arm32 is default
- cross compiled libraries are in android_libs/armv7a_32 or android_libs/armv8_64

# How to use it
How to use libftdi with C++ and Qt5 on Android - see how_to_use.txt
