import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/HomeScreen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Simulate no notifications (change this logic based on your actual data)
    final bool hasNotifications =
        false; // Set to true if you have real notifications

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(index: 0)),
          (Route<dynamic> route) => false,
        );
        return false; // Prevents default back button behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Text(
                  'Notification',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: "Adamina",
                  ),
                ),
              ),
              Expanded(
                child: hasNotifications
                    ? ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        itemCount:
                            20, // Replace with your actual notification count
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10.0),
                            padding: const EdgeInsets.only(bottom: 5),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 1,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.teal[700],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.asset(
                                    "assets/icons/notification_screen_icon.png",
                                    height: 25,
                                    width: 25,
                                    color: Colors
                                        .white, // Optional: make icon white for better contrast
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Barbershop',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      Text(
                                        'Your Booking Appointment has been ..',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '34 minutes',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF9CA3AF),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // You can replace this with your own empty state icon
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Notification Yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'We\'ll notify you when something new arrives',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
