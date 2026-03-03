import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tressle_app_1/UI/Widgets/drawerOpener.dart';
import 'dart:math' as math;
import 'package:tressle_app_1/UI/shopDetailScreen.dart';

class Neartoyouscreen extends StatefulWidget {
  const Neartoyouscreen({super.key});

  @override
  State<Neartoyouscreen> createState() => _NeartoyouscreenState();
}

class _NeartoyouscreenState extends State<Neartoyouscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> nearbyShops = [];
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
          await _loadNearbyShops();
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

  Future<void> _loadNearbyShops() async {
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

        if (shop['latitude'] != null && shop['longitude'] != null) {
          double distance = _calculateDistance(
            userLat,
            userLon,
            shop['latitude'],
            shop['longitude'],
          );

          if (distance <= 999999) {
            shop['distance'] = distance;
            shop['shopId'] = doc.id;
            // Calculate estimated time (assuming average speed of 40 km/h)
            shop['estimatedTime'] = _calculateEstimatedTime(distance);
            shops.add(shop);
          }
        }
      }

      shops.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        nearbyShops = shops;
      });
    } catch (e) {
      print('Error loading shops: $e');
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
    // Assuming average speed of 40 km/h in city
    double timeInHours = distanceInKm / 40;
    int timeInMinutes = (timeInHours * 60).round();
    return '$timeInMinutes min/s';
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
            child: const Text(
              'Near To You',
              style: TextStyle(
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
                : nearbyShops.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No shops within 20km',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: nearbyShops.length,
                    itemBuilder: (context, index) {
                      var shop = nearbyShops[index];
                      String shopName = shop['shopName'] ?? 'Shop';
                      String shopAddress = shop['shopAddress'] ?? 'Address';
                      String shopImage =
                          shop['shopImage'] ??
                          'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=200&h=200&fit=crop&crop=face';
                      double distance = shop['distance'] ?? 0.0;
                      String estimatedTime = shop['estimatedTime'] ?? '';
                      String shopId = shop['shopId'] ?? '';

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
                            border: Border.all(width: 1, color: Colors.black45),
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
                                      // Title
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
                                      // Address
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.navigation_rounded,
                                            size: 10,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              shopAddress,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Rating, Distance, and Time
                                      Row(
                                        children: [
                                          // Rating
                                          Row(
                                            children: [
                                              ...List.generate(5, (starIndex) {
                                                return Icon(
                                                  Icons.star,
                                                  size: 16,
                                                  color: starIndex < 4
                                                      ? Colors.amber
                                                      : Colors.grey[300],
                                                );
                                              }),
                                              const SizedBox(width: 4),
                                              const Text(
                                                '4.5',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          // Distance
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.green,
                                                        shape: BoxShape.circle,
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

                                          // Estimated Time
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
                  ),
          ),
        ],
      ),
    );
  }
}
