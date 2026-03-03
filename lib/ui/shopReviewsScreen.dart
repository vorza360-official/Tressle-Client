// UI/ShopReviewsScreen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShopReviewsScreen extends StatelessWidget {
  final String shopId;
  final String shopName;

  const ShopReviewsScreen({
    Key? key,
    required this.shopId,
    required this.shopName,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchShopRatingStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: shopId)
          .get();

      double sum = 0;
      int count = 0;
      Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = data['shopRating'] ?? 0;
        if (rating is num) {
          sum += rating.toDouble();
          count++;
          starDistribution[rating.round()] = (starDistribution[rating.round()] ?? 0) + 1;
        }
      }

      return {
        'avg': count == 0 ? 0.0 : sum / count,
        'count': count,
        'distribution': starDistribution,
      };
    } catch (e) {
      print('Error fetching rating: $e');
      return {'avg': 0.0, 'count': 0, 'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0}};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              shopName,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Rating Summary Card
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchShopRatingStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  height: 200,
                  color: Colors.white,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              double avgRating = snapshot.data!['avg'];
              int reviewCount = snapshot.data!['count'];
              Map<int, int> distribution = snapshot.data!['distribution'];

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Average Rating
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  if (i < avgRating.floor()) {
                                    return Icon(Icons.star, size: 20, color: Colors.amber);
                                  } else if (i < avgRating) {
                                    return Icon(Icons.star_half, size: 20, color: Colors.amber);
                                  } else {
                                    return Icon(Icons.star_border, size: 20, color: Colors.amber);
                                  }
                                }),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '$reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 24),
                        // Right side - Star Distribution
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [5, 4, 3, 2, 1].map((star) {
                              int count = distribution[star] ?? 0;
                              double percentage = reviewCount > 0 ? (count / reviewCount) : 0;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      '$star',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.star, size: 14, color: Colors.amber),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: percentage,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                                          minHeight: 6,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '$count',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          // Reviews List Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[50],
            child: Text(
              'Customer Reviews',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),

          // Reviews List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('shopId', isEqualTo: shopId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reviews',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No reviews yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to review this shop!',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                // Sort reviews by date (newest first)
                List<QueryDocumentSnapshot> reviews = snapshot.data!.docs;
                reviews.sort((a, b) {
                  Timestamp? timeA = (a.data() as Map<String, dynamic>)['createdAt'];
                  Timestamp? timeB = (b.data() as Map<String, dynamic>)['createdAt'];
                  if (timeA == null || timeB == null) return 0;
                  return timeB.compareTo(timeA);
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = reviews[index];
                    final data = doc.data() as Map<String, dynamic>;

                    String userName = data['userName'] ?? 'Anonymous';
                    String comment = data['shopReview'] ?? data['barberReview'] ?? '';
                    num rating = data['shopRating'] ?? data['barberRating'] ?? 0;
                    Timestamp? timestamp = data['createdAt'];
                    String date = timestamp != null
                        ? DateFormat('MMMM d, yyyy • h:mm a').format(timestamp.toDate())
                        : 'Unknown date';
                    
                    // Calculate time ago
                    String timeAgo = '';
                    if (timestamp != null) {
                      Duration difference = DateTime.now().difference(timestamp.toDate());
                      if (difference.inDays > 365) {
                        timeAgo = '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'year' : 'years'} ago';
                      } else if (difference.inDays > 30) {
                        timeAgo = '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'month' : 'months'} ago';
                      } else if (difference.inDays > 0) {
                        timeAgo = '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
                      } else if (difference.inHours > 0) {
                        timeAgo = '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
                      } else {
                        timeAgo = 'Just now';
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info & Rating
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // User Avatar
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.teal[400]!, Colors.teal[700]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // User Name & Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Star Rating
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.amber[200]!, width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.amber[700]),
                                    SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[900],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Stars Display
                          Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            child: Row(
                              children: List.generate(5, (i) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Icon(
                                    i < rating.floor()
                                        ? Icons.star_rounded
                                        : i < rating
                                            ? Icons.star_half_rounded
                                            : Icons.star_outline_rounded,
                                    size: 20,
                                    color: Colors.amber[600],
                                  ),
                                );
                              }),
                            ),
                          ),

                          // Review Comment
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              comment,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.6,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 8),
                            Text(
                              'No written review provided',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],

                          // Date (full format at bottom)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 12, color: Colors.grey[400]),
                                SizedBox(width: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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