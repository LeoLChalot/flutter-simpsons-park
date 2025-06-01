import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:simpsons_park/pages/tabs/admin/dashboard_overview_tab.dart';
import 'package:simpsons_park/pages/tabs/admin/profile_tab.dart';
import 'package:simpsons_park/widgets/appbar/appbar_custom.dart';
import 'package:simpsons_park/widgets/drawer/drawer_custom.dart';

import 'package:simpsons_park/utils/routes.dart';

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
    ProfileTab(),
  ];
  static const List<BottomNavigationBarItem>
  _bottomNavigationBarItems = <BottomNavigationBarItem>[
    // == Résumé des données enregistrées
    BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Résumé'),
    // == Profile de l'utilisateur connecté
    BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: 'Profil'),
  ];

  void _handleSpeedDialAction(String actionType) {
    switch (actionType) {
      case 'add_character':
        Navigator.pushNamed(context, Routes.addCharacter);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action: Ajouter Personnage')),
        );
        break;
      case 'add_episode':
        Navigator.pushNamed(context, Routes.addEpisode);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action: Ajouter Épisode')),
        );
        break;
      case 'add_newspaper': // Correspond à "Article" dans le SpeedDial
        Navigator.pushNamed(context, Routes.addNewspaper);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action: Ajouter Article (à implémenter)'),
          ),
        );
        break;
    }
  }

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
        items: _bottomNavigationBarItems,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.amber[500],
        elevation: 15,
        onTap: _onItemTapped,
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        buttonSize: const Size(56.0, 56.0),
        visible: true,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        tooltip: 'Ajouter',
        heroTag: 'admin-speed-dial',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          // AJOUT CHARACTER
          SpeedDialChild(
            child: const Icon(Icons.person_add_alt_1),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
            label: 'Personnage',
            labelStyle: const TextStyle(fontSize: 16.0),
            onTap: () => _handleSpeedDialAction('add_character'),
          ),
          // AJOUT EPISODE
          SpeedDialChild(
            child: const Icon(Icons.movie_filter_outlined),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
            label: 'Épisode',
            labelStyle: const TextStyle(fontSize: 16.0),
            onTap: () => _handleSpeedDialAction('add_episode'),
          ),
          // AJOUT ARTICLE
          SpeedDialChild(
            child: const Icon(Icons.article_outlined),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            label: 'Article',
            labelStyle: const TextStyle(fontSize: 16.0),
            onTap: () => _handleSpeedDialAction('add_newspaper'),
          ),

          // SpeedDialChild(
          //   child: const Icon(Icons.video_library_outlined),
          //   backgroundColor: Colors.blueAccent,
          //   foregroundColor: Colors.white,
          //   label: 'Saison',
          //   labelStyle: const TextStyle(fontSize: 16.0),
          //   onTap: () => _handleSpeedDialAction('add_season'),
          // ),
        ],
      ),
    );
  }
}
