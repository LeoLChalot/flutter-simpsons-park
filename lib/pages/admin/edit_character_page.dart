import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:simpsons_park/models/character_model.dart'; // Assurez-vous que le chemin est correct

class EditCharacterPage extends StatefulWidget {
  final Character character;

  const EditCharacterPage({super.key, required this.character});

  @override
  State<EditCharacterPage> createState() => _EditCharacterPageState();
}

class _EditCharacterPageState extends State<EditCharacterPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Contrôleurs pour les champs du formulaire
  late TextEditingController _nameController;
  late TextEditingController _pseudoController;
  // late TextEditingController _imageUrlController;
  late TextEditingController _descriptionController;
  late TextEditingController _functionsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.character.name);
    _pseudoController = TextEditingController(text: widget.character.pseudo);
    // _imageUrlController = TextEditingController(text: widget.character.imageUrl);
    _descriptionController = TextEditingController(text: widget.character.description);
    _functionsController = TextEditingController(text: widget.character.function);

  }

  @override
  void dispose() {
    _nameController.dispose();
    _pseudoController.dispose();
    // _imageUrlController.dispose();
    _descriptionController.dispose();
    _functionsController.dispose();
    super.dispose();
  }

  Future<void> _saveCharacterChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'pseudo': _pseudoController.text.trim(),
        // 'imageUrl': _imageUrlController.text.trim(),
        'description': _descriptionController.text.trim(),
        'firstAppearance': _functionsController.text.trim(),
      };

      // Mettre à jour le document dans Firestore
      await FirebaseFirestore.instance
          .collection('characters')
          .doc(widget.character.id)
          .update(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.character.name} mis à jour avec succès !'),
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
        title: Text('Modifier ${widget.character.name.isNotEmpty ? widget.character.name : "Personnage"}'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCharacterChanges,
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
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du personnage',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Veuillez entrer un nom pour le personnage.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pseudoController,
                decoration: const InputDecoration(
                  labelText: 'Pseudo (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
             // TextFormField(
             //   controller: _imageUrlController,
             //   decoration: const InputDecoration(
             //     labelText: 'URL de l\'image (Optionnel)',
             //     border: OutlineInputBorder(),
             //     prefixIcon: Icon(Icons.image_outlined),
             //   ),
             //   keyboardType: TextInputType.url,
             // ),
             // const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                maxLines: 4, // Pour un champ de texte plus grand
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _functionsController,
                decoration: const InputDecoration(
                  labelText: 'Fonction(s) (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.history_edu_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isLoading ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,)) : const Icon(Icons.save_alt_outlined),
                label: Text(_isLoading ? 'Enregistrement...' : 'Enregistrer les modifications'),
                onPressed: _isLoading ? null : _saveCharacterChanges,
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