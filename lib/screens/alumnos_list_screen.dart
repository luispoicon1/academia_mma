import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../services/firestore_service.dart';
import 'add_alumno_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'alumno_historial_screen.dart';
import '../screens/edit_alumno_screen.dart';
import '../services/pdf_service.dart';
import 'perfil_fisico_screen.dart';

class AlumnosListScreen extends StatefulWidget {
  const AlumnosListScreen({super.key});

  @override
  State<AlumnosListScreen> createState() => _AlumnosListScreenState();
}

class _AlumnosListScreenState extends State<AlumnosListScreen> {
  final FirestoreService fs = FirestoreService();
  final Map<String, Map<String, dynamic>> _perfilesCache = {};

  @override
  void initState() {
    super.initState();
    _cargarPerfilesFisicos();
  }

  // Cargar todos los perfiles físicos una sola vez
  Future<void> _cargarPerfilesFisicos() async {
    try {
      print('🔄 Cargando perfiles físicos...');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('perfiles_fisicos')
          .get();

      _perfilesCache.clear();
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final alumnoId = data['alumnoId'] as String?;
        
        if (alumnoId != null) {
          _perfilesCache[alumnoId] = data;
          print('✅ Perfil cargado para alumno: $alumnoId');
        }
      }
      
      print('📊 Total perfiles cargados: ${_perfilesCache.length}');
      setState(() {});
      
    } catch (e) {
      print('❌ Error cargando perfiles: $e');
    }
  }

  // Widget para mostrar el perfil físico
  Widget _buildPerfilFisico(String alumnoId) {
    final perfilData = _perfilesCache[alumnoId];
    
    if (perfilData == null) {
      return const Text(
        '📝 Sin perfil físico',
        style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final peso = perfilData['peso']?.toDouble() ?? 0.0;
    final altura = perfilData['altura']?.toDouble() ?? 0.0;

    if (peso <= 0 || altura <= 0) {
      return const Text(
        '📝 Perfil incompleto',
        style: TextStyle(fontSize: 11, color: Colors.orange),
      );
    }

    // Convertir altura a cm si está en metros
    double alturaCm = altura;
    if (altura < 3) {
      alturaCm = altura * 100;
    }

    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          '⚖️ $peso kg • 📏 ${alturaCm.toStringAsFixed(0)} cm • 🧮 IMC: ${imc.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 12, color: Colors.green),
        ),
        if (perfilData['pesoObjetivo'] != null)
          Text(
            '🎯 Objetivo: ${perfilData['pesoObjetivo']} kg',
            style: const TextStyle(fontSize: 10, color: Colors.blue),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alumnos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAlumnoScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarPerfilesFisicos,
            tooltip: 'Actualizar perfiles físicos',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.streamAlumnos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No hay alumnos registrados'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              
              final nombre = data['nombre'] ?? '';
              final curso = data['curso'] ?? '';
              final celular = data['celular'] ?? '';
              final plan = data['plan'] ?? '';
              final turno = data['turno'] ?? '';
              final promocion = data['promocion'] ?? '';
              final monto = data['monto_pagado'] ?? 0;
              final tsFin = data['fecha_fin'] as Timestamp?;
              final fechaFin = tsFin?.toDate() ?? DateTime.now();
              final estado = data['estado'] ?? FirestoreService.calcularEstado(fechaFin);

              Color color = estado == 'Vencido'
                  ? Colors.red[200]!
                  : estado == 'Por vencer'
                      ? Colors.yellow[200]!
                      : Colors.green[200]!;

              return Card(
                color: color,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$curso • Vence: ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}'),
                      _buildPerfilFisico(doc.id),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                        onPressed: () {
                          final mensaje = Uri.encodeComponent(
                              'Hola $nombre, tu membresía vence el ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}. ¡Renueva para seguir entrenando! 💪');
                          final url = 'https://wa.me/51$celular?text=$mensaje';
                          launchUrlString(url, mode: LaunchMode.externalApplication);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.print, color: Colors.black),
                        onPressed: () async {
                          final montoPrint = (data['monto_pagado'] ?? 0).toDouble();
                          final fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();

                          await PdfService.generarBoleta(
                            context: context,
                            nombre: data['nombre'] ?? '',
                            apellido: data['apellido'] ?? '',
                            edad: data['edad'] ?? 0,
                            dni: data['dni'] ?? '',
                            correo: data['correo'] ?? '',
                            celular: data['celular'] ?? '',
                            direccion: data['direccion'] ?? '',
                            esMenorEdad: data['es_menor_edad'] ?? false,
                            apoderado: data['apoderado'] ?? '',
                            dniApoderado: data['dni_apoderado'] ?? '',
                            celularApoderado: data['celular_apoderado'] ?? '',
                            curso: curso,
                            plan: plan,
                            turno: data['turno'] ?? '',
                            promocion: data['promocion'] ?? '',
                            monto: montoPrint,
                            fecha: fechaInicio,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlumnoHistorialScreen(
                                alumnoId: doc.id,
                                nombre: data['nombre'] ?? '',
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('¿Eliminar alumno?'),
                              content: const Text('Se eliminará este alumno permanentemente.'),
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
                            await FirebaseFirestore.instance
                                .collection('alumnos')
                                .doc(doc.id)
                                .delete();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditAlumnoScreen(
                                alumnoId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.fitness_center, color: Colors.purple),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PerfilFisicoScreen(
                                alumnoId: doc.id,
                                nombreAlumno: data['nombre'] ?? '',
                              ),
                            ),
                          ).then((_) {
                            // Recargar perfiles cuando vuelvas
                            _cargarPerfilesFisicos();
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('$nombre ${data['apellido'] ?? ''}'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Edad: ${data['edad'] ?? ''} años'),
                                  Text('DNI: ${data['dni'] ?? ''}'),
                                  Text('Correo: ${data['correo'] ?? 'No especificado'}'),
                                  Text('Dirección: ${data['direccion'] ?? ''}'),
                                  if (data['es_menor_edad'] == true) ...[
                                    Text('Apoderado: ${data['apoderado'] ?? ''}'),
                                    Text('DNI Apoderado: ${data['dni_apoderado'] ?? ''}'),
                                    Text('Celular Apoderado: ${data['celular_apoderado'] ?? ''}'),
                                  ],
                                  Text('Curso: $curso'),
                                  Text('Plan: $plan'),
                                  Text('Turno: $turno'),
                                  Text('Promoción: $promocion'),
                                  Text('Monto pagado: S/ $monto'),
                                  Text('Fecha inicio: ${DateFormat('dd/MM/yyyy').format((data['fecha_inicio'] as Timestamp).toDate())}'),
                                  Text('Fecha fin: ${DateFormat('dd/MM/yyyy').format(fechaFin)}'),
                                  Text('Estado: $estado'),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cerrar'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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