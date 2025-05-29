import 'package:flutter/material.dart';

import '../widgets/login_form_widget.dart';
import '../widgets/register_form_widget.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showLoginForm ? 'Page de Connexion' : 'Page d\'Inscription'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: _showLoginForm
              ? LoginForm(onSwitchToRegister: _toggleFormType)
              : RegisterForm(onSwitchToLogin: _toggleFormType),
        ),
      ),
    );
  }
}
