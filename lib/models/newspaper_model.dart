// lib/models/newspaper_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Newspaper {
  final String? id;
  final String title;
  final String subtitle;
  final String body;
  final String? authorEmail;
  final String? authorDisplayName;
  final Timestamp createdAt;

  Newspaper({
    this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    this.authorEmail,
    this.authorDisplayName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'body': body,
      'authorEmail': authorEmail,
      'authorDisplayName': authorDisplayName,
      'createdAt': createdAt,
    };
  }


  factory Newspaper.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Newspaper(
      id: doc.id,
      title: data['title'] as String,
      subtitle: data['subtitle'] as String,
      body: data['body'] as String,
      authorEmail: data['authorEmail'] as String?,
      authorDisplayName: data['authorDisplayName'] as String?,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

}