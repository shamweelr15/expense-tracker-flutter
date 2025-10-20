import 'package:expense_calculator/pages/homePage.dart';
import 'package:expense_calculator/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final Widget? pageIfNotConnected;
  const AuthLayout({super.key, this.pageIfNotConnected});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: authService,
      builder: (context, authService, child) {
        return StreamBuilder(
          stream: authService.authStateChanges,
          builder: (context, snapshot) {
            Widget widget;
            if (snapshot.connectionState == ConnectionState.waiting) {
              widget = const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasData) {
              widget = child ?? HomePage();
            } else {
              widget =
                  pageIfNotConnected ??
                  const Scaffold(body: Center(child: Text("Not connected")));
            }
            return widget;
          },
        );
      },
    );
  }
}
