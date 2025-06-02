import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart';

import 'package:simpsons_park/utils/routes.dart';

class FormLoginWidget extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const FormLoginWidget({
    super.key,
    required this.onSwitchToRegister,
  });

  @override
  State<FormLoginWidget> createState() => _FormLoginWidgetState();
}

class _FormLoginWidgetState extends State<FormLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.errorMessage ?? "Connexion échouée, veuillez réessayer."),
            backgroundColor: Colors.red,
          ),
        );
      }
      if(!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.appSimpson,
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Connexion', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty || !value.contains('@')) {
                  return 'Veuillez entrer une adresse e-mail valide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un mot de passe';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (authService.errorMessage != null && !authService.isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  authService.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: authService.isLoading ? null : _loginUser,
              child: authService.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Text('Email'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onSwitchToRegister,
              child: const Text('Pas encore inscrit ? Inscription'),
            ),
          ],
        ),
      ),
    );
  }
}