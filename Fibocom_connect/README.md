
# Fibocom L860-GL connect script (NCM, Linux)

The script

- runs on Linux / Ubuntu.
- handles Fibocom L860-GL in NCM mode.

It allows:

- getting info about the modem
- bringing the modem online
- setting 3g/4g/auto Net mode
- resetting WAN IP
- reading/sending SMS
- rebooting the modem

### Install prerequisites:

```
sudo apt -y install libdevice-gsm-perl libdevice-modem-perl python3-pip jq curl bc tofrodos iproute2 gammu
sudo pip3 install yq
```

Disable & stop ModemManager to avoid conflicts of what controls the hardware

```
sudo systemctl disable --now ModemManager
```



### Copy the files

```
mkdir -p /usr/local/lib/
curl -L https://raw.githubusercontent.com/ezbik/scripts/master/Fibocom_connect/Fibocom_L860_hlp.sh -o /usr/local/bin/Fibocom_L860_hlp.sh
curl -L https://raw.githubusercontent.com/ezbik/scripts/master/Fibocom_connect/sendat.pl -o /usr/local/bin/sendat.pl
curl -L https://raw.githubusercontent.com/ezbik/scripts/master/list_sms.pl  -o /usr/local/lib/list_sms.pl
chmod 755 /usr/local/bin/Fibocom_L860_hlp.sh /usr/local/bin/sendat.pl /usr/local/lib/list_sms.pl
```

### Set proper APN 

.. in the script's foot (the `WAN_APN` variable)

Detect 1st WWAN interface of the Fibocom modem. E.g. `eth2`, and 

### Bring it online:

```
sudo Fibocom_L860_hlp.sh eth2 data_on
```

### Other actions

Run the script without parameters  for the usage manual.


## Changelog

* 2024-02-02, make it possible to connect after reboot

