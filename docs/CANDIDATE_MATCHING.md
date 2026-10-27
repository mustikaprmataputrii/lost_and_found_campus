# Candidate Matching Laporan Hilang dan Temuan

Dokumen ini mencatat implementasi candidate matching pada aplikasi TEMU UIN
Malang. Fitur ini mencocokkan laporan barang hilang dengan laporan barang
ditemukan, lalu menampilkan kandidat paling mirip di halaman detail laporan.

Candidate matching dijalankan di sisi Flutter. Tidak ada perubahan skema
database, endpoint PHP, atau format sinkronisasi pada tahap ini.

## Tujuan

1. Membantu pengguna menemukan laporan jenis sebaliknya yang mungkin merujuk
   pada barang yang sama.
2. Memberi alasan yang dapat dibaca pengguna, bukan hanya angka skor.
3. Menjaga agar rekomendasi tidak mengubah status laporan secara otomatis.

## Aturan kandidat

Sebuah laporan hanya dibandingkan jika:

- jenisnya berbeda (hilang dengan ditemukan);
- bukan laporan yang sama;
- status kandidat belum `selesai`;
- laporan yang sedang dilihat belum `selesai`;
- pemilik emailnya tidak sama, bila kedua laporan memiliki email pemilik.

Laporan yang selesai atau dimiliki akun yang sama sengaja dilewati karena tidak
memberi tindak lanjut yang berguna.

## Sumber data

Skor memakai data yang sudah tersedia di `BarangItem`:

- nama barang;
- deskripsi/ciri-ciri;
- lokasi;
- tanggal laporan;
- jenis dan status laporan;
- email pemilik, hanya untuk filter kepemilikan.

Tidak ada data baru yang dikirim ke server.

## Normalisasi teks

Teks diubah ke huruf kecil, tanda baca diganti spasi, lalu dipecah menjadi token.
Kata umum seperti `yang`, `dan`, `di`, `barang`, `hilang`, `ditemukan`, `warna`,
dan `kampus` dibuang agar tidak mendominasi skor.

Ada kamus sinonim kecil:

- `hp`, `ponsel`, `telepon` -> `handphone`
- `ransel` -> `tas`

Normalisasi ini sederhana dan deterministik; bukan model bahasa atau embedding.

## Rumus skor

Untuk setiap pasangan laporan:

```text
text    = (0.60 x skor_nama) + (0.40 x skor_deskripsi)
skor    = (0.60 x text) + (0.25 x skor_lokasi) + (0.15 x skor_waktu)
```

Dengan demikian bobot efektifnya:

| Komponen | Bobot efektif |
|---|---:|
| Nama barang | 36% |
| Deskripsi | 24% |
| Lokasi | 25% |
| Kedekatan waktu | 15% |

### Kemiripan nama dan deskripsi

Kemiripan token memakai koefisien Dice:

```text
2 x jumlah token yang sama / (jumlah token A + jumlah token B)
```

Nilai berada pada rentang 0 sampai 1. Laporan dengan kemiripan teks di bawah
`0.05` tidak diproses lebih lanjut agar laporan yang sama sekali tidak terkait
tidak muncul sebagai kandidat.

### Kemiripan lokasi

- Lokasi sama setelah normalisasi: `1.00`
- Satu lokasi mengandung lokasi lainnya: `0.85`
- Selain itu: koefisien Dice lokasi x `0.70`

### Kedekatan waktu

| Selisih waktu | Skor |
|---|---:|
| <= 24 jam | 1.00 |
| <= 3 hari | 0.80 |
| <= 7 hari | 0.60 |
| <= 30 hari | 0.30 |
| > 30 hari | 0.00 |

### Ambang dan batas

- Skor minimum agar ditampilkan: `0.42`.
- Maksimal kandidat per laporan: `3`.
- Kandidat diurutkan berdasarkan skor tertinggi, lalu selisih waktu terdekat,
  lalu ID laporan sebagai penentu stabil.

Contoh: nama, deskripsi, lokasi, dan tanggal sama menghasilkan skor `1.00`;
nama, deskripsi, dan lokasi sama tetapi selisih dua hari menghasilkan sekitar
`0.97`.

## Alasan yang ditampilkan

Kandidat dapat memiliki label:

- **Nama barang mirip** jika skor nama >= 0,45;
- **Deskripsi mirip** jika skor teks >= 0,45 tetapi nama belum memenuhi;
- **Lokasi berdekatan** jika skor lokasi >= 0,60;
- **Waktu berdekatan** jika skor waktu >= 0,60;
- **Kata kunci mirip** sebagai fallback bila tidak ada label lain.

## Tampilan

Halaman detail laporan menampilkan bagian **Kandidat cocok** bila ada hasil.
Setiap kartu menampilkan:

- persentase kecocokan;
- jenis laporan kandidat;
- nama, lokasi, tanggal, dan cuplikan deskripsi;
- label alasan;
- tombol ketuk untuk membuka detail kandidat.

Membuka kandidat tidak mengubah status, klaim, atau chat secara otomatis.
Pengguna tetap memutuskan sendiri apakah akan menghubungi pelapor.

## Pengujian

Test baru berada di `test/candidate_matching_test.dart`:

1. menemukan laporan jenis sebaliknya yang mirip;
2. mengabaikan jenis sama, laporan selesai, dan pemilik sama;
3. mengabaikan laporan yang tidak mirip;
4. mengurutkan skor dan membatasi jumlah kandidat;
5. menormalkan huruf, tanda baca, dan sinonim `hp`;
6. menampilkan kandidat di detail dan meneruskan ketukan.

Total test repository setelah fitur ini: **48**, semuanya lulus. `flutter analyze`
juga lulus tanpa issue.

## Batasan

- Pencocokan hanya berbasis kata, bukan makna. Istilah yang sangat berbeda tetapi
  merujuk barang yang sama dapat terlewat.
- Singkatan di luar kamus sinonim kecil belum dikenali.
- Skor adalah rekomendasi, bukan bukti kepemilikan. Pengguna tetap perlu
  memverifikasi melalui chat.
- Kandidat hanya dihitung dari data yang sudah tersinkron ke perangkat.
- Laporan milik akun yang sama tidak ditampilkan sebagai kandidat.
- Belum ada notifikasi otomatis saat laporan baru memiliki kandidat.
- Ambang `0.42` dan bobot belum dikalibrasi dengan dataset laporan nyata.
- Fitur belum diuji pada APK/perangkat fisik pada tahap ini.

## Langkah berikutnya

1. Kumpulkan contoh laporan nyata dan evaluasi precision/recall secara manual.
2. Kalibrasi bobot, ambang, dan daftar sinonim berdasarkan hasil evaluasi.
3. Pertimbangkan notifikasi kandidat atau endpoint pencocokan di server.
4. Uji alur kandidat pada APK dan perangkat fisik.
