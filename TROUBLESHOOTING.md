# Troubleshooting - Masalah Membuat Postingan

## Masalah Umum dan Solusi

### 1. Base URL API
**Masalah**: Base URL kosong atau salah
**Solusi**: 
- Edit file `lib/config/api_config.dart`
- Sesuaikan URL dengan API Laravel Anda:
  - Localhost: `http://localhost:8000/api`
  - Emulator Android: `http://10.0.2.2:8000/api`
  - Device fisik: `http://[IP_KOMPUTER]:8000/api`

### 2. Dependencies
**Masalah**: Package `http_parser` tidak terinstall
**Solusi**: Jalankan `flutter pub get` di terminal

### 3. Server Laravel
**Masalah**: API Laravel tidak berjalan
**Solusi**: 
- Pastikan server Laravel berjalan: `php artisan serve`
- Cek endpoint `/api/posts` bisa diakses
- Pastikan CORS sudah dikonfigurasi

### 4. Token Authentication
**Masalah**: Token expired atau tidak valid
**Solusi**: 
- Login ulang untuk mendapatkan token baru
- Cek token di SharedPreferences

### 5. Image Upload
**Masalah**: Gambar tidak terupload
**Solusi**:
- Pastikan format gambar didukung (JPG, PNG)
- Cek permission storage di Android
- Pastikan ukuran gambar tidak terlalu besar

### 6. Network Error
**Masalah**: Tidak bisa connect ke API
**Solusi**:
- Cek koneksi internet
- Pastikan firewall tidak memblokir
- Cek URL API benar

## Debug Steps

1. Buka Developer Tools (F12) di browser
2. Cek Console untuk error messages
3. Cek Network tab untuk request/response
4. Tambahkan `print()` statements di kode untuk debugging

## Log Error
Jika masih error, cek log di console Flutter untuk detail error message.
