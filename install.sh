#!/bin/sh

# OpenWRT Otomatik Kurulum ve Restore Scripti
# Gereksinimler: wget ve unzip paketleri önceden yüklü olmalıdır

echo "================================================"
echo "OpenWRT Otomatik Kurulum ve Restore Scripti"
echo "================================================"
echo ""

# Hata kontrolü fonksiyonu
check_error() {
    if [ $? -eq 0 ]; then
        echo "[✓] $1 başarılı"
        return 0
    else
        echo "[✗] $1 başarısız!"
        exit 1
    fi
}

# Devam fonksiyonu
confirm_continue() {
    echo ""
    echo "----------------------------------------"
    echo "$1"
    echo "Devam etmek için Enter tuşuna basın..."
    read dummy
}

# wget ve unzip kontrolü
echo "[i] Gerekli paketler kontrol ediliyor..."
which wget > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[✗] wget paketi bulunamadı!"
    exit 1
fi
echo "[✓] wget paketi mevcut"

which unzip > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "[✗] unzip paketi bulunamadı!"
    exit 1
fi
echo "[✓] unzip paketi mevcut"

confirm_continue "Paket kontrolleri tamamlandı"

# İnternet bağlantısı kontrolü
echo ""
echo "[i] İnternet bağlantısı kontrol ediliyor..."
ping -c 2 8.8.8.8 > /dev/null 2>&1
check_error "İnternet bağlantısı"

confirm_continue "İnternet bağlantısı kontrolü tamamlandı"

# Çalışma dizinini temizle ve oluştur
echo ""
echo "[i] Çalışma dizini hazırlanıyor..."
rm -rf /tmp/install
mkdir -p /tmp/install
cd /tmp/install
check_error "Çalışma dizini oluşturma"

confirm_continue "Çalışma dizini hazırlandı"

# Paket listesini güncelle
echo ""
echo "[i] Paket listeleri güncelleniyor..."
opkg update
check_error "Paket listesi güncellemesi"

confirm_continue "Paket listeleri güncellendi"

# Ana paketleri yükle
echo ""
echo "[i] Ana paketler yükleniyor..."
opkg install \
    luci-app-https-dns-proxy \
    luci-compat \
    luci-app-adblock \
    luci-app-sqm \
    luci-app-banip \
    luci-app-nlbwmon \
    luci-app-ttyd \
    luci-app-attendedsysupgrade \
    openssh-sftp-server \
    ca-certificates \
    fish \
    btop \
    git \
    nano \
    gzip \
    zerotier
check_error "Ana paketlerin yüklenmesi"

confirm_continue "Ana paketler yüklendi"

# GitHub deposundan dosyaları indir
echo ""
echo "[i] Kurulum dosyaları indiriliyor..."
wget -O /tmp/install/wrt-main.zip https://github.com/oguzozmen/wrt/archive/refs/heads/main.zip
check_error "Kurulum dosyalarının indirilmesi"

confirm_continue "Kurulum dosyaları indirildi"

# Arşivi aç
echo ""
echo "[i] Arşiv dosyası açılıyor..."
unzip -q /tmp/install/wrt-main.zip -d /tmp/install/
check_error "Arşiv dosyasının açılması"

# Ana dizini bul
WRT_DIR="/tmp/install/wrt-main"
if [ ! -d "$WRT_DIR" ]; then
    echo "[✗] wrt-main dizini bulunamadı!"
    exit 1
fi

cd "$WRT_DIR"
echo "[✓] Çalışma dizini: $WRT_DIR"

confirm_continue "Arşiv açma işlemi tamamlandı"

# IPK dosyalarını yükle
echo ""
echo "[i] IPK paketleri yükleniyor..."
IPK_COUNT=0
for ipk in *.ipk; do
    if [ -f "$ipk" ]; then
        echo "  → $ipk yükleniyor..."
        opkg install "$ipk"
        if [ $? -eq 0 ]; then
            IPK_COUNT=$((IPK_COUNT + 1))
            echo "    ✓ $ipk yüklendi"
        else
            echo "    ! $ipk yüklenemedi (devam ediliyor)"
        fi
    fi
done

if [ $IPK_COUNT -gt 0 ]; then
    echo "[✓] Toplam $IPK_COUNT IPK paketi yüklendi"
    service rpcd reload
else
    echo "[!] Hiç IPK paketi bulunamadı"
fi

confirm_continue "IPK paket kurulumu tamamlandı"

# Zapret kurulumu
echo ""
echo "[i] Zapret DPI bypass aracı kuruluyor..."

# ZIP dosyasını bul
ZAPRET_ZIP=$(find "$WRT_DIR" -name "*.zip" -type f | head -n 1)

