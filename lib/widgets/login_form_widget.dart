import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginForm({super.key, required this.onSwitchToRegister});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Utiliser signInWithEmailAndPassword pour la connexion standard
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(), // Bonne pratique d'utiliser trim()
        password: _passwordController.text,
      );

      final User? user = userCredential.user;

      if (!mounted) return; // Vérifier si le widget est toujours monté

      if (user != null) {
        print("Utilisateur connecté avec l'ID : ${user.uid}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté en tant que : ${user.email} (ID: ${user.uid})'),
            backgroundColor: Colors.green,
          ),
        );
        // Ici, vous pourriez naviguer vers une autre page, par exemple.
        // widget.onLoginSuccess(); // Si vous avez un callback pour le succès
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Erreur de connexion.';
      if (e.code == 'user-not-found') {
        message = 'Aucun utilisateur trouvé pour cet email.';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect.';
      } else if (e.code == 'invalid-email') {
        message = 'Format d\'email invalide.';
      }
      print('FirebaseAuthException: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      print('Erreur de connexion inattendue: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Une erreur inattendue est survenue.'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Connexion', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            )
                : const Text('Se connecter'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.onSwitchToRegister,
            child: const Text("Pas encore de compte ? M'inscrire"),
          ),
        ],
      ),
    );
  }
}