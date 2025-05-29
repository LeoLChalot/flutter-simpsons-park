import 'package:flutter/material.dart';

import 'appbar_leading.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget{
  final String title;
  final double height;

  const AppBarCustom({
    super.key,
    required this.title,
    this.height = kToolbarHeight});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 12,
      centerTitle: true,
      leading: AppBarLeading(),
      title: Text(title),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
