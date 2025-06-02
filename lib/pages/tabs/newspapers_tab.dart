import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Ajout pour Provider
import 'package:simpsons_park/models/newspaper_model.dart';
import 'package:simpsons_park/pages/newspaper_detail_page.dart';
import 'package:simpsons_park/services/auth_service.dart'; // Ajout pour AuthService

// TODO: Importez votre page/widget de modification d'article ici
// import 'package:simpsons_park/pages/edit_newspaper_page.dart';

class NewspapersTab extends StatefulWidget {
  const NewspapersTab({super.key});

  @override
  State<NewspapersTab> createState() => _NewspapersTabState();
}

class _NewspapersTabState extends State<NewspapersTab> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _buildNewspapersQuery() {
    return FirebaseFirestore.instance
        .collection('newspapers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Méthode pour vérifier l'authentification (utilisée par les gestionnaires d'action)
  bool _isUserAuthenticated(BuildContext context) {
    return context.read<AuthService>().isAuthenticated;
  }

  // Méthode pour naviguer vers la page de modification d'un article
  void _navigateToEditNewspaper(BuildContext context, Newspaper newspaper) {
    if (!_isUserAuthenticated(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour modifier un article.')),
      );
      return;
    }
    // TODO: Implémenter la navigation vers la page de modification d'article
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigation vers la modification de : ${newspaper.title}')),
    );
    if (kDebugMode) {
      print('Naviguer pour modifier l\'article: ${newspaper.title} (ID: ${newspaper.id})');
    }
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNewspaperPage(newspaper: newspaper), // Votre page de modification
      ),
    );
    */
  }

  Future<void> _deleteNewspaper(BuildContext context, Newspaper newspaper) async {
    if (!_isUserAuthenticated(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous devez être connecté pour supprimer un article.')),
      );
      return;
    }
    // Vérification cruciale que l'ID de l'article n'est pas null ou vide
    if (newspaper.id == null || newspaper.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : ID de l\'article manquant pour la suppression.')),
      );
      return;
    }

    try {
      // Suppression dans Firestore
      await FirebaseFirestore.instance.collection('newspapers').doc(newspaper.id).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Article "${newspaper.title}" supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression de "${newspaper.title}": $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (kDebugMode) {
        print("Erreur Firestore (_deleteNewspaper): $e");
      }
    }
  }


  Widget _buildSwipeActionLeft() { // Fond pour le swipe vers la droite (action "Modifier")
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.blueAccent, // Couleur pour l'action de modification
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

  Widget _buildSwipeActionRight() { // Fond pour le swipe vers la gauche (action "Supprimer")
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.redAccent, // Couleur pour l'action de suppression
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 12.0),
              child: Text(
                "Articles Récents",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _buildNewspapersQuery(),
                builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      print("Erreur Firestore (NewspapersTab): ${snapshot.error}");
                    }
                    return const Center(child: Text('Impossible de charger les articles...'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aucun article trouvé.'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = snapshot.data!.docs[index];
                      Newspaper article = Newspaper.fromFirestore(
                        document as DocumentSnapshot<Map<String, dynamic>>,
                      );

                      bool hasSubtitle = article.subtitle.isNotEmpty;

                      // Déterminer la draggabilité en fonction de l'état d'authentification
                      final bool isAuthenticated = context.watch<AuthService>().isAuthenticated;
                      final DismissDirection itemDismissDirection = isAuthenticated
                          ? DismissDirection.horizontal // Permet le glissement horizontal
                          : DismissDirection.none;    // Désactive le glissement

                      return Dismissible(
                        key: Key(article.id ?? 'fallback_key_${DateTime.now().millisecondsSinceEpoch}_$index'), // Clé unique, avec fallback si ID est null
                        direction: itemDismissDirection,
                        background: _buildSwipeActionLeft(), // Swipe vers la droite (Modifier)
                        secondaryBackground: _buildSwipeActionRight(), // Swipe vers la gauche (Supprimer)
                        confirmDismiss: (direction) async {
                          if (!_isUserAuthenticated(context)) { // Vérification de sécurité
                            return false;
                          }
                          if (direction == DismissDirection.startToEnd) { // Modifier
                            _navigateToEditNewspaper(context, article);
                            return false; // Ne pas supprimer l'élément de la liste immédiatement
                          } else if (direction == DismissDirection.endToStart) { // Supprimer
                            return await showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: Text('Voulez-vous vraiment supprimer l\'article "${article.title}"?'),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Annuler'),
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                    ),
                                    TextButton(
                                      child: Text('Supprimer', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                    ),
                                  ],
                                );
                              },
                            ) ?? false; // Retourne false si la boîte de dialogue est fermée
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (!_isUserAuthenticated(context)) return; // Vérification de sécurité

                          if (direction == DismissDirection.endToStart) {
                            // La suppression effective se fait ici si confirmDismiss a retourné true
                            _deleteNewspaper(context, article);
                          }
                          // Pour l'action de modification (startToEnd), nous ne faisons rien dans onDismissed
                          // car confirmDismiss retourne false et la navigation est déjà gérée.
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          elevation: 2.0,
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            title: Text(
                              article.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: hasSubtitle
                                ? Text(
                              article.subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            )
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16), // Icône plus discrète
                            contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                            onTap: () {
                              if (kDebugMode) {
                                print('Tapped on ${article.title} (ID: ${article.id})');
                              }
                              if (article.id != null && article.id!.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NewspaperDetailPage(article: article),
                                  ),
                                );
                                // Optionnel: SnackBar pour la navigation peut être redondant si la page change visiblement.
                                /*
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Ouverture de : ${article.title}')),
                                );
                                */
                              } else {
                                if (kDebugMode) {
                                  print('Erreur: ID de l\'article manquant.');
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erreur: Impossible d\'ouvrir cet article.')),
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}