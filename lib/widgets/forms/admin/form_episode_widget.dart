import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/season_model.dart'; // Assurez-vous que ce modèle existe et est correct

// Modèle Episode (simplifié pour cet exemple, adaptez selon votre modèle Episode réel)
// Vous devriez avoir un modèle Episode.dart complet.
// class Episode {
//   final String title;
//   final int episodeNumber;
//   final String description;
//   final String imageUrl;
//   final String releaseDate;
//   final String duration;
//   Episode({required this.title, required this.episodeNumber, /* ...autres champs... */});
// }

class FormEpisodeWidget extends StatefulWidget {
  const FormEpisodeWidget({super.key});

  @override
  State<FormEpisodeWidget> createState() => _FormEpisodeWidgetState();
}

class _FormEpisodeWidgetState extends State<FormEpisodeWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Contrôleurs pour les champs de l'épisode
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _episodeNumberController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _releaseDateController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Gestion de la sélection/création de saison
  List<Season> _existingSeasons = [];
  Season? _selectedSeason; // Pour le DropdownMenuItem, stocke l'objet Season
  String? _selectedSeasonId; // Pour stocker l'ID si une saison existante est choisie
  bool _isLoadingSeasons = true;
  bool _createNewSeason = false;
  final TextEditingController _newSeasonNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExistingSeasons();
  }

  Future<void> _fetchExistingSeasons() async {
    setState(() {
      _isLoadingSeasons = true;
    });
    try {
      QuerySnapshot seasonSnapshot = await FirebaseFirestore.instance
          .collection('seasons')
          .orderBy('seasonNumber')
          .get();
      _existingSeasons = seasonSnapshot.docs
          .map((doc) => Season.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des saisons : ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSeasons = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _episodeNumberController.dispose();
    _imageUrlController.dispose();
    _releaseDateController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _newSeasonNumberController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    String targetSeasonId;
    int newEpisodeNumber;

    try {
      newEpisodeNumber = int.parse(_episodeNumberController.text.trim());

      if (_createNewSeason) {
        // Créer une nouvelle saison
        if (_newSeasonNumberController.text.trim().isEmpty) {
          throw Exception('Le numéro de la nouvelle saison est requis.');
        }
        final int newSeasonNum = int.parse(_newSeasonNumberController.text.trim());

        // Optionnel: Vérifier si une saison avec ce numéro existe déjà pour éviter les doublons stricts
        // QuerySnapshot existingSeasonQuery = await FirebaseFirestore.instance
        //     .collection('seasons')
        //     .where('seasonNumber', isEqualTo: newSeasonNum)
        //     .limit(1)
        //     .get();
        // if (existingSeasonQuery.docs.isNotEmpty) {
        //   throw Exception('Une saison avec le numéro $newSeasonNum existe déjà.');
        // }

        DocumentReference newSeasonRef = await FirebaseFirestore.instance.collection('seasons').add({
          'seasonNumber': newSeasonNum,
          'name': 'Saison $newSeasonNum', // Nom auto-généré, vous pouvez ajouter un champ pour cela
          'episodesCount': 0, // Sera incrémenté
          'createdAt': FieldValue.serverTimestamp(), // Optionnel: pour trier par date de création
        });
        targetSeasonId = newSeasonRef.id;
      } else {
        // Utiliser une saison existante
        if (_selectedSeasonId == null) {
          throw Exception('Veuillez sélectionner une saison ou en créer une nouvelle.');
        }
        targetSeasonId = _selectedSeasonId!;
      }

      // Préparer les données de l'épisode
      Map<String, dynamic> episodeData = {
        'title': _titleController.text.trim(),
        'episodeNumber': newEpisodeNumber,
        'imageUrl': _imageUrlController.text.trim(),
        'releaseDate': _releaseDateController.text.trim(),
        'duration': _durationController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Optionnel
        // Assurez-vous que tous les champs requis par votre modèle Episode sont ici
      };

      // Ajouter l'épisode à la sous-collection de la saison cible
      await FirebaseFirestore.instance
          .collection('seasons')
          .doc(targetSeasonId)
          .collection('episodes')
          .add(episodeData);

      // Mettre à jour le compteur d'épisodes de la saison
      await FirebaseFirestore.instance
          .collection('seasons')
          .doc(targetSeasonId)
          .update({'episodesCount': FieldValue.increment(1)});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Épisode ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _titleController.clear();
        _episodeNumberController.clear();
        _imageUrlController.clear();
        _releaseDateController.clear();
        _durationController.clear();
        _descriptionController.clear();
        _newSeasonNumberController.clear();
        setState(() {
          _selectedSeasonId = null;
          _selectedSeason = null;
          _createNewSeason = false;
        });
        _fetchExistingSeasons(); // Rafraîchir la liste des saisons au cas où une nouvelle a été ajoutée
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'épisode : ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Text('Ajouter un Nouvel Épisode', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),

            // Sélection de la saison ou création
            if (_isLoadingSeasons)
              const Center(child: CircularProgressIndicator())
            else ...[
              DropdownButtonFormField<Season>(
                value: _selectedSeason,
                hint: const Text('Sélectionner une saison existante'),
                isExpanded: true,
                items: _existingSeasons.map<DropdownMenuItem<Season>>((Season season) {
                  return DropdownMenuItem<Season>(
                    value: season,
                    child: Text('Saison ${season.seasonNumber}${season.name.isNotEmpty ? " - ${season.name}" : ""}'),
                  );
                }).toList(),
                onChanged: _createNewSeason ? null : (Season? newValue) {
                  setState(() {
                    _selectedSeason = newValue;
                    _selectedSeasonId = newValue?.id;
                  });
                },
                validator: (value) {
                  if (!_createNewSeason && value == null) {
                    return 'Veuillez sélectionner une saison.';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Saison Existante',
                  border: OutlineInputBorder(),
                ),
                disabledHint: _createNewSeason ? const Text("Création d'une nouvelle saison activée") : null,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text("Ou créer une nouvelle saison ?"),
                value: _createNewSeason,
                onChanged: (bool? value) {
                  setState(() {
                    _createNewSeason = value ?? false;
                    if (_createNewSeason) {
                      _selectedSeason = null; // Désélectionner la saison existante
                      _selectedSeasonId = null;
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_createNewSeason) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newSeasonNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de la Nouvelle Saison',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.fiber_new_outlined),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_createNewSeason) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Entrez un numéro pour la nouvelle saison.';
                      }
                      if (int.tryParse(value.trim()) == null) {
                        return 'Numéro invalide.';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'épisode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un titre.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _episodeNumberController,
              decoration: const InputDecoration(
                labelText: 'Numéro de l\'épisode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.format_list_numbered),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un numéro d\'épisode.';
                }
                if (int.tryParse(value.trim()) == null) {
                  return 'Numéro invalide.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL de l\'image (Optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.image_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _releaseDateController,
              decoration: const InputDecoration(
                labelText: 'Date de sortie (ex: 2023-10-26)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Durée (ex: 22 min)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isSaving
                  ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isSaving ? 'Ajout en cours...' : 'Ajouter l\'Épisode'),
              onPressed: _isSaving ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}