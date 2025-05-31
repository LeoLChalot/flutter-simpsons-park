// lib/widgets/form_newspaper_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importer le modèle si tu l'as mis dans un fichier séparé
// import '../models/newspaper_model.dart'; // Adapte le chemin si nécessaire

class FormNewspaperWidget extends StatefulWidget {
  const FormNewspaperWidget({super.key});

  @override
  State<FormNewspaperWidget> createState() => _FormNewspaperWidgetState();
}

class _FormNewspaperWidgetState extends State<FormNewspaperWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _signWithEmail = false; // État de la checkbox
  bool _isLoading =
      false; // Pour l'indicateur de chargement lors de la soumission

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return; // Ne rien faire si le formulaire n'est pas valide
    }

    if (_isLoading) return; // Éviter les soumissions multiples

    setState(() {
      _isLoading = true;
    });

    String? authorEmailValue;
    if (_signWithEmail && _currentUser != null) {
      authorEmailValue = _currentUser!.email;
    }

    // Création de l'objet ou du Map à envoyer à Firestore
    Map<String, dynamic> newspaperData = {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'body': _bodyController.text.trim(),
      'authorEmail': authorEmailValue, // Peut être null
      'createdAt': Timestamp.now(), // Date et heure actuelles
    };

    try {
      await FirebaseFirestore.instance
          .collection('newspapers')
          .add(newspaperData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Article ${_titleController.text} ajouté avec succès !',
            ),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        _titleController.clear();
        _subtitleController.clear();
        _bodyController.clear();
        setState(() {
          _signWithEmail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout de l\'article : $e'),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            Text(
              'Qu',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de l\'article',
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
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Sous-titre (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subtitles_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Contenu de l\'article',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 217),
                  child: Icon(Icons.article_outlined),
                ),
              ),
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer le contenu de l\'article.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_currentUser != null)
              CheckboxListTile(
                title: Text(
                  'Signer cet article avec mon email (${_currentUser!.email})',
                ),
                value: _signWithEmail,
                onChanged: (bool? newValue) {
                  setState(() {
                    _signWithEmail = newValue ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: colorScheme.primary,
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Vous devez être connecté pour pouvoir signer l\'article.',
                  style: TextStyle(color: theme.hintColor),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: _isLoading
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2.0),
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(
                _isLoading ? 'Envoi en cours...' : 'Ajouter l\'article',
              ),
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
