import 'package:flutter/material.dart';
import '../../services/catalogo_service.dart';
import '../qr/qr_landing_screen.dart';

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
        title: const Text('Explorar Catálogo IA', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade900, Colors.deepPurple.shade700],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda semántica
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Qué quieres aprender hoy?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Ej. "tecnología", "arte", "música"...',
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(Icons.auto_awesome, color: Colors.indigo),
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _onSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final id = evento['id_conferencia'] as int?;
                final titulo = (evento['titulo'] as String?) ?? 'Evento';
                if (id != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrLandingScreen(
                        idConferencia: id,
                        tituloEvento: titulo,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.event, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            evento['titulo'] ?? 'Evento',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            evento['descripcion'] ?? 'Sin descripción',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
