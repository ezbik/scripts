
install prerequisites:

```
sudo apt -y install libdevice-gsm-perl libdevice-modem-perl python3-pip jq
sudo pip3 install yq
```

Copy the files

```
sudo cp ./sendat.pl ./Fibocom_L860_hlp.sh /usr/local/bin/
```


Detect 1st WWAN interface of the Fibocom modem. E.g. `eth2`, and bring it online:

```
sudo Fibocom_L860_hlp.sh eth2data_on
```
