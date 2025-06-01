import 'dart:async';
import 'dart:typed_data';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Classe pour stocker les credentials temporaires AWS
class AwsTemporaryCredentials {
  final String accessKeyId;
  final String secretAccessKey;
  final String sessionToken;
  final DateTime expiration;
  final String awsRegion;

  AwsTemporaryCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.sessionToken,
    required this.expiration,
    required this.awsRegion
  });
}

// Remplacez par vos détails réels Cognito User Pool
const String _awsUserPoolId =
    'eu-west-3_u13dOolt7'; // Ex: 'eu-west-3_xxxxxxxxx'
const String _awsClientId =
    'qd3frggmu2a2pnjo6shpr1k7j'; // Ex: 'xxxxxxxxxxxxxxxxxxxxxx'

const _secureStorage = FlutterSecureStorage();
const _refreshTokenKey = 'cognito_refresh_token';
const _idTokenKey = 'cognito_id_token';
const _accessTokenKey = 'cognito_access_token';
const _usernameKey = 'cognito_username';

class AuthService with ChangeNotifier {
  late final CognitoUserPool _userPool;
  CognitoUser? _cognitoUser;
  CognitoUserSession? _session;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSignedUpUserConfirmed = false;

  CognitoUser? get cognitoUser => _cognitoUser;

  CognitoUserSession? get session => _session;

  String? get errorMessage => _errorMessage;

  bool get isLoading => _isLoading;

  bool get isAuthenticated => _session != null && _session!.isValid();

  bool get isSignedUpUserConfirmed => _isSignedUpUserConfirmed;

  String? get userEmail {
    return _cognitoUser?.username;
  }

