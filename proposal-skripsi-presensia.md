# Proposal Skripsi

## Implementasi Convolutional Neural Network Menggunakan Arsitektur MobileFaceNet untuk Pengenalan Wajah pada Sistem Presensi Mobile

---

## Identitas Singkat Penelitian

**Bidang penelitian:** Computer Vision dan Video  
**Kategori:** AI + RPL  
**Fokus utama:** Implementasi pengenalan wajah berbasis Convolutional Neural Network pada sistem presensi mobile  
**Objek penelitian:** Aplikasi mobile Presensia  
**Platform implementasi:** Android berbasis Flutter  
**Metode utama:** MobileFaceNet, face embedding, cosine similarity, quality filtering, dan multi-pose enrollment  

---

# BAB I PENDAHULUAN

## 1.1 Latar Belakang

Presensi merupakan salah satu proses penting dalam kegiatan akademik maupun operasional organisasi. Melalui presensi, institusi dapat mengetahui kehadiran, kedisiplinan, serta aktivitas pengguna dalam rentang waktu tertentu. Akan tetapi, sistem presensi konvensional seperti tanda tangan manual, input mandiri, maupun pencatatan sederhana masih memiliki beberapa kelemahan. Kelemahan tersebut antara lain risiko manipulasi data, titip absen, kesalahan pencatatan, serta kurangnya validasi bahwa pengguna yang melakukan presensi benar-benar merupakan pemilik akun.

Perkembangan teknologi biometrik memberikan solusi terhadap permasalahan autentikasi identitas. Salah satu bentuk biometrik yang banyak digunakan adalah pengenalan wajah karena bersifat unik, mudah digunakan, dan tidak memerlukan kontak fisik secara langsung. Sistem pengenalan wajah dapat memanfaatkan kamera perangkat untuk menangkap citra wajah, kemudian memprosesnya menggunakan pendekatan Computer Vision dan Artificial Intelligence.

Dalam beberapa tahun terakhir, metode deep learning, khususnya Convolutional Neural Network (CNN), banyak digunakan dalam pengenalan wajah karena mampu mengekstraksi fitur visual secara otomatis dari citra. CNN dapat mempelajari pola spasial pada wajah seperti bentuk mata, hidung, kontur wajah, dan hubungan antarfitur visual. Salah satu model CNN yang dirancang ringan untuk perangkat mobile adalah MobileFaceNet. Model ini menghasilkan face embedding, yaitu representasi numerik wajah dalam bentuk vektor berdimensi tinggi yang dapat dibandingkan menggunakan metrik kemiripan seperti cosine similarity.

Pada perangkat mobile, implementasi pengenalan wajah memiliki tantangan tersendiri. Sistem harus mampu bekerja secara real-time, efisien terhadap penggunaan memori dan komputasi, serta tetap akurat dalam berbagai kondisi pencahayaan dan pose wajah. Oleh karena itu, diperlukan pipeline pengenalan wajah yang tidak hanya menjalankan inferensi CNN, tetapi juga mencakup deteksi wajah, penyaringan kualitas citra, penyelarasan wajah, penyimpanan embedding, dan pengambilan keputusan berdasarkan nilai ambang batas kemiripan.

Berdasarkan permasalahan tersebut, penelitian ini mengimplementasikan pengenalan wajah menggunakan arsitektur MobileFaceNet berbasis Convolutional Neural Network pada sistem presensi mobile. Sistem yang dikembangkan menggunakan Google ML Kit untuk deteksi wajah dan landmark, TensorFlow Lite untuk inferensi model MobileFaceNet, serta cosine similarity untuk mencocokkan embedding wajah pengguna. Penelitian ini difokuskan pada implementasi dan evaluasi pipeline pengenalan wajah dalam proses presensi, bukan pada pelatihan model CNN dari awal.

## 1.2 Rumusan Masalah

Berdasarkan latar belakang tersebut, rumusan masalah dalam penelitian ini adalah sebagai berikut:

