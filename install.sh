#!/bin/sh

# OpenWRT Otomatik Kurulum ve Restore Scripti
# Gereksinimler: wget ve unzip paketleri önceden yüklü olmalıdır

echo "================================================"
echo "OpenWRT Otomatik Kurulum ve Restore Scripti"
echo "================================================"
echo ""

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Hata kontrolü fonksiyonu
check_error() {
    if [ $? -eq 0 ]; then
        echo "${GREEN}[✓] $1 başarılı${NC}"
        return 0
    else
        echo "${RED}[✗] $1 başarısız!${NC}"
        exit 1
    fi
}

# Paket kontrolü fonksiyonu
check_package() {
    which $1 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${GREEN}[✓] $1 paketi mevcut${NC}"
        return 0
    else
        echo "${RED}[✗] $1 paketi bulunamadı!${NC}"
        return 1
    fi
}

# wget ve unzip kontrolü
echo "${BLUE}[i] Gerekli paketler kontrol ediliyor...${NC}"
check_package "wget" || exit 1
check_package "unzip" || exit 1

# İnternet bağlantısı kontrolü
echo ""
echo "${YELLOW}[i] İnternet bağlantısı kontrol ediliyor...${NC}"
ping -c 2 8.8.8.8 > /dev/null 2>&1
check_error "İnternet bağlantısı"

# Çalışma dizinini temizle ve oluştur
echo ""
echo "${YELLOW}[i] Çalışma dizini hazırlanıyor...${NC}"
rm -rf /tmp/install
mkdir -p /tmp/install
cd /tmp/install
check_error "Çalışma dizini oluşturma"

# Paket listesini güncelle
echo ""
echo "${YELLOW}[i] Paket listeleri güncelleniyor...${NC}"
opkg update
check_error "Paket listesi güncellemesi"

# Ana paketleri yükle
echo ""
echo "${YELLOW}[i] Ana paketler yükleniyor...${NC}"
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

# GitHub deposundan dosyaları indir
echo ""
echo "${YELLOW}[i] Kurulum dosyaları indiriliyor...${NC}"
wget -O /tmp/install/wrt-main.zip https://github.com/oguzozmen/wrt/archive/refs/heads/main.zip
check_error "Kurulum dosyalarının indirilmesi"

# Arşivi aç
echo ""
echo "${YELLOW}[i] Arşiv dosyası açılıyor...${NC}"
unzip -q /tmp/install/wrt-main.zip -d /tmp/install/
check_error "Arşiv dosyasının açılması"

# Ana dizini bul
WRT_DIR="/tmp/install/wrt-main"
if [ ! -d "$WRT_DIR" ]; then
    echo "${RED}[✗] wrt-main dizini bulunamadı!${NC}"
    exit 1
fi

cd "$WRT_DIR"
echo "${GREEN}[✓] Çalışma dizini: $WRT_DIR${NC}"

# IPK dosyalarını yükle
echo ""
echo "${YELLOW}[i] IPK paketleri yükleniyor...${NC}"
IPK_COUNT=0
for ipk in *.ipk; do
    if [ -f "$ipk" ]; then
        echo "${BLUE}  → $ipk yükleniyor...${NC}"
        opkg install "$ipk"
        if [ $? -eq 0 ]; then
            IPK_COUNT=$((IPK_COUNT + 1))
            echo "${GREEN}    ✓ $ipk yüklendi${NC}"
        else
            echo "${YELLOW}    ! $ipk yüklenemedi (devam ediliyor)${NC}"
        fi
    fi
done

if [ $IPK_COUNT -gt 0 ]; then
    echo "${GREEN}[✓] Toplam $IPK_COUNT IPK paketi yüklendi${NC}"
    service rpcd reload
else
    echo "${YELLOW}[!] Hiç IPK paketi bulunamadı${NC}"
fi

# Zapret kurulumu
echo ""
echo "${YELLOW}[i] Zapret DPI bypass aracı kuruluyor...${NC}"

# ZIP dosyasını bul
ZAPRET_ZIP=$(find "$WRT_DIR" -name "*.zip" -type f | head -n 1)

if [ -z "$ZAPRET_ZIP" ]; then
    echo "${RED}[✗] Zapret ZIP dosyası bulunamadı!${NC}"
    exit 1
fi

