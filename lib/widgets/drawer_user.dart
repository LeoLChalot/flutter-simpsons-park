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

  // DECONNEXION
  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // Naviguer vers l'écran de connexion/accueil après déconnexion
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
          ListTile(
            title: const Text('Connexion'),
            onTap: () {
              Navigator.pushNamed(context, Routes.loading);
              Future.delayed(const Duration(seconds: 2), () {
                if (!mounted) return;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, Routes.accessForm);
              });
            },
            leading: const Icon(Icons.login),
          ),
          ListTile(
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, Routes.loading);
              Future.delayed(const Duration(seconds: 2), () {
                if (!mounted) return;
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, Routes.dashboard);
              });
            },
            leading: const Icon(Icons.dashboard),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: _signOut, // Appeler la méthode _signOut
          ),
        ],
      ),
    );
  }
}
