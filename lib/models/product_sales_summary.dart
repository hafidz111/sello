class ProductSalesSummary {
  const ProductSalesSummary({
    required this.productId,
    required this.productName,
    required this.revenue,
    required this.profit,
    required this.transactionCount,
    required this.quantitySold,
  });

  final String productId;
  final String productName;
  final int revenue;
  final int profit;
  final int transactionCount;
  final int quantitySold;
}
