# orelio v0.5 — panduan pemasangan gratis tanpa Mac

## Penting

- Tidak ada opsi Android-style "install from unknown sources" di iPhone Indonesia.
- Anda tidak perlu berlangganan Apple Developer Program untuk uji pribadi.
- Paket ini masih **source code + workflow**, bukan IPA hasil build. Build perlu dilakukan di macOS GitHub Actions, dan bisa gagal jika kode Xcode menemukan masalah; cek lognya.
- Jangan unggah Apple ID, password, sertifikat, atau provisioning profile ke GitHub.

## Tahap A — compile IPA menggunakan GitHub Actions

1. Masuk ke GitHub dan buat repository baru, lebih baik **Private** supaya source aplikasi tidak terbuka untuk umum. Gunakan kuota GitHub Actions gratis yang tersedia; hentikan penggunaan sebelum melewati kuota.
2. Upload **semua isi** folder paket ini ke **root repository**, termasuk `.github/workflows/build-unsigned-ipa.yml` dan `orelio.xcodeproj`.
   - Cara yang lebih mudah untuk mempertahankan folder tersembunyi `.github`: ekstrak ZIP di PC, buka terminal di folder, lalu jalankan `git init`, `git add .`, `git commit -m "orelio free sideload"`, dan push ke repository yang dibuat.
3. Di GitHub, buka **Actions → Build unsigned iPhone IPA (free sideload) → Run workflow**.
4. Jika berhasil, buka run tersebut → Artifacts → `orelio-unsigned-iphone-ipa`; download ZIP artifact dan ekstrak file `orelio-unsigned.ipa`.
5. Jika gagal, download artifact `orelio-device-build-log` dan perbaiki error Xcode sebelum mengulangi. Proyek **belum pernah diuji dengan Xcode di lingkungan ini**.

Catatan: workflow hanya berjalan bila Anda menjalankannya secara manual, agar tidak menghabiskan kuota secara tak sengaja.

## Tahap B — instalasi IPA ke iPhone tanpa bayar (Windows)

1. Unduh Sideloadly dari sumber resmi: https://sideloadly.io/
2. Instal iTunes dan iCloud untuk Windows sebagaimana disarankan oleh situs Sideloadly jika perangkat tidak terdeteksi.
3. Sambungkan iPhone ke Windows dengan kabel, buka kunci, dan tap **Trust This Computer**.
4. Buka Sideloadly, pilih iPhone, seret `orelio-unsigned.ipa`, pilih **Apple ID Sideload**, dan ikuti proses autentikasi memakai Apple Account gratis Anda. Jangan kirim detail akun kepada siapa pun.
5. Jika diminta, di iPhone buka **Settings → General → VPN & Device Management**, lalu percayai profil pengembang Anda. Buka **Settings → Privacy & Security → Developer Mode** bila diperlukan, dan restart sesuai petunjuk.
6. Buka orelio dari layar utama iPhone. Jika instalasi gagal, simpan pesan error Sideloadly dan log dari GitHub Actions.

## Batasan gratis

- Masa berlaku penandatanganan biasanya **7 hari**; perlu refresh atau instal ulang secara berkala.
- Batas umumnya **3 aplikasi sideload aktif** pada akun Apple gratis.
- Sideloadly menawarkan penyegaran otomatis melalui PC bila disetel dengan benar.
- Proses build cloud, autentikasi dan instalasi awal membutuhkan internet; **editing foto orelio tetap dirancang offline setelah terpasang**.

## Alternatif

Jika hanya memiliki iPhone (tidak ada PC Windows atau Mac), jalur gratis ini tidak menyediakan instalasi langsung hanya dengan mengetuk IPA dari aplikasi Files/Safari.
