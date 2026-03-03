import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:latlong2/latlong.dart';
import 'package:tressle_app_1/Models/BarberShop.dart';
import 'package:tressle_app_1/UI/Widgets/drawerOpener.dart';
import 'package:tressle_app_1/UI/barberDetailScreen.dart';
import 'package:tressle_app_1/UI/bookingTimmingScreen.dart';
import 'package:tressle_app_1/UI/forgetPasswordUsernameScreen.dart';
import 'package:tressle_app_1/UI/shopOnMapScreen.dart';
import 'package:tressle_app_1/UI/shopReviewsScreen.dart';
import 'package:tressle_app_1/controller/appointment_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class BarberShopDetailScreen extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> shopData;

  const BarberShopDetailScreen({
    Key? key,
    required this.shopId,
    required this.shopData,
  }) : super(key: key);

  @override
  _BarberShopDetailScreenState createState() => _BarberShopDetailScreenState();
}

class _BarberShopDetailScreenState extends State<BarberShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, bool> _expandedSections = {};
  Map<String, Map<String, dynamic>> _servicesData = {};

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // GetX Controller
  final AppointmentController appointmentController = Get.put(
    AppointmentController(),
  );

  int get _selectedServicesCount => appointmentController.totalServicesCount;

  double get _totalPrice => appointmentController.totalServicesPrice;

  void _showFullScreenImage(List<dynamic> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return FullScreenImageGallery(
          images: images,
          initialIndex: initialIndex,
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Set shop details in controller
    appointmentController.setShopDetails(
      widget.shopId,
      widget.shopData['shopName'] ?? 'Shop',
      widget.shopData['shopAddress'],
    );

    // Initialize expanded sections
    List<dynamic> services = widget.shopData['services'] ?? [];
    for (var category in services) {
      String categoryName = category['categoryName'] ?? '';
      _expandedSections[categoryName] = services.indexOf(category) == 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Handle book appointment button
  void _handleBookAppointment() {
    // Check if services are selected
    if (appointmentController.totalServicesCount == 0) {
      Get.snackbar(
        'No Services Selected',
        'Please select at least one service to continue',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: EdgeInsets.all(16),
      );
      _tabController.animateTo(1); // Move to Services tab
      return;
    }

    // Check if staff is selected
    if (!appointmentController.hasSelectedStaff) {
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.teal[700]),
              SizedBox(width: 10),
              Text('Select a Barber'),
            ],
          ),
          content: Text(
            'You must select a barber/staff member before booking an appointment.',
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _tabController.animateTo(2); // Move to Staff tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Select Barber',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Check if products are already selected
    if (appointmentController.selectedProducts.isNotEmpty) {
      // Products are already selected, proceed directly to booking
      _proceedToBooking();
    } else {
      // Ask about products only if none are selected
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.shopping_bag, color: Colors.teal[700]),
              SizedBox(width: 10),
              Text('Add Products?'),
            ],
          ),
          content: Text('Do you want to add any products to your booking?'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                // Proceed without products - Navigate to booking timing screen
                _proceedToBooking();
              },
              child: Text(
                'No, Continue',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Get.back();
                _tabController.animateTo(3); // Move to Products tab
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes, Add Products',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  // Proceed to booking timing screen
  void _proceedToBooking() {
    Get.back(); // Close any open dialog

    // Navigate to booking timing screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingTimingScreen()),
    );
  }

  Future<Map<String, dynamic>> _fetchShopRating() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('shopId', isEqualTo: widget.shopId)
          .get();

      double sum = 0;
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rating = data['shopRating'] ?? data['barberRating'] ?? 0;
        if (rating is num) {
          sum += rating.toDouble();
          count++;
        }
      }

      return {'avg': count == 0 ? 0.0 : sum / count, 'count': count};
    } catch (e) {
      print('Error fetching rating: $e');
      return {'avg': 0.0, 'count': 0};
    }
  }

  // Helper method to format time from "9:0" to "9:00 AM"
  String _formatTime(String time) {
    try {
      List<String> parts = time.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      String minuteStr = minute.toString().padLeft(2, '0');

      return '$displayHour:$minuteStr $period';
    } catch (e) {
      return time;
    }
  }

  // Helper method to display timings properly
  Widget _buildTimingsDisplay(dynamic timingsData) {
    if (timingsData == null) {
      return Text(
        'No timings available',
        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
      );
    }

    // If timings is a List (new format)
    if (timingsData is List) {
      if (timingsData.isEmpty) {
        return Text(
          'No timings available',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timingsData.map<Widget>((slot) {
          String startDay = slot['startDay'] ?? '';
          String endDay = slot['endDay'] ?? '';
          String startTime = slot['startTime'] ?? '';
          String endTime = slot['endTime'] ?? '';

          // Format time from "9:0" to "9:00 AM"
          String formattedStartTime = _formatTime(startTime);
          String formattedEndTime = _formatTime(endTime);

          // Format day range
          String dayRange = startDay == endDay
              ? startDay
              : '$startDay - $endDay';

          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$dayRange: $formattedStartTime - $formattedEndTime',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // If timings is a String (old format) - fallback
    return Text(
      timingsData.toString(),
      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    String shopName = widget.shopData['shopName'] ?? 'Shop';
    String shopAddress = widget.shopData['shopAddress'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: Colors.black),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      key: _scaffoldKey,
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    height: 1.2,
                    fontFamily: "Adamina",
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Haircut",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                // ---- REAL RATING + CLICKABLE ----
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchShopRating(),
                  builder: (context, snapshot) {
                    double avgRating = 0.0;
                    int reviewCount = 0;

                    if (snapshot.hasData) {
                      avgRating = snapshot.data!['avg'];
                      reviewCount = snapshot.data!['count'];
                    }

                    List<Widget> _buildStars(double rating) {
                      return List.generate(5, (i) {
                        if (i < rating.floor()) {
                          return const Icon(
                            Icons.star,
                            size: 20,
                            color: Colors.amber,
                          );
                        } else if (i < rating) {
                          return const Icon(
                            Icons.star_half,
                            size: 20,
                            color: Colors.amber,
                          );
                        } else {
                          return const Icon(
                            Icons.star_border,
                            size: 20,
                            color: Colors.amber,
                          );
                        }
                      });
                    }

                    return GestureDetector(
                      onTap: reviewCount > 0
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShopReviewsScreen(
                                    shopId: widget.shopId,
                                    shopName: shopName,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Row(
                        children: [
                          ..._buildStars(avgRating),
                          const SizedBox(width: 8),
                          Text(
                            avgRating > 0
                                ? '${avgRating.toStringAsFixed(1)} | $reviewCount ${reviewCount == 1 ? 'rating' : 'ratings'}'
                                : 'No ratings yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: reviewCount > 0
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                              decoration: reviewCount > 0
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          // Tab Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[400],
              indicatorColor: Colors.teal[700],
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: [
                Tab(text: "About"),
                Tab(text: "Services"),
                Tab(text: "Staff"),
                Tab(text: "Products"),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildServicesTab(),
                _buildStaffTab(),
                _buildProductsTab(),
              ],
            ),
          ),
          // Bottom Button
          Container(
            padding: EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: Obx(
                () => ElevatedButton(
                  onPressed: () {
                    _handleBookAppointment();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    appointmentController.totalServicesCount > 0
                        ? "Book Appointment (${appointmentController.totalServicesCount} services)"
                        : "Book Appointment",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    List<dynamic> gallery = widget.shopData['gallery'] ?? [];
    String description =
        widget.shopData['description'] ?? 'No description available';
    dynamic timingsData = widget.shopData['timings'];
    String address = widget.shopData['shopAddress'] ?? '';
    String phoneNumber = widget.shopData['phoneNumber'] ?? '';
    String shopName = widget.shopData['shopName'] ?? 'Shop';

    // Add these lines to extract coordinates if available
    String? latitude = widget.shopData['latitude']?.toString();
    String? longitude = widget.shopData['longitude']?.toString();

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gallery Section
          Text(
            "Gallery",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 90,
            child: gallery.isEmpty
                ? Center(
                    child: Text(
                      'No gallery images',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: gallery.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Show full-screen preview
                          _showFullScreenImage(gallery, index);
                        },
                        child: Container(
                          width: 80,
                          height: 90,
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(gallery[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: 10),
          // Description
          Text(
            "Description",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          SizedBox(height: 10),
          // Information
          Text(
            "Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),

          // Timings Section
          _buildTimingsDisplay(timingsData),

          SizedBox(height: 10),
          Container(height: 1, width: double.infinity, color: Colors.black54),
          SizedBox(height: 4),

          // Updated Address Section with Arrow Icon - Now clickable
          GestureDetector(
            onTap: () {
              // Navigate to Shop Location Map Screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopLocationMapScreen(
                    shopName: shopName,
                    shopAddress: address,
                    latitude: latitude,
                    longitude: longitude,
                    phoneNumber: phoneNumber.isNotEmpty
                        ? phoneNumber
                        : '+92 000 0000000',
                  ),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Address",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal[700],
                    ),
                    child: Image.asset(
                      "assets/icons/arrow.png",
                      height: 18,
                      width: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 4),
          Container(height: 1, width: double.infinity, color: Colors.black54),
          SizedBox(height: 4),

          // Updated Phone Number Section with Call Icon - Now clickable
          GestureDetector(
            onTap: () async {
              final String phone = phoneNumber.isNotEmpty
                  ? phoneNumber
                  : '+92 000 0000000';
              final Uri phoneUri = Uri(scheme: 'tel', path: phone);
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not launch phone app'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.transparent),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      phoneNumber.isNotEmpty ? phoneNumber : "+92 000 0000000",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.teal[700],
                    ),
                    child: Icon(Icons.call_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesTab() {
    List<dynamic> servicesCategories = widget.shopData['services'] ?? [];

    if (servicesCategories.isEmpty) {
      return Center(
        child: Text(
          'No services available',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...servicesCategories.map((category) {
            String categoryName = category['categoryName'] ?? '';
            List<dynamic> serviceIds = category['services'] ?? [];
            return Column(
              children: [
                _buildExpandableServiceCategory(categoryName, serviceIds),
                SizedBox(height: 15),
              ],
            );
          }).toList(),
          SizedBox(height: 15),
          // Total
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total $_selectedServicesCount services",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "\ PKR ${_totalPrice.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableServiceCategory(
    String title,
    List<dynamic> serviceIds,
  ) {
    bool isExpanded = _expandedSections[title] ?? false;

    if (serviceIds.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      children: [
        Container(height: 1, width: double.infinity, color: Colors.black54),
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedSections[title] = !isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isExpanded ? null : 0,
          child: isExpanded
              ? StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where(
                        FieldPath.documentId,
                        whereIn: serviceIds.isEmpty ? ['dummy'] : serviceIds,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    var services = snapshot.data!.docs;

                    // Store service data for price calculation
                    for (var doc in services) {
                      var data = doc.data() as Map<String, dynamic>;
                      _servicesData[doc.id] = data;
                    }

                    return Container(
                      padding: EdgeInsets.only(top: 15),
                      child: Column(
                        children: services.map((serviceDoc) {
                          var serviceData =
                              serviceDoc.data() as Map<String, dynamic>;
                          String serviceName = serviceData['name'] ?? '';
                          double price = (serviceData['price'] ?? 0.0)
                              .toDouble();
                          String currency = serviceData['currency'] ?? 'PKR';
                          String duration = serviceData['duration'] ?? '';
                          bool selected = appointmentController
                              .isServiceSelected(serviceDoc.id);

                          return _buildServiceItem(
                            serviceDoc.id,
                            serviceName,
                            "$currency ${price.toStringAsFixed(0)}",
                            selected,
                            price,
                            currency,
                            duration,
                          );
                        }).toList(),
                      ),
                    );
                  },
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    String serviceId,
    String name,
    String price,
    bool selected,
    double priceValue,
    String currency,
    String duration,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          appointmentController.toggleService(
            serviceId,
            name,
            priceValue,
            currency,
            duration,
          );
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            Text(
              "Service fee $price",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            SizedBox(width: 10),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.teal[700]! : Colors.grey[400]!,
                  width: 2,
                ),
                color: selected ? Colors.teal[700] : Colors.transparent,
              ),
              child: selected
                  ? Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab() {
    List<dynamic> staffIds = widget.shopData['staff'] ?? [];
    if (staffIds.isEmpty) {
      return Center(
        child: Text(
          'No staff members',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('employees')
          .where(
            FieldPath.documentId,
            whereIn: staffIds.isEmpty ? ['dummy'] : staffIds,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var staff = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: staff.map((staffDoc) {
              var staffData = staffDoc.data() as Map<String, dynamic>;
              String name = staffData['name'] ?? '';
              String designation = staffData['designation'] ?? '';
              String? imageUrl = staffData['profileImageUrl'];
              List<dynamic> ratings = staffData['ratings'] ?? [];
              bool isSelected =
                  appointmentController.selectedStaffId.value == staffDoc.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    appointmentController.selectStaff(
                      staffDoc.id,
                      name,
                      designation,
                    );
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 37,
                        backgroundImage: imageUrl != null
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl == null
                            ? Icon(Icons.person, size: 40)
                            : null,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  designation,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Spacer(),
                                // Real rating from employee's ratings array
                                _buildRatingWidget(ratings),
                                SizedBox(width: 25),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.teal[700]!
                                : Colors.grey[400]!,
                            width: 2,
                          ),
                          color: isSelected
                              ? Colors.teal[700]
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 14)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Helper widget to build rating display with real data from Firebase
  Widget _buildRatingWidget(List<dynamic> ratingIds) {
    if (ratingIds.isEmpty) {
      return Row(
        children: [
          Icon(Icons.star_border, color: Colors.grey, size: 16),
          SizedBox(width: 4),
          Text("New", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('reviews')
          .where(FieldPath.documentId, whereIn: ratingIds)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 16),
              SizedBox(width: 4),
              SizedBox(
                width: 20,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          );
        }

        // Calculate average rating from barberRating field
        var reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return Row(
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "New",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          );
        }

        double totalRating = 0;
        int validRatings = 0;

        for (var review in reviews) {
          var reviewData = review.data() as Map<String, dynamic>;
          var barberRating = reviewData['barberRating'];
          if (barberRating != null) {
            totalRating += (barberRating is int)
                ? barberRating.toDouble()
                : (barberRating as double);
            validRatings++;
          }
        }

        if (validRatings == 0) {
          return Row(
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "New",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          );
        }

        double averageRating = totalRating / validRatings;

        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 16),
            SizedBox(width: 4),
            Text(
              averageRating.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsTab() {
    List<dynamic> productIds = widget.shopData['products'] ?? [];

    if (productIds.isEmpty) {
      return Center(
        child: Text(
          'No products available',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where(
            FieldPath.documentId,
            whereIn: productIds.isEmpty ? ['dummy'] : productIds,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.docs;

        return SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              var productDoc = products[index];
              var productData = productDoc.data() as Map<String, dynamic>;
              String name = productData['name'] ?? '';
              double price = (productData['price'] ?? 0.0).toDouble();
              String currency = productData['currency'] ?? 'PKR';
              List<dynamic> images = productData['images'] ?? [];
              String? imageUrl = images.isNotEmpty ? images[0] : null;
              bool isSelected = appointmentController.isProductSelected(
                productDoc.id,
              );

              return GestureDetector(
                onTap: () {
                  setState(() {
                    appointmentController.toggleProduct(
                      productDoc.id,
                      name,
                      price,
                      currency,
                    );
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.teal[700]! : Colors.grey[200]!,
                      width: isSelected ? 2 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: imageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: imageUrl == null ? Colors.grey[300] : null,
                            ),
                            child: imageUrl == null
                                ? Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey[500],
                                  )
                                : null,
                          ),
                          if (isSelected)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.teal[700],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "$currency ${price.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class FullScreenImageGallery extends StatefulWidget {
  final List<dynamic> images;
  final int initialIndex;

  const FullScreenImageGallery({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _FullScreenImageGalleryState createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for swiping between images
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(Icons.error, color: Colors.white, size: 50),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Image counter
          if (widget.images.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

          // Swipe instructions for multiple images
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Swipe left or right to navigate',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
