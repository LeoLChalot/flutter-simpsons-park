import 'package:flutter/material.dart';

import '../pages/tabs/admin/add_character_tab.dart';
import '../pages/tabs/admin/add_episode_tab.dart';
import '../pages/tabs/admin/add_season_tab.dart';
import '../pages/tabs/admin/profile_tab.dart';
import '../widgets/appbar_custom.dart';
import '../widgets/drawer_admin.dart';

class AppDashboard extends StatefulWidget {
  const AppDashboard({super.key});

  @override
  State<AppDashboard> createState() => _AppDashboardState();
}

class _AppDashboardState extends State<AppDashboard> {
  int _selectedIndex = 0;
  String title = 'Simpsons Park 2.0 ADMIN';

  static const List<Widget> _pagesOptions = <Widget>[
    AddCharacterTab(),
    AddEpisodeTab(),
    AddSeasonTab(),
    ProfileTab(),
  ];

  void _onItemAimed(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarCustom(title: title),
      drawer: DrawerAdmin(),
      body: IndexedStack(index: _selectedIndex, children: _pagesOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '+ Personnage',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: '+ Episode'),
          BottomNavigationBarItem(icon: Icon(Icons.tv), label: '+ Saison'),
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
        onTap: _onItemAimed,
      ),
    );
  }
}
