import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:simpsons_park/apps/app_simpson.dart';
import 'package:simpsons_park/pages/access_form_page.dart';
import 'package:simpsons_park/pages/loading_page.dart';
import 'package:simpsons_park/utils/routes.dart';
import 'package:simpsons_park/utils/simpsons_color_scheme.dart';
import 'apps/app_dashboard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      // home: AuthWrapper(),
      home: AppSimpson(),
      theme: simpsonsTheme,
      routes: {
        Routes.accessForm: (context) => const AccessFormPage(),
        Routes.dashboard: (context) => const AppDashboard(),
        Routes.loading: (context) => const LoadingPage(),
      },
    ),
  );
}

