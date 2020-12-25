#!/bin/bash
# -----------------
# build_android_usb
# -----------------
# Android crossbuild - libusb1.0 and libftdi ...
# Pavel Fiala@2015 - 2020
#
# Android 5.x - 10.x supported !!!
# - armv8_64 supported
# - armv7a_32 supported
# ---------------------

# Exit immediately if a command exits with a non-zero status ...
set -e

ARCH_SELECT=$1

# LIBRARY type - SHARED (only supported now) or STATIC 
# ----------------------------------------------------
LIB_TYPE="LIB_SHARED"
LIB_DEFAULT_CONFIG_REMOVE="YES"

# LIBUSB_GIT_VERSION="YES"
# ANDROID_LOLLIPOP_5_PLUS="YES"
# LIB_TYPE="LIB_STATIC"

# Select android architecture (change if necessary - default is armv7a_32)
# ------------------------------------------------------------------------
# export ARCH="armv8_64"
# export ARCH="armv7a_32"

case "$ARCH_SELECT" in
    arm32)
        echo "Selecting armv7a (32-bit) architecture ..."
        export ARCH="armv7a_32"
        ;;
    arm64)
        echo "Selecting armv8 (64-bit) architecture ..." 
        export ARCH="armv8_64"
        ;;
    *)
        echo "Selecting armv7a (32-bit) architecture ..."
        export ARCH="armv7a_32"
        ;;
esac


# Tools version (change if necessary)
# -----------------------------------
LIBUSB_VERSION=1.0.22+GIT
LIBFTDI1_VERSION=1.3+GIT

# Set the path to android ndk and sdk (change if necessary - default )
# --------------------------------------------------------------------
export NDK=$HOME/Android/Sdk/ndk/21.1.6352462
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64

if [ "$LIB_TYPE" != "LIB_STATIC" ] && [ "$LIB_TYPE" != "LIB_SHARED" ]; then
   echo "LIB_SHARED or LIB_STATIC option must be selected - exiting ..."
   exit 
fi
 
# Change directory to crossbuild
# ------------------------------
mkdir -p crossbuild
mkdir -p android_libs/armv7a_32/include
mkdir -p android_libs/armv8_64/include

pushd crossbuild

# Declare necessary variables for cross compilation
# ------------------------------------------------

export BUILDROOT=$PWD
export PATH=${TOOLCHAIN}/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-$ARCH/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
# export LD_LIBRARY_PATH=${PREFIX}/lib

# armv8_64 ...
# ------------
if [ "$ARCH" == "armv8_64" ]; then
    export BUILDCHAIN=aarch64-linux-android
    export BUILDCHAIN_TOOLS=aarch64-linux-android
fi

# armv7a_32 ...
# -------------
if [ "$ARCH" == "armv7a_32" ]; then
    export BUILDCHAIN=armv7a-linux-androideabi
    export BUILDCHAIN_TOOLS=arm-linux-androideabi
fi
    
# Not supported now ...
# ---------------------
# export BUILDCHAIN=i686-linux-android
# export BUILDCHAIN=x86_64-linux-android

# Set this to your minSdkVersion ...
# ----------------------------------

export API=21

# Set crosscompile tools ...
# --------------------------

export AR=$TOOLCHAIN/bin/$BUILDCHAIN_TOOLS-ar
export AS=$TOOLCHAIN/bin/$BUILDCHAIN_TOOLS-as
export CC=$TOOLCHAIN/bin/$BUILDCHAIN$API-clang
export CXX=$TOOLCHAIN/bin/$BUILDCHAIN$API-clang++
export LD=$TOOLCHAIN/bin/$BUILDCHAIN_TOOLS-ld
export RANLIB=$TOOLCHAIN/bin/$BUILDCHAIN_TOOLS-ranlib
export STRIP=$TOOLCHAIN/bin/$BUILDCHAIN_TOOLS-strip

    
echo "-----------------------------------------------------"
echo "Start of building - libusb and libftdi for android..."
echo "-----------------------------------------------------"

# --------------------------------------------------
# Download and extract libusb & libftdi from GIT ... 
# --------------------------------------------------

if [ ! -e libusb-${LIBUSB_VERSION} ] ; then
    git clone -b android https://github.com/vianney/libusb libusb-${LIBUSB_VERSION}
fi

if [ ! -e libftdi1-${LIBFTDI1_VERSION} ] ; then
    git clone https://github.com/mitchellkline/libftdi libftdi1-${LIBFTDI1_VERSION}
    # Apply libftdi patches ...
	# -------------------------
	echo "Patching file: ftdi.c ... "
	cp ../0001-ftdi_libusb_patch.patch 0001-ftdi_libusb_patch.patch
	patch -p2 < 0001-ftdi_libusb_patch.patch
fi

# -------------------
# Build of libusb ...
# -------------------

