
# usbtree


### What for

- Returns YAML of all usb devices.
- Designed mainly for checking statuses of 4G modems.


also check

-  https://github.com/tuna-f1sh/cyme
- https://kellyjonbrazil.github.io/jc/docs/parsers/lsusb

### Prereqs:

find, lsusb, grep, udevadm.

### How to run

`usbtree [USB_ID]`

Where

- USB_ID is like 5-1.7.2

USB_ID is optional.


Full Output, when is run without options:

```
-
  USB_ID: 5-1
  busnum: "005"
  devnum: "002"
  manufacturer:
  product: USB 2.0 Hub [MTT]
  vendorID_productID: 1a40:0201
  hub: true
-
  USB_ID: 5-1.1
  busnum: "005"
  devnum: "003"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.2
  busnum: "005"
  devnum: "004"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.3
  busnum: "005"
  devnum: "005"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.4
  busnum: "005"
  devnum: "006"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.6
  busnum: "005"
  devnum: "045"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.6.1
  busnum: "005"
  devnum: "082"
  manufacturer: ZXIC,Incorporated
  product: ZXIC Mobile Boardband
  vendorID_productID: 19d2:0536
  hub: false
  ID_VENDOR_FROM_DATABASE: ZTE WCDMA Technologies MSM
  num_ports: 7
  ports:
   -
    KERNELS: 5-1.6.1:1.0
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.0
    driver: cdc_ether
    interface: CDC Ethernet Control Model (ECM)
    net: modem367
   -
    KERNELS: 5-1.6.1:1.1
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.1
    driver: cdc_ether
    interface: CDC Ethernet Data
   -
    KERNELS: 5-1.6.1:1.2
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.2
    driver:
   -
    KERNELS: 5-1.6.1:1.3
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.3
    driver:
   -
    KERNELS: 5-1.6.1:1.4
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.4
    driver:
   -
    KERNELS: 5-1.6.1:1.5
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.5
    driver: usbfs
    ADB: true
   -
    KERNELS: 5-1.6.1:1.6
    PORT_PATH: /sys/bus/usb/devices/5-1.6.1/5-1.6.1:1.6
    driver: usb-storage
    interface: Mass Storage
    BLOCK_DEVS:
     sr2: { BLOCK: ZXIC_USB_SCSI_CD-ROM_2.3_1234567890ABCDEF-0:0 } 
    SCSI_DEVS:
     sg2: { SCSI:  }
-
  USB_ID: 5-1.7
  busnum: "005"
  devnum: "106"
  manufacturer:
  product: USB 2.0 Hub
  vendorID_productID: 1a40:0101
  hub: true
-
  USB_ID: 5-1.7.1
  busnum: "005"
  devnum: "049"
  manufacturer: ZXIC,Incorporated
  product: ZXIC Mobile Boardband
  vendorID_productID: 19d2:0536
  hub: false
  ID_VENDOR_FROM_DATABASE: ZTE WCDMA Technologies MSM
  num_ports: 7
  ports:
   -
    KERNELS: 5-1.7.1:1.0
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.0
    driver: cdc_ether
    interface: CDC Ethernet Control Model (ECM)
    net: modem440
   -
    KERNELS: 5-1.7.1:1.1
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.1
    driver: cdc_ether
    interface: CDC Ethernet Data
   -
    KERNELS: 5-1.7.1:1.2
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.2
    driver:
   -
    KERNELS: 5-1.7.1:1.3
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.3
    driver:
   -
    KERNELS: 5-1.7.1:1.4
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.4
    driver:
   -
    KERNELS: 5-1.7.1:1.5
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.5
    driver: usbfs
    ADB: true
   -
    KERNELS: 5-1.7.1:1.6
    PORT_PATH: /sys/bus/usb/devices/5-1.7.1/5-1.7.1:1.6
    driver: usb-storage
    interface: Mass Storage
    BLOCK_DEVS:
     sr0: { BLOCK: ZXIC_USB_SCSI_CD-ROM_2.3_1234567890ABCDEF-0:0 } 
    SCSI_DEVS:
     sg0: { SCSI:  }
-
  USB_ID: 5-1.7.2
  busnum: "005"
  devnum: "081"
  manufacturer: ZXIC,Incorporated
  product: ZXIC Mobile Boardband
  vendorID_productID: 19d2:0536
  hub: false
  ID_VENDOR_FROM_DATABASE: ZTE WCDMA Technologies MSM
  num_ports: 7
  ports:
   -
    KERNELS: 5-1.7.2:1.0
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.0
    driver: cdc_ether
    interface: CDC Ethernet Control Model (ECM)
    net: modem449
   -
    KERNELS: 5-1.7.2:1.1
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.1
    driver: cdc_ether
    interface: CDC Ethernet Data
   -
    KERNELS: 5-1.7.2:1.2
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.2
    driver:
   -
    KERNELS: 5-1.7.2:1.3
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.3
    driver:
   -
    KERNELS: 5-1.7.2:1.4
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.4
    driver:
   -
    KERNELS: 5-1.7.2:1.5
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.5
    driver: usbfs
    ADB: true
   -
    KERNELS: 5-1.7.2:1.6
    PORT_PATH: /sys/bus/usb/devices/5-1.7.2/5-1.7.2:1.6
    driver: usb-storage
    interface: Mass Storage
    BLOCK_DEVS:
     sr1: { BLOCK: ZXIC_USB_SCSI_CD-ROM_2.3_1234567890ABCDEF-0:0 } 
    SCSI_DEVS:
     sg1: { SCSI:  }
```
