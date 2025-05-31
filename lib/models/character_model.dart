import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id;
  final String firstName;
  final String lastName;
  final String pseudo;
  final String imageUrl;
  final String history;
  final List<String> searchInitials;

  Character({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.pseudo,
    required this.imageUrl,
    required this.history,
    required this.searchInitials,
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
      searchInitials: List<String>.from(data['searchInitials'] as List<dynamic>? ?? []),
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
      searchInitials: List<String>.from(json['searchInitials'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    List<String> initials = [];
    if (firstName.isNotEmpty) initials.add(firstName[0].toUpperCase());
    if (lastName.isNotEmpty) initials.add(lastName[0].toUpperCase());
    if (pseudo.isNotEmpty) initials.add(pseudo[0].toUpperCase());
    initials = initials.toSet().toList();
    return {
      'firstName': firstName,
      'lastName': lastName,
      'pseudo': pseudo,
      'imageUrl': imageUrl,
      'history': history,
      'searchInitials': initials.isNotEmpty ? initials : null,
    };
  }
}