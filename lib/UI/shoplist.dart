import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tressle_app_1/UI/shopDetailScreen.dart';

class ShopsListScreen extends StatefulWidget {
  @override
  _ShopsListScreenState createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Discover Shops',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
          child: Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for shops...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Something went wrong!', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No Shops Available', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Check back later for new shops', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          var shops = snapshot.data!.docs.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            String shopName = (data['shopName'] ?? '').toString().toLowerCase();
            String address = (data['shopAddress'] ?? '').toString().toLowerCase();
            return shopName.contains(_searchQuery) || address.contains(_searchQuery);
          }).toList();

          if (shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No shops found', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Try a different search term', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              var shopDoc = shops[index];
              var shopData = shopDoc.data() as Map<String, dynamic>;
              return _buildShopCard(shopDoc.id, shopData);
            },
          );
        },
      ),
    );
  }

  Widget _buildShopCard(String shopId, Map<String, dynamic> shopData) {
    String shopName = shopData['shopName'] ?? 'Unknown Shop';
    String shopAddress = shopData['shopAddress'] ?? 'No address';
    String? shopImage = shopData['shopImage'];
    String phoneNumber = shopData['phoneNumber'] ?? '';
    String description = shopData['description'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BarberShopDetailScreen(
                shopId: shopId,
                shopData: shopData,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: shopImage != null
                  ? Image.network(
                      shopImage,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(height: 200, color: Colors.grey[300], child: Center(child: CircularProgressIndicator()));
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(height: 200, color: Colors.grey[300], child: Icon(Icons.store, size: 60, color: Colors.grey[500]));
                      },
                    )
                  : Container(height: 200, color: Colors.grey[300], child: Icon(Icons.store, size: 60, color: Colors.grey[500])),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shopName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(shopAddress, style: TextStyle(fontSize: 14, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  if (phoneNumber.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 18, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(phoneNumber, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BarberShopDetailScreen(shopId: shopId, shopData: shopData),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal[700],
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text('View Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
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
  }
}