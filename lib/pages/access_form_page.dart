import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/drawer/drawer_custom.dart';

import '../widgets/appbar/appbar_custom.dart';
import '../widgets/forms/form_login_widget.dart';
import '../widgets/forms/form_register_widget.dart';

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
  void initState() {
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
              ? FormLoginWidget(onSwitchToRegister: _toggleFormType)
              : FormRegisterWidge(onSwitchToLogin: _toggleFormType),
        ),
      ),
    );
  }
}
