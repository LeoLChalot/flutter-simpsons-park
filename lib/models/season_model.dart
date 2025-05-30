import 'package:simpsons_park/models/episode_model.dart';

class Season {
  final int seasonNumber;
  final List<Episode> episodes;

  Season({required this.seasonNumber, required this.episodes});

  factory Season.fromJson(Map<String, dynamic> json) {
    final seasonNumber = json['seasonNumber'];
    final episodesList = List<Episode>.from(
      json['episodes'].map((episode) => Episode.fromJson(episode)),
    );

    return Season(seasonNumber: seasonNumber, episodes: episodesList);
  }

  Map<String, dynamic> toJson() {
    return {
      'seasonNumber': seasonNumber,
      'episodes': episodes.map((episode) => episode.toJson()).toList(),
    };
  }
}
