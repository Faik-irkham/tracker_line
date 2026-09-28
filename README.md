# Tracker Line

> **⚠️ Proyek ini hanya untuk belajar dan pembuatan konten.**
> Bukan aplikasi produksi, tidak untuk dijual, dan tidak berafiliasi dengan
> aplikasi ojek online atau layanan pesan-antar mana pun.

Demo Flutter untuk melacak pengiriman di peta, seperti yang ada di aplikasi
ojek online. Motor driver bergerak di sepanjang rute jalan asli, dengan
kamera sinematik, notifikasi, dan sebuah cerita pendek: *driver galau yang
ternyata mengantar pesanan ke rumah mantannya*.

## Isi demo

- Peta OpenStreetMap dengan mode malam dan efek hujan
- Ikon motor tampak atas yang digambar dengan kode (`CustomPainter`) dan
  berputar mengikuti arah jalan
- Alur pesanan: cari driver (radar), ke restoran, ambil pesanan, antar, sampai
- Posisi driver disimulasikan seperti update GPS berkala, lalu dianimasikan
  halus di antara update
- Kamera otomatis yang mengikuti tahapan pesanan
- Gelembung isi hati driver, adegan chat, layar "pesanan sampai", dan kartu
  penutup

## Menjalankan

```bash
flutter pub get
flutter run --profile   # animasi lebih mulus dibanding mode debug
```

Butuh koneksi internet untuk memuat peta dan rute.

### Kontrol tersembunyi (untuk merekam layar)

| Gesture | Fungsi |
|---|---|
| Tekan lama bar atas | Mode rekam on/off (tombol kamera disembunyikan) |
| Ketuk 2x bar atas | Ulangi perjalanan dari awal |
| Ketuk kartu penutup | Ulangi perjalanan dari awal |

## Mengubah cerita dan durasi

| File | Isi |
|---|---|
| `lib/delivery/galau_story.dart` | Kalimat isi hati driver, chat, catatan driver, kartu penutup, mode malam, dan hujan |
| `lib/delivery/trip_phase.dart` | Durasi tiap tahap dan kecepatan motor (`DemoTimeline`) |
| `lib/delivery/delivery_map_page.dart` | Lokasi restoran/customer, warna utama, data driver |

## Layanan pihak ketiga

Demo ini memakai layanan publik gratis yang **hanya boleh untuk pengembangan
dan trafik kecil**:

- **Tile peta OpenStreetMap** (`tile.openstreetmap.org`), yang tunduk pada
  [Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles).
  Atribusi "© OpenStreetMap contributors" wajib tetap terlihat, termasuk di
  video. Untuk aplikasi sungguhan, gunakan penyedia tile seperti Mapbox,
  MapTiler, atau Stadia Maps.
- **Server demo OSRM** (`router.project-osrm.org`) untuk rute jalan. Server
  ini hanya untuk demo; untuk aplikasi sungguhan, jalankan server OSRM
  sendiri atau gunakan layanan routing berbayar.

Kalau server rute tidak bisa diakses, aplikasi memakai rute cadangan
sederhana.

## Disclaimer

- Cerita, nama restoran, nomor pesanan, pelat nomor, dan data driver
  **fiktif**. Kesamaan dengan kejadian atau orang sungguhan hanya kebetulan.
- Tidak ada nama orang yang dipakai; tokoh hanya disebut "Mas Driver" dan
  "dia".
- Warna dan desain tidak meniru merek aplikasi mana pun.
- Posisi driver adalah simulasi, bukan data GPS sungguhan.

## Teknologi

- [Flutter](https://flutter.dev)
- [flutter_map](https://pub.dev/packages/flutter_map) +
  [latlong2](https://pub.dev/packages/latlong2)
- [OpenStreetMap](https://www.openstreetmap.org/copyright) (data peta, ©
  OpenStreetMap contributors)
- [OSRM](https://project-osrm.org) (rute jalan)
