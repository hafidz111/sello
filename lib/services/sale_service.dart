import 'package:sello/core/config/supabase_config.dart';
import 'package:sello/models/product.dart';
import 'package:sello/models/sale.dart';
import 'package:sello/models/sales_page_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaleException implements Exception {
  const SaleException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SaleService {
  SaleService._();

  static final SaleService instance = SaleService._();

  static const _selectWithProduct =
      'id, user_id, product_id, quantity, unit_price, unit_cost, total, '
      'customer_name, created_at, products(name)';

  static const defaultPageSize = 10;

  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Sale>> fetchTodaySales(String userId) async {
    final now = DateTime.now();
    return fetchSales(
      userId: userId,
      from: SaleDateRange.startOfDay(now),
      toExclusive: SaleDateRange.endExclusive(now),
    );
  }

  Future<SalesDaySummary> fetchSalesDaySummary({
    required String userId,
    required DateTime date,
  }) async {
    final from = SaleDateRange.startOfDay(date);
    final to = SaleDateRange.endExclusive(date);

    try {
      final response = await _client
          .from('sales')
          .select('total, quantity')
          .eq('user_id', userId)
          .gte('created_at', from.toUtc().toIso8601String())
          .lt('created_at', to.toUtc().toIso8601String())
          .count(CountOption.exact);

      var totalRevenue = 0;
      var totalUnits = 0;
      for (final row in response.data as List) {
        if (row is Map<String, dynamic>) {
          totalRevenue += (row['total'] as num?)?.toInt() ?? 0;
          totalUnits += (row['quantity'] as num?)?.toInt() ?? 0;
        }
      }

      return SalesDaySummary(
        transactionCount: response.count,
        totalRevenue: totalRevenue,
        totalUnits: totalUnits,
      );
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (_) {
      throw const SaleException('Gagal memuat ringkasan penjualan.');
    }
  }

  Future<SalesPageResult> fetchSalesPage({
    required String userId,
    required DateTime date,
    required int page,
    int pageSize = defaultPageSize,
  }) async {
    if (page < 0) {
      throw const SaleException('Halaman tidak valid.');
    }

    final from = SaleDateRange.startOfDay(date);
    final to = SaleDateRange.endExclusive(date);
    final offset = page * pageSize;

    try {
      final response = await _client
          .from('sales')
          .select(_selectWithProduct)
          .eq('user_id', userId)
          .gte('created_at', from.toUtc().toIso8601String())
          .lt('created_at', to.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1)
          .count(CountOption.exact);

      final sales = (response.data as List)
          .whereType<Map<String, dynamic>>()
          .map(Sale.fromJson)
          .toList();

      return SalesPageResult(
        sales: sales,
        totalCount: response.count,
        page: page,
        pageSize: pageSize,
      );
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (error) {
      if (error is SaleException) rethrow;
      throw const SaleException(
        'Gagal memuat penjualan. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<List<Sale>> fetchSales({
    required String userId,
    required DateTime from,
    required DateTime toExclusive,
  }) async {
    try {
      final rows = await _client
          .from('sales')
          .select(_selectWithProduct)
          .eq('user_id', userId)
          .gte('created_at', from.toUtc().toIso8601String())
          .lt('created_at', toExclusive.toUtc().toIso8601String())
          .order('created_at', ascending: false);

      return (rows as List)
          .whereType<Map<String, dynamic>>()
          .map(Sale.fromJson)
          .toList();
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (_) {
      throw const SaleException(
        'Gagal memuat penjualan. Periksa koneksi internet kamu.',
      );
    }
  }

  Future<Sale> createSale({
    required String userId,
    required Product product,
    required int quantity,
    String? customerName,
    int? unitPrice,
  }) async {
    if (quantity <= 0) {
      throw const SaleException('Jumlah penjualan minimal 1.');
    }

    final price = unitPrice ?? product.price;
    final total = price * quantity;
    final trimmedCustomer = customerName?.trim();

    try {
      final row = await _client
          .from('sales')
          .insert({
            'user_id': userId,
            'product_id': product.id,
            'quantity': quantity,
            'unit_price': price,
            'unit_cost': product.costPrice,
            'total': total,
            if (trimmedCustomer != null && trimmedCustomer.isNotEmpty)
              'customer_name': trimmedCustomer,
          })
          .select(_selectWithProduct)
          .single();

      final newStock = product.stock - quantity;
      await _client
          .from('products')
          .update({'stock': newStock < 0 ? 0 : newStock})
          .eq('id', product.id);

      return Sale.fromJson(row);
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (error) {
      if (error is SaleException) rethrow;
      throw const SaleException('Gagal menyimpan penjualan. Coba lagi.');
    }
  }

  Future<Sale> updateSale({
    required String saleId,
    required int quantity,
    String? customerName,
  }) async {
    if (quantity <= 0) {
      throw const SaleException('Jumlah penjualan minimal 1.');
    }

    try {
      final existing = await _client
          .from('sales')
          .select('id, product_id, quantity, unit_price')
          .eq('id', saleId)
          .single();

      final oldQuantity = (existing['quantity'] as num).toInt();
      final productId = existing['product_id'] as String;
      final unitPrice = (existing['unit_price'] as num).toInt();
      final stockDelta = oldQuantity - quantity;
      final trimmedCustomer = customerName?.trim();

      final row = await _client
          .from('sales')
          .update({
            'quantity': quantity,
            'total': unitPrice * quantity,
            'customer_name':
                trimmedCustomer == null || trimmedCustomer.isEmpty
                ? null
                : trimmedCustomer,
          })
          .eq('id', saleId)
          .select(_selectWithProduct)
          .single();

      if (stockDelta != 0) {
        final productRow = await _client
            .from('products')
            .select('stock')
            .eq('id', productId)
            .single();
        final currentStock = (productRow['stock'] as num).toInt();
        final newStock = currentStock + stockDelta;
        await _client
            .from('products')
            .update({'stock': newStock < 0 ? 0 : newStock})
            .eq('id', productId);
      }

      return Sale.fromJson(row);
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (error) {
      if (error is SaleException) rethrow;
      throw const SaleException('Gagal memperbarui penjualan. Coba lagi.');
    }
  }

  Future<void> deleteSale(String saleId) async {
    try {
      final existing = await _client
          .from('sales')
          .select('product_id, quantity')
          .eq('id', saleId)
          .single();

      final productId = existing['product_id'] as String;
      final quantity = (existing['quantity'] as num).toInt();

      await _client.from('sales').delete().eq('id', saleId);

      final productRow = await _client
          .from('products')
          .select('stock')
          .eq('id', productId)
          .single();
      final currentStock = (productRow['stock'] as num).toInt();
      await _client
          .from('products')
          .update({'stock': currentStock + quantity})
          .eq('id', productId);
    } on PostgrestException catch (error) {
      throw SaleException(_mapDbError(error));
    } catch (error) {
      if (error is SaleException) rethrow;
      throw const SaleException('Gagal menghapus penjualan. Coba lagi.');
    }
  }

  Product? matchProductByName(String name, List<Product> catalog) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    for (final product in catalog) {
      if (product.name.trim().toLowerCase() == normalized) {
        return product;
      }
    }

    for (final product in catalog) {
      final productName = product.name.trim().toLowerCase();
      if (productName.contains(normalized) || normalized.contains(productName)) {
        return product;
      }
    }

    return null;
  }

  String _mapDbError(PostgrestException error) {
    final msg = error.message.toLowerCase();
    final details = '${error.details ?? ''} ${error.hint ?? ''}'.toLowerCase();
    final combined = '$msg $details ${error.code ?? ''}';

    if (combined.contains('relation') && combined.contains('does not exist')) {
      return 'Tabel database belum dibuat. Push migrasi supabase/migrations/ ke GitHub.';
    }
    if (combined.contains('jwt') ||
        combined.contains('unauthorized') ||
        combined.contains('pgrst301') ||
        error.code == 'PGRST301') {
      return 'Sesi autentikasi ditolak database. Pastikan kamu sudah masuk '
          'dan Firebase Auth sudah dihubungkan di Supabase.';
    }
    if (combined.contains('row-level security') ||
        combined.contains('rls') ||
        combined.contains('42501') ||
        combined.contains('permission denied') ||
        combined.contains('violates row-level')) {
      return 'Akses data ditolak. Pastikan kamu sudah masuk dan '
          'integrasi Firebase Auth di Supabase sudah diaktifkan.';
    }
    return 'Terjadi kesalahan database. Coba lagi nanti.';
  }
}
