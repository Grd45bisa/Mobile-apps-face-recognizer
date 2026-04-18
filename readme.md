# FaceWork Tracker

Aplikasi mobile *employee self-service* berbasis Flutter untuk absensi berbasis pengenalan wajah, pencatatan pekerjaan harian, dan pemantauan performa karyawan — dirancang untuk kebutuhan [NAMA PERUSAHAAN].

---

## Daftar Isi

- [Latar Belakang Masalah](#latar-belakang-masalah)
- [Tujuan Produk](#tujuan-produk)
- [Target Pengguna](#target-pengguna)
- [Alur Penggunaan](#alur-penggunaan)
- [Status Pengembangan](#status-pengembangan)
- [Fitur Utama](#fitur-utama)
- [Arsitektur Sistem](#arsitektur-sistem)
- [Face Recognition Pipeline](#face-recognition-pipeline)
- [Flow Enrollment Wajah](#flow-enrollment-wajah)
- [Struktur Folder](#struktur-folder)
- [Setup & Instalasi](#setup--instalasi)
- [Desain & UI](#desain--ui)

---

## Latar Belakang Masalah

Sistem pencatatan kehadiran karyawan di banyak perusahaan masih mengandalkan metode konvensional yang memiliki celah signifikan baik dari sisi keamanan, higienitas, maupun efisiensi operasional.

### Masalah pada Sistem Absensi Konvensional

| Metode | Kelemahan |
|---|---|
| Kartu / Swipe | Mudah dititipkan ke rekan kerja (*buddy punching*), tidak memverifikasi kehadiran fisik |
| Fingerprint | Perangkat keras mahal, error rate tinggi untuk sidik jari tertentu, risiko higienitas (kontak fisik ratusan orang per hari) |
| PIN / Password | Tidak ada bukti kehadiran fisik, PIN dapat dibagikan atau diingat orang lain |
| Absensi manual (tanda tangan) | Rawan manipulasi, rekap data lambat, tidak real-time |

### Gap Produktivitas yang Tidak Terjembatani

Masalah yang lebih besar dari sekadar absensi adalah **tidak adanya keterkaitan antara data kehadiran dengan data produktivitas**. Manajer di [NAMA PERUSAHAAN] saat ini harus:

1. Merekap absensi dari satu sistem
2. Meminta laporan kerja harian secara manual (email, chat, atau form terpisah)
3. Menggabungkan keduanya secara manual untuk mengevaluasi performa karyawan setiap bulan

Proses ini memakan waktu, rawan human error, dan tidak memberikan visibilitas real-time kepada manajemen.

### Solusi yang Diusulkan

FaceWork Tracker menggabungkan tiga fungsi ke dalam satu aplikasi:

- **Verifikasi kehadiran** yang sulit dipalsukan (wajah tidak bisa dipinjamkan)
- **Pencatatan kerja harian** yang terintegrasi langsung dengan data absensi
- **Dashboard performa** yang menghasilkan laporan siap pakai tanpa rekap manual

Seluruh inferensi pengenalan wajah berjalan *on-device* tanpa mengirimkan data biometrik ke server, menjawab kekhawatiran privasi yang umum muncul pada solusi serupa berbasis cloud.

---

## Tujuan Produk

FaceWork Tracker dirancang dengan tiga tujuan utama:

1. **Eliminasi titip absen** — Verifikasi identitas berbasis wajah memastikan hanya karyawan yang bersangkutan yang dapat melakukan check-in, tanpa kontak fisik dengan perangkat bersama.

2. **Sentralisasi data kerja** — Absensi dan catatan kerja harian tersimpan di satu tempat, menghasilkan laporan performa bulanan secara otomatis tanpa rekap manual oleh HR.

3. **Privasi biometrik terjaga** — Embedding wajah sebagai representasi biometrik tidak pernah dikirim ke server. Semua proses pencocokan wajah terjadi sepenuhnya di perangkat karyawan.

---

## Target Pengguna

Aplikasi ini melayani dua jenis pengguna dengan kebutuhan berbeda:

**Karyawan**
Pengguna utama dengan berbagai latar belakang teknis — dari yang terbiasa dengan smartphone hingga yang baru pertama kali menggunakannya. UI dirancang tanpa jargon teknis, dengan feedback visual yang jelas di setiap langkah.

**Admin / HR**
Pengguna dengan akses penuh ke data seluruh karyawan: mendaftarkan wajah baru, memantau kehadiran, dan mengunduh laporan performa bulanan.

---

## Alur Penggunaan

### Perspektif Karyawan — Hari Kerja Tipikal

**Pagi hari — Check-in**

Karyawan membuka aplikasi dan mengarahkan kamera ke wajahnya sendiri. Dalam hitungan detik, sistem mendeteksi wajah secara otomatis, mencocokkan identitas, dan menampilkan konfirmasi berhasil beserta jam masuk dan lokasi GPS. Tidak ada tombol yang perlu ditekan secara manual — proses berlangsung otomatis setelah wajah terdeteksi di frame kamera.

```
Buka aplikasi
      │
      ▼
Tab "Absen" → Kamera aktif otomatis
      │
      ▼
Arahkan wajah ke kamera
      │
      ▼
[Berhasil] Muncul nama + jam masuk + lokasi
      │
      ▼
Karyawan masuk kerja ✓
```

**Sepanjang hari — Catat pekerjaan di Tracker**

Setiap kali mengerjakan sebuah pekerjaan, karyawan membuka tab Tracker dan menambahkan entri: nama pekerjaan, project yang dikerjakan, serta waktu mulai dan selesai. Durasi dihitung otomatis dari selisih waktu. Ini menggantikan laporan kerja harian yang biasanya dikirim lewat chat atau email.

**Sore hari — Check-out**

Proses identik dengan check-in. Sistem mencatat jam keluar dan menghitung total jam kerja hari itu secara otomatis.

---

### Perspektif Admin — Awal Bulan

Setiap awal bulan, admin membuka dashboard laporan untuk memilih periode dan karyawan yang ingin dievaluasi. Sistem menampilkan ringkasan kehadiran, total jam kerja vs. target, dan tren produktivitas mingguan. Laporan dapat langsung di-export ke PDF untuk kebutuhan review atau arsip HR.

```
Buka Laporan → Pilih bulan & karyawan
      │
      ▼
Dashboard muncul:
- Total hari hadir / izin / absen
- Total jam kerja vs. target
- Rating kerja rata-rata
- Bar chart jam harian
- Line chart tren mingguan
      │
      ▼
Export ke PDF → Selesai
```

---

### Perspektif Admin — Karyawan Baru

Ketika ada karyawan baru bergabung, admin membuka menu Enrollment, mengisi data profil, lalu mengambil foto wajah dari tiga sudut (depan, kiri, kanan). Sistem otomatis memproses foto menjadi embedding dan menyimpannya ke perangkat. Karyawan baru langsung bisa melakukan check-in di hari yang sama.

---

## Status Pengembangan

Dokumen ini mencakup rancangan produk secara menyeluruh. Agar tidak terjadi kebingungan antara yang sudah ada di aplikasi dan yang masih berupa rencana, berikut ringkasan status saat ini:

| Area | Status | Keterangan |
|---|---|---|
| Rancangan UI / Tampilan seluruh halaman | ✅ Selesai | Home, Tracker, Absen, Kalender, Laporan, Profil sudah dibangun dengan tema, warna, dan navigasi final |
| Bottom navigation dengan FAB melengkung (notched) | ✅ Selesai | 5 tab + tombol Absen di tengah dengan notch dan animasi |
| Tema & palet warna (flat design) | ✅ Selesai | `AppColors` & `AppTheme` final dan dipakai di seluruh halaman |
| State dummy / in-memory (`AppStore`) untuk demo UI | ✅ Selesai | Dipakai agar tampilan dapat diinteraksikan tanpa backend |
| Face detection (MLKit) | ⏳ Belum | Masih di level tampilan, belum terhubung ke kamera real-time |
| Face recognition SFace via TFLite | ⏳ Belum | Model dan pipeline inferensi belum diintegrasikan |
| Enrollment wajah (3 sudut → embedding) | ⏳ Belum | Alur admin belum dibangun |
| Penyimpanan lokal SQLite (`sqflite`) | ⏳ Belum | Data masih disimpan sementara di memori |
| Sinkronisasi Supabase (cloud) | ⏳ Belum | Konfigurasi dan sync layer belum dibuat |
| GPS / geolocator saat check-in | ⏳ Belum | Belum ada pencatatan koordinat |
| Export laporan ke PDF | ⏳ Belum | UI laporan sudah ada, export masih placeholder |

Dengan kata lain: **tampilan sudah rampung**, fokus tahap berikutnya adalah mengisi logika fitur (face recognition, database, sync, GPS, export).

---

## Fitur Utama

### 1. Check-in / Check-out
Karyawan membuka layar kamera, wajah terdeteksi otomatis oleh MLKit, diidentifikasi oleh model SFace via TFLite, lalu jam masuk/keluar beserta koordinat GPS tercatat ke database. Tersedia status visual yang jelas: siap scan, mendeteksi, berhasil, dan gagal.

### 2. Tracker Harian
Karyawan mencatat pekerjaan yang dikerjakan: nama pekerjaan, project terkait, serta waktu mulai dan selesai. Durasi dihitung otomatis dari selisih waktu. Data ini menjadi bukti kerja untuk review bulanan.

### 3. Kalender Kehadiran
Tampilan kalender bulanan dengan marker warna:
- Hijau — hari hadir
- Merah — cuti
- Kuning — libur nasional
- Biru — hari ini

Tap pada tanggal menampilkan detail jam masuk/keluar dan daftar tugas hari tersebut.

### 4. Laporan Performa
Dashboard bulanan berisi total jam kerja vs. target, persentase penyelesaian tugas, ketepatan waktu, rating rata-rata, bar chart jam harian, dan line chart tren mingguan. Dapat di-export ke PDF.

---

## Arsitektur Sistem

Aplikasi menggunakan arsitektur **hybrid**: data biometrik disimpan sepenuhnya lokal di perangkat, sementara data operasional disinkronkan ke cloud untuk akses admin dan HR.

```
┌──────────────────────────────────────────────────────┐
│                     Flutter App                      │
│                                                      │
│  ┌─────────────────────┐   ┌────────────────────┐    │
│  │  SQLite (Lokal)     │   │  Supabase (Cloud)  │    │
│  │                     │   │                    │    │
│  │  • Embedding wajah  │   │  • Rekap absensi   │    │
│  │  • Profil karyawan  │   │  • Laporan bulanan │    │
│  │  • Cache timesheet  │   │  • Kalender HR     │    │
│  └─────────────────────┘   └────────────────────┘    │
│           ▲                          ▲               │
│           │ tidak pernah            │ sync saat      │
│           │ keluar perangkat        │ ada koneksi    │
└──────────────────────────────────────────────────────┘
```

| Komponen | Teknologi | Alasan Pemilihan |
|---|---|---|
| Framework | Flutter 3.11+ / Dart | Cross-platform Android & iOS dari satu codebase |
| Local DB | SQLite via `sqflite` | Penyimpanan embedding & data offline-first |
| Cloud | Supabase | Sync data operasional + akses admin real-time |
| State Management | Riverpod | Cocok untuk async stream kamera dan reactive UI |
| Face Detection | google_mlkit_face_detection | On-device, akurat, mendukung landmark & alignment |
| Face Recognition | SFace via `tflite_flutter` | Model ringan, embedding 128-dim, berjalan offline |
| Charts | fl_chart | Bar chart & line chart di halaman laporan |
| Calendar | table_calendar | Kalender dengan event marker kustom |
| Location | geolocator | Koordinat GPS saat check-in untuk verifikasi lokasi |

---

## Face Recognition Pipeline

Seluruh proses inferensi berjalan *on-device* tanpa memerlukan koneksi internet.

```
Frame Kamera (real-time)
          │
          ▼
 [MLKit Face Detection]
  Deteksi bounding box wajah
  + ekstraksi 468 landmark
  + face alignment (rotasi koreksi)
          │
          ▼
   [Face Crop & Resize]
  Region wajah diekstrak
  dan di-resize ke 112×112 px
          │
          ▼
  [SFace Model via TFLite]
  Inferensi menghasilkan
  embedding 128-dimensi
          │
          ▼
   [Cosine Similarity]
  Dibandingkan terhadap seluruh
  embedding karyawan di SQLite
          │
          ▼
     similarity ≥ 0.6 ?
          │
   Ya ────┼──▶ Identitas valid → Check-in dicatat
          │
  Tidak ──┴──▶ Wajah tidak dikenali → Tampilkan pesan gagal
```

> **Catatan threshold:** Nilai `0.6` ditentukan berdasarkan hasil pengujian pada dataset internal. Nilai ini dapat disesuaikan melalui konfigurasi — nilai lebih tinggi meningkatkan presisi namun berisiko menolak wajah yang sah pada kondisi pencahayaan buruk.

---

## Flow Enrollment Wajah

Enrollment adalah proses pendaftaran wajah karyawan baru. Hanya dapat dilakukan oleh akun admin.

```
Admin buka menu Enrollment
          │
          ▼
Isi data karyawan:
nama, ID karyawan, jabatan, departemen
          │
          ▼
Ambil foto wajah via kamera
(3 sudut: depan · miring kiri · miring kanan)
          │
          ▼
Setiap foto → SFace pipeline
→ menghasilkan embedding 128-dim
          │
          ▼
Rata-rata ketiga embedding dihitung
→ disimpan ke SQLite lokal
          │
          ▼
Data profil karyawan (tanpa embedding)
→ disinkronkan ke Supabase
```

Dengan menyimpan rata-rata embedding dari beberapa sudut, sistem menjadi lebih robust terhadap variasi pose dan pencahayaan saat check-in harian.

---

## Struktur Folder

```
face_recognizer/
├── android/                    # Konfigurasi native Android
├── ios/                        # Konfigurasi native iOS
├── assets/
│   ├── models/
│   │   └── sface.tflite        # Model SFace yang sudah dikonversi ke TFLite
│   └── images/                 # Aset gambar & ikon UI
├── lib/
│   ├── main.dart               # Entry point & inisialisasi Supabase
│   ├── core/
│   │   ├── database/           # Helper SQLite: schema, DAO, migrasi
│   │   ├── supabase/           # Konfigurasi & client Supabase
│   │   └── utils/              # Fungsi utilitas: cosine similarity, date helper, dll.
│   ├── features/
│   │   ├── attendance/         # Fitur check-in / check-out
│   │   │   ├── data/           # Repository + model database
│   │   │   ├── domain/         # Use case + entitas bisnis
│   │   │   └── presentation/   # Screen + widget kamera
│   │   ├── timesheet/          # Fitur Tracker — pencatatan pekerjaan harian
│   │   ├── calendar/           # Fitur kalender kehadiran
│   │   ├── report/             # Fitur laporan performa & PDF export
│   │   └── enrollment/         # Pendaftaran wajah karyawan (admin only)
│   └── shared/
│       ├── widgets/            # Widget reusable: tombol, kartu, status badge
│       └── theme/              # Palet warna, tipografi, tema global
├── test/                       # Unit test & widget test
├── pubspec.yaml
└── readme.md
```

---

## Setup & Instalasi

### Prasyarat

- Flutter SDK 3.11 atau lebih baru (`flutter --version` untuk cek)
- Android Studio / Xcode untuk emulator atau device fisik
- Akun Supabase untuk konfigurasi cloud sync

### Langkah Instalasi

**1. Clone repositori**
```bash
git clone <url-repositori>
cd face_recognizer
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Konfigurasi Supabase**

Buat file `lib/core/supabase/supabase_config.dart`:

```dart
const supabaseUrl = 'https://xxxx.supabase.co';
const supabaseAnonKey = 'eyJ...';
```

Buat storage bucket berikut di dashboard Supabase:
- `face-photos` — foto enrollment karyawan (akses: **private**)

**4. Letakkan model TFLite**

Pastikan file `sface.tflite` tersedia di `assets/models/` dan sudah terdaftar di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/sface.tflite
```

**5. Jalankan aplikasi**
```bash
flutter run
```

---

## Desain & UI

Bagian ini menggambarkan tampilan aplikasi **yang sudah selesai dibangun**. Logika fitur (face recognition, database, sync) belum terhubung — semua data di layar saat ini masih bersumber dari store dummy di memori (`AppStore`) agar tampilan bisa dicoba secara interaktif.

**Filosofi:** Flat design murni — tidak ada gradasi, tidak ada drop shadow berlebihan, tidak ada blur. Semua elemen menggunakan solid fill. Visual hierarchy dibangun dari kontras warna, ukuran teks, dan whitespace. Tema diimplementasikan di `lib/shared/theme/` (`AppColors` + `AppTheme`).

**Palet Warna**

Diambil langsung dari `lib/shared/theme/app_colors.dart`:

| Peran | Hex | Digunakan Pada |
|---|---|---|
| Primary | `#1565C0` | Tombol utama, aksen, FAB tengah |
| Primary Dark | `#0D47A1` | Header, state aktif FAB |
| Primary Light | `#E3F2FD` | Background pill tab yang aktif |
| Background | `#F5F7FA` | Latar semua halaman |
| Surface | `#FFFFFF` | Kartu, panel konten, bottom bar |
| Success | `#1B5E20` | Status check-in berhasil |
| Success Light | `#ECFDF5` | Background pill status hadir |
| Error | `#B71C1C` | Tombol keluar, status gagal dikenali |
| Error Light | `#FEF2F2` | Background pill status gagal |
| Warning | `#FF8F00` | Indikator keterlambatan |
| Warning Light | `#FFF8E1` | Background pill status late |
| Missing | `#D97706` | Indikator tidak hadir / data hilang |
| Text Primary | `#1A1A2E` | Judul dan body text utama |
| Text Secondary | `#6B7280` | Label, caption, ikon non-aktif |
| Border | `#E5E7EB` | Garis pemisah, outline kartu |

**Navigasi**

Bottom navigation dengan **5 tab + FAB melengkung (notched)** di tengah:

```
┌─────────────────────────────────────────────────┐
│                                                 │
│           ╭──────  [ FAB ]  ──────╮             │
│  ╭────────╯                       ╰────────╮    │
│  │  Home    Tracker   |   Kalender  Laporan │   │
│  ╰──────────────────────────────────────────╯   │
└─────────────────────────────────────────────────┘
```

- **Home** — ringkasan hari ini dan akses cepat
- **Tracker** — pencatatan pekerjaan harian (sebelumnya disebut "Tugas")
- **Absen** (FAB tengah) — tombol utama check-in / check-out berbasis wajah
- **Kalender** — tampilan kehadiran bulanan
- **Laporan** — dashboard performa

FAB tengah memiliki animasi scale saat ditekan dan haptic feedback (`HapticFeedback.mediumImpact`). Pergantian tab memicu `HapticFeedback.selectionClick`, ikon berganti antara versi outlined ↔ filled, dan background pill muncul pada tab aktif.

**Halaman yang Sudah Dibangun**

| Halaman | File | Status Tampilan |
|---|---|---|
| Home | `features/home/presentation/home_screen.dart` | ✅ Selesai |
| Tracker (Timesheet) | `features/timesheet/presentation/timesheet_screen.dart` | ✅ Selesai |
| Absen (Attendance) | `features/attendance/presentation/attendance_screen.dart` | ✅ Selesai |
| Kalender | `features/calendar/presentation/calendar_screen.dart` | ✅ Selesai |
| Laporan | `features/report/presentation/report_screen.dart` | ✅ Selesai |
| Profil | `features/profile/presentation/profile_screen.dart` | ✅ Selesai |
| Main Nav (shell + bottom bar) | `features/main_nav/main_screen.dart` | ✅ Selesai |

> Catatan: folder `timesheet/` masih memakai nama lama di codebase, tetapi istilah yang tampil di UI dan dokumen ini adalah **Tracker**.
