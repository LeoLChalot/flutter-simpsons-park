import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/forms/admin/form_newspaper_widget.dart';

class AddNewspaperPage extends StatelessWidget {
  const AddNewspaperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un article'),
        centerTitle: true,
      ),
      body: FormNewspaperWidget(),
    );
  }
}
