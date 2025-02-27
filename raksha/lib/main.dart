import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raksha/app_themes.dart';
import 'package:raksha/firebase_options.dart';
import 'package:raksha/homepage.dart';
import 'package:raksha/login.dart';
import 'package:raksha/settings.dart';
import 'package:raksha/theme_provider.dart';

import 'get_started.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(), child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return MaterialApp(
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          home: HomePage(),
          // Define named routes
          routes: {
            '/login': (context) => Scaffold(
                  body: LoginSignupModal(key: loginFormKey),
                ),
          });
    });
  }
}
