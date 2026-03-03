import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tressle_app_1/ui/BarberHomeScreen.dart';
import 'dart:math' as math;

class UpCommingBookingWidget extends StatefulWidget {
  const UpCommingBookingWidget({super.key});

  @override
  State<UpCommingBookingWidget> createState() => _UpCommingBookingWidgetState();
}

class _UpCommingBookingWidgetState extends State<UpCommingBookingWidget> {
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

  String _formatAppointmentDate(Map<String, dynamic> appointment) {
    try {
      // Get the date part (as string or Timestamp)
      DateTime datePart;
      dynamic dateData = appointment['appointmentDate'];

      if (dateData is String) {
        datePart = DateTime.parse(dateData);
      } else if (dateData is Timestamp) {
        datePart = dateData.toDate();
      } else {
        return 'Date not available';
      }

      // Get the time string, e.g., "12:00 PM"
      String? timeString = appointment['appointmentTime'] as String?;
      if (timeString == null || timeString.isEmpty) {
        // Fallback: use the time from datePart if no separate time
        return DateFormat('MMM dd, yyyy • hh:mm a').format(datePart);
      }

      // Parse the time (hh:mm a) format
      final timeFormat = DateFormat('hh:mm a');
      DateTime timePart = timeFormat.parse(timeString);

      // Combine: use date from datePart, time from timePart
      DateTime combined = DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        timePart.hour,
        timePart.minute,
      );

      // Now format the correct combined date-time
      return DateFormat('MMM dd, yyyy • hh:mm a').format(combined);
    } catch (e) {
      print('Error formatting appointment date/time: $e');
      return 'Date not available';
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

  // Check if appointment can be cancelled (within 30 minutes of booking)
  bool _canCancelAppointment(Map<String, dynamic> appointmentData) {
    if (appointmentData['createdAt'] == null) {
      return false;
    }

    try {
      DateTime bookingTime;

      // Handle both Timestamp and String formats
      if (appointmentData['createdAt'] is String) {
        bookingTime = DateTime.parse(appointmentData['createdAt']);
      } else {
        // Firebase Timestamp
        bookingTime = (appointmentData['createdAt'] as Timestamp).toDate();
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(bookingTime);

      // Can cancel only within 30 minutes
      return difference.inMinutes <= 30;
    } catch (e) {
      print('Error parsing booking time: $e');
      return false;
    }
  }

  // Get remaining time for cancellation
  String _getRemainingCancellationTime(Map<String, dynamic> appointmentData) {
    if (appointmentData['createdAt'] == null) {
      return '';
    }

    try {
      DateTime bookingTime;

      if (appointmentData['createdAt'] is String) {
        bookingTime = DateTime.parse(appointmentData['createdAt']);
      } else {
        bookingTime = (appointmentData['createdAt'] as Timestamp).toDate();
      }

      DateTime now = DateTime.now();
      Duration difference = now.difference(bookingTime);
      int remainingMinutes = 30 - difference.inMinutes;

      if (remainingMinutes > 0) {
        return '$remainingMinutes minutes';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling appointment: $e')),
      );
    }
  }

  void _handleCancelAppointment(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) {
    if (!_canCancelAppointment(appointmentData)) {
      // Show dialog that cancellation is not possible
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Unable to Cancel'),
            ],
          ),
          content: const Text(
            'Appointment cancellation can only be done within the first 30 minutes of booking. Your cancellation window has expired.',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show confirmation dialog with remaining time
      _showCancelDialog(appointmentId, appointmentData);
    }
  }

  void _showCancelDialog(
    String appointmentId,
    Map<String, dynamic> appointmentData,
  ) {
    String remainingTime = _getRemainingCancellationTime(appointmentData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this appointment? This action cannot be undone.',
            ),
            if (remainingTime.isNotEmpty) ...[
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Time remaining for cancellation: $remainingTime',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointmentId);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
                  .where('status', whereIn: ['waiting', 'processing'])
                  .orderBy('appointmentDate')
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
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No upcoming appointments',
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

                        // ---- NEW: Fetch real shop rating ----
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
                                            Row(
                                              children: [
                                                // ---- APPOINTMENT DATE AND TIME ----
                                                if (appointment['appointmentDate'] !=
                                                    null)
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today,
                                                        size: 12,
                                                        color: Colors.blueGrey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _formatAppointmentDate(
                                                          appointment,
                                                        ), // pass appointment map, not just date
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.blueGrey,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                Spacer(),
                                                GestureDetector(
                                                  onTap: () =>
                                                      _handleCancelAppointment(
                                                        appointmentId,
                                                        appointment,
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
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
                                                      'Cancel',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.teal[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
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
