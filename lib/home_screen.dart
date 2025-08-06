import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import 'app_strings.dart';
import 'colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _apiUrl =
      'https://ai-chief-backend.onrender.com/generate-recipe';

  final TextEditingController _ingredientsController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _recipeResult;
  String? _error;
  bool _isFrench = true;

  Map<String, String> get _strings => _isFrench ? AppStrings.fr : AppStrings.en;

  // MODIFIÉ : La logique d'appel et d'analyse est améliorée
  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _recipeResult = null;
      _error = null;
    });

    // --- DÉBUT DE LA MODIFICATION ---

    // 1. On transforme la chaîne de texte en une liste propre
    // "poulet, tomate, oignon" -> ["poulet", "tomate", "oignon"]
    final List<String> ingredientsList =
        _ingredientsController.text
            .split(',') // Sépare la chaîne par les virgules
            .map(
              (e) => e.trim(),
            ) // Enlève les espaces avant/après chaque ingrédient
            .where((e) => e.isNotEmpty) // Retire les éléments vides
            .toList();

    // 2. On détermine le code de la langue
    final String languageCode = _isFrench ? 'fr' : 'en';

    // 3. On construit l'objet (payload) à envoyer
    final Map<String, dynamic> payload = {
      'ingredients': ingredientsList,
      'language': languageCode,
    };

    // --- FIN DE LA MODIFICATION ---

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 1. On décode la réponse principale
        final responseBody = json.decode(utf8.decode(response.bodyBytes));

        // 2. On extrait la chaîne de caractères qui contient le JSON de la recette
        final recipeString = responseBody['recipe'] as String;

        // 3. NOUVEAU : On utilise une expression régulière pour extraire proprement le JSON
        // qui est à l'intérieur du bloc de code ```json ... ```
        final regExp = RegExp(r'```json\n([\s\S]*?)\n```');
        final match = regExp.firstMatch(recipeString);

        if (match != null) {
          final recipeJsonString = match.group(1)!;
          Logger().i("JSON de la recette extrait: $recipeJsonString");
          // 4. On décode enfin le JSON de la recette
          setState(() {
            _recipeResult = json.decode(recipeJsonString);
          });
          Logger().i("Recette générée avec succès: $_recipeResult");

          // NOUVEAU : On affiche un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseBody['message'] ?? 'Recette trouvée !'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          throw Exception('Format de recette JSON non trouvé.');
        }
      } else {
        Logger().e("Erreur de l'API: ${response.statusCode}");
        Logger().e("Erreur de l'API: ${response.body}");
        setState(() {
          _error = _strings['errorText'];
        });
      }
    } catch (e) {
      setState(() {
        _error = _strings['errorText'];
        Logger().e('Erreur: $e'); // Pour le débogage
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le reste de la méthode build reste identique
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/1.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: .5),
            colorBlendMode: BlendMode.darken,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLanguageSwitcher(),
                  const SizedBox(height: 60),
                  Text(
                    _strings['title']!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _strings['subtitle']!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildIngredientsTextField(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                  const SizedBox(height: 40),
                  _buildResultArea(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Les autres widgets (LanguageSwitcher, TextField, Button, Loading, Error) ne changent pas...

  Widget _buildLanguageSwitcher() {
    return Align(
      alignment: Alignment.topRight,
      child: ToggleButtons(
        isSelected: [_isFrench, !_isFrench],
        onPressed: (index) {
          setState(() {
            _isFrench = index == 0;
          });
        },
        color: Colors.white,
        selectedColor: Colors.black,
        fillColor: AppColors.primary,
        borderColor: AppColors.primary,
        selectedBorderColor: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('FR'),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('EN'),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTextField() {
    return TextField(
      controller: _ingredientsController,
      style: const TextStyle(color: AppColors.textLight),
      decoration: InputDecoration(
        hintText: _strings['hintText'],
        hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _generateRecipe,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        _strings['buttonText']!,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildResultArea() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child:
          _isLoading
              ? _buildLoadingIndicator()
              : _error != null
              ? _buildErrorWidget()
              : _recipeResult != null
              ? _buildRecipeCard()
              : const SizedBox.shrink(), // Espace vide au début
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        const SpinKitFadingCube(color: AppColors.primary, size: 40.0),
        const SizedBox(height: 16),
        Text(
          _strings['loadingText']!,
          style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Text(
      _error!,
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.redAccent, fontSize: 16),
    );
  }

  // MODIFIÉ : La carte de recette utilise maintenant le widget Markdown
  Widget _buildRecipeCard() {
    // On regroupe toutes les instructions en une seule chaîne, séparées par des sauts de ligne
    final instructionsMarkdown = (List<String>.from(
      _recipeResult!['instructions'] ?? [],
    )).join('\n\n');

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _recipeResult!['nom_recette'] ?? _strings['recipeName'],
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _recipeResult!['description_courte'] ?? '',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textLight.withValues(alpha: 0.8),
              ),
            ),
            const Divider(height: 32, color: AppColors.primary),

            // NOUVEAU : On utilise MarkdownBody pour afficher les instructions
            MarkdownBody(
              data: instructionsMarkdown,
              styleSheet: MarkdownStyleSheet(
                // On peut personnaliser le style du Markdown
                p: const TextStyle(height: 1.5, fontSize: 15),
                h2: TextStyle(color: AppColors.primaryAccent, fontSize: 20),
                strong: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
