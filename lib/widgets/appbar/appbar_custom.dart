import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/appbar/appbar_leading.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget{
  final double height;

  const AppBarCustom({
    super.key,
    this.height = kToolbarHeight});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 5,
      shadowColor: Colors.black87,
      centerTitle: true,
      leading: AppBarLeading(),
      title: Image.asset('assets/images/simpsons-park-logo.png',
        height: kToolbarHeight - 20,),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
