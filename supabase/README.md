# Supabase

Migrasi database ada di folder `migrations/`. File ini **tidak** dijalankan otomatis oleh aplikasi Flutter.

## GitHub Integration (sudah terhubung)

Setelah push ke GitHub, Supabase menjalankan file SQL baru di `migrations/` secara otomatis.

```
git add supabase/migrations/
git commit -m "Add products migration"
git push
```

Cek status di **Supabase Dashboard → Database → Migrations**.

## Migrasi

| File | Isi |
|------|-----|
| `20260710120000_products_and_sales.sql` | Tabel products, product_images, sales, bucket product-images, RLS dev |
| `20260714120000_rls_per_user.sql` | RLS per-user (Firebase UID), bucket privat, policy storage |
| `20260714140000_sales_profit_customer.sql` | `cost_price`, `unit_cost`, `customer_name` untuk laba & pelanggan |
| `20260714184500_fix_requesting_user_id_jwt_sub.sql` | Perbaiki `requesting_user_id()`: pakai `auth.jwt()->>'sub'` (Firebase UID bukan UUID) |
| `20260716190000_user_subscriptions.sql` | Tabel `user_subscriptions` (plan `free`/`pro`) + RLS per user |
| `20260716193000_device_tokens.sql` | Token FCM perangkat untuk push notifikasi (stok menipis) |

## Notifikasi stok menipis

- Ambang: stok ≤ **5** (`StockConstants.lowStockThreshold`)
- Setelah penjualan: notifikasi lokal per produk (maks 1x/hari per produk)
- Saat login: ringkasan produk stok menipis (maks 1x/hari)
- Token FCM disimpan di `device_tokens` (siap push server-side nanti)
- Izinkan notifikasi di HP saat diminta app

## Debug paket Gratis / Pro (production)

Paket tersimpan di tabel **`user_subscriptions`**.

1. Buka **Supabase Dashboard → Table Editor → `user_subscriptions`**
2. Cari baris `user_id` = Firebase UID akun (lihat di Firebase Auth / chip login)
3. Ubah kolom **`plan`**:
   - `free` = paket dasar (ada iklan/blur di Laporan)
   - `pro` = tanpa iklan
4. Di app: tutup–buka ulang atau logout–login supaya `SubscriptionProvider` memuat ulang

Atau lewat **SQL Editor**:

```sql
-- Jadikan Pro (ganti UID)
update public.user_subscriptions
set plan = 'pro', updated_at = now()
where user_id = 'FIREBASE_UID_DISINI';

-- Kembalikan ke Gratis
update public.user_subscriptions
set plan = 'free', updated_at = now()
where user_id = 'FIREBASE_UID_DISINI';

-- Lihat semua
select user_id, plan, updated_at from public.user_subscriptions order by updated_at desc;
```

Catatan: update langsung di Dashboard memakai role service dan tidak terhalang RLS user. App sendiri hanya bisa ubah baris milik sendiri.

## Firebase Auth + RLS (wajib)

Auth aplikasi memakai **Firebase Auth**. Supabase memakai JWT Firebase supaya RLS mengenali pemakai lewat claim `sub` (Firebase UID).

**Penting:** Jangan pakai `auth.uid()` di policy. Firebase UID bukan format UUID; gunakan `auth.jwt()->>'sub'` (sudah dibungkus di `public.requesting_user_id()`).

### Langkah di Dashboard Supabase

1. Buka **Authentication → Third-party Auth** (atau **Sign In / Providers → Third-party**).
2. Tambah integrasi **Firebase** dengan Project ID: `sello-62633`
   (sama dengan `projectId` di `lib/firebase_options.dart`).
3. Pastikan migrasi `20260714120000_rls_per_user.sql` status **Applied**.

Tanpa langkah 1–2, query yang login tetap ditolak RLS karena JWT Firebase tidak dipercaya.

Konfigurasi CLI mirror ada di `config.toml`:

```toml
[auth.third_party.firebase]
enabled = true
project_id = "sello-62633"
```

### Perilaku keamanan

| Objek | Aturan |
|-------|--------|
| `products`, `sales` | Hanya baris dengan `user_id` = Firebase UID pemanggil |
| `product_images` | Hanya jika produk induk milik pemanggil |
| Storage `product-images` | Path wajib `{firebaseUid}/...`; bucket **privat** |
| App | URL gambar lewat **signed URL** (bukan public URL) |

Klien Flutter mengirim token lewat `accessToken` di `SupabaseConfig.initialize()`.

## Manual (tanpa push)

Supabase Dashboard → SQL Editor → paste isi file migrasi, atau:

```powershell
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

## Catatan

- Jangan edit migrasi yang sudah pernah dijalankan di production. Buat file migrasi baru dengan timestamp baru.
- Semua perubahan database hanya lewat `migrations/*.sql`, lalu commit dan push ke GitHub.
- Opsional lanjutan: custom claim Firebase `role: authenticated` via Cloud Function Blocking. Policy saat ini sudah mencakup role `anon` dan `authenticated` agar tetap jalan tanpa claim itu, selama JWT Firebase tervalidasi.
