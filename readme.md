# FaceWork Tracker

FaceWork Tracker adalah aplikasi Flutter untuk presensi karyawan berbasis pengenalan wajah, pencatatan pekerjaan harian, kalender kehadiran, dan laporan performa.

Project ini memakai kamera perangkat, ML Kit Face Detection, MobileFaceNet TFLite, SQLite lokal, dan Supabase sebagai backend utama.

## Fitur Utama

- Login, register, reset password, dan session auth dengan Supabase.
- Enrollment wajah 1 kali menggunakan 1 foto wajah.
- Check-in dan check-out melalui tombol konfirmasi.
- Frame wajah muncul saat proses scan/verifikasi berlangsung.
- Analisis wajah dengan beberapa sampel sebelum presensi dinyatakan gagal.
- Popup sukses check-in dengan pesan penyemangat kerja.
- Popup sukses check-out dengan pesan istirahat.
- Tracker project dan worklog harian.
- Kalender presensi, worklog, izin/libur, dan marker tanggal.
- Laporan performa dan export PDF.
- Reminder lokal untuk check-in/check-out.

## Alur Presensi Wajah

### Enrollment

```text
Buka halaman pendaftaran wajah
  -> arahkan wajah ke kamera
  -> ambil 1 foto
  -> ML Kit mendeteksi wajah
  -> crop wajah dari bounding box
  -> resize ke 112x112
  -> MobileFaceNet membuat embedding 192 dimensi
  -> embedding disimpan untuk user tersebut
```

### Check-In / Check-Out

```text
Tekan Konfirmasi Check-In atau Konfirmasi Check-Out
  -> kamera mulai scan
  -> frame muncul jika wajah terdeteksi
  -> aplikasi menampilkan proses analisis
  -> wajah dicocokkan dengan embedding yang sudah terdaftar
  -> jika cocok, presensi sukses
  -> jika tidak cocok setelah beberapa sampel, presensi gagal
```

Saat presensi sukses, frame scan akan hilang lagi. Frame akan muncul kembali ketika user menekan tombol konfirmasi presensi berikutnya.

## Teknologi

- Flutter
- Dart
- Supabase
- Camera
- Google ML Kit Face Detection
- TFLite Flutter
- MobileFaceNet
- SQLite / sqflite
- PDF dan Printing
- Local Notifications

## Struktur Folder

```text
lib/
  features/
    attendance/      # UI presensi dan kamera
    auth/            # login, register, reset password, splash
    calendar/        # kalender kehadiran dan worklog
    enrollment/      # pendaftaran wajah
    home/            # dashboard utama
    main_nav/        # navigasi utama aplikasi
    profile/         # profil user
    report/          # laporan dan export PDF
    tracker/         # project dan worklog
  shared/
    database/        # database lokal embedding
    models/          # model aplikasi
    providers/       # provider notifikasi
    services/        # service Supabase, attendance, face, PDF, dll
    store/           # state utama aplikasi
    theme/           # warna dan tema aplikasi

assets/
  models/
    mobilefacenet.tflite
    sface.tflite

supabase/
  schema.sql
```

## Prasyarat

- Flutter SDK sesuai environment project.
- Android Studio atau VS Code dengan Flutter plugin.
- Perangkat Android fisik disarankan untuk kamera dan ML Kit.
- Project Supabase aktif.
- Model TFLite tersedia di `assets/models/`.

## Setup Project

1. Masuk ke folder project.

```bash
cd face_recognizer
```

2. Install dependency Flutter.

```bash
flutter pub get
```

3. Pastikan asset model sudah ada.

```text
assets/models/mobilefacenet.tflite
assets/models/sface.tflite
```

4. Pastikan asset sudah terdaftar di `pubspec.yaml`.

```yaml
flutter:
  assets:
    - assets/models/sface.tflite
    - assets/models/mobilefacenet.tflite
```

5. Siapkan database Supabase.

Jalankan isi file berikut di Supabase SQL Editor:

```text
supabase/schema.sql
```

6. Pastikan konfigurasi Supabase sudah sesuai di:

```text
lib/shared/services/supabase_client.dart
```

7. Jalankan aplikasi.

```bash
flutter run
```

## Cara Uji Manual

1. Register atau login.
2. Lengkapi profil jika diperlukan.
3. Buka halaman pendaftaran wajah.
4. Daftarkan wajah 1 kali.
5. Buka tab Absen.
6. Tekan `Konfirmasi Check-In`.
7. Arahkan wajah yang sama ke kamera.
8. Tunggu proses analisis sampai presensi sukses.
9. Coba `Konfirmasi Check-Out` dengan flow yang sama.

Untuk menguji kasus gagal, gunakan wajah berbeda atau kondisi wajah yang tidak sesuai dengan enrollment.

## Catatan Face Recognition

- Face detection memakai ML Kit.
- Face embedding memakai MobileFaceNet.
- Input model menggunakan ukuran `112x112`.
- Output embedding berukuran 192 dimensi.
- Matching memakai Euclidean distance.
- Threshold saat ini memakai nilai `1.25`.
- Jika wajah tidak cocok, sistem mencoba maksimal beberapa sampel sebelum menggagalkan presensi.

Nilai threshold bisa dikalibrasi lagi jika hasil di perangkat nyata terlalu ketat atau terlalu longgar.

## Platform

Target utama project saat ini adalah Android/native.

Web masih memakai stub untuk fitur kamera/face recognition, sehingga flow presensi wajah tidak ditujukan untuk browser.

## Dokumentasi Konsep

Penjelasan konsep yang lebih lengkap ada di:

```text
Konsep_Projek.md
```

## Status Saat Ini

Project sudah memiliki alur inti untuk:

- Auth Supabase.
- Enrollment wajah 1 foto.
- Presensi check-in/check-out dengan verifikasi wajah.
- Penyimpanan embedding lokal dan sync ke Supabase.
- Tracker worklog.
- Kalender.
- Laporan PDF.

Fitur yang belum menjadi flow utama:

- GPS presensi.
- Face recognition di web.
- Panel admin penuh untuk HR.
