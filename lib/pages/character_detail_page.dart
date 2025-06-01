import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:simpsons_park/models/character_model.dart';

class CharacterDetailPage extends StatelessWidget {
  final Character character;

  const CharacterDetailPage({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    String displayName = character.name.trim();
    if (displayName.isEmpty) {
      displayName = character.pseudo.isNotEmpty ? character.pseudo : "Personnage Inconnu";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        elevation: 1.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (character.imageUrl.isNotEmpty)
              Center(
                child: Hero(
                  tag: 'character_image_${character.id}',
                  child: CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(character.imageUrl),
                    onBackgroundImageError: (exception, stackTrace) {
                      if (kDebugMode) {
                        print("Erreur chargement image personnage: $exception");
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    child: character.imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 80)
                        : null,
                  ),
                ),
              ),
            if (character.imageUrl.isNotEmpty) const SizedBox(height: 20.0),

            Center(
              child: Text(
                displayName,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (character.pseudo.isNotEmpty && character.pseudo != displayName)
              Center(
                child: Text(
                  "Alias: ${character.pseudo}",
                  style: textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16.0),

            if (character.function.isNotEmpty) ...[
              _buildSectionTitle(context, "Rôle / Fonction :"),
              Text(
                character.function,
                style: textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 16),
              ),
              const SizedBox(height: 16.0),
            ],
            if (character.description.isNotEmpty) ...[
              _buildSectionTitle(context, "Description / Histoire :"),
              SelectableText(
                character.description,
                style: textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontSize: 16,
                  color: colorScheme.onSurface.withValues(),
                ),
                textAlign: TextAlign.justify,
              ),
            ],

            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}