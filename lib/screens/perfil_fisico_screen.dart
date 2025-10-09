import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // Para Clipboard

class PerfilFisicoScreen extends StatefulWidget {
  final String alumnoId;
  final String nombreAlumno;

  const PerfilFisicoScreen({super.key, required this.alumnoId, required this.nombreAlumno});

  @override
  State<PerfilFisicoScreen> createState() => _PerfilFisicoScreenState();
}

class _PerfilFisicoScreenState extends State<PerfilFisicoScreen> {
  final _formKey = GlobalKey<FormState>();

  
  
  // Controladores para los campos
  final _pesoCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _pechoCtrl = TextEditingController();
  final _espaldaCtrl = TextEditingController();
  final _hombrosCtrl = TextEditingController();
  final _brazoCtrl = TextEditingController();
  final _piernaCtrl = TextEditingController();
  final _pesoObjetivoCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  String _videoUrlPelea = '';

  
  // Variables para niveles
  String _cinturonJiujitsu = 'Blanco';
  String _nivelMma = 'Amateur';
  String _nivelBox = 'Principiante';
  String _nivelMuayThai = 'Principiante';
  String _cinturonSanda = 'Blanco';

  // Variables para PELEAS (NUEVAS)
  String _tipoPelea = 'MMA';
  String _resultadoPelea = 'Victoria';
  String _metodoPelea = 'KO';
  String _oponentePelea = '';
  String _eventoPelea = '';
  int _roundsPelea = 3;
  String _notasPelea = '';
  
  // Para mostrar el último perfil
  Map<String, dynamic>? _ultimoPerfil;
  
  // Datos del alumno para peleas
  Map<String, dynamic>? _datosAlumnoCompletos;
  List<dynamic> _historialPeleas = [];

  @override
  void initState() {
    super.initState();
    _cargarUltimoPerfil();
    _cargarNivelesAlumno();
    _cargarDatosAlumnoCompletos();
  }

  // NUEVO: Cargar datos completos del alumno
  Future<void> _cargarDatosAlumnoCompletos() async {
    try {
      final alumnoDoc = await FirebaseFirestore.instance
          .collection('alumnos')
          .doc(widget.alumnoId)
          .get();

      if (alumnoDoc.exists) {
        final data = alumnoDoc.data()!;
        setState(() {
          _datosAlumnoCompletos = data;
          _historialPeleas = data['historial_peleas'] ?? [];
        });
      }
    } catch (e) {
      print('Error cargando datos completos del alumno: $e');
    }
  }

