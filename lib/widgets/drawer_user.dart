import 'package:firebase_auth/firebase_auth.dart'; // Importer FirebaseAuth
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/routes.dart';

class DrawerUser extends StatefulWidget {
  const DrawerUser({super.key});

  @override
  State<DrawerUser> createState() => _DrawerUserState();
}

class _DrawerUserState extends State<DrawerUser> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final int _delayDuration = 1;

  // FIREBASE DECONNEXION
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.accessForm,
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez été déconnecté.'),
          backgroundColor: Colors.green,
        ),
      );
      if (kDebugMode) {
        print('Utilisateur déconnecté');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion : ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      if (kDebugMode) {
        print('Erreur de déconnexion: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('User: $_currentUser');
    }
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/drawer.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(child: Text('')),
          ),

          // ============== MENU ==================
          // == ACCUEIL
          ListTile(
            title: const Text('Accueil'),
            onTap: () {
              Navigator.pushNamed(context, Routes.loading);
              Future.delayed(Duration(seconds: _delayDuration), () {
                if (!mounted) return;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, Routes.home);
              });
            },
            leading: const Icon(Icons.home),
          ),
          // == LOGIN
          if (_currentUser == null)
            ListTile(
              title: const Text('Connexion'),
              onTap: () {
                Navigator.pushNamed(context, Routes.loading);
                Future.delayed(Duration(seconds: _delayDuration), () {
                  if (!mounted) return;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.pushNamed(context, Routes.accessForm);
                });
              },
              leading: const Icon(Icons.login),
            ),
          // == DASHBOARD
          if (_currentUser != null)
            ListTile(
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pushNamed(context, Routes.loading);
                Future.delayed(Duration(seconds: _delayDuration), () {
                  if (!mounted) return;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.pushNamed(context, Routes.dashboard);
                });
              },
              leading: const Icon(Icons.dashboard),
            ),
          if (_currentUser != null)
            const Divider(),
            // == LOGOUT
          if (_currentUser != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: _signOut,
            ),

        ],
      ),
    );
  }
}
