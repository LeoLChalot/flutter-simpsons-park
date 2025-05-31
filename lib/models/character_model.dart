import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id;
  final String firstName;
  final String lastName;
  final String pseudo;
  final String imageUrl;
  final String history;

  Character({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.pseudo,
    required this.imageUrl,
    required this.history,
  });

  factory Character.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Character(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      pseudo: data['pseudo'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      history: data['history'] as String? ?? '',
    );
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      pseudo: json['pseudo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      history: json['history'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'pseudo': pseudo,
      'imageUrl': imageUrl,
      'history': history,
    };
  }
}