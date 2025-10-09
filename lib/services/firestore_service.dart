import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // ← AGREGAR este import

class FirestoreService {
  // Colección principal de alumnos
  final CollectionReference alumnos =
      FirebaseFirestore.instance.collection('alumnos');

  // Colección de historial de todos los registros
  final CollectionReference historial =
      FirebaseFirestore.instance.collection('Publicaciones');

  // Colección de perfiles eliminados
  final CollectionReference perfiles =
      FirebaseFirestore.instance.collection('perfiles_alumnos');

  // 🔹 Agregar alumno y registrar historial
  Future<void> addAlumno(Map<String, dynamic> data) async {
    // Guardar en alumnos
    DocumentReference docRef = await alumnos.add(data);

    // Guardar también en historial con ID único
    await historial.add({
      ...data,
      'alumnoId': docRef.id,           // referencia al alumno
      'fecha_registro': Timestamp.now(), // fecha de registro
    });
  }

  // 🔹 Leer alumnos en tiempo real
  Stream<QuerySnapshot> streamAlumnos() {
    return alumnos.snapshots();
  }

  // 🔹 Leer historial en tiempo real
  Stream<QuerySnapshot> streamHistorial() {
    return historial.orderBy('fecha_registro', descending: true).snapshots();
  }

  // 🔹 Actualizar alumno
  Future<void> updateAlumno(String id, Map<String, dynamic> data) async {
    await alumnos.doc(id).update(data);
  }

  // 🔹 Guardar perfil antes de eliminar alumno
  Future<void> guardarPerfilAlumno(String id, Map<String, dynamic> data) async {
    await perfiles.doc(id).set({
      ...data,
      'fecha_eliminado': Timestamp.now(),
    });
  }

  // 🔹 Calcular estado de membresía
  static String calcularEstado(DateTime fechaFin) {
    final hoy = DateTime.now();
    if (fechaFin.isBefore(hoy)) return "Vencido";
    if (fechaFin.difference(hoy).inDays <= 3) return "Por vencer";
    return "Activo";
  }

  // 🔹 Guardar un pago
  // 🔹 EN FirestoreService - SOLO ACTUALIZA ESTE MÉTODO:
Future<void> addPago(Map<String, dynamic> data) async {
  try {
    // Si es una inscripción, no tiene vencimiento
    final esInscripcion = data['tipo'] == 'inscripcion';
    final fechaPago = DateTime.now();
    final fechaVencimiento = esInscripcion 
        ? null 
        : fechaPago.add(Duration(days: 30)); // 30 días para mensualidades

    await FirebaseFirestore.instance.collection('pagos').add({
      ...data,
      'fecha_pago': Timestamp.now(),
      'fechaVencimiento': fechaVencimiento != null 
          ? Timestamp.fromDate(fechaVencimiento) 
          : null,
      'estado': 'pagado',
      'fechaRegistro': FieldValue.serverTimestamp(),
    });
  } catch (e) {
    print('Error agregando pago: $e');
    throw e;
  }
}

