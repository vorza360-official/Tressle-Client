import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tressle_app_1/services/auth_check.dart';
import 'package:tressle_app_1/services/auth_service.dart';
import 'package:tressle_app_1/ui/splashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //await AuthService().initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'TRESSLE',
      theme: ThemeData(
        textTheme: GoogleFonts.manropeTextTheme(),
        primarySwatch: Colors.teal,
        //fontFamily: 'Adamina',
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
