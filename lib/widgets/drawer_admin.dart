import 'package:flutter/material.dart';
import '../utils/routes.dart';

class DrawerAdmin extends StatefulWidget {
  const DrawerAdmin({super.key});

  @override
  State<DrawerAdmin> createState() => _DrawerAdminState();
}

class _DrawerAdminState extends State<DrawerAdmin> {
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
            leading: Icon(Icons.logout),
            title: Text('Déconnexion (Placeholder)'),
            onTap: () {
              Navigator.pushNamed(context, Routes.loading);
              Future.delayed(const Duration(seconds: 2), () {
                if (!mounted) {
                  return;
                }
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, Routes.home);
              });
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
