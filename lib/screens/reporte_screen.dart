import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ReporteScreen extends StatelessWidget {
  const ReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final hoy = DateTime.now();

    return FutureBuilder<double>(
  future: fs.calcularIngresosMesDesdeAlumnos(hoy.year, hoy.month),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final total = snapshot.data ?? 0;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        color: Colors.blue[50],
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ingresos hasta hoy de ${hoy.month}/${hoy.year}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "S/ ${total.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }
}
