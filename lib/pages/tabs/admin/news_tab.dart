import 'package:flutter/material.dart';
import 'package:simpsons_park/widgets/forms/admin/form_newspaper_widget.dart';

class NewsTab extends StatefulWidget {
  const NewsTab({super.key});

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FormNewspaperWidget(),
    );
  }
}
