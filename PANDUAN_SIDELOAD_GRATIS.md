# Orelio — instalasi IPA gratis di iPhone menggunakan Windows

## 1. Download IPA yang benar (BUKAN simulator)

Repository: https://github.com/ikhsanadityaaa/orelio-app

1. Di GitHub, buka **Actions**.
2. Pilih workflow **Build unsigned iPhone IPA (free sideload)**.
3. Pilih run terbaru yang ditandai **Success** pada branch `main`.
4. Di halaman run, buka bagian **Artifacts**, pilih **orelio-unsigned-iphone-ipa** (bukan `orelio-simulator-only`).
5. Download ZIP artifact, lalu **extract** hingga mendapat **`orelio-unsigned.ipa`**.
6. Jangan extract isi file `.ipa` lagi. Seret file `.ipa` tersebut ke Sideloadly.

Build baru otomatis dibuat ketika source iOS atau workflow IPA berubah. Untuk menjalankan secara manual: **Actions → Build unsigned iPhone IPA (free sideload) → Run workflow → main → Run workflow**.

**Info penting:** Paket ini adalah iPhone **arm64/iphoneos** yang belum ditandatangani (unsigned). Proses build sukses memastikan kompilasi dan struktur paket, bukan menjamin berhasil diinstal pada setiap iPhone.

## 2. Pasang dengan Sideloadly di Windows

1. Di Windows, unduh **Sideloadly** dari https://sideloadly.io/
2. Jika diminta Sideloadly, pasang iTunes/iCloud yang kompatibel untuk mendeteksi iPhone.
3. Hubungkan iPhone ke komputer dengan kabel, buka kuncinya, dan setujui **Trust This Computer**.
4. Buka Sideloadly, pilih perangkat Anda, lalu masukkan file **`orelio-unsigned.ipa`**.
5. Pilih mode **Apple ID Sideload**, masukkan Apple Account sendiri melalui proses autentikasi Sideloadly, dan jalankan instalasi. **Jangan pernah mengirim password, kode 2FA atau Apple ID ke chat/GitHub.**
6. Jika iPhone meminta persetujuan, buka **Settings → General → VPN & Device Management** dan percayai profil pengembang yang sesuai. Aktifkan **Settings → Privacy & Security → Developer Mode** apabila diminta.

Apple Account gratis umumnya membatasi masa signing aplikasi sekitar **7 hari** dan jumlah aplikasi sideload aktif. Perlu refresh/instal ulang setelah masa itu.

## 3. Kalau gagal

- **ZIP berisi `Info.plist`, `Assets.car`, `orelio`, `__preview.dylib`**: itu kemungkinan besar artifact **simulator** yang salah. Jangan instal isi folder tersebut.
- **Run workflow merah/Failed**: klik **Build real iPhone arm64 app and package unsigned IPA** pada run dan ambil error log; atau unduh artifact **orelio-device-build-log**.
- **Sideloadly menolak IPA**: simpan error lengkap, tipe iPhone dan versi iOS, lalu laporkan untuk memperbaiki paket/signing. Perhatikan kompatibilitas minimum iOS 17.
- **IPA hanya dibuka di Files iPhone**: itu bukan cara pemasangan aplikasi unsigned. Gunakan Windows + Sideloadly untuk menandatangani.

Build GitHub menggunakan macOS runner, sehingga Anda tidak perlu memasang Xcode secara lokal. Instalasi dan penandatanganan tetap dilakukan di komputer Windows. Editing foto Orelio ditujukan untuk bekerja offline setelah instalasi.
