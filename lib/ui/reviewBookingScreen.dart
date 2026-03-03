import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tressle_app_1/UI/paymentSuccessScreen.dart';
import 'package:tressle_app_1/controller/appointment_controller.dart';

class ReviewBookingScreen extends StatelessWidget {
  final AppointmentController controller = Get.find<AppointmentController>();

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
        centerTitle: false,
        actions: [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '  Review Booking',
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
              fontWeight: FontWeight.w500,
              fontFamily: "Adamina",
            ),
          ),
          Expanded(
            child: Obx(
              () => ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Appointment date and time
                  BookingDetailTile(
                    title: 'Appointment',
                    subtitle: controller.selectedDate.value != null
                        ? '${DateFormat('EEEE, MMMM d').format(controller.selectedDate.value!)}\n${controller.selectedTime.value}'
                        : 'Not selected',
                    hasArrow: true,
                  ),
                  // Staff details
                  BookingDetailTile(
                    title: 'Barber',
                    subtitle: controller.hasSelectedStaff
                        ? '${controller.selectedStaffName.value}\n${controller.selectedStaffDesignation.value}'
                        : 'Not selected',
                    hasArrow: true,
                  ),
                  // Shop address
                  BookingDetailTile(
                    title: 'Address',
                    subtitle: controller.shopAdress.value.isNotEmpty
                        ? '${controller.shopName.value}\n${controller.shopAdress.value}'
                        : 'Not selected',
                    hasArrow: true,
                  ),
                  // Payment placeholder (static as no payment integration provided)
                  BookingDetailTile(
                    title: 'Payment',
                    subtitle: 'Cash',
                    hasArrow: true,
                  ),
                  SizedBox(height: 20),
                  // Service and product breakdown
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Services & Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 12),
                        // Services list
                        ...controller.selectedServices.entries.map((entry) {
                          final service = entry.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                service.serviceName,
                                style: TextStyle(fontSize: 16, height: 1.5),
                              ),
                              Text(
                                '${service.currency} ${service.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        // Products list
                        ...controller.selectedProducts.entries.map((entry) {
                          final product = entry.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.productName,
                                style: TextStyle(fontSize: 16, height: 1.5),
                              ),
                              Text(
                                '${product.currency} ${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                        Divider(height: 32),
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${controller.primaryCurrency} ${controller.grandTotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF00A693),
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
          Obx(
            () => Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: controller.isSavingAppointment.value
                      ? null // Disable button when loading
                      : () async {
                          String? validationMessage = controller
                              .validateForBooking();
                          if (validationMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(validationMessage)),
                            );
                            return;
                          }

                          bool success = await controller.saveAppointment();
                          if (success) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentSuccessScreen(),
                              ),
                              (Route<dynamic> route) =>
                                  route.isFirst, // keep only the first screen
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save appointment'),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isSavingAppointment.value
                        ? Colors.teal[700]!.withOpacity(0.7)
                        : Colors.teal[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isSavingAppointment.value
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BookingDetailTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool hasArrow;

  const BookingDetailTile({
    Key? key,
    required this.title,
    required this.subtitle,
    this.hasArrow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(width: 1, color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          if (hasArrow)
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
