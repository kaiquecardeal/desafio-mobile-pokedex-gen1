// Importações necessárias para comunicação HTTP
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

/// Serviço responsável por buscar dados de Pokémons da PokéAPI
///
/// Esta classe centraliza todas as chamadas à API externa,
/// convertendo os dados JSON em objetos Pokemon utilizáveis na aplicação.
class PokemonService {
  /// URL base da PokéAPI
  static const String baseUrl = 'https://pokeapi.co/api/v2/pokemon/';

  /// Busca uma lista de Pokémons da primeira geração (IDs 1-151)
  ///
  /// [limit] - Quantidade de Pokémons a buscar (padrão: 20)
  /// [offset] - Posição inicial da busca (padrão: 0)
  ///
  /// Retorna uma lista de Pokémons da Geração 1.
  /// Útil para implementar paginação na listagem.
  Future<List<Pokemon>> fetchGen1Pokemon({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final start = (offset + 1).clamp(1, 151);
      final end = (offset + limit).clamp(1, 151);
      if (start > end) return [];

      final futures = <Future<Pokemon>>[];
      for (int i = start; i <= end; i++) {
        futures.add(fetchPokemonById(i));
      }

      // Remover eagerError e adicionar tratamento de erro
      final results = await Future.wait(futures, eagerError: true);

      return results;
    } catch (e) {
      print('Erro ao buscar pokémons: $e');
      return [];
    }
  }

  /// Busca um Pokémon específico pelo ID
  ///
  /// [id] - ID numérico do Pokémon na Pokédex
  ///
  /// Retorna um objeto Pokemon com todos os dados.
  /// Também busca a descrição em uma segunda requisição à API de species.
  Future<Pokemon> fetchPokemonById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao carregar Pokémon $id: ${response.statusCode}',
        );
      }

      final json = jsonDecode(response.body);

      // Adicione o restante da implementação aqui
      String description = '';
      try {
        final speciesUrl = json['species']['url'];
        final speciesResponse = await http.get(Uri.parse(speciesUrl));
        if (speciesResponse.statusCode == 200) {
          final speciesJson = jsonDecode(speciesResponse.body);
          description = (speciesJson['flavor_text_entries'] as List)
              .firstWhere(
                (entry) => entry['language']['name'] == 'en',
                orElse: () => {'flavor_text': 'No description available'},
              )['flavor_text']
              .replaceAll('\n', ' ')
              .replaceAll('\f', ' ');
        }
      } catch (e) {
        print('Erro ao buscar descrição: $e');
      }

      return Pokemon.fromJson(json, description);
    } catch (e) {
      print('Erro ao buscar Pokémon $id: $e');
      rethrow;
    }
  }

  /// Busca a cadeia de evoluções de um Pokémon
  ///
  /// [pokemonId] - ID do Pokémon
  ///
  /// Retorna uma lista com todos os Pokémons da cadeia evolutiva.
  /// Exemplo: Bulbasaur retorna [Bulbasaur, Ivysaur, Venusaur]
  Future<List<Pokemon>> fetchEvolutions(int pokemonId) async {
    try {
      // Primeiro busca os dados da espécie
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$pokemonId/'),
      );

      if (response.statusCode == 200) {
        final speciesData = jsonDecode(response.body);
        final evolutionChainUrl = speciesData['evolution_chain']['url'];

        // Depois busca a cadeia de evolução completa
        final evolutionResponse = await http.get(Uri.parse(evolutionChainUrl));
        if (evolutionResponse.statusCode == 200) {
          final evolutionData = jsonDecode(evolutionResponse.body);
          return await _extractEvolutions(evolutionData['chain']);
        }
      }
      return [];
    } catch (e) {
      print('Erro ao carregar evoluções: $e');
      return [];
    }
  }

  /// Extrai a lista de Pokémons da cadeia evolutiva
  ///
  /// [chain] - Dados da cadeia evolutiva retornados pela API
  ///
  /// Retorna lista de Pokémons da cadeia
  Future<List<Pokemon>> _extractEvolutions(Map<String, dynamic> chain) async {
    List<Pokemon> evolutions = [];
    await _processChain(chain, evolutions);
    return evolutions;
  }

  /// Processa recursivamente a cadeia de evoluções
  ///
  /// [chain] - Nó atual da cadeia evolutiva
  /// [evolutions] - Lista onde os Pokémons serão adicionados
  ///
  /// A cadeia é processada recursivamente pois um Pokémon pode ter
  /// múltiplas evoluções (ex: Eevee -> Vaporeon, Jolteon, Flareon)
  Future<void> _processChain(
    Map<String, dynamic> chain,
    List<Pokemon> evolutions,
  ) async {
    // Adiciona o Pokémon atual se existir e não for duplicado
    if (chain['species'] != null) {
      final speciesName = chain['species']['name'];
      final pokemon = await fetchPokemonByName(speciesName);
      if (pokemon != null && !evolutions.any((p) => p.id == pokemon.id)) {
        evolutions.add(pokemon);
      }
    }

    // Processa recursivamente as próximas evoluções
    if (chain['evolves_to'] != null) {
      for (var evolution in chain['evolves_to']) {
        await _processChain(evolution, evolutions);
      }
    }
  }

  /// Busca um Pokémon pelo nome
  ///
  /// [name] - Nome do Pokémon (em inglês, minúsculas)
  ///
  /// Retorna o Pokémon encontrado ou null se não existir.
  /// Também busca a descrição do Pokémon.
  Future<Pokemon?> fetchPokemonByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon/$name'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final pokemonId = json['id'];

        // Busca a descrição
        String description = 'Sem descrição disponível';
        try {
          final speciesResponse = await http.get(
            Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$pokemonId/'),
          );
          if (speciesResponse.statusCode == 200) {
            final speciesData = jsonDecode(speciesResponse.body);
            if (speciesData['flavor_text_entries'] != null) {
              final entries =
                  speciesData['flavor_text_entries'] as List<dynamic>?;
              if (entries != null && entries.isNotEmpty) {
                final entry = entries.cast<Map<String, dynamic>?>().firstWhere(
                  (e) => e?['language']?['name'] == 'en',
                  orElse: () => null,
                );
                if (entry != null) {
                  description = (entry['flavor_text'] as String)
                      .replaceAll('\n', ' ')
                      .replaceAll('\f', ' ');
                }
              }
            }
          }
        } catch (e) {
          print('Erro ao buscar Pokémon por nome $name: $e');
        }
        return Pokemon.fromJson(json, description);
      }
      return null;
    } catch (e) {
      print('Erro ao buscar Pokémon por nome $name: $e');
      return null;
    }
  }

  /// Busca um Pokémon por ID ou nome (método flexível)
  ///
  /// [query] - ID numérico ou nome do Pokémon
  ///
  /// Retorna o Pokémon encontrado ou null.
  /// Detecta automaticamente se a busca é por ID (número) ou nome (texto).
  /// Útil para campos de busca onde o usuário pode digitar qualquer coisa.
  Future<Pokemon?> fetchPokemonByIdOrName(String query) async {
    try {
      // Tenta buscar por ID se for número
      if (int.tryParse(query) != null) {
        return await fetchPokemonById(int.parse(query));
      }
      // Caso contrário, busca por nome
      return await fetchPokemonByName(query.toLowerCase());
    } catch (e) {
      print('Erro ao buscar Pokémon: $e');
      return null;
    }
  }
}
