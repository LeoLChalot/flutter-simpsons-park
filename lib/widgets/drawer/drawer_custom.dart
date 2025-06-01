// drawer_custom.dart
// import 'package:firebase_auth/firebase_auth.dart'; // N'est PLUS NÉCESSAIRE pour la déconnexion Cognito
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // IMPORTER PROVIDER
import 'package:simpsons_park/services/auth_service.dart'; // IMPORTER VOTRE AUTHSERVICE COGNITO
import 'package:simpsons_park/utils/routes.dart';

class DrawerCustom extends StatefulWidget {
  const DrawerCustom({super.key});

  @override
  State<DrawerCustom> createState() => _DrawerCustomState();
}

class _DrawerCustomState extends State<DrawerCustom> {
  final int _delayDuration = 1;

  // DECONNEXION avec AuthService (Cognito)
  Future<void> _signOutCognito() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        Routes.appSimpson,
            (Route<dynamic> route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A la prochaine !'),
          backgroundColor: Colors.green,
        ),
      );
      if (kDebugMode) {
        print('Utilisateur déconnecté via Cognito AuthService');
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
        print('Erreur de déconnexion dans DrawerCustom: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAuthenticated = authService.isAuthenticated; // Utiliser le getter de AuthService
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
                      Navigator.pushNamed(context, Routes.appSimpson);
                    });
                  },
                  leading: const Icon(Icons.home),
                ),
                if (isAuthenticated)
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
                if (isAuthenticated)
                  ListTile(
                    title: const Text('Ajouter Personnage'),
                    leading: const Icon(Icons.person_add),
                    onTap: () {
                      Navigator.pop(context); // Fermer le drawer
                      Navigator.pushNamed(context, Routes.addCharacter);
                    },
                  ),
                if (isAuthenticated)
                  ListTile(
                    title: const Text('Ajouter Épisode'),
                    leading: const Icon(Icons.movie_creation),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.addEpisode);
                    },
                  ),
                if (isAuthenticated)
                  ListTile(
                    title: const Text('Ajouter Journal'),
                    leading: const Icon(Icons.article),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, Routes.addNewspaper);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (!isAuthenticated)
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
          if (isAuthenticated)
            ListTile(
              leading: const Icon(Icons.logout),
              iconColor: Theme.of(context).colorScheme.error,
              textColor: Theme.of(context).colorScheme.error,
              title: const Text('Déconnexion'),
              onTap: () {
                Navigator.pop(context);
                _signOutCognito();
              },
            ),

          if (isAuthenticated)
            SafeArea(
              top: false,
              child: Container(),
            )
        ],
      ),
    );
  }
}