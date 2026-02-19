#!/bin/sh
opkg update 
opkg install luci-app-sqm luci-app-nlbwmon openssh-sftp-server ca-certificates fish nano zerotier wget unzip

wget --no-check-certificate -O /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk https://github.com/gSpotx2f/packages-openwrt/raw/master/24.10/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
opkg install /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
rm /tmp/luci-app-cpu-status-mini_0.2.0-r1_all.ipk
service rpcd reload

# luci-app-https-dns-proxy
#--dpi-desync=fake --dpi-desync-ttl=3


