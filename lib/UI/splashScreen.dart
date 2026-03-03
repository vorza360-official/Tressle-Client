import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:tressle_app_1/Services/auth_check.dart';
import 'package:tressle_app_1/UI/signupScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    //Navigate to SignUpScreen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthCheck()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar
            // Logo and Title
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 25,
                  children: [
                    // Placeholder for your logo image
                    // Image.asset(
                    //   "assets/images/tressle_logo.png",
                    //   height: 300,
                    //   width: 300,
                    // ),
                    SizedBox(height: 30),
                    AnimatedTextKit(
                      animatedTexts: [
                        FadeAnimatedText(
                          'TRESSLE',
                          textStyle: TextStyle(
                            fontFamily: "Adamina",
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        FadeAnimatedText(
                          'TRESSLE',
                          textStyle: TextStyle(
                            fontFamily: "Adamina",
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        FadeAnimatedText(
                          'TRESSLE',
                          textStyle: TextStyle(
                            fontFamily: "Adamina",
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),

                    // Text(
                    //   'TRESSLE',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.w600,
                    //     letterSpacing: 2,
                    //     fontFamily: "Adamina",
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
