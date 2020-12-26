Libftdi for android
====================

Libftdi is a library that is useful for communication with ftdi chipsets.
Libftdi uses libusb internally for all its usb communication. Hence, to enable
its usage on android, it is essential that libusb works on android. The patches
for enabling libusb usage on android can be found in libusb folder.
Now, that libusb works on android, the only task left is to use this modified
API for android for communication when on android rather than the original one.
This is implemented with the added patches.

Patches
-------
0001-Added-functions-for-open-using-USB-file-descriptor.patch

The function ftdi_usb_open_fd is implemented in this patch which should be used
on android while communicating with ftdi devices on android. Along with ftdi
context and ftdi device, the file descriptor obtained from android API's
should also be passed.
Internally, it uses libusb_open_fd to get a libusb_device_handle.
This patch can also be found in branch android-fd of my github repository.[1]

Dependency
----------
This library depends on libusb-1.0.19 patched for android. The libusb patches
are present in folder libusb. The patched library provides necessary
libusb_open_fd function required for proper functioning on android.

Upstream status
----------------
As functioning of this library on android depends upon presence of patched
libusb, this has not been sent to libftdi developers. This could be done once
libusb patches are upstream.

Usage
-----
The usage of libftdi remains unchanged. The only difference would be, on
android, ftdi_usb_open functions would also pass file descriptors. These are
listed below.

1. ftdi_usb_open_fd() instead of ftdi_usb_open()
2. ftdi_usb_open_fd_dev() instead of ftdi_usb_open_dev()
3. ftdi_usb_open_fd_desc() instead of ftdi_usb_open_desc()
4. ftdi_usb_open_fd_desc_index() instead of ftdi_usb_open_desc_index()

Instead of the usual arguments, also add the usb file descriptors as the last
argument.

