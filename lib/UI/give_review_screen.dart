import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GiveReviewScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final Map<String, dynamic> shopData;
  final String? existingReviewId;

  const GiveReviewScreen({
    Key? key,
    required this.appointmentId,
    required this.appointmentData,
    required this.shopData,
    this.existingReviewId,
  }) : super(key: key);

  @override
  State<GiveReviewScreen> createState() => _GiveReviewScreenState();
}

class _GiveReviewScreenState extends State<GiveReviewScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final TextEditingController _shopReviewController = TextEditingController();
  final TextEditingController _barberReviewController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  
  int _shopRating = 0;
  int _barberRating = 0;
  bool _isSubmitting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingReview();
    // Pre-fill amount from appointment
    _amountPaidController.text = (widget.appointmentData['grandTotal'] ?? 0).toString();
  }

  Future<void> _loadExistingReview() async {
    if (widget.existingReviewId != null) {
      try {
        DocumentSnapshot reviewDoc = await _firestore
            .collection('reviews')
            .doc(widget.existingReviewId)
            .get();
        
        if (reviewDoc.exists) {
          var reviewData = reviewDoc.data() as Map<String, dynamic>;
          setState(() {
            _shopRating = reviewData['shopRating'] ?? 0;
            _barberRating = reviewData['barberRating'] ?? 0;
            _shopReviewController.text = reviewData['shopReview'] ?? '';
            _barberReviewController.text = reviewData['barberReview'] ?? '';
            _amountPaidController.text = (reviewData['amountPaid'] ?? 0).toString();
          });
        }
      } catch (e) {
        print('Error loading review: $e');
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _submitReview() async {
    // Validation
    if (_shopRating == 0) {
      _showErrorSnackBar('Please rate the shop');
      return;
    }
    
    if (_barberRating == 0) {
      _showErrorSnackBar('Please rate the barber');
      return;
    }
    
    if (_shopReviewController.text.trim().isEmpty) {
      _showErrorSnackBar('Please write a review for the shop');
      return;
    }
    
    if (_barberReviewController.text.trim().isEmpty) {
      _showErrorSnackBar('Please write a review for the barber');
      return;
    }
    
    if (_amountPaidController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the amount paid');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get user data
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>?;

      String shopId = widget.appointmentData['shopId'] ?? '';
      String staffId = widget.appointmentData['staffId'] ?? '';
      
      // Prepare review data
      Map<String, dynamic> reviewData = {
        'appointmentId': widget.appointmentId,
        'userId': user.uid,
        'userName': userData?['fullName'] ?? '',
        'userProfilePicture': userData?['profilePicture'] ?? '',
        'shopId': shopId,
        'shopName': widget.appointmentData['shopName'] ?? '',
        'staffId': staffId,
        'staffName': widget.appointmentData['staffName'] ?? '',
        'shopRating': _shopRating,
        'barberRating': _barberRating,
        'shopReview': _shopReviewController.text.trim(),
        'barberReview': _barberReviewController.text.trim(),
        'amountPaid': double.tryParse(_amountPaidController.text.trim()) ?? 0.0,
        'currency': widget.appointmentData['currency'] ?? 'PKR',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String reviewId;
      
      if (widget.existingReviewId != null) {
        // Update existing review
        await _firestore.collection('reviews').doc(widget.existingReviewId).update(reviewData);
        reviewId = widget.existingReviewId!;
        
        _showSuccessSnackBar('Review updated successfully');
      } else {
        // Create new review
        DocumentReference reviewRef = await _firestore.collection('reviews').add(reviewData);
        reviewId = reviewRef.id;
        
        // Add review ID to shop's ratings array
        await _firestore.collection('shops').doc(shopId).update({
          'ratings': FieldValue.arrayUnion([reviewId]),
        });
        
        // Add review ID to employee's ratings array
        await _firestore.collection('employees').doc(staffId).update({
          'ratings': FieldValue.arrayUnion([reviewId]),
        });
        
        _showSuccessSnackBar('Review submitted successfully');
      }

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      _showErrorSnackBar('Error submitting review: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _shopReviewController.dispose();
    _barberReviewController.dispose();
    _amountPaidController.dispose();
    super.dispose();
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
        title: Text(
          widget.existingReviewId != null ? 'Edit Review' : 'Give Review',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: "Adamina",
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shop Information
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(
                                widget.shopData['shopImage'] ??
                                    'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=300&h=200&fit=crop',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.appointmentData['shopName'] ?? 'Shop',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Barber: ${widget.appointmentData['staffName'] ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Shop Review Section
                  const Text(
                    'Shop Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Shop Rating
                  const Text(
                    'Rate the Shop',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _shopRating = index + 1;
                          });
                        },
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: index < _shopRating ? Colors.amber : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 15),
                  
                  // Shop Review Text
                  const Text(
                    'Write your review (max 100 words)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _shopReviewController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with the shop...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Barber Review Section
                  const Text(
                    'Barber Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Barber Rating
                  const Text(
                    'Rate the Barber',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _barberRating = index + 1;
                          });
                        },
                        child: Icon(
                          Icons.star,
                          size: 40,
                          color: index < _barberRating ? Colors.amber : Colors.grey[300],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 15),
                  
                  // Barber Review Text
                  const Text(
                    'Write your review (max 100 words)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _barberReviewController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with the barber...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Amount Paid Section
                  const Text(
                    'Amount Paid',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter total amount paid',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixText: '${widget.appointmentData['currency'] ?? 'PKR'} ',
                      prefixStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.teal.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.existingReviewId != null
                                  ? 'Update Review'
                                  : 'Submit Review',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}