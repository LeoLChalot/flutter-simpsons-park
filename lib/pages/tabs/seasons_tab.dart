// lib/pages/tabs/seasons_tab.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/season_model.dart';
import 'package:simpsons_park/models/episode_model.dart';
import 'episode_detail_page.dart';

class SeasonsTab extends StatefulWidget {
  const SeasonsTab({super.key});

  @override
  State<SeasonsTab> createState() => _SeasonsTabState();
}

class _SeasonsTabState extends State<SeasonsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('seasons')
          .orderBy('seasonNumber')
          .snapshots(),
      builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> seasonSnapshot,
          ) {
        if (seasonSnapshot.hasError) {
          if (kDebugMode) {
            print("Erreur Firestore (SeasonsTab - Saisons): ${seasonSnapshot.error}");
          }
          return const Center(
            child: Text('Quelque chose s\'est mal passé avec les saisons.'),
          );
        }

        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!seasonSnapshot.hasData || seasonSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune saison trouvée.'));
        }

        final List<Season> seasons = seasonSnapshot.data!.docs.map((doc) {
          try {
            return Season.fromFirestore(doc);
          } catch (e) {
            if (kDebugMode) {
              print("Error creating Season from Firestore doc ${doc.id}: $e");
            }
            return Season(
              id: doc.id,
              seasonNumber: 0,
              episodeCount: 0,
            );
          }
        }).toList();

        return ListView.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final Season season = seasons[index];

            return ExpansionTile(
              key: PageStorageKey<String>(season.id),
              title: Text(
                'Saison ${season.seasonNumber} - ${season.episodeCount} épisodes',
              ),
              children: <Widget>[
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('seasons')
                      .doc(season.id)
                      .collection('episodes')
                      .orderBy('episodeNumber')
                      .snapshots(),
                  builder: (
                      BuildContext context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> episodeSnapshot,
                      ) {
                    if (episodeSnapshot.hasError) {
                      if (kDebugMode) {
                        print("Erreur Firestore (SeasonsTab - Episodes pour ${season.id}): ${episodeSnapshot.error}");
                      }
                      return const ListTile(title: Text('Erreur de chargement des épisodes.'));
                    }

                    if (episodeSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }

                    if (!episodeSnapshot.hasData || episodeSnapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                        child: Center(
                          child: Text('Aucun épisode trouvé pour cette saison.'),
                        ),
                      );
                    }

                    // Lliste des ListTiles d'épisodes
                    return Column(
                      children: episodeSnapshot.data!.docs.map<Widget>((episodeDoc) {
                        final Episode episode = Episode.fromFirestore(episodeDoc); // Utilise Episode.fromFirestore
                        return ListTile(
                          key: ValueKey(episode.id),
                          title: Text(
                            'E${episode.episodeNumber.toString().padLeft(2, '0')}: ${episode.title}',
                          ),
                          leading: episode.imageUrl.isNotEmpty
                              ? Image.network(
                            episode.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 50);
                            },
                          )
                              : const Icon(Icons.tv_sharp, size: 50),
                          subtitle: Text(
                            "${episode.releaseDate} - ${episode.duration}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 8.0,
                          ),
                          onTap: () {
                            if (kDebugMode) {
                              print('Tapped on episode: ${episode.title} (ID: ${episode.id})');
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EpisodeDetailPage(episode: episode),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}