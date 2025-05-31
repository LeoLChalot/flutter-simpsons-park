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

  Future<int?> _getCollectionCount(String collectionName) async {
    try {
      AggregateQuerySnapshot snapshot =
      await _firestore.collection(collectionName).count().get();
      return snapshot.count;
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la récupération du nombre pour $collectionName: $e");
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding (
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Text(
              'Aperçu des Données',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildCountCard(
              title: 'Personnages Enregistrés',
              countFuture: _getCollectionCount('characters'),
              icon: Icons.people_alt_outlined,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Saisons Enregistrées',
              countFuture: _getCollectionCount('seasons'),
              icon: Icons.video_library_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Épisodes Enregistrés',
              countFuture: _getCollectionCount('episodes'),
              icon: Icons.tv_outlined,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            _buildCountCard(
              title: 'Topics Rédigés',
              countFuture: _getCollectionCount('newspapers'),
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
    required Future<int?> countFuture,
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
                  FutureBuilder<int?>(
                    future: countFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      } else if (snapshot.hasError || snapshot.data == null) {
                        return Text(
                          'Erreur de chargement',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        return Text(
                          snapshot.data.toString(),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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