mkdir -vp build

if [ "$LIB_DEFAULT_CONFIG_REMOVE" == "YES" ]; then
       echo "Removing default generated config - configure file ..." 
       # rm libusb-${LIBUSB_VERSION}/configure 
fi

if [ ! -e libusb-${LIBUSB_VERSION}/configure ] ; then
       pushd libusb-${LIBUSB_VERSION}
       mkdir -vp m4
       autoreconf -i 
       popd
fi

# ANDROID mod Linux - does not support udev ...[ --disable-udev option is neccesary for Android ] 
# -----------------------------------------------------------------------------------------------

# - Shared LIBRARY - 
# ------------------
# --disable-udev

# - Static LIBRARY - 
# ------------------
# --enable-static
# --disable-shared 
# --disable-udev


if [ ! -e $PKG_CONFIG_LIBDIR/libusb-1.0.pc ] ; then
       mkdir -p build/libusb-build-$ARCH
       pushd build/libusb-build-$ARCH
       
       if [ "$LIB_TYPE" == "LIB_STATIC" ]; then
	  ../../libusb-${LIBUSB_VERSION}/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --enable-static --disable-shared --disable-udev CFLAGS="-Wno-unused-function" 
       fi
       
       if [ "$LIB_TYPE" == "LIB_SHARED" ]; then
         ../../libusb-${LIBUSB_VERSION}/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --disable-udev CFLAGS="-Wno-unused-function" 
       fi

      make
      make install
      popd

      # Patch libusb-1.0.pc due to bug in there ...
      # -------------------------------------------
      # Fix comming in 1.0.20
      # sed -ie 's/Libs.private: -c/Libs.private: /' $PKG_CONFIG_PATH/libusb-1.0.pc
fi

# ----------------
# Build of libftdi 
# ----------------

# - Shared LIBRARY - 
# ------------------
# -DBUILD_SHARED_LIBS=ON 
# -DSTATICLIBS=OFF 
# -DPYTHON_BINDINGS=OFF 
# -DDOCUMENTATION=OFF 
# -DFTDIPP=OFF 
# -DBUILD_TESTS=OFF

# - Static LIBRARY - 
# -----------------------
# -DBUILD_SHARED_LIBS=OFF 
# -DSTATICLIBS=ON 
# -DPYTHON_BINDINGS=OFF 
# -DDOCUMENTATION=OFF 
# -DFTDIPP=OFF 
# -DBUILD_TESTS=OFF

mkdir -p build/libftdi-build-$ARCH
pushd build/libftdi-build-$ARCH

if [ ! -e Makefile ] ; then
  if [ "$LIB_TYPE" == "LIB_STATIC" ]; then
      cmake -DCMAKE_C_COMPILER=${CC} -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_PREFIX_PATH=${PREFIX} -DBUILD_SHARED_LIBS=OFF -DSTATICLIBS=ON -DPYTHON_BINDINGS=OFF -DDOCUMENTATION=OFF -DFTDIPP=OFF -DBUILD_TESTS=OFF ../../libftdi1-${LIBFTDI1_VERSION}
  fi
  
  if [ "$LIB_TYPE" == "LIB_SHARED" ]; then
      cmake -DCMAKE_C_COMPILER=${CC} -DCMAKE_INSTALL_PREFIX=${PREFIX} -DCMAKE_PREFIX_PATH=${PREFIX} -DBUILD_SHARED_LIBS=ON -DSTATICLIBS=OFF -DPYTHON_BINDINGS=OFF -DDOCUMENTATION=OFF -DFTDIPP=OFF -DBUILD_TESTS=OFF ../../libftdi1-${LIBFTDI1_VERSION}
  fi

fi
make
make install
popd
popd

cp ${PREFIX}/lib/libusb-1.0.so $PWD/android_libs/$ARCH
cp ${PREFIX}/lib/libftdi1.so $PWD/android_libs/$ARCH

cp -u ${PREFIX}/include/libusb-1.0/libusb.h $PWD/android_libs/$ARCH/include
cp -u ${PREFIX}/include/libftdi1/ftdi.h $PWD/android_libs/$ARCH/include


if [[ $? == 0 ]] ; then 
   echo "------------------------------------------------------------"
   echo "Finished building - libusb and libftdi for android ready ..."
   echo "------------------------------------------------------------"
fi

# --------------------------------------------------------------------------
# PATCH create : diff -crB a b > patch_versioning.patch { a b - directories}
# PATCH apply : patch -p1 < patch_versioning.patch
# --------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------
# HEX edit with SED: sed 's/libusb-1.0.so.0/libusb-1.0.so\x00\x00/g' libftdi1.so > /home/pavelf/libftdi1.so 
# HEX edit also possible with great KDE APP OKTETA
# ---------------------------------------------------------------------------------------------------------