1. Bagaimana mengimplementasikan Convolutional Neural Network menggunakan arsitektur MobileFaceNet untuk proses pengenalan wajah pada sistem presensi mobile?
2. Bagaimana menerapkan pipeline prapemrosesan citra wajah yang meliputi deteksi wajah, quality filtering, alignment, cropping, ekstraksi embedding, dan pencocokan wajah?
3. Bagaimana menentukan keputusan presensi berdasarkan nilai cosine similarity antara embedding wajah pengguna dan embedding wajah yang telah terdaftar?
4. Bagaimana performa sistem pengenalan wajah berdasarkan metrik evaluasi seperti accuracy, precision, recall, FAR, FRR, dan confusion matrix pada berbagai skenario pengujian?

## 1.3 Batasan Masalah

Agar penelitian lebih terarah, batasan masalah yang digunakan adalah sebagai berikut:

1. Penelitian berfokus pada implementasi pengenalan wajah untuk presensi, bukan pada seluruh fitur manajemen aplikasi.
2. Model CNN yang digunakan adalah MobileFaceNet dalam format TensorFlow Lite sebagai pretrained model, sehingga penelitian tidak melakukan training model CNN dari awal.
3. Deteksi wajah dan landmark dilakukan menggunakan Google ML Kit Face Detection.
4. Pencocokan wajah dilakukan menggunakan face embedding dan cosine similarity.
5. Sistem menggunakan threshold kemiripan untuk menentukan apakah wajah pengguna cocok dengan akun yang sedang login.
6. Enrollment wajah dilakukan dengan mengambil beberapa sampel wajah dari variasi pose, yaitu wajah lurus, menoleh kiri, dan menoleh kanan.
7. Sistem menerapkan quality filtering berupa ukuran wajah, pose kepala, tingkat blur, dan pencahayaan.
8. Pengujian dilakukan pada perangkat Android dengan jumlah responden terbatas sesuai kebutuhan penelitian skripsi.
9. Fitur pendukung seperti login, dashboard, kalender, tracker aktivitas, reminder, dan laporan PDF tidak menjadi fokus utama evaluasi AI, tetapi dijelaskan sebagai bagian dari sistem.

## 1.4 Tujuan Penelitian

Tujuan dari penelitian ini adalah:

1. Mengimplementasikan model MobileFaceNet berbasis Convolutional Neural Network untuk pengenalan wajah pada sistem presensi mobile.
2. Menerapkan pipeline pengenalan wajah mulai dari deteksi wajah, penyaringan kualitas, penyelarasan wajah, ekstraksi embedding, hingga pencocokan wajah.
3. Menguji efektivitas penggunaan face embedding dan cosine similarity dalam menentukan kecocokan wajah pengguna.
4. Mengevaluasi performa sistem berdasarkan skenario pengujian pengguna terdaftar dan pengguna tidak terdaftar pada beberapa kondisi pencahayaan dan variasi pose.

## 1.5 Manfaat Penelitian

### 1.5.1 Manfaat Akademik

Penelitian ini diharapkan dapat memberikan kontribusi akademik dalam bentuk studi implementasi CNN ringan pada perangkat mobile untuk pengenalan wajah. Selain itu, penelitian ini dapat menjadi referensi mengenai penggunaan MobileFaceNet, face embedding, cosine similarity, dan quality filtering dalam sistem biometrik berbasis aplikasi mobile.

### 1.5.2 Manfaat Praktis

Secara praktis, penelitian ini menghasilkan sistem presensi mobile yang dapat memverifikasi identitas pengguna melalui wajah. Sistem ini dapat membantu mengurangi potensi kecurangan presensi, meningkatkan keakuratan validasi kehadiran, dan memberikan pengalaman presensi yang lebih cepat serta mudah digunakan.

## 1.6 Sistematika Penulisan

Sistematika penulisan proposal ini terdiri dari:

1. **BAB I Pendahuluan**  
   Berisi latar belakang, rumusan masalah, batasan masalah, tujuan penelitian, manfaat penelitian, dan sistematika penulisan.

2. **BAB II Tinjauan Pustaka dan Landasan Teori**  
   Berisi teori yang mendukung penelitian, seperti computer vision, pengenalan wajah, CNN, MobileFaceNet, face embedding, cosine similarity, TensorFlow Lite, Google ML Kit, dan metrik evaluasi biometrik.

