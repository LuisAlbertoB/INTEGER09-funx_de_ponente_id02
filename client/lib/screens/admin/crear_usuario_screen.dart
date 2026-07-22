import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class CrearUsuarioScreen extends StatefulWidget {
  const CrearUsuarioScreen({super.key});

  @override
  State<CrearUsuarioScreen> createState() => _CrearUsuarioScreenState();
}

class _CrearUsuarioScreenState extends State<CrearUsuarioScreen> {
  final _service = AdminService();
  final _nombreCtrl = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _rol = 'usuario_general';
  bool _loading = false;

  final List<String> _roles = [
    'admin',
    'ponente',
    'coordinador',
    'participante',
    'asistente',
    'usuario_general',
  ];

  Future<void> _submit() async {
    if (_nombreCtrl.text.trim().isEmpty ||
        _matriculaCtrl.text.trim().isEmpty ||
        _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son requeridos.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.createUsuario(
        nombreCompleto: _nombreCtrl.text.trim(),
        matricula: _matriculaCtrl.text.trim(),
        contrasena: _passCtrl.text,
        rol: _rol,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    }
  }

  String _rolLabel(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'ponente':
        return 'Ponente';
      case 'coordinador':
        return 'Coordinador';
      case 'participante':
        return 'Participante';
      case 'asistente':
        return 'Asistente';
      case 'usuario_general':
        return 'Usuario general';
      default:
        return rol;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _matriculaCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.deepPurple,
          width: 1.6,
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Nuevo Usuario'),
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _loading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Registrar usuario',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa los datos para crear una nueva cuenta dentro del sistema.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Información del usuario',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _nombreCtrl,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: _decoration(
                            label: 'Nombre completo *',
                            hint: 'Ej. Juan Pérez López',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _matriculaCtrl,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: _decoration(
                            label: 'Matrícula *',
                            hint: 'Ej. 202400123',
                            icon: Icons.badge_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _loading ? null : _submit(),
                          decoration: _decoration(
                            label: 'Contraseña *',
                            hint: 'Ingresa una contraseña',
                            icon: Icons.lock_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _rol,
                          borderRadius: BorderRadius.circular(14),
                          decoration: _decoration(
                            label: 'Rol *',
                            hint: 'Selecciona un rol',
                            icon: Icons.admin_panel_settings_outlined,
                          ),
                          items: _roles
                              .map(
                                (r) => DropdownMenuItem(
                              value: r,
                              child: Text(_rolLabel(r)),
                            ),
                          )
                              .toList(),
                          onChanged: (v) => setState(() => _rol = v!),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                                : const Text(
                              'Crear Usuario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
