import 'package:flutter/material.dart';
import 'search_results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Mock data for UI
  final List<Map<String, String>> _recentSearches = [
    {'image': 'assets/images/placeholder.png', 'label': 'shoes'}, // Assuming assets exist or will fall back
    {'image': 'assets/images/placeholder.png', 'label': 'lava agni 2 skin'},
    {'image': 'assets/images/placeholder.png', 'label': 'caps for men'},
    {'image': 'assets/images/placeholder.png', 'label': 'back cover'},
  ];

  final List<Map<String, String>> _trendingSearches = [
    {'image': 'assets/images/placeholder.png', 'label': 'Oppo reno 15 5g'},
    {'image': 'assets/images/placeholder.png', 'label': 'Oppo reno 15 pro'},
    {'image': 'assets/images/placeholder.png', 'label': 'Poco m8'},
    {'image': 'assets/images/placeholder.png', 'label': 'Cleaning sponge'},
    {'image': 'assets/images/placeholder.png', 'label': 'Gift cards'},
    {'image': 'assets/images/placeholder.png', 'label': 'Oppo reno14'},
  ];

  final List<Map<String, String>> _recommendedStores = [
    {'image': 'assets/images/placeholder.png', 'label': "Men's Casual Shoes"},
    {'image': 'assets/images/placeholder.png', 'label': "Men's Slippers"},
  ];

  @override
  void initState() {
    super.initState();
    // Auto-focus the search bar when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
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
                    onTap: () => _performSearch(_recentSearches[index]['label']!),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[200],
                            child: const Icon(Icons.history, color: Colors.grey),
                            // backgroundImage: AssetImage(...) // Use real images if available
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 70,
                            child: Text(
                              _recentSearches[index]['label']!,
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

            // Trending Searches
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text('Trending Searches',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
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
              itemCount: _trendingSearches.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                   onTap: () => _performSearch(_trendingSearches[index]['label']!),
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
                          color: Colors.grey[300], // Placeholder for product image
                          child: const Icon(Icons.trending_up, size: 20, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _trendingSearches[index]['label']!,
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

             const SizedBox(height: 20),
            // Recommended Stores
             Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text('Recommended Stores For You',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
             SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _recommendedStores.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.grey[100],
                            width: double.infinity,
                             child: const Icon(Icons.store, size: 48, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(_recommendedStores[index]['label']!, style: const TextStyle(color: Colors.grey)),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
