#!/bin/bash
# ----------------------------------------------------------
# Android crossbuild - libusb1.0 and libftdi
# Pavel Fiala@2015 - 2016
#----------------------------------------------------------

# Exit immediately if a command exits with a non-zero status
set -e

# LIBRARY type  - STATIC or SHARED
# --------------------------------

LIB_TYPE="LIB_SHARED"
LIB_DEFAULT_CONFIG_REMOVE="YES"
ANDROID_LOLLIPOP_5_PLUS="YES"

# LIB_TYPE="LIB_STATIC"

if [ "$LIB_TYPE" != "LIB_STATIC" ] && [ "$LIB_TYPE" != "LIB_SHARED" ]; then
   echo "LIB_SHARED or LIB_STATIC option must be selected - exiting ..."
   exit 
fi

# Build architecure (old default was 21; using 23 now)
# ----------------------------------------------------
ANDROID_PLATFORM="android-23"

ARCH="arm"
QT_ARCH="armv7"
BUILDCHAIN=arm-linux-androideabi
export TARGET_ARCH_ABI=armeabi-v7a
 
# x86 architecture / preliminary support only
# ------------------------------------------- 
# ARCH="x86"
# QT_ARCH="x86"
# BUILDCHAIN=i686-linux-android
# export APP_ABI=x86

# Tools version (change if necessary)
# -----------------------------------

LIBUSB_VERSION=1.0.19
LIBFTDI1_VERSION=1.2

# Set the path to android ndk and sdk (change if necessary)
# ---------------------------------------------------------
# Old tested NDK was r10c; new is r12
# export ANDROID_NDK_ROOT=$HOME/android/android-ndk-r10c	
# ---------------------------------------------------------

export ANDROID_NDK_ROOT=$HOME/android/android-ndk-r12
export ANDROID_SDK_ROOT=$HOME/android/android-sdk-linux

# Set Qt5 path (change if necessary - for future use)
# ---------------------------------------------------

export QT5_ANDROID=$HOME/Qt5.5.0/5.5/
# export QT5_ANDROID=$HOME/android/Qt/5.4/

export QT5_ANDROID_BIN=${QT5_ANDROID}/android_${QT_ARCH}/bin

# Create android_libs directory ...
# ---------------------------------
mkdir -p android_libs/include 

# Change directory to crossbuild
# ------------------------------

pushd crossbuild

# Initialise cross toolchain
# Contains a copy of the android-$ANDROID_PLATFORM/arch-arm sysroot, and of the toolchain binaries
# URL: http://www.kandroid.org/ndk/docs/STANDALONE-TOOLCHAIN.html
# ------------------------------------------------------------------------------------------------

if [ ! -e ndk-$ARCH ] ; then
        $ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --arch=$ARCH --install-dir=ndk-$ARCH --platform=$ANDROID_PLATFORM
fi

# Declare necessary variables for cross compilation
# ------------------------------------------------

export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-$ARCH/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-$ARCH/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export CC=${BUILDCHAIN}-gcc
export CXX=${BUILDCHAIN}-g++
export AR=${BUILDCHAIN}-ar


echo "Start of building - libusb and libftdi for android..."
echo "-----------------------------------------------------"

# Download and extract libftdi 
# ----------------------------

if [ ! -e libusb-${LIBUSB_VERSION}.tar.bz2 ] ; then
        wget http://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-${LIBUSB_VERSION}/libusb-${LIBUSB_VERSION}.tar.bz2
fi

