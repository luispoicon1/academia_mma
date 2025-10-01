import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Colección principal de alumnos
  final CollectionReference alumnos =
      FirebaseFirestore.instance.collection('alumnos');

  // Colección de historial de todos los registros
  final CollectionReference historial =
<<<<<<< HEAD
      FirebaseFirestore.instance.collection('Publicaciones');
=======
      FirebaseFirestore.instance.collection('historial_alumnos');
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f

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
    'alumnoId': docRef.id,           // ❗ referencia al alumno
    'fecha_registro': Timestamp.now(), // ❗ fecha de registro
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
Future<void> addPago(Map<String, dynamic> data) async {
  await FirebaseFirestore.instance.collection('pagos').add({
    ...data,
    'fecha_pago': Timestamp.now(),
  });
}

// 🔹 Obtener pagos en tiempo real
Stream<QuerySnapshot> streamPagos() {
  return FirebaseFirestore.instance
      .collection('pagos')
      .orderBy('fecha_pago', descending: true)
      .snapshots();
}

// 🔹 Calcular ingresos de un mes
Future<double> calcularIngresosMesHastaHoy(int anio, int mes) async {
  final fs = FirebaseFirestore.instance;
  final inicioMes = DateTime(anio, mes, 1).toUtc();
  final hoy = DateTime.now().toUtc();

final snapshot = await FirebaseFirestore.instance
    .collection('alumnos') // o 'historial_alumnos' si quieres historial
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
Future<double> calcularIngresosMesDesdeAlumnos(int anio, int mes) async {
  final inicioMes = DateTime(anio, mes, 1);
  final finMes = DateTime(anio, mes + 1, 0, 23, 59, 59);

  final snapshot = await alumnos
      .where('fecha_inicio', isGreaterThanOrEqualTo: inicioMes)
      .where('fecha_inicio', isLessThanOrEqualTo: finMes)
      .get();

  double total = 0;
  for (var doc in snapshot.docs) {
    total += (doc['monto_pagado'] as num).toDouble();
  }

  return total;
}
}