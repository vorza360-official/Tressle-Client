import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:tressle_app_1/ui/BarberHomeScreen.dart';
import 'dart:math' as math;

import 'package:tressle_app_1/ui/give_review_screen.dart';
import 'package:tressle_app_1/ui/shopDetailScreen.dart';
import 'package:tressle_app_1/controller/appointment_controller.dart';

class HistoryBookingWidget extends StatefulWidget {
  const HistoryBookingWidget({super.key});

  @override
  State<HistoryBookingWidget> createState() => _HistoryBookingWidgetState();
}

class _HistoryBookingWidgetState extends State<HistoryBookingWidget> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
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

  Future<void> _orderAgain(
    Map<String, dynamic> appointment,
    Map<String, dynamic> shopData,
  ) async {
    try {
      // Initialize GetX controller
      final AppointmentController appointmentController = Get.put(
        AppointmentController(),
      );

      // Clear previous selections
      appointmentController.resetBooking();

      // Set shop details
      appointmentController.setShopDetails(
        appointment['shopId'] ?? '',
        appointment['shopName'] ?? '',
        shopData['shopAddress'] ?? '',
      );

      // Add services
      List<dynamic> services = appointment['services'] ?? [];
      for (var service in services) {
        appointmentController.toggleService(
          service['serviceId'] ?? '',
          service['serviceName'] ?? '',
          (service['price'] ?? 0.0).toDouble(),
          service['currency'] ?? 'PKR',
          service['duration'] ?? '',
        );
      }

      // Add products if any
      List<dynamic> products = appointment['products'] ?? [];
      for (var product in products) {
        appointmentController.toggleProduct(
          product['productId'] ?? '',
          product['productName'] ?? '',
          (product['price'] ?? 0.0).toDouble(),
          product['currency'] ?? 'PKR',
        );
      }

      // Select staff if available
      if (appointment['staffId'] != null) {
        appointmentController.selectStaff(
          appointment['staffId'],
          appointment['staffName'] ?? '',
          appointment['staffDesignation'] ?? '',
        );
      }

      // Navigate to shop detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarberShopDetailScreen(
            shopId: appointment['shopId'] ?? '',
            shopData: shopData,
          ),
        ),
      );

      Get.snackbar(
        'Order Loaded',
        'Previous order has been loaded. You can modify it before booking.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal[700],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load previous order: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('appointments')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .where('status', whereIn: ['completed', 'cancelled'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No appointment history',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var appointmentDoc = snapshot.data!.docs[index];
                    var appointment =
                        appointmentDoc.data() as Map<String, dynamic>;
                    String appointmentId = appointmentDoc.id;

                    String shopId = appointment['shopId'] ?? '';

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestore.collection('shops').doc(shopId).get(),
                      builder: (context, shopSnapshot) {
                        if (!shopSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        var shopData =
                            shopSnapshot.data!.data() as Map<String, dynamic>?;
                        if (shopData == null) return const SizedBox.shrink();

                        // ---- NEW: fetch reviews for this shop to compute rating ----
                        Future<Map<String, dynamic>> _fetchShopRating() async {
                          final List<dynamic> reviewIds =
                              shopData['ratings'] ?? [];
                          if (reviewIds.isEmpty) {
                            return {'avg': 0.0, 'count': 0};
                          }

                          final List<Future<DocumentSnapshot>> futures =
                              reviewIds
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
                                  data['shopRating'] ??
                                  data['barberRating'] ??
                                  0;
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

                        String shopName =
                            appointment['shopName'] ??
                            shopData['shopName'] ??
                            'Shop';
                        String shopAddress =
                            shopData['shopAddress'] ?? 'Address';
                        String shopImage =
                            shopData['shopImage'] ??
                            'https://images.unsplash.com/photo-1622286342621-4bd786c2447c?w=200&h=200&fit=crop&crop=face';

                        double distance = 0.0;
                        String estimatedTime = '';

                        if (userData != null &&
                            userData!['latitude'] != null &&
                            userData!['longitude'] != null &&
                            shopData['latitude'] != null &&
                            shopData['longitude'] != null) {
                          distance = _calculateDistance(
                            userData!['latitude'],
                            userData!['longitude'],
                            shopData['latitude'],
                            shopData['longitude'],
                          );
                          estimatedTime = _calculateEstimatedTime(distance);
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

                            // ---- Helper to build star icons ----
                            List<Widget> _buildStars(double rating) {
                              return List.generate(5, (i) {
                                return Icon(
                                  i < rating.floor()
                                      ? Icons.star
                                      : i < rating
                                      ? Icons.star_half
                                      : Icons.star_border,
                                  size: 16,
                                  color: Colors.amber,
                                );
                              });
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AppointmentDetailScreen(
                                          appointmentId: appointmentId,
                                          appointmentData: appointment,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
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

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
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
                                                if (distance > 0) ...[
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 4,
                                                          vertical: 4,
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
                                                                color: Colors
                                                                    .green,
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${distance.toStringAsFixed(1)} km',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),

                                            // ---- REAL STARS + RATING + COUNT ----
                                            Row(
                                              children: [
                                                ..._buildStars(avgRating),
                                                const SizedBox(width: 4),
                                                Text(
                                                  avgRating > 0
                                                      ? avgRating
                                                            .toStringAsFixed(1)
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
                                            const SizedBox(height: 5),

                                            // Review Button - Only for completed appointments
                                            if (appointment['status'] ==
                                                'completed')
                                              FutureBuilder<QuerySnapshot>(
                                                future: _firestore
                                                    .collection('reviews')
                                                    .where(
                                                      'appointmentId',
                                                      isEqualTo: appointmentId,
                                                    )
                                                    .where(
                                                      'userId',
                                                      isEqualTo: _auth
                                                          .currentUser
                                                          ?.uid,
                                                    )
                                                    .limit(1)
                                                    .get(),
                                                builder: (context, reviewSnapshot) {
                                                  bool hasReview =
                                                      reviewSnapshot.hasData &&
                                                      reviewSnapshot
                                                          .data!
                                                          .docs
                                                          .isNotEmpty;
                                                  String? existingReviewId =
                                                      hasReview
                                                      ? reviewSnapshot
                                                            .data!
                                                            .docs
                                                            .first
                                                            .id
                                                      : null;

                                                  return GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              GiveReviewScreen(
                                                                appointmentId:
                                                                    appointmentId,
                                                                appointmentData:
                                                                    appointment,
                                                                shopData:
                                                                    shopData,
                                                                existingReviewId:
                                                                    existingReviewId,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 15,
                                                            vertical: 8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          width: 1,
                                                          color: Colors
                                                              .teal
                                                              .shade700,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        hasReview
                                                            ? 'Edit Review'
                                                            : 'Give Review',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Colors.teal[600],
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
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
