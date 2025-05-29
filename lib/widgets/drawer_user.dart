import 'package:flutter/material.dart';
import '../utils/routes.dart';

class DrawerUser extends StatefulWidget {
  const DrawerUser({super.key});

  @override
  State<DrawerUser> createState() => _DrawerUserState();
}

class _DrawerUserState extends State<DrawerUser> {
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
                if (!mounted) {
                  return;
                }
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
                if (!mounted) {
                  return;
                }
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, Routes.dashboard);
              });
            },
            leading: const Icon(Icons.dashboard),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Déconnexion (Placeholder)'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Déconnecté !')));
            },
          ),
        ],
      ),
    );
  }
}
