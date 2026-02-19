#!/bin/sh
PACKAGES="
    luci-app-https-dns-proxy
    luci-app-sqm
    luci-app-nlbwmon
    openssh-sftp-server
    ca-certificates
    fish
    git
    nano
    gzip
    zerotier
    wget
    unzip
"
opkg update 
opkg install $PACKAGES 

wget --no-check-certificate -O /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/24.10/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
opkg install /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
rm /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
service rpcd reload

#--dpi-desync=fake --dpi-desync-ttl=3

