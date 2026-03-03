import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/HomeScreen.dart';
import 'package:tressle_app_1/UI/mapScreen.dart';
import 'package:tressle_app_1/UI/shoplist.dart';

class LocationScreen extends StatelessWidget {
  Future<void> _markOnboardingComplete() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'hasCompletedOnboarding': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      print('Error marking onboarding complete: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            spacing: 8,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                "assets/icons/location_icon.png",
                width: 100,
                height: 100,
              ),
              SizedBox(height: 10),
              Text(
                'Hello , nice to \nmeet you',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: "Adamina",
                ),
              ),

              Text(
                'Get your location to start find barbershop \nnear you',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 10),

              // Buttons
              SizedBox(
                height: 40,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    // Mark onboarding as complete
                    await _markOnboardingComplete();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarberMapScreen(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Location permission requested')),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icons/arrow.png",
                        height: 18,
                        width: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Use current location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),

              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () async {
              //       // Mark onboarding as complete
              //       await _markOnboardingComplete();

              //       Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(builder: (context) => MainScreen()),
              //       );
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         SnackBar(content: Text('Location permission requested')),
              //       );
              //     },
              //     child: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(Icons.navigation, size: 20),
              //         SizedBox(width: 8),
              //         Text(
              //           'Go to Home',
              //           style: TextStyle(fontWeight: FontWeight.w600),
              //         ),
              //       ],
              //     ),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Colors.teal[700],
              //       foregroundColor: Colors.white,
              //       padding: EdgeInsets.symmetric(vertical: 15),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(5),
              //       ),
              //     ),
              //   ),
              // ),
              Text(
                'We only access your location while you are using this incredible app',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
