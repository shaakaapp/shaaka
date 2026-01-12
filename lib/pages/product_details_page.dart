import 'package:flutter/material.dart';
import '../models/cart_order_models.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import '../theme/app_theme.dart';
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
             return Dialog(
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppTheme.warmWhite,
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       'Write a Review',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: List.generate(5, (index) {
                         return Material(
                           color: Colors.transparent,
                           child: InkWell(
                             onTap: () => setStateDialog(() => rating = index + 1),
                             borderRadius: BorderRadius.circular(24),
                             child: Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Icon(
                                 index < rating
                                     ? Icons.star_rounded
                                     : Icons.star_border_rounded,
                                 color: Color(0xFFD4A574),
                                 size: 40,
                               ),
                             ),
                           ),
                         );
                       }),
                     ),
                     const SizedBox(height: 24),
                     TextField(
                       controller: commentController,
                       decoration: const InputDecoration(
                         labelText: 'Comment (Optional)',
                       ),
                       maxLines: 3,
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: Text(
                             'Cancel',
                             style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!),
                           ),
                         ),
                         const SizedBox(width: 12),
                         ElevatedButton(
                           onPressed: () async {
                             Navigator.pop(context);
                             _submitReview(_currentUserId!, rating,
                                 commentController.text.trim());
                           },
                           child: const Text('Submit'),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
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
             return Dialog(
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: AppTheme.warmWhite,
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Text(
                       'Edit Your Review',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: List.generate(5, (index) {
                         return Material(
                           color: Colors.transparent,
                           child: InkWell(
                             onTap: () => setStateDialog(() => rating = index + 1),
                             borderRadius: BorderRadius.circular(24),
                             child: Padding(
                               padding: const EdgeInsets.all(8.0),
                               child: Icon(
                                 index < rating
                                     ? Icons.star_rounded
                                     : Icons.star_border_rounded,
                                 color: Color(0xFFD4A574),
                                 size: 40,
                               ),
                             ),
                           ),
                         );
                       }),
                     ),
                     const SizedBox(height: 24),
                     TextField(
                       controller: commentController,
                       decoration: const InputDecoration(
                         labelText: 'Comment (Optional)',
                       ),
                       maxLines: 3,
                     ),
                     const SizedBox(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton(
                           onPressed: () {
                             Navigator.pop(context);
                             _deleteReview();
                           },
                           style: TextButton.styleFrom(
                             foregroundColor: Theme.of(context).colorScheme.error,
                           ),
                           child: const Text('Delete'),
                         ),
                         const SizedBox(width: 12),
                         TextButton(
                           onPressed: () => Navigator.pop(context),
                           child: Text(
                             'Cancel',
                             style: TextStyle(color: Theme.of(context).textTheme.bodyMedium!.color!),
                           ),
                         ),
                         const SizedBox(width: 12),
                         ElevatedButton(
                           onPressed: () async {
                             Navigator.pop(context);
                             _updateReview(rating, commentController.text.trim());
                           },
                           child: const Text('Update'),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
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

  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.softBeige,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                expandedHeight: 400.0,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.warmWhite,
                flexibleSpace: FlexibleSpaceBar(
                  background: _product.images.isNotEmpty
                      ? Stack(
                          children: [
                            PageView.builder(
                              itemCount: _product.images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  duration: AppAnimations.medium,
                                  curve: AppAnimations.defaultCurve,
                                  builder: (context, value, child) {
                                    return Opacity(
                                      opacity: value,
                                      child: Transform.scale(
                                        scale: 0.95 + (value * 0.05),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Image.network(
                                    _product.images[index].imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.softBeige,
                                        child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 64,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            // Image indicators
                            if (_product.images.length > 1)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _product.images.length,
                                    (index) => AnimatedContainer(
                                      duration: AppAnimations.fast,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: _currentImageIndex == index ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentImageIndex == index
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.white.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AppAnimations.medium,
                  curve: AppAnimations.defaultCurve,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    color: AppTheme.warmWhite,
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          _product.name,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Price and Unit Selector Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${(_product.price * _quantityStep).toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'For $_selectedUnitName',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Unit Selector
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: DropdownButton<double>(
                                value: _quantityStep,
                                underline: const SizedBox(),
                                icon: Icon(
                                  Icons.arrow_drop_down_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                items: _variants.map((v) {
                                  return DropdownMenuItem<double>(
                                    value: v['step'],
                                    child: Text(
                                      v['name'],
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _quantityStep = value;
                                      _selectedUnitName = _variants
                                          .firstWhere((v) => v['step'] == value)['name'];
                                    });
                                    _checkCart();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stock and Rating Row
                        Row(
                          children: [
                            // Stock Status
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _product.stockQuantity > 0
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                    : Theme.of(context).colorScheme.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _product.stockQuantity > 0
                                        ? Icons.check_circle_outline
                                        : Icons.cancel_outlined,
                                    size: 16,
                                    color: _product.stockQuantity > 0
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _product.stockQuantity > 0
                                        ? (_product.stockQuantity < 5
                                            ? 'Only ${_product.stockQuantity} left!'
                                            : 'In Stock')
                                        : 'Out of Stock',
                                    style: TextStyle(
                                      color: _product.stockQuantity > 0
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Rating
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFD4A574).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Color(0xFFD4A574),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_product.averageRating} (${_product.ratingCount})',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Vendor Info
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Scaffold(
                                    appBar: AppBar(
                                      title: Text(_product.vendorName),
                                      elevation: 0,
                                    ),
                                    body: StorePage(vendorId: _product.vendorId),
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.store_outlined,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sold by: ${_product.vendorName}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).textTheme.bodySmall!.color!,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: const [
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: AppAnimations.medium,
                      curve: AppAnimations.defaultCurve,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _product.description ?? 'No description available.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: Theme.of(context).textTheme.bodyMedium!.color!,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Similar Products Section
                    if (_isLoadingSimilar)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    else if (_similarProducts.isNotEmpty) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: AppAnimations.medium,
                        curve: AppAnimations.defaultCurve,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Similar Products',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 280,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _similarProducts.length,
                                itemBuilder: (context, index) {
                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: Duration(
                                      milliseconds: 300 + (index * 100),
                                    ),
                                    curve: AppAnimations.defaultCurve,
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.scale(
                                          scale: 0.9 + (value * 0.1),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      width: 180,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 16.0),
                                        child: ProductCard(
                                          product: _similarProducts[index],
                                          onTap: () {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProductDetailsPage(
                                                  product: _similarProducts[index],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
              
              // Reviews Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    if (_isLoadingReviews)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                    else if (_reviews.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.rate_review_outlined,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No reviews yet',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Be the first to review!',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium!.color!,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          final isUserReview = _currentUserId != null &&
                              review.userId == _currentUserId;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 200 + (index * 50)),
                            curve: AppAnimations.defaultCurve,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: isUserReview
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                                  : AppTheme.warmWhite,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: isUserReview
                                          ? Theme.of(context).colorScheme.primary
                                          : AppTheme.accentTerracotta,
                                      child: Text(
                                        review.userName.isNotEmpty
                                            ? review.userName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  review.userName +
                                                      (isUserReview
                                                          ? ' (You)'
                                                          : ''),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: List.generate(
                                              5,
                                              (starIndex) => Icon(
                                                starIndex < review.rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_border_rounded,
                                                size: 16,
                                                color: Color(0xFFD4A574),
                                              ),
                                            ),
                                          ),
                                          if (review.comment != null &&
                                              review.comment!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              review.comment!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                color: Theme.of(context).textTheme.bodyMedium!.color!,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        floatingActionButton: (_currentUserId != null &&
                _currentUserId == _product.vendorId)
            ? null
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppAnimations.slow,
                curve: AppAnimations.bounceCurve,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: FloatingActionButton.extended(
                      onPressed: _showAddReviewDialog,
                      backgroundColor: AppTheme.accentTerracotta,
                      icon: Icon(
                        _userReview != null
                            ? Icons.edit_outlined
                            : Icons.rate_review_outlined,
                        color: Colors.white,
                      ),
                      label: Text(
                        _userReview != null ? 'Edit Review' : 'Write Review',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
        bottomNavigationBar: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppAnimations.medium,
          curve: AppAnimations.defaultCurve,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warmWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: _cartItem != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.softBeige,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoadingCart
                                      ? null
                                      : () => _updateCartQuantity(false),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.remove_rounded,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 50,
                                alignment: Alignment.center,
                                child: Text(
                                  _cartItem != null
                                      ? '${_cartItem!.quantity % 1 == 0 ? _cartItem!.quantity.toInt() : _cartItem!.quantity}'
                                      : '0',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isLoadingCart
                                      ? null
                                      : () => _updateCartQuantity(true),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.add_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.softBeige,
                                foregroundColor: Theme.of(context).colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Continue Shopping'),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: (_currentUserId != null &&
                                  _currentUserId == _product.vendorId) ||
                              _product.stockQuantity <= 0
                          ? null
                          : _addToCart,
                      icon: _isLoadingCart
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.shopping_cart_rounded),
                      label: Text(
                        (_currentUserId != null &&
                                _currentUserId == _product.vendorId)
                            ? 'Your Product'
                            : (_product.stockQuantity <= 0
                                ? 'Out of Stock'
                                : 'Add $_selectedUnitName to Cart'),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: _product.stockQuantity <= 0
                            ? Theme.of(context).textTheme.bodySmall!.color!
                            : AppTheme.accentTerracotta,
                        disabledBackgroundColor: Theme.of(context).textTheme.bodySmall!.color!,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                      ),
                    ),
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
      color: AppTheme.warmWhite,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
