import 'package:flutter/material.dart';
import '../pages/tabs/characters_tab.dart';
import '../pages/tabs/episodes_tab.dart';
import '../pages/tabs/seasons_tab.dart';
import '../widgets/appbar_custom.dart';
import '../widgets/drawer_user.dart';

class AppSimpson extends StatefulWidget {
  const AppSimpson({super.key});

  @override
  State<AppSimpson> createState() => _AppSimpsonState();
}

class _AppSimpsonState extends State<AppSimpson> {
  int _selectedIndex = 0;
  String title = 'Simpsons Park 2.0';

  static const List<Widget> _pagesOptions = <Widget>[
    CharactersTab(),
    // EpisodesTab(),
    SeasonsTab(),
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
      drawer: DrawerUser(),
      body: IndexedStack(index: _selectedIndex, children: _pagesOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Personnages',
          ),
          // BottomNavigationBarItem(icon: Icon(Icons.tv), label: 'Episodes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.tv),
              label: 'Saisons'
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.amber[500],
        elevation: 15,
        onTap: _onItemAimed,
      ),
    );
  }
}
