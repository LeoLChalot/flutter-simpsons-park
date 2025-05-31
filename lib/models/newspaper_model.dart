import 'package:cloud_firestore/cloud_firestore.dart';

class Newspaper {
  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String author;

  Newspaper({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.author
  });

  factory Newspaper.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Newspaper(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subtitle: data['subtitle'] as String? ?? '',
      body: data['body'] as String? ?? '',
      author: data['author'] as String? ?? '',
    );
  }

  factory Newspaper.fromJson(Map<String, dynamic> json) {
    return Newspaper(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      body: json['body'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'author': author
    };
  }
}