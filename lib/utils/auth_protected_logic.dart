import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/apps/app_simpson.dart';
import 'package:simpsons_park/services/auth_service.dart';
import 'package:simpsons_park/apps/app_dashboard.dart';
import 'package:simpsons_park/pages/loading_page.dart';

class AuthProtectedLogic extends StatelessWidget {
  const AuthProtectedLogic({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading) {
      return const LoadingPage();
    }

    // Si l'utilisateur est authentifié
    if (authService.isAuthenticated) {
      return const AppDashboard(); // Accès autorisé à AppDashboard
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) { // Accès refusé
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppSimpson()),
        );
      });
      return LoadingPage();
    }
  }
}