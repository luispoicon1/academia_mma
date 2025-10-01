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
        stream: fs.historial
            .where('alumnoId', isEqualTo: alumnoId)
            .orderBy('fecha_registro', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔍 DEBUG: Agregar más estados
          print('📱 Estado de conexión: ${snapshot.connectionState}');
          print('📱 Tiene datos: ${snapshot.hasData}');
          print('📱 Tiene error: ${snapshot.hasError}');
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando historial...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            print('❌ Error en historial: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error al cargar historial'),
                  Text('${snapshot.error}', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No se encontraron datos'),
            );
          }

          final docs = snapshot.data!.docs;
          print('📊 Documentos en historial: ${docs.length}');

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay historial aún'),
                  Text('Los registros aparecerán aquí cuando agregues alumnos', 
                       style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              
              // 🔍 DEBUG: Verificar campos
              print('📄 Documento $i: $data');
              
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
                    'Promoción: $promocion\nMonto: S/ $monto\nEstado: $estado'
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar registro?'),
                          content: const Text(
                              'Se eliminará este registro del historial.'),
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

                      if (confirm == true) {
                        await fs.historial.doc(doc.id).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registro eliminado')),
                        );
                      }
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