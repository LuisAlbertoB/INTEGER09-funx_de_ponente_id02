import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/event_service.dart';

/// Foro de comunidad de un evento.
/// Consume GET + POST /api/eventos/:id/foro
class ForoEventoScreen extends StatefulWidget {
  final int idEvento;
  final String tituloEvento;

  const ForoEventoScreen({
    super.key,
    required this.idEvento,
    required this.tituloEvento,
  });

  @override
  State<ForoEventoScreen> createState() => _ForoEventoScreenState();
}

class _ForoEventoScreenState extends State<ForoEventoScreen> {
  final _service = EventService();
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _comentarios = [];
  bool _loading = true;
  bool _sending = false;
  int? _respondiendo; // id del comentario padre al que se responde

  @override
  void initState() {
    super.initState();
    _loadForo();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadForo() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getForo(widget.idEvento);
      if (mounted) setState(() { _comentarios = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enviar() async {
    final texto = _msgCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() => _sending = true);
    try {
      await _service.postComentario(
        widget.idEvento,
        texto,
        idComentarioPadre: _respondiendo,
      );
      _msgCtrl.clear();
      if (mounted) setState(() { _respondiendo = null; _sending = false; });
      await _loadForo();
      // Hacer scroll hasta abajo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFecha(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM, HH:mm', 'es').format(dt);
    } catch (_) {
      return '';
    }
  }

  Widget _buildComentario(Map<String, dynamic> c, {bool esRespuesta = false}) {
    final nombre = (c['usuario']?['nombre_completo'] as String?) ?? 'Usuario';
    final mensaje = (c['mensaje'] as String?) ?? '';
    final fecha = _formatFecha(c['created_at'] as String?);
    final idComentario = c['id_comentario'] as int?;
    final List<dynamic> hijos = c['respuestas'] ?? [];

    return Padding(
      padding: EdgeInsets.only(left: esRespuesta ? 28 : 0, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: esRespuesta
                  ? Colors.deepPurple.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: esRespuesta
                  ? Border(
                      left: BorderSide(
                        color: Colors.deepPurple.shade200,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      fecha,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(mensaje),
                if (idComentario != null && !esRespuesta) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() => _respondiendo = idComentario);
                      FocusScope.of(context).requestFocus(FocusNode());
                    },
                    child: Text(
                      'Responder',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Respuestas anidadas
          ...hijos.map(
            (h) => _buildComentario(
              h as Map<String, dynamic>,
              esRespuesta: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comunidad', style: TextStyle(fontSize: 16)),
            Text(
              widget.tituloEvento,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadForo,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de comentarios ─────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _comentarios.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Sé el primero en comentar',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _comentarios.length,
                        itemBuilder: (_, i) =>
                            _buildComentario(_comentarios[i]),
                      ),
          ),

          // ── Banner de respuesta activa ───────────────────────────────
          if (_respondiendo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepPurple.shade50,
              child: Row(
                children: [
                  Icon(Icons.reply, size: 16, color: Colors.deepPurple.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Respondiendo al comentario #$_respondiendo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepPurple.shade600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _respondiendo = null),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            ),

          // ── Caja de mensaje ──────────────────────────────────────────
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded,
                                color: Colors.white),
                            onPressed: _enviar,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
