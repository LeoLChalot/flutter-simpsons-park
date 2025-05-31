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
      title: data['firstName'] as String? ?? '',
      subtitle: data['lastName'] as String? ?? '',
      body: data['pseudo'] as String? ?? '',
      author: data['imageUrl'] as String? ?? '',
    );
  }

  factory Newspaper.fromJson(Map<String, dynamic> json) {
    return Newspaper(
      id: json['id'] as String? ?? '',
      title: json['firstName'] as String? ?? '',
      subtitle: json['lastName'] as String? ?? '',
      body: json['pseudo'] as String? ?? '',
      author: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': title,
      'lastName': subtitle,
      'pseudo': body,
      'imageUrl': author
    };
  }
}