3. **BAB III Metodologi Penelitian**  
   Berisi alur penelitian, arsitektur sistem, pipeline pengenalan wajah, rancangan pengujian, serta metode evaluasi sistem.

---

# BAB II TINJAUAN PUSTAKA DAN LANDASAN TEORI

## 2.1 Tinjauan Pustaka

Tinjauan pustaka membahas penelitian terdahulu yang berkaitan dengan sistem presensi berbasis wajah, implementasi MobileFaceNet, pengenalan wajah berbasis CNN, serta penggunaan face embedding untuk verifikasi identitas. Kajian pustaka digunakan untuk mengetahui pendekatan yang telah digunakan sebelumnya, kelebihan dan kekurangannya, serta posisi penelitian ini dibandingkan penelitian terdahulu.

Tinjauan pustaka yang disarankan mencakup:

1. Penelitian mengenai sistem presensi berbasis pengenalan wajah.
2. Penelitian mengenai implementasi CNN untuk face recognition.
3. Penelitian mengenai MobileFaceNet pada perangkat mobile.
4. Penelitian mengenai cosine similarity dalam verifikasi wajah.
5. Penelitian mengenai quality filtering atau face image quality assessment.

## 2.2 Computer Vision

Computer Vision merupakan bidang ilmu yang mempelajari bagaimana komputer dapat memperoleh, memproses, menganalisis, dan memahami informasi visual dari citra atau video. Dalam konteks penelitian ini, computer vision digunakan untuk mendeteksi wajah, mengambil landmark wajah, melakukan penyelarasan wajah, dan menyiapkan citra wajah sebelum diproses oleh model CNN.

## 2.3 Pengenalan Wajah

Pengenalan wajah adalah proses identifikasi atau verifikasi seseorang berdasarkan karakteristik wajah. Secara umum, sistem pengenalan wajah terdiri dari beberapa tahap, yaitu:

1. Deteksi wajah pada citra.
2. Prapemrosesan wajah.
3. Ekstraksi fitur wajah.
4. Penyimpanan atau pencocokan fitur.
5. Pengambilan keputusan identitas.

Pada penelitian ini, pengenalan wajah digunakan untuk verifikasi identitas pengguna saat melakukan presensi. Sistem tidak mencari identitas dari seluruh populasi secara bebas, tetapi memverifikasi apakah wajah yang terdeteksi sesuai dengan akun pengguna yang sedang login.

## 2.4 Convolutional Neural Network

Convolutional Neural Network adalah salah satu jenis deep learning yang umum digunakan untuk pengolahan citra. CNN memiliki kemampuan mengekstraksi fitur visual melalui operasi konvolusi. Lapisan konvolusi dapat mengenali pola lokal seperti tepi, tekstur, bentuk, dan fitur visual yang lebih kompleks pada lapisan yang lebih dalam.

Dalam pengenalan wajah, CNN digunakan untuk mengubah citra wajah menjadi representasi numerik yang disebut embedding. Embedding ini kemudian digunakan untuk menghitung kemiripan antarwajah.

## 2.5 MobileFaceNet

MobileFaceNet adalah arsitektur CNN ringan yang dirancang untuk pengenalan wajah pada perangkat dengan keterbatasan komputasi seperti smartphone. Model ini menghasilkan embedding wajah yang dapat digunakan untuk membandingkan identitas seseorang.

Pada penelitian ini, MobileFaceNet digunakan dalam format TensorFlow Lite. Model tidak dilatih ulang dari awal, melainkan digunakan sebagai model pretrained untuk melakukan inferensi pada perangkat mobile. Kontribusi penelitian terletak pada implementasi pipeline pengenalan wajah, prapemrosesan, penyimpanan embedding, pencocokan similarity, dan evaluasi performa pada skenario presensi.

## 2.6 Face Detection dan Face Landmark

Face detection adalah proses menemukan lokasi wajah pada citra. Output dari proses ini biasanya berupa bounding box yang menunjukkan area wajah. Face landmark adalah titik-titik penting pada wajah seperti mata, hidung, mulut, dan kontur wajah.

