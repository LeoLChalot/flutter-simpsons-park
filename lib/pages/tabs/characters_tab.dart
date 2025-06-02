import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/models/character_model.dart';
import 'package:simpsons_park/pages/character_detail_page.dart';

import 'package:simpsons_park/services/auth_service.dart';

import '../admin/edit_character_page.dart';
// TODO: Importez votre page/widget de modification de personnage ici

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

  bool _isUserAuthenticated(BuildContext context) {
    return context.read<AuthService>().isAuthenticated; //
  }

  Future<void> _deleteCharacter(
    BuildContext context,
    Character character,
  ) async {
    if (!_isUserAuthenticated(context)) {
      //
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez être connecté pour supprimer un personnage.',
          ),
        ),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('characters')
          .doc(character.id)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${character.name} supprimé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur lors de la suppression de ${character.name}: $e',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      if (kDebugMode) {
        print("Erreur Firestore (deleteCharacter): $e");
      }
    }
  }

  void _navigateToEditCharacter(BuildContext context, Character character) {
    if (!_isUserAuthenticated(context)) {
      //
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vous devez être connecté pour modifier un personnage.',
          ),
        ),
      );
      return;
    }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Navigation vers la page de modification pour ${character.name}',
        ),
      ),
    );
    if (kDebugMode) {
      print(
        'Naviguer pour modifier le personnage: ${character.name} (ID: ${character.id})',
      );
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditCharacterPage(character: character), // Passer le personnage ici
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
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
                  print(
                    "Erreur Firestore (CharactersTab StreamBuilder): ${snapshot.error}",
                  );
                }
                return const Center(
                  child: Text(
                    'Quelque chose s\'est mal passé lors du chargement des personnages.',
                  ),
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
                    characterDisplayName = character.pseudo.isNotEmpty
                        ? character.pseudo
                        : "Personnage inconnu";
                  }

                  // Ecouteur d'authentification pour savoir si l'utilisateur est connecté
                  final bool isAuthenticated = context
                      .watch<AuthService>()
                      .isAuthenticated;

                  // Déterminer la direction du Dismissible en fonction de l'état d'authentification
                  final DismissDirection itemDismissDirection = isAuthenticated
                      ? DismissDirection.horizontal
                      : DismissDirection.none;

                  return Dismissible(
                    key: Key(character.id),
                    direction: itemDismissDirection,
                    background: _buildSwipeActionLeft(),
                    secondaryBackground: _buildSwipeActionRight(),
                    confirmDismiss: (direction) async {
                      //
                      if (!_isUserAuthenticated(context)) {
                        return false;
                      }
                      if (direction == DismissDirection.startToEnd) {
                        //
                        _navigateToEditCharacter(context, character);
                        return false;
                      } else if (direction == DismissDirection.endToStart) {
                        //
                        return await showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text('Confirmer la suppression'),
                                  content: Text(
                                    'Voulez-vous vraiment supprimer $characterDisplayName?',
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Annuler'),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(false);
                                      },
                                    ),
                                    TextButton(
                                      child: Text(
                                        'Supprimer',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop(true);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      //
                      if (!_isUserAuthenticated(context)) return; //
                      if (direction == DismissDirection.endToStart) {
                        //
                        _deleteCharacter(context, character);
                      }
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 4.0,
                      ),
                      elevation: 2.0,
                      child: ListTile(
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
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey,
                                ),
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
                              builder: (context) =>
                                  CharacterDetailPage(character: character),
                            ),
                          );
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
    );
  }

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
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context)
                            .elevatedButtonTheme
                            .style
                            ?.backgroundColor
                            ?.resolve({}),
                  foregroundColor: _selectedLetter == null
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context)
                            .elevatedButtonTheme
                            .style
                            ?.foregroundColor
                            ?.resolve({}),
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
              final bool isSelected = _selectedLetter == letter;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.backgroundColor
                              ?.resolve({}),
                    foregroundColor: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context)
                              .elevatedButtonTheme
                              .style
                              ?.foregroundColor
                              ?.resolve({}),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(30, 30),
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

  Widget _buildSwipeActionLeft() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.blueAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.edit, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Modifier',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeActionRight() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.redAccent,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Supprimer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 10),
          Icon(Icons.delete_sweep, color: Colors.white),
        ],
      ),
    );
  }
}
