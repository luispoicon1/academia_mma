import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Para mostrar el último perfil
  Map<String, dynamic>? _ultimoPerfil;

  @override
  void initState() {
    super.initState();
    _cargarUltimoPerfil();
  }

  // Cargar el último perfil físico guardado
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil Físico - ${widget.nombreAlumno}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // MOSTRAR ÚLTIMO PERFIL GUARDADO
            if (_ultimoPerfil != null) _buildUltimoPerfil(),
            
            // FORMULARIO PARA NUEVO REGISTRO
            _buildFormularioNuevoRegistro(),
          ],
        ),
      ),
    );
  }

  // Widget para mostrar el último perfil físico (NUEVO MÉTODO AÑADIDO)
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

  // Widget para mostrar el perfil físico (CORREGIDO)
  Widget _buildPerfilFisico(Map<String, dynamic> perfilData) {
    final peso = perfilData['peso']?.toDouble() ?? 0.0;
    final altura = perfilData['altura']?.toDouble() ?? 0.0;

    if (peso <= 0 || altura <= 0) {
      return const Text(
        '📝 Perfil incompleto',
        style: TextStyle(fontSize: 14, color: Colors.orange),
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
        // Línea 1: Medidas básicas
        Text(
          '⚖️ Peso: $peso kg • 📏 Altura: ${alturaCm.toStringAsFixed(0)} cm',
          style: const TextStyle(fontSize: 14, color: Colors.green),
        ),
        const SizedBox(height: 5),
        
        // Línea 2: IMC
        Text(
          '🧮 IMC: ${imc.toStringAsFixed(1)} (${_categoriaIMC(imc)})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        
        // Línea 3: Medidas corporales si existen
        if (_tieneMedidasCorporales(perfilData))
          _buildMedidasCorporales(perfilData),
        
        // Línea 4: Peso objetivo si existe
        if (perfilData['pesoObjetivo'] != null && perfilData['pesoObjetivo'] > 0)
          Text(
            '🎯 Peso Objetivo: ${perfilData['pesoObjetivo']} kg',
            style: const TextStyle(fontSize: 14, color: Colors.blue),
          ),
        
        // Línea 5: Observaciones si existen
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
        
        // Línea 6: Fecha de registro
        const SizedBox(height: 10),
        Text(
          '📅 Fecha: ${_formatearFecha(perfilData['fechaRegistro'])}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // Función para formatear fecha
  String _formatearFecha(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
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
              
              // Medidas básicas
              _buildSeccionMedidas(),
              const SizedBox(height: 20),
              
              // Medidas corporales
              _buildSeccionMedidasCorporales(),
              const SizedBox(height: 20),
              
              // Observaciones
              _buildSeccionObservaciones(),
              const SizedBox(height: 20),
              
              // Botón guardar
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
    };

    try {
      await FirebaseFirestore.instance
          .collection('perfiles_fisicos')
          .add(perfilData);

      // Recargar el último perfil
      await _cargarUltimoPerfil();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil físico guardado exitosamente')),
      );

      // Limpiar campos después de guardar
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