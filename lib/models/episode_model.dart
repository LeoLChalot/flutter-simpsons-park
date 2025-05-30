import 'package:simpsons_park/models/character_model.dart';
import 'package:simpsons_park/models/season_model.dart';

class Episode {
  final Season season;
  final int episodeNumber;
  final String title;
  final String synopsis;
  final String code;
  final String duration;
  final DateTime releaseDate;
  final List<Character> characters;
  final String imageUrl;

  Episode({
    required this.season,
    required this.episodeNumber,
    required this.title,
    required this.synopsis,
    required this.code,
    required this.duration,
    required this.releaseDate,
    required this.characters,
    required this.imageUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    final season = Season.fromJson(json['season']);
    final episodeNumber = json['episodeNumber'];
    final title = json['title'];
    final synopsis = json['synopsis'];
    final code = json['code'];
    final duration = json['duration'];
    final releaseDate = DateTime.parse(json['releaseDate']);
    final charactersList = List<Character>.from(
      json['characters'].map((character) => Character.fromJson(character)),
    );

    final imageUrl = json['imageUrl'];

    return Episode(
    season: season,
      episodeNumber: episodeNumber,
      title: title,
      synopsis: synopsis,
      code: code,
      duration: duration,
      releaseDate: releaseDate,
      characters: charactersList,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'episodeNumber': episodeNumber,
      'title': title,
      'synopsis': synopsis,
      'code': code,
      'duration': duration,
      'releaseDate': releaseDate.toIso8601String(),
      'characters': characters.map((character) => character).toList(),
      'imageUrl': imageUrl,
    };
  }
}
