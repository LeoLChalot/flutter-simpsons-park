import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart'; // Assurez-vous que c'est le bon chemin

import '../../../utils/routes.dart'; // Assurez-vous que c'est le bon chemin

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

  // Cette variable sera initialisée par le FutureBuilder
  String _userDisplayNameFromAttributes = ''; // Pour stocker le nom d'affichage récupéré

  bool _signArticle = false; // Renommé de _signWithEmail pour plus de clarté
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String? authorDisplayNameValue; // Utilisera le nom d'affichage
    if (_signArticle &&
        authService.isAuthenticated &&
        _userDisplayNameFromAttributes.isNotEmpty) { // Vérifier si le nom d'affichage est disponible
      authorDisplayNameValue = _userDisplayNameFromAttributes;
    }

    Map<String, dynamic> newspaperData = {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'body': _bodyController.text.trim(),
      // Utiliser un nom de champ plus approprié comme 'authorDisplayName' ou 'authorName'
      'authorDisplayName': authorDisplayNameValue,
      'createdAt': Timestamp.now(),
      // Vous pourriez aussi vouloir stocker l'UID de l'utilisateur pour référence,
      // même si vous affichez le displayName.
      // 'authorUid': authService.isAuthenticated ? authService.currentUser?.uid : null,
    };

    try {
      await FirebaseFirestore.instance
          .collection('newspapers')
          .add(newspaperData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Article "${_titleController.text}" ajouté avec succès !',
            ),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        _titleController.clear();
        _subtitleController.clear();
        _bodyController.clear();
        setState(() {
          _signArticle = false; // Réinitialiser la case à cocher
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
    final authService = Provider.of<AuthService>(context);

    // Gérer l'état de chargement initial d'AuthService
    if (authService.isLoading && !authService.isAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    // Gérer le cas où l'utilisateur n'est pas authentifié
    if (!authService.isAuthenticated || authService.cognitoUser == null) { // ou authService.currentUser == null si vous utilisez Firebase Auth directement
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Veuillez vous connecter pour ajouter un article.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(Routes.accessForm, (route) => false); // Assurez-vous que Routes.accessForm est correct
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserAttributes(), // Méthode pour obtenir les attributs utilisateur
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur de chargement du profil utilisateur : ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Impossible de récupérer les informations utilisateur.'),
          );
        }

        final userAttributes = snapshot.data!;
        // Assigner le nom d'affichage à notre variable d'état
        // Assurez-vous que 'name' est la bonne clé pour le displayName dans vos attributs utilisateur
        _userDisplayNameFromAttributes = userAttributes['name'] ?? 'Auteur inconnu';
        // final userEmail = userAttributes['email']?.toString() ?? 'Non fourni'; // Si vous en avez encore besoin ailleurs

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: <Widget>[
                Text(
                  'Ajouter un nouvel article',
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
                    prefixIcon: Icon(Icons.article_outlined),
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

                // La case à cocher ne s'affiche que si l'utilisateur est authentifié (déjà géré en amont)
                // et si le nom d'affichage a pu être récupéré.
                if (_userDisplayNameFromAttributes.isNotEmpty && _userDisplayNameFromAttributes != 'Auteur inconnu')
                  CheckboxListTile(
                    title: Text(
                      'Signer cet article en tant que "$_userDisplayNameFromAttributes"',
                    ),
                    value: _signArticle,
                    onChanged: _isLoading
                        ? null
                        : (bool? newValue) {
                      setState(() {
                        _signArticle = newValue ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: colorScheme.primary,
                  )
                else if (authService.isAuthenticated) // Si authentifié mais displayName non dispo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Impossible de récupérer votre nom d\'affichage pour signer l\'article.',
                      style: TextStyle(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                // Pas besoin de gérer les cas !authService.isAuthenticated ici, car le widget entier est remplacé.

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
      },
    );
  }
}