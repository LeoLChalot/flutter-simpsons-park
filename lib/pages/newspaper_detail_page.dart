import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/newspaper_model.dart';
import 'package:share_plus/share_plus.dart';

class NewspaperDetailPage extends StatelessWidget {
  final Newspaper article;

  const NewspaperDetailPage({super.key, required this.article});

  // Méthode pour un vrai partage d'article
  Future<void> _shareArticle(BuildContext context) async {
    final String articleTitle = article.title;
    final String shareText =
        "J'ai lu cet article intéressant sur Simpsons Park : \"$articleTitle\"";
    final String articleUrl =
        "https://simpsonspark.example.com/articles/${article.id ?? articleTitle.replaceAll(' ', '-').toLowerCase()}";
    final String subject = "Article : $articleTitle";
    final box = context.findRenderObject() as RenderBox?;

    try {
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(subject: subject, uri: Uri.parse(articleUrl)),
      );

      if (result.status == ShareResultStatus.success) {
        if (kDebugMode) {
          print('Merci pour le partage!');
        }
      } else if (result.status == ShareResultStatus.dismissed) {
        if (kDebugMode) {
          print('Partage de "$articleTitle" annulé par l\'utilisateur.');
        }
      } else if (result.status == ShareResultStatus.unavailable) {
        if (kDebugMode) {
          print('Partage de "$articleTitle" non disponible.');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune application de partage disponible.'),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du partage de "$articleTitle": $e');
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erreur lors du partage.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(article.title, overflow: TextOverflow.ellipsis),
        elevation: 8.0,
        shadowColor: Colors.black87,
        actions: [
          // Option: Mettre l'icône de partage dans l'AppBar
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareArticle(context),
            tooltip: 'Partager l\'article',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              article.title,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8.0),

            if (article.subtitle.isNotEmpty) ...[
              Text(
                article.subtitle,
                style: textTheme.titleLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16.0),
            ],

            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    article.author ?? 'Membre de la communauté d\'amin',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 4),
                Text(
                  "Publié le ${article.createdAt.toDate().day}/${article.createdAt.toDate().month}/${article.createdAt.toDate().year}",
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Divider(color: theme.dividerColor.withValues()),
            const SizedBox(height: 16.0),

            SelectableText(
              article.body,
              style: textTheme.bodyLarge?.copyWith(
                height: 1.6,
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(),
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24.0),

            // Bouton de Partage
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share),
                label: const Text('Partager cet article'),
                onPressed: () => _shareArticle(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
