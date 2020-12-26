Libusb on Android
==================

Android has restricted access to its USB port. The only way one can access USB
on android devices is via the java based API provided by android[1]. Hence using
libusb on android posed a challenge. When libusb is directly cross compiled for
android and used normally a ACCESS DENIED error is encountered. The exact error
seen is this

```
I stderr  : libusb: 0.000000 error [op_open] libusb couldn't open USB device
/dev/bus/usb/001/002: Permission denied.
I stderr  : libusb: 0.000055 error [op_open] libusb requires write access to USB
device nodes.
```

Android has a static permissions system. All the permissions required by an
application is declared in the manifest file and when loaded, these permissions
are already granted to the application. But for access of USB, there is a
difference in approach for acquiring permissions. Besides the need of
presence of declaration in the manifest file, android requires runtime
permissions from the user in order to use the USB connected devices. This adds
some complication to usage of libusb. Permissions for USB device is not already
granted to the application and hence, libusb functions cannot be used directly
in the applications.

As a fix to this situation, we can aquire the permissions to use the USB device
via the Android APIs, open the usb device and acquire its file descriptor. And
using this file descriptor, obtain a libusb_device_handle. This handle can then
be used to perform all the usual operations of libusb.

After some experimentation, it was found out that this approach works and hence
libusb is usable on android given that
a. We acquire permissions for use of USB from the user.
b. We pass the file descriptor of USB device obtained after opening it to libusb

Patches
--------

The following patches contain changes for enabling cross-building of libusb on
android and functions that would provide libusb_device_handle when file
descriptor acquired from Android API is passed.

1. Modifications for android permissions
The motive is to acquire a libusb_device_handle using the file descriptor
obtained. This patch adds a functions libusb_open_fd(struct libusb_device_handle
*handle, int fd) which should be used when working on android.

2. Remove -c flags from LIBS
Libusb upstream has a bug. `configure.ac : 126 LIBS="${LIBS} -c"`
The -c flag here ends up in libusb-1.0.pc when compiled and is then interpreted
as 'compile only don't link' flag of gcc. This caused huge ld errors during
cross compilation of libusb for android.

These patches can be applied to the master by using the following command
     `$ git am patch_name.patch`

The patches can be found in androidi-fd branch of my fork of libusb git repo. [2]

Usage
------

The usage of the libusb API on android remains almost entirely the same as
before. The only difference is in the opening of the usb device. The steps, also
mentioned above, are listed here:

1. Using the Android USB API, get permission to use the attached USB device. [3]
2. Open the USB device thereby obtaining a UsbDeviceConnection object. [4]
3. Acquire the file descriptor of the USB device. [5]
4. Using Java Native Interface, pass on this USB file descriptor to the native
backend so that it becomes accessible to libusb.
5. Using the function libusb_open_fd(libusb_dev* dev, libusb_device_handle** handle, int fd),
acquire the libusb_device_handle to the libusb_device created using the passed
file descriptor.
6. Use the libusb_device_handle to do all the usual stuff with libusb.
7. Make sure that UsbDeviceConnection is not closed until all required work is
achieved by libusb code.

Status of the patches
----------------------

In order to get libusb-android changes in libusb upstream, I have sent these
patches to libusb mailing list [6]. But I have got a negative response from the
libusb community. Even though they agree that this is an acceptable way and
would work, but they are unwilling to include this in the upstream.

"The problem is that the libusb API will then be different on Android
so may not be included in the official libusb as is."

The patch sent to remove -c flag from configure.ac as it was leading to linking
errors did not generate any responses from the community. [7]


References
------------

1. http://developer.android.com/guide/topics/connectivity/usb/host.html
2. https://github.com/venkateshshukla/libusb/commits/android-fd
3. UsbManager : requestPermission http://developer.android.com/reference/android/hardware/usb/UsbManager.html#requestPermission(android.hardware.usb.UsbDevice, android.app.PendingIntent)
4. UsbManager : openDevice http://developer.android.com/reference/android/hardware/usb/UsbManager.html#openDevice(android.hardware.usb.UsbDevice)
5. UsbDeviceConnection : getFileDescriptor http://developer.android.com/reference/android/hardware/usb/UsbDeviceConnection.html#getFileDescriptor()
6. http://sourceforge.net/p/libusb/mailman/message/32567699/
7. http://libusb.6.n5.nabble.com/libusb-PATCH-Remove-c-flag-Erroneous-output-caused-on-android-td5713396.html


