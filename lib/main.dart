// Importações necessárias
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// Ponto de entrada da aplicação
void main() {
  runApp(const PokedexApp());
}

/// Widget raiz da aplicação Pokédex
///
/// Esta classe configura o MaterialApp com tema e tela inicial
class PokedexApp extends StatelessWidget {
  const PokedexApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      // Tema principal da aplicação em vermelho (cor característica da Pokédex)
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Tela inicial é a HomeScreen
      home: const HomeScreen(),
    );
  }
}
