import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class AlumnoHistorialScreen extends StatelessWidget {
  final String alumnoId;
  final String nombre;

  const AlumnoHistorialScreen({super.key, required this.alumnoId, required this.nombre});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Historial de $nombre'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.historial
            .where('alumnoId', isEqualTo: alumnoId)
            .orderBy('fecha_registro', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando historial...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar historial',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Volver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text(
                'No se encontraron datos',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 100, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  Text(
                    'No hay historial aún',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Los registros del historial aparecerán aquí cuando se realicen nuevas inscripciones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header con estadísticas
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.blue.shade100),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '${docs.length} registro${docs.length > 1 ? 's' : ''} en el historial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de registros
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
                    final fechaFin = (data['fecha_fin'] as Timestamp).toDate();
                    final plan = data['plan'] ?? '';
                    final curso = data['curso'] ?? '';
                    final turno = data['turno'] ?? '';
                    final promocion = data['promocion'] ?? '';
                    final monto = data['monto_pagado'] ?? 0.0;
                    final estado = data['estado'] ?? '';
                    
                    // Determinar color según el estado
                    final Color estadoColor;
                    switch (estado) {
                      case 'Activo':
                        estadoColor = Colors.green;
                        break;
                      case 'Por vencer':
                        estadoColor = Colors.orange;
                        break;
                      case 'Vencido':
                        estadoColor = Colors.red;
                        break;
                      default:
                        estadoColor = Colors.grey;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header del registro
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$curso • $plan',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          turno,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: estadoColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: estadoColor.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      estado,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: estadoColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Información del periodo
                              Row(
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.calendar_today,
                                    label: 'Inicio',
                                    value: DateFormat('dd/MM/yyyy').format(fechaInicio),
                                  ),
                                  const SizedBox(width: 16),
                                  _buildInfoItem(
                                    icon: Icons.event_available,
                                    label: 'Fin',
                                    value: DateFormat('dd/MM/yyyy').format(fechaFin),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Información adicional
                              Row(
                                children: [
                                  _buildInfoItem(
                                    icon: Icons.local_offer,
                                    label: 'Promoción',
                                    value: promocion.isEmpty ? 'Ninguna' : promocion,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildInfoItem(
                                    icon: Icons.attach_money,
                                    label: 'Monto',
                                    value: 'S/ ${monto.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Botón de eliminar
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: () => _confirmarEliminacion(context, fs, doc.id),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('Eliminar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context, FirestoreService fs, String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('¿Eliminar registro?'),
          ],
        ),
        content: const Text('Esta acción no se puede deshacer. ¿Estás seguro de que quieres eliminar este registro del historial?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await fs.historial.doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Registro eliminado correctamente'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al eliminar: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}