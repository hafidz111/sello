import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/product_match_result.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/dashboard_provider.dart';
import 'package:sello/screens/features/product_list_screen.dart';
import 'package:sello/screens/features/product_register_screen.dart';
import 'package:sello/services/ai_service.dart';
import 'package:sello/services/product_service.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/product_scan/scan_bottom_panel.dart';
import 'package:sello/widgets/features/product_scan/scan_camera_area.dart';

class ProductScanScreen extends StatefulWidget {
  const ProductScanScreen({super.key});

  @override
  State<ProductScanScreen> createState() => _ProductScanScreenState();
}

class _ProductScanScreenState extends State<ProductScanScreen> {
  final _aiService = AiService.instance;
  final _productService = ProductService.instance;

  CameraController? _controller;
  bool _isInitializingCamera = true;
  bool _isLoadingCatalog = true;
  bool _isDetecting = false;
  bool _isRecording = false;
  String? _cameraError;

  List<Product> _catalog = [];
  ProductMatchResult? _lastMatch;
  Product? _claimedProduct;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    final userId = context.read<AuthProvider>().userId;
    setState(() => _isLoadingCatalog = true);
    try {
      final products = await _productService.fetchProducts(userId);
      if (!mounted) return;
      setState(() {
        _catalog = products;
        _isLoadingCatalog = false;
      });
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCatalog = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCatalog = false);
      AppSnackbar.error(context, 'Gagal memuat katalog produk.');
    }
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ProductRegisterScreen()),
    );
    if (created == true) {
      await _loadCatalog();
    }
  }

  Future<void> _initCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _cameraError =
            'Izin kamera ditolak. Aktifkan izin kamera di pengaturan perangkat.';
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final camera = back.isNotEmpty ? back.first : cameras.first;

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializingCamera = false;
        _cameraError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitializingCamera = false;
        _cameraError =
            'Kamera tidak dapat dibuka. Coba tutup aplikasi lain yang memakai kamera.';
      });
    }
  }

  void _retryCamera() {
    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });
    _initCamera();
  }

  Future<void> _detectProduct() async {
    if (_catalog.isEmpty) {
      AppSnackbar.warning(
        context,
        'Belum ada produk terdaftar. Daftar produk dulu.',
      );
      return;
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isDetecting) {
      return;
    }

    setState(() {
      _isDetecting = true;
      _lastMatch = null;
      _claimedProduct = null;
      _quantity = 1;
    });

    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final match = await _aiService.matchProductToCatalog(
        imageBytes: bytes,
        catalog: _catalog,
      );

      if (!mounted) return;

      final threshold = _productService.matchConfidenceThreshold;
      final product = match.matchedProduct;
      final canClaim =
          match.isMatched && match.confidence >= threshold && product != null;

      setState(() {
        _lastMatch = match;
        _claimedProduct = canClaim ? product : null;
        _isDetecting = false;
      });

      if (canClaim) {
        AppSnackbar.success(context, 'Produk dikenali: ${product.name}');
      } else {
        AppSnackbar.warning(
          context,
          'Produk tidak cocok dengan katalog. Coba daftar produk baru.',
        );
      }
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() => _isDetecting = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDetecting = false);
      AppSnackbar.error(context, 'Gagal mendeteksi produk. Coba lagi.');
    }
  }

  Future<void> _recordSale() async {
    final product = _claimedProduct;
    if (product == null) return;

    setState(() => _isRecording = true);
    final userId = context.read<AuthProvider>().userId;

    try {
      await _productService.recordSale(
        userId: userId,
        product: product,
        quantity: _quantity,
      );
      if (!mounted) return;

      AppSnackbar.success(
        context,
        'Penjualan tercatat: $_quantity ${product.name}',
      );

      await context.read<DashboardProvider>().load(userId);
      if (!mounted) return;

      setState(() {
        _lastMatch = null;
        _claimedProduct = null;
        _quantity = 1;
        _isRecording = false;
      });

      await _loadCatalog();
    } on ProductException catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      AppSnackbar.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      AppSnackbar.error(context, 'Gagal mencatat penjualan.');
    }
  }

  void _resetScan() {
    setState(() {
      _lastMatch = null;
      _claimedProduct = null;
      _quantity = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Produk'),
        backgroundColor: Colors.black,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProductListScreen()),
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: 'Katalog produk',
          ),
          IconButton(
            onPressed: _openRegister,
            icon: const Icon(Icons.add_box_outlined),
            tooltip: 'Daftar produk',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ScanCameraArea(
              isInitializingCamera: _isInitializingCamera,
              cameraError: _cameraError,
              controller: _controller,
              isDetecting: _isDetecting,
              onRetryCamera: _retryCamera,
            ),
          ),
          ScanBottomPanel(
            isLoadingCatalog: _isLoadingCatalog,
            catalogCount: _catalog.length,
            lastMatch: _lastMatch,
            claimedProduct: _claimedProduct,
            quantity: _quantity,
            isDetecting: _isDetecting,
            isRecording: _isRecording,
            canDetect: _controller != null,
            onOpenRegister: _openRegister,
            onDetect: _detectProduct,
            onRecordSale: _recordSale,
            onResetScan: _resetScan,
            onDecrementQuantity: () => setState(() => _quantity--),
            onIncrementQuantity: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }
}
