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

  // Widget para mostrar el último perfil guardado
  Widget _buildUltimoPerfil() {
    final data = _ultimoPerfil!;
    final fecha = (data['fechaRegistro'] as Timestamp).toDate();
    final peso = data['peso'] ?? 0;
    final altura = data['altura'] ?? 0;
    final imc = peso / ((altura / 100) * (altura / 100));

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Último Registro',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Spacer(),
                Text(
                  '${fecha.day}/${fecha.month}/${fecha.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Medidas básicas
            _buildLineaMedida('⚖️ Peso', '$peso kg'),
            _buildLineaMedida('📏 Altura', '$altura cm'),
            _buildLineaMedida('🧮 IMC', '${imc.toStringAsFixed(1)} (${_categoriaIMC(imc)})'),
            
            // Medidas corporales si existen
            if (data['cintura'] != null && data['cintura'] > 0)
              _buildLineaMedida('📐 Cintura', '${data['cintura']} cm'),
            if (data['pecho'] != null && data['pecho'] > 0)
              _buildLineaMedida('💪 Pecho', '${data['pecho']} cm'),
            if (data['espalda'] != null && data['espalda'] > 0)
              _buildLineaMedida('🔙 Espalda', '${data['espalda']} cm'),
            if (data['hombros'] != null && data['hombros'] > 0)
              _buildLineaMedida('👤 Hombros', '${data['hombros']} cm'),
            
            // Observaciones si existen
            if (data['observaciones'] != null && data['observaciones'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    '📝 Observaciones:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(data['observaciones']),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineaMedida(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Text(valor),
        ],
      ),
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