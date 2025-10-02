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
import 'package:flutter/services.dart'; // Para Clipboard
import 'dart:convert' show utf8;
import 'dart:html' as html; // Solo para web

class AlumnosListScreen extends StatefulWidget {
  const AlumnosListScreen({super.key});

  @override
  State<AlumnosListScreen> createState() => _AlumnosListScreenState();
}

class _AlumnosListScreenState extends State<AlumnosListScreen> {
  final FirestoreService fs = FirestoreService();
  final Map<String, Map<String, dynamic>> _perfilesCache = {};
  
  // ============ VARIABLES PARA FILTROS ============
  final TextEditingController _searchController = TextEditingController();
  String _selectedCurso = 'Todos';
  String _selectedPlan = 'Todos';
  String _selectedMetodoPago = 'Todos';
  String _selectedEstado = 'Todos';
  
  // Listas para los dropdowns
  List<String> _cursos = ['Todos'];
  List<String> _planes = ['Todos'];
  List<String> _metodosPago = ['Todos'];

  @override
void initState() {
  super.initState();
  _cargarPerfilesFisicos();
  _cargarOpcionesFiltros();
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

// ============ CARGAR OPCIONES PARA FILTROS ============
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

// ============ APLICAR FILTROS ============
bool _aplicarFiltros(Map<String, dynamic> data) {
  final nombreCompleto = '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.toLowerCase();
  final busqueda = _searchController.text.toLowerCase();
  
  // Filtro por búsqueda de texto
  if (_searchController.text.isNotEmpty && 
      !nombreCompleto.contains(busqueda)) {
    return false;
  }
  
  // Filtro por curso
  if (_selectedCurso != 'Todos' && data['curso'] != _selectedCurso) {
    return false;
  }
  
  // Filtro por plan
  if (_selectedPlan != 'Todos' && data['plan'] != _selectedPlan) {
    return false;
  }
  
  // Filtro por método de pago
  if (_selectedMetodoPago != 'Todos' && data['metodo_pago'] != _selectedMetodoPago) {
    return false;
  }
  
  // Filtro por estado
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

// ============ LIMPIAR FILTROS ============
void _limpiarFiltros() {
  setState(() {
    _searchController.clear();
    _selectedCurso = 'Todos';
    _selectedPlan = 'Todos';
    _selectedMetodoPago = 'Todos';
    _selectedEstado = 'Todos';
  });
}

// ============ WIDGET DE FILTROS ============
Widget _buildFiltros() {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '🔍 Buscar por nombre o apellido...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
              ),
            ),
            onChanged: (value) => setState(() {}),
          ),
          
          const SizedBox(height: 10),
          
          // Filtros en fila
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Filtro por Curso
              _buildFiltroDropdown(
                value: _selectedCurso,
                items: _cursos,
                hint: '🎓 Curso',
                onChanged: (value) => setState(() => _selectedCurso = value!),
              ),
              
              // Filtro por Plan
              _buildFiltroDropdown(
                value: _selectedPlan,
                items: _planes,
                hint: '📋 Plan',
                onChanged: (value) => setState(() => _selectedPlan = value!),
              ),
              
              // Filtro por Método de Pago
              _buildFiltroDropdown(
                value: _selectedMetodoPago,
                items: _metodosPago,
                hint: '💰 Pago',
                onChanged: (value) => setState(() => _selectedMetodoPago = value!),
              ),
              
              // Filtro por Estado
              _buildFiltroDropdown(
                value: _selectedEstado,
                items: ['Todos', 'Activo', 'Por vencer', 'Vencido'],
                hint: '🟢 Estado',
                onChanged: (value) => setState(() => _selectedEstado = value!),
              ),
              
