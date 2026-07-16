import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/catalogo_service.dart';
import '../ponente/conferencias_screen.dart';
import '../admin/admin_usuarios_screen.dart';
import '../admin/admin_reportes_screen.dart'; // NEW
import '../catalogo/infraestructura_screen.dart';
import '../catalogo/periodos_screen.dart';
import '../catalogo/catalogo_eventos_screen.dart'; // NEW
import '../events/recomendados_screen.dart'; // NEW
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _catalogoService = CatalogoService();
  bool? _serverOnline;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final ok = await _catalogoService.checkHealth();
    if (mounted) setState(() => _serverOnline = ok);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UniEvents'),
        actions: [
          // Indicador de estado del servidor
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.cloud,
                color: _serverOnline == null
                    ? Colors.grey
                    : _serverOnline! ? Colors.green : Colors.red,
              ),
              tooltip: _serverOnline == null
                  ? 'Verificando servidor...'
                  : _serverOnline! ? 'Servidor en línea' : 'Servidor fuera de línea',
              onPressed: _checkServer,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola, ${user?.nombreCompleto.split(' ').first ?? 'Usuario'} 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rol: ${user?.rol ?? ''}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // === SECCIÓN IA (PARA TODOS LOS USUARIOS) ===
              const Text('Explorar Eventos (IA)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.deepPurple)),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.auto_awesome,
                title: 'Para Ti',
                subtitle: 'Eventos recomendados según tu perfil',
                color: Colors.deepPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RecomendadosScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _MenuCard(
                icon: Icons.psychology,
                title: 'Catálogo Semántico',
                subtitle: 'Buscador inteligente de eventos',
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogoEventosScreen()),
                ),
              ),
              const SizedBox(height: 20),

              // Sección Ponente
              if (user?.isPonente ?? false) ...[
                const Text('Módulo Ponente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.mic_none,
                  title: 'Mis Conferencias',
                  subtitle: 'Crear, editar y gestionar charlas',
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConferenciasScreen()),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Sección Admin
              if (user?.isAdmin ?? false) ...[
                const Text('Administración', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red)),
                const SizedBox(height: 12),
                _MenuCard(
                  icon: Icons.people_outline,
                  title: 'Gestión de Usuarios',
                  subtitle: 'Crear, activar/desactivar y eliminar',
                  color: Colors.red,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsuariosScreen()),
                  ),
                ),
                const SizedBox(height: 8),
                _MenuCard(
                  icon: Icons.bubble_chart,
                  title: 'Reportes (IA)',
                  subtitle: 'Agrupamiento inteligente de daños',
                  color: Colors.red.shade800,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminReportesScreen()),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Sección Catálogos
              const Text('Recursos Físicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.business,
                title: 'Infraestructura',
                subtitle: 'Edificios y aulas disponibles',
                color: Colors.blueGrey,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfraestructuraScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _MenuCard(
                icon: Icons.calendar_month,
                title: 'Periodos Académicos',
                subtitle: 'Consultar cuatrimestres',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PeriodosScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