  AuthService() {
    _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);
    _tryAutoLogin();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
    }
  }

  Future<void> _storeTokens(CognitoUserSession session) async {
    if (session.refreshToken?.token != null) {
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: session.refreshToken!.token!,
      );
    }
    if (session.idToken.jwtToken != null) {
      await _secureStorage.write(
        key: _idTokenKey,
        value: session.idToken.jwtToken!,
      );
    }
    if (session.accessToken.jwtToken != null) {
      await _secureStorage.write(
        key: _accessTokenKey,
        value: session.accessToken.jwtToken!,
      );
    }
  }

  Future<void> _clearStoredTokens() async {
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _usernameKey);
  }

  Future<void> _tryAutoLogin() async {
    _setLoading(true);
    _clearError();
    try {
      final storedRefreshToken = await _secureStorage.read(
        key: _refreshTokenKey,
      );
      final storedUsername = await _secureStorage.read(key: _usernameKey);

      if (storedRefreshToken != null && storedUsername != null) {
        _cognitoUser = CognitoUser(storedUsername, _userPool);
        final refreshToken = CognitoRefreshToken(storedRefreshToken);

        _session = await _cognitoUser!.refreshSession(refreshToken);
        if (_session != null && _session!.isValid()) {
          if (kDebugMode) {
            print(
              "AuthService: Session rafraîchie avec succès via auto-login.",
            );
          }
          await _storeTokens(_session!);
          _isSignedUpUserConfirmed =
              true; // Assume confirmed if auto-login with refresh token works
        } else {
          if (kDebugMode) {
            print(
              "AuthService: Auto-login: Échec du rafraîchissement de session ou session invalide.",
            );
          }
          _cognitoUser = null;
          _session = null;
          await _clearStoredTokens();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("AuthService: Erreur durant auto-login: $e");
      }
      _errorMessage = "Échec de l'auto-login."; // Simplified error
      _cognitoUser = null;
      _session = null;
      await _clearStoredTokens();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    _clearError();
    _isSignedUpUserConfirmed = false;

    final userAttributes = [
      AttributeArg(name: 'email', value: email),
      AttributeArg(name: 'name', value: name),
    ];

    try {
      final data = await _userPool.signUp(
        email,
        password,
        userAttributes: userAttributes,
      );
      _cognitoUser = data.user;
      _isSignedUpUserConfirmed = data.userConfirmed!;

      if (kDebugMode) {
        print(
          "AuthService: Inscription réussie. Confirmation nécessaire: ${data.userConfirmed}",
        );
      }
      if (data.userConfirmed == false) {
        _errorMessage =
            'Veuillez vérifier vos emails pour confirmer votre compte.';
      }
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage = e.message ?? "Erreur d'inscription inconnue.";
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito lors de l'inscription: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage =
          "Erreur inattendue lors de l'inscription: ${e.toString()}";
      if (kDebugMode) {
        print("AuthService: Erreur d'inscription: $e");
      }
    }
    _setLoading(false);
    return false;
  }

  Future<bool> confirmSignUp(String email, String confirmationCode) async {
    _setLoading(true);
    _clearError();
    _cognitoUser ??= CognitoUser(email, _userPool);

    try {
      final confirmed = await _cognitoUser!.confirmRegistration(
        confirmationCode,
      );
      if (kDebugMode) {
        print("AuthService: Confirmation réussie: $confirmed");
      }
      _isSignedUpUserConfirmed = true;
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage = e.message ?? "Erreur de confirmation inconnue.";
      if (e.code == 'CodeMismatchException') {
        _errorMessage = "Code de confirmation incorrect.";
      } else if (e.code == 'ExpiredCodeException') {
        _errorMessage =
            "Le code de confirmation a expiré. Veuillez en demander un nouveau.";
      }
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito lors de la confirmation: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage =
          "Erreur inattendue lors de la confirmation: ${e.toString()}";
      if (kDebugMode) {
        print("AuthService: Erreur de confirmation: $e");
      }
    }
    _setLoading(false);
    notifyListeners(); // Notify to show error
    return false;
  }

  Future<bool> resendConfirmationCode(String email) async {
    _setLoading(true);
    _clearError();
    _cognitoUser ??= CognitoUser(email, _userPool);

    try {
      await _cognitoUser!.resendConfirmationCode();
      if (kDebugMode) {
        print("AuthService: Code de confirmation renvoyé à $email");
      }
      _errorMessage = "Un nouveau code de confirmation a été envoyé à $email.";
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage = e.message ?? "Erreur lors du renvoi du code.";
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito lors du renvoi du code: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage =
          "Erreur inattendue lors du renvoi du code: ${e.toString()}";
      if (kDebugMode) {
        print("AuthService: Erreur renvoi code: $e");
      }
    }
    _setLoading(false);
    notifyListeners();
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();
    _cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );

    try {
      _session = await _cognitoUser!.authenticateUser(authDetails);
      if (_session != null && _session!.isValid()) {
        if (kDebugMode) {
          print("AuthService: Connexion réussie.");
        }
        await _storeTokens(_session!);
        await _secureStorage.write(key: _usernameKey, value: email);
        _isSignedUpUserConfirmed = true;
        _setLoading(false);
        return true;
      } else {
        _errorMessage = "Connexion échouée: Session invalide.";
      }
    } on CognitoUserNewPasswordRequiredException catch (e) {
      _errorMessage =
          "Un nouveau mot de passe est requis. Veuillez compléter le processus.";
      if (kDebugMode) {
        print("AuthService: Cognito New Password Required: $e");
      }
      // Gérer la navigation vers un écran de changement de mot de passe obligatoire
    } on CognitoUserConfirmationNecessaryException catch (e) {
      _errorMessage =
          "Veuillez confirmer votre compte avant de vous connecter.";
      if (kDebugMode) {
        print("AuthService: Cognito User Confirmation Necessary: $e");
      }
      _isSignedUpUserConfirmed = false;
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotFoundException' ||
          e.code == 'NotAuthorizedException') {
        _errorMessage = "Email ou mot de passe incorrect.";
      } else {
        _errorMessage = e.message ?? "Erreur de connexion inconnue.";
      }
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito lors de la connexion: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage = "Erreur inattendue lors de la connexion: ${e.toString()}";
      if (kDebugMode) {
        print("AuthService: Erreur de connexion: $e");
      }
    }
    _setLoading(false);
    _session = null;
    _cognitoUser = null;
    notifyListeners(); // Notify to show error and update state
    return false;
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    if (_cognitoUser != null) {
      try {
        await _cognitoUser!.signOut();
        if (kDebugMode) {
          print("AuthService: Déconnexion Cognito réussie.");
        }
      } catch (e) {
        if (kDebugMode) {
          print("AuthService: Erreur durant la déconnexion Cognito: $e");
        }
      }
    }
    _cognitoUser = null;
    _session = null;
    _isSignedUpUserConfirmed = false;
    await _clearStoredTokens();
    _setLoading(false); // Notifies
  }

  Future<Map<String, dynamic>?> getUserAttributes() async {
    if (!isAuthenticated) {
      if (kDebugMode) {
        print(
          "AuthService: Utilisateur non authentifié pour getUserAttributes.",
        );
      }
      return null;
    }
    try {
      final attributes = await _cognitoUser!.getUserAttributes();
      if (attributes == null) return null;
      final attributesMap = <String, dynamic>{};
      for (var attribute in attributes) {
        attributesMap[attribute.getName()!] = attribute.getValue();
      }
      return attributesMap;
    } catch (e) {
      _errorMessage =
          "Erreur lors de la récupération des attributs: ${e.toString()}";
      if (kDebugMode) {
        print("AuthService: Erreur getUserAttributes: $e");
      }
      notifyListeners();
      return null;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!isAuthenticated) {
      _errorMessage =
          "Utilisateur non authentifié pour changer le mot de passe.";
      notifyListeners();
      return false;
    }
    _setLoading(true);
    _clearError();
    try {
      await _cognitoUser!.changePassword(oldPassword, newPassword);
      if (kDebugMode) {
        print("AuthService: Mot de passe changé avec succès.");
      }
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage = e.message ?? "Échec du changement de mot de passe.";
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito Change Password: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage = "Erreur inattendue: $e";
      if (kDebugMode) {
        print("AuthService: Erreur Change Password: $e");
      }
    }
    _setLoading(false);
    notifyListeners();
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    final tempUser = CognitoUser(email, _userPool);

    try {
      await tempUser.forgotPassword();
      if (kDebugMode) {
        print("AuthService: Demande de réinitialisation envoyée pour $email.");
      }
      _errorMessage = "Un code de réinitialisation a été envoyé à $email.";
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage =
          e.message ?? "Erreur lors de la demande de réinitialisation.";
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito Forgot Password: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage = "Erreur inattendue: $e";
      if (kDebugMode) {
        print("AuthService: Erreur Forgot Password: $e");
      }
    }
    _setLoading(false);
    notifyListeners();
    return false;
  }

  Future<bool> confirmForgotPassword(
    String email,
    String confirmationCode,
    String newPassword,
  ) async {
    _setLoading(true);
    _clearError();
    final tempUser = CognitoUser(email, _userPool);

    try {
      await tempUser.confirmPassword(confirmationCode, newPassword);
      if (kDebugMode) {
        print("AuthService: Mot de passe réinitialisé pour $email.");
      }
      _setLoading(false);
      return true;
    } on CognitoClientException catch (e) {
      _errorMessage =
          e.message ?? "Erreur de confirmation du nouveau mot de passe.";
      if (kDebugMode) {
        print(
          "AuthService: Erreur Cognito Confirm Forgot Password: ${e.code} - ${e.message}",
        );
      }
    } catch (e) {
      _errorMessage = "Erreur inattendue: $e";
      if (kDebugMode) {
        print("AuthService: Erreur Confirm Forgot Password: $e");
      }
    }
    _setLoading(false);
    notifyListeners();
    return false;
  }

  Future<AwsTemporaryCredentials?> getAwsCredentialsFromCognito(
      String cognitoIdentityPoolId)
  async {
    _setLoading(true);
    _clearError();

    // Le SDK s'attend à ce que _session (qui est liée à _cognitoUser,
    // qui est lui-même lié à _userPool) soit valide et contienne l'ID Token.
    if (!isAuthenticated || _session!.idToken.jwtToken == null) {
      _errorMessage =
          "AuthService: Session utilisateur invalide ou ID Token manquant.";
      if (kDebugMode) print(_errorMessage);
      _setLoading(false);
      return null;
    }

    // Initialisation standard de CognitoCredentials.
    // Le SDK utilisera la session active du _userPool (via _cognitoUser.getSession())
    // pour obtenir l'ID token requis pour l'échange avec l'Identity Pool.
    final credentials = CognitoCredentials(
      cognitoIdentityPoolId,
      _userPool, // Le CognitoUserPool où l'utilisateur est connecté
    );

    // Il N'EST PAS nécessaire d'assigner manuellement credentials.logins.
    // Le SDK gère la récupération du jeton ID depuis la session active de _userPool
    // lorsque getAwsCredentials() est appelée.

    try {
      // getAwsCredentials() va tenter d'obtenir les credentials.
      // Si la session de _cognitoUser (liée à _userPool) est valide,
      // l'ID token sera utilisé.
      await credentials.getAwsCredentials(
        _session!.idToken.jwtToken!,
      );

      if (credentials.accessKeyId == null ||
          credentials.secretAccessKey == null ||
          credentials.sessionToken == null ||
          credentials.expireTime == null) {
        _errorMessage =
            "AuthService: Impossible de récupérer les credentials AWS complets.";
        if (kDebugMode) print(_errorMessage);
        _setLoading(false);
        return null;
      }

      if (kDebugMode) {
        print("AuthService: Credentials AWS obtenus avec succès.");
        print("Access Key ID: ${credentials.accessKeyId}");
        // NE PAS logguer secretAccessKey ou sessionToken en production
      }
      _setLoading(false);
      return AwsTemporaryCredentials(
        accessKeyId: credentials.accessKeyId!,
        secretAccessKey: credentials.secretAccessKey!,
        sessionToken: credentials.sessionToken!,
        awsRegion: "eu-west-3",
        expiration: DateTime.fromMillisecondsSinceEpoch(
          credentials.expireTime!,
        ),
      );
    } catch (e) {
      _errorMessage =
          "AuthService: Erreur lors de l'obtention des credentials AWS : ${e.toString()}";
      if (kDebugMode) print(_errorMessage);
      if (e is CognitoClientException) {
        if (kDebugMode) {
          print(
            "CognitoClientException details: ${e.message}, code: ${e.code}, name: ${e.name}",
          );
        }
        // Des codes d'erreur spécifiques ici peuvent être très utiles
        // e.g. 'NotAuthorizedException', 'ResourceNotFoundException'
      }
      _setLoading(false);
      return null;
    }
  }

  void clearErrorMessage() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