echo "${BLUE}  → Zapret arşivi: $ZAPRET_ZIP${NC}"

# Zapret'i aç
ZAPRET_EXTRACT_DIR="/tmp/install/zapret_extract"
mkdir -p "$ZAPRET_EXTRACT_DIR"
unzip -q "$ZAPRET_ZIP" -d "$ZAPRET_EXTRACT_DIR"
check_error "Zapret arşivinin açılması"

# Zapret klasörünü bul
ZAPRET_DIR=$(find "$ZAPRET_EXTRACT_DIR" -maxdepth 2 -type d -name "zapret-v*" | head -n 1)

if [ -z "$ZAPRET_DIR" ]; then
    echo "${RED}[✗] Zapret kurulum dizini bulunamadı!${NC}"
    exit 1
fi

echo "${GREEN}[✓] Zapret dizini: $ZAPRET_DIR${NC}"
cd "$ZAPRET_DIR"

# Zapret kurulum scriptlerini çalıştır
echo ""
echo "${YELLOW}[i] Zapret ön gereksinimler yükleniyor...${NC}"
if [ -f "./install_prereq.sh" ]; then
    chmod +x ./install_prereq.sh
    ./install_prereq.sh
    check_error "Zapret ön gereksinimler"
else
    echo "${RED}[✗] install_prereq.sh bulunamadı!${NC}"
fi

echo ""
echo "${YELLOW}[i] Zapret binary dosyaları yükleniyor...${NC}"
if [ -f "./install_bin.sh" ]; then
    chmod +x ./install_bin.sh
    ./install_bin.sh
    check_error "Zapret binary kurulumu"
else
    echo "${RED}[✗] install_bin.sh bulunamadı!${NC}"
fi

# Zapret parametrelerini göster ve bekle
echo ""
echo "================================================"
echo "${GREEN}ZAPRET DPI BYPASS PARAMETRELERİ${NC}"
echo "================================================"
echo ""
echo "${YELLOW}Aşağıdaki parametreleri kopyalayın (Ctrl+C):${NC}"
echo ""
echo "${BLUE}--dpi-desync=fake --dpi-desync-ttl=3${NC}"
echo ""
echo "================================================"
echo ""
echo "${YELLOW}Parametreleri kopyaladıktan sonra devam etmek için${NC}"
echo "${YELLOW}herhangi bir tuşa basın...${NC}"
read -n 1 -s
echo ""
echo "${GREEN}[✓] Devam ediliyor...${NC}"

echo ""
echo "${YELLOW}[i] Zapret yapılandırma sihirbazı başlatılıyor...${NC}"
if [ -f "./install_easy.sh" ]; then
    chmod +x ./install_easy.sh
    ./install_easy.sh
    check_error "Zapret yapılandırma"
else
    echo "${RED}[✗] install_easy.sh bulunamadı!${NC}"
fi

# Yedek dosyasını bul ve restore et
echo ""
echo "${YELLOW}[i] Sistem yedek dosyası aranıyor...${NC}"
cd "$WRT_DIR"

BACKUP_FILE=$(find "$WRT_DIR" -name "*.tar.gz" -type f | head -n 1)

if [ -z "$BACKUP_FILE" ]; then
    echo "${YELLOW}[!] tar.gz yedek dosyası bulunamadı, restore atlanıyor${NC}"
else
    echo "${GREEN}[✓] Yedek dosyası bulundu: $BACKUP_FILE${NC}"
    echo ""
    echo "${YELLOW}[i] Sistem ayarları geri yükleniyor...${NC}"
    
    # sysupgrade ile restore
    sysupgrade -r "$BACKUP_FILE"
    check_error "Sistem ayarlarının geri yüklenmesi"
fi

# Temizlik
echo ""
echo "${YELLOW}[i] Geçici dosyalar temizleniyor...${NC}"
cd /tmp
rm -rf /tmp/install
check_error "Temizlik işlemi"

# Özet bilgi
echo ""
echo "================================================"
echo "${GREEN}Kurulum tamamlandı!${NC}"
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
echo "${YELLOW}DİKKAT: Değişikliklerin etkinleşmesi için sistemi yeniden başlatın${NC}"
echo ""
echo "Yeniden başlatmak için:"
echo "  ${BLUE}reboot${NC}"
echo ""
echo "================================================"
