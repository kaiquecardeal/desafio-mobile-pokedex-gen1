import 'package:flutter/material.dart';
import 'package:projects/screens/team_builder_screen.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../db/database_helper.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final PokemonService _pokemonService = PokemonService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  late TabController _tabController;

  List<Pokemon> _filteredList = [];
  List<Pokemon> _pokemonList = [];
  List<Pokemon> _favoritesList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 2, vsync: this);
    _loadPokemon();
    _loadFavorites();
    _searchController.addListener(_filterPokemon);
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 100) {
      if (!_isLoadingMore) {
        _loadMorePokemon();
      }
    }
  }

  Future<void> _loadPokemon() async {
    try {
      final pokemonList = await _pokemonService.fetchGen1Pokemon(
        offset: 0,
        limit: 20,
      );
      setState(() {
        _pokemonList = pokemonList;
        _filteredList = pokemonList;
        _isLoading = false;
        _currentOffset = 20;
      });
    } catch (e) {
      print('Erro ao carregar Pokémons: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePokemon() async {
    if (_isLoadingMore || _currentOffset >= 151 || _isSearching) return;

    setState(() => _isLoadingMore = true);

    try {
      final morePokemon = await _pokemonService.fetchGen1Pokemon(
        offset: _currentOffset,
        limit: 20,
      );
      setState(() {
        _pokemonList.addAll(morePokemon);
        _filteredList.addAll(morePokemon);
        _currentOffset += 20;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Erro ao carregar mais Pokémons: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _dbHelper.getFavorites();
      setState(() {
        _favoritesList = favorites;
      });
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
    }
  }

  void _filterPokemon() async {
    String query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _filteredList = _pokemonList;
      });
      return;
    }

    setState(() => _isSearching = true);

    final result = await _pokemonService.fetchPokemonByIdOrName(query);

    setState(() {
      if (result != null) {
        _filteredList = [result];
      } else {
        _filteredList = _pokemonList
            .where((p) => p.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 400) return 2;
    if (width >= 700) return 3;
    if (width >= 1000) return 4;
    return 5;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _searchController.clear();
      _filterPokemon();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 120,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Montador de Times',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeamBuilderScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        title: const Text('Pokédex'),
        backgroundColor: Colors.red,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por nome ou ID',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Favoritos'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPokemonGrid(_filteredList, _isLoading),
          _buildPokemonGrid(_favoritesList, false),
        ],
      ),
    );
  }

  Widget _buildPokemonGrid(List<Pokemon> list, bool isLoading) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadPokemon,
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: 0.85,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final pokemon = list[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PokemonDetailScreen(pokemon: pokemon),
                      ),
                    ).then((_) => _loadFavorites());
                  },
                  child: PokemonCard(pokemon: pokemon),
                );
              },
            ),
          );
  }
}
