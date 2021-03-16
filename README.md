
# android_usb_ftdi
Automatic **libusb** and **libftdi** build script for Android (**5.x-10.x Android** version supported)

>Tested on: 
- Samsung S9 with Android 10
- Asus Zenpad 8.0 Z380KL with Android 6

## Based on patched libusb and libftdi
- libusb: https://github.com/vianney/libusb
- libftdi: https://github.com/mitchellkline/libftdi

## Requirements
Install recent **Android Native Development Kit (NDK)**, tested with: **21.1.6352462** 

Set your NDK path in **build_android_usb.sh**

Example: `export NDK=$HOME/Android/Sdk/ndk/21.1.6352462`

## Build
- for `armv7a` (32-bit) architecture run: `./build_android_usb.sh` arm32
- for `armv8` (64-bit) architecture run: `./build_android_usb.sh` arm64 
- **arm32** (armv7a ) is default option
- cross compiled libraries are in `android_libs/armv7a_32` or `android_libs/armv8_64`

## How to use it
How to use libftdi with C++ and Qt5 on Android - fragments from **how_to_use.txt**
> Add  shared libs records to *.pro file
```
contains(ANDROID_TARGET_ARCH,armeabi-v7a) {
	ANDROID_EXTRA_LIBS = \
		$$PWD/lib/armv7a_32/libusb-1.0.so \
		$$PWD/lib/armv7a_32/libftdi1.so
		LIBS += -L$$PWD/lib/armv7a_32/ -lftdi1
}

contains(ANDROID_TARGET_ARCH,arm64-v8a) {
	ANDROID_EXTRA_LIBS = \
		$$PWD/lib/armv8_64/libusb-1.0.so \
		$$PWD/lib/armv8_64/libftdi1.so
		LIBS += -L$$PWD/lib/armv8_64/ -lftdi1
}
```
> Set device filter: YOUR_PROJECT/android/res/xml/device_filter.xml
```
<?xml version="1.0" encoding="utf-8"?>
<resources>
	<!-- FTDI Chips -->
	<usb-device vendor-id="1027" product-id="24577"/>
	<usb-device vendor-id="1027" product-id="24596"/>
	<usb-device vendor-id="1027" product-id="24597"/>
</resources>
```
> You need obtain descriptor (fd) and device name first

