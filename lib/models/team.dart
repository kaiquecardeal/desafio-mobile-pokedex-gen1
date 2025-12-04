/// Modelo de dados que representa um Time de Pokémons
///
/// Esta classe armazena informações de um time criado pelo usuário,
/// incluindo nome e IDs dos Pokémons selecionados (máximo 6).
class Team {
  // ID único do time no banco de dados (null para novos times)
  final int? id;

  // Nome personalizado do time
  final String name;

  // Lista de IDs dos Pokémons que compõem o time
  final List<int> pokemonIds;

  /// Construtor do modelo Team
  Team({this.id, required this.name, required this.pokemonIds});

  /// Converte o objeto Team em um Map para salvar no banco de dados
  ///
  /// Os IDs dos Pokémons são convertidos em uma string separada por vírgulas
  /// para facilitar o armazenamento no SQLite
  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'pokemonIds': pokemonIds.join(',')};
  }

  /// Factory constructor que cria um Team a partir de um Map do banco de dados
  ///
  /// [map] - Mapa contendo os dados do time retornados do SQLite
  ///
  /// Converte a string de IDs separada por vírgulas de volta para uma lista de inteiros
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      name: map['name'],
      pokemonIds: (map['pokemonIds'] as String)
          .split(',')
          .map((e) => int.parse(e))
          .toList(),
    );
  }
}
