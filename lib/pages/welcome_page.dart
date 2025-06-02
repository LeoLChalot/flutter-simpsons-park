import 'package:flutter/material.dart';

import '../apps/app_simpson.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme; // Utiliser le thème global
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Logo de l'application
              Image.asset(
                'assets/images/simpsons-park-logo.png',
                width: 250,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.mood_bad, size: 100, color: Colors.black54);
                },
              ),
              const SizedBox(height: 40),
              Text(
                'Bienvenue à Simpsons Park !',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onPrimary, // Noir sur fond jaune
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre guide ultime de Springfield.',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary.withValues(),
                ),
              ),
              const SizedBox(height: 50),

              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                label: const Text('Commencer la visite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0), // Bouton arrondi
                  ),
                  elevation: 5,
                ),
                onPressed: () {
                  Navigator.pushReplacement( // Remplace la page d'accueil pour ne pas pouvoir y retourner avec "back"
                    context,
                    MaterialPageRoute(builder: (context) => const AppSimpson()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}