Dalam sistem ini, Google ML Kit digunakan untuk:

1. Mendeteksi wajah dari kamera.
2. Mengambil bounding box wajah.
3. Mengambil landmark mata untuk membantu proses face alignment.
4. Membaca sudut kepala seperti yaw, pitch, dan roll untuk quality filtering.

## 2.7 Face Alignment dan Cropping

Face alignment merupakan proses menyelaraskan posisi wajah agar lebih konsisten sebelum dimasukkan ke model CNN. Salah satu pendekatan yang digunakan adalah menyelaraskan posisi mata kiri dan mata kanan agar berada pada garis horizontal. Setelah wajah disejajarkan, area wajah dipotong dan diubah ukurannya sesuai input model MobileFaceNet.

Tahapan ini penting karena variasi pose dan kemiringan wajah dapat memengaruhi kualitas embedding yang dihasilkan oleh CNN.

## 2.8 Face Embedding

Face embedding adalah representasi numerik wajah dalam bentuk vektor. Vektor ini dihasilkan oleh model CNN setelah citra wajah melewati proses inferensi. Wajah dari orang yang sama diharapkan memiliki embedding yang saling berdekatan, sedangkan wajah dari orang yang berbeda diharapkan memiliki embedding yang berjauhan.

Pada sistem ini, embedding dinormalisasi menggunakan L2 normalization agar perhitungan kemiripan lebih stabil.

## 2.9 Cosine Similarity

Cosine similarity digunakan untuk mengukur kemiripan antara dua vektor embedding. Nilai similarity yang lebih tinggi menunjukkan bahwa dua embedding memiliki arah vektor yang semakin mirip.

Rumus cosine similarity adalah:

```text
cosine_similarity(A, B) = (A . B) / (||A|| ||B||)
```

Dalam sistem presensi, jika nilai similarity antara embedding wajah pengguna dan embedding yang tersimpan melebihi threshold tertentu, maka wajah dianggap cocok.

## 2.10 Quality Filtering

Quality filtering adalah proses menyaring frame atau citra wajah sebelum masuk ke model CNN. Tujuannya adalah mencegah citra berkualitas buruk menghasilkan embedding yang tidak akurat.

Parameter quality filtering yang digunakan meliputi:

1. Ukuran wajah terhadap frame kamera.
2. Tingkat kecerahan citra wajah.
3. Tingkat blur menggunakan pendekatan Laplacian variance.
4. Sudut kepala seperti yaw, pitch, dan roll.

## 2.11 Multi-Pose Enrollment

Multi-pose enrollment adalah proses pendaftaran wajah dengan mengambil beberapa sampel dari variasi pose. Pada sistem ini, pengguna diarahkan untuk mengambil sampel wajah pada posisi lurus, menoleh kiri, dan menoleh kanan. Tujuannya adalah memperkaya representasi embedding pengguna agar sistem lebih toleran terhadap variasi pose saat presensi.

## 2.12 TensorFlow Lite

TensorFlow Lite adalah framework machine learning yang dirancang untuk menjalankan model pada perangkat mobile dan edge device. TensorFlow Lite memungkinkan model CNN seperti MobileFaceNet dijalankan secara on-device, sehingga proses inferensi tidak harus dikirim ke server.

Keuntungan penggunaan TensorFlow Lite adalah:

1. Latensi lebih rendah.
2. Tidak selalu bergantung pada koneksi jaringan untuk inferensi.
3. Data citra wajah dapat diproses langsung di perangkat.
4. Lebih efisien untuk perangkat mobile.

## 2.13 Metrik Evaluasi Biometrik

Evaluasi sistem biometrik memerlukan metrik yang dapat mengukur tingkat keberhasilan dan risiko kesalahan. Metrik yang digunakan antara lain:

