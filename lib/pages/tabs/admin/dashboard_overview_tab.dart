// lib/pages/tabs/admin/dashboard_overview_tab.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardOverviewTab extends StatefulWidget {
  const DashboardOverviewTab({super.key});

  @override
  State<DashboardOverviewTab> createState() => _DashboardOverviewTabState();
}

class _DashboardOverviewTabState extends State<DashboardOverviewTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text(
              'Aperçu des Données',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            // == Personnages enregistrés
            const SizedBox(height: 24),
            _buildCountCard(
              title: 'Personnages Enregistrés',
              countStream: _firestore.collection('characters').snapshots(),
              icon: Icons.people_alt_outlined,
              color: Colors.orange,
            ),
            // == Saisons enregistrées
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Saisons Enregistrées',
              countStream: _firestore.collection('seasons').snapshots(),
              icon: Icons.video_library_outlined,
              color: Colors.blue,
            ),
            // == Épisodes enregistrés
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Épisodes Enregistrés (Total)',
              countStream: _firestore.collectionGroup('episodes').snapshots(),
              icon: Icons.tv_outlined,
              color: Colors.green,
            ),
            // == Topics Rédigés
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Topics Rédigés',
              countStream: _firestore.collection('newspapers').snapshots(),
              icon: Icons.newspaper_outlined,
              color: Colors.pink,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountCard({
    required String title,
    required Stream<QuerySnapshot<Map<String, dynamic>>> countStream,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    // == Récupération des documents dans la collection
                    stream: countStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot
                              .hasData) // Gèrer l'état de la récupération des données
                      {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      } else if (snapshot.hasError) // Cas où il y a une erreur
                      {
                        if (kDebugMode) {
                          print(
                            "Erreur StreamBuilder pour $title: ${snapshot.error}",
                          );
                        }
                        return Text(
                          'Erreur',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                        );
                      } else if (snapshot.hasData) // Cas où il y a des données
                      {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        );
                      } else // Cas où il n'y a pas de données
                      {
                        return Text(
                          '0',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
