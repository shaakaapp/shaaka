import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/product_card.dart';
import 'product_details_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _performSearch(widget.query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiService.getProducts(query: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _products = result['data'];
        } else {
          _error = result['error'] is Map
              ? (result['error']['error'] ?? 'Failed to load results')
              : result['error'].toString();
        }
      });
    }
  }
  
  void _onSearchSubmitted(String value) {
      if (value.trim().isNotEmpty) {
          _performSearch(value);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
         titleSpacing: 0,
        title: Container(
          height: 40,
          margin: const EdgeInsets.only(right: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                    _searchController.clear();
                },
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
             textInputAction: TextInputAction.search,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
        actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Stack(
                  alignment: Alignment.center,
                  children: [
                       const Icon(Icons.shopping_cart_outlined, color: Colors.black),
                       // Badge could go here
                  ]
              ),
            )
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Sort', Icons.keyboard_arrow_down),
                const SizedBox(width: 8),
                _buildFilterChip('Filter', Icons.tune),
                 const SizedBox(width: 8),
                _buildFilterChip('Latest Trends', Icons.local_fire_department, isSelected: true),
                 const SizedBox(width: 8),
                _buildFilterChip('Top Rated', Icons.star_border),
                 const SizedBox(width: 8),
                _buildFilterChip('Brand', Icons.keyboard_arrow_down),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _products.isEmpty
                        ? const Center(child: Text('No products found matching your search.'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              return ProductCard(
                                product: _products[index],
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailsPage(product: _products[index]),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData? icon, {bool isSelected = false}) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            if (icon != null && isSelected) ...[
                 Icon(icon, size: 16, color: Colors.purple),
                 const SizedBox(width: 4),
            ] else if (icon != null && !label.contains('Sort') && !label.contains('Brand')) ...[
               Icon(icon, size: 16, color: Colors.black54),
               const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.purple : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
             if (icon != null && (label.contains('Sort') || label.contains('Brand'))) ...[
               const SizedBox(width: 4),
                 Icon(icon, size: 16, color: Colors.black54),
            ],
        ],
      ),
      backgroundColor: isSelected ? Colors.purple.withOpacity(0.1) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? Colors.purple : Colors.grey[300]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
