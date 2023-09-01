# PXME

It is a script to redirect all traffic of an app via a proxy.

## Features:

- It supports TCP and UDP redirecting
- UDP is redirected only when the proxy supports it ( https://gost.run proxies do)
- compatible with https://gost.run proxies.
- No DNS leaks - a local recursive caching DNS server that sends DNS via the proxy.

## Prerequisites

- `unbound` binary ( with its daemon stopped )
- `firejail` (  with `network yes` in `/etc/firejail/firejail.config` )
- `gost` ( saved as `/usr/local/bin/gost3` binary  from https://gost.run )

## Usage:


On Proxy server:

```
gost3 -L 'socks5://User:Password@:2325?udp=true&bind=true' 2>&1
```

On Desktop PC:

```
./pxme socks5://User:Password@116.202.103.247:2325 google-chrome 2ip.io
```

## Results

- Twilio Network Test

![](https://raw.githubusercontent.com/ezbik/scripts/master/pxme/results/twilio.png)

