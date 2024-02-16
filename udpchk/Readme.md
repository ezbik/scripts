
## Socks5 Proxy UDP checking scripts

Based on https://github.com/semigodking/socks5chk/tree/master

### udpchk.py

Sends a UDP packet to a server IP  (via UDP-capable Socks5 proxy)

Usage:

```
python3 udpchk.py       --proxy  $HO --port $PO --user $UU --pwd $PP;
```
### udpchk_name.py

Sends a UDP packet to a server Hostname (via UDP-capable Socks5 proxy)

Usage: 

```
python3 udpchk_name.py  --proxy  $HO --port $PO --user $UU --pwd $PP;
```

### udpchk_name_dnsleak.py

Tests DNSleak on a proxy - 

1. Sends a UDP packet (via UDP-capable Socks5 proxy) to a random server Hostname; 
2. Then shows where DNS request came from


Usage: 

```
python3 udpchk_name_dnsleak.py  --proxy $HO --port $PO --user $UU --pwd $PP
```

Output:

```
= sending UDP to rr25632zz37530.dnsleaktest.tanatos.org
= sent
= requesting info - who actually queried the hostname rr25632zz37530.dnsleaktest.tanatos.org
---
- IP: 172.217.33.132
  CITY: Frankfurt am Main
  COUNTRY: Germany
  NET: AS15169 Google LLC
  ISP: Google LLC
  Link: https://ifconfig.co/?ip=172.217.33.132
- IP: 173.194.96.195
  CITY: Frankfurt am Main
  COUNTRY: Germany
  NET: AS15169 Google LLC
  ISP: Google LLC
  Link: https://ifconfig.co/?ip=173.194.96.195
...
```

