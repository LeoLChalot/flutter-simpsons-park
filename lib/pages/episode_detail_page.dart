import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/episode_model.dart';
import 'package:simpsons_park/models/character_model.dart';
import 'package:simpsons_park/pages/character_detail_page.dart';

class EpisodeDetailPage extends StatefulWidget {
  final Episode episode;
  final int seasonNumber;

  const EpisodeDetailPage({
    super.key,
    required this.episode,
    required this.seasonNumber, // Gardé si tu en as un usage spécifique
  });

  @override
  State<EpisodeDetailPage> createState() => _EpisodeDetailPageState();
}

class _EpisodeDetailPageState extends State<EpisodeDetailPage> {
  List<Character>? _loadedCharacters;
  bool _isLoadingCharacters = true;
  String? _characterLoadError;

  @override
  void initState() {
    super.initState();
    _fetchCharacters();
  }

  Future<void> _fetchCharacters() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCharacters = true;
      _characterLoadError = null;
    });
    try {
      // S'assurer que widget.episode.getOrLoadCharacters est bien implémenté
      // pour utiliser charactersList (Map<String, String>) et charger les personnages
      final characters = await widget.episode.getOrLoadCharacters(FirebaseFirestore.instance);
      if (mounted) {
        setState(() {
          _loadedCharacters = characters;
          _isLoadingCharacters = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors du chargement des personnages pour l'épisode ${widget.episode.id}: $e");
      }
      if (mounted) {
        setState(() {
          _characterLoadError = "Impossible de charger les personnages.";
          _isLoadingCharacters = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final Episode episode = widget.episode;
    // Utiliser le seasonNumber de l'objet episode s'il est fiable, sinon celui passé en paramètre
    final int displaySeasonNumber = widget.seasonNumber;

    return Scaffold(
      appBar: AppBar(
        title: Text(episode.title, overflow: TextOverflow.ellipsis),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (episode.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  episode.imageUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 50)),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (episode.imageUrl.isNotEmpty) const SizedBox(height: 16.0),

            Text(
              episode.title,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8.0),

            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.center,
              children: <Widget>[
                _buildInfoChip(
                  context,
                  Icons.tv_outlined,
                  'S${displaySeasonNumber.toString().padLeft(2, '0')} E${episode.episodeNumber.toString().padLeft(2, '0')}',
                ),
                if (episode.releaseDate.isNotEmpty)
                  _buildInfoChip(
                    context,
                    Icons.calendar_today_outlined,
                    episode.releaseDate,
                  ),
                if (episode.duration.isNotEmpty)
                  _buildInfoChip(
                    context,
                    Icons.timer_outlined,
                    episode.duration,
                  ),
              ],
            ),
            const SizedBox(height: 16.0),

            Text(
              "Synopsis :",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            SelectableText(
              episode.description,
              style: textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontSize: 15,
                color: theme.colorScheme.onSurface.withValues(),
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20.0),

            Text(
              "Personnages présents :",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            _buildCharactersSection(),

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(icon, size: 16, color: theme.colorScheme.onSecondaryContainer),
      label: Text(label, style: TextStyle(color: theme.colorScheme.onSecondaryContainer)),
      backgroundColor: theme.colorScheme.secondaryContainer.withValues(), // CORRECTION: .withOpacity()
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
    );
  }

  Widget _buildCharactersSection() {
    final theme = Theme.of(context);
    if (_isLoadingCharacters) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
      );
    }

    if (_characterLoadError != null) {
      return Center(
        child: Text(_characterLoadError!, style: TextStyle(color: theme.colorScheme.error)),
      );
    }

    if (_loadedCharacters == null || _loadedCharacters!.isEmpty) {
      if (widget.episode.charactersList.isEmpty) {
        return const Text('Aucun personnage crédité pour cet épisode.');
      }
      return const Text('Les informations des personnages n\'ont pu être chargées.');
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 6.0,
      children: _loadedCharacters!.map((character) {
        String characterName = character.name.trim();
        if (characterName.isEmpty) {
          characterName = character.pseudo.isNotEmpty ? character.pseudo : "Personnage inconnu";
        }

        return Chip(
          avatar: character.imageUrl.isNotEmpty
              ? CircleAvatar(
            backgroundImage: NetworkImage(character.imageUrl),
            onBackgroundImageError: (exception, stackTrace) {
              if (kDebugMode) {
                print("Erreur chargement avatar pour ${character.id}: $exception");
              }
            },
            child: character.imageUrl.isEmpty ? const Icon(Icons.person_outline, size: 18) : null,
          )
              : const CircleAvatar(child: Icon(Icons.person_outline, size: 18)),
          label: Text(characterName),
          backgroundColor: theme.chipTheme.backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
          labelStyle: theme.chipTheme.labelStyle ?? TextStyle(color: theme.colorScheme.onSurfaceVariant),
          deleteIcon: Icon(Icons.info),
          onDeleted: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CharacterDetailPage(character: character),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}