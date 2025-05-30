// seasons_tab.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/season_model.dart'; // Ensure this path is correct
import 'package:simpsons_park/models/episode_model.dart'; // Ensure this path is correct

class SeasonsTab extends StatefulWidget {
  const SeasonsTab({super.key});

  @override
  State<SeasonsTab> createState() => _SeasonsTabState();
}

class _SeasonsTabState extends State<SeasonsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Key: season.id (String), Value: List of Episodes
  final Map<String, List<Episode>> _loadedEpisodes = {};
  // Key: season.id (String), Value: bool (true if loading)
  final Map<String, bool> _isLoadingEpisodes = {};

  Future<void> _fetchEpisodesForSeason(Season season) async {
    if (_loadedEpisodes.containsKey(season.id) || (_isLoadingEpisodes[season.id] == true)) {
      return;
    }

    setState(() {
      _isLoadingEpisodes[season.id] = true;
    });

    List<Episode> fetchedEpisodes = [];

    try {
      if (kDebugMode) {
        print("Fetching episodes for season ID: ${season.id}");
      }

      // Utiliser directement season.episodeReferences si le modèle Season les contient déjà
      // Sinon, récupérer le document season à nouveau si nécessaire.
      // Le modèle Season actuel stocke episodeReferences, donc nous devrions les utiliser.
      // DocumentSnapshot seasonDoc = await _firestore.collection('seasons').doc(season.id).get();
      // if (!seasonDoc.exists || seasonDoc.data() == null) {
      //   if (kDebugMode) {
      //     print("Season document ${season.id} not found or has no data.");
      //   }
      //   setState(() {
      //     _loadedEpisodes[season.id] = [];
      //     _isLoadingEpisodes[season.id] = false;
      //   });
      //   return;
      // }
      // Map<String, dynamic> seasonData = seasonDoc.data()! as Map<String, dynamic>;
      // List<dynamic>? episodeRefsArray = seasonData['episodes'] as List<dynamic>?;

      // Utilisation des références stockées dans l'objet Season
      List<Map<String, dynamic>>? episodeRefsArray = season.episodeReferences;


      if (episodeRefsArray.isEmpty) {
        if (kDebugMode) {
          print("No episode references found in season object ${season.id}");
        }
        setState(() {
          _loadedEpisodes[season.id] = [];
          // _isLoadingEpisodes[season.id] = false; // Géré dans finally
        });
        // return; // Ne pas retourner ici pour que finally s'exécute
      } else { // Seulement si episodeRefsArray n'est pas null et pas vide
        for (var episodeMapEntry in episodeRefsArray) {
          // Le modèle Season stocke déjà des Map<String, dynamic>
          // donc episodeMapEntry est déjà une Map<String, dynamic>.
          // if (episodeMapEntry is Map<String, dynamic>) { // Plus nécessaire si le type est garanti par Season.episodeReferences
          final DocumentReference? episodeRef = episodeMapEntry['episode'] as DocumentReference?;

          if (episodeRef != null) {
            try {
              final DocumentSnapshot episodeDoc = await episodeRef.get();
              if (episodeDoc.exists) {
                fetchedEpisodes.add(Episode.fromFirestore(episodeDoc as DocumentSnapshot<Map<String, dynamic>>));
              } else {
                if (kDebugMode) {
                  print("Episode document not found for ref: ${episodeRef.path}");
                }
              }
            } catch (e, stackTrace) {
              if (kDebugMode) {
                print("Error fetching individual episode ${episodeRef.path}: $e");
              }
              if (kDebugMode) {
                print("Stack trace: $stackTrace");
              }
            }
          }
          // }
        }
      }


      // Optionnel: Trier les épisodes si l'ordre n'est pas garanti par l'array
      fetchedEpisodes.sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));

      if (kDebugMode) {
        print("Fetched ${fetchedEpisodes.length} episodes for season ${season.id}");
      }

      // Vérifier si le widget est toujours monté avant d'appeler setState
      if (mounted) {
        setState(() {
          _loadedEpisodes[season.id] = fetchedEpisodes;
        });
      }

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error in _fetchEpisodesForSeason for season ${season.id}: $e");
      }
      if (kDebugMode) {
        print("Stack trace: $stackTrace");
      }
      if (mounted) {
        setState(() {
          _loadedEpisodes[season.id] = []; // Marquer comme erreur ou vide
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEpisodes[season.id] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('seasons').orderBy('seasonNumber').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> seasonSnapshot) {
        if (seasonSnapshot.hasError) {
          return Center(child: Text('Quelque chose s\'est mal passé avec les saisons: ${seasonSnapshot.error}'));
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
            return Season(id: doc.id, seasonNumber: 0, title: "Error: Invalid Season Data", episodeReferences: []);
          }
        }).toList();

        return ListView.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final Season season = seasons[index];
            final bool isCurrentlyLoadingEpisodes = _isLoadingEpisodes[season.id] ?? false;
            final List<Episode>? episodesForThisSeason = _loadedEpisodes[season.id];

            return ExpansionTile(
              key: PageStorageKey<String>(season.id), // Clé pour sauvegarder l'état d'expansion
              title: Text(season.title.isNotEmpty ? season.title : 'Saison ${season.seasonNumber}'),
              onExpansionChanged: (isExpanded) {
                if (isExpanded && episodesForThisSeason == null && !isCurrentlyLoadingEpisodes) {
                  // Modifié : !_loadedEpisodes.containsKey(season.id) -> episodesForThisSeason == null
                  // pour refléter plus directement si les données sont chargées pour l'UI.
                  _fetchEpisodesForSeason(season);
                }
              },
              children: <Widget>[
                if (isCurrentlyLoadingEpisodes)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (episodesForThisSeason != null && episodesForThisSeason.isNotEmpty)
                // Enveloppe le ListView.builder dans son propre PageStorageBucket
                  PageStorage(
                    bucket: PageStorageBucket(), // Crée un nouveau contexte de stockage pour ce sous-arbre
                    child: ListView.builder(
                      key: ValueKey('episodes_list_for_season_${season.id}'), // Clé unique pour ce ListView
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: episodesForThisSeason.length,
                      itemBuilder: (context, episodeIndex) {
                        final episode = episodesForThisSeason[episodeIndex];
                        return ListTile(
                          title: Text('E${episode.episodeNumber}: ${episode.title}'),
                          leading: Image.network(episode.imageUrl),
                          subtitle: Text(
                            "${episode.releaseDate} - ${episode.duration} min",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.arrow_forward),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                          onTap: () {
                            if (kDebugMode) {
                              print('Tapped on ${episode.title}');
                              // Exemple pour charger et afficher les personnages :
                              // episode.getOrLoadCharacters(_firestore).then((characters) {
                              //   print("Personnages pour ${episode.title}:");
                              //   for (var char in characters) {
                              //     print("- ${char.name}"); // Supposant que Character a un champ 'name'
                              //   }
                              // });
                            }
                          },
                        );
                      },
                    ),
                  )
                else if (episodesForThisSeason != null && episodesForThisSeason.isEmpty && !isCurrentlyLoadingEpisodes)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Aucun épisode trouvé pour cette saison.')),
                    )
              ],
            );
          },
        );
      },
    );
  }
}