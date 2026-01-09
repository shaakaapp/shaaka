import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isAdding = false;

  Future<void> _addToCart() async {
    setState(() => _isAdding = true);
    
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add to cart')));
      }
      setState(() => _isAdding = false);
      return;
    }

    final result = await ApiService.addToCart(userId, widget.product.id, 1);
    
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? (result['error']['error'] ?? 'Failed') : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
      setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              flex: 3,
              child: Container(
                color: Colors.grey[200],
                child: widget.product.firstImageUrl != null
                    ? Image.network(
                        widget.product.firstImageUrl!,
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
                          widget.product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                         const SizedBox(height: 2),
                        Text(
                           widget.product.vendorName,
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
                               '${widget.product.averageRating} (${widget.product.ratingCount})',
                               style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                           )
                        ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${widget.product.price}/${widget.product.unit}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (widget.onEdit != null)
                          Row(
                              children: [
                                  Text(
                                      'Stock: ${widget.product.stockQuantity % 1 == 0 ? widget.product.stockQuantity.toInt() : widget.product.stockQuantity}',
                                      style: TextStyle(fontSize: 12, color: widget.product.stockQuantity > 0 ? Colors.black : Colors.red),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 30,
                                    width: 30,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                      onPressed: widget.onEdit,
                                      padding: EdgeInsets.zero,
                                      style: IconButton.styleFrom(backgroundColor: Colors.blue[50]),
                                    ),
                                  ),
                              ],
                          )
                        else if (widget.product.stockQuantity == 0)
                          const Text('Out of Stock',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold))
                        else
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: IconButton(
                              icon: _isAdding 
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.add_shopping_cart, size: 18),
                              onPressed: _isAdding ? null : _addToCart,
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(backgroundColor: Colors.orange[100]),
                            ),
                          )
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
