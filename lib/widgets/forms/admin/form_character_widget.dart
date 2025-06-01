import 'dart:io';
import 'dart:async'; // Pour StreamTransformer
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:firebase_auth/firebase_auth.dart'; // Supposons que vous utilisez Cognito AuthService
import 'package:provider/provider.dart'; // Si vous utilisez AuthService via Provider
import 'package:simpsons_park/services/auth_service.dart'; // Votre AuthService pour Cognito
import 'package:simpsons_park/models/character_model.dart';

// Imports pour AWS S3 Upload
import 'package:minio_new/io.dart';
import 'package:minio_new/minio.dart';
import 'package:minio_new/models.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart'; // Pour générer des noms de fichiers uniques
// import 'package:path/path.dart' as p; // Si nécessaire pour manipuler les chemins

// **CONFIGURATION S3 - À GÉRER PLUS PROPREMENT DANS UNE VRAIE APP (par ex. via un service ou variables d'environnement)**
const String _s3_bucket_name = 'simpsons-park-images'; // Remplacez
const String _aws_region = 'eu-west-3'; // Ex: 'us-east-1', 'eu-west-1'
const String _cognito_identity_pool_id ='eu-west-3:9aa4ef32-32ee-43f9-8018-be4b92cd2fee'; // Ex: 'us-east-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
const String _s3_sub_folder = 'character_images'; // Optionnel: pour stocker les images dans un sous-dossier

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
    // ... (votre code _pickImage reste le même)
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _uploadError =
              null; // Réinitialiser l'erreur si une nouvelle image est sélectionnée
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

  Future<String?> _uploadImageToS3(File imageFile, String idToken) async {
    if (_imageFile == null) return null;
    setState(() => _isLoading = true);
    _uploadError = null;

    final String fileExtension = p.extension(imageFile.path).isNotEmpty
        ? p.extension(imageFile.path).substring(1)
        : 'jpg';
    final String fileName = '${const Uuid().v4()}.$fileExtension';
    final String s3ObjectPath = _s3_sub_folder.isNotEmpty
        ? '$_s3_sub_folder/$fileName'
        : fileName;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (!authService.isAuthenticated || authService.session?.idToken.jwtToken == null) {
        _uploadError = "Utilisateur non authentifié ou session invalide.";
        if (mounted) setState(() => _isLoading = false);
        return null;
      }
      final String userPoolIdToken = authService.session!.idToken.jwtToken!;

      // Obtenir les credentials AWS temporaires via Cognito Identity Pool
      final tempCredentials = await authService.getAwsCredentialsFromCognito(
        _cognito_identity_pool_id
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
        // print('S3 Upload - Secret Key: ${tempCredentials.secretAccessKey}'); // Attention avec ceci
        // print('S3 Upload - Session Token: ${tempCredentials.sessionToken}'); // Attention avec ceci
        print('S3 Upload - Expiration: ${tempCredentials.expiration}');
      }

      // Initialiser le client Minio/S3
      // C'EST LA PARTIE CRUCIALE POUR L'ERREUR ACTUELLE
      final minio = Minio(
        endPoint: 's3.eu-west-3.amazonaws.com', // Endpoint S3 spécifique à VOTRE région de bucket
        region: 'eu-west-3',                 // VOTRE région S3 (doit correspondre à l'endpoint)
        accessKey: tempCredentials.accessKeyId,
        secretKey: tempCredentials.secretAccessKey,
        sessionToken: tempCredentials.sessionToken,
      );

      if (kDebugMode) {
        print('Minio Client configuré avec Endpoint: ${minio.endPoint}, Region: ${minio.region}');
      }

      // Uploader le fichier
      await minio.putObject(
        _s3_bucket_name, // Nom de votre bucket S3
        s3ObjectPath,    // Nom/chemin de l'objet dans le bucket
        imageFile.openRead().transform<Uint8List>(
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              sink.add(Uint8List.fromList(data));
            },
          ),
        ),
        // contentType: 'image/$fileExtension', // Optionnel, mais recommandé
      );

      // Construire l'URL de l'image uploadéeToo many positional arguments: 3 expected, but 4 found. (Documentation)
      //
      // Try removing the extra positional arguments, or specifying the name for named arguments.
      // Le format standard est https://<bucket-name>.s3.<region>.amazonaws.com/<object-key>
      // Ou si vous avez un nom de domaine personnalisé / CloudFront devant.
      final String imageUrl =
          'https://$_s3_bucket_name.s3.$_aws_region.amazonaws.com/$s3ObjectPath';
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
      final String idToken = authService.session!.idToken.jwtToken!;

      imageUrl = await _uploadImageToS3(_imageFile!, idToken);
      if (imageUrl == null) {
        // L'erreur est déjà gérée et affichée par _uploadImageToS3
        setState(() => _isLoading = false);
        return; // Arrêter si l'upload a échoué
      }
    } else {
      imageUrl = ''; // Pas d'image, URL vide ou null
    }

    Character tempCharacter = Character(
      id: '',
      // Firestore générera l'ID
      name: _nameController.text.trim(),
      pseudo: _pseudoController.text.trim(),
      description: _descriptionController.text.trim(),
      function: _functionController.text.trim(),
      imageUrl: imageUrl, // Utiliser l'URL S3
    );
    Map<String, dynamic> characterData = tempCharacter.toJson();

    try {
      await FirebaseFirestore.instance
          .collection('characters')
          .add(characterData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personnage ajouté avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
        _nameController.clear();
        _pseudoController.clear();
        _descriptionController.clear();
        _functionController.clear();
        setState(() {
          _imageFile = null;
        });
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

    // if (_uploadError != null && !_isLoading)
    //   Padding(
    //     padding: const EdgeInsets.only(top: 8.0),
    //     child: Text(_uploadError!, style: TextStyle(color: Colors.red)),
    //   ),

    // Le reste de votre méthode build reste largement le même.
    // Adaptez simplement l'affichage de l'état de chargement et des erreurs.
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
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
                prefixIcon: Icon(Icons.face_retouching_natural_outlined, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
                prefixIcon: Icon(Icons.work_outline, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
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
                prefixIcon: Icon(Icons.description_outlined, color: colorScheme.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              maxLines: 3, // Permet plusieurs lignes pour la description
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
              textInputAction: TextInputAction.done, // Ou TextInputAction.newline si vous voulez une nouvelle ligne facile
            ),
            const SizedBox(height: 24), // Augmenté un peu l'espace avant l'image

            // Sélection d'image améliorée
            Text(
              'Image du personnage :',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Un peu plus de poids
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Aligner verticalement
              children: [
                Expanded(
                  flex: 2, // Donner plus d'espace à l'image
                  child: AspectRatio( // Pour maintenir un ratio pour le placeholder
                    aspectRatio: 1.0, // Carré, ajustez si besoin
                    child: Container(
                      decoration: BoxDecoration(
                        color: _imageFile == null ? colorScheme.surfaceVariant.withOpacity(0.5) : Colors.transparent,
                        border: Border.all(
                          color: _imageFile == null ? colorScheme.outline.withOpacity(0.5) : colorScheme.primary,
                          width: _imageFile == null ? 1 : 2,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: _imageFile == null
                          ? Center(
                        child: Icon(
                          Icons.image_search_outlined,
                          size: 50,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(11.0), // légèrement moins pour éviter le débordement du border
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover, // Assure que l'image remplit l'espace
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded( // Pour que le bouton puisse prendre de la place et être centré si on veut
                  flex: 1,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Choisir'),
                    onPressed: _isLoading ? null : _pickImage,
                    style: ElevatedButton.styleFrom(
                      // backgroundColor: colorScheme.primary, // Si vous voulez une couleur spécifique
                      // foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
