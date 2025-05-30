import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simpsons_park/pages/access_form_page.dart';

import '../apps/app_simpson.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Une erreur est survenue : ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return AppSimpson();
        } else {
          // Redirection si l'utilisateur n'est pas connecté
          return const AccessFormPage();
        }
      },
    );
  }
}