1. **Accuracy**: tingkat prediksi benar dari seluruh pengujian.
2. **Precision**: proporsi prediksi diterima yang benar-benar pengguna sah.
3. **Recall**: proporsi pengguna sah yang berhasil diterima sistem.
4. **False Acceptance Rate (FAR)**: tingkat kesalahan ketika sistem menerima pengguna yang tidak sah.
5. **False Rejection Rate (FRR)**: tingkat kesalahan ketika sistem menolak pengguna sah.
6. **Confusion Matrix**: tabel evaluasi yang terdiri dari TP, TN, FP, dan FN.
7. **Genuine Score**: skor similarity dari pasangan wajah orang yang sama.
8. **Impostor Score**: skor similarity dari pasangan wajah orang yang berbeda.

---

# BAB III METODOLOGI PENELITIAN

## 3.1 Jenis Penelitian

Penelitian ini merupakan penelitian implementatif dan eksperimental. Disebut implementatif karena penelitian menerapkan model MobileFaceNet berbasis CNN ke dalam sistem presensi mobile. Disebut eksperimental karena sistem diuji menggunakan beberapa skenario untuk mengevaluasi performa pengenalan wajah.

## 3.2 Alur Penelitian

Alur penelitian yang digunakan adalah sebagai berikut:

1. Studi literatur mengenai pengenalan wajah, CNN, MobileFaceNet, face embedding, dan sistem presensi.
2. Analisis kebutuhan sistem presensi wajah.
3. Perancangan pipeline pengenalan wajah.
4. Implementasi deteksi wajah menggunakan Google ML Kit.
5. Implementasi ekstraksi embedding menggunakan MobileFaceNet TensorFlow Lite.
6. Implementasi penyimpanan embedding pada SQLite dan Supabase.
7. Implementasi pencocokan wajah menggunakan cosine similarity.
8. Implementasi quality filtering dan multi-pose enrollment.
9. Pengujian sistem pada beberapa skenario.
10. Analisis hasil pengujian menggunakan metrik evaluasi biometrik.

## 3.3 Gambaran Umum Sistem

Sistem Presensia merupakan aplikasi mobile yang digunakan untuk melakukan presensi check-in dan check-out berbasis wajah. Pengguna harus login terlebih dahulu, kemudian melakukan enrollment wajah. Setelah wajah terdaftar, pengguna dapat melakukan presensi dengan menghadapkan wajah ke kamera.

Sistem akan mendeteksi wajah, memeriksa kualitas frame, mengekstraksi embedding menggunakan MobileFaceNet, membandingkan embedding dengan data yang tersimpan, dan menentukan apakah presensi diterima atau ditolak.

## 3.4 Arsitektur Sistem

Arsitektur sistem terdiri dari beberapa komponen utama:

1. **Mobile Application Layer**  
   Dibangun menggunakan Flutter untuk menyediakan antarmuka pengguna, kamera, presensi, enrollment, dashboard, dan laporan.

2. **Face Detection Layer**  
   Menggunakan Google ML Kit untuk mendeteksi wajah, landmark, dan pose kepala.

3. **Face Recognition Layer**  
   Menggunakan MobileFaceNet TensorFlow Lite untuk mengekstraksi embedding wajah.

4. **Matching Layer**  
   Menggunakan cosine similarity untuk membandingkan embedding query dengan embedding yang tersimpan.

5. **Storage Layer**  
   Menggunakan SQLite untuk cache lokal embedding dan Supabase untuk penyimpanan cloud.

6. **Attendance Layer**  
   Menyimpan hasil presensi check-in/check-out setelah identitas pengguna berhasil diverifikasi.

## 3.5 Pipeline Enrollment Wajah

Pipeline enrollment wajah adalah sebagai berikut:

1. Pengguna login ke aplikasi.
2. Pengguna membuka halaman enrollment wajah.
3. Kamera depan aktif dan mendeteksi wajah pengguna.
4. Sistem mengarahkan pengguna untuk mengambil sampel wajah pada beberapa pose.
5. Setiap frame diperiksa melalui quality filtering.
6. Frame yang lolos dipotong dan disejajarkan.
7. MobileFaceNet menghasilkan embedding wajah.
8. Beberapa embedding disimpan sebagai representasi wajah pengguna.
9. Embedding disimpan di SQLite dan Supabase.

