import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes/app_routes.dart';
import 'theme/user_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Single shared notifier — created once, lives for the app's lifetime.
// Only user-facing screens read from this.
final userThemeNotifier = UserThemeNotifier();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dobbie App',
      debugShowCheckedModeBanner: false,
      // Always light at the MaterialApp level —
      // admin / driver / shop-owner screens are never affected.
      theme: UserTheme.lightTheme,
      onGenerateRoute: (settings) => AppRoutes.generateRoute(settings),
      initialRoute: AppRoutes.login,
    );
  }
}