if [ -z "$ZAPRET_ZIP" ]; then
    echo "[✗] Zapret ZIP dosyası bulunamadı!"
    exit 1
fi

echo "  → Zapret arşivi: $ZAPRET_ZIP"

# Zapret'i aç
ZAPRET_EXTRACT_DIR="/tmp/install/zapret_extract"
mkdir -p "$ZAPRET_EXTRACT_DIR"
unzip -q "$ZAPRET_ZIP" -d "$ZAPRET_EXTRACT_DIR"
check_error "Zapret arşivinin açılması"

# Zapret klasörünü bul
ZAPRET_DIR=$(find "$ZAPRET_EXTRACT_DIR" -maxdepth 2 -type d -name "zapret-v*" | head -n 1)

if [ -z "$ZAPRET_DIR" ]; then
    echo "[✗] Zapret kurulum dizini bulunamadı!"
    exit 1
fi

echo "[✓] Zapret dizini: $ZAPRET_DIR"
cd "$ZAPRET_DIR"

confirm_continue "Zapret dosyaları hazırlandı"

# Zapret kurulum scriptlerini çalıştır
echo ""
echo "[i] Zapret ön gereksinimler yükleniyor..."
if [ -f "./install_prereq.sh" ]; then
    chmod +x ./install_prereq.sh
    ./install_prereq.sh
    check_error "Zapret ön gereksinimler"
else
    echo "[✗] install_prereq.sh bulunamadı!"
fi

confirm_continue "Zapret ön gereksinimler yüklendi"

echo ""
echo "[i] Zapret binary dosyaları yükleniyor..."
if [ -f "./install_bin.sh" ]; then
    chmod +x ./install_bin.sh
    ./install_bin.sh
    check_error "Zapret binary kurulumu"
else
    echo "[✗] install_bin.sh bulunamadı!"
fi

confirm_continue "Zapret binary dosyaları yüklendi"

# Zapret parametrelerini göster
echo ""
echo "================================================"
echo "ZAPRET DPI BYPASS PARAMETRELERİ"
echo "================================================"
echo ""
echo "Aşağıdaki parametreleri kopyalayın (Ctrl+C):"
echo ""
echo "--dpi-desync=fake --dpi-desync-ttl=3"
echo ""
echo "================================================"
echo ""
echo "Parametreleri kopyaladıktan sonra devam etmek için"
echo "Enter tuşuna basın..."
read dummy

echo "[i] Zapret yapılandırma sihirbazı başlatılıyor..."
if [ -f "./install_easy.sh" ]; then
    chmod +x ./install_easy.sh
    ./install_easy.sh
    check_error "Zapret yapılandırma"
else
    echo "[✗] install_easy.sh bulunamadı!"
fi

confirm_continue "Zapret kurulumu tamamlandı"

# Yedek dosyasını bul ve restore et
echo ""
echo "[i] Sistem yedek dosyası aranıyor..."
cd "$WRT_DIR"

BACKUP_FILE=$(find "$WRT_DIR" -name "*.tar.gz" -type f | head -n 1)

if [ -z "$BACKUP_FILE" ]; then
    echo "[!] tar.gz yedek dosyası bulunamadı, restore atlanıyor"
    confirm_continue "Yedek dosyası bulunamadı"
else
    echo "[✓] Yedek dosyası bulundu: $BACKUP_FILE"
    echo ""
    echo "[i] Sistem ayarları geri yükleniyor..."
    
    # sysupgrade ile restore
    sysupgrade -r "$BACKUP_FILE"
    check_error "Sistem ayarlarının geri yüklenmesi"
    
    confirm_continue "Sistem ayarları geri yüklendi"
fi

# Temizlik
echo ""
echo "[i] Geçici dosyalar temizleniyor..."
cd /tmp
rm -rf /tmp/install
check_error "Temizlik işlemi"

# Özet bilgi
echo ""
echo "================================================"
echo "Kurulum tamamlandı!"
echo "================================================"
echo ""
echo "Yüklenen bileşenler:"
echo "  ✓ Sistem paketleri (LuCI uygulamaları, araçlar)"
echo "  ✓ $IPK_COUNT adet IPK paketi"
echo "  ✓ Zapret DPI Bypass"
if [ -n "$BACKUP_FILE" ]; then
    echo "  ✓ Sistem ayarları geri yüklendi"
fi
echo ""
echo "DİKKAT: Değişikliklerin etkinleşmesi için sistemi yeniden başlatın"
echo ""
echo "Yeniden başlatmak için:"
echo "  reboot"
echo ""
echo "================================================"
