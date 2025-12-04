// Importações necessárias para gerenciamento de banco de dados
import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/pokemon.dart';
import '../models/team.dart';

/// Helper para gerenciar o banco de dados SQLite local
///
/// Esta classe implementa o padrão Singleton para garantir uma única
/// instância do banco de dados durante toda a execução da aplicação.
/// Gerencia tanto os Pokémons favoritos quanto os times criados.
class DatabaseHelper {
  // Instância única (Singleton)
  static final DatabaseHelper _instace = DatabaseHelper._internal();

  /// Factory constructor que retorna sempre a mesma instância
  factory DatabaseHelper() => _instace;

  /// Construtor privado que inicializa o banco para desktop se necessário
  ///
  /// Para Windows, Linux e macOS, é necessário usar sqflite_ffi
  /// pois o SQLite padrão só funciona nativamente em Android/iOS
  DatabaseHelper._internal() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // Instância do banco de dados
  static Database? _database;

  /// Getter que retorna a instância do banco de dados
  /// Se não existir, cria uma nova instância
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa o banco de dados criando as tabelas necessárias
  ///
  /// Cria duas tabelas:
  /// - favorites: armazena Pokémons favoritados
  /// - teams: armazena times criados pelo usuário
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pokemon_database.db');

    return await openDatabase(
      path,
      version: 2, // Versão atual do banco
      // Callback executado quando o banco é criado pela primeira vez
      onCreate: (db, version) async {
        // Tabela de favoritos com todos os dados do Pokémon
        await db.execute('''CREATE TABLE favorites (
          id INTEGER PRIMARY KEY,
          name TEXT,
          types TEXT,
          imageUrl TEXT,
          height REAL,
          weight REAL,
          abilities TEXT,
          evolvesFrom TEXT,
          evolvesTo TEXT,
          description TEXT
      );''');
        // Tabela de times com nome e IDs dos Pokémons
        await db.execute('''CREATE TABLE teams (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          pokemonIds TEXT
      );''');
      },
      // Callback executado quando há upgrade de versão
      onUpgrade: (db, oldVersion, newVersion) async {
        // Se estava na versão 1, cria a tabela de times
        if (oldVersion < 2) {
          await db.execute('''CREATE TABLE teams (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            pokemonIds TEXT
        );''');
        }
      },
    );
  }

  /// Adiciona um Pokémon aos favoritos
  ///
  /// [pokemon] - Pokémon a ser favoritado
  ///
  /// Se o Pokémon já existir, substitui os dados (REPLACE)
  Future<void> addFavorite(Pokemon pokemon) async {
    final db = await database;
    await db.insert('favorites', {
      'id': pokemon.id,
      'name': pokemon.name,
      'types': pokemon.types.join(','),
      'imageUrl': pokemon.imageUrl,
      'height': pokemon.height,
      'weight': pokemon.weight,
      'abilities': pokemon.abilities.join(','),
      'evolvesFrom': pokemon.evolvesFrom,
      'evolvesTo': pokemon.evolvesTo,
      'description': pokemon.description,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Remove um Pokémon dos favoritos
  ///
  /// [id] - ID do Pokémon a ser removido
  Future<void> removeFavorite(int id) async {
    final db = await database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  /// Retorna todos os Pokémons favoritados
  ///
  /// Busca todos os registros da tabela favorites e reconstrói
  /// os objetos Pokemon a partir dos dados salvos
  Future<List<Pokemon>> getFavorites() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('favorites');

    return List.generate(maps.length, (i) {
      return Pokemon(
        id: maps[i]['id'],
        name: maps[i]['name'],
        // Converte string separada por vírgulas de volta para lista
        types: maps[i]['types'].split(','),
        imageUrl: maps[i]['imageUrl'],
        height: maps[i]['height'],
        weight: maps[i]['weight'],
        abilities: maps[i]['abilities'].split(','),
        evolvesFrom: maps[i]['evolvesFrom'],
        evolvesTo: maps[i]['evolvesTo'],
        description: maps[i]['description'],
      );
    });
  }

  /// Cria um novo time no banco de dados
  ///
  /// [team] - Time a ser criado
  ///
  /// Retorna o ID do time criado
  Future<int> createTeam(Team team) async {
    final db = await database;
    return await db.insert('teams', team.toMap());
  }

  /// Retorna todos os times salvos
  ///
  /// Busca todos os registros da tabela teams e reconstrói
  /// os objetos Team a partir dos dados salvos
  Future<List<Team>> getTeams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('teams');
    return List.generate(maps.length, (i) => Team.fromMap(maps[i]));
  }

  /// Remove um time do banco de dados
  ///
  /// [id] - ID do time a ser removido
  Future<void> deleteTeam(int id) async {
    final db = await database;
    await db.delete('teams', where: 'id = ?', whereArgs: [id]);
  }

  /// Atualiza um time existente no banco de dados
  ///
  /// [team] - Time com dados atualizados (deve conter o ID)
  ///
  /// Útil para editar nome ou composição do time
  Future<void> updateTeam(Team team) async {
    final db = await database;
    await db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }
}
