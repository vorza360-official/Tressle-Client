import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:tressle_app_1/UI/resetPasswordScreen.dart';

class DeepLinkHandler {
  static final AppLinks _appLinks = AppLinks();

  static void initDeepLinks(BuildContext context) async {
    // Handle initial link when app starts
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _handleDeepLink(context, uri);
    }

    // Subscribe to incoming links
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(context, uri);
        }
      },
      onError: (error) {
        print('Deep Link Error: $error');
      },
    );
  }

  static void _handleDeepLink(BuildContext context, Uri uri) {
    if (uri.host == 'tree-platform-7ae17.firebaseapp.com' &&
        uri.path == '/reset-password') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SetNewPasswordScreen()),
      );
    }
  }
}
