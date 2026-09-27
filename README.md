# Dynamic Notch (macOS Native HUD & Dynamic Island)

macOS Sonoma ve Sequoia (Apple Silicon M1/M2/M3/M4) için Swift, SwiftUI ve AppKit mimarisiyle sıfırdan geliştirilmiş, yüksek performanslı, minimalist ve akıcı çentik HUD uygulaması.

---

## 🌟 Özellikler

### 1. Akıllı Ekran & Çentik Geometrisi Tespiti
- **Fiziksel Çentik:** `NSScreen.auxiliaryTopLeftArea` ve `auxiliaryTopRightArea` geometrileri kullanılarak MacBook Pro ve MacBook Air çentiğinin tam etrafına sıfır boşlukla yerleşir.
- **Sanal Dinamik Ada (Virtual Island):** Harici monitörlerde (Studio Display, 4K ekranlar) veya çentiksiz Mac'lerde ekranın üst ortasında modern bir ada (pill) şeklinde konumlanır.
- **Çoklu Ekran & Çözünürlük Desteği:** Ekran değiştiğinde (`NSApplication.didChangeScreenParametersNotification`) pencere konumunu otomatik olarak yeniden hesaplar.

### 2. Now Playing (Medya Oynatıcı & HUD)
- **Apple Music & Spotify Entegrasyonu:** `DistributedNotificationCenter` üzerinden anlık şarkı durumu, sanatçı adı, albüm, süre ve kapak resmini yakalar.
- **Kompakt Mod:** Çentiğin solunda mini albüm kapağı, sağında ise canlı zıplayan ekolayzır / audio visualizer efekti gösterir.
- **Genişletilmiş Kart Modu:** Çentiğin üzerine gelindiğinde (hover) veya tıklandığında yumuşak yay (`.spring(response: 0.35, dampingFraction: 0.75)`) animasyonuyla genişler.
  - Yüksek çözünürlüklü albüm kapağı & arka plan ışıltısı
  - Otomatik kayan şarkı adı (Marquee) ve sanatçı bilgisi
  - İnteraktif scrubber (ilerleme çubuğu & kalan süre)
  - Oynat/Duraklat, Sonraki Parça, Önceki Parça kontrolleri
- Medya kapandığında çentiğin orijinal boyutuna pürüzsüzce küçülmesi.

### 3. Ses ve Parlaklık HUD Göstergeleri
- **CoreAudio Dinleyicisi:** `AudioObjectAddPropertyListenerBlock` ile sistem varsayılan ses çıkış aygıtının ses seviyesini (`kAudioDevicePropertyVolumeScalar`) ve sessize alma durumunu (`kAudioDevicePropertyMute`) donanım düzeyinde dinler.
- **Parlaklık Dinleyicisi:** `DisplayServices` ve `IOKit` üzerinden ekran parlaklığı değişimlerini takip eder.
- **Dinamik Kapsül HUD:** Ses veya parlaklık değiştiğinde SF Symbols ikonları (`speaker.wave.3.fill`, `sun.max.fill`) ve neon dolgu barı ile çentikten sağa/sola açılan şık bir bar gösterir; 1.8 saniye işlem yapılmadığında çentiğin arkasına geri çekilir.

### 4. Menü Çubuğu Denetimi & Simülasyon Modu
- Menü çubuğundaki (Status Bar) dinamik dalga simgesinden:
  - **Simulate Playing Music:** Müzik çalar açık olmasa dahi demoyu ve kapak görsellerini anında test edebilme
  - **Test Volume / Brightness HUD:** Ses ve parlaklık animasyonlarını tek tıkla test etme
  - **Recalculate Notch Position:** Çentik koordinatlarını zorla yenileme

---

## 🏗️ Proje Mimarisi

```
DynamicNotch/
├── Package.swift
├── Sources/
│   └── DynamicNotch/
│       ├── App/
│       │   ├── DynamicNotchApp.swift           # SwiftUI App entry point
│       │   └── AppDelegate.swift               # Status Bar Item, Lifecycle, Menüler
│       ├── Window/
│       │   ├── NotchPanel.swift                # Şeffaf, tam ekran üstü NSPanel (.nonactivatingPanel)
│       │   ├── NotchWindowController.swift     # Window controller & ekran dinleyicisi
│       │   └── ScreenGeometryHelper.swift      # Fiziksel çentik ve sanal ada geometri hesaplaması
│       ├── Managers/
│       │   ├── NotchStateManager.swift         # Merkezi UI durumları & auto-dismiss zamanlayıcıları
│       │   ├── NowPlayingManager.swift         # Apple Music & Spotify bildirimleri ve AppleScript
│       │   ├── AudioMonitor.swift              # CoreAudio Default Output Device listener'ı
│       │   ├── BrightnessMonitor.swift         # DisplayServices & IOKit parlaklık monitörü
│       │   └── MediaKeyTapManager.swift        # Klavye medya tuşları ve CGEventTap
│       ├── Models/
│       │   ├── NotchState.swift                # .idle, .mediaCompact, .mediaExpanded, .volumeHUD, .brightnessHUD
│       │   ├── MediaTrack.swift                # Parça bilgileri & zaman hesaplayıcıları
│       │   └── HUDType.swift                   # Ses & Parlaklık bildirim tipleri
│       ├── Views/
│       │   ├── NotchRootView.swift             # Ana çentik konteyneri ve yay animasyonları
│       │   ├── Components/
│       │   │   ├── NotchShape.swift            # Fiziksel çentik kavisi ve yumuşak köşeler
│       │   │   ├── AudioVisualizerView.swift   # TimelineView tabanlı canlı ekolayzır dalgaları
│       │   │   └── MarqueeText.swift           # Kayan yazı bileşeni
│       │   ├── Media/
│       │   │   ├── MediaCompactView.swift      # Sol/sağ mini kanatlar
│       │   │   └── MediaExpandedView.swift     # Zengin medya çalar kartı
│       │   └── HUD/
│       │       └── IndicatorHUDView.swift      # Ses / Parlaklık barı ve yüzde göstergesi
│       └── Resources/
│           └── Info.plist                      # LSUIElement=YES (arka plan uygulaması)
├── Scripts/
│   └── build_app.sh                            # .app paketi derleme ve oluşturma betiği
└── README.md
```

---

## 🚀 Derleme ve Çalıştırma

### 1. Hızlı Paketleme & Çalıştırma:
```bash
cd DynamicNotch
./Scripts/build_app.sh
open build/DynamicNotch.app
```

### 2. Geliştirme Sırasında Terminalden Çalıştırma:
```bash
cd DynamicNotch
swift run
```

---

## 🔐 İzinler (Gerektiğinde)
- **Apple Events (Otomasyon):** Apple Music / Spotify şarkı bilgilerini okumak ve oynat/duraklat kontrolü yapmak için ilk açılışta macOS izin penceresi onaylanmalıdır.
- **Erişilebilirlik (Accessibility):** Klavye medya tuşlarını (`F10/F11/F12`, `F1/F2`) küresel olarak `CGEventTap` ile yakalamak isterseniz *Sistem Ayarları > Gizlilik ve Güvenlik > Erişilebilirlik* altından izin verebilirsiniz.