## 3.6 Pipeline Presensi Wajah

Pipeline presensi wajah adalah sebagai berikut:

1. Pengguna menekan tombol check-in atau check-out.
2. Kamera menangkap frame wajah pengguna.
3. Google ML Kit mendeteksi wajah dan landmark.
4. Sistem melakukan quality filtering terhadap ukuran wajah, pose kepala, dan kualitas frame.
5. Wajah dipotong dan disejajarkan.
6. MobileFaceNet mengekstraksi embedding dari citra wajah.
7. Embedding query dibandingkan dengan embedding pengguna yang sedang login.
8. Sistem menghitung cosine similarity.
9. Jika similarity lebih besar atau sama dengan threshold, presensi diterima.
10. Jika similarity di bawah threshold, presensi ditolak.

## 3.7 Alur Keputusan Pencocokan Wajah

Alur keputusan pencocokan wajah menggunakan logika berikut:

```text
Input frame kamera
       |
Deteksi wajah dengan ML Kit
       |
Quality filtering
       |
Face alignment dan cropping
       |
Ekstraksi embedding MobileFaceNet
       |
Normalisasi L2 embedding
       |
Hitung cosine similarity
       |
Similarity >= threshold?
       |              |
      Ya            Tidak
       |              |
Presensi valid   Presensi ditolak
```

## 3.8 Data Uji

Data uji diperoleh dari sampel wajah pengguna yang terdaftar dan pengguna yang tidak terdaftar. Setiap responden diambil beberapa sampel wajah dalam kondisi berbeda.

Contoh rancangan data uji:

1. Jumlah responden: 20-30 orang.
2. Sampel per responden: 10-15 citra atau percobaan presensi.
3. Kondisi pengujian:
   - Cahaya normal.
   - Cahaya rendah.
   - Wajah lurus.
   - Wajah sedikit menoleh.
   - Pengguna terdaftar.
   - Pengguna tidak terdaftar.

## 3.9 Skenario Pengujian

Skenario pengujian yang digunakan adalah:

### 3.9.1 Pengujian Pengguna Terdaftar

Pengujian dilakukan kepada pengguna yang sudah melakukan enrollment wajah. Tujuannya adalah mengukur apakah sistem dapat menerima pengguna yang sah.

### 3.9.2 Pengujian Pengguna Tidak Terdaftar

Pengujian dilakukan kepada pengguna yang tidak memiliki embedding pada akun tersebut. Tujuannya adalah mengukur apakah sistem mampu menolak pengguna yang tidak sah.

### 3.9.3 Pengujian Kondisi Pencahayaan

Pengujian dilakukan pada kondisi cahaya normal dan cahaya rendah. Tujuannya adalah mengetahui pengaruh pencahayaan terhadap similarity score dan keberhasilan presensi.

### 3.9.4 Pengujian Variasi Pose

Pengujian dilakukan pada pose wajah lurus, sedikit menoleh kiri, dan sedikit menoleh kanan. Tujuannya adalah mengetahui pengaruh variasi pose terhadap performa sistem.

### 3.9.5 Pengujian Threshold

Pengujian dilakukan dengan beberapa nilai threshold, misalnya 0.60, 0.65, 0.70, dan 0.75. Tujuannya adalah mencari threshold yang seimbang antara FAR dan FRR.

### 3.9.6 Pengujian Latensi

Pengujian dilakukan untuk mengukur waktu proses mulai dari deteksi wajah sampai keputusan presensi. Latensi penting karena sistem berjalan pada perangkat mobile dan digunakan secara real-time.

## 3.10 Metrik Evaluasi

Metrik evaluasi yang digunakan adalah:

### 3.10.1 Confusion Matrix

Confusion matrix terdiri dari:

1. **True Positive (TP)**: pengguna sah diterima.
2. **True Negative (TN)**: pengguna tidak sah ditolak.
3. **False Positive (FP)**: pengguna tidak sah diterima.
4. **False Negative (FN)**: pengguna sah ditolak.

### 3.10.2 Accuracy

```text
Accuracy = (TP + TN) / (TP + TN + FP + FN)
```

