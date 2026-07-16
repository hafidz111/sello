# Sello — Jualan Cerdas dengan AI

Aplikasi mobile (Flutter) untuk membantu UMKM mengelola penjualan dengan bantuan AI:
pencatatan kasir via suara & scan produk, laporan bisnis, terjemah produk, edukasi mikro,
katalog digital, dan paket Gratis/Pro.

> **Status proyek:** kerangka + banyak fitur inti sudah jalan. **Kasir**, **laporan**,
> **edukasi**, **terjemah & ekspor**, **paket langganan (Supabase)**, dan **rewarded ads
> di Laporan (Gratis)** sudah tersedia. Barcode, offline sync, dan Foto ke Konten masih rencana.
> Lihat [Status Fitur](#status-fitur).

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Arsitektur Produk & Scan](#arsitektur-produk--scan)
- [Paket Gratis / Pro](#paket-gratis--pro)
- [Status Fitur](#status-fitur)
- [Teknologi](#teknologi)
- [Struktur Folder](#struktur-folder)
- [Prasyarat](#prasyarat)
- [Konfigurasi Environment (.env)](#konfigurasi-environment-env)
- [Firebase](#firebase)
- [AdMob](#admob)
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

1. Pengguna membuka aplikasi → **AuthShell** (login / register / lupa password, Firebase).
2. Setelah login → **MainShell** dengan 5 tab: Beranda, Kasir, Konten, Laporan, Menu.
3. Paket langganan dimuat dari Supabase (`user_subscriptions`).
4. Navigasi memakai **floating bottom navbar** yang responsif.

---

## Arsitektur Produk & Scan

### Yang sudah berjalan (visual match)

1. **Daftar produk** (`ProductRegisterScreen`): nama, harga, modal (HPP), stok, foto referensi
   (depan/samping/label) → Supabase (`products`, `product_images`, bucket privat
   `product-images` + signed URL).
2. **Scan penjualan** (tab Kasir, mode Scan): kamera live → AI `matchProductToCatalog` →
   jika confidence ≥ 65% produk terklaim otomatis → atur qty → `recordSale` (kurangi stok,
   opsional `customer_name`).
3. **Kasir suara** (tab Kasir, mode Suara): ucapan singkat → AI `extractSale` + fuzzy match
   katalog; daftar produk lengkap lewat prompt terpisah.
4. **Katalog** (`ProductListScreen`): lihat produk terdaftar.

### Rencana berikutnya (barcode)

| Fase | Metode | Status |
|------|--------|--------|
| Daftar | Scan barcode retail, generate Code 128 | Belum |
| Jualan | Scan Code 128 / barcode → lookup DB | Belum |

### Skema database (migrasi `supabase/migrations/`)

```
products             id, user_id, name, price, cost_price, stock, created_at
product_images       product_id, storage_path, angle_label, sort_order
sales                user_id, product_id, quantity, unit_price, unit_cost, total,
                     customer_name, created_at
user_subscriptions   user_id, plan (free|pro), updated_at, created_at
```

RLS memakai `requesting_user_id()` = claim JWT `sub` (Firebase UID).
Detail: [`supabase/README.md`](supabase/README.md) dan [`.context/context.md`](.context/context.md).

### Alur scan visual

```
Kamera live → ambil frame → AI bandingkan dengan foto katalog user
        │
        ├── Cocok (≥65%) → auto klaim → stepper qty → catat penjualan
        └── Tidak cocok → pilih manual / daftar produk baru
```

---

## Paket Gratis / Pro

Sumber kebenaran: tabel Supabase **`user_subscriptions`**.

| Paket | `plan` | Perilaku utama |
|-------|--------|----------------|
| Gratis | `free` | Laporan diburamkan 1 halaman penuh → tonton rewarded ads untuk buka; edukasi 1x/hari; ada iklan |
| Pro | `pro` | Laporan langsung terbuka (tanpa iklan); edukasi 3x/hari |

UI: **Menu → Paket & Harga**. Chip paket di kartu akun.
Payment gateway belum ada (tombol Pro = uji coba, menulis `plan` ke Supabase).

### Debug production (ubah paket di Dashboard)

```sql
update public.user_subscriptions
set plan = 'pro', updated_at = now()
where user_id = 'FIREBASE_UID_DISINI';

-- Kembali ke dasar:
update public.user_subscriptions
set plan = 'free', updated_at = now()
where user_id = 'FIREBASE_UID_DISINI';
```

Lalu logout–login di app. Lihat juga [`supabase/README.md`](supabase/README.md).

---

## Status Fitur

Legenda: **Selesai** · **Sebagian** · **Belum**

### Fitur Aplikasi (UI/Kerangka)

| Fitur | Status | Keterangan |
|-------|:------:|------------|
| Halaman Login / Register / Reset | Selesai | Firebase Auth (email/password). |
| Halaman Beranda | Selesai | Statistik dari Supabase (`DashboardProvider`). |
| Floating bottom navbar | Selesai | 5 tab, animasi aktif, responsif tablet. |
| Halaman Menu | Selesai | Produk, terjemah, paket, edukasi, offline (placeholder), logout. |
| Logout | Selesai | Dialog konfirmasi, reset ke tab Beranda. |
| AppSnackbar | Selesai | Notifikasi error/success/warning/info kustom. |
| SafeArea global | Selesai | Diterapkan di seluruh layar. |
| Responsivitas tablet | Selesai | Breakpoint & layout menyesuaikan lebar layar. |

### Fitur Utama (Bisnis) — 7 Fitur + Paket

| # | Fitur | Status | Keterangan |
|---|-------|:------:|------------|
| 1 | Kasir Suara & Scan | Sebagian | Suara singkat + fuzzy match + pelanggan; daftar produk lewat suara. Scan visual. Barcode belum. |
| 2 | Foto ke Konten | Belum | Placeholder. Upload foto & generator caption. |
| 3 | Laporan Bisnis | Selesai | Filter periode + rentang tanggal; penjualan/laba; produk & pelanggan; insight AI. Gratis: blur + rewarded ads. |
| 4 | Terjemah & Ekspor | Selesai | ID/EN/AR/ZH + ekspor JSON/teks skema `sello.product_i18n`. |
| 5 | Katalog Digital | Sebagian | Daftar produk (`ProductListScreen`). Link share belum. |
| 6 | Mode Offline | Belum | Termasuk klaim paket Gratis. Belum ada penyimpanan lokal & sinkronisasi. |
| 7 | Edukasi Mikro | Selesai | Tips AI 30 hari. Gratis 1x/hari, Pro 3x/hari. |
| — | Paket & Harga | Selesai | `user_subscriptions` di Supabase. Billing sungguhan belum. |

Asisten WhatsApp **tidak** lagi bagian dari produk.

### Backend & Integrasi

| Komponen | Status | Keterangan |
|----------|:------:|------------|
| Supabase | Sebagian | Produk, gambar, penjualan, paket + RLS per-user (Firebase UID). Bucket gambar privat. |
| Firebase | Selesai | Auth + JWT ke Supabase. |
| Layanan AI (Gemini) | Sebagian | Sale, match katalog, laporan, edukasi, terjemah. |
| AdMob rewarded | Selesai | Gate Laporan paket Gratis. |

---

## Teknologi

- **Flutter** (Dart SDK `^3.12.2`)
- **Provider** — state management
- **dio** — HTTP Gemini (`DioClient`, `GeminiApiService`)
- **supabase_flutter** — DB + storage
- **firebase_core / firebase_auth** — login; JWT ke RLS
- **google_mobile_ads** — rewarded ads
- **camera**, **image_picker**, **permission_handler**, **speech_to_text**
- **share_plus**, **path_provider**, **shared_preferences**
- **flutter_dotenv**, **flutter_lints**

Package rencana: `mobile_scanner`, `barcode_widget`.

---

## Struktur Folder

```
lib/
├── main.dart                     # .env → Firebase → Supabase → AdMob → runApp
├── app.dart                      # MultiProvider + AuthGate
├── firebase_options.dart
│
├── core/
│   ├── config/                   # env, supabase_config (accessToken Firebase)
│   ├── network/                  # dio_client, network_exception
│   ├── constants/                # feature_data, gemini_schemas, admob_config
│   └── utils/                    # responsive, currency, feature_navigation, fuzzy match
│
├── models/                       # product, report, education, subscription_plan, ...
├── providers/                    # auth, nav, dashboard, report, education, subscription
├── services/                     # ai, product, report, education, translate_export,
│                                 # subscription, rewarded_ad, gemini_api
├── screens/
│   ├── auth/
│   ├── home/, shell/, menu/
│   └── features/                 # cashier, report, education, translate_export, pricing, ...
├── styles/
└── widgets/
    ├── common/, navigation/
    └── features/                 # report/, education/, pricing/, cashier/, ...
```

Detail konteks AI: [`.context/context.md`](.context/context.md).

---

## Prasyarat

- Flutter SDK (channel stable) dengan Dart `^3.12.2`
- Android Studio / VS Code + plugin Flutter
- JDK 17 (untuk build Android)
- Akun & project [Supabase](https://supabase.com)
- API key [Google AI Studio](https://aistudio.google.com/apikey) (Gemini)
- Akun [AdMob](https://admob.google.com) (unit rewarded sudah terpasang di kode)

---

## Konfigurasi Environment (.env)

1. Buat file `.env` di root proyek (sudah di `.gitignore`).
2. Isi:
   ```
   SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGci...
   GEMINI_API_KEY=your_gemini_api_key
   GEMINI_MODEL=gemini-3.5-flash
   ```

`GEMINI_MODEL` opsional. Jangan masukkan `service_role` key ke app.

---

## Firebase

- `lib/firebase_options.dart` (FlutterFire CLI).
- Diinit di `main.dart` sebelum Supabase.
- JWT dikirim ke Supabase agar RLS memakai `auth.jwt()->>'sub'`.
- Dashboard Supabase: **Third-party Auth → Firebase**, Project ID `sello-62633`.
  Detail: [`supabase/README.md`](supabase/README.md).

---

## AdMob

- App ID: `ca-app-pub-4122766238215136~5990475654` (Android Manifest + iOS `GADApplicationIdentifier`).
- Rewarded Laporan (produksi): `ca-app-pub-4122766238215136/2564713459`.
- Mode **debug** memakai unit uji Google agar akun aman; **release** memakai unit produksi
  (`lib/core/constants/admob_config.dart`).

---

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Login Firebase (email & password). Kasir butuh `GEMINI_API_KEY`. Pastikan migrasi Supabase
(termasuk `user_subscriptions`) status **Applied**, dan Third-party Auth Firebase aktif.

### Database Supabase

```bash
git add supabase/migrations/
git commit -m "Add subscription migration"
git push
```

Cek Dashboard → Database → Migrations.

---

## Build & Rilis ke Play Store

Panduan: [`.context/PLAYSTORE.md`](.context/PLAYSTORE.md).

1. Signing: `android/key.properties` + keystore (`android/setup_signing.ps1`).
2. `flutter build appbundle --release`
3. Upload `.aab` ke Play Console.

---

## State Management

Didaftarkan di `app.dart`:

| Provider | Fungsi |
|----------|--------|
| `AuthProvider` | Firebase Auth; `userId` = Firebase UID |
| `NavigationProvider` | Tab aktif; `openCashier(mode)` |
| `DashboardProvider` | Statistik beranda |
| `ReportProvider` | Laporan per periode |
| `EducationProvider` | Tips + kuota harian |
| `SubscriptionProvider` | Paket free/pro dari Supabase |

---

## Konvensi Kode

- Kode: **Bahasa Inggris** · UI/pesan: **Bahasa Indonesia**
- Notifikasi: `AppSnackbar`
- AI lewat `AiService`; HTTP Gemini lewat `GeminiApiService` + Dio
- Warna/teks: `AppColors` / `AppTextStyles`
- Screen tipis; UI di `widgets/features/<fitur>/`

---

## Tema & Desain

- Primary `#2563EB` di `lib/styles/app_colors.dart`
- Material 3 di `lib/styles/app_theme.dart`

---

## Responsivitas

| Layar | Grid fitur | Padding | Lebar konten |
|-------|:----------:|:-------:|:------------:|
| Phone (<600px) | 2 kolom | 20 | penuh |
| Tablet (≥600px) | 3 kolom | 32 | 720px |
| Large (≥900px) | 4 kolom | 32 | 960px |

---

## Keamanan & File Rahasia

Jangan commit: `.env`, `android/key.properties`, `*.jks` / `*.keystore`.

---

## Roadmap

- [x] Kasir suara + scan + fuzzy match + pelanggan
- [x] Supabase produk/penjualan + RLS Firebase + HPP/laba
- [x] Laporan Bisnis + gate rewarded ads (Gratis)
- [x] Edukasi Mikro (kuota per paket)
- [x] Terjemah & Ekspor
- [x] Paket free/pro di `user_subscriptions`
- [x] Auth Firebase + AdMob init
- [ ] Foto ke Konten
- [ ] Mode offline & sinkronisasi
- [ ] Barcode Code 128 / retail
- [ ] Payment gateway
- [ ] Pengujian (unit/widget/integration)

---
