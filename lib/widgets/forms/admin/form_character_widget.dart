import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';
import 'package:simpsons_park/services/auth_service.dart';
import 'package:simpsons_park/models/character_model.dart';

import 'package:minio_new/minio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../pages/character_detail_page.dart';

const String _s3BucketName = 'simpsons-park-images';
const String _awsRegion = 'eu-west-3';
const String _cognitoIdentityPoolId =
    'eu-west-3:9aa4ef32-32ee-43f9-8018-be4b92cd2fee';

class FormCharacterWidget extends StatefulWidget {
  const FormCharacterWidget({super.key});

  @override
  State<FormCharacterWidget> createState() => _FormCharacterWidgetState();
}

class _FormCharacterWidgetState extends State<FormCharacterWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _functionController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  String? _uploadError;

  @override
  void dispose() {
    _nameController.dispose();
    _pseudoController.dispose();
    _descriptionController.dispose();
    _functionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _uploadError = null;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Erreur lors de la sélection de l'image: $e");
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection de l\'image.'),
          ),
        );
      }
    }
  }

  // Non implémentée pour ne pas bloquer l'upload d'image
  Future<String?> _uploadImageToS3(File imageFile, String idToken) async {
    if (_imageFile == null) return null;
    setState(() => _isLoading = true);
    _uploadError = null;

    final String fileExtension = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path).substring(1)
        : 'jpg';
    final String fileName = '${const Uuid().v4()}.$fileExtension';
    final String s3ObjectPath = _s3BucketName.isNotEmpty
        ? '$_s3BucketName/$fileName'
        : fileName;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated ||
          authService.session?.idToken.jwtToken == null) {
        _uploadError = "Utilisateur non authentifié ou session invalide.";
        if (mounted) setState(() => _isLoading = false);
        return null;
      }
      final String userPoolIdToken = authService.session!.idToken.jwtToken!;

      // Obtenir les credentials AWS temporaires via Cognito Identity Pool
      final tempCredentials = await authService.getAwsCredentialsFromCognito(
        _cognitoIdentityPoolId,
      );

      if (tempCredentials == null) {
        _uploadError =
            "Impossible d'obtenir les informations d'identification AWS via Cognito Identity.";
        if (mounted) setState(() => _isLoading = false);
        return null;
      }

      // DEBUG: AFFICHER LES DETAILS DES CREDENTIALS (À ENLEVER EN PRODUCTION)
      if (kDebugMode) {
        print('S3 Upload - Access Key: ${tempCredentials.accessKeyId}');
        print('S3 Upload - Expiration: ${tempCredentials.expiration}');
      }

      // Initialiser le client Minio/S3
      final minio = Minio(
        endPoint: 's3.eu-west-3.amazonaws.com',
        // Endpoint S3 spécifique à VOTRE région de bucket
        region: 'eu-west-3',
        accessKey: tempCredentials.accessKeyId,
        secretKey: tempCredentials.secretAccessKey,
        sessionToken: tempCredentials.sessionToken,
      );

      if (kDebugMode) {
        print(
          'Minio Client configuré avec Endpoint: ${minio.endPoint}, Region: ${minio.region}',
        );
      }

      // Uploader le fichier
      await minio.putObject(
        _s3BucketName,
        s3ObjectPath,
        imageFile.openRead().transform<Uint8List>(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              sink.add(Uint8List.fromList(data));
            },
          ),
        ),
      );

      final String imageUrl =
          'https://$_s3BucketName.s3.$_awsRegion.amazonaws.com/$s3ObjectPath';
      if (kDebugMode) {
        print('Image uploadée avec succès sur S3. URL: $imageUrl');
      }
      return imageUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'upload S3 avec Minio: $e');
      }
      if (e is MinioError) {
        _uploadError = 'Erreur S3: ${e.message})';
      } else {
        _uploadError = 'Erreur lors de l\'upload de l\'image: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_uploadError!)));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String slugify(String text) {
    if (text.isEmpty) {
      return "";
    }
    String result = text.toLowerCase();
    result = result
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a');
    result = result
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e');
    result = result
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i');
    result = result
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o');
    result = result
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u');
    result = result.replaceAll('ç', 'c');
    result = result.replaceAll('ñ', 'n');
    result = result.replaceAll(RegExp(r'\s+'), '-');
    result = result.replaceAll(RegExp(r'[^a-z0-9-]'), '');
    result = result.replaceAll(RegExp(r'^-+|-+$'), '');
    result = result.replaceAll(RegExp(r'-+'), '-');
    return result;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _uploadError = null;
    });

    String? imageUrl;
    if (_imageFile != null) {
      // Obtenir l'idToken de l'utilisateur actuel depuis AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.session == null ||
          authService.session!.idToken.jwtToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Session utilisateur invalide. Veuillez vous reconnecter.',
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      // final String idToken = authService.session!.idToken.jwtToken!;

      // imageUrl = await _uploadImageToS3(_imageFile!, idToken);
      // if (imageUrl == null) {
      // L'erreur est déjà gérée et affichée par _uploadImageToS3
      // setState(() => _isLoading = false);
      // return; // Arrêter si l'upload a échoué
      // }
    } else {
      imageUrl = '';
    }

    final String characterName = _nameController.text.trim();
    final String characterId = slugify(
      characterName,
    ); // Utiliser le nom slugifié comme ID

    if (characterId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Le nom du personnage ne peut pas être vide ou contenir uniquement des caractères spéciaux.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    Character tempCharacter = Character(
      id: characterId,
      name: characterName,
      pseudo: _pseudoController.text.trim(),
      description: _descriptionController.text.trim(),
      function: _functionController.text.trim(),
      imageUrl: imageUrl?.trim() ?? '',
    );
    Map<String, dynamic> characterData = tempCharacter.toJson();

    try {
      final characterDocRef = FirebaseFirestore.instance
          .collection('characters')
          .doc(characterId);

      // Vérifier si un personnage avec cet ID existe déjà
      final docSnapshot = await characterDocRef.get();
      if (docSnapshot.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Un personnage avec le nom "$characterName" (ID: $characterId) existe déjà.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      await characterDocRef.set(characterData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnage ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Réinitialiser le formulaire
        _formKey.currentState!.reset();
        _nameController.clear();
        _pseudoController.clear();
        _descriptionController.clear();
        _functionController.clear();
        setState(() {
          _imageFile = null;
        });

        final Character characterForNavigation = tempCharacter;

        await Future.delayed(Duration(milliseconds: 300));

        // Si la page actuelle est un dialogue ou une modale que vous voulez fermer avant de naviguer :
        if(!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }

        // Naviguer vers la page de détail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CharacterDetailPage(character: characterForNavigation),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout du personnage : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              'Nouveau Personnage',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: "Nom du personnage",
                hintText: "Ex: Homer Simpson",
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _pseudoController,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: "Pseudo (optionnel)",
                hintText: "Ex: Homie",
                prefixIcon: Icon(
                  Icons.face_retouching_natural_outlined,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(),
              ),
              textInputAction: TextInputAction.next,
              // Pas de validateur si c'est optionnel, ou un validateur spécifique si besoin
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _functionController,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: "Fonction / Rôle",
                hintText: "Ex: Inspecteur de la sécurité",
                prefixIcon: Icon(
                  Icons.work_outline,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer une fonction';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              style: theme.textTheme.titleMedium,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Décrivez le personnage...",
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(),
              ),
              maxLines: 3,
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 24),

            // Augmenté un peu l'espace avant l'image
            Text(
              'Image du personnage :',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ), // Un peu plus de poids
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _imageFile == null
                            ? colorScheme.surfaceContainerHighest.withValues()
                            : Colors.transparent,
                        border: Border.all(
                          color: _imageFile == null
                              ? colorScheme.outline.withValues()
                              : colorScheme.primary,
                          width: _imageFile == null ? 1 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: _imageFile == null
                          ? Center(
                              child: Icon(
                                Icons.image_search_outlined,
                                size: 50,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(11.0),
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choisir'),
                    onPressed: _isLoading ? null : _pickImage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      textStyle: theme.textTheme.labelLarge,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Afficher l'erreur d'upload S3 ici
            if (_uploadError != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
                child: Text(
                  _uploadError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 32),

            // Bouton de soumission
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
                  : const Icon(Icons.person_add_alt_1_outlined),
              label: Text(
                _isLoading ? 'Ajout en cours...' : 'Ajouter le Personnage',
              ),
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
