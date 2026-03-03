import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentController extends GetxController {
  // User Information
  var userId = ''.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;

  // Shop Information
  var shopId = ''.obs;
  var shopName = ''.obs;
  var shopAdress = ''.obs;

  // Selected Services (Map of serviceId -> service details)
  var selectedServices = <String, ServiceSelection>{}.obs;

  // Selected Staff
  var selectedStaffId = ''.obs;
  var selectedStaffName = ''.obs;
  var selectedStaffDesignation = ''.obs;

  // Selected Products (Map of productId -> product details)
  var selectedProducts = <String, ProductSelection>{}.obs;

  // Appointment Date and Time
  var selectedDate = Rx<DateTime?>(null);
  var selectedTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
  }

  // Load current user information
  Future<void> _loadUserInfo() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        userId.value = currentUser.uid;
        userEmail.value = currentUser.email ?? '';

        // Load additional user info from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          userName.value = userData['name'] ?? '';
          userPhone.value = userData['phone'] ?? '';
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  // Set shop details
  void setShopDetails(String id, String name, String adress) {
    shopId.value = id;
    shopName.value = name;
    shopAdress.value = adress;
  }

  // Toggle service selection
  void toggleService(
    String serviceId,
    String serviceName,
    double price,
    String currency,
    String duration,
  ) {
    if (selectedServices.containsKey(serviceId)) {
      selectedServices.remove(serviceId);
    } else {
      selectedServices[serviceId] = ServiceSelection(
        serviceId: serviceId,
        serviceName: serviceName,
        price: price,
        currency: currency,
        duration: duration,
      );
    }
  }

  // Check if service is selected
  bool isServiceSelected(String serviceId) {
    return selectedServices.containsKey(serviceId);
  }

  // Get total services count
  int get totalServicesCount => selectedServices.length;

  // Get total services price
  double get totalServicesPrice {
    double total = 0.0;
    selectedServices.forEach((key, service) {
      total += service.price;
    });
    return total;
  }

  // Get primary currency (from first selected service)
  String get primaryCurrency {
    if (selectedServices.isEmpty) return 'PKR';
    return selectedServices.values.first.currency;
  }

  // Select staff member
  void selectStaff(String staffId, String staffName, String designation) {
    selectedStaffId.value = staffId;
    selectedStaffName.value = staffName;
    selectedStaffDesignation.value = designation;
  }

  // Check if staff is selected
  bool get hasSelectedStaff => selectedStaffId.value.isNotEmpty;

  // Toggle product selection
  void toggleProduct(
    String productId,
    String productName,
    double price,
    String currency,
  ) {
    if (selectedProducts.containsKey(productId)) {
      selectedProducts.remove(productId);
    } else {
      selectedProducts[productId] = ProductSelection(
        productId: productId,
        productName: productName,
        price: price,
        currency: currency,
      );
    }
  }

  // Check if product is selected
  bool isProductSelected(String productId) {
    return selectedProducts.containsKey(productId);
  }

  // Get total products count
  int get totalProductsCount => selectedProducts.length;

  // Get total products price
  double get totalProductsPrice {
    double total = 0.0;
    selectedProducts.forEach((key, product) {
      total += product.price;
    });
    return total;
  }

  // Get grand total (services + products)
  double get grandTotal {
    return totalServicesPrice + totalProductsPrice;
  }

  // Set appointment date and time
  void setAppointmentDateTime(DateTime date, String time) {
    selectedDate.value = date;
    selectedTime.value = time;
  }

  // Validate if ready to book
  bool canProceedToBooking() {
    return selectedServices.isNotEmpty;
  }

  bool canFinalizeBooking() {
    return selectedServices.isNotEmpty &&
        hasSelectedStaff &&
        selectedDate.value != null &&
        selectedTime.value.isNotEmpty;
  }

  // Show service selection reminder
  String? validateForBooking() {
    if (selectedServices.isEmpty) {
      return 'Please select at least one service';
    }
    if (!hasSelectedStaff) {
      return 'Please select a barber/staff member';
    }
    return null;
  }

  // Create appointment data for Firestore
  Map<String, dynamic> getAppointmentData() {
    return {
      'userId': userId.value,
      'userName': userName.value,
      'userEmail': userEmail.value,
      'userPhone': userPhone.value,
      'shopId': shopId.value,
      'shopName': shopName.value,
      'services': selectedServices.values.map((s) => s.toMap()).toList(),
      'staffId': selectedStaffId.value,
      'staffName': selectedStaffName.value,
      'staffDesignation': selectedStaffDesignation.value,
      'products': selectedProducts.values.map((p) => p.toMap()).toList(),
      'appointmentDate': selectedDate.value?.toIso8601String(),
      'appointmentTime': selectedTime.value,
      'totalServicesPrice': totalServicesPrice,
      'totalProductsPrice': totalProductsPrice,
      'grandTotal': grandTotal,
      'currency': primaryCurrency,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  RxBool isSavingAppointment = false.obs;

  // Save appointment to Firestore
  Future<bool> saveAppointment() async {
    try {
      if (!canFinalizeBooking()) {
        return false;
      }
      isSavingAppointment.value = true;

      await FirebaseFirestore.instance
          .collection('appointments')
          .add(getAppointmentData());

      return true;
    } catch (e) {
      print('Error saving appointment: $e');
      return false;
    } finally {
      isSavingAppointment.value = false;
    }
  }

  // Reset all selections
  void resetBooking() {
    selectedServices.clear();
    selectedStaffId.value = '';
    selectedStaffName.value = '';
    selectedStaffDesignation.value = '';
    selectedProducts.clear();
    selectedDate.value = null;
    selectedTime.value = '';
  }

  // Get booking summary
  String getBookingSummary() {
    StringBuffer summary = StringBuffer();
    summary.writeln('Shop: $shopName');
    summary.writeln('Services: ${totalServicesCount}');
    summary.writeln('Staff: $selectedStaffName');
    summary.writeln('Products: ${totalProductsCount}');
    summary.writeln('Total: $primaryCurrency ${grandTotal.toStringAsFixed(2)}');
    return summary.toString();
  }
}

// Service Selection Model
class ServiceSelection {
  final String serviceId;
  final String serviceName;
  final double price;
  final String currency;
  final String duration;

  ServiceSelection({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.currency,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'currency': currency,
      'duration': duration,
    };
  }
}

// Product Selection Model
class ProductSelection {
  final String productId;
  final String productName;
  final double price;
  final String currency;

  ProductSelection({
    required this.productId,
    required this.productName,
    required this.price,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'currency': currency,
    };
  }
}
