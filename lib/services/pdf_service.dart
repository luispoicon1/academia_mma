import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
  }) async {
    final pdf = pw.Document();
    
    final logo = await _cargarLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (context) => pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          crossAxisAlignment: pw.CrossAxisAlignment.center, // 👈 CENTRAR TODO
          children: [
            // ENCABEZADO CON LOGO Y DATOS DE LA ACADEMIA
            _buildEncabezado(logo),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),

            // DATOS DEL ALUMNO
            _buildSeccionCentrada(
              titulo: "DATOS DEL ALUMNO",
              contenido: [
                "Nombre: $nombre $apellido",
                "Edad: $edad años",
                "DNI: $dni",
                "Celular: $celular", 
                "Dirección: $direccion",
                if (correo.isNotEmpty) "Correo: $correo",
              ],
            ),

            // DATOS DEL APODERADO
            if (esMenorEdad) 
              _buildSeccionCentrada(
                titulo: "DATOS DEL APODERADO",
                contenido: [
                  "Nombre: $apoderado",
                  "DNI: $dniApoderado",
                  "Celular: $celularApoderado",
                ],
              ),

            // INFORMACIÓN DEL CURSO
            _buildSeccionCentrada(
              titulo: "INFORMACIÓN DEL CURSO",
              contenido: [
                "Curso: $curso",
                "Plan: $plan",
                if (turno.isNotEmpty) "Turno: $turno",
                if (promocion.isNotEmpty && promocion != 'Ninguna') 
                  "Promoción: $promocion",
              ],
            ),

            // MONTO DE PAGO
            _buildSeccionCentrada(
              titulo: "INFORMACIÓN DE PAGO",
              contenido: [
                "MONTO: S/ ${monto.toStringAsFixed(2)}",
              ],
              estiloEspecial: true,
            ),
            pw.SizedBox(height: 8),

            // DATOS DE CONTACTO DE LA ACADEMIA
            _buildSeccionCentrada(
              titulo: "CONTACTO ACADEMIA",
              contenido: [
                "Tel: 977908078",
                "Email: grupotigre.azul@gmail.com",
                "Sede: Chincha",
                "Ubicación: Prolongación Colón 715, Chincha Alta",
              ],
            ),

            // PIE DE PÁGINA
            _buildPiePagina(logo, fecha),
          ],
        ),
      ),
    );

    await _mostrarPreview(context, pdf);
  }

  // 👇 ENCABEZADO CENTRADO
  static pw.Widget _buildEncabezado(pw.ImageProvider? logo) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) 
            pw.Container(
              height: 40,
              child: pw.Image(logo),
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            "TEAM LAN HU",
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.Text(
            "Academia de Artes Marciales",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "BOLETA DE PAGO",
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 👇 SECCIÓN CENTRADA
  static pw.Widget _buildSeccionCentrada({
    required String titulo,
    required List<String> contenido,
    bool estiloEspecial = false,
  }) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          for (String linea in contenido)
            pw.Text(
              linea,
              style: estiloEspecial 
                  ? pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
                  : pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 8),
        ],
      ),
    );
  }

  // 👇 PIE DE PÁGINA CENTRADO
  static pw.Widget _buildPiePagina(pw.ImageProvider? logo, DateTime fecha) {
    return pw.Center(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 8),
          if (logo != null) 
            pw.Container(
              height: 25,
              child: pw.Image(logo),
            ),
          pw.SizedBox(height: 6),
          pw.Text(
            "¡Gracias por entrenar con nosotros!",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            "Team Lan Hu - Chincha Alta",
            style: pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            _formatearFechaCompleta(fecha),
            style: pw.TextStyle(fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 👇 CARGAR LOGO
  static Future<pw.MemoryImage?> _cargarLogo() async {
    try {
      print('🔄 Intentando cargar logo desde assets...');
      
      final ByteData byteData = await rootBundle.load('assets/logo.jpg');
      final Uint8List imageBytes = byteData.buffer.asUint8List();
      
      print('✅ Logo cargado exitosamente - ${imageBytes.length} bytes');
      return pw.MemoryImage(imageBytes);
      
    } catch (e) {
      print('❌ Error cargando logo: $e');
      
      try {
        final ByteData byteData = await rootBundle.load('assets/logo.png');
        final Uint8List imageBytes = byteData.buffer.asUint8List();
        print('✅ Logo PNG cargado exitosamente');
        return pw.MemoryImage(imageBytes);
      } catch (e2) {
        print('❌ También falló con PNG: $e2');
      }
      
      return null;
    }
  }

  // 👇 MOSTRAR PREVIEW
  static Future<void> _mostrarPreview(BuildContext context, pw.Document pdf) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Boleta de Pago")),
          body: PdfPreview(
            build: (format) => pdf.save(),
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: true,
            allowSharing: false,
          ),
        ),
      ),
    );
  }

  // 👇 FORMATEAR FECHA COMPLETA
  static String _formatearFechaCompleta(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}