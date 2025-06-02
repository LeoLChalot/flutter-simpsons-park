import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/episode_model.dart'; // Assurez-vous que le chemin est correct

class EditEpisodePage extends StatefulWidget {
  final String seasonId; // ID de la saison parente
  final Episode episode;

  const EditEpisodePage({
    super.key,
    required this.seasonId,
    required this.episode,
  });

  @override
  State<EditEpisodePage> createState() => _EditEpisodePageState();
}

class _EditEpisodePageState extends State<EditEpisodePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _episodeNumberController;
  // late TextEditingController _imageUrlController;
  late TextEditingController _releaseDateController;
  late TextEditingController _durationController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.episode.title);
    _episodeNumberController = TextEditingController(text: widget.episode.episodeNumber.toString());
    // _imageUrlController = TextEditingController(text: widget.episode.imageUrl);
    _releaseDateController = TextEditingController(text: widget.episode.releaseDate);
    _durationController = TextEditingController(text: widget.episode.duration);
    _descriptionController = TextEditingController(text: widget.episode.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _episodeNumberController.dispose();
    // _imageUrlController.dispose();
    _releaseDateController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveEpisodeChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int? episodeNumber = int.tryParse(_episodeNumberController.text.trim());
      if (episodeNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Le numéro de l\'épisode doit être un nombre valide.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      // Préparer les données à mettre à jour
      Map<String, dynamic> updatedData = {
        'title': _titleController.text.trim(),
        'episodeNumber': episodeNumber,
        // 'imageUrl': _imageUrlController.text.trim(),
        'releaseDate': _releaseDateController.text.trim(),
        'duration': _durationController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      // Mettre à jour le document de l'épisode dans Firestore
      await FirebaseFirestore.instance
          .collection('seasons')
          .doc(widget.seasonId) // Utiliser l'ID de la saison
          .collection('episodes')
          .doc(widget.episode.id) // Utiliser l'ID de l'épisode
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Épisode "${widget.episode.title}" mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour : ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier: ${widget.episode.title.isNotEmpty ? widget.episode.title : "Épisode"}'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveEpisodeChanges,
              tooltip: 'Enregistrer les modifications',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre de l\'épisode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un titre pour l\'épisode.';
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
                    return 'Veuillez entrer un numéro pour l\'épisode.';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Veuillez entrer un nombre valide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // TextFormField(
              //  controller: _imageUrlController,
              //  decoration: const InputDecoration(
              //    labelText: 'URL de l\'image (Optionnel)',
              //    border: OutlineInputBorder(),
              //    prefixIcon: Icon(Icons.image_outlined),
              //  ),
              //  keyboardType: TextInputType.url,
              // ),
              // const SizedBox(height: 16),
              TextFormField(
                controller: _releaseDateController,
                decoration: const InputDecoration(
                  labelText: 'Date de sortie (yyyy-mm-dd)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer une date de sortie pour l\'épisode.';
                  }
                  // Vous devrez vérifier le format de la date ici
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value.trim())) {
                    return 'Veuillez entrer une date au format YYYY-MM-DD.';
                  }
                  return null;
                }
                // Vous pourriez utiliser un DatePicker ici pour une meilleure UX
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Durée (ex: 20\'00)',
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
                maxLines: 5, // Pour un champ de texte plus grand
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Icon(Icons.save_alt_outlined),
                label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
                onPressed: _isLoading ? null : _saveEpisodeChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}