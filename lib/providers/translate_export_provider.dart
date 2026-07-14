import 'package:flutter/foundation.dart';
import 'package:sello/models/export_language.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_translation_bundle.dart';
import 'package:sello/services/translate_export_service.dart';

class TranslateExportProvider extends ChangeNotifier {
  List<Product> _products = const [];
  Product? _selectedProduct;
  ProductTranslationBundle? _bundle;
  ExportLanguage _activeLanguage = ExportLanguage.id;
  bool _isLoadingProducts = false;
  bool _isTranslating = false;
  bool _isExporting = false;
  String? _errorMessage;

  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  ProductTranslationBundle? get bundle => _bundle;
  ExportLanguage get activeLanguage => _activeLanguage;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isTranslating => _isTranslating;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;
  bool get canTranslate =>
      _selectedProduct != null && !_isTranslating && !_isLoadingProducts;

  Future<void> loadProducts(String userId) async {
    _isLoadingProducts = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await TranslateExportService.instance.loadProducts(userId);
      if (_selectedProduct != null) {
        final stillExists = _products.any((p) => p.id == _selectedProduct!.id);
        if (!stillExists) {
          _selectedProduct = null;
          _bundle = null;
        }
      }
    } on TranslateExportException catch (e) {
      _errorMessage = e.message;
      _products = const [];
    } catch (_) {
      _errorMessage = 'Gagal memuat produk.';
      _products = const [];
    }

    _isLoadingProducts = false;
    notifyListeners();
  }

  void selectProduct(Product? product) {
    _selectedProduct = product;
    _bundle = null;
    _activeLanguage = ExportLanguage.id;
    notifyListeners();
  }

  void setActiveLanguage(ExportLanguage language) {
    if (_activeLanguage == language) return;
    _activeLanguage = language;
    notifyListeners();
  }

  Future<void> translate({String sourceNotes = ''}) async {
    final product = _selectedProduct;
    if (product == null) {
      _errorMessage = 'Pilih produk dulu sebelum menerjemahkan.';
      notifyListeners();
      return;
    }

    _isTranslating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _bundle = await TranslateExportService.instance.translateProduct(
        product: product,
        sourceNotes: sourceNotes,
      );
      _activeLanguage = ExportLanguage.id;
    } on TranslateExportException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Gagal menerjemahkan produk.';
    }

    _isTranslating = false;
    notifyListeners();
  }

  Future<void> exportJson() async {
    final current = _bundle;
    if (current == null) return;

    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await TranslateExportService.instance.shareJson(current);
    } catch (_) {
      _errorMessage = 'Gagal mengekspor file JSON.';
    }

    _isExporting = false;
    notifyListeners();
  }

  Future<void> exportText() async {
    final current = _bundle;
    if (current == null) return;

    _isExporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await TranslateExportService.instance.shareText(current);
    } catch (_) {
      _errorMessage = 'Gagal mengekspor file teks.';
    }

    _isExporting = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }
}