```
int32_t get_usb_fd(QString &thisFtdiDev){

	int32_t i;
	jint fd, vendorid, productid;

	QAndroidJniObject usbName, usbDevice;
	// Get the current main activity of the application.
	QAndroidJniObject activity = QtAndroid::androidActivity();
	QAndroidJniObject usb_service = QAndroidJniObject::fromString(USB_SERVICE);
	// Get UsbManager from activity
	QAndroidJniObject usbManager = activity.callObjectMethod("getSystemService", "(Ljava/lang/String;)Ljava/lang/Object;", usb_service.object());
	// Get a HashMap<Name, UsbDevice> of all USB devices attached to Android
	QAndroidJniObject deviceMap = usbManager.callObjectMethod("getDeviceList", "()Ljava/util/HashMap;");

	jint num_devices = deviceMap.callMethod<jint>("size", "()I");
	if (num_devices == 0) {
	    // No USB device is attached.
	    return -1;
	}

	// Iterate over all the devices and find the first available FTDI device.
	QAndroidJniObject keySet = deviceMap.callObjectMethod("keySet", "()Ljava/util/Set;");
	QAndroidJniObject iterator = keySet.callObjectMethod("iterator", "()Ljava/util/Iterator;");

	for (i = 0; i < num_devices; i++) {
	     usbName = iterator.callObjectMethod("next", "()Ljava/lang/Object;");
	     usbDevice = deviceMap.callObjectMethod ("get", "(Ljava/lang/Object;)Ljava/lang/Object;", usbName.object());

	    vendorid = usbDevice.callMethod<jint>("getVendorId", "()I");
	    productid = usbDevice.callMethod<jint>("getProductId", "()I");

	    if(vendorid == CONST_FTDI_VID && (productid == CONST_FTDI_PID_H || productid == CONST_FTDI_PID_R || productid == CONST_FTDI_PID_X) ){ // Found a FTDI device - create USBInterface instance and break
	    usbInterface = usbDevice.callObjectMethod("getInterface", "(I)Landroid/hardware/usb/UsbInterface;",i);
	    thisFtdiDev = usbName.toString(); // Set usb device name ...
	    break;
	    }
	}
	if (i == num_devices) {
	    // No ftdi device found.
            return -2;
	}

	jboolean hasPermission = usbManager.callMethod<jboolean>("hasPermission", "(Landroid/hardware/usb/UsbDevice;)Z", usbDevice.object());

	if (!hasPermission) {
	    // You do not have permission to use the usbDevice.
	    // Please remove and reinsert the USB device.
	    // Could also give an dialogbox asking for permission.
	    return -3;
	}
	// An FTDI device is present and we also have permission to use the device.
	// Open the device and get its file descriptor.

	usbDeviceConnection = usbManager.callObjectMethod("openDevice", "(Landroid/hardware/usb/UsbDevice;)Landroid/hardware/usb/UsbDeviceConnection;", usbDevice.object());

	if (usbDeviceConnection.object() == NULL) {
	   // Some error occurred while opening the device. Exit.
	   return -4;
	}

	// Finally get the required file descriptor.
	fd = usbDeviceConnection.callMethod<jint>("getFileDescriptor", "()I");
	
	if (fd == -1) {
	   // The device is not opened. Some error.
	   return -4;
	}

      return fd;
}
```
> FTDI init function (use previous descriptor fd and thisFtdiDev as parameters)
>  ftdiInit(fd,thisFtdiDev.toStdString().c_str());
```
// ftdiInit function - init of FTDI resources (UART)

int32_t ftdiInit(const int32_t fd,const char *devName){
	
	 int32_t f_d=-1;
	// Allocate and initialize a new ftdi_context ...

	if ((ftdi = ftdi_new()) == 0){
	    cout << "ftdi_new failed" << endl;
	    return CONST_FTDI_NEW_FAILED;
	}
	
	ftdi_set_interface(ftdi, INTERFACE_ANY);
	
	// Open interface - ftdi_set_interface ...
	if((f_d = ftdi_usb_open2(ftdi,devName,fd)) < 0){
	    cout << "Unable to open device with name: " <<devName<<endl;
	    ftdi=0;
	    return CONST_FTDI_UNABLE_OPEN;
	}

	// Set baudrate
	if((f_d = ftdi_set_baudrate(ftdi, baudrate)) < 0){
	    cout << "Unable to set baudrate:"<< f_d << endl << "(" << ftdi_get_error_string(ftdi) <<")"<< endl;
	    return CONST_FTDI_UNABLE_SET_BAUDARETE;
	}

	// Set line parameters (default STOP_BIT_1 == 0, parity NONE == 0 )
	if((f_d = ftdi_set_line_property(ftdi, BITS_8, STOP_BIT_1, NONE)) < 0){
	    cout << "Unable to set line parameters:"<< f_d << endl << "(" << ftdi_get_error_string(ftdi) <<")"<< endl;
	    return CONST_FTDI_UNABLE_SET_LINE;
	}

	// Configure write buffer chunk size, Default is 4096.
	if((f_d = ftdi_write_data_set_chunksize(ftdi,4096 )) < 0){
	   cout << "Unable to set write buffer chunk size parameter:"<< f_d << endl << "(" << ftdi_get_error_string(ftdi) <<")"<< endl;
	   return CONST_FTDI_UNABLE_SET_WRITE_CHUNK_SIZE;
	}

	// Configure read buffer chunk size, Default is 4096.
	if((f_d = ftdi_read_data_set_chunksize(ftdi,4096 )) < 0){
	    cout << "Unable to set read buffer chunk size parameter:"<< f_d << endl << "(" << ftdi_get_error_string(ftdi) <<")"<< endl;
	    return CONST_FTDI_UNABLE_SET_READ_CHUNK_SIZE;
	}

	// Set latency timer, the FTDI chip keeps data in the internal buffer for a specific amount of time if the buffer is not full yet to decrease load on the usb bus.
	
	if((f_d = ftdi_set_latency_timer(ftdi,16)) < 0){
	    cout << "Unable to set latency timer parameter:"<< f_d << endl << "(" << ftdi_get_error_string(ftdi) <<")"<< endl;
	    return CONST_FTDI_UNABLE_SET_LATENCY_TIMER;
	}

	return CONST_FTDI_OK;
}
```
> Close USB connection finally ...
```
if(fd > 0){	
	jboolean release=usbDeviceConnection.callMethod<jboolean>("releaseInterface", "(Landroid/hardware/usb/UsbInterface;)Z",usbInterface.object());
	Q_UNUSED(release);
	usbDeviceConnection.callMethod<void>("close");
}
```
