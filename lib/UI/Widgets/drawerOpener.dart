import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/profileScreen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SidebarMenuScreen(), // Your existing sidebar screen
    );
  }
}