### 3.10.3 Precision

```text
Precision = TP / (TP + FP)
```

### 3.10.4 Recall

```text
Recall = TP / (TP + FN)
```

### 3.10.5 False Acceptance Rate

```text
FAR = FP / (FP + TN)
```

FAR menunjukkan persentase pengguna tidak sah yang salah diterima oleh sistem.

### 3.10.6 False Rejection Rate

```text
FRR = FN / (FN + TP)
```

FRR menunjukkan persentase pengguna sah yang salah ditolak oleh sistem.

### 3.10.7 Latency

Latency mengukur waktu yang dibutuhkan sistem untuk memproses frame wajah sampai menghasilkan keputusan presensi.

## 3.11 Rancangan Tabel Pengujian

### 3.11.1 Tabel Pengujian Similarity Pengguna Terdaftar

| No | Subjek | Kondisi Cahaya | Pose | Similarity | Keputusan Sistem | Keterangan |
|----|--------|----------------|------|------------|-------------------|------------|
| 1 | User 1 | Normal | Lurus | 0.xx | Diterima/Ditolak | - |
| 2 | User 1 | Rendah | Lurus | 0.xx | Diterima/Ditolak | - |
| 3 | User 1 | Normal | Menoleh | 0.xx | Diterima/Ditolak | - |

### 3.11.2 Tabel Pengujian Pengguna Tidak Terdaftar

| No | Subjek | Akun Target | Similarity | Keputusan Sistem | Keterangan |
|----|--------|-------------|------------|-------------------|------------|
| 1 | User A | User B | 0.xx | Diterima/Ditolak | - |
| 2 | User C | User D | 0.xx | Diterima/Ditolak | - |

### 3.11.3 Tabel Confusion Matrix

| Aktual / Prediksi | Diterima | Ditolak |
|-------------------|----------|---------|
| Pengguna Sah | TP | FN |
| Pengguna Tidak Sah | FP | TN |

### 3.11.4 Tabel Pengujian Threshold

| Threshold | TP | TN | FP | FN | Accuracy | FAR | FRR |
|-----------|----|----|----|----|----------|-----|-----|
| 0.60 | - | - | - | - | - | - | - |
| 0.65 | - | - | - | - | - | - | - |
| 0.70 | - | - | - | - | - | - | - |
| 0.75 | - | - | - | - | - | - | - |

## 3.12 Justifikasi Penggunaan Pretrained MobileFaceNet

Penelitian ini tidak melakukan training model CNN dari awal. Hal tersebut tidak mengurangi nilai akademik penelitian karena fokus penelitian adalah implementasi CNN pada sistem mobile dan evaluasi performa pada kasus presensi wajah.

Penggunaan pretrained MobileFaceNet dapat dijustifikasi melalui beberapa alasan:

1. MobileFaceNet telah dirancang sebagai arsitektur CNN ringan untuk perangkat mobile.
2. Training model wajah dari awal membutuhkan dataset sangat besar dan sumber daya komputasi tinggi.
3. Kontribusi penelitian terletak pada integrasi model CNN ke dalam pipeline presensi real-time.
4. Penelitian mengevaluasi performa model pada dataset lokal dan kondisi penggunaan nyata.
5. Penelitian menerapkan quality filtering dan multi-pose enrollment untuk meningkatkan keandalan sistem.
6. Penelitian menganalisis threshold similarity yang sesuai untuk kasus presensi.

## 3.13 Kebutuhan Perangkat Lunak

Perangkat lunak yang digunakan dalam penelitian ini adalah:

1. Flutter sebagai framework aplikasi mobile.
2. Dart sebagai bahasa pemrograman.
3. TensorFlow Lite untuk menjalankan model MobileFaceNet.
4. Google ML Kit untuk deteksi wajah dan landmark.
5. SQLite untuk penyimpanan embedding lokal.
6. Supabase untuk penyimpanan cloud dan sinkronisasi data.
7. Android sebagai platform pengujian.

## 3.14 Kebutuhan Perangkat Keras

Perangkat keras yang digunakan adalah:

