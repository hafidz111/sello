import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/product.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/screens/features/product_detail_screen.dart';
import 'package:sello/screens/features/product_register_screen.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/product_list/product_list_empty_state.dart';
import 'package:sello/widgets/features/product_list/product_list_tile.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _productService = ProductService.instance;

  bool _isLoading = true;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final userId = context.read<AuthProvider>().userId;
    try {
      final products = await _productService.fetchProducts(userId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppSnackbar.error(context, 'Gagal memuat daftar produk.');
    }
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductRegisterScreen()),
    );
    if (created == true) await _loadProducts();
  }

  Future<void> _openDetail(Product product) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
    if (mounted) await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Katalog Produk'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRegister,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: AppColors.textOnPrimary),
        label: Text('Daftar Produk', style: AppTextStyles.labelLarge),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? ProductListEmptyState(onRegister: _openRegister)
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(padding, 16, padding, 100),
                itemCount: _products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ProductListTile(
                    product: product,
                    onTap: () => _openDetail(product),
                  );
                },
              ),
            ),
    );
  }
}