if [ ! -e libusb-${LIBUSB_VERSION} ] ; then
        tar -xvjf libusb-${LIBUSB_VERSION}.tar.bz2
	pushd libusb-${LIBUSB_VERSION} 
	
	# copy libusb paches ...
	# ----------------------
	cp $BUILDROOT/patches/libusb/0001-Modifications-for-android-permissions.patch $BUILDROOT/libusb-${LIBUSB_VERSION}
 	cp $BUILDROOT/patches/libusb/0002-Remove-c-flag-from-LIBS.patch $BUILDROOT/libusb-${LIBUSB_VERSION}
	cp $BUILDROOT/patches/libusb/0003-usb-patch-versioning-disable.patch $BUILDROOT/libusb-${LIBUSB_VERSION}
	cp $BUILDROOT/patches/libusb/0004-usb-patch-android-lollipop-5.patch $BUILDROOT/libusb-${LIBUSB_VERSION}

	# apply libusb patches ...
	# ------------------------
	patch -p1 < 0001-Modifications-for-android-permissions.patch 
	patch -p1 < 0002-Remove-c-flag-from-LIBS.patch 
	patch -p1 < 0003-usb-patch-versioning-disable.patch

if [ "$ANDROID_LOLLIPOP_5_PLUS" == "YES" ]; then
	# https://github.com/libusb/libusb/commit/34d03254b7910ca0fc3b121b8eefb31fe44388e8
        echo "Patching libusb for Android 5+(lollipop) support [SE Linux workaround] ..." 
        patch -p1 < 0004-usb-patch-android-lollipop-5.patch
fi

	popd
fi

if [ ! -e libftdi1-${LIBFTDI1_VERSION}.tar.bz2 ]; then
        wget http://www.intra2net.com/en/developer/libftdi/download/libftdi1-${LIBFTDI1_VERSION}.tar.bz2
fi

if [ ! -e libftdi1-${LIBFTDI1_VERSION} ]; then
        tar -xvjf libftdi1-${LIBFTDI1_VERSION}.tar.bz2
        pushd libftdi1-${LIBFTDI1_VERSION} 

        # copy libftdi patches ...
        # ------------------------
if (( $(bc <<< "$LIBFTDI1_VERSION <= 1.1") )); then
	cp $BUILDROOT/patches/libftdi/0002-Disable-build-tests.patch  $BUILDROOT/libftdi1-${LIBFTDI1_VERSION}
fi
	# cp $BUILDROOT/patches/libftdi/0002-Disable-build-tests.patch  $BUILDROOT/libftdi1-${LIBFTDI1_VERSION}
	cp $BUILDROOT/patches/libftdi/0001-Added-functions-for-open-using-USB-file-descriptor.patch  $BUILDROOT/libftdi1-${LIBFTDI1_VERSION}
	cp $BUILDROOT/patches/libftdi/0003-ftdi-patch-versioning-disable.patch  $BUILDROOT/libftdi1-${LIBFTDI1_VERSION}

        # apply libftdi patches ...
        # -------------------------
if (( $(bc <<< "$LIBFTDI1_VERSION <= 1.1") )); then
	patch -p1 < 0002-Disable-build-tests.patch
fi
	# patch -p1 < 0002-Disable-build-tests.patch
	patch -p1 < 0001-Added-functions-for-open-using-USB-file-descriptor.patch
	patch -p1 < 0003-ftdi-patch-versioning-disable.patch

        popd
fi

if [ ! -e libftdispi.tar.bz2 ]; then
        cp $BUILDROOT/backup/libftdispi.tar.bz2 $BUILDROOT
fi

if [ ! -e libftdispi ]; then
         tar -xvjf libftdispi.tar.bz2
fi	

if [ ! -e libmpsse.tar.bz2 ]; then
        cp $BUILDROOT/backup/libmpsse.tar.bz2 $BUILDROOT
fi

if [ ! -e libmpsse ]; then
        tar -xvjf libmpsse.tar.bz2

	pushd libmpsse
        
        # copy libmpsse patches ...
        # -------------------------
        cp $BUILDROOT/patches/libmpsse/0001-libmpsse-android-descriptor-fd.patch  $BUILDROOT/libmpsse
        
        # apply libmpsse patches ...
        # -------------------------
        patch -p1 < 0001-libmpsse-android-descriptor-fd.patch 
        
        popd

fi

# Build of libusb 
# ---------------

mkdir -vp build

