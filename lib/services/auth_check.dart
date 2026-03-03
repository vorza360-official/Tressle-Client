import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/HomeScreen.dart';
import 'package:tressle_app_1/UI/locationDirectionScreen.dart';
import 'package:tressle_app_1/UI/loginScreen.dart';

class AuthCheck extends StatefulWidget {
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  late Stream<User?> _authStream;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Ensure persistence is set
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

      // Add a delay to ensure persistence is loaded
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _authStream = FirebaseAuth.instance.authStateChanges();
        _initialized = true;
      });
    } catch (e) {
      print('Error initializing auth: $e');
      setState(() {
        _initialized = true;
        _authStream = FirebaseAuth.instance.authStateChanges();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          final User? user = snapshot.data;

          // Double-check user is not null
          if (user == null) {
            return LoginScreen();
          }

          // User is logged in - check if first time
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError) {
                print('Firestore error: ${userSnapshot.error}');
                // Try to get user from Firebase Auth directly
                return _buildUserDirect(user);
              }

              if (!userSnapshot.hasData || userSnapshot.data == null) {
                return LoginScreen();
              }

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;

              if (userData == null) {
                return LoginScreen();
              }

              // Check if this is first time opening app
              final hasCompletedOnboarding =
                  userData['hasCompletedOnboarding'] ?? false;

              if (!hasCompletedOnboarding) {
                return LocationScreen();
              } else {
                return MainScreen(index: 0);
              }
            },
          );
        } else {
          return LoginScreen(); // Not logged in
        }
      },
    );
  }

  Widget _buildUserDirect(User user) {
    // If Firestore fails, check auth state directly
    return FutureBuilder<bool>(
      future: _checkUserExists(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          // User exists, go to home
          return MainScreen(index: 0);
        } else {
          return LoginScreen();
        }
      },
    );
  }

  Future<bool> _checkUserExists(String uid) async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      return false;
    }
  }
}
