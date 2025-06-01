import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:simpsons_park/models/character_model.dart';

class Episode {
  final String id;
  final int episodeNumber;
  final String title;
  final String imageUrl;
  final String description;
  final String duration;
  final String releaseDate;
  final Map<String, String> charactersList;

  List<Character>? _loadedCharacters;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.duration,
    required this.releaseDate,
    required this.charactersList,
  });

  factory Episode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Les données de l'épisode ${doc.id} sont nulles!");
    }

    Map<String, String> parsedCharactersList = {};
    if (data['charactersList'] != null && data['charactersList'] is Map) {
      (data['charactersList'] as Map<dynamic, dynamic>).forEach((key, value) {
        if (key is String && value is String) {
          parsedCharactersList[key] = value;
        }
      });
    }

    return Episode(
      id: doc.id,
      episodeNumber: data['episodeNumber'] as int? ?? 0,
      title: data['title'] as String? ?? 'Titre inconnu',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? 'Aucune description disponible.',
      duration: data['duration'] as String? ?? 'N/A',
      releaseDate: data['releaseDate'] as String? ?? 'Date inconnue',
      charactersList: parsedCharactersList,
    );
  }

  Future<List<Character>> getOrLoadCharacters(FirebaseFirestore firestoreInstance) async {
    if (_loadedCharacters != null) {
      return _loadedCharacters!;
    }
    List<Character> characters = [];
    // Les clés de charactersList sont les IDs des personnages
    for (String characterId in charactersList.keys) {
      try {
        DocumentSnapshot<Map<String, dynamic>> charDoc =
        await firestoreInstance.collection('characters').doc(characterId).get();
        if (charDoc.exists && charDoc.data() != null) {
          characters.add(Character.fromFirestore(charDoc));
        } else {
          if (kDebugMode) {
            print('Document personnage non trouvé pour ID (depuis charactersList): $characterId');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erreur de chargement du personnage ID $characterId: $e");
        }
      }
    }
    _loadedCharacters = characters;
    return characters;
  }

  // toJson si besoin
  Map<String, dynamic> toJson() {
    return {
      'episodeNumber': episodeNumber,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'duration': duration,
      'releaseDate': releaseDate,
      'charactersList': charactersList,
    };
  }
}