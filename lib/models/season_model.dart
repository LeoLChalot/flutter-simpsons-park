// lib/models/season_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Season {
  final String id;
  final String name;
  final int seasonNumber;
  final int episodesCount;

  Season({
    required this.id,
    required this.name,
    required this.seasonNumber,
    required this.episodesCount,
  });

  factory Season.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Les données de la saison ${doc.id} sont nulles!");
    }

    return Season(
      id: doc.id,
      name: data['name'] as String? ?? 'Saison Inconnue', // Champ "name" de ta capture
      seasonNumber: data['seasonNumber'] as int? ?? 0,   // Si tu as aussi un champ "seasonNumber" pour le tri
      episodesCount: data['episodesCount'] as int? ?? 0,
    );
  }
}