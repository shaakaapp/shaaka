import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[200],
                child: product.firstImageUrl != null
                    ? Image.network(
                        product.firstImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey));
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey)),
              ),
            ),
            // Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                         const SizedBox(height: 2),
                        Text(
                           product.vendorName,
                           style: TextStyle(color: Colors.grey[600], fontSize: 12),
                           maxLines: 1,
                           overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                        children: [
                           const Icon(Icons.star, size: 14, color: Colors.amber),
                           const SizedBox(width: 2),
                           Text(
                               '${product.averageRating} (${product.ratingCount})',
                               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                           )
                        ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${product.price}/${product.unit}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if(product.stockQuantity == 0)
                          const Text('Out of Stock', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