if [ "$LIB_DEFAULT_CONFIG_REMOVE" == "YES" ]; then
       echo "Removing default generated config - configure file ..." 
       rm libusb-${LIBUSB_VERSION}/configure 
fi

if [ ! -e libusb-${LIBUSB_VERSION}/configure ] ; then
       pushd libusb-${LIBUSB_VERSION}
       mkdir -vp m4
       autoreconf -i 
       popd
fi

# ANDROIDi mod Linux - does not support udev ...[ --disable-udev option is neccesary] 
# -----------------------------------------------------------------------------------

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
	  ../../libusb-${LIBUSB_VERSION}/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --enable-static --disable-shared --disable-udev
       fi
       
       if [ "$LIB_TYPE" == "LIB_SHARED" ]; then
         ../../libusb-${LIBUSB_VERSION}/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --disable-udev
       fi

      make
      make install
      popd

      # Patch libusb-1.0.pc due to bug in there
      # Fix comming in 1.0.20
      sed -ie 's/Libs.private: -c/Libs.private: /' $PKG_CONFIG_PATH/libusb-1.0.pc
fi

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

#   - Static LIBRARY - 
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

# Build of libftdispi (simple makefile)
# -------------------------------------

pushd libftdispi

make clean
make

popd

# Build of libmpsse library
# -------------------------

pushd libmpsse/src

# http://www.uclibc.org/FAQ.html#gnu_malloc warning workaround ... 
# ----------------------------------------------------------------
export ac_cv_func_malloc_0_nonnull=yes
export ac_cv_func_realloc_0_nonnull=yes

./configure --host=${BUILDCHAIN} --prefix=${PREFIX} --disable-python

make clean

make
make install

popd

popd # from crossbuild

if [ -e android_libs/libusb-1.0.so ] ; then
    rm android_libs/libusb-1.0.so	
fi

if [ -e android_libs/libftdi1.so ] ; then
    rm android_libs/libftdi1.so
fi

if [ -e android_libs/libftdispi.so ] ; then
    rm android_libs/libftdispi.so
fi

if [ -e android_libs/libmpsse.so ] ; then
    rm android_libs/libmpsse.so
fi

cp ${PREFIX}/lib/libusb-1.0.so $PWD/android_libs
cp ${PREFIX}/lib/libftdi1.so $PWD/android_libs
cp ${BUILDROOT}/libftdispi/libftdispi.so $PWD/android_libs
cp ${PREFIX}/lib/libmpsse.so $PWD/android_libs

cp -u ${PREFIX}/include/libusb-1.0/libusb.h $PWD/android_libs/include
cp -u ${PREFIX}/include/libftdi1/ftdi.h $PWD/android_libs/include
cp -u ${BUILDROOT}/libftdispi/src/ftdispi.h $PWD/android_libs/include
cp -u ${PREFIX}/include/mpsse.h  $PWD/android_libs/include

if [[ $? == 0 ]] ; then 
   echo "Finished building - libusb and libftdi for android ready ..."
   echo "------------------------------------------------------------"
fi

# Clean finally ...
# -----------------
rm crossbuild/*.tar.bz2
rm -rf crossbuild/build
rm -rf crossbuild/libftdi1-1.2
rm -rf crossbuild/libftdispi
rm -rf crossbuild/libmpsse
rm -rf crossbuild/libusb-1.0.19

# Build native libraries (not needed)
# -----------------------------------
# $ANDROID_NDK_ROOT/ndk-build -B

# Update application if build.xml is not present (not needed)
# -----------------------------------------------------------

# if [ ! -e build.xml ] ; then
#        $HOME/android/android-sdk-linux/tools/android update project -p  .
# fi

# ------------------------------------------------------------------------
# PATCH create : diff -crB a b > patch_versioning.patch { a b - directories}
# PATCH apply : patch -p1 < patch_versioning.patch

# HEX edit with SED: sed 's/libusb-1.0.so.0/libusb-1.0.so\x00\x00/g' libftdi1.so > /home/pavelf/libftdi1.so 
# HEX edit also possible with great KDE APP OKTETA
