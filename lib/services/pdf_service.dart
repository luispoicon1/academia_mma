import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PdfService {
  static Future<void> generarBoleta({
    required BuildContext context,
    required String nombre,
    required String apellido,
    required int edad,
    required String dni,
    required String correo,
    required String celular,
    required String direccion,
    required bool esMenorEdad,
    required String curso,
    required String plan,
    required double monto,
    required DateTime fecha,
    String apoderado = '',
    String dniApoderado = '',
    String celularApoderado = '',
    String turno = '',
    String promocion = '',
    required String metodoPago,
  }) async {
    // Generar comandos ESC/POS para RawBT
    final comandosEscPos = _generarComandosEscPos(
      nombre: nombre,
      apellido: apellido,
      edad: edad,
      dni: dni,
      correo: correo,
      celular: celular,
      direccion: direccion,
      esMenorEdad: esMenorEdad,
      curso: curso,
      plan: plan,
      monto: monto,
      fecha: fecha,
      apoderado: apoderado,
      dniApoderado: dniApoderado,
      celularApoderado: celularApoderado,
      turno: turno,
      promocion: promocion,
      metodoPago: metodoPago,
    );

    // Enviar directamente a RawBT
    await _enviarARawBT(context, comandosEscPos);
  }

  static List<int> _generarComandosEscPos({
    required String nombre,
    required String apellido,
    required int edad,
    required String dni,
    required String correo,
    required String celular,
    required String direccion,
    required bool esMenorEdad,
    required String curso,
    required String plan,
    required double monto,
    required DateTime fecha,
    String apoderado = '',
    String dniApoderado = '',
    String celularApoderado = '',
    String turno = '',
    String promocion = '',
    required String metodoPago,
  }) {
    List<int> bytes = [];

    // FUNCIONES AUXILIARES
    void addText(String text, {bool centered = false, bool bold = false, bool large = false}) {
      if (centered) {
        bytes.addAll([0x1B, 0x61, 0x01]); // Centrar
      }
      if (bold) {
        bytes.addAll([0x1B, 0x45, 0x01]); // Negrita ON
      }
      if (large) {
        bytes.addAll([0x1D, 0x21, 0x01]); // Tamaño doble
      }
      
      bytes.addAll(text.codeUnits);
      bytes.add(0x0A); // Nueva línea
      
      // Resetear formatos
      if (large) bytes.addAll([0x1D, 0x21, 0x00]);
      if (bold) bytes.addAll([0x1B, 0x45, 0x00]);
      if (centered) bytes.addAll([0x1B, 0x61, 0x00]);
    }

    void addSeparator() {
      addText('--------------------------------', centered: true);
    }

    void addDoubleSeparator() {
      addText('================================', centered: true);
    }

    // INICIALIZAR IMPRESORA
    bytes.addAll([0x1B, 0x40]); // Reset

    // ENCABEZADO
    addText('TEAM LAN HU', centered: true, large: true);
    addText('Academia de Artes Marciales', centered: true);
    addText('BOLETA DE PAGO', centered: true, bold: true);
    addDoubleSeparator();
    addText(''); // Línea vacía

    // DATOS DEL ALUMNO
    addText('DATOS DEL ALUMNO', centered: true, bold: true);
    addSeparator();
    addText('Nombre: $nombre $apellido');
    addText('Edad: $edad años');
    addText('DNI: $dni');
    addText('Celular: $celular');
    addText('Direccion: $direccion');
    if (correo.isNotEmpty) addText('Correo: $correo');
    addText('');

    // DATOS DEL APODERADO
    if (esMenorEdad) {
      addText('DATOS DEL APODERADO', centered: true, bold: true);
      addSeparator();
      addText('Nombre: $apoderado');
      addText('DNI: $dniApoderado');
      addText('Celular: $celularApoderado');
      addText('');
    }

    // INFORMACIÓN DEL CURSO
    addText('INFORMACIÓN DEL CURSO', centered: true, bold: true);
    addSeparator();
    addText('Curso: $curso');
    addText('Plan: $plan');
    if (turno.isNotEmpty) addText('Turno: $turno');
    if (promocion.isNotEmpty && promocion != 'Ninguna') {
      addText('Promoción: $promocion');
    }
    addText('');

    // MONTO DE PAGO
    addText('INFORMACIÓN DE PAGO', centered: true, bold: true);
    addSeparator();
    addText('MONTO: S/ ${monto.toStringAsFixed(2)}', centered: true, large: true, bold: true);
    
    // MÉTODO DE PAGO
    addText('MÉTODO: $metodoPago', centered: true, bold: true);
    addText('');

    // CONTACTO ACADEMIA
    addText('CONTACTO ACADEMIA', centered: true, bold: true);
    addSeparator();
    addText('Tel: 977908078');
    addText('Email: grupotigre.azul@gmail.com');
    addText('Sede: Chincha Alta');
    addText('Direccion: Prolong. Colon 715');
    addText('');

    // PIE DE PÁGINA
    addDoubleSeparator();
    addText('¡Gracias por entrenar', centered: true, bold: true);
    addText('con nosotros!', centered: true, bold: true);
    addText('');
    addText('Team Lan Hu - Chincha Alta', centered: true);
    addText(_formatearFechaSimple(fecha), centered: true);
    addDoubleSeparator();

    // CORTAR PAPEL
    bytes.addAll([0x1D, 0x56, 0x41, 0x10]); // Cortar papel

    return bytes;
  }

  static Future<void> _enviarARawBT(BuildContext context, List<int> comandos) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Enviando a RawBT..."),
            ],
          ),
        ),
      );

      // Convertir bytes a texto (RawBT acepta texto con comandos ESC/POS)
      final textoConComandos = String.fromCharCodes(comandos);
      
      // Codificar para URL
      final textoCodificado = Uri.encodeComponent(textoConComandos);
      
      // URL para RawBT - formato correcto
      final rawBtUrl = "rawbt:${textoCodificado}";
      
      // Intentar abrir RawBT
      final lanzado = await launchUrlString(
        rawBtUrl,
        mode: LaunchMode.externalApplication,
      );

      // Cerrar loading
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (!lanzado) {
        // Si no se pudo abrir, mostrar opción alternativa
        _mostrarErrorRawBT(context, textoConComandos);
      }
      
    } catch (e) {
      // Cerrar loading si hay error
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Si hay error, mostrar opción de copiar manualmente
      final textoConComandos = String.fromCharCodes(comandos);
      _mostrarErrorRawBT(context, textoConComandos);
    }
  }

  static void _mostrarErrorRawBT(BuildContext context, String contenido) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No se pudo abrir RawBT"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("RawBT no está instalado o no respondió."),
            SizedBox(height: 16),
            Text("Puedes:"),
            SizedBox(height: 8),
            Text("• Instalar RawBT desde Play Store"),
            Text("• O copiar el contenido manualmente"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _abrirPlayStore();
            },
            child: const Text('Instalar RawBT'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copiarAlPortapapeles(context, contenido);
            },
            child: const Text('Copiar Manual'),
          ),
        ],
      ),
    );
  }

  static void _abrirPlayStore() {
    launchUrlString(
      "https://play.google.com/store/apps/details?id=ru.a402d.rawbtprinter",
      mode: LaunchMode.externalApplication,
    );
  }

  static void _copiarAlPortapapeles(BuildContext context, String contenido) {
    Clipboard.setData(ClipboardData(text: contenido));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Contenido copiado - Pega en RawBT manualmente"),
        duration: Duration(seconds: 4),
      ),
    );
  }

  static String _formatearFechaSimple(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
}