# orelio — Build dan uji langsung di iPhone

Status: **source siap dibuka di Xcode, belum berhasil dikompilasi atau dipasang di iPhone**. Pemeriksaan Linux **tidak menggantikan** build Apple.

## Cara termudah: Xcode + Apple Account gratis

1. Di Mac, instal Xcode dari Mac App Store, buka sekali hingga komponen tambahan selesai terpasang.
2. Ekstrak ZIP dan buka **`orelio.xcodeproj`**.
3. Di Xcode > Settings > Accounts, login Apple Account Anda. Akun gratis akan tersedia sebagai `Personal Team`.
4. Klik target **orelio** > **Signing & Capabilities**. Aktifkan `Automatically manage signing`, pilih `Team` milik Anda, dan ganti Bundle Identifier `com.example.orelio` dengan ID yang unik, misalnya `id.namaanda.orelio`.
5. Sambungkan iPhone menggunakan kabel, buka kuncinya, pilih **Trust This Computer** saat ditanya. Jika iOS memintanya, aktifkan **Developer Mode** di Settings > Privacy & Security > Developer Mode dan restart sesuai petunjuk.
6. Di toolbar Xcode pilih scheme **orelio** dan tujuan **iPhone Anda**, bukan simulator.
7. Klik tombol **Run (▶)**. Xcode akan build, sign, install, dan menjalankan app. Jika terdapat error kompilasi, salin `Issue Navigator` atau build log ke ChatGPT untuk diperbaiki.
8. Aplikasi dapat digunakan secara offline sesudah terpasang. Build dengan akun gratis perlu diperbarui setelah masa berlaku provisioning berakhir (biasanya **7 hari**).

> **Perlu Mac untuk jalur Xcode ini.** Apple ID dan password tidak perlu dibagikan kepada ChatGPT. Jangan kirim file sertifikat private key atau provisioning profile pribadi.

## Build otomatis melalui terminal Mac (opsional)

Setelah Team diatur dari Xcode dan perangkat terdaftar:

```bash
./tools/build_simulator_on_mac.sh
# atau untuk perangkat:
ORELIO_DEVICE_ID='UDID_DARI_XCODE' ./tools/build_on_mac.sh
# build + install via devicectl (Xcode CLI terkini):
ORELIO_DEVICE_ID='UDID_DARI_XCODE' ORELIO_INSTALL=1 ./tools/build_on_mac.sh
```

Dapat memberi override secara opsional memakai `ORELIO_TEAM_ID` dan `ORELIO_BUNDLE_ID`; gunakan nilai milik Anda dan jangan membagikan kredensial Apple. Hasil build dan log tersimpan di `.build-iphone/` atau `.build-simulator/`.

## Build verification dengan GitHub Actions (bukan instalasi)

Workflow `.github/workflows/ios-build-check.yml` menggunakan runner macOS untuk *compile check* simulator tanpa code signing. Setelah source ini ditempatkan ke GitHub repository, jalankan workflow melalui tab Actions. Artefak `.app` simulator **tidak bisa dipasang di iPhone asli**. Build perangkat tetap memerlukan penandatanganan Apple.

## Jika tidak punya Mac

Untuk aplikasi native SwiftUI ini, dibutuhkan lingkungan build macOS/Xcode (Mac milik sendiri atau Mac cloud) dan proses signing oleh Apple. Untuk memasang lewat **TestFlight** ke iPhone tanpa koneksi Mac langsung, Anda memerlukan Apple Developer Program serta build yang diunggah ke App Store Connect. Kami tidak memiliki koneksi signing atau fasilitas upload tersebut dalam sesi ini.

## Checklist pengujian di iPhone

- [ ] Import foto dari Files/Photos.
- [ ] Film: ganti preset dan periksa thumbnail vs hasil.
- [ ] Tools: cek semua kontrol dan respons slider.
- [ ] Lighting: geser efek ke tepi foto, pastikan tidak keluar area.
- [ ] Border: inside/outside, warna putih/hitam, cek resolusi hasil.
- [ ] Grid: Rule of Thirds, Golden Spiral (rotate/mirror), Center, Golden Triangles, Square.
- [ ] Grid tidak ikut ke file ekspor.
- [ ] Copy edit satu foto ke beberapa foto, lalu undo.
- [ ] Export JPEG/PNG/HEIC multi-foto dan cek file di Files.
- [ ] Collage: Add Page, pilih layout, isi frame, dan export beberapa halaman.
- [ ] Mode pesawat: semua fitur tetap berfungsi.

## Dokumentasi resmi

- Xcode di perangkat: https://help.apple.com/xcode/mac/current/en.lproj/dev5a825a1ca.html
- Apple Personal Team: https://developer.apple.com/help/account/basics/about-your-developer-account
- TestFlight: https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/
