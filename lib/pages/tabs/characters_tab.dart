import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/character_model.dart';

class ChatactersTab extends StatefulWidget {
  const ChatactersTab({super.key});

  @override
  State<ChatactersTab> createState() => _ChatactersTabState();
}

class _ChatactersTabState extends State<ChatactersTab> {
  String? _selectedLetter;

  // Liste des lettres pour le filtre
  final List<String> _alphabet = List.generate(
    26,
    (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
  );

  // Récupérer la liste des documents de la collection "characters"
  Query _buildCharactersQuery() {
    Query query = FirebaseFirestore.instance.collection('characters');

    if (_selectedLetter != null && _selectedLetter!.isNotEmpty) {
      String startAt = _selectedLetter!;
      String endAt =
          '${_selectedLetter!}\uf8ff'; // caractère élevé pour indiquer la fin

      query = query
          .where('lastName', isGreaterThanOrEqualTo: startAt)
          .where('lastName', isLessThanOrEqualTo: endAt);
    }

    query = query.orderBy('lastName').orderBy('firstName');
    return query;
  }

  // == Widget principal
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCharactersList(),
      ),
    );
  }

  // == Widget Liste des personnages
  Widget _buildCharactersList() {
    return Column(
      children: [
        _buildLetterSelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildCharactersQuery().snapshots(),
            // Utilise la requête dynamique
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                // Affiche l'erreur Firestore pour le débogage si nécessaire
                if (kDebugMode) {
                  print("Erreur Firestore: ${snapshot.error}");
                }
                return const Center(
                  child: Text('Quelque chose s\'est mal passé...'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    _selectedLetter == null
                        ? 'Aucun personnage trouvé.'
                        : 'Aucun personnage trouvé pour la lettre "$_selectedLetter".',
                  ),
                );
              }

              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = snapshot.data!.docs[index];
                  Character character = Character.fromFirestore(document);
                  return ListTile(
                    title: Text("${character.firstName} ${character.lastName}"),
                    leading: character.imageUrl.isNotEmpty
                        ? Image.network(
                            character.imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 50);
                            },
                          )
                        : const Icon(Icons.person, size: 50),
                    onTap: () {
                      if (kDebugMode) {
                        print(
                          'Tapped on ${character.firstName} (ID: ${character.id})',
                        );
                      }
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => CharacterDetailPage(character: character)));
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // == Widget Pagination alphabétique
  Widget _buildLetterSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedLetter == null
                      ? Theme.of(context)
                            .colorScheme
                            .primaryContainer // Couleur pour l'état sélectionné
                      : null, // Couleur par défaut
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: () {
                  setState(() {
                    _selectedLetter = null; // Réinitialiser le filtre
                  });
                },
                child: const Text('Tous'),
              ),
            ),
            // Boutons pour chaque lettre
            ..._alphabet.map((letter) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedLetter == letter
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(30, 30),
                    // Pour rendre les boutons plus petits
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedLetter = letter;
                    });
                  },
                  child: Text(letter),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
