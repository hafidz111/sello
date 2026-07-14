# Sello — Jualan Cerdas dengan AI

Aplikasi mobile (Flutter) untuk membantu UMKM mengelola penjualan dengan bantuan AI:
pencatatan kasir via suara & scan produk, pembuatan konten dari foto produk, laporan
bisnis berbahasa manusia, katalog digital, dan lainnya.

> **Status proyek:** tahap awal. Kerangka aplikasi sudah jadi. **Kasir Suara & Scan**
> (satu layar), **daftar produk dengan foto**, **katalog produk**, dan **statistik beranda**
> sudah berjalan. Barcode/Code 128 dan fitur lainnya masih rencana.
> Lihat [Status Fitur](#status-fitur).

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Arsitektur Produk & Scan](#arsitektur-produk--scan)
- [Status Fitur](#status-fitur)
- [Teknologi](#teknologi)
- [Struktur Folder](#struktur-folder)
- [Prasyarat](#prasyarat)
- [Konfigurasi Environment (.env)](#konfigurasi-environment-env)
- [Firebase](#firebase)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Build & Rilis ke Play Store](#build--rilis-ke-play-store)
- [State Management](#state-management)
- [Konvensi Kode](#konvensi-kode)
- [Tema & Desain](#tema--desain)
- [Responsivitas](#responsivitas)
- [Keamanan & File Rahasia](#keamanan--file-rahasia)
- [Roadmap](#roadmap)

---

## Tentang Aplikasi

- **Nama:** Sello
- **Package/Application ID:** `com.titiksenyapstudio.sello`
- **Pengembang:** Titik Senyap Studio
- **Tagline:** Jualan Cerdas dengan AI

Alur aplikasi saat ini:

1. Pengguna membuka aplikasi → **halaman Login**.
2. Setelah login → **MainShell** dengan 5 tab: Beranda, Kasir, Konten, Laporan, Menu.
3. Navigasi memakai **floating bottom navbar** yang responsif.

---

## Arsitektur Produk & Scan

### Yang sudah berjalan (visual match)

1. **Daftar produk** (`ProductRegisterScreen`): nama, harga, stok, foto referensi
   (depan/samping/label) → disimpan ke Supabase (`products`, `product_images`, bucket
   `product-images`).
2. **Scan penjualan** (tab Kasir, mode Scan): kamera live → AI `matchProductToCatalog` →
   jika confidence ≥ 65% produk terklaim otomatis → atur qty → `recordSale` (kurangi stok).
3. **Kasir suara** (tab Kasir, mode Suara): ketuk mikrofon → ucapan natural → AI `extractSale`
   → daftar item + total di layar yang sama.
4. **Katalog** (`ProductListScreen`): lihat produk terdaftar dari fitur Katalog Digital.

### Rencana berikutnya (barcode & suara)

| Fase | Metode | Status |
|------|--------|--------|
| Daftar | Suara lengkap, scan barcode retail, generate Code 128 | Belum |
| Jualan | Scan Code 128 / barcode → lookup DB | Belum (teman user) |
| Jualan | Suara singkat → fuzzy match nama | Belum |

### Skema database (migrasi `supabase/migrations/`)

```
products          id, user_id, name, price, stock, created_at
product_images    product_id, storage_path, angle_label, sort_order
sales             user_id, product_id, quantity, unit_price, total, created_at
```

Kolom `code_type` / `code_value` untuk barcode akan ditambahkan di migrasi terpisah.

### Alur scan visual (implementasi saat ini)

```
Kamera live → ambil frame → AI bandingkan dengan foto katalog user
        │
        ├── Cocok (≥65%) → auto klaim → stepper qty → catat penjualan
        └── Tidak cocok → pilih manual / daftar produk baru
```

Detail arsitektur lengkap ada di [`.context/context.md`](.context/context.md).

---

## Status Fitur

Legenda: **Selesai** · **Sebagian** · **Belum**

### Fitur Aplikasi (UI/Kerangka)

| Fitur | Status | Keterangan |
|-------|:------:|------------|
| Halaman Login | Selesai | Firebase Auth (email/password). Register & lupa password tersedia. |
| Halaman Beranda | Selesai | Statistik penjualan & transaksi dari Supabase (`DashboardProvider`). |
| Floating bottom navbar | Selesai | 5 tab, animasi aktif, responsif tablet. |
| Halaman Menu | Selesai | Daftar semua fitur + tombol logout. |
| Logout | Selesai | Dialog konfirmasi, reset ke tab Beranda. |
| AppSnackbar | Selesai | Notifikasi error/success/warning/info kustom. |
| SafeArea global | Selesai | Diterapkan di seluruh layar. |
| Responsivitas tablet | Selesai | Breakpoint & layout menyesuaikan lebar layar. |

### Fitur Utama (Bisnis) — 8 Fitur

| # | Fitur | Status | Keterangan |
|---|-------|:------:|------------|
| 1 | Kasir Suara & Scan | Sebagian | Suara singkat + fuzzy match katalog + pelanggan; daftar produk lewat suara lengkap. Scan + customer. Barcode belum. |
| 2 | Foto ke Konten | Belum | Placeholder. Upload foto & generator caption. |
| 3 | Asisten WhatsApp | Belum | Belum ada halaman & integrasi WhatsApp Business API. |
| 4 | Laporan Bisnis | Selesai | Filter periode + rentang tanggal; penjualan/laba/transaksi/item; produk & pelanggan; laporan AI. |
| 5 | Terjemah & Ekspor | Belum | Belum ada halaman & mesin terjemahan. |
| 6 | Katalog Digital | Sebagian | Daftar produk terdaftar (`ProductListScreen`). Link share belum. |
| 7 | Mode Offline | Belum | Belum ada penyimpanan lokal & sinkronisasi. |
| 8 | Edukasi Mikro | Selesai | Tips AI dari penjualan 30 hari terakhir (Menu / kartu fitur). |

### Backend & Integrasi

| Komponen | Status | Keterangan |
|----------|:------:|------------|
| Supabase | Sebagian | Tabel produk, gambar, penjualan + RLS per-user (Firebase UID). Bucket gambar privat. |
| Firebase | Selesai | `Firebase.initializeApp` + Auth (login/register/reset). JWT diteruskan ke Supabase. |
| Autentikasi asli | Selesai | Firebase Auth. `userId` = Firebase UID. |
| Layanan AI (Gemini) | Sebagian | `extractSale`, `matchProductToCatalog` berjalan. Input suara via `speech_to_text`. |

---

## Teknologi

- **Flutter** (Dart SDK `^3.12.2`)
- **Provider** — state management
- **dio** — HTTP client terpusat (`DioClient`, `GeminiApiService`)
- **supabase_flutter** — produk, gambar, penjualan, storage
- **camera**, **image_picker**, **permission_handler**, **speech_to_text** — scan, daftar produk, kasir suara
- **firebase_core / firebase_auth** — login, register, reset password; JWT ke Supabase RLS
- **flutter_dotenv** — konfigurasi environment via `.env`
- **flutter_lints** — aturan linting

Package rencana: `mobile_scanner`, `barcode_widget`.

---

## Struktur Folder

```
lib/
├── main.dart                     # Entry: load .env → Firebase → Supabase → runApp
├── app.dart                      # MultiProvider + MaterialApp + AuthGate
├── firebase_options.dart         # Konfigurasi Firebase
│
├── core/
│   ├── config/
│   │   ├── env.dart              # Env.supabaseUrl, geminiApiKey, geminiModel, dll
│   │   └── supabase_config.dart  # Supabase + accessToken Firebase JWT
│   ├── network/
│   │   ├── dio_client.dart       # Dio terpusat (Gemini + REST custom)
│   │   └── network_exception.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── feature_data.dart     # Daftar 8 fitur (id & route Bahasa Inggris)
│   │   └── gemini_schemas.dart   # JSON schema untuk respons AI terstruktur
│   └── utils/
│       ├── responsive.dart
│       ├── currency.dart         # formatRupiah()
│       └── feature_navigation.dart
│
├── models/
│   ├── feature_item.dart
│   ├── nav_item.dart
│   ├── sale_item.dart
│   ├── product.dart
│   ├── product_image.dart
│   ├── product_match_result.dart
│   ├── dashboard_stats.dart
│   ├── report_period.dart
│   ├── business_report.dart
│   └── product_sales_summary.dart
│
├── providers/
│   ├── auth_provider.dart
│   ├── navigation_provider.dart
│   ├── dashboard_provider.dart
│   └── report_provider.dart
│
├── services/
│   ├── ai_service.dart           # Logika bisnis AI
│   ├── gemini_api_service.dart   # HTTP Gemini via Dio
│   ├── product_service.dart
│   └── report_service.dart       # Agregasi laporan penjualan
│
├── screens/
│   ├── auth/login_screen.dart
│   ├── home/home_screen.dart
│   ├── shell/main_shell.dart
│   ├── menu/menu_screen.dart
│   └── features/
│       ├── cashier_screen.dart
│       ├── content_screen.dart
│       ├── report_screen.dart
│       ├── product_register_screen.dart
│       ├── product_scan_screen.dart
│       └── product_list_screen.dart
│
├── styles/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
│
└── widgets/
    ├── navigation/floating_bottom_nav.dart
    ├── common/
    │   ├── app_safe_area.dart
    │   ├── app_snackbar.dart
    │   └── ...
    └── features/
        ├── report/               # UI laporan bisnis
        └── <feature_name>/
            └── <widget_name>.dart
```

---

## Prasyarat

- Flutter SDK (channel stable) dengan Dart `^3.12.2`
- Android Studio / VS Code + plugin Flutter
- JDK 17 (untuk build Android)
- Akun & project [Supabase](https://supabase.com) (untuk `.env`)
- API key [Google AI Studio](https://aistudio.google.com/apikey) (untuk Gemini)

---

## Konfigurasi Environment (.env)

Aplikasi memuat kredensial dari file `.env` di root proyek (via `flutter_dotenv`).
File ini **tidak** ikut di-commit (sudah masuk `.gitignore`).

### Langkah

1. Buat file `.env` di root proyek.
2. Isi nilai:
   ```
   SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGci...
   GEMINI_API_KEY=your_gemini_api_key
   GEMINI_MODEL=gemini-3.5-flash
   ```

`GEMINI_MODEL` opsional. Bila kosong, memakai `gemini-3.5-flash`.

> `SUPABASE_URL` dan anon key bersifat publik dan aman di client. Keamanan data bergantung
> pada **Row Level Security (RLS)** di Supabase. Jangan masukkan `service_role` key ke app.

`.env` didaftarkan sebagai asset di `pubspec.yaml`.

---

## Firebase

- File konfigurasi: `lib/firebase_options.dart` (di-generate FlutterFire CLI).
- Diinit di `main.dart` sebelum Supabase.
- Auth dipakai di `AuthProvider` (email/password).
- JWT Firebase dikirim ke Supabase (`accessToken`) agar RLS memakai `auth.jwt()->>'sub'` (Firebase UID).
- Di Dashboard Supabase: aktifkan **Third-party Auth → Firebase** dengan Project ID `sello-62633`.
  Detail: [`supabase/README.md`](supabase/README.md).
- Regenerate opsi platform:
  ```bash
  dart pub global activate flutterfire_cli
  flutterfire configure
  ```

---

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Login memakai **Firebase Auth** (email & password).
Tab **Kasir** membutuhkan `GEMINI_API_KEY` di `.env`. Mode suara butuh izin mikrofon; mode scan butuh izin kamera.

Setelah migrasi RLS per-user diterapkan, pastikan integrasi Firebase di Supabase Dashboard sudah aktif
(lihat [Database Supabase](#database-supabase) dan `supabase/README.md`).

### Database Supabase

Migrasi ada di `supabase/migrations/`. Push ke GitHub agar Supabase GitHub Integration
menerapkan skema otomatis:

```bash
git add supabase/migrations/
git commit -m "Add products migration"
git push
```

Cek status di Supabase Dashboard → Database → Migrations (**Applied**).
Tanpa migrasi, fitur produk menampilkan pesan bahwa tabel belum dibuat.

---

## Build & Rilis ke Play Store

Panduan lengkap: [`.context/PLAYSTORE.md`](.context/PLAYSTORE.md).

1. Siapkan signing key (`android/key.properties` + `android/app/upload-keystore.jks`).
   Script bantu: `android/setup_signing.ps1`.
2. Build: `flutter build appbundle --release`
3. Upload `.aab` ke [Google Play Console](https://play.google.com/console).

---

## State Management

**Provider** (`ChangeNotifier`), didaftarkan di `app.dart`:

| Provider | Fungsi |
|----------|--------|
| `AuthProvider` | Firebase Auth: login/register/reset/logout, `userId` = Firebase UID |
| `NavigationProvider` | Index tab bottom navigation aktif; `openCashier(mode)` untuk buka kasir dengan mode suara/scan |
| `DashboardProvider` | Statistik penjualan & transaksi dari Supabase |
| `ReportProvider` | Laporan bisnis per periode (harian–tahunan) |

Logout: `NavigationProvider.setIndex(0)` lalu `AuthProvider.logout()`.

---

## Konvensi Kode

- Penamaan kode (file, folder, class, variabel, id, route): **Bahasa Inggris**
- Teks UI & pesan error/success/warning: **Bahasa Indonesia**, ramah untuk awam
- Notifikasi: `AppSnackbar` (`lib/widgets/common/app_snackbar.dart`)
- AI: semua lewat `AiService`, HTTP Gemini lewat `GeminiApiService` + Dio
- Warna: `AppColors.*`, teks: `AppTextStyles.*` (jangan hardcode di widget)
- Logika bisnis di service/provider, bukan di widget

### UI wajib dipisah jadi widget

Jangan menumpuk seluruh tampilan di satu file `*_screen.dart`. Screen hanya mengatur
state, provider, navigasi, dan merakit widget anak.

| Lokasi | Isi |
|--------|-----|
| `screens/features/` | Orchestrasi layar (tipis) |
| `widgets/features/<fitur>/` | Bagian UI khusus fitur itu (satu widget per file) |
| `widgets/common/` | Widget dipakai lintas fitur |

Widget private (`_Foo`) di file screen hanya untuk potongan sangat kecil (sekitar 30 baris
ke bawah). Selain itu wajib diekstrak ke `widgets/features/`.

---

## Tema & Desain

- Tema biru, warna di `lib/styles/app_colors.dart` (primary `#2563EB`).
- Gaya teks di `lib/styles/app_text_styles.dart`.
- `ThemeData` di `lib/styles/app_theme.dart` (Material 3).

---

## Responsivitas

Helper di `lib/core/utils/responsive.dart`:

| Layar | Grid fitur | Padding | Lebar konten |
|-------|:----------:|:-------:|:------------:|
| Phone (<600px) | 2 kolom | 20 | penuh |
| Tablet (≥600px) | 3 kolom | 32 | 720px |
| Large (≥900px) | 4 kolom | 32 | 960px |

Navbar dibatasi 560px di tablet; form login dibatasi 480px.

---

## Keamanan & File Rahasia

File berikut **tidak** boleh di-commit (sudah ada di `.gitignore`):

- `.env` (dan `.env.*`)
- `android/key.properties`
- `android/app/*.jks` / `*.keystore`

---

## Roadmap

- [x] Kasir suara + scan (satu layar) + AiService (Gemini) + AppSnackbar
- [x] Migrasi Supabase: `products`, `product_images`, `sales` + storage + RLS per-user (Firebase)
- [x] ProductService + ProductRegisterScreen (foto multi-sudut)
- [x] ProductScanScreen (legacy; logika scan dipakai di tab Kasir mode Scan)
- [x] ProductListScreen + routing kartu fitur (`feature_navigation.dart`)
- [x] DashboardProvider + statistik beranda nyata
- [ ] Generate Code 128 + scan barcode (`mobile_scanner`)
- [x] Pisah AI: suara jualan (singkat) vs daftar produk (lengkap) + fuzzy match
- [x] Input suara (`speech_to_text`)
- [x] Auth Firebase + JWT ke Supabase RLS
- [x] Laporan Bisnis: agregasi harian/mingguan/bulanan/tahunan + insight
- [x] Pelanggan di kasir (`customer_name`) + Edukasi Mikro
- [ ] Implementasi fitur konten, WhatsApp, dll.
- [ ] Mode offline & sinkronisasi
- [ ] Pengujian (unit/widget/integration)

---
