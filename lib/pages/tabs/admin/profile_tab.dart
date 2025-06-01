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

  bool _isLoadingDialog = false; // Pour le dialogue de changement de mot de passe

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
    bool passwordChangedSuccessfully = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // StatefulBuilder pour gérer l'état de chargement à l'intérieur du dialogue
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
                        if (value.length < 6) { // Conservez vos règles de complexité
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
                    if (_isLoadingDialog) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                    if (authService.errorMessage != null && !authService.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(authService.errorMessage!, style: TextStyle(color: simpsonsTheme.colorScheme.error)),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: _isLoadingDialog ? null : () {
                    authService.clearErrorMessage();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: _isLoadingDialog ? null : () async {
                    if (_changePasswordFormKey.currentState!.validate()) {
                      setStateDialog(() => _isLoadingDialog = true);
                      authService.clearErrorMessage();

                      bool success = await authService.changePassword(
                        _oldPasswordController.text,
                        _newPasswordController.text,
                      );
                      setStateDialog(() => _isLoadingDialog = false);

                      if (success) {
                        passwordChangedSuccessfully = true;
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop();
                      } else {
                        // setStateDialog est nécessaire pour reconstruire le dialogue et montrer l'erreur
                        setStateDialog((){});
                      }
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
          content: Text('Mot de passe mis à jour avec succès ! Il peut être nécessaire de vous reconnecter.'),
          backgroundColor: Colors.green,
        ),
      );
      // Avec Cognito, l'utilisateur n'est généralement PAS déconnecté
      // automatiquement après un changement de mot de passe.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter AuthService pour l'état d'authentification et les détails de l'utilisateur
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

    // L'utilisateur est authentifié, utiliser FutureBuilder pour obtenir les attributs
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
        // Pour Cognito, le "displayName" est souvent l'attribut 'name'.
        // L'UID est le 'sub' (subject) dans les jetons Cognito, ou le username.
        final displayName = userAttributes['name'] ?? '';
        final uid = authService.cognitoUser!.username; // ou userAttributes['sub'] si vous préférez

        // Pour les dates, Cognito les stocke généralement en tant que timestamps ou chaînes ISO.
        // Vous devrez les parser. Voici des exemples de noms d'attributs communs :
        // 'UserCreateDate', 'UserLastModifiedDate' ne sont pas des attributs standards
        // directement disponibles de la même manière que Firebase.
        // 'updated_at' est un attribut standard (timestamp Unix). 'email_verified', 'phone_number_verified'.
        // Pour la date de création, vous pourriez avoir à la stocker comme attribut personnalisé lors de l'inscription.

        // Placeholder pour la date de création et dernière connexion car Cognito ne les fournit pas
        // aussi directement que Firebase. Vous devrez peut-être utiliser `updated_at` pour `UserLastModifiedDate`.
        DateTime? creationTime;
        DateTime? lastSignInTime; // Cognito ne trace pas le "last sign in" de la même manière.
        // `auth_time` dans le jeton ID est l'heure d'authentification.

        if (userAttributes['updated_at'] != null) {
          try {
            lastSignInTime = DateTime.fromMillisecondsSinceEpoch((int.tryParse(userAttributes['updated_at'].toString()) ?? 0) * 1000);
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing updated_at: $e");
            }
          }
        }

        // TODO GERER L'UTILISATION DE PHOTOS DE PROFIL
        // final photoUrl = userAttributes['picture'] as String?;


        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: null,
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
                        label: 'User ID (sub/username)', // Cognito utilise 'sub' comme identifiant unique ou le username
                        value: uid ?? 'Non fourni',
                      ),
                      // Pour la date de création, vous devriez stocker cela comme un attribut personnalisé.
                      // if (creationTime != null) ...[
                      //   const Divider(height: 20),
                      //   _buildUserInfoRow(
                      //     context: context,
                      //     icon: Icons.date_range_outlined,
                      //     label: 'Compte créé le',
                      //     value: MaterialLocalizations.of(context).formatMediumDate(creationTime),
                      //   ),
                      // ],
                      if (lastSignInTime != null) ...[ // Utilisation de 'updated_at' comme proxy
                        const Divider(height: 20),
                        _buildUserInfoRow(
                          context: context,
                          icon: Icons.login_outlined,
                          label: 'Dernière modification du profil', // ou 'Dernière authentification' si vous utilisez auth_time du jeton
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
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                onPressed: () async {
                  await authService.signOut();
                  // AuthWrapper devrait gérer la redirection
                  if (!mounted) return;
                  // Forcer la navigation vers le formulaire d'accès est une bonne pratique de fallback
                  Navigator.of(context).pushNamedAndRemoveUntil(Routes.accessForm, (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: simpsonsTheme.colorScheme.error,
                  foregroundColor: simpsonsTheme.colorScheme.onError,
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