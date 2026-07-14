/// Local fuzzy string matching for catalog product names (Bahasa Indonesia aware).
abstract final class CatalogFuzzyMatcher {
  static const defaultThreshold = 0.55;

  static ProductNameMatch? bestMatch(
    String query, {
    required List<({String id, String name})> catalog,
    double threshold = defaultThreshold,
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty || catalog.isEmpty) return null;

    ProductNameMatch? best;
    for (final entry in catalog) {
      final score = similarity(normalizedQuery, normalize(entry.name));
      if (score < threshold) continue;
      if (best == null || score > best.score) {
        best = ProductNameMatch(
          productId: entry.id,
          productName: entry.name,
          score: score,
        );
      }
    }
    return best;
  }

  static String normalize(String input) {
    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  /// Dice coefficient on character bigrams, with exact/containment boosts.
  static double similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;

    if (a.contains(b) || b.contains(a)) {
      final shorter = a.length < b.length ? a.length : b.length;
      final longer = a.length > b.length ? a.length : b.length;
      return 0.7 + (0.3 * shorter / longer);
    }

    final bigramsA = _bigrams(a);
    final bigramsB = _bigrams(b);
    if (bigramsA.isEmpty || bigramsB.isEmpty) {
      return a[0] == b[0] ? 0.2 : 0;
    }

    var overlap = 0;
    final remaining = Map<String, int>.from(bigramsB);
    for (final entry in bigramsA.entries) {
      final available = remaining[entry.key] ?? 0;
      if (available <= 0) continue;
      final used = available < entry.value ? available : entry.value;
      overlap += used;
      remaining[entry.key] = available - used;
    }

    final total = _count(bigramsA) + _count(bigramsB);
    return total == 0 ? 0 : (2 * overlap) / total;
  }

  static Map<String, int> _bigrams(String value) {
    if (value.length < 2) {
      return value.isEmpty ? {} : {value: 1};
    }
    final map = <String, int>{};
    for (var i = 0; i < value.length - 1; i++) {
      final key = value.substring(i, i + 2);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  static int _count(Map<String, int> map) =>
      map.values.fold(0, (sum, value) => sum + value);
}

class ProductNameMatch {
  const ProductNameMatch({
    required this.productId,
    required this.productName,
    required this.score,
  });

  final String productId;
  final String productName;
  final double score;
}
