
# Fibocom L860-GL connect script

The script allows:

- bringing the modem online
- setting 3g/4g/auto Net mode
- resetting WAN IP
- reading/sending SMS

### Install prerequisites:

```
sudo apt -y install libdevice-gsm-perl libdevice-modem-perl python3-pip jq
sudo pip3 install yq
```

### Copy the files

```
sudo cp ./sendat.pl ./Fibocom_L860_hlp.sh /usr/local/bin/
```

### Set proper APN 

.. in the script's foot (the `WAN_APN` variable)

Detect 1st WWAN interface of the Fibocom modem. E.g. `eth2`, and 

### Bring it online:

```
sudo Fibocom_L860_hlp.sh eth2 data_on
```
