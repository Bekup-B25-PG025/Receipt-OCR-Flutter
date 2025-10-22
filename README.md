# SmartNote – Receipt OCR Flutter App

![Flutter](https://img.shields.io/badge/Flutter-3.22%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

Digitalisasi nota belanja dengan Flutter + Google Gemini.  
Ambil foto struk, biarkan AI mengurai item & totalnya, review hasilnya, lalu simpan. Lihat riwayat transaksi dan laporan per bulan — tanpa backend (local-first). Cocok untuk demo/POC dan bisa diupgrade ke Firebase kapan pun.

---

## ✨ Fitur

- ✅ **Scan nota** dari kamera atau galeri
- 🤖 **OCR & parsing AI** (Gemini 1.5 Flash) → merchant, tanggal, mata uang, item (nama/qty/harga), subtotal, pajak, total
- ✏️ **Review & edit** hasil AI sebelum simpan (subtotal & total auto-recalc)
- 📋 **Riwayat**: daftar semua nota; ketuk untuk melihat/mengedit kembali
- 📊 **Laporan bulanan**: grup per bulan + total bulanan
- 💾 **Local-first**: data disimpan di perangkat (receipts.json + gambar di folder images/)

---

## 🧱 Tech Stack

- **Flutter** (Material 3) + **Provider** (state management)
- **google_generative_ai** (Gemini API)
- **image_picker**, **path_provider**, **intl**, **uuid**
- **Branding**: flutter_launcher_icons, flutter_native_splash

---

## 🗂️ Struktur Data Lokal

File & gambar disimpan di **Application Documents Directory**:

```
<app-documents>/smartnote/
  ├─ receipts.json            # database ringan (JSON)
  └─ images/
      └─ <id>.jpg             # foto nota tersimpan
```

> **Note:** Tidak ada backend yang dibutuhkan. App tetap berfungsi offline untuk baca/lihat/edit data yang sudah tersimpan. OCR AI membutuhkan koneksi saat memanggil Gemini.

---

## 🚀 Quick Start

### 1️⃣ Prasyarat

- Flutter 3.22+
- Android SDK / Xcode (untuk run di device)
- Akun [Google AI Studio](https://makersuite.google.com/app/apikey) (API Key)

### 2️⃣ Clone & Install

```bash
git clone https://github.com/Bekup-B25-PG025/Receipt-OCR-Flutter.git
cd Receipt-OCR-Flutter
flutter pub get
```

### 3️⃣ API Key (Gemini)

Buat file `.env` di root proyek:

```env
GEMINI_API_KEY=PASTE_API_KEY_DI_SINI
```

Pastikan `pubspec.yaml` sudah memuat:

```yaml
flutter:
  assets:
    - .env
```

> ⚠️ **Jangan commit `.env` ke repo publik!**

### 4️⃣ Jalankan

```bash
flutter run
```

---

## 🧠 Model AI yang Dipakai

**Model:** `gemini-1.5-flash` (disarankan & gratisan AI Studio)

App sudah memformat prompt & output ke JSON dengan skema:

```json
{
  "merchant": "string | null",
  "date": "YYYY-MM-DD",
  "currency": "IDR|USD|...",
  "payment_method": "string | null",
  "items": [{"name":"string", "qty": number, "price": number}],
  "subtotal": number,
  "tax": number,
  "total": number,
  "raw_text": "full OCR text"
}
```

---

## 📱 Branding (Ikon & Splash)

Taruh aset di:

```
assets/branding/
  ├─ icon-foreground.png
  ├─ icon_background_blue.png
  ├─ splash-icon.png
  └─ branding.png
```

Contoh konfigurasi di `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/branding/icon-foreground.png
  adaptive_icon_foreground: assets/branding/icon-foreground.png
  adaptive_icon_background: assets/branding/icon_background_blue.png
  remove_alpha_ios: true

flutter_native_splash:
  color: "#0B0710"
  image: assets/branding/splash-icon.png
  branding: assets/branding/branding.png
  color_dark: "#0B0710"
  image_dark: assets/branding/splash-icon.png
  branding_dark: assets/branding/branding.png
  android: true
  ios: true
  web: false
  android_12:
    icon_background_color: "#0B0710"
    image: assets/branding/splash-icon.png
    branding: assets/branding/branding.png
```

Generate:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 🧭 Navigasi Aplikasi

| Screen | Deskripsi |
|--------|-----------|
| **Home** | Ambil/unggah foto → AI parse → Konfirmasi Review → Simpan |
| **History** | Daftar nota tersimpan → ketuk untuk detail & edit |
| **Report** | Rekap per bulan (daftar transaksi & total) |

---

🛠️ Troubleshooting

1) “models/gemini-1.5-flash is not found for API version v1beta …”

Pastikan paket cukup baru:

flutter pub upgrade google_generative_ai


Pakai model gemini-1.5-flash (bukan alias yang tidak tersedia).

2) Ikon/splash gagal: “PathNotFoundException …assets/branding/…”

Cek path & nama file (case-sensitive).

Jalankan ulang:

dart run flutter_launcher_icons
dart run flutter_native_splash:create


3) “Impeller does not support software rendering”

Jangan pakai --enable-software-rendering bersamaan dengan Impeller.

Cukup flutter run biasa, atau flutter run --no-impeller.

4) “Unsupported operation: Cannot modify an unmodifiable list” (Report)

Saat ingin sort, salin dulu: final list = receipts.toList()..sort(...);

### 5. Perubahan tidak muncul

Uninstall app dari device (clear cache), lalu `flutter run` lagi.

---

## 🧩 Folder Penting

```
lib/
  ├─ models/
  │   └─ receipt.dart              # model nota & item
  ├─ providers/
  │   └─ receipt_provider.dart     # state draft + analyze
  ├─ screens/
  │   ├─ home_screen.dart          # ambil/galeri gambar
  │   ├─ review_screen.dart        # review & edit (auto-recalc)
  │   ├─ history_screen.dart       # daftar riwayat
  │   └─ report_screen.dart        # laporan per bulan
  ├─ services/
  │   ├─ gemini_service.dart       # panggil Gemini API
  │   └─ local_store_service.dart  # simpan/baca JSON lokal
  └─ app.dart                      # root + bottom nav
```

---

## 🗺️ Roadmap

- [ ] Sinkronisasi Firebase (opsional) saat akun siap
- [ ] Kategori pengeluaran & grafik
- [ ] Ekspor CSV/PDF
- [ ] Multi-bahasa (i18n)
- [ ] Dark mode theme

---

## 🤝 Kontribusi

Pull request & issue dipersilakan!  
Mohon **jangan sertakan API key atau data sensitif** di commit.

---

## 📄 Lisensi

Pilih lisensi sesuai kebutuhan (mis. MIT).  
Tambahkan file `LICENSE` di root proyek.

---

## 🙌 Kredit

- [Google Gemini API](https://ai.google.dev/)
- Paket komunitas Flutter (lihat `pubspec.yaml`)
- Icons dari [Material Design](https://fonts.google.com/icons)

---

**Dibuat dengan ❤️ menggunakan Flutter & Gemini AI**