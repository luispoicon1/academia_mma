import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_type.dart';

class UserTypeService {
  static Future<UserType> determinarTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();

    final esAlumno = prefs.getBool('es_alumno') ?? false;
    final alumnoId = prefs.getString('alumno_id');

    if (esAlumno && alumnoId != null) {
      return UserType.alumno;
    }

    return UserType.admin;
  }

  static Future<void> guardarSesionAlumno(String alumnoId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('es_alumno', true);
    await prefs.setString('alumno_id', alumnoId);
    await prefs.setString('alumno_nombre', data['nombre'] ?? '');
    await prefs.setString('alumno_dni', data['dni'] ?? '');
    await prefs.setString('alumno_curso', data['curso'] ?? '');
  }

  static Future<void> limpiarSesionAlumno() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('es_alumno');
    await prefs.remove('alumno_id');
    await prefs.remove('alumno_nombre');
    await prefs.remove('alumno_dni');
    await prefs.remove('alumno_curso');
  }

  static Future<Map<String, String?>> getDatosAlumno() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString('alumno_id'),
      'nombre': prefs.getString('alumno_nombre'),
      'dni': prefs.getString('alumno_dni'),
      'curso': prefs.getString('alumno_curso'),
    };
  }

  /// 🔍 Método para debuggear los datos actuales de la sesión guardada
  static Future<void> debugSesion() async {
    final prefs = await SharedPreferences.getInstance();
    print('🐛 DEBUG Sesión:');
    print('   es_alumno: ${prefs.getBool('es_alumno')}');
    print('   alumno_id: ${prefs.getString('alumno_id')}');
    print('   alumno_nombre: ${prefs.getString('alumno_nombre')}');
    print('   alumno_dni: ${prefs.getString('alumno_dni')}');
    print('   alumno_curso: ${prefs.getString('alumno_curso')}');
  }
}
