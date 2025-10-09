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
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert' show utf8, base64Encode;
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'renovar_mensualidad_screen.dart'; // Agrega esta línea

class AlumnosListScreen extends StatefulWidget {
  const AlumnosListScreen({super.key});

  @override
  State<AlumnosListScreen> createState() => _AlumnosListScreenState();
}

class _AlumnosListScreenState extends State<AlumnosListScreen> {
  final FirestoreService fs = FirestoreService();
  final Map<String, Map<String, dynamic>> _perfilesCache = {};
  
  // ============ FUNCIÓN MEJORADA PARA PERMISOS ============
  Future<bool> _verificarPermisosAlmacenamiento() async {
    try {
      if (kIsWeb) return true;
      
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted) {
          return true;
        }
        
        final status = await Permission.storage.request();
        return status.isGranted;
      }
      
      if (Platform.isIOS) {
        return true;
      }
      
      return true;
      
    } catch (e) {
      print('Error verificando permisos: $e');
      return true;
    }
  }

  // ============ VARIABLES PARA FILTROS ============
  final TextEditingController _searchController = TextEditingController();
  String _selectedCurso = 'Todos';
  String _selectedPlan = 'Todos';
  String _selectedMetodoPago = 'Todos';
  String _selectedEstado = 'Todos';
  bool _filtrosExpandidos = false;
  
  List<String> _cursos = ['Todos'];
  List<String> _planes = ['Todos'];
  List<String> _metodosPago = ['Todos'];

  @override
  void initState() {
    super.initState();
    _cargarPerfilesFisicos();
    _cargarOpcionesFiltros();
  }

  Future<void> _cargarPerfilesFisicos() async {
  try {
    // Cargar perfiles físicos
    final perfilesSnapshot = await FirebaseFirestore.instance
        .collection('perfiles_fisicos')
        .get();

    _perfilesCache.clear();
    
    for (var doc in perfilesSnapshot.docs) {
      final data = doc.data();
      final alumnoId = data['alumnoId'] as String?;
      
      if (alumnoId != null) {
        _perfilesCache[alumnoId] = data;
      }
    }
    
    // Cargar niveles desde alumnos collection (para actualizaciones rápidas)
    final alumnosSnapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .get();
    
    for (var doc in alumnosSnapshot.docs) {
      final data = doc.data();
      final alumnoId = doc.id;
      
      // Si el alumno tiene niveles actualizados pero no tiene perfil físico reciente
      // crear un perfil básico con los niveles
      if (data['cinturon_jiujitsu'] != null || data['nivel_mma'] != null) {
        if (!_perfilesCache.containsKey(alumnoId)) {
          _perfilesCache[alumnoId] = {
            'niveles_registrados': {
              'jiujitsu': data['cinturon_jiujitsu'] ?? 'Blanco',
              'mma': data['nivel_mma'] ?? 'Principiante',
              'box': data['nivel_box'] ?? 'Principiante',
              'muay_thai': data['nivel_muay_thai'] ?? 'Principiante',
              'sanda': data['cinturon_sanda'] ?? 'Blanco',
            }
          };
        } else {
          // Si ya tiene perfil, actualizar los niveles con los más recientes
          final perfilExistente = _perfilesCache[alumnoId]!;
          _perfilesCache[alumnoId] = {
            ...perfilExistente,
            'niveles_registrados': {
              'jiujitsu': data['cinturon_jiujitsu'] ?? perfilExistente['niveles_registrados']?['jiujitsu'] ?? 'Blanco',
              'mma': data['nivel_mma'] ?? perfilExistente['niveles_registrados']?['mma'] ?? 'Principiante',
              'box': data['nivel_box'] ?? perfilExistente['niveles_registrados']?['box'] ?? 'Principiante',
              'muay_thai': data['nivel_muay_thai'] ?? perfilExistente['niveles_registrados']?['muay_thai'] ?? 'Principiante',
              'sanda': data['cinturon_sanda'] ?? perfilExistente['niveles_registrados']?['sanda'] ?? 'Blanco',
            }
          };
        }
      }
    }
    
    setState(() {});
    
  } catch (e) {
    print('❌ Error cargando datos completos: $e');
  }
}
  Future<void> _cargarOpcionesFiltros() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .get();

      final cursosSet = <String>{};
      final planesSet = <String>{};
      final metodosPagoSet = <String>{};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['curso'] != null) cursosSet.add(data['curso']);
        if (data['plan'] != null) planesSet.add(data['plan']);
        if (data['metodo_pago'] != null) metodosPagoSet.add(data['metodo_pago']);
      }

      setState(() {
        _cursos = ['Todos']..addAll(cursosSet.toList()..sort());
        _planes = ['Todos']..addAll(planesSet.toList()..sort());
        _metodosPago = ['Todos']..addAll(metodosPagoSet.toList()..sort());
      });
    } catch (e) {
      print('Error cargando opciones de filtros: $e');
    }
  }

  bool _aplicarFiltros(Map<String, dynamic> data) {
    final nombreCompleto = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.toLowerCase();
    final busqueda = _searchController.text.toLowerCase();
    
    if (_searchController.text.isNotEmpty && !nombreCompleto.contains(busqueda)) {
      return false;
    }
    
    if (_selectedCurso != 'Todos' && data['curso'] != _selectedCurso) {
      return false;
    }
    
    if (_selectedPlan != 'Todos' && data['plan'] != _selectedPlan) {
      return false;
    }
    
    if (_selectedMetodoPago != 'Todos' && data['metodo_pago'] != _selectedMetodoPago) {
      return false;
    }
    
    if (_selectedEstado != 'Todos') {
      final tsFin = data['fecha_fin'] as Timestamp?;
      final fechaFin = tsFin?.toDate() ?? DateTime.now();
      final estadoReal = FirestoreService.calcularEstado(fechaFin);
      
      if (_selectedEstado != estadoReal) {
        return false;
      }
    }
    
    return true;
  }

  void _limpiarFiltros() {
    setState(() {
      _searchController.clear();
      _selectedCurso = 'Todos';
      _selectedPlan = 'Todos';
      _selectedMetodoPago = 'Todos';
      _selectedEstado = 'Todos';
    });
  }

  // ============ MÉTODO UNIFICADO MEJORADO PARA EXPORTACIÓN ============
  Future<void> _exportarAlumnosExcel() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exportando datos...'),
          ],
        ),
      ),
    );

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alumnos')
          .get();

      if (querySnapshot.docs.isEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay alumnos para exportar')),
        );
        return;
      }

      String csvContent = 'N°;Nombre;Apellido;DNI;Edad;Celular;Correo;Dirección;Curso;Plan;Turno;Promoción;Método Pago;Monto Pagado;Fecha Inicio;Fecha Fin;Estado;Es Menor Edad;Apoderado;DNI Apoderado;Celular Apoderado\n';
      
      int contador = 1;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        String fechaInicioStr = 'N/A';
        String fechaFinStr = 'N/A';
        
        try {
          if (data['fecha_inicio'] != null) {
            final fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
            fechaInicioStr = DateFormat('dd/MM/yyyy').format(fechaInicio);
          }
          if (data['fecha_fin'] != null) {
            final fechaFin = (data['fecha_fin'] as Timestamp).toDate();
            fechaFinStr = DateFormat('dd/MM/yyyy').format(fechaFin);
          }
        } catch (e) {
          print('Error procesando fechas: $e');
        }

        String escapeCsv(String text) {
          final textStr = text.toString();
          if (textStr.contains(';') || textStr.contains('"') || textStr.contains('\n')) {
            return '"${textStr.replaceAll('"', '""')}"';
          }
          return textStr;
        }

        csvContent += 
          '${contador++};'
          '${escapeCsv(data['nombre']?.toString() ?? '')};'
          '${escapeCsv(data['apellido']?.toString() ?? '')};'
          '${escapeCsv(data['dni']?.toString() ?? '')};'
          '${escapeCsv(data['edad']?.toString() ?? '')};'
          '${escapeCsv(data['celular']?.toString() ?? '')};'
          '${escapeCsv(data['correo']?.toString() ?? '')};'
          '${escapeCsv(data['direccion']?.toString() ?? '')};'
          '${escapeCsv(data['curso']?.toString() ?? '')};'
          '${escapeCsv(data['plan']?.toString() ?? '')};'
          '${escapeCsv(data['turno']?.toString() ?? '')};'
          '${escapeCsv(data['promocion']?.toString() ?? '')};'
          '${escapeCsv(data['metodo_pago']?.toString() ?? 'Efectivo')};'
          '${data['monto_pagado']?.toString() ?? '0'};'
          '$fechaInicioStr;'
          '$fechaFinStr;'
          '${escapeCsv(data['estado']?.toString() ?? 'Activo')};'
          '${data['es_menor_edad'] == true ? 'Sí' : 'No'};'
          '${escapeCsv(data['apoderado']?.toString() ?? '')};'
          '${escapeCsv(data['dni_apoderado']?.toString() ?? '')};'
          '${escapeCsv(data['celular_apoderado']?.toString() ?? '')}\n';
      }

      Navigator.pop(context);

      if (kIsWeb) {
        await _exportarEnWeb(csvContent, contador - 1);
      } else if (Platform.isAndroid || Platform.isIOS) {
        await _exportarEnMovil(csvContent, contador - 1);
      } else {
        await _exportarEnDesktop(csvContent, contador - 1);
      }

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print('❌ Error exportando: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // ============ MÉTODO PARA WEB CORREGIDO ============
  Future<void> _exportarEnWeb(String csvContent, int totalAlumnos) async {
    try {
      final bytes = utf8.encode(csvContent);
      final base64 = base64Encode(bytes);
      final dataUrl = 'data:text/csv;base64,$base64';
      
      final encodedUri = Uri.encodeFull(dataUrl);
      final success = await launchUrlString(
        encodedUri,
        mode: LaunchMode.externalApplication,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Descargando CSV con $totalAlumnos alumnos...'),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('No se pudo iniciar la descarga');
      }
      
    } catch (e) {
      print('Error en exportación web: $e');
      _mostrarDatosParaCopiar(csvContent, totalAlumnos);
    }
  }

  // ============ MÉTODO PARA MÓVIL ============
  Future<void> _exportarEnMovil(String csvContent, int totalAlumnos) async {
    try {
      final tienePermisos = await _verificarPermisosAlmacenamiento();
      if (!tienePermisos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesitan permisos de almacenamiento para exportar'),
          ),
        );
        return;
      }

      Directory directory;
      String rutaAmigable = '';
      
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory()) ?? await getApplicationDocumentsDirectory();
        rutaAmigable = 'Almacenamiento interno/Download';
      } else {
        directory = await getApplicationDocumentsDirectory();
        rutaAmigable = 'Archivos de la App';
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'alumnos_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvContent, flush: true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Exportación Exitosa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alumnos exportados: $totalAlumnos'),
              const SizedBox(height: 8),
              Text('Archivo: $fileName'),
              const SizedBox(height: 8),
              const Text(
                '💡 El archivo se guardó en la carpeta de Descargas',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _compartirArchivo(file);
              },
              child: const Text('Compartir'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('Error en exportación móvil: $e');
      _mostrarDatosParaCopiar(csvContent, totalAlumnos);
    }
  }

  // ============ MÉTODO PARA DESKTOP ============
  Future<void> _exportarEnDesktop(String csvContent, int totalAlumnos) async {
    try {
      final directory = await getDownloadsDirectory();
      
      if (directory == null) {
        throw Exception('No se pudo acceder al directorio de descargas');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/alumnos_$timestamp.csv');
      
      await file.writeAsString(csvContent, flush: true);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Exportación Exitosa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alumnos exportados: $totalAlumnos'),
              const SizedBox(height: 8),
              Text('Archivo: ${file.path}'),
              const SizedBox(height: 8),
              const Text(
                '💡 El archivo se guardó en tu carpeta de Descargas',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                OpenFile.open(file.path);
              },
              child: const Text('Abrir Archivo'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _compartirArchivo(file);
              },
              child: const Text('Compartir'),
            ),
          ],
        ),
      );

    } catch (e) {
      print('Error en exportación desktop: $e');
      
      try {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final file = File('${directory.path}/alumnos_$timestamp.csv');
        
        await file.writeAsString(csvContent, flush: true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Archivo guardado en: ${file.path}'),
            duration: const Duration(seconds: 5),
          ),
        );
      } catch (fallbackError) {
        print('Error en fallback: $fallbackError');
        _mostrarDatosParaCopiar(csvContent, totalAlumnos);
      }
    }
  }

  Future<void> _compartirArchivo(File file) async {
    try {
      if (kIsWeb) {
        // Para web, usar un enfoque diferente
        final bytes = await file.readAsBytes();
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:text/csv;base64,$base64';
        final encodedUri = Uri.encodeFull(dataUrl);
        await launchUrlString(encodedUri);
      } else {
        // Para móvil/desktop
        final xFile = XFile(file.path);
        await Share.shareXFiles([xFile], text: 'Exportación de Alumnos - Academia Tigre Azul');
      }
    } catch (e) {
      print('Error compartiendo archivo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al compartir el archivo')),
      );
    }
  }

  void _mostrarDatosParaCopiar(String csvContent, int totalAlumnos) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📋 Datos para Exportar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total alumnos: $totalAlumnos'),
              const SizedBox(height: 10),
              const Text('Copia los datos y pégalos en Excel:'),
              const SizedBox(height: 10),
              Container(
                width: double.maxFinite,
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    csvContent,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ Datos copiados al portapapeles')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copiar Datos'),
          ),
        ],
      ),
    );
  }

  // ============ NUEVO: MOSTRAR HISTORIAL COMPLETO ============
  Future<void> _mostrarHistorialCompleto(String alumnoId, String nombreAlumno) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('perfiles_fisicos')
          .where('alumnoId', isEqualTo: alumnoId)
          .orderBy('fechaRegistro', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros históricos')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Historial de $nombreAlumno'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: querySnapshot.docs.length,
              itemBuilder: (context, index) {
                final perfil = querySnapshot.docs[index].data();
                final fecha = perfil['fechaRegistro'].toDate();
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📅 ${fecha.day}/${fecha.month}/${fecha.year}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _buildResumenPerfil(perfil),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar historial: $e')),
      );
    }
  }

  // ============ NUEVO: RESUMEN DEL PERFIL PARA HISTORIAL ============
 Widget _buildResumenPerfil(Map<String, dynamic> perfil) {
  final peso = perfil['peso']?.toDouble() ?? 0;
  final altura = perfil['altura']?.toDouble() ?? 0;
  
  double alturaCm = altura < 3 ? altura * 100 : altura;
  final imc = peso / ((alturaCm / 100) * (alturaCm / 100));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('⚖️ Peso: $peso kg'),
      Text('📏 Altura: ${alturaCm.toStringAsFixed(0)} cm'),
      Text('🧮 IMC: ${imc.toStringAsFixed(1)}'),
      
      if (perfil['pesoObjetivo'] != null && perfil['pesoObjetivo'] > 0)
        Text('🎯 Objetivo: ${perfil['pesoObjetivo']} kg'),
      
      // NUEVO: Mostrar niveles en el historial
      if (perfil['niveles_registrados'] != null)
        _buildNivelesHistorial(perfil['niveles_registrados']),
      
      ..._buildMedidasEspecificas(perfil),
      
      if (perfil['observaciones'] != null && perfil['observaciones'].isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('📝 Observaciones:', 
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text('"${perfil['observaciones']}"'),
          ],
        ),
    ],
  );
}

