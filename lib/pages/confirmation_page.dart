// pages/auth/confirm_account_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart';

class ConfirmAccountPage extends StatefulWidget {
  final String email;

  const ConfirmAccountPage({super.key, required this.email});

  @override
  State<ConfirmAccountPage> createState() => _ConfirmAccountPageState();
}

class _ConfirmAccountPageState extends State<ConfirmAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _confirmationCodeController = TextEditingController();

  @override
  void dispose() {
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmUserAccount() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.confirmSignUp(
        widget.email, // Use the email passed to the page
        _confirmationCodeController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account confirmed successfully! Please login."), backgroundColor: Colors.green),
        );
        // Navigate back to the login form, potentially clearing navigation stack
        Navigator.popUntil(context, (route) => route.isFirst); // Go back to the initial route (usually AccessFormPage or AuthWrapper)
        // Or specific navigation if AccessFormPage is not the first route:
        // Navigator.of(context).pop(); // Just pop this page
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ?? "Confirmation failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'A confirmation code has been sent to ${widget.email}. Please enter it below.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _confirmationCodeController,
                  decoration: const InputDecoration(labelText: 'Confirmation Code', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the confirmation code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (authService.errorMessage != null && !authService.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom:10.0),
                    child: Text(
                      authService.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: authService.isLoading ? null : _confirmUserAccount,
                  child: authService.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : const Text('Confirm Account'),
                ),
                // Optionally add a resend code button here
              ],
            ),
          ),
        ),
      ),
    );
  }
}