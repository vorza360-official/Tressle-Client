import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tressle_app_1/UI/Widgets/drawerOpener.dart';
import 'dart:math' as math;
import 'package:tressle_app_1/UI/shopDetailScreen.dart';

class HairServiceScreen extends StatefulWidget {
  final String serviceName;

  const HairServiceScreen({Key? key, this.serviceName = 'Hair'})
    : super(key: key);

  @override
  State<HairServiceScreen> createState() => _HairServiceScreenState();
}

class _HairServiceScreenState extends State<HairServiceScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> filteredShops = [];
  bool isLoading = true;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserDataAndShops();
  }

  Future<void> _loadUserDataAndShops() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>?;
          await _loadFilteredShops();
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFilteredShops() async {
    if (userData == null ||
        userData!['latitude'] == null ||
        userData!['longitude'] == null) {
      return;
    }

    double userLat = userData!['latitude'];
    double userLon = userData!['longitude'];

    try {
      QuerySnapshot shopsSnapshot = await _firestore.collection('shops').get();

      List<Map<String, dynamic>> shops = [];

      for (var doc in shopsSnapshot.docs) {
        var shop = doc.data() as Map<String, dynamic>;

        // Check if shop has the service category
        List<dynamic> serviceCategories = shop['services'] ?? [];
        bool hasService = false;

        for (var category in serviceCategories) {
          String categoryName = category['categoryName'] ?? '';
          // Match the service name (case-insensitive)
          if (categoryName.toLowerCase().contains(
                widget.serviceName.toLowerCase(),
              ) ||
              widget.serviceName.toLowerCase().contains(
                categoryName.toLowerCase(),
              )) {
            hasService = true;
            break;
          }
        }

        // If shop has the service, calculate distance
        if (hasService &&
            shop['latitude'] != null &&
            shop['longitude'] != null) {
          double distance = _calculateDistance(
            userLat,
            userLon,
            shop['latitude'],
            shop['longitude'],
          );

          if (distance <= 999999) {
            shop['distance'] = distance;
            shop['shopId'] = doc.id;
            shop['estimatedTime'] = _calculateEstimatedTime(distance);

            // Get the lowest price for this service category
            await _getLowestServicePrice(shop, widget.serviceName);

            shops.add(shop);
          }
        }
      }

      shops.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        filteredShops = shops;
      });
    } catch (e) {
      print('Error loading shops: $e');
    }
  }

  Future<void> _getLowestServicePrice(
    Map<String, dynamic> shop,
    String serviceName,
  ) async {
    try {
      List<dynamic> serviceCategories = shop['services'] ?? [];
      double lowestPrice = 0.0;
      String currency = 'PKR';

      for (var category in serviceCategories) {
        String categoryName = category['categoryName'] ?? '';

        if (categoryName.toLowerCase().contains(serviceName.toLowerCase()) ||
            serviceName.toLowerCase().contains(categoryName.toLowerCase())) {
          List<dynamic> serviceIds = category['services'] ?? [];

          if (serviceIds.isNotEmpty) {
            QuerySnapshot servicesSnapshot = await _firestore
                .collection('services')
                .where(FieldPath.documentId, whereIn: serviceIds)
                .get();

            for (var serviceDoc in servicesSnapshot.docs) {
              var serviceData = serviceDoc.data() as Map<String, dynamic>;
              double price = (serviceData['price'] ?? 0.0).toDouble();

              if (lowestPrice == 0.0 || price < lowestPrice) {
                lowestPrice = price;
                currency = serviceData['currency'] ?? 'PKR';
              }
            }
          }
          break;
        }
      }

      shop['lowestPrice'] = lowestPrice;
      shop['currency'] = currency;
    } catch (e) {
      print('Error getting service price: $e');
      shop['lowestPrice'] = 0.0;
      shop['currency'] = 'PKR';
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371;

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  String _calculateEstimatedTime(double distanceInKm) {
    double timeInHours = distanceInKm / 40;
    int timeInMinutes = (timeInHours * 60).round();
    return '$timeInMinutes min/s';
  }

  int _getOtherServicesCount(Map<String, dynamic> shop) {
    List<dynamic> serviceCategories = shop['services'] ?? [];
    int totalServices = 0;

    for (var category in serviceCategories) {
      List<dynamic> services = category['services'] ?? [];
      totalServices += services.length;
    }

    return totalServices;
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      key: _scaffoldKey,

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 10),
            child: Text(
              '${widget.serviceName} Service',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: "Adamina",
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredShops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No shops offering ${widget.serviceName} service nearby',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredShops.length,
                    itemBuilder: (context, index) {
                      var shop = filteredShops[index];
                      String shopName = shop['shopName'] ?? 'Shop';
                      String shopAddress = shop['shopAddress'] ?? 'Address';
                      String shopImage =
                          shop['shopImage'] ??
                          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=200&h=200&fit=crop&crop=face';
                      double distance = shop['distance'] ?? 0.0;
                      String estimatedTime = shop['estimatedTime'] ?? '';
                      String shopId = shop['shopId'] ?? '';
                      double lowestPrice = shop['lowestPrice'] ?? 0.0;
                      String currency = shop['currency'] ?? 'PKR';
                      int otherServicesCount = _getOtherServicesCount(shop);

                      // ---- NEW: Fetch real shop rating ----
                      Future<Map<String, dynamic>> _fetchShopRating() async {
                        final List<dynamic> reviewIds = shop['ratings'] ?? [];
                        if (reviewIds.isEmpty) {
                          return {'avg': 0.0, 'count': 0};
                        }

                        final List<Future<DocumentSnapshot>> futures = reviewIds
                            .map(
                              (id) => _firestore
                                  .collection('reviews')
                                  .doc(id)
                                  .get(),
                            )
                            .toList();

                        final List<DocumentSnapshot> docs = await Future.wait(
                          futures,
                        );
                        double sum = 0;
                        int count = 0;
                        for (var doc in docs) {
                          if (doc.exists) {
                            final data = doc.data() as Map<String, dynamic>;
                            final rating =
                                data['shopRating'] ?? data['barberRating'] ?? 0;
                            if (rating is num) {
                              sum += rating.toDouble();
                              count++;
                            }
                          }
                        }
                        return {
                          'avg': count == 0 ? 0.0 : sum / count,
                          'count': count,
                        };
                      }

                      return FutureBuilder<Map<String, dynamic>>(
                        future: _fetchShopRating(),
                        builder: (context, ratingSnap) {
                          double avgRating = 0.0;
                          int reviewCount = 0;
                          if (ratingSnap.hasData) {
                            avgRating = ratingSnap.data!['avg'];
                            reviewCount = ratingSnap.data!['count'];
                          }

                          // ---- Helper to build dynamic stars ----
                          List<Widget> _buildStars(double rating) {
                            return List.generate(5, (i) {
                              if (i < rating.floor()) {
                                return const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else if (i < rating) {
                                return const Icon(
                                  Icons.star_half,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              } else {
                                return const Icon(
                                  Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              }
                            });
                          }

                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BarberShopDetailScreen(
                                    shopId: shopId,
                                    shopData: shop,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  width: 1,
                                  color: Colors.black45,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Barber Image
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(shopImage),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Title and Price
                                          Text(
                                            shopName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            lowestPrice > 0
                                                ? '$currency ${lowestPrice.toStringAsFixed(0)}'
                                                : 'Price on request',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          // Location, Distance, and Time
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  shopAddress,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.green,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${distance.toStringAsFixed(1)} km',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.green,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      estimatedTime,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),

                                          // ---- REAL RATING + STARS + COUNT ----
                                          Row(
                                            children: [
                                              ..._buildStars(avgRating),
                                              const SizedBox(width: 4),
                                              Text(
                                                avgRating > 0
                                                    ? avgRating.toStringAsFixed(
                                                        1,
                                                      )
                                                    : '-',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '($reviewCount)',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),

                                          // Other Services
                                          Row(
                                            children: [
                                              Text(
                                                '$otherServicesCount Other Services',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.teal[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                size: 16,
                                                color: Colors.teal[600],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
}
