// lib/models/character_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id; // Ajout de l'ID du document
  final String firstName;
  final String lastName;
  final String pseudo;
  final String imageUrl;
  final String history;

  Character({
    required this.id, // Ajout de l'ID ici
    required this.firstName,
    required this.lastName,
    required this.pseudo,
    required this.imageUrl,
    required this.history,
  });

  factory Character.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Character(
      id: doc.id, // On stocke l'ID du document
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      pseudo: data['pseudo'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      history: data['history'] as String? ?? '', // Correction: utiliser data['history']
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
      // 'id': id, // Tu peux l'ajouter si tu en as besoin en écrivant dans Firestore
      'firstName': firstName,
      'lastName': lastName,
      'pseudo': pseudo,
      'imageUrl': imageUrl,
      'history': history,
    };
  }
}