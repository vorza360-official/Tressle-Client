import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tressle_app_1/UI/paymentMethodsScreen.dart';
import 'package:tressle_app_1/controller/appointment_controller.dart';

class BookingTimingScreen extends StatefulWidget {
  const BookingTimingScreen({Key? key}) : super(key: key);

  @override
  State<BookingTimingScreen> createState() => _BookingTimingScreenState();
}

class _BookingTimingScreenState extends State<BookingTimingScreen> {
  late AppointmentController appointmentController;

  DateTime selectedDate = DateTime.now();
  String selectedTime = '';
  String selectedReminder = '30 minutes before';

  PageController pageController = PageController();
  DateTime currentMonth = DateTime.now();

  // Dynamic time slots based on shop timings and booked appointments
  List<String> availableTimeSlots = [];
  Map<String, bool> bookedSlots = {};

  // Shop timings
  List<Map<String, dynamic>> shopTimings = [];
  bool isLoading = true;

  List<String> reminderOptions = [
    '10 minutes before',
    '20 minutes before',
    '30 minutes before',
    '40 minutes before',
    '50 minutes before',
    '1 hour before',
  ];

  @override
  void initState() {
    super.initState();
    try {
      appointmentController = Get.find<AppointmentController>();
      _loadShopData();
    } catch (e) {
      print('Error: AppointmentController not found: $e');
      Get.back();
      return;
    }
  }

  Future<void> _loadShopData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 1. Fetch shop timings from shops collection
      final shopDoc = await FirebaseFirestore.instance
          .collection('shops')
          .doc(appointmentController.shopId.value)
          .get();

      if (shopDoc.exists) {
        final shopData = shopDoc.data() as Map<String, dynamic>;
        shopTimings = List<Map<String, dynamic>>.from(
          shopData['timings'] ?? [],
        );
      }

