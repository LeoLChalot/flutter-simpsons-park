import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/models/season_model.dart';
import 'package:simpsons_park/models/episode_model.dart';
import 'package:simpsons_park/pages/episode_detail_page.dart';
import 'package:simpsons_park/services/auth_service.dart';

import '../admin/edit_episode_page.dart';

// TODO: Importer la future page de modification d'épisode
// import 'package:simpsons_park/pages/edit_episode_page.dart';

class SeasonsTab extends StatefulWidget {
  const SeasonsTab({super.key});

  @override
  State<SeasonsTab> createState() => _SeasonsTabState();
}

class _SeasonsTabState extends State<SeasonsTab> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildSeasonsQuery() {
    return FirebaseFirestore.instance.collection('seasons').orderBy("seasonNumber").snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildEpisodesQuery(String seasonId) {
    return FirebaseFirestore.instance
        .collection('seasons')
        .doc(seasonId)
        .collection('episodes')
        .orderBy('episodeNumber')
        .snapshots();
  }

  bool _isUserAuthenticated(BuildContext context) {
    return context.read<AuthService>().isAuthenticated;
  }

  Future<void> _deleteSeason(BuildContext context, Season season) async {
    if (!_isUserAuthenticated(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour supprimer une saison.')),
      );
      return;
    }

    try {
      final episodesQuery = FirebaseFirestore.instance
          .collection('seasons')
          .doc(season.id)
          .collection('episodes');
      final episodesSnapshot = await episodesQuery.get();

      if (episodesSnapshot.docs.isNotEmpty) {
        final WriteBatch batch = FirebaseFirestore.instance.batch();
        for (DocumentSnapshot doc in episodesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        if (kDebugMode) {
          print('${episodesSnapshot.docs.length} épisodes supprimés pour la saison ${season.id}.');
        }
      }

      await FirebaseFirestore.instance.collection('seasons').doc(season.id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saison ${season.seasonNumber} et ses épisodes supprimés avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de la saison ${season.seasonNumber}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (kDebugMode) {
        print("Erreur Firestore (_deleteSeason ${season.id}): $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthenticated = context.watch<AuthService>().isAuthenticated;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _buildSeasonsQuery(),
      builder: (
          BuildContext context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> seasonSnapshot,
          ) {
        if (seasonSnapshot.hasError) {
          if (kDebugMode) {print("Erreur Firestore (SeasonsTab - Saisons): ${seasonSnapshot.error}");}
          return const Center(child: Text('Quelque chose s\'est mal passé avec les saisons.'));
        }
        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!seasonSnapshot.hasData || seasonSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Aucune saison trouvée.'));
        }

        final List<Season> seasons = seasonSnapshot.data!.docs.map(
              (doc) {
            try {
              return Season.fromFirestore(doc);
            } catch (e) {
              if (kDebugMode) {print("Error creating Season from Firestore doc ${doc.id}: $e");}
              return Season(id: doc.id, seasonNumber: 0, episodesCount: 0, name: 'Erreur Saison');
            }
          },
        ).toList();

        return ListView.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final Season season = seasons[index];
            final seasonId = season.id;
            final title = 'Saison ${season.seasonNumber} - ${season.episodesCount} épisodes';

            final DismissDirection seasonDismissDirection = isAuthenticated
                ? DismissDirection.endToStart
                : DismissDirection.none;

            return Dismissible(
              key: Key("season_$seasonId"),
              direction: seasonDismissDirection,
              background: _buildSwipeActionDeleteBackground(),
              secondaryBackground: _buildSwipeActionDeleteBackground(),
              confirmDismiss: (direction) async {
                if (!_isUserAuthenticated(context)) return false;
                if (direction == DismissDirection.endToStart) {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: Text('Voulez-vous vraiment supprimer la Saison ${season.seasonNumber} et tous ses épisodes ? Cette action est irréversible.'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('Annuler'),
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                          ),
                          TextButton(
                            child: Text('Supprimer Définitivement', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                          ),
                        ],
                      );
                    },
                  ) ?? false;
                }
                return false;
              },
              onDismissed: (direction) {
                if (direction == DismissDirection.endToStart) {
                  _deleteSeason(context, season);
                }
              },
              child: ExpansionTile(
                key: PageStorageKey<String>(seasonId),
                title: Text(title),
                children: <Widget>[
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _buildEpisodesQuery(seasonId),
                    builder: (
                        BuildContext context,
                        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> episodeSnapshot,
                        ) {
                      if (episodeSnapshot.hasError) {
                        if (kDebugMode) {print("Erreur Firestore (SeasonsTab - Episodes pour ${season.id}): ${episodeSnapshot.error}");}
                        return const ListTile(title: Text('Erreur de chargement des épisodes.'));
                      }
                      if (episodeSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
                      }
                      if (!episodeSnapshot.hasData || episodeSnapshot.data!.docs.isEmpty) {
                        return const Padding(padding: EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0), child: Center(child: Text('Aucun épisode trouvé pour cette saison.')));
                      }

                      return Column(
                        children: episodeSnapshot.data!.docs.map<Widget>((episodeDoc) {
                          final Episode episode = Episode.fromFirestore(episodeDoc);
                          return ListItemEpisode(
                            episode: episode,
                            seasonNumber: season.seasonNumber,
                            seasonId: seasonId,
                            isAuthenticated: isAuthenticated,
                            onDeleteEpisode: (ep) => _deleteEpisode(context, seasonId, ep),
                            onEditEpisode: (ep) => _navigateToEditEpisode(context, seasonId, ep), // Nouveau callback
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteEpisode(BuildContext context, String seasonId, Episode episode) async {
    if (!_isUserAuthenticated(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour supprimer un épisode.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('seasons')
          .doc(seasonId)
          .collection('episodes')
          .doc(episode.id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Épisode "${episode.title}" supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de l\'épisode "${episode.title}": $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (kDebugMode) {
        print("Erreur Firestore (_deleteEpisode ${episode.id} in season $seasonId): $e");
      }
    }
  }
  Widget _buildSwipeActionDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.redAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Icon(Icons.delete_sweep, color: Colors.white),
        ],
      ),
    );
  }
  void _navigateToEditEpisode(BuildContext context, String seasonId, Episode episode) {
    if (!_isUserAuthenticated(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour modifier un épisode.')),
      );
      return;
    }

    // TODO: Implémenter la navigation vers la page de modification d'épisode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation pour modifier : ${episode.title} (S${seasonId}E${episode.episodeNumber})')),
    );
    if (kDebugMode) {
      print('Naviguer pour modifier l\'épisode: ${episode.title} (ID: ${episode.id}) de la saison $seasonId');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEpisodePage(seasonId: seasonId, episode: episode), // Votre future page
      ),
    );
  }
}

class ListItemEpisode extends StatelessWidget {
  final Episode episode;
  final int seasonNumber;
  final String seasonId;
  final bool isAuthenticated;
  final Future<void> Function(Episode episode) onDeleteEpisode;
  final void Function(Episode episode) onEditEpisode;

  const ListItemEpisode({
    super.key,
    required this.episode,
    required this.seasonNumber,
    required this.seasonId,
    required this.isAuthenticated,
    required this.onDeleteEpisode,
    required this.onEditEpisode,
  });

  @override
  Widget build(BuildContext context) {
    final episodeId = episode.id;
    final episodeNumber = episode.episodeNumber.toString().padLeft(2, '0');
    final episodeTitle = 'E$episodeNumber: ${episode.title}';
    final episodeImageWidget = episode.imageUrl.isNotEmpty
        ? ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Image.network(
        episode.imageUrl,
        width: 60, height: 40, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 40, color: Colors.grey[300], child: const Icon(Icons.broken_image, size: 30)),
        loadingBuilder:(context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(width: 60, height: 40, color: Colors.grey[200], child: const Center(child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,))));
        },
      ),
    )
        : Container(width: 60, height: 40, color: Colors.grey[300], child: const Icon(Icons.tv_sharp, size: 30));
    final subtitleEpisode = Text("${episode.releaseDate} - ${episode.duration}", maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall);

    // Si authentifié, permettre glissement G/D, sinon aucun glissement.
    final DismissDirection episodeDismissDirection = isAuthenticated
        ? DismissDirection.horizontal
        : DismissDirection.none;

    return Dismissible(
      key: Key("episode_${episodeId}"),
      direction: episodeDismissDirection,
      background: _buildSwipeActionEditBackground(),
      secondaryBackground: _buildSwipeActionDeleteBackground(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEditEpisode(episode);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          return await showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text('Confirmer la suppression'),
                content: Text('Voulez-vous vraiment supprimer l\'épisode "${episode.title}"?'),
                actions: <Widget>[
                  TextButton(child: const Text('Annuler'), onPressed: () => Navigator.of(dialogContext).pop(false)),
                  TextButton(child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)), onPressed: () => Navigator.of(dialogContext).pop(true)),
                ],
              );
            },
          ) ?? false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDeleteEpisode(episode);
        }
      },
      child: ListTile(
        title: Text(episodeTitle, style: Theme.of(context).textTheme.titleSmall),
        leading: episodeImageWidget,
        subtitle: subtitleEpisode,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        dense: true,
        onTap: () {
          if (kDebugMode) {
            print('Tapped on episode: ${episode.title} (ID: $episodeId)');
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EpisodeDetailPage(episode: episode, seasonNumber: seasonNumber),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeActionEditBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.blueAccent, // Couleur distinctive pour "Modifier"
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.edit, color: Colors.white),
          SizedBox(width: 10),
          Text('Modifier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildSwipeActionDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.redAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Supprimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          SizedBox(width: 10),
          Icon(Icons.delete, color: Colors.white),
        ],
      ),
    );
  }
}