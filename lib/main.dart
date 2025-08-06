import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_screen.dart'; // On va créer ce fichier juste après

void main() {
  runApp(const ChefAIApp());
}

class ChefAIApp extends StatelessWidget {
  const ChefAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: MaterialApp(
        title: 'Chef IA',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: Colors.transparent,
          // Important pour le fond d'écran
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