      // 2. Load initial available time slots for today
      await _loadAvailableTimeSlots(selectedDate);
    } catch (e) {
      print('Error loading shop data: $e');
      Get.snackbar(
        'Error',
        'Failed to load shop timings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableTimeSlots(DateTime date) async {
    try {
      // Clear previous data
      setState(() {
        availableTimeSlots = [];
        bookedSlots = {};
      });

      // 1. Check if shop is open on this day
      if (!_isShopOpenOnDate(date)) {
        setState(() {
          availableTimeSlots = [];
        });
        return;
      }

      // 2. Get shop working hours for this day
      final workingHours = _getShopWorkingHours(date);
      if (workingHours == null) {
        setState(() {
          availableTimeSlots = [];
        });
        return;
      }

      // 3. Generate time slots based on shop working hours
      final generatedSlots = _generateTimeSlots(
        workingHours['startTime']!,
        workingHours['endTime']!,
      );

      // 4. Check which slots are already booked
      await _checkBookedSlots(date, generatedSlots);

      // 5. Filter out booked slots and set available slots
      setState(() {
        availableTimeSlots = generatedSlots
            .where(
              (slot) => !bookedSlots.containsKey(slot) || !bookedSlots[slot]!,
            )
            .toList();

        // Set default selected time if available
        if (availableTimeSlots.isNotEmpty) {
          selectedTime = availableTimeSlots[0];
        } else {
          selectedTime = '';
        }
      });
    } catch (e) {
      print('Error loading available time slots: $e');
    }
  }

  bool _isShopOpenOnDate(DateTime date) {
    if (shopTimings.isEmpty) return false;

    // Get day name
    final dayName = DateFormat('EEEE').format(date);

    // Check if any timing range includes this day
    for (var timing in shopTimings) {
      final startDay = timing['startDay'] as String;
      final endDay = timing['endDay'] as String;

      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      final startIndex = days.indexOf(startDay);
      final endIndex = days.indexOf(endDay);
      final currentIndex = days.indexOf(dayName);

      if (startIndex <= endIndex) {
        // Normal range (e.g., Monday to Friday)
        if (currentIndex >= startIndex && currentIndex <= endIndex) {
          return true;
        }
      } else {
        // Wrap-around range (e.g., Saturday to Monday)
        if (currentIndex >= startIndex || currentIndex <= endIndex) {
          return true;
        }
      }
    }

    return false;
  }

  Map<String, String>? _getShopWorkingHours(DateTime date) {
    if (shopTimings.isEmpty) return null;

    final dayName = DateFormat('EEEE').format(date);
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    for (var timing in shopTimings) {
      final startDay = timing['startDay'] as String;
      final endDay = timing['endDay'] as String;
      final startTime = timing['startTime'] as String;
      final endTime = timing['endTime'] as String;

      final startIndex = days.indexOf(startDay);
      final endIndex = days.indexOf(endDay);
      final currentIndex = days.indexOf(dayName);

      bool isInRange = false;

      if (startIndex <= endIndex) {
        // Normal range
        isInRange = currentIndex >= startIndex && currentIndex <= endIndex;
      } else {
        // Wrap-around range
        isInRange = currentIndex >= startIndex || currentIndex <= endIndex;
      }

      if (isInRange) {
        return {'startTime': startTime, 'endTime': endTime};
      }
    }

    return null;
  }

  List<String> _generateTimeSlots(String startTimeStr, String endTimeStr) {
    List<String> slots = [];

    try {
      // Parse times
      final startParts = startTimeStr.split(':');
      final endParts = endTimeStr.split(':');

      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);

      DateTime slotTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startHour,
        startMinute,
      );

      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endHour,
        endMinute,
      );

      // Generate slots in 1-hour intervals (adjust as needed)
      while (slotTime.isBefore(endDateTime)) {
        final formattedTime = DateFormat('hh:mm a').format(slotTime);
        slots.add(formattedTime);

        // Add 1 hour for next slot (adjust duration as needed)
        slotTime = slotTime.add(Duration(hours: 1));
      }
    } catch (e) {
      print('Error generating time slots: $e');
    }

    return slots;
  }

  Future<void> _checkBookedSlots(DateTime date, List<String> slots) async {
    try {
      // Format date for query
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Create start and end datetime strings
      final startDate = '${formattedDate}T00:00:00';
      final endDate = '${formattedDate}T23:59:59';

      // Query appointments for this shop and date
      final querySnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('shopId', isEqualTo: appointmentController.shopId.value)
          .where('appointmentDate', isGreaterThanOrEqualTo: startDate)
          .where('appointmentDate', isLessThan: endDate)
          .get();

      // Mark booked slots
      for (var doc in querySnapshot.docs) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final appointmentTime = appointmentData['appointmentTime'] as String?;

        if (appointmentTime != null && slots.contains(appointmentTime)) {
          bookedSlots[appointmentTime] = true;
        }
      }

      // Initialize all slots as not booked
      for (var slot in slots) {
        if (!bookedSlots.containsKey(slot)) {
          bookedSlots[slot] = false;
        }
      }
    } catch (e) {
      print('Error checking booked slots: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCalendar(),
                  SizedBox(height: 15),
                  _buildTimeSection(),
                  SizedBox(height: 15),
                  _buildServicesSection(),
                  SizedBox(height: 15),
                  _buildBarberSection(),
                  if (appointmentController.totalProductsCount > 0) ...[
                    SizedBox(height: 15),
                    _buildProductsSection(),
                  ],
                  SizedBox(height: 15),
                  _buildReminderSection(),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),
          _buildBookButton(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getMonthName(currentMonth.month)} ${currentMonth.year}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.teal[700],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.teal[700]),
                  onPressed: () {
                    setState(() {
                      currentMonth = DateTime(
                        currentMonth.year,
                        currentMonth.month - 1,
                      );
                    });
                  },
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.teal[700]),
                  onPressed: () {
                    setState(() {
                      currentMonth = DateTime(
                        currentMonth.year,
                        currentMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        _buildWeekHeader(),
        SizedBox(height: 10),
        _buildCalendarGrid(),
      ],
    );
  }

  Widget _buildWeekHeader() {
    List<String> weekDays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map(
            (day) => Container(
              width: 40,
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    DateTime firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    int daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    int startWeekday = firstDay.weekday % 7;

    List<Widget> dayWidgets = [];

    // Empty cells for days before month starts
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(Container(width: 30, height: 30));
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(currentMonth.year, currentMonth.month, day);
      bool isSelected =
          selectedDate.year == date.year &&
          selectedDate.month == date.month &&
          selectedDate.day == date.day;
      bool isPastDate = date.isBefore(
        DateTime.now().subtract(Duration(days: 1)),
      );

      // Check if shop is open on this day
      bool isShopOpen = _isShopOpenOnDate(date);

      dayWidgets.add(
        GestureDetector(
          onTap: (isPastDate || !isShopOpen)
              ? null
              : () {
                  setState(() {
                    selectedDate = date;
                  });
                  // Load available slots for selected date
                  _loadAvailableTimeSlots(date);
                },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal[700] : Colors.transparent,
              shape: BoxShape.circle,
              border: isShopOpen && !isPastDate
                  ? null
                  : Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 16,
                      color: isPastDate
                          ? Colors.grey[300]
                          : (!isShopOpen
                                ? Colors.grey[400]
                                : (isSelected ? Colors.white : Colors.black)),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (!isShopOpen && !isPastDate)
                    Container(
                      width: 4,
                      height: 4,
                      margin: EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      physics: NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 10),
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        SizedBox(height: 10),
        if (!isLoading &&
            availableTimeSlots.isEmpty &&
            _isShopOpenOnDate(selectedDate))
          Text(
            'No available slots for this date',
            style: TextStyle(color: Colors.red),
          ),
        if (!isLoading && !_isShopOpenOnDate(selectedDate))
          Text(
            'Shop is closed on this day',
            style: TextStyle(color: Colors.red),
          ),
        if (!isLoading && availableTimeSlots.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableTimeSlots.map((time) {
                bool isSelected = selectedTime == time;
                bool isBooked = bookedSlots[time] ?? false;

                return Container(
                  margin: EdgeInsets.only(right: 15),
                  child: GestureDetector(
                    onTap: isBooked
                        ? null
                        : () {
                            setState(() {
                              selectedTime = time;
                            });
                          },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isBooked
                            ? Colors.grey[200]
                            : (isSelected ? Colors.teal[700] : Colors.white),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          width: 1,
                          color: isBooked
                              ? Colors.grey[300]!
                              : (isSelected ? Colors.teal[700]! : Colors.black),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            time,
                            style: TextStyle(
                              color: isBooked
                                  ? Colors.grey[400]
                                  : (isSelected ? Colors.white : Colors.black),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isBooked) SizedBox(width: 8),
                          if (isBooked)
                            Icon(
                              Icons.block,
                              color: Colors.grey[400],
                              size: 14,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServicesSection() {
    var services = appointmentController.selectedServices.values.toList();

    if (services.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: services.take(3).map((service) {
              return Container(
                width: 140,
                height: 200,
                margin: EdgeInsets.only(right: 10),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(0xFF00A86B),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      service.serviceName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      service.duration,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Spacer(),
                    Text(
                      'Service fee',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      '${service.currency} ${service.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarberSection() {
    if (!appointmentController.hasSelectedStaff) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barber',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Obx(
          () => FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('employees')
                .doc(appointmentController.selectedStaffId.value)
                .get(),
            builder: (context, snapshot) {
              String? imageUrl;
              List<dynamic> ratings = [];

              if (snapshot.hasData && snapshot.data != null) {
                var staffData = snapshot.data!.data() as Map<String, dynamic>?;
                if (staffData != null) {
                  imageUrl = staffData['profileImageUrl'];
                  ratings = staffData['ratings'] ?? [];
                }
              }

              return Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : AssetImage("assets/images/barber_image.jpg")
                                as ImageProvider,
                      radius: 35,
                      backgroundColor: Colors.grey[400],
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Icon(Icons.person, size: 35, color: Colors.white)
                          : null,
                    ),
                    SizedBox(height: 8),
                    Text(
                      appointmentController.selectedStaffName.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      appointmentController.selectedStaffDesignation.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    _buildBarberRating(ratings),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarberRating(List<dynamic> ratingIds) {
    if (ratingIds.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, color: Colors.grey, size: 14),
          Text(' New', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.orange, size: 14),
              Text(
                ' ...',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
        }

        var reviews = snapshot.data!.docs;
        if (reviews.isEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 14),
              Text(
                ' New',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, color: Colors.grey, size: 14),
              Text(
                ' New',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
        }

        double averageRating = totalRating / validRatings;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: Colors.orange, size: 14),
            Text(
              ' ${averageRating.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsSection() {
    var products = appointmentController.selectedProducts.values.toList();

    if (products.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Products',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: products.map((product) {
              return Container(
                width: 120,
                margin: EdgeInsets.only(right: 10),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal[700]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.teal[700],
                          size: 18,
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      product.productName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Text(
                      '${product.currency} ${product.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal[700],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        GestureDetector(
          onTap: () {
            _showReminderPicker();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select alert',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Text(
                      selectedReminder,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          if (selectedTime.isEmpty) {
            Get.snackbar(
              'Select Time',
              'Please select a time slot',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          // Check if slot is available
          if (bookedSlots[selectedTime] == true) {
            Get.snackbar(
              'Slot Not Available',
              'This time slot is already booked',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          // Save date and time to controller
          appointmentController.setAppointmentDateTime(
            selectedDate,
            selectedTime,
          );

          print(
            "${appointmentController.selectedDate} , ${appointmentController.selectedTime}",
          );
          Get.to(() => PaymentScreen());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal[700],
          padding: EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Confirm Booking',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showReminderPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Reminder Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              ...reminderOptions.map(
                (option) => ListTile(
                  title: Text(option),
                  trailing: selectedReminder == option
                      ? Icon(Icons.check, color: Colors.teal[700])
                      : null,
                  onTap: () {
                    setState(() {
                      selectedReminder = option;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
