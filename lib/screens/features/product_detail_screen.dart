import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/constants/stock_constants.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/product.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/common/overwrite_zero_number_field.dart';
import 'package:sello/widgets/features/product_register/register_photo_slot.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _productService = ProductService.instance;
  final _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _stockController = TextEditingController();

  Product? _product;
  final Map<String, Uint8List> _newPhotos = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _fillForm(Product product) {
    _nameController.text = product.name;
    _priceController.text = product.price.toString();
    _costController.text = product.costPrice.toString();
    _stockController.text = product.stock.toString();
  }

  String? _existingUrlForAngle(String angle) {
    final product = _product;
    if (product == null) return null;
    for (final image in product.images) {
      if (image.angleLabel == angle) return image.publicUrl;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;
    try {
      final product = await _productService.fetchProductById(
        userId: userId,
        productId: widget.productId,
      );
      if (!mounted) return;
      if (product == null) {
        setState(() {
          _product = null;
          _isLoading = false;
        });
        AppSnackbar.warning(
          context,
          'Produk tidak ditemukan atau sudah dihapus.',
        );
        return;
      }
      _fillForm(product);
      setState(() {
        _product = product;
        _newPhotos.clear();
        _isLoading = false;
      });
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, 'Gagal memuat detail produk.');
    }
  }

  Future<void> _capturePhoto(String angle) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _newPhotos[angle] = bytes);
  }

  Future<void> _save() async {
    final product = _product;
    if (product == null || _isSaving || _isDeleting) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim());
    final cost = int.tryParse(_costController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());

    if (name.isEmpty) {
      AppSnackbar.warning(context, 'Nama produk wajib diisi.');
      return;
    }
    if (price == null || cost == null || stock == null) {
      AppSnackbar.warning(
        context,
        'Isi harga jual, modal, dan stok dengan angka yang valid.',
      );
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;
    try {
      final updated = await _productService.updateProduct(
        userId: userId,
        productId: product.id,
        name: name,
        price: price,
        costPrice: cost,
        stock: stock,
        newImagesByAngle: Map<String, Uint8List>.from(_newPhotos),
      );
      if (!mounted) return;
      _fillForm(updated);
      setState(() {
        _product = updated;
        _newPhotos.clear();
        _isSaving = false;
      });
      AppSnackbar.success(context, 'Produk berhasil diperbarui.');
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppSnackbar.error(context, 'Gagal menyimpan produk. Coba lagi.');
    }
  }

  Future<void> _confirmDelete() async {
    final product = _product;
    if (product == null || _isSaving || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text(
          'Produk "${product.name}" akan dihapus dari katalog. '
          'Tindakan ini tidak bisa dibatalkan.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _delete();
  }

  Future<void> _delete() async {
    final product = _product;
    if (product == null) return;

    setState(() => _isDeleting = true);
    final userId = context.read<AuthProvider>().userId;
    try {
      await _productService.deleteProduct(
        userId: userId,
        productId: product.id,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Produk berhasil dihapus.');
      Navigator.of(context).pop(true);
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppSnackbar.error(context, 'Gagal menghapus produk. Coba lagi.');
    }
  }

  InputDecoration _decoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final product = _product;
    final stockValue = int.tryParse(_stockController.text.trim());
    final isLow =
        stockValue != null && stockValue <= StockConstants.lowStockThreshold;
    final busy = _isSaving || _isDeleting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (product != null)
            IconButton(
              onPressed: busy ? null : _confirmDelete,
              tooltip: 'Hapus produk',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: busy ? AppColors.textHint : AppColors.error,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? Center(
                  child: Text(
                    'Produk tidak ditemukan.',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              : ListView(
                  padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
                  children: [
                    Text(
                      'Ubah data produk, harga, stok, dan foto referensi.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (isLow) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.warning),
                        ),
                        child: Text(
                          'Stok menipis. Perbarui stok agar penjualan tidak terhenti.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      enabled: !busy,
                      decoration: _decoration(
                        'Nama produk',
                        'Contoh: Keripik singkong pedas',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OverwriteZeroNumberField(
                      controller: _priceController,
                      enabled: !busy,
                      decoration: _decoration('Harga jual (Rp)', '10000'),
                    ),
                    const SizedBox(height: 12),
                    OverwriteZeroNumberField(
                      controller: _costController,
                      enabled: !busy,
                      decoration: _decoration('Harga modal / HPP (Rp)', '7000'),
                    ),
                    const SizedBox(height: 12),
                    OverwriteZeroNumberField(
                      controller: _stockController,
                      enabled: !busy,
                      onChanged: (_) => setState(() {}),
                      decoration: _decoration('Stok (pcs)', '50'),
                    ),
                    const SizedBox(height: 20),
                    Text('Foto referensi', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk foto untuk mengganti. Foto lama tetap dipakai jika tidak diganti.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ProductPhotoAngle.all
                          .map(
                            (angle) => Expanded(
                              child: RegisterPhotoSlot(
                                label: ProductPhotoAngle.labelFor(angle),
                                bytes: _newPhotos[angle],
                                networkUrl: _existingUrlForAngle(angle),
                                onTap: busy ? null : () => _capturePhoto(angle),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textOnPrimary,
                                ),
                              )
                            : Text(
                                'Simpan perubahan',
                                style: AppTextStyles.labelLarge,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _confirmDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: _isDeleting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.error,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text(
                          _isDeleting ? 'Menghapus...' : 'Hapus produk',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
