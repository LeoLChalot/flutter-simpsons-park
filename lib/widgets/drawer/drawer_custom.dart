import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../utils/routes.dart';

class DrawerCustom extends StatefulWidget {
  const DrawerCustom({super.key});

  @override
  State<DrawerCustom> createState() => _DrawerCustomState();
}

class _DrawerCustomState extends State<DrawerCustom> {
  final int _delayDuration = 1;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // DECONNEXION
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
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        mainAxisSize: MainAxisSize.max,
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ============== MENU ==================
                // == ACCUEIL
                ListTile(
                  title: const Text('Accueil'),
                  onTap: () {
                    Navigator.pushNamed(context, Routes.loading);
                    Future.delayed(Duration(seconds: _delayDuration), () {
                      if (!context.mounted) return;
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                      Navigator.pushNamed(context, Routes.home);
                    });
                  },
                  leading: const Icon(Icons.home),
                ),
                if(_currentUser != null) // If user => DASHBOARD link
                  ListTile(
                    title: const Text('Dashboard'),
                    onTap: () {
                      Navigator.pushNamed(context, Routes.loading);
                      Future.delayed(Duration(seconds: _delayDuration), () {
                        if (!context.mounted) return;
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                        Navigator.pushNamed(context, Routes.dashboard);
                      });
                    },
                    leading: const Icon(Icons.dashboard),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_currentUser == null) // If !user => LOGIN link
            ListTile(
              title: const Text('Connexion'),
              onTap: () {
                Navigator.pushNamed(context, Routes.loading);
                Future.delayed(Duration(seconds: _delayDuration), () {
                  if (!context.mounted) return;
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                  Navigator.pushNamed(context, Routes.accessForm);
                });
              },
              leading: const Icon(Icons.login),
            ),
          if (_currentUser != null) // If user => LOGOUT link
            ListTile(
              leading: const Icon(Icons.logout),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              title: const Text('Déconnexion'),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          if (_currentUser != null) // If user => Use SafeArea
            SafeArea(
              top: false,
              child: Container(),
            )
        ]
      )
    );
  }
}
