// access_form_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:simpsons_park/services/auth_service.dart'; // Import your AuthService
import 'package:simpsons_park/widgets/forms/form_login_widget.dart';
import 'package:simpsons_park/widgets/forms/form_register_widget.dart';
// Import your confirmation page if you have one

import 'confirmation_page.dart';


class AccessFormPage extends StatefulWidget {
  const AccessFormPage({super.key});

  @override
  State<AccessFormPage> createState() => _AccessFormPageState();
}

class _AccessFormPageState extends State<AccessFormPage> {
  bool _showLoginForm = true;

  void _toggleFormType() {
    setState(() {
      _showLoginForm = !_showLoginForm;
      // Clear any previous error messages from the auth service when switching forms
      Provider.of<AuthService>(context, listen: false).clearErrorMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    // You can listen to specific parts of AuthService if needed here,
    // e.g., for a global loading indicator or error message area for this page.
    // final authService = Provider.of<AuthService>(context);

    return Scaffold(
      // appBar: AppBarCustom(titleText: _showLoginForm ? 'Login' : 'Register'),
      // drawer: DrawerCustom(), // If needed on this page
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _showLoginForm
                ? FormLoginWidget(
              key: const ValueKey('loginForm'), //Key for AnimatedSwitcher
              onSwitchToRegister: _toggleFormType,
            )
                : FormRegisterWidget(
              key: const ValueKey('registerForm'), // Key for AnimatedSwitcher
              onSwitchToLogin: _toggleFormType,
              // If registration leads to a confirmation step:
              onRegistrationSuccessNeedsConfirmation: (email) {
                // Navigate to a confirmation page or show a message
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfirmAccountPage(email: email),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
