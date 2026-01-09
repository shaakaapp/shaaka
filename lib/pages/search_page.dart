import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'search_results_page.dart';
import 'product_details_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<String> _recentSearches = [];
  List<Product> _trendingProducts = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    _loadRecentSearches();
    _loadTrendingProducts();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> searches = prefs.getStringList('recent_searches') ?? [];
    
    // Remove if exists to move to top
    searches.remove(query);
    // Add to top
    searches.insert(0, query);
    // Keep max 10
    if (searches.length > 10) {
      searches = searches.sublist(0, 10);
    }
    
    await prefs.setStringList('recent_searches', searches);
    _loadRecentSearches();
  }

  Future<void> _loadTrendingProducts() async {
    // Fetch top rated products as "Trending"
    final result = await ApiService.getProducts(ordering: '-rating_count', limit: 6);
    if (mounted) {
      setState(() {
        _isLoadingTrending = false;
        if (result['success'] == true) {
          _trendingProducts = result['data'];
        }
      });
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    _saveSearch(query);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(query: query),
      ),
    );
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
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search for products...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _searchController.clear,
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
            onSubmitted: _performSearch,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent Searches
            if (_recentSearches.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: const Text('Recent Searches',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentSearches.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _performSearch(_recentSearches[index]),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[200],
                                child: const Icon(Icons.history, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  _recentSearches[index],
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 0.5),
            ],

            // Trending Searches / Top Products
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text('Trending Products', // Renamed as we are showing products
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            if (_isLoadingTrending)
                 const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_trendingProducts.isEmpty)
                 const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("No trending products yet."))
            else
                GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5, // Wide minimal cards
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                ),
                itemCount: _trendingProducts.length,
                itemBuilder: (context, index) {
                    final product = _trendingProducts[index];
                    return GestureDetector(
                    onTap: () {
                         Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => ProductDetailsPage(product: product))
                        );
                    },
                    child: Container(
                        decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Row(
                        children: [
                            Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child: product.firstImageUrl != null 
                                ? Image.network(product.firstImageUrl!, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 20))
                                : const Icon(Icons.trending_up, size: 20, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                            child: Text(
                                product.name,
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                            ),
                            ),
                        ],
                        ),
                    ),
                    );
                },
                ),
          ],
        ),
      ),
    );
  }
}
