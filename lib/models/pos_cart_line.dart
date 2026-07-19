import 'package:sello/models/product.dart';

class PosCartLine {
  PosCartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  int get subtotal => product.price * quantity;
}
