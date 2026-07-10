import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/product_register/register_form_body.dart';

class ProductRegisterScreen extends StatefulWidget {
  const ProductRegisterScreen({super.key});

  @override
  State<ProductRegisterScreen> createState() => _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends State<ProductRegisterScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _stockController = TextEditingController(text: '0');
  final _picker = ImagePicker();
  final _productService = ProductService.instance;

  final Map<String, Uint8List> _photos = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto(String angle) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1280,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() => _photos[angle] = bytes);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final price =
        int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final stock =
        int.tryParse(_stockController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;

    if (name.isEmpty) {
      AppSnackbar.warning(context, 'Nama produk wajib diisi.');
      return;
    }
    if (_photos.isEmpty) {
      AppSnackbar.warning(context, 'Ambil minimal satu foto referensi produk.');
      return;
    }

    setState(() => _isSaving = true);
    final userId = context.read<AuthProvider>().userId;

    try {
      await _productService.createProduct(
        userId: userId,
        name: name,
        price: price,
        stock: stock,
        imagesByAngle: Map.from(_photos),
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Produk berhasil didaftarkan.');
      Navigator.of(context).pop(true);
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

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Produk'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        child: RegisterFormBody(
          nameController: _nameController,
          priceController: _priceController,
          stockController: _stockController,
          photos: _photos,
          isSaving: _isSaving,
          onCapturePhoto: _capturePhoto,
          onSave: _save,
        ),
      ),
    );
  }
}
