# wrt

#Openwrt install Script
opkg update
opkg install wget unzip
wget -O - https://raw.githubusercontent.com/oguzozmen/wrt/refs/heads/main/install.sh | sh
