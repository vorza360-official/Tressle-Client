import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tressle_app_1/UI/paymentMethodSelectionScreen.dart';
import 'package:tressle_app_1/UI/loginScreen.dart';
import 'package:tressle_app_1/UI/profileScreen.dart';

class TressleSideBar extends StatefulWidget {
  final Function(int) onTabSelected;

  const TressleSideBar({Key? key, required this.onTabSelected})
    : super(key: key);

  @override
  State<TressleSideBar> createState() => _TressleSideBarState();
}

class _TressleSideBarState extends State<TressleSideBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userImage = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          setState(() {
            userName =
                userData['fullName'] ??
                userData['name'] ??
                user.displayName ??
                'User';
            userEmail = userData['email'] ?? user.email ?? '';
            userPhone = userData['phoneNumber'] ?? userData['phone'] ?? '';
            userImage =
                userData['profilePicture'] ??
                userData['profileImage'] ??
                user.photoURL ??
                '';
            isLoading = false;
          });
        } else {
          setState(() {
            userName = user.displayName ?? 'User';
            userEmail = user.email ?? '';
            userPhone = user.phoneNumber ?? '';
            userImage = user.photoURL ?? '';
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        setState(() => isLoading = false);
      }
    } else {
      print('No user logged in');
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        await _auth.signOut();

        if (mounted) Navigator.pop(context);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Helper method to handle drawer item tap
  void _handleDrawerItemTap(int tabIndex) {
    Navigator.pop(context); // Close the drawer
    widget.onTabSelected(tabIndex); // Then switch to the selected tab
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                image: userImage.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(userImage),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: userImage.isEmpty
                                  ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.grey[600],
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () async {
                                  Navigator.pop(context); // Close drawer
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.teal[700],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userPhone.isNotEmpty
                                    ? userPhone
                                    : 'No phone number',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        _buildMenuItem(
                          icon:
                              "assets/icons/bottomNav/nav_home_filled_icon.png",
                          title: 'Home',
                          onTap: () => _handleDrawerItemTap(0),
                        ),
                        _buildMenuItem(
                          icon:
                              "assets/icons/bottomNav/nav_search_filled_icon.png",
                          title: 'Search',
                          onTap: () => _handleDrawerItemTap(1),
                        ),
                        _buildMenuItem(
                          icon:
                              "assets/icons/bottomNav/nav_calender_filled_icon.png",
                          title: 'My Appointment',
                          onTap: () => _handleDrawerItemTap(2),
                        ),
                        _buildMenuItem(
                          icon:
                              "assets/icons/bottomNav/nav_notification_filled_icon.png",
                          title: 'Notification',
                          onTap: () => _handleDrawerItemTap(3),
                        ),
                        _buildMenuItem(
                          icon: "assets/icons/payment_icon.png",
                          title: 'Payments',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentMethods2(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon:
                              "assets/icons/bottomNav/nav_profile_filled_icon.png",
                          title: 'Profile',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                        _buildMenuItem(
                          icon: "assets/icons/customer_care_icon.png",
                          title: 'Customer Support',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            // Navigate to Customer Support
                          },
                        ),
                        _buildMenuItem(
                          icon: "assets/icons/blog_icon.png",
                          title: 'Blogs',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            // Navigate to Blogs
                          },
                        ),
                        _buildMenuItem(
                          icon: "assets/icons/privacy_icon.png",
                          title: 'Terms & Condition',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            // Navigate to Terms
                          },
                        ),
                        _buildMenuItem(
                          icon: "assets/icons/security_icon.png",
                          title: 'Privacy Policy',
                          onTap: () {
                            Navigator.pop(context); // Close drawer
                            // Navigate to Privacy Policy
                          },
                        ),

                        // Logout Option
                        const Divider(height: 32, thickness: 1),
                        ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.teal,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          onTap: _handleLogout,
                        ),
                        Container(
                          margin: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context); // Close drawer
                                // Handle business setup
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[700],
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business_center_outlined,
                                    size: 30,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Set Up My Business',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Image.asset(
        icon,
        width: 25,
        height: 25,
        color: Colors.teal.shade700,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
          fontWeight: FontWeight.w400,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
