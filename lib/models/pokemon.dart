/// Modelo de dados que representa um Pokémon
///
/// Esta classe contém todas as informações de um Pokémon obtidas da PokéAPI,
/// incluindo dados básicos, físicos e de evolução.
class Pokemon {
  // Identificador único do Pokémon na Pokédex
  final int id;

  // Nome do Pokémon
  final String name;

  // Lista de tipos do Pokémon (ex: fire, water, grass)
  final List<String> types;

  // URL da imagem oficial do Pokémon
  final String imageUrl;

  // Altura do Pokémon em decímetros (API retorna em dm)
  final num height;

  // Peso do Pokémon em hectogramas (API retorna em hg)
  final num weight;

  // Lista de habilidades do Pokémon
  final List<String> abilities;

  // Nome do Pokémon do qual este evolui (opcional)
  final String? evolvesFrom;

  // Nome do Pokémon para o qual este evolui (opcional)
  final String? evolvesTo;

  // Descrição/biografia do Pokémon
  final String description;

  /// Construtor do modelo Pokemon
  Pokemon({
    required this.id,
    required this.name,
    required this.types,
    required this.imageUrl,
    required this.height,
    required this.weight,
    required this.abilities,
    required this.description,
    this.evolvesFrom,
    this.evolvesTo,
  });

  /// Retorna a altura formatada em metros
  /// Converte de decímetros para metros (divide por 10)
  String get formattedHeight => '${(height / 10).toStringAsFixed(2)} m';

  /// Retorna o peso formatado em quilogramas
  /// Converte de hectogramas para kg (divide por 10)
  String get formattedWeight => '${(weight / 10).toStringAsFixed(2)} kg';

  /// Factory constructor que cria um Pokemon a partir do JSON da API
  ///
  /// [json] - Mapa contendo os dados do Pokémon retornados pela PokéAPI
  /// [customDescription] - Descrição personalizada (opcional)
  ///
  /// Retorna uma instância de Pokemon com os dados parseados
  factory Pokemon.fromJson(
    Map<String, dynamic> json, [
    String? customDescription,
  ]) {
    return Pokemon(
      id: json['id'],
      name: json['name'],
      // Obtém a imagem oficial de alta qualidade
      imageUrl:
          json['sprites']['other']['official-artwork']['front_default'] ?? '',
      // Extrai os tipos do Pokémon
      types: List<String>.from(
        (json['types'] as List).map((t) => t['type']['name']),
      ),
      height: (json['height'] as num).toDouble(),
      weight: (json['weight'] as num).toDouble(),
      // Extrai as habilidades do Pokémon
      abilities: List<String>.from(
        (json['abilities'] as List).map((a) => a['ability']['name']),
      ),
      description: customDescription ?? 'Descrição não disponível',
    );
  }
}
