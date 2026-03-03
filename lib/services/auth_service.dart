import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  // Get current user
  User? get currentUser => _auth.currentUser;
  // Future<void> initialize() async {
  //   // This ensures Firebase Auth persistence is properly set up
  //   await Firebase.initializeApp();

  //   // Set persistence to LOCAL (default, but explicit is better)
  //   await _auth.setPersistence(Persistence.LOCAL);

  //   // Listen for auth state changes
  //   setupEmailVerificationListener();
  // }

  // Get current user ID (UUID)
  String? get currentUserId => _auth.currentUser?.uid;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign in cancelled'};
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;
      if (user == null) {
        return {'success': false, 'message': 'Google sign in failed'};
      }

      // Check if user already exists in Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        // Existing user - return their data
        return {
          'success': true,
          'message': 'Google sign in successful',
          'uid': user.uid,
          'userData': userDoc.data(),
          'isNewUser': false,
        };
      } else {
        // New user - create Firestore document with userType 'client'
        final userData = {
          'uid': user.uid,
          'email': user.email,
          'fullName': user.displayName ?? '',
          'profilePicture': user.photoURL ?? '',
          'emailVerified': true,
          'phoneVerified': false,
          'phoneNumber': '',
          'countryCode': '',
          'countryName': '',
          'authProvider': 'google',
          'profileComplete': false,
          'userType': 'client',
          'hasCompletedOnboarding': false, // 👈 Add this
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await _firestore.collection('users').doc(user.uid).set(userData);

        return {
          'success': true,
          'message': 'Google sign in successful',
          'uid': user.uid,
          'userData': userData,
          'isNewUser': true,
          'needsProfileCompletion': true, // Needs phone verification
        };
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message = 'Account already exists with different credential';
          break;
        case 'invalid-credential':
          message = 'Invalid Google credential';
          break;
        case 'operation-not-allowed':
          message = 'Google sign in is not enabled';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'user-not-found':
          message = 'No account found';
          break;
        default:
          message = 'Google sign in failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Google sign in failed: $e'};
    }
  }

  // Complete Google user profile (add phone number)
  Future<Map<String, dynamic>> completeGoogleUserProfile({
    required String uid,
    required String phoneNumber,
    required String countryCode,
    required String countryName,
  }) async {
    try {
      // Update the user document in Firestore
      await _firestore.collection('users').doc(uid).update({
        'phoneNumber': phoneNumber,
        'countryCode': countryCode,
        'countryName': countryName,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {'success': true, 'message': 'Profile completed successfully'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to complete profile: $e'};
    }
  }

  // Check if email is valid format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Check if email exists in Firebase Auth
  Future<bool> checkEmailExists(String email) async {
    try {
      // Query Firestore to check if email exists
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .where('userType', isEqualTo: 'client')
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  // Validate phone number format
  bool isValidPhoneNumber(String phone, String countryCode) {
    // Remove spaces and special characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Basic validation - should have at least 7 digits
    return cleanPhone.length >= 7 && cleanPhone.length <= 15;
  }

  // Create user account with email and password
  Future<Map<String, dynamic>> createUserWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String countryCode,
    required String countryName,
  }) async {
    try {
      // Validate email format
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      // Check if email already exists
      bool emailExists = await checkEmailExists(email);
      if (emailExists) {
        return {'success': false, 'message': 'Email already registered'};
      }

      // Validate password length
      if (password.length < 8) {
        return {
          'success': false,
          'message': 'Password must be at least 8 characters',
        };
      }

      // Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      // Prepare full phone number
      String fullPhoneNumber = '$countryCode$phoneNumber';

      // Store user data in Firestore with userType 'client'
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'phoneNumber': fullPhoneNumber,
        'countryCode': countryCode,
        'countryName': countryName,
        'emailVerified': false,
        'phoneVerified': false,
        'authProvider': 'email',
        'profilePicture': '',
        'userType': 'client',
        'hasCompletedOnboarding': false, // 👈 Add this
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send email verification
      await sendEmailVerification();

      return {
        'success': true,
        'message': 'Verification Link sent to Email',
        'uid': uid,
        'needsEmailVerification': true,
        'needsPhoneVerification': true,
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        default:
          message = 'Registration failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  // Send email verification
  Future<Map<String, dynamic>> sendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      if (user.emailVerified) {
        return {'success': false, 'message': 'Email already verified'};
      }

      await user.sendEmailVerification();

      return {'success': true, 'message': 'Verification email sent'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send verification email: $e',
      };
    }
  }

  // Check if email is verified
  Future<bool> checkEmailVerified() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      await user.reload();
      user = _auth.currentUser;

      if (user?.emailVerified == true) {
        // Update Firestore
        await _firestore.collection('users').doc(user!.uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  // Send phone OTP
  Future<Map<String, dynamic>> sendPhoneOTP(String phoneNumber) async {
    try {
      print('🔵 Starting phone verification for: $phoneNumber');

      // Ensure phone number has country code
      if (!phoneNumber.startsWith('+')) {
        print('❌ Phone number missing country code');
        return {
          'success': false,
          'message': 'Phone number must include country code (e.g., +92...)',
        };
      }

      // Use a Completer to handle async callbacks
      bool otpSent = false;
      String? errorMessage;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            print('✅ Auto-verification completed');
            // Auto-verification (Android only)
            await _auth.currentUser?.updatePhoneNumber(credential);
            await _firestore
                .collection('users')
                .doc(_auth.currentUser?.uid)
                .update({
                  'phoneVerified': true,
                  'phoneNumber': phoneNumber,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
            print('✅ Phone auto-verified successfully');
          } catch (e) {
            print('❌ Auto-verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          errorMessage = e.message;
          print('❌ Phone verification FAILED:');
          print('   Error Code: ${e.code}');
          print('   Error Message: ${e.message}');
          print('   Full Error: $e');

          // Provide more specific error messages
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'The phone number format is invalid';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many attempts. Please try again later';
          } else if (e.code == 'web-context-cancelled') {
            errorMessage = 'Request cancelled. Please try again';
          } else if (e.message!.contains('Invalid app info') ||
              e.message!.contains('play_integrity_token')) {
            errorMessage =
                'App configuration error. SHA certificates may need time to propagate (wait 5-10 minutes)';
          } else if (e.message!.contains('not authorized')) {
            errorMessage =
                'Phone authentication not enabled in Firebase Console';
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          otpSent = true;
          print('✅ OTP CODE SENT SUCCESSFULLY');
          print('   Verification ID: $verificationId');
          print('   Resend Token: $resendToken');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          print('⏱️ Auto retrieval timeout - user needs to enter OTP manually');
        },
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );

      // Wait a bit for callbacks
      await Future.delayed(const Duration(seconds: 2));

      if (errorMessage != null) {
        return {'success': false, 'message': errorMessage};
      }

      if (otpSent || _verificationId != null) {
        print('✅ Returning success response');
        return {
          'success': true,
          'message': 'OTP sent to $phoneNumber',
          'verificationId': _verificationId,
        };
      }

      print('❌ No error but OTP not sent');
      return {
        'success': false,
        'message': 'Failed to send OTP. Please try again',
      };
    } catch (e) {
      print('💥 EXCEPTION in sendPhoneOTP: $e');
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> verifyPhoneOTP(String otp) async {
    try {
      if (_verificationId == null || _verificationId!.isEmpty) {
        return {
          'success': false,
          'message': 'No verification in progress. Please request OTP again',
        };
      }

      if (otp.length != 6) {
        return {'success': false, 'message': 'OTP must be 6 digits'};
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Link phone credential to current user
      if (_auth.currentUser != null) {
        await _auth.currentUser!.updatePhoneNumber(credential);

        // Update Firestore
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({
              'phoneVerified': true,
              'phoneNumber': _auth.currentUser!.phoneNumber,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        return {
          'success': true,
          'message': 'Phone verified successfully',
          'user': _auth.currentUser,
        };
      } else {
        // Sign in with phone credential if no user is logged in
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        return {
          'success': true,
          'message': 'Phone verified and signed in successfully',
          'user': userCredential.user,
        };
      }
    } on FirebaseAuthException catch (e) {
      print('verifyPhoneOTP error: ${e.code} - ${e.message}');

      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP code. Please check and try again';
          break;
        case 'session-expired':
          message = 'OTP expired. Please request a new one';
          break;
        case 'provider-already-linked':
          message = 'Phone number already linked to this account';
          break;
        case 'credential-already-in-use':
          message = 'This phone number is already in use';
          break;
        default:
          message = 'Verification failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      print('verifyPhoneOTP unexpected error: $e');
      return {
        'success': false,
        'message': 'Verification failed: ${e.toString()}',
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    return await sendPhoneOTP(phoneNumber);
  }

  // Clear verification state
  void clearVerification() {
    _verificationId = null;
    _resendToken = null;
  }

  // Login with email and password
  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Reload user to get latest emailVerified status
      await userCredential.user?.reload();
      User? user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Please verify your email before logging in',
        };
      }

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      return {
        'success': true,
        'message': 'Login successful',
        'uid': userCredential.user!.uid,
        'userData': userDoc.data(),
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Login with phone and OTP (Step 1: Send OTP)
  Future<Map<String, dynamic>> sendLoginOTP(String phoneNumber) async {
    try {
      if (!phoneNumber.startsWith('+')) {
        return {
          'success': false,
          'message': 'Phone number must include country code',
        };
      }

      // Check if phone exists in database
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (query.docs.isEmpty) {
        return {
          'success': false,
          'message': 'No account found with this phone number',
        };
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto sign-in
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Phone verification failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );

      return {'success': true, 'message': 'OTP sent to phone'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: $e'};
    }
  }

  // Login with phone and OTP (Step 2: Verify OTP)
  Future<Map<String, dynamic>> loginWithPhoneOTP(String otp) async {
    try {
      if (_verificationId == null) {
        return {'success': false, 'message': 'No verification in progress'};
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      return {
        'success': true,
        'message': 'Login successful',
        'uid': userCredential.user!.uid,
        'userData': userDoc.data(),
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-verification-code':
          message = 'Invalid OTP code';
          break;
        case 'session-expired':
          message = 'OTP expired. Please request a new one';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _verificationId = null;
    _resendToken = null;
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error updating user data: $e');
      return false;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Password reset email sent'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send reset email: $e'};
    }
  }

  void setupEmailVerificationListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Reload user to get latest email verification status
        await user.reload();
        user = _auth.currentUser;

        if (user?.emailVerified == true) {
          // Update Firestore
          await _firestore.collection('users').doc(user!.uid).update({
            'emailVerified': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          print('Email verification status updated in Firestore');
        }
      }
    });
  }

  // Call this when your app starts (in main.dart or initState)
  void initializeAuthListener() {
    setupEmailVerificationListener();
  }
}
