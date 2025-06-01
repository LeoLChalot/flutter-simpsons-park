import 'package:cloud_firestore/cloud_firestore.dart';

class Character {
  final String id;
  final String name;
  final String pseudo;
  final String imageUrl;
  final String description;
  final String function;

  Character({
    required this.id,
    required this.name,
    required this.pseudo,
    required this.imageUrl,
    required this.description,
    required this.function,
  });

  factory Character.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Character(
      id: doc.id,
      name: data['name'] as String? ?? '',
      pseudo: data['pseudo'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      function: data['function'] as String? ?? '',
    );
  }

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      pseudo: json['pseudo'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      function: json['function'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    List<String> initials = [];
    if (name.isNotEmpty) initials.add(name[0].toUpperCase());
    if (pseudo.isNotEmpty) initials.add(pseudo[0].toUpperCase());
    initials = initials.toSet().toList();
    return {
      'name': name,
      'pseudo': pseudo,
      'imageUrl': imageUrl,
      'description': description,
      'function': function,
    };
  }
}