import 'package:cloud_firestore/cloud_firestore.dart';

class Season {
  final String id;
  final int seasonNumber;
  final String title;
  final List<Map<String, dynamic>> episodeReferences; // Pour stocker [{episode: Ref, seasonNumber: X}, ...]

  Season({
    required this.id,
    required this.seasonNumber,
    required this.title,
    required this.episodeReferences,
  });

  factory Season.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    // Important: S'assurer que le cast est sûr.
    List<Map<String, dynamic>> refs = [];
    if (data['episodes'] != null) {
      // Firestore retourne List<dynamic>, chaque élément doit être casté en Map<String, dynamic>
      refs = List<Map<String, dynamic>>.from(
          (data['episodes'] as List<dynamic>).map((item) => item as Map<String, dynamic>)
      );
    }

    return Season(
      id: doc.id,
      seasonNumber: data['seasonNumber'] as int,
      title: data['title'] as String? ?? 'Saison ${data['seasonNumber']}',
      episodeReferences: refs, // Stocker les maps contenant les références
    );
  }
}

