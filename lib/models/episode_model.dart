import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:simpsons_park/models/character_model.dart';

class Episode {
  final String id;
  final int episodeNumber;
  final int seasonNumber;
  final String title;
  final String imageUrl;
  final String description;
  final String duration;
  final String releaseDate;
  final List<String> charactersRef;

  List<Character>? _loadedCharacters;

  Episode({
    required this.id,
    required this.episodeNumber,
    required this.seasonNumber,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.duration,
    required this.releaseDate,
    required this.charactersRef,
  });

  // Factory pour créer un Episode depuis un DocumentSnapshot Firestore
  factory Episode.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Les données de l'épisode ${doc.id} sont nulles!");
    }
    return Episode(
      id: doc.id, // Utilise l'ID du document Firestore
      episodeNumber: data['episodeNumber'] as int? ?? 0,
      seasonNumber: data['seasonNumber'] as int? ?? 0,
      title: data['title'] as String? ?? 'Titre inconnu',
      imageUrl: data['imageUrl'] as String? ?? '',
      description: data['description'] as String? ?? '',
      duration: data['duration'] as String? ?? 'N/A',
      releaseDate: data['releaseDate'] as String? ?? 'Date inconnue',
      charactersRef: (data['charactersRef'] as List<dynamic>?)
          ?.map((ref) => ref as String)
          .toList() ??
          [],
    );
  }

  // La méthode getCharacters reste la même
  Future<List<Character>> getCharacters(FirebaseFirestore firestoreInstance) async {
    if (_loadedCharacters != null) return _loadedCharacters!;
    _loadedCharacters = [];
    for (String characterId in charactersRef) {
      try {
        DocumentSnapshot<Map<String, dynamic>> charDoc =
        await firestoreInstance.collection('characters').doc(characterId).get();
        if (charDoc.exists && charDoc.data() != null) {
          _loadedCharacters!.add(Character.fromFirestore(charDoc));
        }
      } catch (e) {
        if (kDebugMode) {
          print("Erreur chargement personnage ID $characterId pour épisode $id: $e");
        }
      }
    }
    return _loadedCharacters!;
  }

  Map<String, dynamic> toJson() {
    return {
      'episodeNumber': episodeNumber,
      'seasonNumber': seasonNumber,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
      'duration': duration,
      'releaseDate': releaseDate,
      'charactersRef': charactersRef,
    };
  }
}