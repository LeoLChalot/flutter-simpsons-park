import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/episode_model.dart';
import 'package:simpsons_park/models/character_model.dart';

class EpisodeDetailPage extends StatefulWidget {
  final Episode episode;

  const EpisodeDetailPage({
    super.key,
    required this.episode,
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
      final characters = await widget.episode.getCharacters(FirebaseFirestore.instance);
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

            // Titre de l'épisode
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
              children: <Widget>[
                _buildInfoChip(context, Icons.tv_outlined, 'S${episode.seasonNumber.toString().padLeft(2, '0')} E${episode.episodeNumber.toString().padLeft(2, '0')}'),
                if (episode.releaseDate.isNotEmpty)
                  _buildInfoChip(context, Icons.calendar_today_outlined, episode.releaseDate), // La date est déjà un String formaté
                if (episode.duration.isNotEmpty)
                  _buildInfoChip(context, Icons.timer_outlined, '${episode.duration} min'),
              ],
            ),
            const SizedBox(height: 16.0),

            // Synopsis
            Text(
              "Synopsis :",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            SelectableText(
              episode.description,
              style: textTheme.bodyLarge?.copyWith(
                height: 1.5, // Interligne
                fontSize: 15, // Taille de police
                color: theme.colorScheme.onSurface.withValues(),
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20.0),

            // Section Personnages
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
    return Chip(
      avatar: Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSecondaryContainer),
      label: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
    );
  }

  Widget _buildCharactersSection() {
    if (_isLoadingCharacters) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      ));
    }

    if (_characterLoadError != null) {
      return Center(child: Text(_characterLoadError!, style: TextStyle(color: Theme.of(context).colorScheme.error)));
    }

    if (_loadedCharacters == null || _loadedCharacters!.isEmpty) {
      return const Text('Aucun personnage spécifique listé pour cet épisode.');
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: _loadedCharacters!.map((character) {
        String characterName = "${character.firstName} ${character.lastName}".trim();
        if (characterName.isEmpty) {
          characterName = character.pseudo.isNotEmpty ? character.pseudo : "Personnage inconnu";
        }
        return Chip(
          avatar: character.imageUrl.isNotEmpty
              ? CircleAvatar(
            backgroundImage: NetworkImage(character.imageUrl),
            onBackgroundImageError: (e,s) => const Icon(Icons.person, size: 18), // Fallback si l'image du perso ne charge pas
          )
              : const CircleAvatar(child: Icon(Icons.person_outline, size: 18)),
          label: Text(characterName),
        );
      }).toList(),
    );
  }
}