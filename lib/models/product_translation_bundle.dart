import 'package:sello/models/export_language.dart';
import 'package:sello/models/product.dart';

class LocalizedProductCopy {
  const LocalizedProductCopy({
    required this.language,
    required this.title,
    required this.description,
    this.tags = const [],
  });

  final ExportLanguage language;
  final String title;
  final String description;
  final List<String> tags;

  factory LocalizedProductCopy.fromJson(
    Map<String, dynamic> json, {
    required ExportLanguage language,
  }) {
    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw.whereType<String>().map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    return LocalizedProductCopy(
      language: language,
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
    'language': language.code,
    'title': title,
    'description': description,
    'tags': tags,
  };
}

class ProductTranslationBundle {
  const ProductTranslationBundle({
    required this.product,
    required this.sourceNotes,
    required this.locales,
    required this.createdAt,
  });

  static const schemaVersion = '1.0';

  final Product product;
  final String sourceNotes;
  final Map<ExportLanguage, LocalizedProductCopy> locales;
  final DateTime createdAt;

  LocalizedProductCopy? of(ExportLanguage language) => locales[language];

  /// Skema ekspor JSON siap pakai marketplace / impor katalog.
  Map<String, dynamic> toExportJson() {
    return {
      'schema': 'sello.product_i18n',
      'schema_version': schemaVersion,
      'exported_at': createdAt.toUtc().toIso8601String(),
      'product': {
        'id': product.id,
        'price_idr': product.price,
        'cost_price_idr': product.costPrice,
        'stock': product.stock,
        'source_notes_id': sourceNotes,
        'locales': {
          for (final entry in locales.entries)
            entry.key.code: {
              'title': entry.value.title,
              'description': entry.value.description,
              'tags': entry.value.tags,
            },
        },
      },
    };
  }

  String toMarketplaceText() {
    final buffer = StringBuffer();
    buffer.writeln('SELLO PRODUCT EXPORT');
    buffer.writeln('Schema: sello.product_i18n@$schemaVersion');
    buffer.writeln('Product ID: ${product.id}');
    buffer.writeln('Price (IDR): ${product.price}');
    buffer.writeln('Stock: ${product.stock}');
    buffer.writeln('');

    for (final language in ExportLanguage.values) {
      final copy = locales[language];
      if (copy == null) continue;
      buffer.writeln('=== ${language.label} (${language.shortLabel}) ===');
      buffer.writeln('Title: ${copy.title}');
      buffer.writeln('Description: ${copy.description}');
      if (copy.tags.isNotEmpty) {
        buffer.writeln('Tags: ${copy.tags.join(', ')}');
      }
      buffer.writeln('');
    }
    return buffer.toString().trimRight();
  }
}
