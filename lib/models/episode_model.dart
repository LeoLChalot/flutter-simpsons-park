import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:simpsons_park/models/character_model.dart';

class Episode {
  final String? id;
  final int seasonNumber;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String code;
  final String duration;
  final String releaseDate; // Reste un String
  final String imageUrl;
  final List<DocumentReference> characterReferences;

  List<Character>? _loadedCharacters;

  Episode({
    this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.title,
    required this.synopsis,
    required this.code,
    required this.duration,
    required this.releaseDate, // Attend maintenant une String formatée
    required this.imageUrl,
    required this.characterReferences,
  });

  factory Episode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Les données du document épisode ${doc.id} sont nulles !');
    }

    List<DocumentReference> charRefs = [];
    if (data['characters'] != null && data['characters'] is List) {
      charRefs = (data['characters'] as List<dynamic>)
          .whereType<DocumentReference>()
          .toList();
    }

    return Episode(
      id: doc.id,
      seasonNumber: data['seasonNumber'] as int,
      episodeNumber: data['episodeNumber'] as int,
      title: data['title'] as String,
      synopsis: data['synopsis'] as String,
      code: data['code'] as String,
      duration: data['duration'] as String,
      releaseDate: data['releaseDate'] as String, // Assignation de la String formatée
      imageUrl: data['imageUrl'] as String,
      characterReferences: charRefs,
    );
  }

  Future<List<Character>> getOrLoadCharacters(FirebaseFirestore firestoreInstance) async {
    if (_loadedCharacters != null) {
      return _loadedCharacters!;
    }
    List<Character> characters = [];
    for (DocumentReference ref in characterReferences) {
      try {
        DocumentSnapshot<Map<String, dynamic>> charDoc =
        await ref.get() as DocumentSnapshot<Map<String, dynamic>>;
        if (charDoc.exists && charDoc.data() != null) {
          characters.add(Character.fromFirestore(charDoc));
        } else {
          if (kDebugMode) {
            print('Document personnage non trouvé ou vide: ${ref.path}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erreur de chargement du personnage ${ref.path}: $e");
        }
      }
    }
    _loadedCharacters = characters;
    return characters;
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'title': title,
      'synopsis': synopsis,
      'code': code,
      'duration': duration,
      'releaseDate': releaseDate, // releaseDate est déjà un String au format souhaité
      'imageUrl': imageUrl,
      'characters': characterReferences,
    };
  }
}