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
      appBar: AppBar(title: Text('Historial de $nombre')),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.historial.where('alumnoId', isEqualTo: alumnoId).orderBy('fecha_registro', descending: true).snapshots()
,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('No hay historial aún'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
              final fechaFin = (data['fecha_fin'] as Timestamp).toDate();
              final plan = data['plan'] ?? '';
              final curso = data['curso'] ?? '';
              final turno = data['turno'] ?? '';
              final promocion = data['promocion'] ?? '';
              final monto = data['monto_pagado'] ?? 0.0;
              final estado = data['estado'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('$curso • $plan • $turno'),
                  subtitle: Text(
                      'Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio)}\n'
                      'Fin: ${DateFormat('dd/MM/yyyy').format(fechaFin)}\n'
                      'Promoción: $promocion\nMonto: S/ $monto\nEstado: $estado'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirm = false;
                      confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar registro?'),
                          content: const Text(
                              'Se eliminará este registro del historial y se guardará como perfil eliminado.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                  
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
