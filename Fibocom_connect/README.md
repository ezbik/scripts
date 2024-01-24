
# Fibocom L860-GL connect script

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
sudo apt -y install libdevice-gsm-perl libdevice-modem-perl python3-pip jq curl bc tofrodos
sudo pip3 install yq
```

Disable & stop ModemManager to avoid conflicts of what controls the hardware

```
sudo systemctl disable --now ModemManager
```



### Copy the files

```
cd /usr/local/bin/
curl -OL https://raw.githubusercontent.com/ezbik/scripts/master/Fibocom_connect/Fibocom_L860_hlp.sh
curl -OL https://raw.githubusercontent.com/ezbik/scripts/master/Fibocom_connect/sendat.pl
chmod 755 Fibocom_L860_hlp.sh sendat.pl 
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

