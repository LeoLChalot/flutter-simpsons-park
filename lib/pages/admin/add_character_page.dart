import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/forms/admin/form_newspaper_widget.dart';

class AddCharacterPage extends StatelessWidget {
  const AddCharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un personnage'),
        centerTitle: true,
      ),
      body: Center(child:const Text("AddCharacterPage")),
    );
  }
}