              // Botón limpiar filtros
              OutlinedButton.icon(
                onPressed: _limpiarFiltros,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Limpiar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

// ============ WIDGET PARA DROPDOWN DE FILTROS ============
Widget _buildFiltroDropdown({
  required String value,
  required List<String> items,
  required String hint,
  required Function(String?) onChanged,
}) {
  return Container(
    constraints: const BoxConstraints(minWidth: 120),
    child: DropdownButton<String>(
      value: value,
      isDense: true,
      hint: Text(hint),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value.length > 15 ? '${value.substring(0, 15)}...' : value,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    ),
  );
}

// ============ INDICADOR DE FILTROS ACTIVOS ============
Widget _buildIndicadorFiltros(int totalFiltrados, int totalGeneral) {
  final tieneFiltros = _selectedCurso != 'Todos' ||
      _selectedPlan != 'Todos' ||
      _selectedMetodoPago != 'Todos' ||
      _selectedEstado != 'Todos' ||
      _searchController.text.isNotEmpty;

  if (!tieneFiltros) return const SizedBox();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Chip(
          backgroundColor: Colors.blue[50],
          label: Text(
            '$totalFiltrados de $totalGeneral alumnos',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.filter_alt, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        const Text(
          'Filtros activos',
          style: TextStyle(fontSize: 12, color: Colors.blue),
        ),
      ],
    ),
  );
}

// ============ VISTA CUANDO NO HAY RESULTADOS ============
Widget _buildVistaSinResultados() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.search_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          'No se encontraron alumnos',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          'Ajusta los filtros o busca con otros términos',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _limpiarFiltros,
          child: const Text('Limpiar filtros'),
        ),
      ],
    ),
  );
}


// ============ MÉTODO UNIFICADO PARA TODAS LAS PLATAFORMAS ============
Future<void> _exportarAlumnosExcel() async {
  try {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Generando archivo Excel...'),
          ],
        ),
      ),
    );

    // Obtener todos los alumnos
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

    // Crear contenido CSV
    String csvContent = 'N°;Nombre;Apellido;DNI;Edad;Celular;Correo;Dirección;Curso;Plan;Turno;Promoción;Método Pago;Monto Pagado;Fecha Inicio;Fecha Fin;Estado;Es Menor Edad;Apoderado;DNI Apoderado;Celular Apoderado\n';
    
    int contador = 1;
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      
      // Manejar fechas de forma segura
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

      // Escapar texto para CSV
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

    // Cerrar loading
    Navigator.pop(context);

    // ============ DETECTAR PLATAFORMA Y EXPORTAR ============
    if (kIsWeb) {
      // ============ SOLUCIÓN PARA WEB ============
      _exportarEnWeb(csvContent, contador - 1);
    } else if (Platform.isAndroid || Platform.isIOS) {
      // ============ SOLUCIÓN PARA MÓVIL ============
      _exportarEnMovil(csvContent, contador - 1);
    } else {
      // ============ SOLUCIÓN PARA DESKTOP ============
      _exportarEnDesktop(csvContent, contador - 1);
    }

  } catch (e) {
    // Cerrar loading en caso de error
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

// ============ MÉTODO PARA WEB ============
void _exportarEnWeb(String csvContent, int totalAlumnos) {
  try {
    // Crear blob y descargar
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'alumnos_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv')
      ..click();
    
    html.Url.revokeObjectUrl(url);

    // Mostrar éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Descargando CSV con $totalAlumnos alumnos...'),
        duration: const Duration(seconds: 3),
      ),
    );
  } catch (e) {
    // Fallback: mostrar datos para copiar
    _mostrarDatosParaCopiar(csvContent, totalAlumnos);
  }
}

// ============ MÉTODO PARA MÓVIL ============
Future<void> _exportarEnMovil(String csvContent, int totalAlumnos) async {
  try {
    // Solicitar permisos en Android
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permisos de almacenamiento denegados')),
        );
        return;
      }
    }

    Directory directory;
    String rutaAmigable = '';
    
    if (Platform.isAndroid) {
      directory = (await getDownloadsDirectory()) ?? await getApplicationDocumentsDirectory();
      rutaAmigable = 'Descargas';
    } else {
      directory = await getApplicationDocumentsDirectory();
      rutaAmigable = 'Documentos';
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'alumnos_$timestamp.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvContent, flush: true);

    // Mostrar diálogo de éxito
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Exportación Exitosa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alumnos exportados: $totalAlumnos'),
            const SizedBox(height: 10),
            Text('Archivo: $fileName'),
            Text('Ubicación: $rutaAmigable'),
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
        ],
      ),
    );

  } catch (e) {
    // Fallback para móvil
    _mostrarDatosParaCopiar(csvContent, totalAlumnos);
  }
}