  // 🔹 Calcular ingresos de un mes
  Future<double> calcularIngresosMesHastaHoy(int anio, int mes) async {
    final fs = FirebaseFirestore.instance;
    final inicioMes = DateTime(anio, mes, 1).toUtc();
    final hoy = DateTime.now().toUtc();

    final snapshot = await FirebaseFirestore.instance
        .collection('alumnos')
        .where('fecha_inicio', isGreaterThanOrEqualTo: inicioMes)
        .where('fecha_inicio', isLessThanOrEqualTo: hoy)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      total += (doc['monto_pagado'] as num).toDouble();
    }
    return total;
  }

  // 🔹 Calcular ingresos de un mes desde la colección alumnos
  Future<Map<String, double>> calcularIngresosPorMetodoPago(int anio, int mes) async {
  try {
    final inicioMes = DateTime(anio, mes, 1);
    final finMes = DateTime(anio, mes + 1, 0, 23, 59, 59);

    // ✅ CORREGIR: Consultar la colección 'pagos'
    final snapshot = await FirebaseFirestore.instance
        .collection('pagos')
        .where('fecha_pago', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioMes))
        .where('fecha_pago', isLessThanOrEqualTo: Timestamp.fromDate(finMes))
        .get();

    double totalEfectivo = 0;
    double totalYape = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final monto = (data['monto'] ?? 0).toDouble(); // ✅ Campo 'monto' (no 'monto_pagado')
      final metodo = (data['metodo'] ?? 'Efectivo').toString();

      if (metodo.toLowerCase().contains('yape')) {
        totalYape += monto;
      } else {
        totalEfectivo += monto;
      }
    }

    return {
      'efectivo': totalEfectivo,
      'yape': totalYape,
      'total': totalEfectivo + totalYape,
    };
  } catch (e) {
    print('Error calculando ingresos por método: $e');
    return {'efectivo': 0, 'yape': 0, 'total': 0};
  }
}

// En FirestoreService
final CollectionReference perfilesFisicos =
    FirebaseFirestore.instance.collection('perfiles_fisicos');

// Guardar perfil físico
Future<void> guardarPerfilFisico(Map<String, dynamic> data) async {
  await perfilesFisicos.add(data);
}

// Obtener historial de perfiles físicos de un alumno
Stream<QuerySnapshot> obtenerEvolucionFisica(String alumnoId) {
  return perfilesFisicos
      .where('alumnoId', isEqualTo: alumnoId)
      .orderBy('fechaRegistro', descending: true)
      .snapshots();
}


// 🔹 AGREGAR AL FINAL de FirestoreService - MÉTODOS NUEVOS:

// Obtener pagos de un alumno específico
Future<List<Map<String, dynamic>>> obtenerPagosAlumno(String alumnoId) async {
  try {
    final query = await FirebaseFirestore.instance
        .collection('pagos')
        .where('alumnoId', isEqualTo: alumnoId)
        .orderBy('fecha_pago', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  } catch (e) {
    print('Error obteniendo pagos del alumno: $e');
    return [];
  }
}

// Obtener próximo vencimiento
Future<Map<String, dynamic>?> obtenerProximoVencimiento(String alumnoId) async {
  try {
    final ahora = DateTime.now();
    
    final query = await FirebaseFirestore.instance
        .collection('pagos')
        .where('alumnoId', isEqualTo: alumnoId)
        .where('fechaVencimiento', isGreaterThan: Timestamp.fromDate(ahora))
        .where('tipo', isEqualTo: 'mensualidad') // Solo mensualidades tienen vencimiento
        .orderBy('fechaVencimiento', descending: false)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data() as Map<String, dynamic>;
      return {
        'id': query.docs.first.id,
        ...data,
      };
    }
    return null;
  } catch (e) {
    print('Error obteniendo próximo vencimiento: $e');
    return null;
  }
}

// Calcular días restantes
static int calcularDiasRestantes(Timestamp? fechaVencimiento) {
  if (fechaVencimiento == null) return 999; // Sin vencimiento
  final ahora = DateTime.now();
  final vencimiento = fechaVencimiento.toDate();
  return vencimiento.difference(ahora).inDays;
}

// Obtener estado del pago
static String obtenerEstadoPago(Timestamp? fechaVencimiento) {
  if (fechaVencimiento == null) return 'vigente';
  
  final diasRestantes = calcularDiasRestantes(fechaVencimiento);
  
  if (diasRestantes < 0) return 'vencido';
  if (diasRestantes <= 2) return 'urgente';
  if (diasRestantes <= 5) return 'proximo';
  return 'vigente';
}
// En FirestoreService - AGREGA ESTE MÉTODO:
Stream<QuerySnapshot> streamPagos() {
  return FirebaseFirestore.instance
      .collection('pagos')
      .orderBy('fecha_pago', descending: true)
      .snapshots();
}
}