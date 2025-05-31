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
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildSeasonsQuery() {
    return FirebaseFirestore.instance.collection('seasons').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildEpisodesQuery(
    String seasonId,
  ) {
    return FirebaseFirestore.instance
        .collection('seasons')
        .doc(seasonId)
        .collection('episodes')
        .orderBy('episodeNumber')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    // On utilise StreamBuilder pour une mise à jour en temps réel
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      // Ici le stream
      stream: _buildSeasonsQuery(),

      // Puis le builder (se met à jour à chaque mouvement du côté du Stream
      builder:
          (
            BuildContext context, // seasonSnapshot est le nom donné au Stream
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> seasonSnapshot,
          ) {
            // 1er cas : Gestion d'erreur
            if (seasonSnapshot.hasError) {
              if (kDebugMode) {
                print(
                  "Erreur Firestore (SeasonsTab - Saisons): ${seasonSnapshot.error}",
                );
              }

              // Solution : On renvoit un message d'erreur pour l'utilisateur
              return const Center(
                child: Text('Quelque chose s\'est mal passé avec les saisons.'),
              );
            }

            // 2ème cas : En attente des premières données
            if (seasonSnapshot.connectionState == ConnectionState.waiting) {
              // Solution : On affiche un indicateur de chargement
              return const Center(child: CircularProgressIndicator());
            }

            // 3ème cas : Le flux de données est vide
            if (!seasonSnapshot.hasData || seasonSnapshot.data!.docs.isEmpty) {
              // Solution : On renvoit un message pour l'utilisateur
              return const Center(child: Text('Aucune saison trouvée.'));
            }

            // Finalité : Le flux a été reçu, et n'est pas vide
            final List<Season> seasons = seasonSnapshot.data!.docs.map(
              (doc) {
                // Bloc try {} catch {} pour la gestion des erreurs
                try {
                  return Season.fromFirestore(doc);
                } catch (e) {
                  if (kDebugMode) {
                    print(
                      "Error creating Season from Firestore doc ${doc.id}: $e",
                    );
                  }
                  return Season(id: doc.id, seasonNumber: 0, episodeCount: 0);
                }
              },
            ).toList(); // On applique .toList() à seasonSnapshot.data!.docs.map

            return ListView.builder(
              itemCount: seasons.length,
              itemBuilder: (context, index) {
                final Season season = seasons[index];
                final seasonId = season.id;
                final title =
                    'Saison ${season.seasonNumber} - ${season.episodeCount} épisodes';

                return ExpansionTile(
                  key: PageStorageKey<String>(seasonId),
                  title: Text(title),
                  children: <Widget>[
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _buildEpisodesQuery(seasonId),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                            episodeSnapshot,
                          ) {
                            // 1er cas : Gestion d'erreur
                            if (episodeSnapshot.hasError) {
                              if (kDebugMode) {
                                print(
                                  "Erreur Firestore (SeasonsTab - Episodes pour ${season.id}): ${episodeSnapshot.error}",
                                );
                              }
                              return const ListTile(
                                title: Text(
                                  'Erreur de chargement des épisodes.',
                                ),
                              );
                            }

                            // 2ème cas : Chargement des données
                            if (episodeSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            // 3ème cas : Pas de données
                            if (!episodeSnapshot.hasData ||
                                episodeSnapshot.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                  vertical: 16.0,
                                ),
                                child: Center(
                                  child: Text(
                                    'Aucun épisode trouvé pour cette saison.',
                                  ),
                                ),
                              );
                            }

                            // Finalité : Données chargées
                            return Column(
                              children: episodeSnapshot.data!.docs.map<Widget>((episodeDoc) {
                                final Episode episode = Episode.fromFirestore(
                                  episodeDoc,
                                );
                                return ListItemEpisode(episode: episode);
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

final _trailingIcon = const Icon(Icons.arrow_forward_ios, size: 16);
final _contentPadding = const EdgeInsets.symmetric(
  horizontal: 32.0,
  vertical: 8.0,
);
class ListItemEpisode extends StatelessWidget {
  final Episode episode;

  const ListItemEpisode({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    final episodeId = episode.id;
    final episodeNumber = episode.episodeNumber.toString().padLeft(2, '0');
    final episodeTitle = 'E$episodeNumber: ${episode.title}';
    final episodeImage = episode.imageUrl.isNotEmpty
        ? Image.network(
            episode.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.broken_image, size: 50);
            },
          )
        : const Icon(Icons.tv_sharp, size: 50);
    final subtitleEpisode = Text(
      "${episode.releaseDate} - ${episode.duration}",
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    return ListTile(
      key: ValueKey(episodeId),
      title: Text(episodeTitle),
      leading: episodeImage,
      subtitle: subtitleEpisode,
      trailing: _trailingIcon,
      contentPadding: _contentPadding,
      onTap: () {
        if (kDebugMode) {
          print('Tapped on episode: ${episode.title} (ID: $episodeId)');
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EpisodeDetailPage(episode: episode),
          ),
        );
      },
    );
    ;
  }
}
