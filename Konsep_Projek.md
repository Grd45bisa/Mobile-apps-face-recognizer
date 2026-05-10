# FaceWork Tracker

Aplikasi mobile employee self-service berbasis Flutter untuk presensi wajah, pencatatan pekerjaan harian, kalender kehadiran, dan laporan performa karyawan.

Dokumen ini menjelaskan kondisi konsep dan implementasi project saat ini.

---

## Daftar Isi

- [Latar Belakang](#latar-belakang)
- [Tujuan Produk](#tujuan-produk)
- [Target Pengguna](#target-pengguna)
- [Alur Penggunaan](#alur-penggunaan)
- [Status Pengembangan](#status-pengembangan)
- [Fitur Utama](#fitur-utama)
- [Arsitektur Sistem](#arsitektur-sistem)
- [Face Recognition Pipeline](#face-recognition-pipeline)
- [Flow Enrollment Wajah](#flow-enrollment-wajah)
- [Struktur Folder](#struktur-folder)
- [Setup Singkat](#setup-singkat)

---

## Latar Belakang

Presensi karyawan dengan metode manual, kartu, PIN, atau tanda tangan mudah dimanipulasi dan sulit dikaitkan langsung dengan produktivitas harian. FaceWork Tracker dibuat untuk menggabungkan presensi, pekerjaan harian, kalender, dan laporan dalam satu aplikasi.

Masalah yang ingin diselesaikan:

- Mengurangi risiko titip absen.
- Membuat check-in dan check-out lebih cepat melalui verifikasi wajah.
- Menghubungkan data presensi dengan worklog harian.
- Memudahkan karyawan melihat status kerja hari ini.
- Memudahkan HR/admin membaca rekap kehadiran dan performa.

---

## Tujuan Produk

1. **Presensi lebih valid**  
   Karyawan melakukan check-in dan check-out melalui pencocokan wajah.

2. **Worklog terpusat**  
   Pekerjaan harian dicatat dalam Tracker dan bisa dikaitkan dengan project.

3. **Data mudah dipantau**  
   Kalender dan laporan membantu melihat pola hadir, izin, libur, absen, jam kerja, dan produktivitas.

4. **Pengalaman pengguna jelas**  
   Aplikasi memberi status visual ketika kamera siap, sedang menganalisis wajah, sukses, atau gagal.

---

## Target Pengguna

**Karyawan**

- Check-in dan check-out.
- Mendaftarkan wajah.
- Mengisi worklog atau timer pekerjaan.
- Melihat kalender kehadiran.
- Melihat laporan pribadi.

**Admin / HR**

- Melihat dan mengelola data kehadiran.
- Meninjau worklog dan laporan performa.
- Mengatur data kalender kerja, libur, izin, dan laporan.

---

## Alur Penggunaan

### 1. Pendaftaran Wajah

Enrollment saat ini dibuat sederhana mengikuti referensi `face-recognition-with-flutter`.

```
Buka halaman pendaftaran wajah
        |
        v
Arahkan wajah ke kamera
        |
        v
Ambil 1 foto wajah
        |
        v
ML Kit mendeteksi bounding box wajah
        |
        v
Crop wajah -> resize 112x112
        |
        v
MobileFaceNet menghasilkan embedding 192 dimensi
        |
        v
Embedding disimpan untuk user tersebut
```

Catatan penting:

- Enrollment hanya mengambil **1 foto wajah**.
- Tidak ada lagi enrollment multi-pose depan/kiri/kanan/senyum.
- Embedding disimpan melalui `EmbeddingSyncService.saveEmbedding`.

### 2. Check-In

```
Buka tab Absen
        |
        v
Tekan "Konfirmasi Check-In"
        |
        v
Kamera mulai scan
        |
        v
Frame muncul jika wajah terdeteksi
        |
        v
Sistem menganalisis sampai maksimal 3 sampel
        |
        +-- cocok --> Presensi sukses + popup "Selamat bekerja"
        |
        +-- tidak cocok --> Presensi gagal, minta konfirmasi ulang
```

Saat wajah cocok, aplikasi sengaja menampilkan state loading/analisis sebentar agar proses terasa natural sebelum menampilkan status sukses.

### 3. Check-Out

Flow check-out sama seperti check-in, tetapi setelah berhasil aplikasi menampilkan popup berisi pesan istirahat.

```
Tekan "Konfirmasi Check-Out"
        |
        v
Konfirmasi dialog check-out
        |
        v
Scan dan cocokkan wajah
        |
        +-- cocok --> Check-out sukses + popup "Selamat beristirahat"
        |
        +-- tidak cocok --> Presensi gagal, minta konfirmasi ulang
```

### 4. Tracker Harian

Karyawan dapat mencatat pekerjaan berdasarkan project. Tracker mendukung timer aktif dan input manual. Data worklog digunakan kembali di kalender dan laporan.

### 5. Kalender dan Laporan

Kalender menampilkan data presensi, izin/libur, dan worklog per tanggal. Laporan menampilkan ringkasan performa dan dapat diekspor ke PDF.

---

## Status Pengembangan

| Area | Status | Keterangan |
|---|---|---|
| UI utama aplikasi | Selesai | Home, Tracker, Absen, Kalender, Laporan, Profil, dan navigasi utama tersedia |
| Auth Supabase | Selesai | Login, register, reset password, dan session terhubung ke Supabase |
| Presensi wajah | Selesai tahap inti | Check-in/check-out memakai kamera, ML Kit, MobileFaceNet, dan threshold Euclidean |
| Enrollment wajah | Selesai tahap inti | 1 foto wajah -> 1 embedding |
| Multi-sample verification | Selesai | Jika tidak cocok, sistem mencoba maksimal 3 sampel sebelum gagal |
| SQLite embedding | Selesai | Cache embedding lokal melalui `EmbeddingDb` |
| Sync embedding Supabase | Selesai tahap inti | Embedding disimpan/sync melalui tabel `face_embeddings` |
| Tracker/worklog | Selesai tahap inti | Project, timer, input manual, edit/delete worklog |
| Kalender | Selesai tahap inti | Presensi, worklog, izin/libur, dan marker tanggal |
| Laporan PDF | Selesai tahap inti | Generate dan share PDF memakai `pdf` dan `printing` |
| Notifikasi lokal | Ada | Reminder check-in/check-out dan kalender |
| GPS presensi | Belum aktif | Belum ada pencatatan koordinat GPS pada flow presensi saat ini |
| Web support kamera | Stub | Kamera/ML Kit diarahkan untuk Android/native; web menampilkan pesan tidak tersedia |

---

## Fitur Utama

### 1. Presensi Wajah

Presensi dilakukan melalui tombol konfirmasi, bukan otomatis dari live preview.

Karakteristik saat ini:

- Kamera aktif di layar Absen.
- Frame wajah hanya muncul saat proses konfirmasi/scan.
- Sistem mengambil beberapa sampel jika wajah tidak langsung cocok.
- Jika wajah cocok, presensi disimpan dan popup sukses muncul.
- Jika wajah tidak cocok setelah beberapa sampel, user diminta konfirmasi ulang.

### 2. Enrollment Wajah 1 Kali

Karyawan mendaftarkan wajah dengan satu foto. Sistem mendeteksi wajah, crop bounding box, resize ke `112x112`, menjalankan MobileFaceNet, lalu menyimpan embedding.

### 3. Tracker Project dan Worklog

Tracker digunakan untuk:

- Membuat project.
- Memilih project aktif.
- Menjalankan timer pekerjaan.
- Menambah worklog manual.
- Mengedit dan menghapus worklog.

### 4. Kalender Kehadiran

Kalender menampilkan:

- Hari hadir.
- Hari tidak hadir.
- Izin/cuti.
- Libur.
- Worklog pada tanggal tertentu.
- Input manual aktivitas/presensi dari kalender.

### 5. Laporan Performa

Laporan memakai data presensi dan worklog untuk membuat ringkasan:

- Total hari hadir.
- Jam kerja.
- Keterlambatan.
- Statistik worklog.
- Export PDF.

### 6. Profil dan Pengaturan Wajah

Profil menampilkan status data wajah. User dapat masuk ke flow enrollment untuk mendaftarkan ulang wajah jika diperlukan.

---

## Arsitektur Sistem

```
Flutter App
  |
  +-- Presentation
  |     +-- Home
  |     +-- Tracker
  |     +-- Attendance
  |     +-- Calendar
  |     +-- Report
  |     +-- Profile
  |
  +-- Shared Services
  |     +-- AuthService
  |     +-- AttendanceService
  |     +-- WorklogService
  |     +-- ProjectService
  |     +-- FaceRecognitionService
  |     +-- EmbeddingSyncService
  |     +-- NotificationService
  |
  +-- Storage
        +-- SQLite: cache embedding wajah
        +-- Supabase: auth, presensi, worklog, project, profile, embedding backup
```

| Komponen | Teknologi |
|---|---|
| Framework | Flutter / Dart |
| Auth dan cloud database | Supabase |
| Local database | SQLite via `sqflite` |
| Kamera | `camera` |
| Face detection | `google_mlkit_face_detection` |
| Face recognition | MobileFaceNet via `tflite_flutter` |
| Image processing | `image` |
| Kalender | `table_calendar` |
| Grafik laporan | `fl_chart` |
| PDF export | `pdf`, `printing` |
| Notifikasi | `flutter_local_notifications`, `timezone` |
| Kecerahan layar | `screen_brightness` |

---

## Face Recognition Pipeline

Pipeline saat ini mengikuti pola project referensi `face-recognition-with-flutter`.

```
Foto / frame kamera
        |
        v
ML Kit Face Detection
        |
        v
Ambil bounding box wajah
        |
        v
Crop wajah
        |
        v
Resize ke 112x112
        |
        v
MobileFaceNet TFLite
        |
        v
Embedding 192 dimensi
        |
        v
Euclidean distance ke embedding terdaftar
        |
        v
distance <= 1.25 ? cocok : tidak cocok
```

Detail teknis:

- Model utama: `assets/models/mobilefacenet.tflite`
- Input model: `112x112x3`
- Output embedding: 192 dimensi
- Metode pencocokan: Euclidean distance
- Threshold saat ini: `1.25`
- Maksimal sampel presensi: `3`

Jika sampel pertama tidak cocok, aplikasi mencoba sampel berikutnya sebelum menyatakan gagal. Ini mengurangi kemungkinan gagal hanya karena blur, pose kurang pas, atau pencahayaan sesaat.

---

## Flow Enrollment Wajah

```
User membuka enrollment
        |
        v
Kamera depan aktif
        |
        v
User tekan "Ambil Foto"
        |
        v
Foto diproses ML Kit
        |
        v
Jika wajah ditemukan:
  crop -> resize -> MobileFaceNet -> embedding
        |
        v
saveEmbedding(userId, embedding)
        |
        v
Enrollment selesai
```

Perbedaan dari konsep lama:

- Tidak memakai 3 sudut.
- Tidak merata-ratakan beberapa embedding.
- Tidak melakukan adaptive update saat presensi.
- Sistem sengaja dibuat sederhana agar perilakunya sama seperti referensi.

---

## Struktur Folder

Struktur utama project saat ini:

```
face_recognizer/
|-- assets/
|   |-- models/
|       |-- mobilefacenet.tflite
|       |-- sface.tflite
|-- lib/
|   |-- main.dart
|   |-- features/
|   |   |-- auth/
|   |   |-- home/
|   |   |-- main_nav/
|   |   |-- attendance/
|   |   |-- enrollment/
|   |   |-- tracker/
|   |   |-- calendar/
|   |   |-- report/
|   |   |-- profile/
|   |-- shared/
|       |-- database/
|       |-- models/
|       |-- providers/
|       |-- services/
|       |   |-- face/
|       |-- store/
|       |-- theme/
|-- supabase/
|-- test/
|-- pubspec.yaml
```

File penting terkait wajah:

| File | Fungsi |
|---|---|
| `lib/features/enrollment/presentation/enrollment_screen_native.dart` | Pendaftaran wajah 1 foto |
| `lib/features/attendance/presentation/attendance_screen.dart` | Flow presensi dan hasil sukses/gagal |
| `lib/features/attendance/presentation/camera_face_view_native.dart` | Kamera, deteksi wajah, dan overlay frame |
| `lib/shared/services/face/face_recognition_service_native.dart` | MobileFaceNet, crop, embedding, matching |
| `lib/shared/services/face/embedding_sync_service.dart` | Simpan/sync embedding |
| `lib/shared/database/embedding_db.dart` | Cache SQLite embedding |

---

## Setup Singkat

1. Install dependency:

```bash
flutter pub get
```

2. Pastikan model tersedia di `assets/models/`:

```text
assets/models/mobilefacenet.tflite
assets/models/sface.tflite
```

3. Pastikan asset terdaftar di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/sface.tflite
    - assets/models/mobilefacenet.tflite
```

4. Jalankan aplikasi:

```bash
flutter run
```

5. Urutan tes yang disarankan:

- Login/register user.
- Buka Profil atau flow enrollment wajah.
- Daftarkan wajah dengan 1 foto.
- Buka tab Absen.
- Tekan `Konfirmasi Check-In`.
- Coba wajah yang sama dan wajah berbeda.
- Jika terlalu ketat atau terlalu longgar, kalibrasi threshold Euclidean `1.25` di `FaceRecognitionService`.

---

## Catatan Pengembangan Lanjutan

Beberapa hal yang masih bisa dikembangkan:

- Kalibrasi threshold wajah berdasarkan hasil tes di perangkat fisik.
- Membersihkan sisa asset/model `sface.tflite` jika sudah tidak dipakai.
- Menambahkan GPS/geofence jika presensi perlu validasi lokasi.
- Menambahkan role admin yang lebih tegas untuk enrollment karyawan lain.
- Menambahkan audit log untuk percobaan presensi gagal.
- Menambahkan pengujian integrasi kamera pada perangkat Android.
