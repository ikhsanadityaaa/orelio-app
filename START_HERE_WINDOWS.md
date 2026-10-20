# Orelio — Panduan Upload dan Build IPA di Windows

**Repository:** https://github.com/ikhsanadityaaa/orelio-app

### 1. Push source (tanpa GitHub CLI)
Ekstrak ZIP ini; lalu double-click `UPLOAD_TO_GITHUB.cmd`.
Git for Windows wajib terpasang. Jika muncul `git not installed`, jalankan `winget install --id Git.Git -e`, tutup CMD dan buka kembali. Login GitHub melalui browser saat Git Credential Manager memintanya.

Script mempertahankan branch `main` yang sudah ada dan tidak melakukan force-push. Setelah selesai, periksa source `orelio/`, `orelio.xcodeproj`, `tools/` dan `.github/workflows/` di repository.

### 2. Build iOS dari GitHub
Buka https://github.com/ikhsanadityaaa/orelio-app/actions/workflows/build-unsigned-ipa.yml , pilih **Run workflow**, branch `main`.
Jika sukses, buka run → Artifacts → `orelio-unsigned-iphone-ipa` → download ZIP artifact → ekstrak `orelio-unsigned.ipa`. Jika gagal, unduh artifact build log dan periksa error Xcode.
Build ini menggunakan runner macOS GitHub Actions dan dapat menggunakan kuota Actions Anda. Workflow tidak dijalankan otomatis setiap commit.

### 3. Sideload dari Windows
Gunakan Sideloadly resmi https://sideloadly.io/ untuk menandatangani IPA menggunakan Apple Account Anda sendiri dan memasang melalui USB. IPA unsigned tidak bisa dipasang di iPhone hanya dengan membuka filenya. Akun Apple gratis biasanya perlu memperbarui signing setiap sekitar 7 hari.

**Status:** Source v0.5 ada dalam ZIP. Build macOS belum dikonfirmasi sukses dan app belum diuji pada iPhone asli. Jangan unggah kredensial, key, atau provisioning profile ke GitHub.
