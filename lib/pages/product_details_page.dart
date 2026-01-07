import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _initialize();
  }

  Future<void> _initialize() async {
    _currentUserId = await StorageService.getUserId();
    _loadReviews();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_product.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewDialog,
        label: Text(_userReview != null ? 'Edit Review' : 'Write Review'),
        icon: Icon(_userReview != null ? Icons.edit : Icons.rate_review),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Images Carousel (Simplified as SizedBox with PageView)
            SizedBox(
              height: 300,
              child: _product.images.isNotEmpty
                  ? PageView.builder(
                      itemCount: _product.images.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          _product.images[index].imageUrl,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 64, color: Colors.grey)),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(
                         '₹${_product.price} / ${_product.unit}',
                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                       ),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                         child: Row(
                           children: [
                               const Icon(Icons.star, size: 16, color: Colors.purple), // Using purple or amber
                               const SizedBox(width: 4),
                               Text('${_product.averageRating} (${_product.ratingCount} reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
                           ],
                         ),
                       )
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text('Sold by: ${_product.vendorName}', style: const TextStyle(color: Colors.grey)),
                   const SizedBox(height: 16),
                   const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   const SizedBox(height: 8),
                   Text(_product.description ?? 'No description available.'),
                   
                   const SizedBox(height: 24),
                   const Divider(),
                   const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                   const SizedBox(height: 8),
                   
                   if (_isLoadingReviews)
                      const Center(child: CircularProgressIndicator())
                   else if (_reviews.isEmpty)
                      const Text('No reviews yet. Be the first to review!')
                   else
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          // Highlight user review?
                          final isUserReview = _currentUserId != null && review.userId == _currentUserId;
                          
                          return Card(
                            color: isUserReview ? Colors.blue[50] : null,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isUserReview ? Colors.blue : null,
                                child: Text(review.userName[0].toUpperCase())),
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
                   const SizedBox(height: 60), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
