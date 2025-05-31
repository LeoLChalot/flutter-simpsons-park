import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/drawer_custom.dart';
import 'package:simpsons_park/widgets/drawer_user.dart';

import '../widgets/appbar_custom.dart';
import '../widgets/login_form_widget.dart';
import '../widgets/register_form_widget.dart';

class AccessFormPage extends StatefulWidget {
  const AccessFormPage({super.key});

  @override
  State<AccessFormPage> createState() => _AccessFormPageState();
}

class _AccessFormPageState extends State<AccessFormPage> {
  bool _showLoginForm = true;
  late String _title;


    void _toggleFormType() {
    setState(() {
      _showLoginForm = !_showLoginForm;
      _title = _showLoginForm ? 'Page de Connexion' : 'Page d\'Inscription';
    });
  }

  @override
  void initState() {
    _title = 'Page de Connexion';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(),
      drawer: DrawerCustom(),
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
