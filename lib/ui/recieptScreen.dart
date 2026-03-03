import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:barcode/barcode.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tressle_app_1/UI/HomeScreen.dart';
import 'package:tressle_app_1/controller/appointment_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EReceiptScreen extends StatelessWidget {
  final AppointmentController controller = Get.find<AppointmentController>();
  final ScreenshotController screenshotController = ScreenshotController();

  // Local reactive variables for user data fetched from Firestore
  final RxString userFullName = 'Loading...'.obs;
  final RxString userEmail = 'Loading...'.obs;
  final RxString userPhone = 'Not provided'.obs;

  EReceiptScreen({Key? key}) : super(key: key) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        userFullName.value = 'Guest';
        userEmail.value = 'Not available';
        userPhone.value = 'Not provided';
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        userFullName.value = data['fullName'] ?? 'Guest';
        userEmail.value = data['email'] ?? currentUser.email ?? 'Not available';

        final phone = data['phoneNumber']?.toString() ?? '';
        userPhone.value = phone.isNotEmpty ? phone : 'Not provided';
      } else {
        // Fallback to Firebase Auth if no Firestore document
        userFullName.value = currentUser.displayName ?? 'Guest';
        userEmail.value = currentUser.email ?? 'Not available';
        userPhone.value = currentUser.phoneNumber ?? 'Not provided';
      }
    } catch (e) {
      // On any error, fallback safely
      final currentUser = FirebaseAuth.instance.currentUser;
      userFullName.value = currentUser?.displayName ?? 'Guest';
      userEmail.value = currentUser?.email ?? 'Not available';
      userPhone.value = 'Not provided';
    }
  }

  // Generate unique barcode based on appointment details
  String generateBarcode() {
    final uniqueData =
        '${controller.userId.value}_${controller.shopId.value}_${controller.selectedDate.value?.toIso8601String()}_${controller.selectedTime.value}';
    final bc = Barcode.gs128();
    return bc.toSvg(uniqueData, width: 300, height: 80);
  }

  // Request storage permission
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        return true; // Android 13+ doesn't need storage permission for gallery
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true; // iOS
  }

  // Save receipt as image
  Future<void> _saveReceiptAsImage(BuildContext context) async {
    try {
      bool hasPermission = await _requestPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Storage permission denied. Cannot save receipt.'),
          ),
        );
        return;
      }

      final uint8List = await screenshotController.capture();
      if (uint8List != null) {
        final result = await SaverGallery.saveImage(
          uint8List,
          quality: 100,
          fileName: 'tressle_receipt_${DateTime.now().millisecondsSinceEpoch}',
          androidRelativePath: 'Pictures/Tressle Receipts',
          skipIfExists: false,
        );

        if (result.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('E-Receipt saved to gallery!')),
          );
          Get.offAll(() => MainScreen(index: 0));
          controller.resetBooking();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save receipt')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture receipt')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving receipt: $e')));
    }
  }

  Widget _buildReceiptRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5, color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String service, String price) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(width: 0.5, color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            service,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: InkWell(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios, color: Colors.black),
          ),
          title: const Text(
            'E-Receipt',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Barcode
                Container(
                  width: double.infinity,
                  height: 120,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SvgPicture.string(
                      generateBarcode(),
                      width: 280,
                      height: 80,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Receipt Details
                Obx(
                  () => Column(
                    children: [
                      _buildReceiptRow(
                        'Barber/Salon',
                        controller.shopName.value,
                      ),
                      _buildReceiptRow('Name', userFullName.value),
                      _buildReceiptRow('Email', userEmail.value),
                      _buildReceiptRow('Mobile Phone', userPhone.value),
                      _buildReceiptRow(
                        'Booking Date',
                        controller.selectedDate.value != null
                            ? DateFormat(
                                'MMMM dd, yyyy',
                              ).format(controller.selectedDate.value!)
                            : 'Not set',
                      ),
                      _buildReceiptRow(
                        'Booking Hours',
                        controller.selectedTime.value.isNotEmpty
                            ? controller.selectedTime.value
                            : 'Not set',
                      ),
                      _buildReceiptRow(
                        'Specialist',
                        controller.selectedStaffName.value.isNotEmpty
                            ? controller.selectedStaffName.value
                            : 'Not set',
                      ),
                      const SizedBox(height: 20),

                      // Services
                      ...controller.selectedServices.entries.map((entry) {
                        final service = entry.value;
                        return _buildServiceRow(
                          service.serviceName,
                          '${service.currency} ${service.price.toStringAsFixed(2)}',
                        );
                      }).toList(),

                      // Products
                      ...controller.selectedProducts.entries.map((entry) {
                        final product = entry.value;
                        return _buildServiceRow(
                          product.productName,
                          '${product.currency} ${product.price.toStringAsFixed(2)}',
                        );
                      }).toList(),

                      const SizedBox(height: 20),

                      // Total
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${controller.primaryCurrency} ${controller.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
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
                ),

                const SizedBox(height: 40),

                // Download Button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => _saveReceiptAsImage(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Download E-Receipt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
