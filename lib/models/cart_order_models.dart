class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImageUrl;
  final double price;
  final String unit;
  double quantity; // This is now Count
  final double unitValue; // This is size (e.g. 0.25)
  final double totalPrice;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.unitValue,
    required this.totalPrice,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    String? imageUrl;
    if (product['images'] != null && (product['images'] as List).isNotEmpty) {
      imageUrl = product['images'][0]['image_url'];
    }

    return CartItem(
      id: json['id'],
      productId: product['id'],
      productName: product['name'],
      productImageUrl: imageUrl,
      price: double.parse(product['price'].toString()),
      unit: product['unit'],
      quantity: double.parse(json['quantity'].toString()),
      unitValue: double.parse(json['unit_value'].toString()),
      totalPrice: double.parse(json['total_price'].toString()), // Trust backend total
    );
  }
}

class Cart {
  final int id;
  final List<CartItem> items;
  final double totalPrice;

  Cart({
    required this.id,
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalPrice: double.parse(json['total_price'].toString()),
    );
  }
}

class OrderItem {
  final int id;
  final int? productId; // Nullable if product deleted
  final String productName;
  final double quantity;
  final double priceAtPurchase;

  OrderItem({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.priceAtPurchase,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['product'] != null ? json['product']['id'] : null,
      productName: json['product_name'],
      quantity: double.parse(json['quantity'].toString()),
      priceAtPurchase: double.parse(json['price_at_purchase'].toString()),
    );
  }
}

class Order {
  final int id;
  final List<OrderItem> items;
  final String status;
  final double totalAmount;
  final String paymentMethod;
  final bool isPaid;
  final DateTime createdAt;
  final String shippingAddress;
  final String city;
  final String state;
  final String pincode;

  Order({
    required this.id,
    required this.items,
    required this.status,
    required this.totalAmount,
    required this.paymentMethod,
    required this.isPaid,
    required this.createdAt,
    required this.shippingAddress,
    required this.city,
    required this.state,
    required this.pincode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentMethod: json['payment_method'],
      isPaid: json['is_paid'],
      createdAt: DateTime.parse(json['created_at']),
      shippingAddress: json['shipping_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }
}
