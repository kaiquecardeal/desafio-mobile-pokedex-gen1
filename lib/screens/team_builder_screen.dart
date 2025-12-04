import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../models/team.dart';
import '../services/pokemon_service.dart';
import '../db/database_helper.dart';
import '../constants/pokemon_types.dart';
import 'pokemon_detail_screen.dart';

class TeamBuilderScreen extends StatefulWidget {
  const TeamBuilderScreen({Key? key}) : super(key: key);

  @override
  State<TeamBuilderScreen> createState() => _TeamBuilderScreenState();
}

class _TeamBuilderScreenState extends State<TeamBuilderScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final PokemonService _pokemonService = PokemonService();
  List<Pokemon> _selectedPokemon = [];
  List<Team> _savedTeams = [];
  Team? _editingTeam;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    final teams = await _dbHelper.getTeams();
    setState(() => _savedTeams = teams);
  }

  Future<List<Pokemon>> _loadTeamPokemon(Team team) async {
    final pokemonList = <Pokemon>[];
    for (final id in team.pokemonIds) {
      try {
        final pokemon = await _pokemonService.fetchPokemonByIdOrName(
          id.toString(),
        );
        if (pokemon != null) {
          pokemonList.add(pokemon);
        }
      } catch (e) {
        print('Erro ao carregar Pokémon $id: $e');
      }
    }
    return pokemonList;
  }

  Future<void> _addPokemon() async {
    if (_selectedPokemon.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time completo! Máximo de 6 Pokémons')),
      );
      return;
    }

    final pokemon = await _showPokemonPicker();

    if (pokemon != null) {
      _handlePokemonSelection(pokemon);
    }
  }

  void _handlePokemonSelection(Pokemon pokemon) {
    if (_selectedPokemon.any((p) => p.id == pokemon.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este Pokémon já está no time')),
      );
    } else {
      setState(() => _selectedPokemon.add(pokemon));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pokemon.name} adicionado ao time!')),
      );
    }
  }

  Future<Pokemon?> _showPokemonPicker() async {
    final controller = TextEditingController();
    bool isSearching = false;
    String? errorMessage;

    return showDialog<Pokemon>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Buscar Pokémon'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Nome ou ID',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                  onSubmitted: (_) async {
                    if (!isSearching) {
                      final query = controller.text.trim();
                      if (query.isNotEmpty) {
                        setDialogState(() {
                          isSearching = true;
                          errorMessage = null;
                        });

                        try {
                          final pokemon = await _pokemonService
                              .fetchPokemonByIdOrName(query);

                          if (!context.mounted) return;

                          if (pokemon != null) {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PokemonDetailScreen(pokemon: pokemon),
                              ),
                            );

                            if (result != null && result is Pokemon) {
                              _handlePokemonSelection(result);
                            }
                          } else {
                            setDialogState(() {
                              isSearching = false;
                              errorMessage = 'Pokémon não encontrado';
                            });
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() {
                            isSearching = false;
                            errorMessage = 'Erro ao buscar: $e';
                          });
                        }
                      }
                    }
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
                if (isSearching) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSearching ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: isSearching
                    ? null
                    : () async {
                        final query = controller.text.trim();
                        if (query.isEmpty) {
                          setDialogState(() {
                            errorMessage = 'Digite um nome ou ID';
                          });
                          return;
                        }

                        setDialogState(() {
                          isSearching = true;
                          errorMessage = null;
                        });

                        try {
                          final pokemon = await _pokemonService
                              .fetchPokemonByIdOrName(query);

                          if (!context.mounted) return;

                          if (pokemon != null) {
                            Navigator.pop(context);
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PokemonDetailScreen(pokemon: pokemon),
                              ),
                            );

                            if (result != null && result is Pokemon) {
                              _handlePokemonSelection(result);
                            }
                          } else {
                            setDialogState(() {
                              isSearching = false;
                              errorMessage = 'Pokémon não encontrado';
                            });
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          setDialogState(() {
                            isSearching = false;
                            errorMessage = 'Erro ao buscar: $e';
                          });
                        }
                      },
                child: const Text('Ver Detalhes'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveTeam() async {
    if (_selectedPokemon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos 1 Pokémon')),
      );
      return;
    }

    final controller = TextEditingController(text: _editingTeam?.name ?? '');

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_editingTeam != null ? 'Atualizar Time' : 'Nome do Time'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Digite o nome'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(_editingTeam != null ? 'Atualizar' : 'Salvar'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      if (_editingTeam != null) {
        final updatedTeam = Team(
          id: _editingTeam!.id,
          name: name,
          pokemonIds: _selectedPokemon.map((p) => p.id).toList(),
        );
        await _dbHelper.updateTeam(updatedTeam);
        setState(() {
          _selectedPokemon.clear();
          _editingTeam = null;
        });
        _loadTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time atualizado com sucesso!')),
          );
        }
      } else {
        final team = Team(
          name: name,
          pokemonIds: _selectedPokemon.map((p) => p.id).toList(),
        );
        await _dbHelper.createTeam(team);
        setState(() => _selectedPokemon.clear());
        _loadTeams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Time salvo com sucesso!')),
          );
        }
      }
    }
  }

  Future<void> _showTeamDetails(Team team) async {
    final pokemonList = <Pokemon>[];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    for (final id in team.pokemonIds) {
      final pokemon = await _pokemonService.fetchPokemonByIdOrName(
        id.toString(),
      );
      if (pokemon != null) {
        pokemonList.add(pokemon);
      }
    }

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(team.name),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: pokemonList.length,
            itemBuilder: (context, index) {
              final pokemon = pokemonList[index];
              return ListTile(
                leading: Image.network(
                  pokemon.imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
                title: Text(pokemon.name),
                subtitle: Text('#${pokemon.id}'),
                trailing: Wrap(
                  spacing: 4,
                  children: pokemon.types.map((type) {
                    return Chip(
                      label: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: PokemonTypes.getTypeColor(type),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editTeam(Team team) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final pokemonList = await _loadTeamPokemon(team);

    if (!mounted) return;
    Navigator.pop(context);

    setState(() {
      _selectedPokemon = pokemonList;
      _editingTeam = team;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editando time: ${team.name}')));
  }

  void _cancelEdit() {
    setState(() {
      _selectedPokemon.clear();
      _editingTeam = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Edição cancelada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: _editingTeam != null ? 150 : 100,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Voltar',
              onPressed: () => Navigator.pop(context),
            ),
            if (_editingTeam != null)
              IconButton(
                icon: const Icon(Icons.cancel),
                tooltip: 'Cancelar Edição',
                onPressed: _cancelEdit,
              ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: _editingTeam != null ? 'Atualizar Time' : 'Salvar Time',
              onPressed: _saveTeam,
            ),
          ],
        ),
        title: Text(
          _editingTeam != null
              ? 'Editando: ${_editingTeam!.name}'
              : 'Montador de Times',
        ),
        backgroundColor: _editingTeam != null ? Colors.orange : Colors.red,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _editingTeam != null ? Colors.orange.shade50 : null,
            child: Column(
              children: [
                Text(
                  'Time Atual (${_selectedPokemon.length}/6)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      if (index < _selectedPokemon.length) {
                        final pokemon = _selectedPokemon[index];
                        return Stack(
                          children: [
                            Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    pokemon.imageUrl,
                                    height: 60,
                                    fit: BoxFit.contain,
                                  ),
                                  Text(
                                    pokemon.name,
                                    style: const TextStyle(fontSize: 10),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() {
                                    _selectedPokemon.removeAt(index);
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        );
                      }
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, size: 40),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Times Salvos',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _savedTeams.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum time salvo ainda',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _savedTeams.length,
                    itemBuilder: (context, index) {
                      final team = _savedTeams[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          leading: const Icon(Icons.groups, color: Colors.red),
                          title: Text(
                            team.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${team.pokemonIds.length} Pokémons'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 80,
                                    child: FutureBuilder<List<Pokemon>>(
                                      future: _loadTeamPokemon(team),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        if (!snapshot.hasData ||
                                            snapshot.data!.isEmpty) {
                                          return const Center(
                                            child: Text('Erro ao carregar'),
                                          );
                                        }

                                        return ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (context, pokemonIndex) {
                                            final pokemon =
                                                snapshot.data![pokemonIndex];
                                            return Container(
                                              width: 70,
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Image.network(
                                                    pokemon.imageUrl,
                                                    height: 50,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  Text(
                                                    pokemon.name,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _showTeamDetails(team),
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 16,
                                        ),
                                        label: const Text('Detalhes'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _editTeam(team),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Editar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Confirmar'),
                                              content: Text(
                                                'Deseja deletar o time "${team.name}"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Deletar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _dbHelper.deleteTeam(
                                              team.id!,
                                            );
                                            _loadTeams();
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Time deletado',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 16,
                                        ),
                                        label: const Text('Deletar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPokemon,
        child: const Icon(Icons.add),
      ),
    );
  }
}
