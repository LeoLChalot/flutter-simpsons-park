import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
  final VoidCallback onSwitchToLogin; // Callback pour basculer
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  RegisterForm({super.key, required this.onSwitchToLogin});

  Future<void> onSubmit(BuildContext context) async {
    try {
      print("$_emailController.text, $_passwordController.text");
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if(credential.user != null){
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Utilisateur créé avec l'ID : ${credential.user!.uid}")));
      }
      print("Utilisateur créé avec l'ID : ${credential.user!.uid}");
      // await FirebaseAuth.instance.signInWithCredential(credential as AuthCredential);
      // final user = credential.user;
      // print("Utilisateur connecté avec l'ID : ${user!.uid}");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Inscription',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 20),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              print('Tentative d\'inscription');
              onSubmit(context);
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            child: Text('M\'inscrire'),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: onSwitchToLogin,
            child: Text('Déjà un compte ? Se connecter'),
          ),
        ],
      ),
    );
  }
}
