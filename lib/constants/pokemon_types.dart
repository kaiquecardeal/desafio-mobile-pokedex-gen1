import 'package:flutter/material.dart';

/// Classe utilitária para gerenciar cores dos tipos de Pokémon
///
/// Contém um mapa com as cores oficiais de cada tipo de Pokémon
/// baseadas nos jogos originais da franquia.
class PokemonTypes {
  /// Mapa de cores para cada tipo de Pokémon
  ///
  /// Cada cor foi escolhida para representar visualmente o tipo,
  /// seguindo o padrão visual dos jogos Pokémon oficiais.
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFFA8A878),     // Bege/cinza claro
    'fire': Color(0xFFF08030),       // Laranja/vermelho
    'water': Color(0xFF6890F0),      // Azul
    'electric': Color(0xFFF8D030),   // Amarelo
    'grass': Color(0xFF78C850),      // Verde
    'ice': Color(0xFF98D8D8),        // Ciano claro
    'fighting': Color(0xFFC03028),   // Vermelho escuro
    'poison': Color(0xFFA040A0),     // Roxo
    'ground': Color(0xFFE0C068),     // Marrom claro
    'flying': Color(0xFFA890F0),     // Roxo claro
    'psychic': Color(0xFFF85888),    // Rosa
    'bug': Color(0xFFA8B820),        // Verde amarelado
    'rock': Color(0xFFB8A038),       // Marrom
    'ghost': Color(0xFF705898),      // Roxo escuro
    'dragon': Color(0xFF7038F8),     // Roxo/azul
  };

  /// Retorna a cor correspondente ao tipo do Pokémon
  ///
  /// [type] - Nome do tipo (ex: "fire", "water")
  ///
  /// Retorna a cor específica do tipo ou cinza se o tipo não for encontrado
  static Color getTypeColor(String type) {
    return typeColors[type.toLowerCase()] ?? Colors.grey;
  }
}
