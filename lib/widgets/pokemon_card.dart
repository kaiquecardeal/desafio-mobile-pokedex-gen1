// Importações necessárias
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../constants/pokemon_types.dart';

/// Widget de card que exibe um Pokémon de forma resumida
///
/// Este card é usado na grid da tela inicial para mostrar
/// os Pokémons de forma visual e atraente, com cores baseadas no tipo.
class PokemonCard extends StatelessWidget {
  /// Pokémon a ser exibido no card
  final Pokemon pokemon;

  const PokemonCard({Key? key, required this.pokemon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtém o tipo primário e sua cor correspondente
    final primaryType = pokemon.types.first;
    final typeColor = PokemonTypes.getTypeColor(primaryType);

    return Card(
      elevation: 4, // Sombra do card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        // Gradiente com a cor do tipo do Pokémon
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              typeColor.withValues(alpha: 0.7),
              typeColor,
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Número do Pokémon na Pokédex (formato #001)
              Text(
                '#${pokemon.id.toString().padLeft(3, '0')}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              // Imagem do Pokémon
              Expanded(
                child: Center(
                  child: Image.network(
                    pokemon.imageUrl,
                    fit: BoxFit.contain,
                    // Ícone de erro caso a imagem não carregue
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
              // Nome do Pokémon em maiúsculas
              Text(
                pokemon.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis, // Trunca nomes longos
              ),
            ],
          ),
        ),
      ),
    );
  }
}
