import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../constants/pokemon_types.dart';
import '../services/pokemon_service.dart';
import '../db/database_helper.dart';

class PokemonDetailScreen extends StatefulWidget {
  final Pokemon pokemon;
  final bool isFromTeamBuilder;

  const PokemonDetailScreen({
    Key? key,
    required this.pokemon,
    this.isFromTeamBuilder = false,
  }) : super(key: key);

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final PokemonService _pokemonService = PokemonService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Pokemon>? _evolutions;
  bool _loadingEvolutions = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadEvolutions();
    _checkIfFavorite();
  }

  Future<void> _loadEvolutions() async {
    try {
      final evolutions = await _pokemonService.fetchEvolutions(
        widget.pokemon.id,
      );
      setState(() {
        _evolutions = evolutions;
        _loadingEvolutions = false;
      });
    } catch (e) {
      print('Erro ao carregar evoluções: $e');
      setState(() {
        _evolutions = [];
        _loadingEvolutions = false;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    final favorites = await _dbHelper.getFavorites();
    setState(() {
      _isFavorite = favorites.any((p) => p.id == widget.pokemon.id);
    });
  }

  Future<void> _toggleFavorite() async {
    if (_isFavorite) {
      await _dbHelper.removeFavorite(widget.pokemon.id);
    } else {
      await _dbHelper.addFavorite(widget.pokemon);
    }
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryType = widget.pokemon.types.first;
    final typeColor = PokemonTypes.getTypeColor(primaryType);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
              onPressed: () => Navigator.pop(context),
            ),
            IconButton(
              icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
              tooltip: 'Favoritar',
              onPressed: _toggleFavorite,
            ),
            if (widget.isFromTeamBuilder)
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.pop(context, widget.pokemon);
                },
              ),
          ],
        ),
        title: Text(widget.pokemon.name.toUpperCase()),
        backgroundColor: typeColor,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabeçalho com Imagem
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [typeColor, typeColor.withValues(alpha: 0.5)],
            ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    '#${widget.pokemon.id.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.network(
                    widget.pokemon.imageUrl,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.error,
                        size: 200,
                        color: Colors.grey,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.pokemon.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Tipos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TIPOS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: widget.pokemon.types.map((type) {
                      return Chip(
                        label: Text(
                          type.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: PokemonTypes.getTypeColor(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Informações físicas
                  const Text(
                    'INFORMAÇÕES',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Altura: ', widget.pokemon.formattedHeight),
                  _buildInfoRow('Peso: ', widget.pokemon.formattedWeight),
                  const SizedBox(height: 20),
                  // Habilidades
                  const Text(
                    'HABILIDADES',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.pokemon.abilities.map((ability) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            ability.toUpperCase(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                  // Descrição
                  const Text(
                    'DESCRIÇÃO',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.pokemon.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 20),
                  // Evoluções
                  const Text(
                    'EVOLUÇÕES',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _loadingEvolutions
                      ? const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _evolutions == null || _evolutions!.isEmpty
                      ? const Text('Nenhuma evolução disponível.')
                      : SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _evolutions!.length,
                            itemBuilder: (context, index) {
                              final evolution = _evolutions![index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PokemonDetailScreen(
                                        pokemon: evolution,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        evolution.imageUrl,
                                        height: 80,
                                        fit: BoxFit.contain,
                                      ),
                                      Text(
                                        evolution.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text('#${evolution.id}'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Botão grande de adicionar ao time
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context, widget.pokemon),
                      icon: const Icon(Icons.add),
                      label: const Text('ADICIONAR AO TIME'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: typeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
