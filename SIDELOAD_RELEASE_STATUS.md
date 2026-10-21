# Orelio — status unsigned iPhone IPA

**Build perangkat fisik berhasil.** Workflow macOS GitHub Actions sekarang menjalankan build iOS ARM64 (bukan simulator), memeriksa platform `iPhoneOS` serta executable ARM64, kemudian mengemas `Payload/orelio.app` menjadi `orelio-unsigned.ipa`.

- [x] Source iOS berada di repository `ikhsanadityaaa/orelio-app`.
- [x] Build `Release-iphoneos` menggunakan Xcode macOS GitHub Actions.
- [x] Pemeriksaan model dan kompatibilitas proyek Collage sukses.
- [x] Struktur ZIP IPA diverifikasi.
- [x] Artifact `orelio-unsigned-iphone-ipa` berhasil dibuat di GitHub Actions.
- [x] Build berjalan otomatis ketika file native iOS/workflow IPA berubah, dan bisa dijalankan manual dari Actions.
- [ ] Belum ditandatangani dan diinstal menggunakan Sideloadly pada iPhone fisik.
- [ ] Runtime foto, kamera, permissions, ekspor dan performa di iPhone fisik belum diuji.

**Build sukses pertama dari workflow terbarukan:** [GitHub Actions run #39523042644](https://github.com/ikhsanadityaaa/orelio-app/actions/runs/39523042644), commit `5ab6e975700aac3fe2a5397740d1abd20966093f`.

**Artifact IPA:** [orelio-unsigned-iphone-ipa](https://github.com/ikhsanadityaaa/orelio-app/actions/runs/39523042644/artifacts/12312317174). Artifact memiliki masa simpan terbatas; gunakan workflow terbaru jika sudah kedaluwarsa.

**Panduan pemasangan:** [PANDUAN_SIDELOAD_GRATIS.md](PANDUAN_SIDELOAD_GRATIS.md)

> IPA unsigned bukan aplikasi yang siap dipasang langsung dari Files. Gunakan Sideloadly di Windows dengan Apple Account milik sendiri agar dapat di-sign dan diinstal, sesuai batasan Apple ID gratis.
