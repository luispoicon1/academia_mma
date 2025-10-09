import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/niveles_model.dart';

class AlumnoFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<NivelAlumno> obtenerNivelesAlumno(String alumnoId) async {
  try {
    // Primero intentar obtener del perfil físico (más actualizado)
    final perfilFisico = await obtenerPerfilFisico(alumnoId);
    if (perfilFisico != null && perfilFisico['niveles_registrados'] != null) {
      print('🎯 Niveles desde perfil físico: ${perfilFisico['niveles_registrados']}');
      return NivelAlumno.fromPerfilFisico(perfilFisico);
    }
    
    // Si no hay perfil físico, obtener de alumnos
    final doc = await _firestore.collection('alumnos').doc(alumnoId).get();
    if (doc.exists) {
      print('🎯 Niveles desde alumnos: ${doc.data()}');
      return NivelAlumno.fromFirestore(doc.data()!);
    }
    
    return NivelAlumno(
      nivelMma: 'Principiante',
      cinturonJiujitsu: 'Blanco',
      nivelSanda: 'Blanco',
      nivelBox: 'Principiante', // ✅ NUEVO
      nivelMuayThai: 'Principiante', // ✅ NUEVO
      progreso: {
        'jiujitsu': 0.0, 
        'mma': 0.0, 
        'sanda': 0.0,
        'box': 0.0, // ✅ NUEVO
        'muay_thai': 0.0, // ✅ NUEVO
      },
    );
  } catch (e) {
    print('Error obteniendo niveles: $e');
    return NivelAlumno(
      nivelMma: 'Principiante',
      cinturonJiujitsu: 'Blanco',
      nivelSanda: 'Blanco',
      nivelBox: 'Principiante', // ✅ NUEVO
      nivelMuayThai: 'Principiante', // ✅ NUEVO
      progreso: {
        'jiujitsu': 0.0, 
        'mma': 0.0, 
        'sanda': 0.0,
        'box': 0.0, // ✅ NUEVO
        'muay_thai': 0.0, // ✅ NUEVO
      },
    );
  }
}
// En AlumnoFirestoreService - AGREGAR ESTOS MÉTODOS:

Future<Map<String, dynamic>?> obtenerPerfilFisico(String alumnoId) async {
  try {
    final querySnapshot = await _firestore
        .collection('perfiles_fisicos')
        .where('alumnoId', isEqualTo: alumnoId)
        .orderBy('fechaRegistro', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
  } catch (e) {
    print('Error obteniendo perfil físico: $e');
    return null;
  }
}

Future<List<Map<String, dynamic>>> obtenerHistorialPerfiles(String alumnoId) async {
  try {
    final querySnapshot = await _firestore
        .collection('perfiles_fisicos')
        .where('alumnoId', isEqualTo: alumnoId)
        .orderBy('fechaRegistro', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
      };
    }).toList();
  } catch (e) {
    print('Error obteniendo historial de perfiles: $e');
    return [];
  }
}

Future<Map<String, dynamic>?> obtenerDatosCompletosAlumno(String alumnoId) async {
  try {
    final doc = await _firestore.collection('alumnos').doc(alumnoId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  } catch (e) {
    print('Error obteniendo datos alumno: $e');
    return null;
  }
}


  Future<List<Map<String, dynamic>>> obtenerUltimosPagos(String alumnoId) async {
    try {
      final datosAlumno = await _firestore.collection('alumnos').doc(alumnoId).get();
      final dniAlumno = datosAlumno.data()?['dni'];
      
      if (dniAlumno == null) return [];

      final query = await _firestore
          .collection('pagos')
          .where('dni', isEqualTo: dniAlumno)
          .orderBy('fecha_pago', descending: true)
          .limit(5)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'monto': data['monto'] ?? 0.0,
          'metodo': data['metodo'] ?? '',
          'fecha_pago': data['fecha_pago'],
          'concepto': data['concepto'] ?? 'Mensualidad',
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo pagos: $e');
      return [];
    }
  }
}