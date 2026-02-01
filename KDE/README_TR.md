# DodoPulse KDE Plasma Widget

KDE Plasma için güzel mini grafiklerle birlikte hafif bir sistem izleme widget'ı.

## Dosya Yapısı

```
dodopulse.plasmoid         # Dağıtılabilir widget paketi
KDE/
├── metadata.json          # Widget meta verisi
├── install.sh            # Kurulum scripti
├── uninstall.sh          # Kaldırma scripti
├── README.md             # İngilizce dokümantasyon
├── README_TR.md          # Türkçe dokümantasyon
├── img/
│   └── example.png       # Ekran görüntüsü
└── contents/
    ├── config/
    │   ├── config.qml    # Yapılandırma menüsü
    │   └── main.xml      # Ayar tanımları
    └── ui/
        ├── main.qml              # Ana widget dosyası
        ├── CompactRepresentation.qml  # Sistem tepsisi görünümü
        ├── FullRepresentation.qml     # Genişletilmiş görünüm
        ├── configGeneral.qml     # Ayarlar paneli
        ├── MetricCard.qml        # CPU/Memory/GPU kartları
        ├── NetworkCard.qml       # Ağ kartı
        ├── DiskCard.qml          # Disk kartı
        ├── SystemCard.qml        # Sistem bilgi kartı
        └── SparklineGraph.qml    # Grafik bileşeni
```

![KDE Plasma](https://img.shields.io/badge/KDE_Plasma-5.x%20|%206.x-blue)
![Lisans](https://img.shields.io/badge/Lisans-MIT-green)

![DodoPulse Ekran Görüntüsü](img/example.png)

## Özellikler

- **CPU izleme** - Kullanım yüzdesi, sıcaklık, çekirdek sayısı ve geçmiş grafiği
- **Bellek izleme** - Kullanılan/toplam bellek ve görsel grafik
- **GPU izleme** - Kullanım yüzdesi, sıcaklık (NVIDIA, AMD, Intel)
- **Ağ izleme** - İndirme/yükleme hızları, yerel IP ve geçmiş grafiği
- **Disk izleme** - Kullanım yüzdesi, boş alan ve ilerleme çubuğu
- **Sistem bilgisi** - Yük ortalaması, işlem sayısı, kernel sürümü, çalışma süresi

### Görsel Özellikler

- Gradyan dolgulu güzel sparkline grafikleri
- Renk kodlu uyarılar (yüksek kullanımda turuncu, kritik durumda kırmızı)
- Yumuşak animasyonlar ve hover efektleri
- Sistem tepsisi için kompakt mod
- Yapılandırılabilir güncelleme aralıkları

## Gereksinimler

- KDE Plasma 5.x veya 6.x
- Qt 5.15+ veya Qt 6.x
- GPU izleme için:
  - NVIDIA: `nvidia-smi` (nvidia-utils paketi)
  - AMD: `amdgpu` kernel sürücüsü
  - Intel: `i915` kernel sürücüsü
- Sıcaklık izleme için: `lm_sensors` (önerilen)

## Kurulum

### Yöntem 1: .plasmoid Dosyası ile (Önerilen)

```bash
# GUI ile kurulum - dosyaya çift tıkla veya:

# Plasma 6 için:
kpackagetool6 -t Plasma/Applet -i dodopulse.plasmoid

# Plasma 5 için:
plasmapkg2 -i dodopulse.plasmoid
```

### Yöntem 2: Kurulum Scripti

```bash
cd KDE
chmod +x install.sh
./install.sh
```

Sistem geneli kurulum için:
```bash
sudo ./install.sh --system
```

### Yöntem 3: plasmapkg2 ile dizinden

```bash
plasmapkg2 -i KDE/
```

### Yöntem 3: Manuel Kurulum

```bash
mkdir -p ~/.local/share/plasma/plasmoids/com.dodoapps.dodopulse
cp -r KDE/* ~/.local/share/plasma/plasmoids/com.dodoapps.dodopulse/
```

## Kullanım

1. Masaüstü veya panele sağ tıklayın
2. "Widget Ekle..." seçeneğini seçin
3. "DodoPulse" araması yapın
4. Masaüstünüze veya panelinize sürükleyin

### Yapılandırma

Widget'a sağ tıklayıp "DodoPulse'u Yapılandır..." seçeneğini seçerek şunlara erişebilirsiniz:

- **Güncelleme aralığı**: Metriklerin ne sıklıkla yenileneceği (500ms - 10s)
- **Görünür bölümler**: CPU, Bellek, Ağ, Disk, GPU açma/kapama
- **Sıcaklık göster**: Sıcaklık okumalarını göster
- **Kompakt mod**: Sistem tepsisi için minimal görünüm

## Kaldırma

```bash
./uninstall.sh
```

Veya manuel olarak:
```bash
rm -rf ~/.local/share/plasma/plasmoids/com.dodoapps.dodopulse
```

Plasma shell'i yeniden başlatın:
```bash
kquitapp5 plasmashell && kstart5 plasmashell
```

## Teknik Detaylar

DodoPulse sistem metriklerini şuralardan okur:

- **CPU**: `/proc/stat`
- **Bellek**: `/proc/meminfo`
- **Ağ**: `/proc/net/dev`
- **Disk**: `df` komutu
- **Sıcaklık**: `/sys/class/hwmon/` (lm_sensors)
- **GPU**:
  - NVIDIA: `nvidia-smi`
  - AMD: `/sys/class/drm/card*/device/gpu_busy_percent`
  - Intel: `/sys/class/drm/card0/gt/gt_cur_freq_mhz`

## Sorun Giderme

### Widget görünmüyor
```bash
# Plasma 6 için (önerilen):
systemctl --user restart plasma-plasmashell

# Veya manuel:
kquitapp6 plasmashell && kstart plasmashell

# Plasma 5 için:
kquitapp5 plasmashell && kstart5 plasmashell
```

### GPU izleme çalışmıyor

NVIDIA için:
```bash
# nvidia-utils kur
sudo pacman -S nvidia-utils  # Arch
sudo apt install nvidia-utils  # Debian/Ubuntu
```

AMD/Intel için kernel modülünün yüklü olduğundan emin olun:
```bash
lsmod | grep -E "amdgpu|i915"
```

### Sıcaklık gösterilmiyor

lm_sensors kur:
```bash
sudo pacman -S lm_sensors  # Arch
sudo apt install lm-sensors  # Debian/Ubuntu

# Sensörleri algıla
sudo sensors-detect
```

## Lisans

MIT Lisansı - detaylar için [LICENSE](../LICENSE) dosyasına bakın.

## Katkıda Bulunma

Katkılarınızı bekliyoruz! Pull request göndermekten çekinmeyin.

---

[DodoPulse](https://github.com/dodoapps/dodopulse) projesinin bir parçası.
