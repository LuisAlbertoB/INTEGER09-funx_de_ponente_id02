import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_service.dart';
import 'qr_landing_screen.dart';

/// Scanner de QR usando la cámara del dispositivo.
/// Al detectar un payload válido "unievent://evento/{id}", navega a QrLandingScreen.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  bool _procesando = false;

  void _onDetect(BarcodeCapture capture) {
    if (_procesando) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;

      final id = QrService.parsePayload(raw);
      if (id != null) {
        setState(() => _procesando = true);
        _controller.stop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QrLandingScreen(
              idConferencia: id,
              tituloEvento: 'Cargando conferencia #$id...',
            ),
          ),
        );
        return;
      }
    }

    // QR no reconocido
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Este QR no pertenece a UniEvents.'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Escanear QR de Clase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Linterna',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Vista de cámara ────────────────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // ── Marco de escaneo ───────────────────────────────────────────
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepPurple.shade300,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // ── Texto de ayuda ─────────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al QR que muestra el ponente',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
              ),
            ),
          ),

          // ── Overlay de carga ───────────────────────────────────────────
          if (_procesando)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              ),
            ),
        ],
      ),
    );
  }
}
