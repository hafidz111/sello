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

## Migrasi awal

| File | Isi |
|------|-----|
| `20260710120000_products_and_sales.sql` | Tabel products, product_images, sales, bucket product-images, RLS dev |

## Manual (tanpa push)

Supabase Dashboard → SQL Editor → paste isi file migrasi, atau:

```powershell
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

## Catatan

- Jangan edit migrasi yang sudah pernah dijalankan di production. Buat file migrasi baru dengan timestamp baru.
- `schema.sql` di root folder ini hanya salinan referensi; yang dipakai integrasi GitHub adalah `migrations/*.sql`.
