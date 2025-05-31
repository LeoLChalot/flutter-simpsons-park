import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/character_model.dart';

class CharactersTab extends StatefulWidget {
  const CharactersTab({super.key});

  @override
  State<CharactersTab> createState() => _CharactersTabState();
}

class _CharactersTabState extends State<CharactersTab> {
  String? _selectedLetter;

  final List<String> _alphabet = List.generate(
    26,
    (index) => String.fromCharCode('A'.codeUnitAt(0) + index),
  );

  Query _buildCharactersQuery() {
    Query query = FirebaseFirestore.instance.collection('characters');

    if (_selectedLetter != null && _selectedLetter!.isNotEmpty) {
      query = query.where(
        'searchInitials',
        arrayContains: _selectedLetter!.toUpperCase(),
      );
    }
    query = query.orderBy('lastName').orderBy('firstName');
    return query;
  }

  @override
  Widget build(BuildContext context) {
    // Renommer la méthode pour la cohérence
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCharactersListWithFilter(),
      ),
    );
  }

  Widget _buildCharactersListWithFilter() {
    return Column(
      children: [
        _buildLetterSelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildCharactersQuery().snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
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

              List<Character> characters = snapshot.data!.docs
                  .map(
                    (doc) => Character.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    ),
                  )
                  .toList();

              return ListView.builder(
                itemCount: characters.length,
                itemBuilder: (context, index) {
                  Character character = characters[index];

                  String characterFullName =
                      (character.firstName == '' || character.lastName == '')
                      ? ''
                      : '${character.firstName} ${character.lastName}';
                  String characterTitle = characterFullName == ''
                      ? character.pseudo
                      : characterFullName;

                  return ListTile(
                    title: Text(
                      characterTitle.isEmpty ? "Nom inconnu" : characterTitle,
                    ),
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

  Widget _buildLetterSelector() {
    // ... (ton code _buildLetterSelector reste inchangé)
    // Assure-toi juste que la lettre sélectionnée est bien passée en MAJUSCULES à la requête
    // ou que _selectedLetter est toujours une majuscule.
    // Si _alphabet produit des majuscules, c'est bon.
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
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                onPressed: () {
                  setState(() {
                    _selectedLetter = null;
                  });
                },
                child: const Text('Tous'),
              ),
            ),
            ..._alphabet.map((letter) {
              // _alphabet contient déjà des majuscules
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
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedLetter = letter; // letter est déjà une majuscule
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