// ============ MÉTODO PARA DESKTOP ============
Future<void> _exportarEnDesktop(String csvContent, int totalAlumnos) async {
  try {
    final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory!.path}/alumnos_$timestamp.csv');
    
    await file.writeAsString(csvContent, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Archivo guardado en: ${file.path}'),
        duration: const Duration(seconds: 5),
      ),
    );
  } catch (e) {
    _mostrarDatosParaCopiar(csvContent, totalAlumnos);
  }
}

// ============ MÉTODO DE FALLBACK ============
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
  // ============ MÉTODO CORREGIDO ============
Widget _buildResumenPerfil(Map<String, dynamic> perfil) {
  final peso = perfil['peso']?.toDouble() ?? 0;
  final altura = perfil['altura']?.toDouble() ?? 0;
  
  // Calcular IMC
  double alturaCm = altura < 3 ? altura * 100 : altura;
  final imc = peso / ((alturaCm / 100) * (alturaCm / 100));
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Medidas básicas
      Text('⚖️ Peso: $peso kg'),
      Text('📏 Altura: ${alturaCm.toStringAsFixed(0)} cm'),
      Text('🧮 IMC: ${imc.toStringAsFixed(1)}'),
      
      // Peso objetivo si existe
      if (perfil['pesoObjetivo'] != null && perfil['pesoObjetivo'] > 0)
        Text('🎯 Objetivo: ${perfil['pesoObjetivo']} kg'),
      
      // Mostrar medidas corporales específicas
      ..._buildMedidasEspecificas(perfil),
      
      // Observaciones específicas
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
              // ============ NUEVO: HISTORIAL PERFIL FÍSICO ============
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

    // Cargar perfil físico para mostrar en el diálogo
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
              // Información personal
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
              
              // PERFIL FÍSICO si existe
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
    
    // Medidas básicas
    medidas.add(Text('Peso: $peso kg'));
    medidas.add(Text('Altura: ${alturaCm.toStringAsFixed(0)} cm'));
    medidas.add(Text('IMC: ${imc.toStringAsFixed(1)}'));
    
    if (perfilData['pesoObjetivo'] != null) {
      medidas.add(Text('Objetivo: ${perfilData['pesoObjetivo']} kg'));
    }
    
    // Medidas corporales
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
    
    // Observaciones
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
          onPressed: () {
            _cargarPerfilesFisicos();
            _cargarOpcionesFiltros();
          },
          tooltip: 'Actualizar perfiles físicos',
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _exportarAlumnosExcel,
          tooltip: 'Exportar alumnos a Excel',
        ),
      ],
    ),
    
    body: SafeArea(
      child: Column(
        children: [
          // Sección de filtros
          _buildFiltros(),
          
          // Indicador de filtros activos
          StreamBuilder<QuerySnapshot>(
            stream: fs.streamAlumnos(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              
              final docs = snapshot.data!.docs;
              final filtrados = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _aplicarFiltros(data);
              }).toList();
              
              return _buildIndicadorFiltros(filtrados.length, docs.length);
            },
          ),
          
          const SizedBox(height: 8),
          
          // Lista de alumnos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.streamAlumnos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                
                // Aplicar filtros
                final alumnosFiltrados = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _aplicarFiltros(data);
                }).toList();

                if (alumnosFiltrados.isEmpty) {
                  return _buildVistaSinResultados();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: alumnosFiltrados.length,
                  itemBuilder: (context, i) {
                    final doc = alumnosFiltrados[i];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    final nombre = data['nombre'] ?? '';
                    final curso = data['curso'] ?? '';
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
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          nombre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '$curso • Vence: ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            _buildPerfilFisico(doc.id),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _mostrarMenuOpciones(context, doc.id, data, doc),
                        ),
                        onTap: () => _mostrarMenuOpciones(context, doc.id, data, doc),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
  
}