## Utilisation de Firebase

Ce projet utilise Firebase pour gérer l'authentification des utilisateurs (Firebase Authentication) et pour stocker et synchroniser les données de l'application en temps réel (Cloud Firestore).

### Initialisation

Firebase est initialisé au démarrage de l'application dans le fichier `lib/main.dart` en utilisant les configurations spécifiques à la plateforme définies dans `lib/firebase_options.dart`.

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      // ...
    ),
  );
}
```
### Gestion de l'Authentification (Firebase Auth)
La gestion de l'authentification est centralisée dans le service AuthService (lib/services/auth_service.dart).

### Connaître l'état de connexion de l'utilisateur
Pour déterminer si un utilisateur est connecté et réagir aux changements d'état d'authentification, nous utilisons :
1. `Stream<User?> get authStateChanges` : Un flux qui émet un objet User lorsqu'un utilisateur se connecte ou se déconnecte. C'est la méthode recommandée pour écouter les changements d'état en temps réel.
    - Utilisé par exemple dans `AuthWrapper` (`lib/utils/auth_wrapper.dart`) pour rediriger l'utilisateur vers l'écran approprié (application principale ou page de connexion).
    ```dart
    // Exemple d'utilisation dans AuthWrapper
    StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // ou _authService.authStateChanges
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return AppSimpson(); // Utilisateur connecté
        } else {
          return AccessFormPage(); // Utilisateur non connecté
        }
      },
    );
     ```  
2. `User? get currentUser` : Permet d'obtenir l'utilisateur actuellement connecté de manière synchrone. Utile pour un accès ponctuel à l'utilisateur.
```dart
// Dans AuthService
User? get currentUser => _firebaseAuth.currentUser;
```
## Méthodes d'Authentification Principales
Le service AuthService expose les méthodes suivantes :
- Inscription
    ```dart
      Future<UserCredential> createUserWithEmailAndPassword({
        required String email,
        required String password,
      });
    ```
- Connexion
    ```dart
    Future<UserCredential> signInWithEmailAndPassword({
      required String email,
      required String password,
    })
    ```
- Déconnexion
    ```dart
    Future<void> signOut(BuildContext context)
    ```

## Opérations sur la Base de Données (Cloud Firestore)
Cloud Firestore est utilisé comme base de données NoSQL pour stocker les informations sur les personnages,
les saisons, les épisodes, etc. L'accès se fait via l'instance `FirebaseFirestore.instance`.

### Structure des Données
  - characters/{id} : Documents des personnages.
  - seasons/{id} : Documents des saisons, contenant des références aux épisodes.
  - episodes/{id} : Documents des épisodes, contenant des références aux personnages.

- **Create**
```dart
// Ajouter un document avec un ID auto-généré
FirebaseFirestore.instance.collection('collection').add({
  'champ1': 'valeur1',
  'champ2': 123,
});
// Ajouter un document avec un ID spécifique
FirebaseFirestore.instance.collection('collection').doc('id').set({
  'champ1': 'valeur1',
  'champ2': 456,
});
```
- **Read** (Lire des données)
  L'application lit les données de Firestore de plusieurs manières :
  Lire un document spécifique (une seule fois) :
```dart
DocumentSnapshot doc = await FirebaseFirestore.instance.collection('collection').doc('monId').get();
if (doc.exists) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  // Utiliser les données...
}
```
Lire une collection (une seule fois) :
```dart
QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('collection').get();
for (var doc in querySnapshot.docs) {
  // Traiter chaque document...
}
```
Écouter les changements en temps réel (Streams) : C'est la méthode privilégiée dans l'application pour avoir des données toujours à jour :
```dart
Stream<QuerySnapshot> stream = FirebaseFirestore.instance.collection('collection').snapshots();
// Utiliser avec un StreamBuilder
```
Filtrage et Tri, Firestore permet de filtrer et trier les données côté serveur :
```dart
Query maRequete = FirebaseFirestore.instance.collection('characters')
    .where('lastName', isGreaterThanOrEqualTo: 'S') // Filtrage
    .where('lastName', isLessThanOrEqualTo: 'S\uf8ff')
    .orderBy('lastName') // Tri
    .orderBy('firstName');
```
- **Update**, mise à jour :
```dart
FirebaseFirestore.instance.collection('collection').doc('id').update({
  'champExistant': 'nouvelleValeur',
  'nouveauChamp': true, // Ajoute le champ s'il n'existe pas
});
```
- **Delete** (Supprimer des données)
```dart
FirebaseFirestore.instance.collection('collection').doc('id').delete();
```
