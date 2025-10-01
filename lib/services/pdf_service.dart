import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generarBoleta({
    required BuildContext context,
    required String nombre,
    required String curso,
    required String plan,
    required double monto,
    required DateTime fecha,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57, // formato para impresora térmica 58mm
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                "ACADEMIA TEAM LAN HU",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                "Boleta de Pago",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Divider(),

            pw.Text("Alumno: $nombre"),
            pw.Text("Curso: $curso"),
            pw.Text("Plan: $plan"),
            pw.Text("Monto: S/ ${monto.toStringAsFixed(2)}"),
            pw.Text("Fecha: ${fecha.day}/${fecha.month}/${fecha.year}"),

            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(
                "Gracias por tu pago 💪",
                style: pw.TextStyle(fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );

    // 👉 Mostrar preview e imprimir directamente
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
}
