import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_type_service.dart';

class AlumnoAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<User?> loginAlumno(String dni, String celular) async {
  try {
    final dniLimpio = dni.trim();
    final celularLimpio = celular.trim();
    
    print('🔐 BUSCANDO ALUMNO: DNI="$dniLimpio", Celular="$celularLimpio"');

    
    final query = await _firestore
        .collection('alumnos')
        .where('dni', isEqualTo: dniLimpio)
        .where('celular', isEqualTo: celularLimpio)
        .where('estado', whereIn: ['Activo', 'Por vencer']) 
        .get();

    print('🎯 RESULTADO CONSULTA: ${query.docs.length} alumnos encontrados');
    
    if (query.docs.isNotEmpty) {
      final alumnoDoc = query.docs.first;
      final alumnoData = alumnoDoc.data();
      final estado = alumnoData['estado'] ?? '';
      
      print('✅ ALUMNO ENCONTRADO: ${alumnoData['nombre']} - Estado: $estado');
      
      
      if (estado == 'Por vencer') {
        print('⚠️  Alumno con membresía por vencer');
      }
      
      final userCredential = await _auth.signInAnonymously();
      await UserTypeService.guardarSesionAlumno(alumnoDoc.id, alumnoData);
      
      return userCredential.user;
    } else {
      print('❌ NO SE ENCONTRÓ ALUMNO CON ESOS DATOS');
      
      
      final queryTodos = await _firestore
          .collection('alumnos')
          .where('dni', isEqualTo: dniLimpio)
          .where('celular', isEqualTo: celularLimpio)
          .get();
          
      if (queryTodos.docs.isNotEmpty && queryTodos.docs.first.data()['estado'] == 'Vencido') {
        throw 'Tu membresía está vencida. Contacta con administración.';
      } else {
        throw 'Alumno no encontrado. Verifica tu DNI y celular.';
      }
    }
  } catch (e) {
    print('💥 ERROR EN LOGIN: $e');
    throw 'Error en login: $e';
  }
}

  Future<void> logout() async {
    await UserTypeService.limpiarSesionAlumno();
    await _auth.signOut();
  }
}
