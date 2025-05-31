import 'package:flutter/material.dart';

class AppBarLeading extends StatefulWidget {
  const AppBarLeading({super.key});

  @override
  State<AppBarLeading> createState() => _AppBarLeadingState();
}

class _AppBarLeadingState extends State<AppBarLeading> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/donut.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        );
      },
    );
  }
}
