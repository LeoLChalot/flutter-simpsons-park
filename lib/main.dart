import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importez Provider
import 'package:simpsons_park/apps/app_simpson.dart';
import 'package:simpsons_park/pages/welcome_page.dart';
import 'package:simpsons_park/services/auth_service.dart'; // Assurez-vous que ce chemin est correct
import 'package:simpsons_park/pages/access_form_page.dart';
import 'package:simpsons_park/pages/admin/add_character_page.dart';
import 'package:simpsons_park/pages/admin/add_episode_page.dart';
import 'package:simpsons_park/pages/admin/add_newspaper_page.dart';
import 'package:simpsons_park/pages/loading_page.dart';
import 'package:simpsons_park/utils/auth_protected_logic.dart';
import 'package:simpsons_park/utils/routes.dart';
import 'package:simpsons_park/utils/simpsons_color_scheme.dart';
import 'package:simpsons_park/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(

    ChangeNotifierProvider<AuthService>(
      create: (context) => AuthService(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      theme: simpsonsTheme,
      routes: {
        Routes.home: (context) => const WelcomePage(),
        Routes.appSimpson: (context) => const AppSimpson(),
        Routes.dashboard: (context) => const AuthProtectedLogic(),
        Routes.accessForm: (context) => const AccessFormPage(),
        Routes.loading: (context) => const LoadingPage(),
        Routes.addCharacter: (context) => const AddCharacterPage(),
        Routes.addEpisode: (context) => const AddEpisodePage(),
        Routes.addNewspaper: (context) => const AddNewspaperPage(),
      },
    );
  }
}

class AuthProtectedDashboard {
  const AuthProtectedDashboard();
}