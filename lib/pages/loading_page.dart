import 'package:flutter/material.dart';
import '../utils/simpsons_color_scheme.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD90F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RotationTransition(
              turns: _controller,
              child: Image.asset(
                'assets/images/donut.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'D\'oh! Chargement en cours...',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                // Appliquez une couleur de texte contrastante
                color: Colors.pink
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  simpsonsTheme.colorScheme.secondary,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}