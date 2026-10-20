# Panduan orelio v0.3

## Preview tanpa build

Buka `orelio_mobile_preview_v0.3.html` di browser. Pilih Film → kategori → preset, lalu Adjust untuk melihat seluruh slider. Dalam Collage, gunakan Add Page → Choose Layout → ketuk frame untuk memilih foto. Ini *prototipe HTML*, bukan aplikasi iOS yang berjalan.

## Project Xcode

1. Ekstrak source ZIP.
2. Buka `orelio.xcodeproj` di Mac dengan Xcode yang mendukung iOS 17.
3. Atur signing Team dan Bundle ID.
4. Jalankan pada iPhone/simulator, impor foto dari Library, dan uji editor.
5. Collage: Add Page → Choose Layout → pilih foto pada frame → Export Pages. Project otomatis tersimpan di perangkat.

## Keamanan dan privasi

Editing dan export didesain lokal/offline. Original disimpan terpisah dari resep adjustment. Pastikan memiliki backup foto penting; implementasi ini belum diuji di perangkat nyata.

## Catatan penting

Filter merupakan interpretasi yang dikembangkan sendiri, bukan preset milik RNI. UI Collage mengambil inspirasi dari workflow SCRL tetapi desain dan rendering-nya independen. Editor freeform penuh dan seamless antarhalaman belum selesai.


## Menu baru v0.5 — Border dan Grid

**Border:** buka foto → tab **Border** → centang Outline / Border → pilih **Inside** atau **Outside**, pilih **White** atau **Black**, lalu geser ketebalan. Inside mempertahankan dimensi foto, Outside menambahkan piksel bingkai pada foto hasil ekspor. Border juga dapat dicopy/paste ke banyak foto melalui opsi `Outline / border` di sheet Paste Settings.

**Grid:** buka tab **Grid** → pilih jenis komposisi (Rule of Thirds, Golden Ratio, Center Marker, Golden Triangles, Square Grid). Golden Ratio dapat di-rotate per 90° dan dimirror untuk orientasi tambahan. Atur warna garis hitam/putih dan opacity. Pilih `Off` untuk menyembunyikan. Grid tidak ikut tersimpan ke foto atau ikut export.

**Catatan:** preview browser adalah simulasi UI. Kualitas render Core Image dan hasil ekspor perlu divalidasi dengan Xcode dan iPhone.
