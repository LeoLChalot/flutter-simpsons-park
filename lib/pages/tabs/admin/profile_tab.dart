import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:simpsons_park/utils/routes.dart';
import 'package:simpsons_park/utils/simpsons_color_scheme.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final GlobalKey<FormState> _currentPasswordFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _newPasswordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    User currentUser,
  ) async {
    // Demander le mot de passe actuel pour re-authentification
    bool? reauthenticated = false;
    bool isLoadingReauth = false;

    // Nettoyer les _variables privées du formulaire
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    reauthenticated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Statful pour l'état de chargement à l'intérieur du dialogue
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Vérification de sécurité'),
              content: Form(
                key: _currentPasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Veuillez entrer votre mot de passe actuel pour continuer.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe actuel',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre mot de passe actuel.';
                        }
                        return null;
                      },
                    ),
                    if (isLoadingReauth) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                // Bouton d'annulation
                TextButton(
                  onPressed: isLoadingReauth
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Annuler'),
                ),
                // Bouton de confirmation
                ElevatedButton(
                  onPressed: isLoadingReauth
                      ? null
                      : () async {
                          if (_currentPasswordFormKey.currentState!
                              .validate()) {
                            setStateDialog(() => isLoadingReauth = true);
                            try {
                              AuthCredential credential =
                                  EmailAuthProvider.credential(
                                    email: currentUser.email!,
                                    password: _currentPasswordController.text,
                                  );
                              await currentUser.reauthenticateWithCredential(
                                credential,
                              );
                              if (!dialogContext.mounted) return;
                              Navigator.of(dialogContext).pop(true);
                            } on FirebaseAuthException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.code == 'wrong-password' ||
                                            e.code == 'ERROR_WRONG_PASSWORD'
                                        ? 'Mot de passe actuel incorrect.'
                                        : 'Erreur de re-authentification: ${e.code}',
                                  ),
                                  backgroundColor:
                                      simpsonsTheme.colorScheme.error,
                                ),
                              );
                              Navigator.of(dialogContext).pop(false);
                            } finally {
                              if (mounted) {
                                setStateDialog(() => isLoadingReauth = false);
                                _currentPasswordController.clear();
                              }
                            }
                          }
                        },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    if (reauthenticated != true) {
      return;
    }

    // Demander le nouveau mot de passe
    if (!context.mounted) return;
    bool? passwordChanged = false;
    bool isLoadingNewPassword = false;

    passwordChanged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Changer le mot de passe'),
              content: Form(
                key: _newPasswordFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                    if (isLoadingNewPassword) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                // Bouton d'annulation
                TextButton(
                  onPressed: isLoadingNewPassword
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: Text('Annuler'),
                ),
                // Bouton de confirmation
                ElevatedButton(
                  onPressed: isLoadingNewPassword
                      ? null
                      : () async {
                          if (_newPasswordFormKey.currentState!.validate()) {
                            setStateDialog(() => isLoadingNewPassword = true);
                            try {
                              await currentUser.updatePassword(
                                _newPasswordController.text,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mot de passe mis à jour avec succès !',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(dialogContext).pop(true);
                            } on FirebaseAuthException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: ${e.message}'),
                                  backgroundColor:
                                      simpsonsTheme.colorScheme.error,
                                ),
                              );
                              // On ne ferme pas le dialogue pour permettre de réessayer ou de corriger
                              setStateDialog(
                                () => isLoadingNewPassword = false,
                              ); // Réactiver les boutons
                            } finally {
                              _newPasswordController.clear();
                              _confirmNewPasswordController.clear();
                            }
                          } else {
                            // Si la validation du formulaire échoue, ne rien faire d'asynchrone.
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

    // Déconnexion après le changement du mot de passe
    if (passwordChanged == true) {
      if (!context.mounted) return;
      await showDialog<void>(
        context: context, // Utiliser le context de ProfileTab
        barrierDismissible: false, // L'utilisateur doit cliquer sur OK
        builder: (BuildContext alertContext) {
          // Contexte différent pour ce dialogue
          return AlertDialog(
            title: Text('Changement de mot de passe réussi'),
            content: Text(
              'Vous allez être déconnecté. Merci de vous reconnecter avec votre nouveau mot de passe.',
            ),
            actions: <Widget>[
              // Bouton OK
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(
                    alertContext,
                  ).pop(); // Ferme cette popup d'information
                },
              ),
            ],
          );
        },
      );

      if (mounted) {
        setState(
          () => _isLoading = true,
        );
        try {
          await FirebaseAuth.instance.signOut();
          if (!context.mounted) return;
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.accessForm,
            (Route<dynamic> route) => false,
          );
        } catch (e) {
          if (kDebugMode) {
            print("Erreur lors de la déconnexion finale : $e");
          }
        } finally {
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }

        if (snapshot.hasData && snapshot.data != null) {
          final User user = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        user.photoURL != null && user.photoURL!.isNotEmpty
                        ? NetworkImage(user.photoURL!)
                        : null,
                    backgroundColor: simpsonsTheme.colorScheme.primaryContainer,
                    child: (user.photoURL == null || user.photoURL!.isEmpty)
                        ? Icon(
                            Icons.person,
                            size: 50,
                            color: simpsonsTheme.colorScheme.onPrimaryContainer,
                          )
                        : null,
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
                        if (user.displayName != null &&
                            user.displayName!.isNotEmpty) ...[
                          Text(
                            user.displayName!,
                            style: simpsonsTheme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _buildUserInfoRow(
                          context: context,
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email ?? 'Non fourni',
                        ),
                        const Divider(height: 20),
                        _buildUserInfoRow(
                          context: context,
                          icon: Icons.vpn_key_outlined,
                          label: 'User ID (UID)',
                          value: user.uid,
                        ),
                        if (user.metadata.creationTime != null) ...[
                          const Divider(height: 20),
                          _buildUserInfoRow(
                            context: context,
                            icon: Icons.date_range_outlined,
                            label: 'Compte créé le',
                            value: MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(user.metadata.creationTime!),
                          ),
                        ],
                        if (user.metadata.lastSignInTime != null) ...[
                          const Divider(height: 20),
                          _buildUserInfoRow(
                            context: context,
                            icon: Icons.login_outlined,
                            label: 'Dernière connexion',
                            value: MaterialLocalizations.of(
                              context,
                            ).formatFullDate(user.metadata.lastSignInTime!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_reset_outlined),
                  label: const Text('Modifier mon mot de passe'),
                  onPressed: _isLoading
                      ? null
                      : () => _showChangePasswordDialog(context, user),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Se Déconnecter'),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(
                            () => _isLoading = true,
                          ); // Démarre le chargement
                          try {
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                Routes.accessForm,
                                (Route<dynamic> route) => false,
                              );

                          } catch (e) {
                            if (kDebugMode) {
                              print(
                                "Erreur pendant la déconnexion depuis le bouton profil: $e",
                              );
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Erreur de déconnexion: ${e.toString()}",
                                ),
                                backgroundColor:
                                    simpsonsTheme.colorScheme.error,
                              ),
                            );
                            setState(() => _isLoading = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: simpsonsTheme.colorScheme.errorContainer,
                    foregroundColor: simpsonsTheme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Aucun utilisateur connecté.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Se connecter'),
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.accessForm,
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildUserInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: simpsonsTheme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: simpsonsTheme.textTheme.bodySmall?.copyWith(
                    color: simpsonsTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(value, style: simpsonsTheme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
