import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart';

import '../../../utils/routes.dart';

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

  bool _signWithEmail = false;
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

    String? authorEmailValue;
    if (_signWithEmail &&
        authService.isAuthenticated &&
        authService.userEmail != null) {
      authorEmailValue = authService.userEmail;
    }

    Map<String, dynamic> newspaperData = {
      'title': _titleController.text.trim(),
      'subtitle': _subtitleController.text.trim(),
      'body': _bodyController.text.trim(),
      'authorEmail': authorEmailValue,
      'createdAt': Timestamp.now(),
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
    final authService = Provider.of<AuthService>(context);
    if (authService.isLoading && !authService.isAuthenticated) {
      // Afficher un indicateur de chargement si AuthService est en train de charger l'état initial
      // et que l'utilisateur n'est pas encore authentifié.
      return const Center(child: CircularProgressIndicator());
    }
    if (!authService.isAuthenticated || authService.cognitoUser == null) {
      // Si l'utilisateur n'est pas authentifié, afficher un message ou rediriger.
      // Normalement, AuthWrapper devrait empêcher d'arriver ici si non authentifié.
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Veuillez vous connecter pour accéder aux formulaires.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(Routes.accessForm, (route) => false);
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
      future: authService.getUserAttributes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur de chargement du profil : ${snapshot.error}'),
          );
        }

        final userAttributes = snapshot.data ?? {};
        final userEmail = userAttributes.containsKey('email')
            ? userAttributes['email'].toString()
            : 'Non fourni';
        DateTime? lastSignInTime;
        if (userAttributes['updated_at'] != null) {
          try {
            lastSignInTime = DateTime.fromMillisecondsSinceEpoch((int.tryParse(userAttributes['updated_at'].toString()) ?? 0) * 1000);
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing updated_at: $e");
            }
          }
        }
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

                if (authService.isAuthenticated)
                  CheckboxListTile(
                    title: Text(
                      // Utiliser authService.userEmail
                      'Signer cet article ($userEmail)',
                    ),
                    value: _signWithEmail,
                    onChanged:
                    _isLoading // Désactiver si en cours de chargement pour éviter des états incohérents
                        ? null
                        : (bool? newValue) {
                      setState(() {
                        _signWithEmail = newValue ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: colorScheme.primary,
                  )
                else if (!authService.isAuthenticated && !authService.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Vous devez être connecté pour pouvoir signer l\'article.',
                      style: TextStyle(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                  )
                else if (authService.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
      },
    );


  }
}
