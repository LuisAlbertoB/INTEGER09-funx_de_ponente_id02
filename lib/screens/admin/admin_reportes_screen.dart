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
  int _totalClusters = 0;
  List<dynamic> _grupos = [];
  late AnimationController _animationController;

  // Paleta de colores para los clusters
  final List<Color> _clusterColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF10B981), // Emerald
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF14B8A6), // Teal
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchClustering();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getClusterColor(int index) {
    return _clusterColors[index % _clusterColors.length];
  }

  Future<void> _fetchClustering() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _adminService.getReportesClustering();
      setState(() {
        _totalClusters = result['total_clusters'] ?? 0;
        _grupos = result['grupos'] ?? [];
        _isLoading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          if (_isLoading)
            const SliverFillRemaining(child: _LoadingState())
          else if (_error != null)
            SliverFillRemaining(child: _ErrorState(error: _error!, onRetry: _fetchClustering))
          else if (_grupos.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else ...[
                SliverToBoxAdapter(child: _buildStatsSection()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final delay = index * 0.1;
                            final animValue = Curves.easeOutBack.transform(
                              ((_animationController.value - delay) / (1 - delay)).clamp(0.0, 1.0),
                            );
                            return Transform.translate(
                              offset: Offset(0, 30 * (1 - animValue)),
                              child: Opacity(
                                opacity: animValue,
                                child: _buildClusterCard(_grupos[index], index),
                              ),
                            );
                          },
                        );
                      },
                      childCount: _grupos.length,
                    ),
                  ),
                ),
              ],
        ],
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Asociación Inteligente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Icon(
                  Icons.bubble_chart,
                  size: 200,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 60,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Potenciado por IA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final totalReportes = _grupos.fold<int>(
      0,
          (sum, grupo) => sum + ((grupo['reportes'] as List?)?.length ?? 0),
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Grupos', '$_totalClusters', Icons.category_rounded, const Color(0xFF6366F1))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Reportes', '$totalReportes', Icons.description_rounded, const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Agrupaciones Semánticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Los incidentes han sido asociados inteligentemente basándose en su contexto, sentimiento y coincidencias.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClusterCard(dynamic grupo, int index) {
    final reportes = grupo['reportes'] as List<dynamic>? ?? [];
    final clusterId = grupo['cluster_id'];
    final color = _getClusterColor(index);

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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${reportes.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Text(
                  'items',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          title: Text(
            'Asociación #$clusterId',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF1E293B),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${reportes.length} incidentes relacionados',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...reportes.asMap().entries.map((entry) {
              final reporte = entry.value;
              return _buildReporteItem(reporte, color);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteItem(dynamic reporte, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reporte['titulo'] ?? 'Sin título',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 14, color: accentColor),
                    const SizedBox(width: 4),
                    Text(
                      reporte['aula']?['nombre_clave'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reporte['descripcion'] ?? 'Sin descripción',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Widgets de estado extraídos para mejor legibilidad
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 32),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analizando reportes...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La IA está identificando patrones semánticos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
            ),
            const SizedBox(height: 24),
            const Text(
              'Error en el análisis',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          const Text(
            'Sin reportes para analizar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aún no hay reportes registrados en el sistema',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
