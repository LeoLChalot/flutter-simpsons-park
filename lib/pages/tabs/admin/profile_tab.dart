import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart'; // Votre AuthService pour Cognito
import 'package:simpsons_park/utils/routes.dart';
import 'package:simpsons_park/utils/simpsons_color_scheme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Pour le dialogue de changement de mot de passe
  final GlobalKey<FormState> _changePasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  bool _isLoadingChangePasswordDialog = false; // Pour le dialogue de changement de mot de passe
  bool _isLoadingDeleteAccountDialog = false; // Pour le dialogue de suppression de compte

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE CHANGEMENT DE MOT DE PASSE (ADAPTÉE POUR COGNITO) ---
  Future<void> _showChangePasswordDialog(BuildContext context, AuthService authService) async {
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
    authService.clearErrorMessage(); // Nettoyer les anciens messages d'erreur
    bool passwordChangedSuccessfully = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isLoadingChangePasswordDialog, // Empêcher la fermeture pendant le chargement
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: Form(
                key: _changePasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Ancien mot de passe',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre ancien mot de passe.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nouveau mot de passe.';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit comporter au moins 6 caractères.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmNewPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmer le nouveau mot de passe',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le nouveau mot de passe.';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Les mots de passe ne correspondent pas.';
                        }
                        return null;
                      },
                    ),
                    if (_isLoadingChangePasswordDialog) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                    // Afficher le message d'erreur de AuthService DANS le dialogue
                    Consumer<AuthService>( // Utiliser Consumer pour réagir aux changements d'errorMessage
                        builder: (context, auth, child) {
                          if (auth.errorMessage != null && !auth.isLoading) { // S'assurer que isLoading est celui d'AuthService
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(auth.errorMessage!, style: TextStyle(color: simpsonsTheme.colorScheme.error)),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isLoadingChangePasswordDialog ? null : () {
                    authService.clearErrorMessage();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: _isLoadingChangePasswordDialog ? null : () async {
                    if (_changePasswordFormKey.currentState!.validate()) {
                      setStateDialog(() => _isLoadingChangePasswordDialog = true);
                      // authService.clearErrorMessage(); // Déjà fait en entrant dans le dialogue et en annulant

                      bool success = await authService.changePassword(
                        _oldPasswordController.text,
                        _newPasswordController.text,
                      );
                      // Pas besoin de reconstruire le dialogue pour le message d'erreur si Consumer est utilisé
                      // Il se reconstruira si authService.errorMessage change
                      // setStateDialog((){}); // Peut être redondant avec Consumer

                      if (success) {
                        passwordChangedSuccessfully = true;
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(); // Fermer le dialogue en cas de succès
                      }
                      // Si !success, le message d'erreur sera affiché par le Consumer
                      setStateDialog(() => _isLoadingChangePasswordDialog = false); // Arrêter le chargement local du dialogue
                    }
                  },
                  child: const Text('Changer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (passwordChangedSuccessfully && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe mis à jour avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // --- LOGIQUE DE SUPPRESSION DE COMPTE ---
  Future<void> _showDeleteAccountConfirmationDialog(BuildContext context, AuthService authService) async {
    authService.clearErrorMessage();
    bool accountDeletedSuccessfully = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isLoadingDeleteAccountDialog, // Empêcher la fermeture pendant le chargement
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Supprimer le compte ?'),
            content: SingleChildScrollView( // Au cas où le message d'erreur est long
              child: ListBody(
                children: <Widget>[
                  const Text('Êtes-vous sûr de vouloir supprimer votre compte ?'),
                  const SizedBox(height: 8),
                  Text(
                    'Cette action est irréversible et toutes vos données associées à ce compte (profil, etc.) seront définitivement perdues.',
                    style: TextStyle(color: simpsonsTheme.colorScheme.error),
                  ),
                  if (_isLoadingDeleteAccountDialog) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  // Afficher le message d'erreur de AuthService DANS le dialogue
                  Consumer<AuthService>(
                      builder: (context, auth, child) {
                        if (auth.errorMessage != null && !auth.isLoading) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(auth.errorMessage!, style: TextStyle(color: simpsonsTheme.colorScheme.error)),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: _isLoadingDeleteAccountDialog ? null : () {
                  authService.clearErrorMessage();
                  Navigator.of(dialogContext).pop(); // Ferme simplement le dialogue
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: simpsonsTheme.colorScheme.error,
                  foregroundColor: simpsonsTheme.colorScheme.onError,
                ),
                onPressed: _isLoadingDeleteAccountDialog ? null : () async {
                  setStateDialog(() => _isLoadingDeleteAccountDialog = true);
                  // authService.clearErrorMessage(); // Déjà fait

                  // Supposant que deleteUserAccount existe dans AuthService
                  bool success = await authService.deleteUserAccount();

                  if (success) {
                    accountDeletedSuccessfully = true;
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(); // Fermer le dialogue en cas de succès
                  }
                  // Si !success, le message d'erreur sera affiché par le Consumer
                  setStateDialog(() => _isLoadingDeleteAccountDialog = false);
                },
                child: const Text('Supprimer Définitivement'),
              ),
            ],
          );
        });
      },
    );

    if (accountDeletedSuccessfully && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre compte a été supprimé avec succès.'),
          backgroundColor: Colors.green,
        ),
      );
      // Déconnecter l'utilisateur et rediriger
      // deleteUserAccount dans AuthService devrait idéalement gérer la session Cognito
      // mais une déconnexion explicite ici est une bonne pratique de fallback.
      await authService.signOut(); // Assurer la déconnexion
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(Routes.accessForm, (route) => false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.isLoading && !authService.isAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!authService.isAuthenticated || authService.cognitoUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Veuillez vous connecter pour voir votre profil.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil(Routes.accessForm, (route) => false);
              },
              child: const Text('Se connecter'),
            )
          ],
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserAttributes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur de chargement du profil : ${snapshot.error}'));
        }

        final userAttributes = snapshot.data ?? {};
        final userEmail = userAttributes.containsKey('email') ? userAttributes['email'].toString() : 'Non fourni';
        final displayName = userAttributes['name'] ?? '';
        final uid = authService.cognitoUser!.username;

        DateTime? lastSignInTime; // 'updated_at' est un proxy pour la dernière modification/activité
        if (userAttributes['updated_at'] != null) {
          try {
            // Cognito 'updated_at' est en secondes epoch, pas millisecondes.
            lastSignInTime = DateTime.fromMillisecondsSinceEpoch((int.parse(userAttributes['updated_at'].toString())) * 1000);
          } catch (e) {
            if (kDebugMode) { print("Error parsing updated_at: $e");}
          }
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: null, // TODO: Gérer photoUrl si disponible
                  backgroundColor: simpsonsTheme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: simpsonsTheme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayName.isNotEmpty) ...[
                        Text(
                          displayName,
                          style: simpsonsTheme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildUserInfoRow(
                        context: context,
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: userEmail,
                      ),
                      if (userAttributes['email_verified'] != null) ... [
                        const Divider(height: 20),
                        _buildUserInfoRow(
                          context: context,
                          icon: userAttributes['email_verified'].toString().toLowerCase() == 'true'
                              ? Icons.verified_user_outlined
                              : Icons.warning_amber_rounded,
                          label: 'Email vérifié',
                          value: userAttributes['email_verified'].toString().toLowerCase() == 'true' ? 'Oui' : 'Non',
                          valueColor: userAttributes['email_verified'].toString().toLowerCase() == 'true' ? Colors.green : Colors.orange,
                        ),
                      ],
                      const Divider(height: 20),
                      _buildUserInfoRow(
                        context: context,
                        icon: Icons.vpn_key_outlined,
                        label: 'User ID (sub/username)',
                        value: uid ?? 'Non fourni',
                      ),
                      if (lastSignInTime != null) ...[
                        const Divider(height: 20),
                        _buildUserInfoRow(
                          context: context,
                          icon: Icons.login_outlined,
                          label: 'Dernière modification du profil',
                          value: MaterialLocalizations.of(context).formatFullDate(lastSignInTime),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset_outlined),
                label: const Text('Modifier le mot de passe'),
                onPressed: () {
                  _showChangePasswordDialog(context, authService);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: simpsonsTheme.colorScheme.secondary,
                  foregroundColor: simpsonsTheme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                onPressed: () async {
                  await authService.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushNamedAndRemoveUntil(Routes.accessForm, (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: simpsonsTheme.colorScheme.errorContainer, // Un peu moins agressif
                  foregroundColor: simpsonsTheme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12), // Espacement avant le nouveau bouton
              OutlinedButton.icon( // Utiliser OutlinedButton pour le différencier visuellement
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Supprimer mon compte'),
                onPressed: () {
                  _showDeleteAccountConfirmationDialog(context, authService);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: simpsonsTheme.colorScheme.error,
                  side: BorderSide(color: simpsonsTheme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: simpsonsTheme.colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Text('$label: ', style: simpsonsTheme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            value,
            style: simpsonsTheme.textTheme.bodyMedium?.copyWith(color: valueColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}