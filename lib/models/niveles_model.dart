class NivelAlumno {
  final String nivelMma;
  final String cinturonJiujitsu;
  final String nivelSanda;
  final String nivelBox; // ✅ NUEVO
  final String nivelMuayThai; // ✅ NUEVO
  final Map<String, double> progreso;

  NivelAlumno({
    required this.nivelMma,
    required this.cinturonJiujitsu,
    required this.nivelSanda,
    required this.nivelBox, // ✅ NUEVO
    required this.nivelMuayThai, // ✅ NUEVO
    required this.progreso,
  });

  factory NivelAlumno.fromFirestore(Map<String, dynamic> data) {
    return NivelAlumno(
      nivelMma: data['nivel_mma'] ?? 'Principiante',
      cinturonJiujitsu: data['cinturon_jiujitsu'] ?? 'Blanco',
      nivelSanda: data['cinturon_sanda'] ?? 'Blanco',
      nivelBox: data['nivel_box'] ?? 'Principiante', // ✅ NUEVO
      nivelMuayThai: data['nivel_muay_thai'] ?? 'Principiante', // ✅ NUEVO
      progreso: {
        'jiujitsu': (data['progreso_jiujitsu'] ?? 0.0).toDouble(),
        'mma': (data['progreso_mma'] ?? 0.0).toDouble(),
        'sanda': (data['progreso_sanda'] ?? 0.0).toDouble(),
        'box': (data['progreso_box'] ?? 0.0).toDouble(), // ✅ NUEVO
        'muay_thai': (data['progreso_muay_thai'] ?? 0.0).toDouble(), // ✅ NUEVO
      },
    );
  }

  // Método para obtener datos desde perfiles_fisicos
  factory NivelAlumno.fromPerfilFisico(Map<String, dynamic> perfilData) {
    final niveles = perfilData['niveles_registrados'] ?? {};
    
    return NivelAlumno(
      nivelMma: niveles['mma'] ?? 'Principiante',
      cinturonJiujitsu: niveles['jiujitsu'] ?? 'Blanco',
      nivelSanda: niveles['sanda'] ?? 'Blanco',
      nivelBox: niveles['box'] ?? 'Principiante', // ✅ NUEVO
      nivelMuayThai: niveles['muay_thai'] ?? 'Principiante', // ✅ NUEVO
      progreso: {
        'jiujitsu': 0.0, // Por defecto, puedes calcularlo si tienes datos
        'mma': 0.0,
        'sanda': 0.0,
        'box': 0.0,
        'muay_thai': 0.0,
      },
    );
  }
}