Widget _buildNivelesHistorial(Map<String, dynamic> niveles) {
  final List<Widget> nivelesWidgets = [];
  
  void agregarNivel(String arte, String nivel) {
    if (nivel != null && nivel.isNotEmpty) {
      // ✅ MOSTRAR TODOS LOS NIVELES
      nivelesWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _obtenerColorCinturon(nivel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _obtenerColorCinturon(nivel), width: 0.5),
          ),
          child: Text(
            '$arte: $nivel',
            style: TextStyle(
              fontSize: 9,
              color: _obtenerColorCinturon(nivel),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  agregarNivel('Jiu Jitsu', niveles['jiujitsu']);
  agregarNivel('MMA', niveles['mma']);
  agregarNivel('Box', niveles['box']);
  agregarNivel('Muay Thai', niveles['muay_thai']);
  agregarNivel('Sanda', niveles['sanda']);

  if (nivelesWidgets.isEmpty) {
    return const SizedBox();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      const Text(
        '🎯 Niveles:',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: nivelesWidgets,
      ),
      const SizedBox(height: 4),
    ],
  );
}
// ============ NUEVO: FUNCIÓN PARA OBTENER COLOR DEL CINTURÓN ============
Color _obtenerColorCinturon(String cinturon) {
  switch (cinturon.toLowerCase()) {
    case 'blanco':
      return Colors.grey[300]!;
    case 'azul':
      return Colors.blue;
    case 'morado':
      return Colors.purple;
    case 'marrón':
      return Colors.brown;
    case 'negro':
      return Colors.grey[900]!;
    case 'amarillo':
      return Colors.yellow[700]!;
    case 'verde':
      return Colors.green;
    case 'rojo':
      return Colors.red;
    case 'intermedio':
      return Colors.orange;
    case 'avanzado':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

  // ============ NUEVO MÉTODO PARA MOSTRAR MEDIDAS ESPECÍFICAS ============
  List<Widget> _buildMedidasEspecificas(Map<String, dynamic> perfil) {
    final List<Widget> medidas = [];
    final Map<String, String> labels = {
      'cintura': '📐 Cintura',
      'pecho': '💪 Pecho', 
      'espalda': '🔙 Espalda',
      'hombros': '👤 Hombros',
      'brazo': '💪 Brazo',
      'pierna': '🦵 Pierna',
    };

    bool tieneMedidas = false;

    labels.forEach((key, label) {
      if (perfil[key] != null && perfil[key] > 0) {
        if (!tieneMedidas) {
          medidas.add(const SizedBox(height: 4));
          medidas.add(const Text('📊 Medidas:', 
              style: TextStyle(fontWeight: FontWeight.bold)));
          tieneMedidas = true;
        }
        medidas.add(Text('$label: ${perfil[key]} cm'));
      }
    });

    return medidas;
  }

  // ============ NUEVO: CONTAR MEDIDAS CORPORALES ============
  int _contarMedidasCorporales(Map<String, dynamic> perfil) {
    int count = 0;
    final medidas = ['cintura', 'pecho', 'espalda', 'hombros', 'brazo', 'pierna'];
    
    for (var medida in medidas) {
      if (perfil[medida] != null && perfil[medida] > 0) {
        count++;
      }
    }
    return count;
  }

  // ============ NUEVO: VERIFICAR SI TIENE MEDIDAS CORPORALES ============
  bool _tieneMedidasCorporales(Map<String, dynamic> perfil) {
    return (perfil['cintura'] != null && perfil['cintura'] > 0) ||
           (perfil['pecho'] != null && perfil['pecho'] > 0) ||
           (perfil['espalda'] != null && perfil['espalda'] > 0) ||
           (perfil['hombros'] != null && perfil['hombros'] > 0) ||
           (perfil['brazo'] != null && perfil['brazo'] > 0) ||
           (perfil['pierna'] != null && perfil['pierna'] > 0);
  }

  // Widget para mostrar el perfil físico
  // Widget para mostrar el perfil físico MEJORADO CON NIVELES
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
      
      // NUEVO: Mostrar niveles si existen en el perfil
      if (perfilData['niveles_registrados'] != null) 
        _buildNivelesPerfilCompacto(perfilData['niveles_registrados']),
      
      if (perfilData['pesoObjetivo'] != null)
        Text(
          '🎯 Objetivo: ${perfilData['pesoObjetivo']} kg',
          style: const TextStyle(fontSize: 10, color: Colors.blue),
        ),
    ],
  );
}


// ============ NUEVO: NIVELES COMPACTOS PARA LISTA ============
Widget _buildNivelesPerfilCompacto(Map<String, dynamic> niveles) {
  final List<Widget> badges = [];
  
  void agregarBadge(String arte, String nivel) {
    if (nivel != null && nivel.isNotEmpty) {
      // ✅ MOSTRAR TODOS LOS NIVELES, INCLUYENDO PRINCIPIANTE Y BLANCO
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _obtenerColorCinturon(nivel).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _obtenerColorCinturon(nivel), width: 0.5),
          ),
          child: Text(
            '$arte: $nivel',
            style: TextStyle(
              fontSize: 9,
              color: _obtenerColorCinturon(nivel),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
  }

  agregarBadge('Jiu Jitsu', niveles['jiujitsu']);
  agregarBadge('MMA', niveles['mma']);
  agregarBadge('Box', niveles['box']);
  agregarBadge('Muay Thai', niveles['muay_thai']);
  agregarBadge('Sanda', niveles['sanda']);

  if (badges.isEmpty) {
    return const SizedBox();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 4),
      Wrap(
        spacing: 6,
        runSpacing: 4,
        children: badges,
      ),
    ],
  );
}

  // Función para mostrar opciones en un menú emergente
  void _mostrarMenuOpciones(BuildContext context, String alumnoId, Map<String, dynamic> data, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // WhatsApp
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                title: const Text('Enviar WhatsApp'),
                onTap: () {
                  Navigator.pop(context);
                  final nombre = data['nombre'] ?? '';
                  final celular = data['celular'] ?? '';
                  final tsFin = data['fecha_fin'] as Timestamp?;
                  final fechaFin = tsFin?.toDate() ?? DateTime.now();
                  
                  final mensaje = Uri.encodeComponent(
                    'Hola $nombre, tu membresía vence el ${fechaFin.day}/${fechaFin.month}/${fechaFin.year}. ¡Renueva para seguir entrenando! 💪');
                  final url = 'https://wa.me/51$celular?text=$mensaje';
                  launchUrlString(url, mode: LaunchMode.externalApplication);
                },
              ),

