import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/character_model.dart';
import 'package:simpsons_park/pages/character_detail_page.dart';

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
      String startAt = _selectedLetter!;
      String endAt = '${_selectedLetter!}\uf8ff';

      query = query
          .where('name', isGreaterThanOrEqualTo: startAt)
          .where('name', isLessThanOrEqualTo: endAt);
    }

    query = query.orderBy('name');
    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCharactersListWithFilter(),
      ),
    );
  }

  Widget _buildCharactersListWithFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLetterSelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildCharactersQuery().snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                if (kDebugMode) {
                  print("Erreur Firestore (CharactersTab): ${snapshot.error}");
                }
                return const Center(
                  child: Text('Quelque chose s\'est mal passé lors du chargement des personnages.'),
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
                  final Character character = characters[index];

                  String characterDisplayName = character.name.trim();
                  if (characterDisplayName.isEmpty) {
                    characterDisplayName = character.pseudo.isNotEmpty ? character.pseudo : "Personnage inconnu";
                  }

                  return ListTile(
                    title: Text(characterDisplayName),
                    leading: character.imageUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        character.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                              width: 50, height: 50,
                              color: Colors.grey[200],
                              child: const Icon(Icons.person, size: 30, color: Colors.grey)
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                              width: 50, height: 50,
                              color: Colors.grey[200],
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2,))
                          );
                        },
                      ),
                    )
                        : Container(
                        width: 50, height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person, size: 30, color: Colors.grey)
                    ),
                    onTap: () {
                      if (kDebugMode) {
                        print(
                          'Tapped on $characterDisplayName (ID: ${character.id})',
                        );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharacterDetailPage(character: character),
                        ),
                      );
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
    // Ton widget _buildLetterSelector est déjà bien configuré
    // pour mettre à jour _selectedLetter avec des majuscules.
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
                      : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}), // Couleur par défaut du thème
                  foregroundColor: _selectedLetter == null
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              final bool isSelected = _selectedLetter == letter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).elevatedButtonTheme.style?.backgroundColor?.resolve({}),
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(30, 30),
                    textStyle: const TextStyle(fontSize: 14),
                    // elevation: isSelected ? 4 : 1, // Optionnel: pour un effet visuel
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