  Future<void> _cargarNivelesAlumno() async {
  try {
    final alumnoDoc = await FirebaseFirestore.instance
        .collection('alumnos')
        .doc(widget.alumnoId)
        .get();

    if (alumnoDoc.exists) {
      final data = alumnoDoc.data()!;
      setState(() {
        _cinturonJiujitsu = data['cinturon_jiujitsu'] ?? 'Blanco';
        _nivelMma = data['nivel_mma'] ?? 'Amateur'; // ✅ CAMBIADO A 'Amateur'
        _nivelBox = data['nivel_box'] ?? 'Principiante';
        _nivelMuayThai = data['nivel_muay_thai'] ?? 'Principiante';
        _cinturonSanda = data['cinturon_sanda'] ?? 'Blanco';
      });
    }
  } catch (e) {
    print('Error cargando niveles del alumno: $e');
  }
}
  Future<void> _cargarUltimoPerfil() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('perfiles_fisicos')
          .where('alumnoId', isEqualTo: widget.alumnoId)
          .orderBy('fechaRegistro', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _ultimoPerfil = querySnapshot.docs.first.data();
        });
      }
    } catch (e) {
      print('Error cargando último perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Perfil, Niveles, Peleas
      child: Scaffold(
        appBar: AppBar(
          title: Text('Perfil - ${widget.nombreAlumno}'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Perfil'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Niveles'),
              Tab(icon: Icon(Icons.sports_mma), text: 'Peleas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabPerfil(),      // Contenido de perfil físico
            _buildTabNiveles(),     // Sección de niveles
            _buildTabPeleas(),      // Sección de peleas
          ],
        ),
      ),
    );
  }

  // ✅ PESTAÑA 1: PERFIL FÍSICO
  Widget _buildTabPerfil() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          if (_ultimoPerfil != null) _buildUltimoPerfil(),
          SizedBox(height: 20),
          _buildFormularioNuevoRegistro(),
        ],
      ),
    );
  }

  // ✅ PESTAÑA 2: NIVELES
  Widget _buildTabNiveles() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSeccionActualizarNiveles(),
        ],
      ),
    );
  }

  // ✅ PESTAÑA 3: PELEAS
  Widget _buildTabPeleas() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResumenPeleas(),
          SizedBox(height: 20),
          _buildFormularioPelea(),
          SizedBox(height: 20),
          _buildHistorialPeleas(),
        ],
      ),
    );
  }

  // 🥊 MÉTODOS PARA PELEAS

  Widget _buildResumenPeleas() {
    int peleasMma = _datosAlumnoCompletos?['peleas_mma'] ?? 0;
    int peleasSanda = _datosAlumnoCompletos?['peleas_sanda'] ?? 0;
    int peleasJiujitsu = _datosAlumnoCompletos?['peleas_jiujitsu'] ?? 0;
    int peleasBoxeo = _datosAlumnoCompletos?['peleas_boxeo'] ?? 0;
    int totalPeleas = _datosAlumnoCompletos?['peleas_totales'] ?? 0;

    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('🥊 Resumen de Peleas', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                'Total: $totalPeleas peleas',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildDisciplinaPelea('MMA', peleasMma, Colors.red),
                _buildDisciplinaPelea('Sanda', peleasSanda, Colors.orange),
                _buildDisciplinaPelea('Jiu-Jitsu', peleasJiujitsu, Colors.blue),
                _buildDisciplinaPelea('Boxeo', peleasBoxeo, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisciplinaPelea(String disciplina, int cantidad, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            disciplina,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            cantidad.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'peleas',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioPelea() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('➕ Registrar Nueva Pelea', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _tipoPelea,
            items: ['MMA', 'Sanda', 'Jiu-Jitsu', 'Boxeo'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _tipoPelea = value!),
            decoration: InputDecoration(labelText: 'Tipo de Pelea'),
          ),
          SizedBox(height: 12),
          
          DropdownButtonFormField<String>(
            value: _resultadoPelea,
            items: ['Victoria', 'Derrota', 'Empate'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) => setState(() => _resultadoPelea = value!),
            decoration: InputDecoration(labelText: 'Resultado'),
          ),
          SizedBox(height: 12),
          
          TextFormField(
            decoration: InputDecoration(labelText: 'Oponente *'),
            onChanged: (value) => _oponentePelea = value,
          ),
          SizedBox(height: 12),
          
          TextFormField(
            decoration: InputDecoration(labelText: 'Evento *'),
            onChanged: (value) => _eventoPelea = value,
          ),
          SizedBox(height: 12),

          // ✅ NUEVO CAMPO PARA VIDEO
          TextFormField(
            decoration: InputDecoration(
              labelText: 'URL del Video (YouTube, etc.)',
              hintText: 'https://youtube.com/watch?v=...',
            ),
            onChanged: (value) => _videoUrlPelea = value,
          ),
          SizedBox(height: 8),
          Text(
            'Pega el enlace completo del video (YouTube, Vimeo, etc.)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 12),
          
          TextFormField(
            decoration: InputDecoration(labelText: 'Notas adicionales'),
            maxLines: 2,
            onChanged: (value) => _notasPelea = value,
          ),
          SizedBox(height: 16),
          
          ElevatedButton(
            onPressed: _registrarPelea,
            child: Text('Registrar Pelea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    ),
  );
}

 Widget _buildHistorialPeleas() {
  if (_historialPeleas.isEmpty) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay peleas registradas',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Historial de Peleas', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ..._historialPeleas.take(5).map((pelea) => _buildItemPelea(pelea)),
        ],
      ),
    ),
  );
}

  Widget _buildItemPelea(Map<String, dynamic> pelea) {
  bool tieneVideo = pelea['video_url'] != null && pelea['video_url'].isNotEmpty;
  
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    elevation: 2,
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_mma, color: Colors.red),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pelea['tipo']} • ${pelea['resultado']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'vs ${pelea['oponente']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                _formatearFecha(pelea['fecha']),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          
          if (pelea['evento'] != null) ...[
            SizedBox(height: 4),
            Text(
              'Evento: ${pelea['evento']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
          
          if (tieneVideo) ...[
            SizedBox(height: 8),
            _buildBotonVerVideo(pelea['video_url']),
          ],
          
          if (pelea['notas'] != null && pelea['notas'].isNotEmpty) ...[
            SizedBox(height: 8),
            Text(
              'Notas: ${pelea['notas']}',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildBotonVerVideo(String videoUrl) {
  return ElevatedButton.icon(
    onPressed: () {
      _abrirVideo(videoUrl);
    },
    icon: Icon(Icons.videocam, size: 16),
    label: Text('Ver Video'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.red[50],
      foregroundColor: Colors.red,
      minimumSize: Size(120, 36),
    ),
  );
}


Future<void> _abrirVideo(String url) async {
  try {
    // Puedes usar url_launcher para abrir en el navegador
    // O implementar un reproductor de video integrado
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Video de la Pelea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('¿Cómo quieres ver el video?'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _abrirEnNavegador(url);
                  },
                  child: Text('En Navegador'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _mostrarReproductorIntegrado(url);
                  },
                  child: Text('En App'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al abrir el video: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _abrirEnNavegador(String url) async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Enlace del Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('URL del video:'),
          SizedBox(height: 8),
          SelectableText(
            url,
            style: TextStyle(fontSize: 12, color: Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            'Copia este enlace y ábrelo en tu navegador',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cerrar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Copiar al portapapeles (necesitas importar 'package:flutter/services.dart')
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('URL copiada al portapapeles'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: Text('Copiar URL'),
        ),
      ],
    ),
  );
}

// Método para reproductor integrado
void _mostrarReproductorIntegrado(String url) {
  // Puedes implementar un reproductor con video_player
  // O simplemente abrir en navegador por ahora
  _abrirEnNavegador(url);
}

  // NUEVO: Método para registrar pelea
  Future<void> _registrarPelea() async {
  try {
    // Validar campos obligatorios
    if (_oponentePelea.isEmpty || _eventoPelea.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Oponente y Evento son obligatorios'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar URL de video (si se proporciona)
    if (_videoUrlPelea.isNotEmpty && !_esUrlValida(_videoUrlPelea)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ URL de video no válida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String tipoKey = '';
    switch (_tipoPelea) {
      case 'Jiu-Jitsu':
        tipoKey = 'peleas_jiujitsu';
        break;
      case 'Boxeo':
        tipoKey = 'peleas_boxeo';
        break;
      case 'MMA':
        tipoKey = 'peleas_mma';
        break;
      case 'Sanda':
        tipoKey = 'peleas_sanda';
        break;
      default:
        tipoKey = 'peleas_${_tipoPelea.toLowerCase().replaceAll('-', '_')}';
    }

    final nuevaPelea = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'tipo': _tipoPelea,
      'fecha': Timestamp.now(),
      'resultado': _resultadoPelea,
      'oponente': _oponentePelea,
      'evento': _eventoPelea,
      'rounds': _roundsPelea,
      'metodo': _metodoPelea,
      'notas': _notasPelea,
      'video_url': _videoUrlPelea, // ✅ NUEVO CAMPO
      'registrado_por': 'Entrenador',
    };

    final contadorActual = _datosAlumnoCompletos?[tipoKey] ?? 0;
    final totalActual = _datosAlumnoCompletos?['peleas_totales'] ?? 0;

    await FirebaseFirestore.instance
        .collection('alumnos')
        .doc(widget.alumnoId)
        .update({
      tipoKey: contadorActual + 1,
      'peleas_totales': totalActual + 1,
      'historial_peleas': FieldValue.arrayUnion([nuevaPelea]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Pelea de $_tipoPelea registrada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );

    // Limpiar campos después de registrar
    _limpiarCamposPelea();

    // Recargar datos para actualizar la UI
    await _cargarDatosAlumnoCompletos();

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error al registrar pelea: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Método para limpiar campos después de registrar
void _limpiarCamposPelea() {
  setState(() {
    _oponentePelea = '';
    _eventoPelea = '';
    _videoUrlPelea = '';
    _notasPelea = '';
  });
}

// Método para validar URL
// ✅ NUEVO MÉTODO MEJORADO PARA VALIDAR URL
bool _esUrlValida(String url) {
  if (url.isEmpty) return true; // URL vacía es válida (opcional)
  
  try {
    // Patrón más flexible para URLs de video
    final urlPattern = r'^(https?:\/\/)?([\w-]+\.)+[\w-]+([\w-.,@?^=%&:/~+#]*[\w-@?^=%&/~+#])?$';
    final isValidFormat = RegExp(urlPattern, caseSensitive: false).hasMatch(url);
    
    if (!isValidFormat) return false;
    
    // Verificar específicamente URLs de plataformas de video
    final videoPlatforms = [
      'youtube.com',
      'youtu.be',
      'vimeo.com',
      'dailymotion.com',
      'twitch.tv'
    ];
    
    final lowerUrl = url.toLowerCase();
    return videoPlatforms.any((platform) => lowerUrl.contains(platform));
    
  } catch (e) {
    return false;
  }
}

  // ✅ MÉTODO ÚNICO PARA FORMATEAR FECHA (sin duplicados)
  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'No disponible';
    if (fecha is Timestamp) {
      final date = fecha.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return fecha.toString();
  }

  // ✅ MÉTODOS QUE FALTABAN (los copias de tu código original)

  Widget _buildSeccionActualizarNiveles() {
    return Card(
      color: Colors.amber[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Actualización Rápida de Niveles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Actualiza solo los cinturones y niveles sin crear un nuevo perfil físico',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _buildNivelesActuales(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _mostrarDialogoActualizarNiveles,
              icon: const Icon(Icons.upgrade),
              label: const Text('Actualizar Niveles'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNivelesActuales() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildBadgeNivel('Jiu Jitsu', _cinturonJiujitsu),
        _buildBadgeNivel('Sanda', _cinturonSanda),
        _buildBadgeNivel('MMA', _nivelMma),
        _buildBadgeNivel('Box', _nivelBox),
        _buildBadgeNivel('Muay Thai', _nivelMuayThai),
      ],
    );
  }

  Widget _buildBadgeNivel(String arte, String nivel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _obtenerColorCinturon(nivel).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _obtenerColorCinturon(nivel)),
      ),
      child: Text(
        '$arte: $nivel',
        style: TextStyle(
          fontSize: 12,
          color: _obtenerColorCinturon(nivel),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoActualizarNiveles() async {
  String tempJiujitsu = _cinturonJiujitsu;
  String tempSanda = _cinturonSanda;
  String tempMma = _nivelMma;
  String tempBox = _nivelBox;
  String tempMuayThai = _nivelMuayThai;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Actualizar Niveles'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdownDialogo(
              label: 'Jiu Jitsu',
              value: tempJiujitsu,
              items: const ['Blanco', 'Azul', 'Morado', 'Marrón', 'Negro'],
              onChanged: (value) => tempJiujitsu = value!,
            ),
            _buildDropdownDialogo(
              label: 'Sanda',
              value: tempSanda,
              items: const ['Blanco', 'Amarillo', 'Verde', 'Azul', 'Rojo', 'Negro'],
              onChanged: (value) => tempSanda = value!,
            ),
            _buildDropdownDialogo(
              label: 'MMA',
              value: tempMma,
              items: const ['Amateur', 'Semi-Profesional', 'Profesional'], // ✅ CORREGIDO
              onChanged: (value) => tempMma = value!,
            ),
            _buildDropdownDialogo(
              label: 'Box',
              value: tempBox,
              items: const ['Principiante', 'Intermedio', 'Avanzado'],
              onChanged: (value) => tempBox = value!,
            ),
            _buildDropdownDialogo(
              label: 'Muay Thai',
              value: tempMuayThai,
              items: const ['Principiante', 'Intermedio', 'Avanzado'],
              onChanged: (value) => tempMuayThai = value!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await _actualizarSoloNiveles(
              tempJiujitsu,
              tempSanda,
              tempMma,
              tempBox,
              tempMuayThai,
            );
          },
          child: const Text('Guardar Niveles'),
        ),
      ],
    ),
  );
}

  Widget _buildDropdownDialogo({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _actualizarSoloNiveles(
    String jiujitsu,
    String sanda,
    String mma,
    String box,
    String muayThai,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('alumnos')
          .doc(widget.alumnoId)
          .update({
        'cinturon_jiujitsu': jiujitsu,
        'cinturon_sanda': sanda,
        'nivel_mma': mma,
        'nivel_box': box,
        'nivel_muay_thai': muayThai,
        'fecha_actualizacion_niveles': Timestamp.now(),
      });

      setState(() {
        _cinturonJiujitsu = jiujitsu;
        _cinturonSanda = sanda;
        _nivelMma = mma;
        _nivelBox = box;
        _nivelMuayThai = muayThai;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Niveles actualizados exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar niveles: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Widget para mostrar el último perfil físico
  Widget _buildUltimoPerfil() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Último Perfil Registrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 10),
            _buildPerfilFisico(_ultimoPerfil!),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar el perfil físico (CORREGIDO - SIN DUPLICADOS)
  Widget _buildPerfilFisico(Map<String, dynamic> perfilData) {
    final peso = perfilData['peso']?.toDouble() ?? 0.0;
    final altura = perfilData['altura']?.toDouble() ?? 0.0;

    if (peso <= 0 || altura <= 0) {
      return const Text(
        '📝 Perfil incompleto',
        style: TextStyle(fontSize: 14, color: Colors.orange),
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
        Text(
          '⚖️ Peso: $peso kg • 📏 Altura: ${alturaCm.toStringAsFixed(0)} cm',
          style: const TextStyle(fontSize: 14, color: Colors.green),
        ),
        const SizedBox(height: 5),
        
        Text(
          '🧮 IMC: ${imc.toStringAsFixed(1)} (${_categoriaIMC(imc)})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),

        if (perfilData['niveles_registrados'] != null)
          _buildNivelesPerfil(perfilData['niveles_registrados']),
      
        if (_tieneMedidasCorporales(perfilData))
          _buildMedidasCorporales(perfilData),
      
        if (perfilData['pesoObjetivo'] != null && perfilData['pesoObjetivo'] > 0)
          Text(
            '🎯 Peso Objetivo: ${perfilData['pesoObjetivo']} kg',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
        
        if (perfilData['observaciones'] != null && perfilData['observaciones'].isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
              const Text(
                '📝 Observaciones:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                perfilData['observaciones'],
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        
        const SizedBox(height: 10),
        Text(
          '📅 Fecha: ${_formatearFecha(perfilData['fechaRegistro'])}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

 

  // Función para verificar si hay medidas corporales
  bool _tieneMedidasCorporales(Map<String, dynamic> perfilData) {
    return (perfilData['cintura'] != null && perfilData['cintura'] > 0) ||
           (perfilData['pecho'] != null && perfilData['pecho'] > 0) ||
           (perfilData['espalda'] != null && perfilData['espalda'] > 0) ||
           (perfilData['hombros'] != null && perfilData['hombros'] > 0) ||
           (perfilData['brazo'] != null && perfilData['brazo'] > 0) ||
           (perfilData['pierna'] != null && perfilData['pierna'] > 0);
  }

  Widget _buildNivelesPerfil(Map<String, dynamic> niveles) {
    final List<Widget> nivelesWidgets = [];
    
    void agregarNivel(String arte, String nivel) {
      if (nivel != null && nivel.isNotEmpty) {
        nivelesWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _obtenerColorCinturon(nivel).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _obtenerColorCinturon(nivel)),
            ),
            child: Text(
              '$arte: $nivel',
              style: TextStyle(
                fontSize: 10,
                color: _obtenerColorCinturon(nivel),
                fontWeight: FontWeight.bold,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        const Text(
          'Niveles:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: nivelesWidgets,
        ),
        const SizedBox(height: 5),
      ],
    );
  }

  // Widget para mostrar medidas corporales
  Widget _buildMedidasCorporales(Map<String, dynamic> perfilData) {
    final List<Widget> medidasWidgets = [];
    
    void agregarMedida(String icono, String label, dynamic valor) {
      if (valor != null && valor > 0) {
        medidasWidgets.add(
          Text(
            '$icono $label: ${valor}cm',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }
    }

    agregarMedida('📐', 'Cintura', perfilData['cintura']);
    agregarMedida('💪', 'Pecho', perfilData['pecho']);
    agregarMedida('🔙', 'Espalda', perfilData['espalda']);
    agregarMedida('👤', 'Hombros', perfilData['hombros']);
    agregarMedida('💪', 'Brazo', perfilData['brazo']);
    agregarMedida('🦵', 'Pierna', perfilData['pierna']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        const Text(
          'Medidas Corporales:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: medidasWidgets,
        ),
      ],
    );
  }

  // Formulario para nuevo registro
  Widget _buildFormularioNuevoRegistro() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nuevo Registro',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildSeccionNiveles(),
              const SizedBox(height: 20),
              _buildSeccionMedidas(),
              const SizedBox(height: 20),
              _buildSeccionMedidasCorporales(),
              const SizedBox(height: 20),
              _buildSeccionObservaciones(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _guardarPerfil,
                child: const Text('Guardar Nuevo Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionNiveles() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Niveles y Cinturones',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      const Text(
        'Actualiza los niveles del alumno:',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      ),
      const SizedBox(height: 15),
      _buildDropdownNivel(
        label: 'Jiu Jitsu',
        value: _cinturonJiujitsu,
        items: const ['Blanco', 'Azul', 'Morado', 'Marrón', 'Negro'],
        onChanged: (value) => setState(() => _cinturonJiujitsu = value!),
        color: _obtenerColorCinturon(_cinturonJiujitsu),
      ),
      const SizedBox(height: 12),
      _buildDropdownNivel(
        label: 'Sanda',
        value: _cinturonSanda,
        items: const ['Blanco', 'Amarillo', 'Verde', 'Azul', 'Rojo', 'Negro'],
        onChanged: (value) => setState(() => _cinturonSanda = value!),
        color: _obtenerColorCinturon(_cinturonSanda),
      ),
      const SizedBox(height: 12),
      _buildDropdownNivel(
        label: 'MMA',
        value: _nivelMma,
        items: const ['Amateur', 'Semi-Profesional', 'Profesional'], // ✅ SIN ESPACIO
        onChanged: (value) => setState(() => _nivelMma = value!),
        color: Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildDropdownNivel(
        label: 'Box',
        value: _nivelBox,
        items: const ['Principiante', 'Intermedio', 'Avanzado'],
        onChanged: (value) => setState(() => _nivelBox = value!),
        color: Colors.red,
      ),
      const SizedBox(height: 12),
      _buildDropdownNivel(
        label: 'Muay Thai',
        value: _nivelMuayThai,
        items: const ['Principiante', 'Intermedio', 'Avanzado'],
        onChanged: (value) => setState(() => _nivelMuayThai = value!),
        color: Colors.purple,
      ),
    ],
  );
}

  Color _obtenerColorCinturon(String nivel) {
  switch (nivel.toLowerCase()) {
    // CINTURONES JIU JITSU
    case 'blanco': return Colors.grey[300]!;
    case 'azul': return Colors.blue;
    case 'morado': return Colors.purple;
    case 'marrón': return Colors.brown;
    case 'negro': return Colors.black;
    
    // CINTURONES SANDA
    case 'amarillo': return Colors.yellow[700]!;
    case 'verde': return Colors.green;
    case 'rojo': return Colors.red;
    
    // NIVELES MMA
    case 'amateur': return Colors.blue;
    case 'semi-profesional': return Colors.orange;
    case 'profesional': return Colors.red;
    
    // NIVELES GENERALES
    case 'principiante': return Colors.green;
    case 'intermedio': return Colors.orange;
    case 'avanzado': return Colors.red;
    
    default: return Colors.grey;
  }
}

  Widget _buildDropdownNivel({
  required String label,
  required String value,
  required List<String> items,
  required Function(String?) onChanged,
  required Color color,
}) {
  // ✅ VALIDACIÓN: Si el valor actual no está en los items, usa el primero
  final currentValue = items.contains(value) ? value : items.first;
  
  final brightness = ThemeData.estimateBrightnessForColor(color);
  final textColor = brightness == Brightness.light ? Colors.black87 : Colors.white;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              DropdownButtonFormField<String>(
                value: currentValue, // ✅ USA EL VALOR VALIDADO
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.arrow_drop_down, color: textColor),
                isExpanded: true,
                dropdownColor: color.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _buildSeccionMedidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medidas Básicas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pesoCtrl,
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obligatorio';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _alturaCtrl,
                decoration: const InputDecoration(labelText: 'Altura (cm)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo obligatorio';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _pesoObjetivoCtrl,
          decoration: const InputDecoration(labelText: 'Peso Objetivo (kg)'),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildSeccionMedidasCorporales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Medidas Corporales (cm)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildMedidaInput('Cintura', _cinturaCtrl, 120),
            _buildMedidaInput('Pecho', _pechoCtrl, 120),
            _buildMedidaInput('Espalda', _espaldaCtrl, 120),
            _buildMedidaInput('Hombros', _hombrosCtrl, 120),
            _buildMedidaInput('Brazo', _brazoCtrl, 120),
            _buildMedidaInput('Pierna', _piernaCtrl, 120),
          ],
        ),
      ],
    );
  }

  Widget _buildMedidaInput(String label, TextEditingController controller, double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildSeccionObservaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Observaciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _observacionesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notas del entrenador',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  String _categoriaIMC(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Future<void> _guardarPerfil() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    // ✅ VALIDACIÓN FINAL DE VALORES
    final nivelesRegistrados = {
      'jiujitsu': _cinturonJiujitsu,
      'mma': _nivelMma,
      'box': _nivelBox,
      'muay_thai': _nivelMuayThai,
      'sanda': _cinturonSanda,
    };

    final perfilData = {
      'alumnoId': widget.alumnoId,
      'fechaRegistro': Timestamp.now(),
      'peso': double.tryParse(_pesoCtrl.text) ?? 0,
      'altura': double.tryParse(_alturaCtrl.text) ?? 0,
      'cintura': double.tryParse(_cinturaCtrl.text) ?? 0,
      'pecho': double.tryParse(_pechoCtrl.text) ?? 0,
      'espalda': double.tryParse(_espaldaCtrl.text) ?? 0,
      'hombros': double.tryParse(_hombrosCtrl.text) ?? 0,
      'brazo': double.tryParse(_brazoCtrl.text) ?? 0,
      'pierna': double.tryParse(_piernaCtrl.text) ?? 0,
      'pesoObjetivo': double.tryParse(_pesoObjetivoCtrl.text),
      'observaciones': _observacionesCtrl.text,
      'niveles_registrados': nivelesRegistrados,
    };

    await FirebaseFirestore.instance
        .collection('perfiles_fisicos')
        .add(perfilData);

    await _cargarUltimoPerfil();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil físico y niveles guardados exitosamente')),
    );

    // Limpiar campos
    _pesoCtrl.clear();
    _alturaCtrl.clear();
    _cinturaCtrl.clear();
    _pechoCtrl.clear();
    _espaldaCtrl.clear();
    _hombrosCtrl.clear();
    _brazoCtrl.clear();
    _piernaCtrl.clear();
    _pesoObjetivoCtrl.clear();
    _observacionesCtrl.clear();
    
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
  @override
  void dispose() {
    _pesoCtrl.dispose();
    _alturaCtrl.dispose();
    _cinturaCtrl.dispose();
    _pechoCtrl.dispose();
    _espaldaCtrl.dispose();
    _hombrosCtrl.dispose();
    _brazoCtrl.dispose();
    _piernaCtrl.dispose();
    _pesoObjetivoCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }
}