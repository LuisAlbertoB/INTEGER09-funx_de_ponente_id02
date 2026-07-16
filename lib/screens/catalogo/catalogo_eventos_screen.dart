import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';

class CatalogoEventosScreen extends StatefulWidget {
  const CatalogoEventosScreen({super.key});

  @override
  State<CatalogoEventosScreen> createState() => _CatalogoEventosScreenState();
}

class _CatalogoEventosScreenState extends State<CatalogoEventosScreen> {
  final CatalogoService _catalogoService = CatalogoService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  String? _error;
  List<dynamic> _eventos = [];

  @override
  void initState() {
    super.initState();
    _fetchEventos();
  }

  Future<void> _fetchEventos([String? query]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _catalogoService.getEventosSemanticos(buscar: query);
      setState(() {
        _eventos = result['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearch() {
    FocusScope.of(context).unfocus();
    _fetchEventos(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo Inteligente (IA)'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda semántica
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Buscador Semántico',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Ej. "tecnología", "arte", "música"...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.psychology, color: Colors.indigo),
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Icon(Icons.search),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de resultados
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.indigo));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    if (_eventos.isEmpty) {
      return const Center(
        child: Text('No se encontraron eventos.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final evento = _eventos[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.indigo.shade100,
              radius: 24,
              child: const Icon(Icons.event, color: Colors.indigo),
            ),
            title: Text(
              evento['titulo'] ?? 'Evento',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                evento['descripcion'] ?? 'Sin descripción',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navegar a detalles del evento si existe la pantalla
            },
          ),
        );
      },
    );
  }
}
