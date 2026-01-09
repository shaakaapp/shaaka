import 'package:flutter/material.dart';
import '../models/cart_order_models.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import 'store_page.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late Product _product;
  ProductReview? _userReview;
  int? _currentUserId;
  List<ProductReview> _reviews = [];
  bool _isLoadingReviews = false;

  // Cart Logic
  CartItem? _cartItem;
  bool _isLoadingCart = false;

  // Similar Products
  List<Product> _similarProducts = [];
  bool _isLoadingSimilar = false;

  // Unit Selection Logic
  double _quantityStep = 1.0;
  String _selectedUnitName = '';
  List<Map<String, dynamic>> _variants = [];

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initialize();
    _calculateVariants();
  }

  void _calculateVariants() {
     _variants.clear();
     String unit = _product.unit.toLowerCase();
     
     if (unit == 'kg' || unit == 'kilogram') {
         _variants = [
             {'name': '250 g', 'step': 0.25},
             {'name': '500 g', 'step': 0.50},
             {'name': '1 kg', 'step': 1.0},
             {'name': '2 kg', 'step': 2.0},
             {'name': '5 kg', 'step': 5.0},
         ];
     } else if (unit == 'l' || unit == 'litre' || unit == 'liter') {
         _variants = [
             {'name': '250 ml', 'step': 0.25},
             {'name': '500 ml', 'step': 0.50},
             {'name': '1 L', 'step': 1.0},
             {'name': '2 L', 'step': 2.0},
         ];
     } else if (unit == 'g' || unit == 'gram' || unit == 'grams') {
          _variants = [
              {'name': '100 g', 'step': 100.0},
              {'name': '250 g', 'step': 250.0},
              {'name': '500 g', 'step': 500.0},
              {'name': '1 kg', 'step': 1000.0},
          ];
     } else {
         _variants = [
             {'name': '1 ${_product.unit}', 'step': 1.0},
             {'name': '2 ${_product.unit}', 'step': 2.0},
             {'name': '5 ${_product.unit}', 'step': 5.0},
         ];
     }
     
     // Set default to 1.0 step or first available
     var defaultVariant = _variants.firstWhere((v) => v['step'] == 1.0, orElse: () => _variants.first);
     _quantityStep = defaultVariant['step'];
     _selectedUnitName = defaultVariant['name'];
  }

  Future<void> _initialize() async {
    _currentUserId = await StorageService.getUserId();
    _loadReviews();
    _checkCart();
    _loadSimilarProducts();
  }

  Future<void> _loadSimilarProducts() async {
      setState(() => _isLoadingSimilar = true);
      final result = await ApiService.getProducts(); // Fetch all (for now, simpler than backend change)
      if (mounted) {
        setState(() {
            _isLoadingSimilar = false;
            if (result['success'] == true) {
                final allProducts = result['data'] as List<Product>;
                _similarProducts = allProducts.where((p) => 
                    p.category == _product.category && p.id != _product.id
                ).take(10).toList();
            }
        });
      }
  }
  
  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    final result = await ApiService.getProductReviews(_product.id);
    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
        if (result['success'] == true) {
          _reviews = result['data'];
          if (_currentUserId != null) {
            try {
              _userReview = _reviews.firstWhere((r) => r.userId == _currentUserId);
            } catch (e) {
              _userReview = null;
            }
          }
        }
      });
    }
  }

  Future<void> _showAddReviewDialog() async {
     if (_currentUserId == null) {
          if(!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to review')));
          return;
     }

     if (_currentUserId == _product.vendorId) {
        if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot review your own product')));
        return;
     }

     if (_userReview != null) {
       _showEditReviewDialog();
       return;
     }

     final commentController = TextEditingController();
     int rating = 5;

     showDialog(
       context: context,
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setStateDialog) {
             return AlertDialog(
               title: const Text('Write a Review'),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setStateDialog(() => rating = index + 1),
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(labelText: 'Comment (Optional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                 ],
               ),
               actions: [
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                 ElevatedButton(
                   onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      _submitReview(_currentUserId!, rating, commentController.text.trim());
                   }, 
                   child: const Text('Submit')
                 ),
               ],
             );
           }
         );
       }
     );
  }

  Future<void> _showEditReviewDialog() async {
     final commentController = TextEditingController(text: _userReview!.comment);
     int rating = _userReview!.rating;

     showDialog(
       context: context,
       builder: (context) {
         return StatefulBuilder(
           builder: (context, setStateDialog) {
             return AlertDialog(
               title: const Text('Edit Your Review'),
               content: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () => setStateDialog(() => rating = index + 1),
                          icon: Icon(
                            index < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                        );
                      }),
                    ),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(labelText: 'Comment (Optional)', border: OutlineInputBorder()),
                      maxLines: 3,
                    ),
                 ],
               ),
               actions: [
                 TextButton(
                    onPressed: () {
                         Navigator.pop(context);
                         _deleteReview();
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                 ),
                 TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                 ElevatedButton(
                   onPressed: () async {
                      Navigator.pop(context); // Close dialog
                      _updateReview(rating, commentController.text.trim());
                   }, 
                   child: const Text('Update')
                 ),
               ],
             );
           }
         );
       }
     );
  }

  Future<void> _submitReview(int userId, int rating, String comment) async {
       final result = await ApiService.addReview(_product.id, {
           'user': userId,
           'rating': rating,
           'comment': comment,
       });

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Submitted!'), backgroundColor: Colors.green));
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _updateReview(int rating, String comment) async {
       if (_userReview == null) return;
       
       final result = await ApiService.updateReview(_userReview!.id, {
           'rating': rating,
           'comment': comment,
       });

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Updated!'), backgroundColor: Colors.green));
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _deleteReview() async {
       if (_userReview == null) return;

       // Confirm delete? Maybe overkill for now, just delete.
       final result = await ApiService.deleteReview(_userReview!.id);

       if (!mounted) return;

       if (result['success'] == true) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review Deleted!'), backgroundColor: Colors.grey));
           _userReview = null; // Clear local reference immediately
           _refreshProductAndReviews();
       } else {
            _showError(result['error']);
       }
  }

  Future<void> _refreshProductAndReviews() async {
      // Refresh Product Details to get updated rating
      final productResult = await ApiService.getProductDetails(_product.id);
      if (productResult['success'] == true) {
           setState(() {
               _product = productResult['data'];
           });
      }
      _loadReviews(); // Refresh reviews list
  }
  
  void _showError(dynamic error) {
      String errorMessage = error is Map 
        ? (error['non_field_errors']?[0] ?? error['error'] ?? 'Operation failed') 
        : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
  }

  Future<void> _checkCart() async {
    if (_currentUserId == null) return;
    
    final result = await ApiService.getCart(_currentUserId!);
    if (mounted && result['success'] == true) {
      final Cart cart = result['data'];
      try {
        setState(() {
          // Check for exact product AND unit value match
          _cartItem = cart.items.firstWhere((item) => 
              item.productId == _product.id && item.unitValue == _quantityStep
          );
        });
      } catch (e) {
        setState(() => _cartItem = null);
      }
    }
  }

  Future<void> _addToCart() async {
    final userId = await StorageService.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to add items to cart')));
      return;
    }

    setState(() => _isLoadingCart = true);

    // Pass unitValue and default quantity 1 (count)
    final result = await ApiService.addToCart(userId, _product.id, _quantityStep, quantity: 1); 

    setState(() => _isLoadingCart = false);

    if (mounted) {
      if (result['success'] == true) {
        final Cart cart = result['data'];
        setState(() {
           _cartItem = cart.items.firstWhere((item) => 
               item.productId == _product.id && item.unitValue == _quantityStep
           );
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart!'), backgroundColor: Colors.green));
      } else {
        _showError(result['error']);
      }
    }
  }

  Future<void> _updateCartQuantity(bool increment) async {
      if (_cartItem == null || _currentUserId == null) return;

      setState(() => _isLoadingCart = true);
      
      double currentQty = _cartItem!.quantity;
      double newQty;
      
      // Increment COUNT by 1
      if (increment) {
          newQty = currentQty + 1.0;
      } else {
          newQty = currentQty - 1.0;
      }
      
      if (newQty <= 0) {
          // Remove item
          final result = await ApiService.removeFromCart(_currentUserId!, _cartItem!.id);
          if (mounted) {
              setState(() => _isLoadingCart = false);
              if (result['success'] == true) {
                  setState(() => _cartItem = null);
              } else {
                  _showError(result['error']);
              }
          }
      } else {
          // Update item
          final result = await ApiService.updateCartItem(_currentUserId!, _cartItem!.id, newQty);
           if (mounted) {
              setState(() => _isLoadingCart = false);
              if (result['success'] == true) {
                  final Cart cart = result['data'];
                   setState(() {
                       try {
                        _cartItem = cart.items.firstWhere((item) => 
                            item.productId == _product.id && item.unitValue == _quantityStep
                        );
                       } catch (e) {
                         _cartItem = null;
                       }
                   });
              } else {
                  _showError(result['error']);
              }
          }
      }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _product.images.isNotEmpty
                      ? PageView.builder(
                          itemCount: _product.images.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              _product.images[index].imageUrl,
                              fit: BoxFit.cover,
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 64, color: Colors.grey),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                Text(
                                  '₹${(_product.price * _quantityStep).toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                                ),
                                 Text(
                                  'For $_selectedUnitName', 
                                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                             ],
                           ),
                           // Unit Selector
                             DropdownButton<double>(
                             value: _quantityStep,
                             items: _variants.map((v) {
                               return DropdownMenuItem<double>(
                                 value: v['step'],
                                 child: Text(v['name']),
                               );
                             }).toList(),
                             onChanged: (value) {
                               if (value != null) {
                                 setState(() {
                                   _quantityStep = value;
                                   _selectedUnitName = _variants.firstWhere((v) => v['step'] == value)['name'];
                                 });
                                 _checkCart();
                               }
                             },
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       
                       // Stock and Rating Row
                       Row(
                         children: [
                            // Stock Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _product.stockQuantity > 0 ? Colors.green[100] : Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _product.stockQuantity > 0 
                                  ? (_product.stockQuantity < 5 ? 'Only ${_product.stockQuantity} left!' : 'In Stock')
                                  : 'Out of Stock',
                                style: TextStyle(
                                  color: _product.stockQuantity > 0 ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Rating
                            Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                             decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                             child: Row(
                               children: [
                                   const Icon(Icons.star, size: 16, color: Colors.purple), 
                                   const SizedBox(width: 4),
                                   Text('${_product.averageRating} (${_product.ratingCount})', style: const TextStyle(fontWeight: FontWeight.bold)),
                               ],
                             ),
                           )
                         ],
                       ),

                       const SizedBox(height: 8),
                       InkWell(
                         onTap: () {
                           Navigator.push(
                             context,
                             MaterialPageRoute(
                               builder: (context) => Scaffold(
                                 appBar: AppBar(title: Text(_product.vendorName)),
                                 body: StorePage(vendorId: _product.vendorId),
                               ),
                             ),
                           );
                         },
                         child: Text(
                           'Sold by: ${_product.vendorName}',
                           style: const TextStyle(
                             color: Colors.blue,
                             fontWeight: FontWeight.bold,
                             decoration: TextDecoration.underline,
                           ),
                         ),
                       ),
                       const SizedBox(height: 16),
                       Text(_product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.orange,
                    tabs: [
                      Tab(text: "Description"),
                      Tab(text: "Reviews"),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              // Description Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_product.description ?? 'No description available.', style: const TextStyle(fontSize: 16, height: 1.5)),
                    const SizedBox(height: 24),
                    const Divider(),
                    // Similar Products Section (Inside Description Tab)
                    if (_isLoadingSimilar)
                       const Center(child: CircularProgressIndicator())
                    else if (_similarProducts.isNotEmpty) ...[
                       const Text('Similar Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                       const SizedBox(height: 8),
                       SizedBox(
                         height: 260, 
                         child: ListView.builder(
                           scrollDirection: Axis.horizontal,
                           itemCount: _similarProducts.length,
                           itemBuilder: (context, index) {
                             return SizedBox(
                               width: 160,
                               child: Padding(
                                 padding: const EdgeInsets.only(right: 8.0),
                                 child: ProductCard(
                                   product: _similarProducts[index],
                                   onTap: () {
                                       Navigator.pushReplacement(
                                           context,
                                           MaterialPageRoute(builder: (context) => ProductDetailsPage(product: _similarProducts[index]))
                                       );
                                   },
                                 ),
                               ),
                             );
                           },
                         ),
                       ),
                       const SizedBox(height: 60),
                    ],
                  ],
                ),
              ),
              
              // Reviews Tab
              SingleChildScrollView(
                 padding: const EdgeInsets.all(16.0),
                 child: Column(
                   children: [
                     if (_isLoadingReviews)
                        const Center(child: CircularProgressIndicator())
                     else if (_reviews.isEmpty)
                        const Center(child: Text('No reviews yet. Be the first to review!', style: TextStyle(fontSize: 16, color: Colors.grey)))
                     else
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            final isUserReview = _currentUserId != null && review.userId == _currentUserId;
                            return Card(
                              color: isUserReview ? Colors.blue[50] : null,
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isUserReview ? Colors.blue : null,
                                  child: Text(review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?')),
                                title: Text(review.userName + (isUserReview ? ' (You)' : '')),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: List.generate(5, (starIndex) => Icon(
                                        starIndex < review.rating ? Icons.star : Icons.star_border,
                                        size: 14, color: Colors.amber
                                    ))),
                                    if (review.comment != null && review.comment!.isNotEmpty)
                                      Text(review.comment!),
                                  ],
                                ),
                                trailing: Text('${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 80),
                   ],
                 ),
              ),
            ],
          ),
        ),
      floatingActionButton: (_currentUserId != null && _currentUserId == _product.vendorId)
          ? null 
          : FloatingActionButton.extended(
              onPressed: _showAddReviewDialog,
              label: Text(_userReview != null ? 'Edit Review' : 'Write Review'),
              icon: Icon(_userReview != null ? Icons.edit : Icons.rate_review),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: _cartItem != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _isLoadingCart 
                          ? null 
                          : () => _updateCartQuantity(false), // Decrement
                        icon: const Icon(Icons.remove),
                        color: Colors.red,
                      ),
                      Text(
                        _cartItem != null 
                            ? '${_cartItem!.quantity % 1 == 0 ? _cartItem!.quantity.toInt() : _cartItem!.quantity}' 
                            : '0', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: _isLoadingCart 
                          ? null 
                          : () => _updateCartQuantity(true), // Increment
                        icon: const Icon(Icons.add),
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                         Navigator.pop(context); // Go back to store
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Continue Shopping', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                )
              ],
            )
          : ElevatedButton.icon(
              onPressed: (_currentUserId != null && _currentUserId == _product.vendorId) || _product.stockQuantity <= 0
                  ? null
                  : _addToCart,
              icon: _isLoadingCart 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.shopping_cart),
              label: Text((_currentUserId != null && _currentUserId == _product.vendorId)
                  ? 'Your Product'
                  : (_product.stockQuantity <= 0 ? 'Out of Stock' : 'Add ${_selectedUnitName} to Cart')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _product.stockQuantity <= 0 ? Colors.grey : Colors.orange,
                disabledBackgroundColor: Colors.grey[300],
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.grey[600],
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
      ),
    ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
