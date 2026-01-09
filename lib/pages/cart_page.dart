import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/cart_order_models.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Cart? _cart;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await StorageService.getUserId();
      if (userId == null) {
        setState(() {
          _error = 'Please login to view cart';
          _isLoading = false;
        });
        return;
      }

      final result = await ApiService.getCart(userId);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _cart = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            // Cart might be empty/not created yet, which is fine
             if (result['error'].toString().contains('not found')) {
               _cart = null; 
             } else {
               _error = result['error'].toString();
             }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, double newQuantity) async {
    if (newQuantity < 0) return;

    // Optimistic update? No, let's wait for server to be safe
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.updateCartItem(userId, item.id, newQuantity);
    if (result['success'] == true) {
      setState(() {
        _cart = result['data'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'] is Map ? result['error']['error'] : result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final userId = await StorageService.getUserId();
    if (userId == null) return;

    final result = await ApiService.removeFromCart(userId, item.id);
    if (result['success'] == true) {
      setState(() {
        _cart = result['data'];
      });
    } else {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['error'].toString()),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _cart == null || _cart!.items.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Your cart is empty',
                              style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cart!.items.length,
                            itemBuilder: (context, index) {
                              final item = _cart!.items[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      // Image
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          image: item.productImageUrl != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      item.productImageUrl!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: item.productImageUrl == null
                                            ? const Icon(Icons.shopping_bag,
                                                color: Colors.grey)
                                            : null,
                                      ),
                                      const SizedBox(width: 16),
                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '₹${item.price.toStringAsFixed(2)} / ${item.unit}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline),
                                                  onPressed: () => _updateQuantity(item, item.quantity - 1.0),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text('${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline),
                                                  onPressed: () => _updateQuantity(item, item.quantity + 1.0),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                const Spacer(),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                  onPressed: () => _removeItem(item),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Summary
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, -4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount:',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '₹${_cart!.totalPrice.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CheckoutPage()),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: Colors.orange, // Amazon-ish
                                    ),
                                    child: const Text('Proceed to Buy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
