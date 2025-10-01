// Puedes crear un nuevo archivo: models/perfil_fisico_model.dart
class PerfilFisico {
  final String alumnoId;
  final DateTime fechaRegistro;
  final double peso; // kg
  final double altura; // cm
  final double cintura; // cm
  final double pecho; // cm
  final double espalda; // cm
  final double hombros; // cm
  final double brazo; // cm
  final double pierna; // cm
  final String? fotoUrl;
  final String? observaciones;
  final double? pesoObjetivo;

  PerfilFisico({
    required this.alumnoId,
    required this.fechaRegistro,
    required this.peso,
    required this.altura,
    required this.cintura,
    required this.pecho,
    required this.espalda,
    required this.hombros,
    required this.brazo,
    required this.pierna,
    this.fotoUrl,
    this.observaciones,
    this.pesoObjetivo,
  });

  // Calcular IMC
  double get imc => peso / ((altura / 100) * (altura / 100));

  // Categoría IMC
  String get categoriaIMC {
    final imcVal = imc;
    if (imcVal < 18.5) return 'Bajo peso';
    if (imcVal < 25) return 'Normal';
    if (imcVal < 30) return 'Sobrepeso';
    return 'Obesidad';
  }
}