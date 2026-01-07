class ProductImage {
  final int id;
  final String imageUrl;

  ProductImage({required this.id, required this.imageUrl});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      imageUrl: json['image_url'],
    );
  }
}

class ProductReview {
  final int id;
  final int userId;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      userId: json['user'],
      userName: json['user_name'] ?? 'Anonymous',
      rating: json['rating'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Product {
  final int id;
  final int vendorId;
  final String vendorName;
  final String name;
  final String? description;
  final String category;
  final double price;
  final String unit;
  final int stockQuantity;
  final double averageRating;
  final int ratingCount;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    required this.unit,
    required this.stockQuantity,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.images = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      vendorId: json['vendor'],
      vendorName: json['vendor_name'] ?? 'Unknown Vendor',
      name: json['name'],
      description: json['description'],
      category: json['category'],
      price: double.parse(json['price'].toString()),
      unit: json['unit'],
      stockQuantity: json['stock_quantity'],
      averageRating: double.parse(json['average_rating'].toString()),
      ratingCount: json['rating_count'],
      images: (json['images'] as List?)
              ?.map((i) => ProductImage.fromJson(i))
              .toList() ??
          [],
    );
  }
  
  // Helper to get first image or null
  String? get firstImageUrl => images.isNotEmpty ? images.first.imageUrl : null;
}
