# Sello — Jualan Cerdas dengan AI

Aplikasi mobile (Flutter) untuk membantu UMKM mengelola penjualan dengan bantuan AI:
pencatatan kasir via suara/teks, pembuatan konten dari foto produk, laporan bisnis
berbahasa manusia, katalog digital, dan lainnya.

> **Status proyek:** tahap awal. Kerangka aplikasi (UI, navigasi, tema, konfigurasi
> backend) sudah jadi. Sebagian besar fitur inti **belum diimplementasikan** dan masih
> berupa halaman placeholder. Lihat [Status Fitur](#status-fitur).

---

## Daftar Isi

- [Tentang Aplikasi](#tentang-aplikasi)
- [Status Fitur](#status-fitur)
- [Teknologi](#teknologi)
- [Struktur Folder](#struktur-folder)
- [Prasyarat](#prasyarat)
- [Konfigurasi Environment (.env)](#konfigurasi-environment-env)
- [Firebase](#firebase)
- [Menjalankan Aplikasi](#menjalankan-aplikasi)
- [Build & Rilis ke Play Store](#build--rilis-ke-play-store)
- [State Management](#state-management)
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

## Status Fitur

Legenda: ✅ Selesai · 🟡 Sebagian / placeholder · ⛔ Belum dibuat

### Fitur Aplikasi (UI/Kerangka)

| Fitur                  | Status | Keterangan                                                                                               |
|------------------------|:------:|----------------------------------------------------------------------------------------------------------|
| Halaman Login          |   🟡   | **Dummy** — menerima email & password apa saja, belum terhubung ke autentikasi asli (Supabase/Firebase). |
| Halaman Beranda        |   ✅    | Header sapaan, kartu statistik (nilai masih dummy `0`), grid & list fitur.                               |
| Floating bottom navbar |   ✅    | 5 tab, animasi aktif, responsif tablet.                                                                  |
| Halaman Menu           |   ✅    | Daftar semua fitur + tombol logout.                                                                      |
| Logout                 |   ✅    | Dialog konfirmasi, reset ke tab Beranda.                                                                 |
| SafeArea global        |   ✅    | Diterapkan di seluruh layar.                                                                             |
| Responsivitas tablet   |   ✅    | Breakpoint & layout menyesuaikan lebar layar.                                                            |

### Fitur Utama (Bisnis) — 9 Fitur

> Semua fitur di bawah **belum memiliki logika/AI**. Yang sudah ada hanya entri di daftar
> fitur (`feature_data.dart`) dan sebagian punya halaman placeholder "Segera hadir".

| # | Fitur                         | Status | Keterangan                                                                                                                      |
|---|-------------------------------|:------:|---------------------------------------------------------------------------------------------------------------------------------|
| 1 | Kasir Suara & Teks Cerdas     |   🟡   | Placeholder. Belum ada input suara/teks maupun ekstraksi AI.                                                                    |
| 2 | Scan Produk (catat penjualan) |   ⛔    | Belum ada halaman. Alur: scan/foto produk → AI kenali produk → user isi jumlah (pcs) → catat penjualan. Baru terdaftar di menu. |
| 3 | Foto ke Konten                |   🟡   | Placeholder. Belum ada upload foto & generator caption.                                                                         |
| 4 | Asisten Chat WhatsApp         |   ⛔    | Belum ada halaman & integrasi WhatsApp Business API.                                                                            |
| 5 | Laporan Bisnis                |   🟡   | Placeholder. Belum ada agregasi data & ringkasan AI.                                                                            |
| 6 | Terjemah & Ekspor Otomatis    |   ⛔    | Belum ada halaman & mesin terjemahan.                                                                                           |
| 7 | Katalog Digital Siap Jual     |   ⛔    | Belum ada halaman & pembuatan link katalog.                                                                                     |
| 8 | Mode Offline Ringan           |   ⛔    | Belum ada penyimpanan lokal & sinkronisasi.                                                                                     |
| 9 | Edukasi Mikro                 |   ⛔    | Belum ada halaman & tips berbasis data.                                                                                         |

### Backend & Integrasi

| Komponen         | Status | Keterangan                                                                                                         |
|------------------|:------:|--------------------------------------------------------------------------------------------------------------------|
| Supabase         |   🟡   | Terkonfigurasi & di-inisialisasi saat startup, **tetapi belum dipakai** (belum ada tabel, query, atau auth).       |
| Firebase         |   🟡   | Dependency & `firebase_options.dart` sudah ada, **tetapi belum di-inisialisasi** di `main.dart` dan belum dipakai. |
| Autentikasi asli |   ⛔    | Masih dummy. Belum terhubung Supabase Auth / Firebase Auth.                                                        |
| Layanan AI       |   ⛔    | Belum ada integrasi model AI apa pun.                                                                              |

---

## Teknologi

- **Flutter** (Dart SDK `^3.12.2`)
- **Provider** — state management
- **supabase_flutter** — backend (belum dipakai penuh)
- **firebase_core / firebase_auth** — terpasang, belum diaktifkan
- **flutter_dotenv** — konfigurasi environment via `.env`
- **flutter_lints** — aturan linting

---

## Struktur Folder

```
lib/
├── main.dart                     # Entry point: load .env → init Supabase → runApp
├── app.dart                      # MultiProvider + MaterialApp + AuthGate
├── firebase_options.dart         # Konfigurasi Firebase (belum dipakai)
│
├── core/
│   ├── config/
│   │   ├── env.dart              # Akses variabel .env (Env.supabaseUrl, dll)
│   │   └── supabase_config.dart  # SupabaseConfig.initialize() + .client
│   ├── constants/
│   │   ├── app_constants.dart    # Nama app, tagline
│   │   └── feature_data.dart     # Daftar 9 fitur
│   └── utils/
│       └── responsive.dart       # Breakpoint & helper responsif
│
├── models/
│   ├── feature_item.dart
│   └── nav_item.dart
│
├── providers/
│   ├── auth_provider.dart        # Login/logout (dummy), userName
│   └── navigation_provider.dart  # Index bottom nav
│
├── screens/
│   ├── auth/login_screen.dart
│   ├── home/home_screen.dart
│   ├── shell/main_shell.dart     # IndexedStack + bottom nav
│   ├── menu/menu_screen.dart
│   └── features/                 # Placeholder: kasir, konten, laporan
│       ├── kasir_screen.dart
│       ├── konten_screen.dart
│       └── laporan_screen.dart
│
├── styles/
│   ├── app_colors.dart           # Palet warna (tema biru)
│   ├── app_text_styles.dart
│   └── app_theme.dart
│
└── widgets/
    ├── navigation/floating_bottom_nav.dart
    └── common/
        ├── app_safe_area.dart
        ├── responsive_center.dart
        ├── feature_card.dart
        ├── placeholder_screen.dart
        └── logout_button.dart
```

---

## Prasyarat

- Flutter SDK (channel stable) dengan Dart `^3.12.2`
- Android Studio / VS Code + plugin Flutter
- JDK 17 (untuk build Android)
- Akun & project [Supabase](https://supabase.com) (untuk `.env`)

---

## Konfigurasi Environment (.env)

Aplikasi memuat kredensial dari file `.env` di root proyek (via `flutter_dotenv`).
File ini **tidak** ikut di-commit (sudah masuk `.gitignore`).

### Langkah:

1. Salin template:
   ```bash
   copy .env.example .env      # Windows
   # atau: cp .env.example .env
   ```
2. Isi nilai dari **Supabase Dashboard → Settings → API**:
   ```
   SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGci...
   ```

> `SUPABASE_URL` dan anon/publishable key memang **bersifat publik** dan aman berada di
> aplikasi client. Keamanan data yang sesungguhnya bergantung pada **Row Level Security
> (RLS)** di Supabase. **Jangan pernah** memasukkan `service_role` key ke `.env` aplikasi
> ini.

`.env` sudah didaftarkan sebagai asset di `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

---

## Firebase

- File `lib/firebase_options.dart` sudah ada (hasil FlutterFire) untuk Android & iOS.
- **Namun Firebase belum diinisialisasi** di `main.dart` dan belum digunakan fitur apa pun.
- Untuk mengaktifkannya nanti, tambahkan pemanggilan berikut di dalam `main()`
  (setelah `WidgetsFlutterBinding.ensureInitialized()`):

  > `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`

---

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Karena login masih **dummy**, Anda bisa masuk dengan mengisi email & password apa saja
(asal tidak kosong).

---

## Build & Rilis ke Play Store

Panduan lengkap ada di [`PLAYSTORE.md`](.context/PLAYSTORE.md). Ringkasnya:

1. Siapkan signing key (`android/key.properties` + `android/app/upload-keystore.jks`).
   Script bantu: `android/setup_signing.ps1`.
2. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```
   Output: `build/app/outputs/bundle/release/app-release.aab`
3. Upload `.aab` ke [Google Play Console](https://play.google.com/console).

---

## State Management

Menggunakan **Provider** (`ChangeNotifier`). Provider didaftarkan di `app.dart`:

| Provider             | Fungsi                                                  |
|----------------------|---------------------------------------------------------|
| `AuthProvider`       | Status login (dummy), `userName`, `login()`, `logout()` |
| `NavigationProvider` | Index tab bottom navigation aktif                       |

Logout dilakukan dengan: `NavigationProvider.setIndex(0)` lalu `AuthProvider.logout()`.

---

## Tema & Desain

- Tema **biru**, warna terpusat di `lib/styles/app_colors.dart` (mis. primary `#2563EB`).
- Gaya teks di `lib/styles/app_text_styles.dart`.
- Konfigurasi `ThemeData` di `lib/styles/app_theme.dart` (Material 3).
- **Aturan:** jangan hardcode warna/teks di widget — selalu pakai `AppColors.*` dan
  `AppTextStyles.*`.

---

## Responsivitas

Helper di `lib/core/utils/responsive.dart`:

| Layar           | Grid fitur | Padding | Lebar konten |
|-----------------|:----------:|:-------:|:------------:|
| Phone (<600px)  |  2 kolom   |   20    |    penuh     |
| Tablet (≥600px) |  3 kolom   |   32    |    720px     |
| Large (≥900px)  |  4 kolom   |   32    |    960px     |

Navbar dibatasi 560px di tablet; form login dibatasi 480px.

---

## Keamanan & File Rahasia

File berikut **tidak** boleh di-commit (sudah ada di `.gitignore`):

- `.env` (dan `.env.*`, kecuali `.env.example`)
- `android/key.properties`
- `android/app/*.jks` / `*.keystore`

---

## Roadmap

- [ ] Ganti login dummy dengan autentikasi asli (Supabase/Firebase Auth)
- [ ] Routing dari kartu fitur ke halaman masing-masing
- [ ] Implementasi 9 fitur utama + integrasi AI
- [ ] Skema database Supabase + RLS
- [ ] Mode offline & sinkronisasi
- [ ] Data statistik beranda dari sumber nyata
- [ ] Pengujian (unit/widget/integration)

---

© 2026 Titik Senyap Studio.
