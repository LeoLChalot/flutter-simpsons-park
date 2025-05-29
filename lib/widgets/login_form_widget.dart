import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final VoidCallback onSwitchToRegister;

  const LoginForm({super.key, required this.onSwitchToRegister});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Connexion', style: Theme.of(context).textTheme.headlineMedium),
          SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              print('Tentative de connexion');
            },
            child: Text('Se connecter'),
            style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15)),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: onSwitchToRegister,
            child: Text("Pas encore de compte ? M'inscrire"),
          ),
        ],
      ),
    );
  }
}