// En el método _mostrarMenuOpciones, agrega:
ListTile(
  leading: const Icon(Icons.autorenew, color: Colors.green),
  title: const Text('Renovar Mensualidad'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RenovarMensualidadScreen(
          alumnoId: doc.id,
          alumnoData: data,
        ),
      ),
    ).then((_) {
      // Recargar datos después de renovar
      _cargarPerfilesFisicos();
    });
  },
),


              // Generar PDF
              ListTile(
                leading: const Icon(Icons.print, color: Colors.black),
                title: const Text('Generar PDF'),
                onTap: () async {
                  Navigator.pop(context);
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
                    curso: data['curso'] ?? '',
                    plan: data['plan'] ?? '',
                    turno: data['turno'] ?? '',
                    promocion: data['promocion'] ?? '',
                    monto: montoPrint,
                    metodoPago: data['metodo_pago'] ?? 'Efectivo',
                    fecha: fechaInicio,
                  );
                },
              ),
              // Historial
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: const Text('Ver Historial'),
                onTap: () {
                  Navigator.pop(context);
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
              // Editar
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Editar Alumno'),
                onTap: () {
                  Navigator.pop(context);
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
              // Perfil Físico
              ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.purple),
                title: const Text('Perfil Físico'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilFisicoScreen(
                        alumnoId: doc.id,
                        nombreAlumno: data['nombre'] ?? '',
                      ),
                    ),
                  ).then((_) {
                    _cargarPerfilesFisicos();
                  });
                },
              ),
              // Historial Perfil Físico
              ListTile(
                leading: const Icon(Icons.timeline, color: Colors.green),
                title: const Text('Historial Perfil Físico'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarHistorialCompleto(doc.id, data['nombre'] ?? '');
                },
              ),
              // Información
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Información'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarInformacionAlumno(context, data);
                },
              ),
              // Eliminar
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar Alumno'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarEliminacion(context, doc.id, data['nombre'] ?? '');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarInformacionAlumno(BuildContext context, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? '';
    final tsFin = data['fecha_fin'] as Timestamp?;
    final fechaFin = tsFin?.toDate() ?? DateTime.now();
    final estado = data['estado'] ?? FirestoreService.calcularEstado(fechaFin);

    final perfilData = _perfilesCache[data['id'] ?? ''];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$nombre ${data['apellido'] ?? ''}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('INFORMACIÓN PERSONAL', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Edad: ${data['edad'] ?? ''} años'),
              Text('DNI: ${data['dni'] ?? ''}'),
              Text('Correo: ${data['correo'] ?? 'No especificado'}'),
              Text('Dirección: ${data['direccion'] ?? ''}'),
              
              if (data['es_menor_edad'] == true) ...[
                const SizedBox(height: 8),
                const Text('DATOS DEL APODERADO', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Apoderado: ${data['apoderado'] ?? ''}'),
                Text('DNI Apoderado: ${data['dni_apoderado'] ?? ''}'),
                Text('Celular Apoderado: ${data['celular_apoderado'] ?? ''}'),
              ],
              
              const SizedBox(height: 8),
              const Text('INFORMACIÓN DEL CURSO', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Curso: ${data['curso'] ?? ''}'),
              Text('Plan: ${data['plan'] ?? ''}'),
              Text('Turno: ${data['turno'] ?? ''}'),
              Text('Promoción: ${data['promocion'] ?? ''}'),
              Text('Método de pago: ${data['metodo_pago'] ?? 'Efectivo'}'),
              Text('Monto pagado: S/ ${data['monto_pagado'] ?? 0}'),
              
              const SizedBox(height: 8),
              const Text('FECHAS', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fecha inicio: ${DateFormat('dd/MM/yyyy').format((data['fecha_inicio'] as Timestamp).toDate())}'),
              Text('Fecha fin: ${DateFormat('dd/MM/yyyy').format(fechaFin)}'),
              Text('Estado: $estado'),
              
              if (perfilData != null) ...[
                const SizedBox(height: 8),
                const Text('PERFIL FÍSICO', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildPerfilCompletoEnDialogo(perfilData),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar perfil físico completo en el diálogo
  Widget _buildPerfilCompletoEnDialogo(Map<String, dynamic> perfilData) {
    final peso = perfilData['peso']?.toDouble() ?? 0.0;
    final altura = perfilData['altura']?.toDouble() ?? 0.0;
    double alturaCm = altura < 3 ? altura * 100 : altura;
    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));
    
    final List<Widget> medidas = [];
    
    medidas.add(Text('Peso: $peso kg'));
    medidas.add(Text('Altura: ${alturaCm.toStringAsFixed(0)} cm'));
    medidas.add(Text('IMC: ${imc.toStringAsFixed(1)}'));
    
    if (perfilData['pesoObjetivo'] != null) {
      medidas.add(Text('Objetivo: ${perfilData['pesoObjetivo']} kg'));
    }
    
    if (perfilData['cintura'] != null && perfilData['cintura'] > 0) {
      medidas.add(Text('Cintura: ${perfilData['cintura']} cm'));
    }
    if (perfilData['pecho'] != null && perfilData['pecho'] > 0) {
      medidas.add(Text('Pecho: ${perfilData['pecho']} cm'));
    }
    if (perfilData['espalda'] != null && perfilData['espalda'] > 0) {
      medidas.add(Text('Espalda: ${perfilData['espalda']} cm'));
    }
    if (perfilData['hombros'] != null && perfilData['hombros'] > 0) {
      medidas.add(Text('Hombros: ${perfilData['hombros']} cm'));
    }
    if (perfilData['brazo'] != null && perfilData['brazo'] > 0) {
      medidas.add(Text('Brazo: ${perfilData['brazo']} cm'));
    }
    if (perfilData['pierna'] != null && perfilData['pierna'] > 0) {
      medidas.add(Text('Pierna: ${perfilData['pierna']} cm'));
    }
    
    if (perfilData['observaciones'] != null && perfilData['observaciones'].isNotEmpty) {
      medidas.add(Text('Observaciones: ${perfilData['observaciones']}'));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: medidas.map((medida) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: medida,
      )).toList(),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context, String docId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar alumno?'),
        content: Text('Se eliminará a $nombre permanentemente.'),
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
          .doc(docId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // HEADER CON ACCIONES
          _buildHeader(),
          
          // FILTROS MEJORADOS
          _buildFiltrosMejorados(),
          
          // INDICADOR DE RESULTADOS
          _buildIndicadorResultados(),
          
          // LISTA DE ALUMNOS
          Expanded(
            child: _buildListaAlumnos(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Título y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            children: [
              _buildBotonAccion(
                icon: Icons.add,
                label: 'Nuevo',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddAlumnoScreen()),
                ),
              ),
              const SizedBox(width: 8),
              _buildBotonAccion(
                icon: Icons.refresh,
                label: 'Actualizar',
                color: Colors.blue,
                onTap: () {
                  _cargarPerfilesFisicos();
                  _cargarOpcionesFiltros();
                },
              ),
              const SizedBox(width: 8),
              _buildBotonAccion(
                icon: Icons.file_download,
                label: 'Exportar',
                color: Colors.orange,
                onTap: _exportarAlumnosExcel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonAccion({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 100,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltrosMejorados() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '🔍 Buscar alumno por nombre o apellido...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            
            const SizedBox(height: 12),
            
            // Botón para expandir/contraer filtros
            Row(
              children: [
                const Icon(Icons.filter_alt, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Filtros Avanzados', 
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    _filtrosExpandidos ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blue,
                  ),
                  onPressed: () => setState(() => _filtrosExpandidos = !_filtrosExpandidos),
                ),
              ],
            ),
            
            // Filtros expandibles
            if (_filtrosExpandidos) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildFiltroDropdownMejorado(
                    value: _selectedCurso,
                    items: _cursos,
                    hint: '🎓 Curso',
                    icon: Icons.school,
                    onChanged: (value) => setState(() => _selectedCurso = value!),
                  ),
                  
                  _buildFiltroDropdownMejorado(
                    value: _selectedPlan,
                    items: _planes,
                    hint: '📋 Plan',
                    icon: Icons.assignment,
                    onChanged: (value) => setState(() => _selectedPlan = value!),
                  ),
                  
                  _buildFiltroDropdownMejorado(
                    value: _selectedMetodoPago,
                    items: _metodosPago,
                    hint: '💰 Pago',
                    icon: Icons.payment,
                    onChanged: (value) => setState(() => _selectedMetodoPago = value!),
                  ),
                  
                  _buildFiltroDropdownMejorado(
                    value: _selectedEstado,
                    items: ['Todos', 'Activo', 'Por vencer', 'Vencido'],
                    hint: '🟢 Estado',
                    icon: Icons.circle,
                    onChanged: (value) => setState(() => _selectedEstado = value!),
                  ),
                  
                  // Botón limpiar
                  Container(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: _limpiarFiltros,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroDropdownMejorado({
    required String value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 140),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        isDense: true,
      ),
    );
  }

  Widget _buildIndicadorResultados() {
    return StreamBuilder<QuerySnapshot>(
      stream: fs.streamAlumnos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final docs = snapshot.data!.docs;
        final filtrados = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _aplicarFiltros(data);
        }).toList();
        
        final tieneFiltros = _selectedCurso != 'Todos' ||
            _selectedPlan != 'Todos' ||
            _selectedMetodoPago != 'Todos' ||
            _selectedEstado != 'Todos' ||
            _searchController.text.isNotEmpty;

        if (!tieneFiltros) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_alt, size: 14, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '$filtrados de ${docs.length} alumnos',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _limpiarFiltros,
                child: const Text(
                  'Limpiar filtros',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaAlumnos() {
    return StreamBuilder<QuerySnapshot>(
      stream: fs.streamAlumnos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = snapshot.data!.docs;
        final alumnosFiltrados = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _aplicarFiltros(data);
        }).toList();

        if (alumnosFiltrados.isEmpty) {
          return _buildVistaSinResultadosMejorada();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: alumnosFiltrados.length,
          itemBuilder: (context, i) {
            final doc = alumnosFiltrados[i];
            final data = doc.data() as Map<String, dynamic>;
            return _buildTarjetaAlumno(doc, data);
          },
        );
      },
    );
  }

  Widget _buildTarjetaAlumno(DocumentSnapshot doc, Map<String, dynamic> data) {
    final nombre = data['nombre'] ?? '';
    final apellido = data['apellido'] ?? '';
    final curso = data['curso'] ?? '';
    final tsFin = data['fecha_fin'] as Timestamp?;
    final fechaFin = tsFin?.toDate() ?? DateTime.now();
    final estado = data['estado'] ?? FirestoreService.calcularEstado(fechaFin);
    final celular = data['celular'] ?? '';

    // Color según estado
    final Color colorEstado;
    final Color colorTexto;
    final String textoEstado;
    
    switch (estado) {
      case 'Vencido':
        colorEstado = Colors.red.shade50;
        colorTexto = Colors.red.shade800;
        textoEstado = 'Vencido';
        break;
      case 'Por vencer':
        colorEstado = Colors.orange.shade50;
        colorTexto = Colors.orange.shade800;
        textoEstado = 'Por vencer';
        break;
      default:
        colorEstado = Colors.green.shade50;
        colorTexto = Colors.green.shade800;
        textoEstado = 'Activo';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarMenuOpciones(context, doc.id, data, doc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar y info básica
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.blue.shade700),
              ),
              
              const SizedBox(width: 12),
              
              // Información del alumno
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$nombre $apellido',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorEstado,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorTexto.withOpacity(0.3)),
                          ),
                          child: Text(
                            textoEstado,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorTexto,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '$curso • Vence: ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Perfil físico
                    _buildPerfilFisicoMejorado(doc.id),
                    
                    // Contacto
                    if (celular.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            celular,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Botón de opciones
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onPressed: () => _mostrarMenuOpciones(context, doc.id, data, doc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfilFisicoMejorado(String alumnoId) {
    final perfilData = _perfilesCache[alumnoId];
    
    if (perfilData == null) {
      return Row(
        children: [
          Icon(Icons.fitness_center, size: 12, color: Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            'Sin perfil físico',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final peso = perfilData['peso']?.toDouble() ?? 0.0;
    final altura = perfilData['altura']?.toDouble() ?? 0.0;

    if (peso <= 0 || altura <= 0) {
      return Row(
        children: [
          Icon(Icons.fitness_center, size: 12, color: Colors.orange.shade400),
          const SizedBox(width: 4),
          Text(
            'Perfil incompleto',
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.shade600,
            ),
          ),
        ],
      );
    }

    double alturaCm = altura;
    if (altura < 3) alturaCm = altura * 100;
    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));

    return Row(
      children: [
        Icon(Icons.fitness_center, size: 12, color: Colors.green.shade600),
        const SizedBox(width: 4),
        Text(
          '$peso kg • ${alturaCm.toStringAsFixed(0)} cm • IMC: ${imc.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.green.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVistaSinResultadosMejorada() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No se encontraron alumnos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros o intenta con otros términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _limpiarFiltros,
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}