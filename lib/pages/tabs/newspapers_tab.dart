import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/newspaper_model.dart';
import '../newspaper_detail_page.dart';

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
                  // 1er cas : Gestion d'erreur
                  if (snapshot.hasError) {
                    if (kDebugMode) {
                      print(
                        "Erreur Firestore (NewspapersTab): ${snapshot.error}",
                      );
                    }
                    return const Center(
                      child: Text('Impossible de charger les articles...'),
                    );
                  }

                  // 2ème cas : En attente des premières données
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 3ème cas : Le flux de données est vide
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aucun article trouvé.'));
                  }

                  // Finalité : Le flux a été reçu, et n'est pas vide
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot document = snapshot.data!.docs[index];
                      Newspaper article = Newspaper.fromFirestore(
                        document as DocumentSnapshot<Map<String, dynamic>>,
                      );

                      bool hasSubtitle = article.subtitle.isNotEmpty;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 6.0,
                          horizontal: 4.0,
                        ),
                        elevation: 2.0,
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          title: Text(
                            article.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                          trailing: const Icon(Icons.arrow_forward),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10.0,
                            horizontal: 16.0,
                          ),
                          onTap: () {
                            if (kDebugMode) {
                              print(
                                'Tapped on ${article.title} (ID: ${article.id})',
                              );
                            }
                            if (article.id != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NewspaperDetailPage(article: article),
                                ),
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Navigation vers l\'article : ${article.title}',
                                  ),
                                ),
                              );
                            } else {
                              if (kDebugMode) {
                                print('Erreur: ID de l\'article manquant.');
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Erreur: Impossible d\'ouvrir cet article.',
                                  ),
                                ),
                              );
                            }
                          },
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
