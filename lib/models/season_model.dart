import 'package:cloud_firestore/cloud_firestore.dart';

class Season {
  final String id;
  final int seasonNumber;
  final int episodeCount;

  Season({
    required this.id,
    required this.seasonNumber,
    required this.episodeCount,
  });

  factory Season.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception("Les données de la saison ${doc.id} sont nulles!");
    }

    return Season(
      id: doc.id,
      seasonNumber: data['seasonNumber'] as int? ?? 0,
      episodeCount: data['episodeCount'] as int? ?? 0,
    );
  }
}