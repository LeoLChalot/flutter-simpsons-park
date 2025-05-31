import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/drawer/drawer_custom.dart';
import 'package:simpsons_park/pages/tabs/characters_tab.dart';
import 'package:simpsons_park/pages/tabs/seasons_tab.dart';
import 'package:simpsons_park/widgets/appbar/appbar_custom.dart';

class AppSimpson extends StatefulWidget {
  const AppSimpson({super.key});

  @override
  State<AppSimpson> createState() => _AppSimpsonState();
}

class _AppSimpsonState extends State<AppSimpson> {
  int _selectedIndex = 0;
  String title = 'Simpsons Park 2.0';

  static const List<Widget> _pagesOptions = <Widget>[
    ChatactersTab(),
    SeasonsTab(),
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

          // == Liste des personnages
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Personnages',
          ),

          // == Liste des saisons
          BottomNavigationBarItem(
              icon: Icon(Icons.tv),
              label: 'Saisons'
          ),

        ],

        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[900],
        unselectedItemColor: Colors.amber[500],
        elevation: 15,
        onTap: _onItemTapped,

      ),
    );
  }
}
