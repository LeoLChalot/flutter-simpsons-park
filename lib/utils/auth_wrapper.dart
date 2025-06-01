// auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:simpsons_park/apps/app_simpson.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/apps/app_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading && authService.cognitoUser == null && authService.session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authService.isAuthenticated) {
      return const AppDashboard();
    } else {
      return const AppSimpson();
    }
  }
}