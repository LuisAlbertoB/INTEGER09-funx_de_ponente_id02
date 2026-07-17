import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminReportesScreen extends StatefulWidget {
  const AdminReportesScreen({super.key});

  @override
  State<AdminReportesScreen> createState() => _AdminReportesScreenState();
}

class _AdminReportesScreenState extends State<AdminReportesScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();

  bool _isLoading = true;
  String? _error;

  // Grupos originales recibidos del servidor
  List<dynamic> _rawGruposPorAula      = [];
  List<dynamic> _rawGruposPorDocente   = [];
  List<dynamic> _rawGruposPorSentimiento = [];
  
  // Grupos filtrados que se muestran en la UI
  List<dynamic> _gruposPorAula      = [];
  List<dynamic> _gruposPorDocente   = [];
  List<dynamic> _gruposPorSentimiento = [];
  
  int _totalReportes = 0;
  int _totalProcesados = 0;

  // Filtro de fecha seleccionado
  String _filtroFecha = 'Todos';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClustering();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClustering() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _adminService.getReportesClustering();
      setState(() {
        _totalReportes           = result['total_reportes'] ?? 0;
        _totalProcesados         = result['total_procesados'] ?? 0;
        _rawGruposPorAula        = result['grupos_por_aula']       ?? [];
        _rawGruposPorDocente     = result['grupos_por_docente']    ?? [];
        _rawGruposPorSentimiento = result['grupos_por_sentimiento']?? [];
        _isLoading = false;
      });
      _aplicarFiltroFecha();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _aplicarFiltroFecha() {
    if (_filtroFecha == 'Todos') {
      setState(() {
        _gruposPorAula = List.from(_rawGruposPorAula);
        _gruposPorDocente = List.from(_rawGruposPorDocente);
        _gruposPorSentimiento = List.from(_rawGruposPorSentimiento);
      });
      return;
    }

    final now = DateTime.now();
    DateTime limite;
    if (_filtroFecha == 'Últimos 7 días') {
      limite = now.subtract(const Duration(days: 7));
    } else if (_filtroFecha == 'Último mes') {
      limite = now.subtract(const Duration(days: 30));
    } else {
      limite = now.subtract(const Duration(days: 3650));
    }

    List<dynamic> filtrarGrupo(List<dynamic> grupos) {
      final List<dynamic> resultado = [];
      for (var grupo in grupos) {
        final reportes = grupo['reportes'] as List<dynamic>? ?? [];
        final reportesFiltrados = reportes.where((r) {
          if (r['fecha_reporte'] == null) return true; // Si no hay fecha, no ocultar
          try {
            final f = DateTime.parse(r['fecha_reporte'].toString());
            return f.isAfter(limite) || f.isAtSameMomentAs(limite);
          } catch (_) {
            return true;
          }
        }).toList();

        if (reportesFiltrados.isNotEmpty) {
          // Copiar el grupo pero con la lista de reportes filtrada
          final Map<String, dynamic> grupoCopia = Map<String, dynamic>.from(grupo);
          grupoCopia['reportes'] = reportesFiltrados;
          resultado.add(grupoCopia);
        }
      }
      return resultado;
    }

    setState(() {
      _gruposPorAula = filtrarGrupo(_rawGruposPorAula);
      _gruposPorDocente = filtrarGrupo(_rawGruposPorDocente);
      _gruposPorSentimiento = filtrarGrupo(_rawGruposPorSentimiento);
    });
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [_buildSliverAppBar()],
        body: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _fetchClustering,
              backgroundColor: const Color(0xFF1E293B),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text('Reanalizar', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      floating: false,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 56),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reportes IA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                if (!_isLoading && _error == null)
                  Text(
                    '$_totalProcesados/$_totalReportes procesados',
                    style: const TextStyle(fontSize: 11, color: Colors.white60),
                  ),
              ],
            ),
            // Widget de filtro de fechas
            if (!_isLoading && _error == null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: Colors.white),
                tooltip: 'Filtrar por fecha',
                onSelected: (valor) {
                  setState(() => _filtroFecha = valor);
                  _aplicarFiltroFecha();
                },
                itemBuilder: (context) => [
                  _buildPopupMenuItem('Todos'),
                  _buildPopupMenuItem('Últimos 7 días'),
                  _buildPopupMenuItem('Último mes'),
                ],
              )
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: -40, top: -20,
                child: Icon(Icons.manage_search_rounded, size: 200, color: Colors.white.withOpacity(0.05))),
              Positioned(
                left: 20, bottom: 16,
                child: Wrap(spacing: 8, children: [
                  _chip(Icons.location_on, '${_gruposPorAula.length} Aulas', Colors.blue.shade300),
                  _chip(Icons.person_pin, '${_gruposPorDocente.length} Docentes', Colors.purple.shade300),
                  _chip(Icons.sentiment_dissatisfied, '${_gruposPorSentimiento.length} Grupos', Colors.orange.shade300),
                ]),
              ),
            ],
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue.shade300,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: [
          Tab(icon: const Icon(Icons.location_on, size: 18), text: 'Por Aula (${_gruposPorAula.length})'),
          Tab(icon: const Icon(Icons.person_pin, size: 18), text: 'Por Docente (${_gruposPorDocente.length})'),
          Tab(icon: const Icon(Icons.mood, size: 18), text: 'Por Sentimiento'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String valor) {
    return PopupMenuItem<String>(
      value: valor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(valor),
          if (_filtroFecha == valor)
            const Icon(Icons.check, color: Color(0xFF3B82F6), size: 18),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── Content ──────────────────────────────────────────────────

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTabAula(),
        _buildTabDocente(),
        _buildTabSentimiento(),
      ],
    );
  }

  // TAB 1 — Por Aula
  Widget _buildTabAula() {
    if (_gruposPorAula.isEmpty) {
      return _buildEmptyTab(
        Icons.location_off,
        'Sin ubicaciones detectadas',
        'La IA no encontró nombres de aulas en los textos de los reportes. Asegúrate de que los reportes mencionen el aula (ej. "Aula A-101").',
        Colors.blue,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _gruposPorAula.length,
      itemBuilder: (ctx, i) {
        final grupo = _gruposPorAula[i];
        return _buildGrupoCard(
          icon: Icons.meeting_room_rounded,
          color: const Color(0xFF3B82F6),
          titulo: grupo['aula']?.toString() ?? 'Aula desconocida',
          subtitulo: '${(grupo['reportes'] as List).length} incidencias en esta ubicación',
          reportes: grupo['reportes'] as List,
          accentColor: const Color(0xFF3B82F6),
        );
      },
    );
  }

  // TAB 2 — Por Docente
  Widget _buildTabDocente() {
    if (_gruposPorDocente.isEmpty) {
      return _buildEmptyTab(
        Icons.person_off,
        'Sin docentes detectados',
        'La IA no encontró nombres de personas en los textos de los reportes. Los reportes que mencionen a algún docente aparecerán aquí.',
        Colors.purple,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _gruposPorDocente.length,
      itemBuilder: (ctx, i) {
        final grupo = _gruposPorDocente[i];
        return _buildGrupoCard(
          icon: Icons.school_rounded,
          color: const Color(0xFF8B5CF6),
          titulo: grupo['docente']?.toString() ?? 'Docente desconocido',
          subtitulo: '${(grupo['reportes'] as List).length} reportes que mencionan a esta persona',
          reportes: grupo['reportes'] as List,
          accentColor: const Color(0xFF8B5CF6),
        );
      },
    );
  }

  // TAB 3 — Por Sentimiento
  Widget _buildTabSentimiento() {
    final colores = {
      'NEGATIVO': const Color(0xFFEF4444),
      'NEUTRAL':  const Color(0xFFF59E0B),
      'POSITIVO': const Color(0xFF10B981),
    };
    final iconos = {
      'NEGATIVO': Icons.sentiment_very_dissatisfied_rounded,
      'NEUTRAL':  Icons.sentiment_neutral_rounded,
      'POSITIVO': Icons.sentiment_very_satisfied_rounded,
    };
    final etiquetas = {
      'NEGATIVO': '🔴 Urgentes — Quejas y daños graves',
      'NEUTRAL':  '🟡 Moderados — Observaciones y avisos',
      'POSITIVO': '🟢 Leves — Comentarios positivos',
    };

    if (_gruposPorSentimiento.isEmpty) {
      return _buildEmptyTab(Icons.mood_bad, 'Sin datos de sentimiento', '', Colors.orange);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _gruposPorSentimiento.length,
      itemBuilder: (ctx, i) {
        final grupo = _gruposPorSentimiento[i];
        final sent  = grupo['sentimiento']?.toString() ?? 'NEUTRAL';
        final color = colores[sent] ?? Colors.grey;
        return _buildGrupoCard(
          icon: iconos[sent] ?? Icons.mood,
          color: color,
          titulo: etiquetas[sent] ?? sent,
          subtitulo: '${(grupo['reportes'] as List).length} reportes clasificados por sentimiento',
          reportes: grupo['reportes'] as List,
          accentColor: color,
        );
      },
    );
  }

  // ─── Reusable group card ──────────────────────────────────────

  Widget _buildGrupoCard({
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    required List reportes,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Icon(icon, color: color, size: 26),
              Positioned(right: 2, top: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Text('${reportes.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B))),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(subtitulo, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...reportes.map((r) => _buildReporteItem(r, accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteItem(dynamic r, Color accent) {
    final importancia = r['ia_importancia']?.toString() ?? '';
    final sentimiento = r['ia_sentimiento']?.toString() ?? '';
    final aula        = r['ia_aula_detectada']?.toString();
    final docente     = r['ia_docente_detectado']?.toString();
    final titulo      = r['titulo']?.toString() ?? 'Sin título';
    final descripcion = r['descripcion']?.toString() ?? '';

    final impColor = importancia == 'ALTA' ? Colors.red.shade400
        : importancia == 'MEDIA' ? Colors.orange.shade400
        : Colors.green.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: impColor, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título + badge de importancia
        Row(children: [
          Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: impColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(importancia, style: TextStyle(color: impColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        // Descripción
        Text(descripcion, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4)),
        const SizedBox(height: 10),
        // Metadata row: aula detectada | docente | sentimiento
        Wrap(spacing: 6, runSpacing: 4, children: [
          if (aula != null) _tag(Icons.meeting_room, aula, Colors.blue.shade600),
          if (docente != null) _tag(Icons.person, docente, Colors.purple.shade600),
          _tag(
            sentimiento == 'NEGATIVO' ? Icons.sentiment_dissatisfied
                : sentimiento == 'POSITIVO' ? Icons.sentiment_satisfied
                : Icons.sentiment_neutral,
            sentimiento,
            sentimiento == 'NEGATIVO' ? Colors.red.shade600
                : sentimiento == 'POSITIVO' ? Colors.green.shade600
                : Colors.orange.shade700,
          ),
        ]),
      ]),
    );
  }

  Widget _tag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ─── States ───────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 72, height: 72,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 72, height: 72,
              child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF3B82F6))),
            Icon(Icons.manage_search_rounded, color: Color(0xFF1E40AF), size: 30),
          ]),
        ),
        SizedBox(height: 24),
        Text('Analizando reportes con IA...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        SizedBox(height: 8),
        Text('NER + Análisis de Sentimiento en proceso', style: TextStyle(fontSize: 13, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
          ),
          const SizedBox(height: 24),
          const Text('Error en el análisis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchClustering,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmptyTab(IconData icon, String title, String subtitle, MaterialColor color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 72, color: color.shade200),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color.shade700)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5)),
          ],
        ]),
      ),
    );
  }
}