1. Smartphone Android dengan kamera depan.
2. Laptop atau komputer untuk pengembangan aplikasi.
3. Koneksi internet untuk sinkronisasi data cloud.

## 3.15 Parameter Sistem

Parameter yang digunakan dalam sistem dapat dijelaskan sebagai berikut:

| Parameter | Keterangan |
|----------|------------|
| Model CNN | MobileFaceNet |
| Format model | TensorFlow Lite |
| Deteksi wajah | Google ML Kit Face Detection |
| Metode pencocokan | Cosine similarity |
| Threshold awal | 0.65 |
| Penyimpanan lokal | SQLite |
| Penyimpanan cloud | Supabase |
| Strategi enrollment | Multi-pose enrollment |
| Quality filtering | Ukuran wajah, pencahayaan, blur, pose kepala |

---

# Rekomendasi Judul

Judul utama yang direkomendasikan:

> **Implementasi Convolutional Neural Network Menggunakan Arsitektur MobileFaceNet untuk Pengenalan Wajah pada Sistem Presensi Mobile**

Alternatif judul:

1. **Implementasi MobileFaceNet untuk Pengenalan Wajah pada Sistem Presensi Mobile Berbasis Android**
2. **Implementasi dan Evaluasi MobileFaceNet pada Sistem Presensi Wajah Berbasis Mobile**
3. **Implementasi Pengenalan Wajah Berbasis Convolutional Neural Network pada Aplikasi Presensi Mobile**

Judul pertama paling disarankan karena sesuai dengan topik kampus, menonjolkan kata implementasi, menyebut CNN, menyebut MobileFaceNet, dan menjelaskan konteks penerapan pada sistem presensi mobile.

---

# Catatan Penyusunan Proposal

Agar proposal terlihat kuat secara akademik, pembahasan sebaiknya menekankan hal-hal berikut:

1. Fokus pada pengenalan wajah, bukan fitur UI aplikasi.
2. Jelaskan bahwa MobileFaceNet adalah implementasi CNN ringan untuk mobile.
3. Jelaskan bahwa kontribusi penelitian bukan training model baru, tetapi implementasi pipeline CNN pada sistem presensi.
4. Gunakan istilah akademik seperti face embedding, L2 normalization, cosine similarity, thresholding, FAR, FRR, genuine score, dan impostor score.
5. Tampilkan alur sistem dalam bentuk flowchart pada proposal final.
6. Sertakan tabel hasil pengujian untuk membuktikan performa sistem.
7. Batasi klaim liveness detection sesuai implementasi yang benar. Jika hanya digunakan pada enrollment, tuliskan sebagai validasi enrollment, bukan sebagai liveness presensi penuh.

---

# Rencana Pengembangan Penelitian

Tahapan pengerjaan penelitian dapat direncanakan sebagai berikut:

| Tahap | Kegiatan |
|------|----------|
| 1 | Studi literatur CNN, MobileFaceNet, dan pengenalan wajah |
| 2 | Analisis sistem Presensia dan pipeline presensi wajah |
| 3 | Implementasi dan penyempurnaan enrollment wajah |
| 4 | Implementasi pengujian presensi wajah |
| 5 | Pengumpulan data uji genuine dan impostor |
| 6 | Perhitungan similarity score dan confusion matrix |
| 7 | Analisis threshold, FAR, FRR, precision, recall, dan accuracy |
| 8 | Penyusunan laporan skripsi |

---

# Penutup

Proposal ini menempatkan Presensia sebagai penelitian implementasi pengenalan wajah berbasis CNN pada sistem presensi mobile. Fokus utama penelitian adalah bagaimana MobileFaceNet digunakan untuk mengekstraksi embedding wajah, bagaimana sistem melakukan prapemrosesan citra, bagaimana embedding dicocokkan menggunakan cosine similarity, serta bagaimana performa sistem dievaluasi menggunakan metrik biometrik.

Dengan fokus tersebut, penelitian ini sesuai dengan bidang Computer Vision dan AI + RPL, serta relevan dengan topik implementasi pengenalan wajah menggunakan metode Convolutional Neural Network berbasis citra.
