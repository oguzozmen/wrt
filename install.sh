#!/bin/sh
# OpenWrt Setup & Install Script
# Tarih: 2026-01-31

set -e

# ─────────────────────────────────────────────
# DEĞIŞKENLER
# ─────────────────────────────────────────────
PACKAGES="
    luci-app-https-dns-proxy
    luci-app-sqm
    luci-app-nlbwmon
    openssh-sftp-server
    ca-certificates
    fish
    btop
    git
    nano
    gzip
    zerotier
    wget
    unzip
"

REPO_URL="https://github.com/oguzozmen/wrt/archive/refs/heads/main.zip"
REPO_ZIP="/tmp/main.zip"
REPO_DIR="/tmp/wrt-main"
CPU_PKG="$REPO_DIR/luci-app-cpu-status-mini_0.2.0-r1_all.ipk"
ZAPRET_ZIP="$REPO_DIR/zapret-v72.9.zip"
ZAPRET_DIR="$REPO_DIR/zapret-v72.9"
BACKUP="$REPO_DIR/backup-OpenWrt-2026-02-03.tar.gz"

# ─────────────────────────────────────────────
# FONKSİYONLAR
# ─────────────────────────────────────────────
log()    { echo "[+] $1"; }
warn()   { echo "[!] $1"; }
err()    { echo "[-] $1"; exit 1; }

# ─────────────────────────────────────────────
# 1. OPKG UPDATE
# ─────────────────────────────────────────────
log "opkg güncelleniyor..."
opkg update || err "opkg update başarısız oldu."

# ─────────────────────────────────────────────
# 2. PAKET KURALLARI
# ─────────────────────────────────────────────
log "Paketler kurulyor..."
opkg install $PACKAGES || err "Paket kurulumu başarısız oldu."

# ─────────────────────────────────────────────
# 3. GITHUB REPO İNDIR & KURULUMU
# ─────────────────────────────────────────────
log "GitHub repo indiriliyor..."
cd /tmp
wget -q "$REPO_URL" -O "$REPO_ZIP" || err "Repo indirme başarısız oldu."

log "Repo unzip yapılıyor..."
unzip -o "$REPO_ZIP" || err "Unzip başarısız oldu."

# ─────────────────────────────────────────────
# 4. LuCI CPU Status Mini Kurulumu
# ─────────────────────────────────────────────
if [ -f "$CPU_PKG" ]; then
    log "luci-app-cpu-status-mini kuruluyur..."
    opkg install "$CPU_PKG" || err "cpu-status-mini kurulumu başarısız oldu."
else
    warn "cpu-status-mini paketi bulunamadı: $CPU_PKG"
fi

# ─────────────────────────────────────────────
# 5. ZAPRET KURULUMU
# ─────────────────────────────────────────────
if [ -f "$ZAPRET_ZIP" ]; then
    log "Zapret unzip yapılıyor..."
    cd $REPO_DIR
    unzip -o "$ZAPRET_ZIP" || err "Zapret unzip başarısız oldu."

    log "Zapret kuruluyur..."
    cd "$ZAPRET_DIR"

    ./install_prereq.sh || warn "install_prereq.sh bulunamadı."
    ./install_bin.sh    || warn "install_bin.sh bulunamadı."
    ./install_easy.sh   || warn "install_easy.sh bulunamadı."

    # Gerekirse DPI ayarı için aşağıdaki satırı yorum dışına alabilirsiniz:
    # Flags: --dpi-desync=fake --dpi-desync-ttl=3
else
    warn "Zapret zip bulunamadı: $ZAPRET_ZIP"
fi

# ─────────────────────────────────────────────
# 6. SYSUPGRADE (BACKUP RESTORE)
# ─────────────────────────────────────────────
if [ -f "$BACKUP" ]; then
    log "Backup restore yapılıyor..."
    sysupgrade -r "$BACKUP" || warn "sysupgrade -r başarısız oldu (kritik olmayabilir)."
else
    warn "Backup dosyası bulunamadı: $BACKUP"
fi

# ─────────────────────────────────────────────
# 7. TEMIZLIK & REBOOT
# ─────────────────────────────────────────────
log "Geçici dosyalar temizleniyor..."
rm -rf "$REPO_DIR" "$REPO_ZIP" "$ZAPRET_DIR" "$ZAPRET_ZIP"

log "Setup tamamlandı. Sistem yeniden başlatılıyor..."
sleep 3
reboot
