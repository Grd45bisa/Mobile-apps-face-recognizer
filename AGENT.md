# AGENT.md - Panduan Lanjutan Mobile Apps Presensia

Dokumen ini menjadi panduan kerja untuk agent/developer yang melanjutkan pengembangan folder `Mobile-Apps`.

Status saat ini: perubahan implementasi mobile lanjutan untuk GPS/geofence, device binding, QR login dashboard, dan upload evidence sudah di-rollback. Jangan anggap fitur-fitur itu sudah final di mobile app.

Fondasi SQL/dokumen di folder `../SQL/` tetap bisa dipakai sebagai referensi, tetapi implementasi mobile perlu dirancang ulang pelan-pelan sesuai kebutuhan terbaru.

## Arah Baru yang Diminta

QR Code bukan untuk login ke dashboard admin.

Flow yang diinginkan:

1. User baru membuka mobile app.
2. User belum bisa login bebas hanya dengan email/password.
3. User meminta QR Code ke admin.
4. Admin menampilkan/memberikan QR Code dari dashboard admin.
5. User scan QR Code di screen auth mobile.
6. Jika QR valid, user boleh masuk ke aplikasi atau melakukan aktivasi akun/perangkat sesuai desain backend.

Jadi implementasi berikutnya harus dimulai dari screen auth, bukan dari menu Profil.

## Hal yang Perlu Dicek Ulang Besok

- Screen auth/login saat ini belum punya entry QR Code.
- Flow QR harus disesuaikan untuk user baru masuk mobile app, bukan menghubungkan dashboard.
- Masalah presensi yang muncul saat dicoba perlu dianalisis dari error aktual.
- Jangan langsung aktifkan GPS/geofence/device binding sebelum flow dasar presensi stabil.
- Jangan upload bukti foto presensi sebelum kebutuhan dan policy datanya jelas.

## File Acuan SQL

```text
../SQL/20260524_00_full_presensia_schema.sql
../SQL/20260524_01_admin_mobile_foundation.sql
../SQL/MOBILE_APPS_SQL_AUDIT.md
```

## Prioritas Lanjutan

1. Analisis error presensi aktual dari device/log.
2. Rapikan flow auth QR untuk user baru.
3. Tentukan kontrak QR dari dashboard ke mobile.
4. Setelah auth QR stabil, baru lanjutkan device binding.
5. Setelah presensi dasar stabil, baru pertimbangkan GPS/geofence dan evidence.

## Prinsip

- Kerjakan bertahap.
- Jangan ubah banyak bagian sekaligus.
- Pastikan setiap step bisa dites di device.
- Hindari fitur berat sebelum flow inti stabil.
- Untuk data sensitif seperti wajah, lokasi, foto, dan perangkat, tampilkan informasi yang jelas ke user.
