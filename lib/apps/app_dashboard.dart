import 'package:flutter/material.dart';
import 'package:simpsons_park/pages/tabs/admin/news_tab.dart';
import '../pages/tabs/admin/dashboard_overview_tab.dart';
import '../pages/tabs/admin/profile_tab.dart';
import '../widgets/appbar/appbar_custom.dart';
import '../widgets/drawer/drawer_custom.dart';

class AppDashboard extends StatefulWidget {
  const AppDashboard({super.key});

  @override
  State<AppDashboard> createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard> {
  int _selectedIndex = 0;
  String title = 'Simpsons Park 2.0 ADMIN';

  static const List<Widget> _pagesOptions = <Widget>[
    DashboardOverviewTab(),
    NewsTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(),
      drawer: DrawerCustom(),
      body: IndexedStack(index: _selectedIndex, children: _pagesOptions),
      bottomNavigationBar: BottomNavigationBar(

        items: const <BottomNavigationBarItem>[

          // == Résumé des données enregistrées
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Résumé'),

          // == Listes des articles
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'News'),

          // == Profile de l'utilisateur connecté
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user),
            label: 'Profil',
          ),

        ],

        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.amber[500],
        elevation: 15,
        onTap: _onItemTapped,
      ),
    );
  }
}
