import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class ReporteScreen extends StatelessWidget {
  const ReporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final hoy = DateTime.now();

    return FutureBuilder<Map<String, double>>(
      future: fs.calcularIngresosPorMetodoPago(hoy.year, hoy.month),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final ingresos = snapshot.data ?? {};
        final totalEfectivo = ingresos['efectivo'] ?? 0;
        final totalYape = ingresos['yape'] ?? 0;
        final totalGeneral = ingresos['total'] ?? 0;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Título del mes
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'REPORTE ${_obtenerNombreMes(hoy.month).toUpperCase()} ${hoy.year}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Tarjeta de Total General
              Card(
                elevation: 4,
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        "INGRESOS TOTALES",
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "S/ ${totalGeneral.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.blue
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_obtenerNombreMes(hoy.month)} ${hoy.year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),

              // Tarjeta de Efectivo
              Card(
                elevation: 3,
                color: Colors.green[50],
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.attach_money, color: Colors.white),
                  ),
                  title: const Text(
                    "EFECTIVO",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${((totalEfectivo / totalGeneral) * 100).toStringAsFixed(1)}% del total",
                    style: TextStyle(color: Colors.green[700]),
                  ),
                  trailing: Text(
                    "S/ ${totalEfectivo.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Tarjeta de Yape
              Card(
                elevation: 3,
                color: Colors.purple[50],
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.white),
                  ),
                  title: const Text(
                    "YAPE",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${((totalYape / totalGeneral) * 100).toStringAsFixed(1)}% del total",
                    style: TextStyle(color: Colors.purple[700]),
                  ),
                  trailing: Text(
                    "S/ ${totalYape.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Estadísticas rápidas
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        "RESUMEN DEL MES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEstadistica(
                            icon: Icons.attach_money,
                            color: Colors.green,
                            label: 'Efectivo',
                            valor: totalEfectivo,
                          ),
                          _buildEstadistica(
                            icon: Icons.phone_android,
                            color: Colors.purple,
                            label: 'Yape',
                            valor: totalYape,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadistica({
    required IconData icon,
    required Color color,
    required String label,
    required double valor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "S/ ${valor.toStringAsFixed(2)}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _obtenerNombreMes(int mes) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }
}