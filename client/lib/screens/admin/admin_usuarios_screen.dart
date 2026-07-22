import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'crear_usuario_screen.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _service = AdminService();
  List<Map<String, dynamic>> _usuarios = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _usuarios = await _service.getUsuarios();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggleEstado(int id, int estadoActual) async {
    try {
      await _service.updateEstadoUsuario(id, estadoActual == 1 ? 0 : 1);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar usuario'),
        content: const Text(
          '¿Estas seguro? Esta accion no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteUsuario(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _rolColor(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red;
      case 'ponente':
        return Colors.deepPurple;
      case 'coordinador':
        return Colors.orange;
      case 'participante':
        return Colors.blue;
      case 'asistente':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'admin':
        return 'Admin';
      case 'ponente':
        return 'Ponente';
      case 'coordinador':
        return 'Coordinador';
      case 'participante':
        return 'Participante';
      case 'asistente':
        return 'Asistente';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestion de Usuarios',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_usuarios.length} registrados',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CrearUsuarioScreen()),
          );
          if (created == true) _load();
        },
        backgroundColor: Colors.deepPurple,
        elevation: 3,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Nuevo usuario',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
            : _usuarios.isEmpty
            ? RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            children: const [
              SizedBox(height: 140),
              Icon(
                Icons.people_outline_rounded,
                size: 72,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Center(
                child: Text(
                  'No hay usuarios registrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        )
            : RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
            itemCount: _usuarios.length,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final u = _usuarios[i];
              final id = u['id_usuario'] as int;
              final nombre =
                  u['nombre_completo'] as String? ?? '-';
              final matricula = u['matricula'] as String? ?? '-';
              final rol =
                  u['rol'] as String? ?? 'usuario_general';
              final estado = u['estado'] as int? ?? 1;
              final rolColor = _rolColor(rol);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: rolColor.withOpacity(0.12),
                    child: Icon(
                      Icons.person_rounded,
                      color: rolColor,
                      size: 26,
                    ),
                  ),
                  title: Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          matricula,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: rolColor.withOpacity(0.10),
                                borderRadius:
                                BorderRadius.circular(30),
                              ),
                              child: Text(
                                _rolLabel(rol),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: rolColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: estado == 1
                                    ? Colors.green.withOpacity(
                                    0.10)
                                    : Colors.red.withOpacity(0.10),
                                borderRadius:
                                BorderRadius.circular(30),
                              ),
                              child: Text(
                                estado == 1
                                    ? 'Activo'
                                    : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: estado == 1
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) {
                      if (val == 'toggle') {
                        _toggleEstado(id, estado);
                      }
                      if (val == 'delete') {
                        _delete(id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              estado == 1
                                  ? Icons.toggle_off_rounded
                                  : Icons.toggle_on_rounded,
                              size: 20,
                              color: Colors.black87,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              estado == 1
                                  ? 'Desactivar'
                                  : 'Activar',
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style:
                              TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
