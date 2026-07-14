abstract final class GeminiSchemas {
  static const sale = {
    'type': 'OBJECT',
    'properties': {
      'items': {
        'type': 'ARRAY',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'name': {
              'type': 'STRING',
              'description': 'Nama produk yang dijual.',
            },
            'quantity': {
              'type': 'INTEGER',
              'description': 'Jumlah unit yang terjual (pcs), minimal 1.',
            },
            'unit_price': {
              'type': 'INTEGER',
              'description':
                  'Harga per satuan dalam Rupiah tanpa titik/koma. '
                  '0 bila tidak disebutkan.',
            },
          },
          'required': ['name', 'quantity', 'unit_price'],
        },
      },
    },
    'required': ['items'],
  };

  static const detection = {
    'type': 'OBJECT',
    'properties': {
      'product_name': {
        'type': 'STRING',
        'description': 'Nama produk yang paling cocok, dalam Bahasa Indonesia.',
      },
      'category': {
        'type': 'STRING',
        'description': 'Kategori produk, mis. Makanan ringan, Minuman.',
      },
      'description': {
        'type': 'STRING',
        'description': 'Deskripsi singkat tampilan produk atau kemasan.',
      },
      'confidence': {
        'type': 'NUMBER',
        'description': 'Tingkat keyakinan 0 sampai 1.',
      },
    },
    'required': ['product_name', 'category', 'description', 'confidence'],
  };

  static const match = {
    'type': 'OBJECT',
    'properties': {
      'matched_product_id': {
        'type': 'STRING',
        'description':
            'ID produk dari katalog yang cocok. String kosong bila tidak ada yang cocok.',
      },
      'product_name': {
        'type': 'STRING',
        'description': 'Nama produk yang paling cocok, dalam Bahasa Indonesia.',
      },
      'confidence': {
        'type': 'NUMBER',
        'description': 'Tingkat keyakinan pencocokan 0 sampai 1.',
      },
      'is_matched': {
        'type': 'BOOLEAN',
        'description': 'True hanya jika produk di foto cocok dengan katalog.',
      },
    },
    'required': [
      'matched_product_id',
      'product_name',
      'confidence',
      'is_matched',
    ],
  };

  static const businessInsight = {
    'type': 'OBJECT',
    'properties': {
      'summary': {
        'type': 'STRING',
        'description':
            'Ringkasan 2–4 kalimat Bahasa Indonesia. '
            'Saran singkat hanya memakai fitur aplikasi Sello. '
            'Jangan sebut aplikasi lain.',
      },
    },
    'required': ['summary'],
  };

  static const productDraft = {
    'type': 'OBJECT',
    'properties': {
      'name': {
        'type': 'STRING',
        'description': 'Nama produk lengkap yang akan didaftarkan.',
      },
      'price': {
        'type': 'INTEGER',
        'description': 'Harga jual satuan Rupiah tanpa titik/koma. 0 bila tidak disebut.',
      },
      'cost_price': {
        'type': 'INTEGER',
        'description':
            'Harga modal/HPP satuan Rupiah. 0 bila tidak disebut.',
      },
      'stock': {
        'type': 'INTEGER',
        'description': 'Stok awal pcs. 0 bila tidak disebut.',
      },
      'notes': {
        'type': 'STRING',
        'description': 'Catatan tambahan singkat, boleh kosong.',
      },
    },
    'required': ['name', 'price', 'cost_price', 'stock', 'notes'],
  };

  static const educationTips = {
    'type': 'OBJECT',
    'properties': {
      'headline': {
        'type': 'STRING',
        'description': 'Judul ringkas dalam Bahasa Indonesia.',
      },
      'tips': {
        'type': 'ARRAY',
        'description': 'Tepat 3 tips. Aksi harus di dalam aplikasi Sello.',
        'items': {
          'type': 'OBJECT',
          'properties': {
            'title': {
              'type': 'STRING',
              'description': 'Judul tip singkat.',
            },
            'body': {
              'type': 'STRING',
              'description': 'Penjelasan tip 1–2 kalimat.',
            },
            'action_hint': {
              'type': 'STRING',
              'description':
                  'Aksi di Sello saja, mis. buka Kasir / Laporan / Produk.',
            },
          },
          'required': ['title', 'body', 'action_hint'],
        },
      },
    },
    'required': ['headline', 'tips'],
  };
}
