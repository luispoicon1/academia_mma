import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/pdf_service.dart';

class AddAlumnoScreen extends StatefulWidget {
  const AddAlumnoScreen({super.key});
  @override
  State<AddAlumnoScreen> createState() => _AddAlumnoScreenState();
}

class _AddAlumnoScreenState extends State<AddAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();
  final _celCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _apoderadoCtrl = TextEditingController();
  final _dniApoderadoCtrl = TextEditingController();
  final _celApoderadoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();

  String curso = 'MMA';
  String turno = 'Mañana';
  String plan = 'Plan Fijo';
  String promocion = 'Ninguna';
  String metodoPago = 'Efectivo';
  DateTime fechaInicio = DateTime.now();
  DateTime fechaFin = DateTime.now().add(Duration(days: 30)); // Fecha fin manual
  bool _esMenorEdad = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10, left: 10, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botón de retroceso
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  const Text(
                    'Nuevo Alumno',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete todos los campos obligatorios (*) para registrar al alumno',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Formulario
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Sección 1: Información Personal
                  _buildSection(
                    title: 'Información Personal',
                    icon: Icons.person_outline,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _nombreCtrl,
                              label: 'Nombre *',
                              icon: Icons.badge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _apellidoCtrl,
                              label: 'Apellido *',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _edadCtrl,
                              label: 'Edad *',
                              icon: Icons.cake,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final edad = int.tryParse(value) ?? 0;
                                setState(() {
                                  _esMenorEdad = edad < 18;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: _buildTextField(
                              controller: _dniCtrl,
                              label: 'DNI *',
                              icon: Icons.credit_card,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _correoCtrl,
                        label: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _celCtrl,
                        label: 'Celular *',
                        icon: Icons.phone_iphone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _direccionCtrl,
                        label: 'Dirección *',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sección 2: Datos del Apoderado (condicional)
                  if (_esMenorEdad) 
                    _buildSection(
                      title: 'Datos del Apoderado (Menor de Edad)',
                      icon: Icons.family_restroom,
                      color: Colors.orange.shade50,
                      children: [
                        _buildTextField(
                          controller: _apoderadoCtrl,
                          label: 'Nombre del Apoderado *',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _dniApoderadoCtrl,
                                label: 'DNI del Apoderado *',
                                icon: Icons.credit_card,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _celApoderadoCtrl,
                                label: 'Celular del Apoderado *',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  if (_esMenorEdad) const SizedBox(height: 20),

                  // Sección 3: Información del Curso
                  _buildSection(
                    title: 'Información del Curso',
                    icon: Icons.sports_martial_arts,
                    color: Colors.green.shade50,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: plan,
                              items: ["Plan Fijo", "Plan Libre"],
                              label: "Plan",
                              onChanged: (v) => setState(() => plan = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              value: curso,
                              items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai", "Gym"],
                              label: "Curso",
                              onChanged: (v) => setState(() => curso = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: turno,
                              items: ['Mañana', 'Tarde', 'Noche'],
                              label: "Turno",
                              onChanged: (v) => setState(() => turno = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              value: promocion,
                              items: ['Ninguna', 'Promoción 1', 'Promoción 2'],
                              label: "Promoción",
                              onChanged: (v) => setState(() => promocion = v!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sección 4: Información de Pago
                  _buildSection(
                    title: 'Información de Pago',
                    icon: Icons.payments_outlined,
                    color: Colors.purple.shade50,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              value: metodoPago,
                              items: ['Efectivo', 'Yape'],
                              label: "Método de Pago",
                              onChanged: (v) => setState(() => metodoPago = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _montoCtrl,
                              label: 'Monto Pagado *',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // FECHA DE INICIO
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Inicio',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(fechaInicio),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: fechaInicio,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) setState(() => fechaInicio = d);
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: const Text('Cambiar'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // FECHA DE FIN MANUAL
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de Fin *',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(fechaFin),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Selecciona manualmente',
                                  style: TextStyle(
                                    color: Colors.orange.shade600,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: fechaFin,
                                  firstDate: fechaInicio,
                                  lastDate: DateTime(2100),
                                );
                                if (d != null) setState(() => fechaFin = d);
                              },
                              icon: const Icon(Icons.calendar_today, size: 16),
                              label: const Text('Seleccionar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Botón de Guardar
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade300,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_alt, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  'GUARDAR ALUMNO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.blue.shade700, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'Campo obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: TextStyle(fontSize: 14)),
              ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
    );
  }

  Future<void> _submitForm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (fechaFin.isBefore(fechaInicio)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ La fecha de fin no puede ser anterior a la fecha de inicio'),
        backgroundColor: Colors.red.shade600,
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final estado = FirestoreService.calcularEstado(fechaFin);
    final monto = double.tryParse(_montoCtrl.text) ?? 0;
    final edad = int.tryParse(_edadCtrl.text) ?? 0;

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'edad': edad,
      'dni': _dniCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'celular': _celCtrl.text.trim(),
      'direccion': _direccionCtrl.text.trim(),
      'es_menor_edad': _esMenorEdad,
      'apoderado': _esMenorEdad ? _apoderadoCtrl.text.trim() : '',
      'dni_apoderado': _esMenorEdad ? _dniApoderadoCtrl.text.trim() : '',
      'celular_apoderado': _esMenorEdad ? _celApoderadoCtrl.text.trim() : '',
      'curso': curso,
      'turno': turno,
      'plan': plan,
      'metodo_pago': metodoPago,
      'fecha_inicio': Timestamp.fromDate(fechaInicio),
      'fecha_fin': Timestamp.fromDate(fechaFin),
      'estado': estado,
      'monto_pagado': monto,
      'promocion': promocion,
      'fecha_registro': Timestamp.now(),
    };

    // 🔥 PRIMERO: Guardar alumno
    DocumentReference alumnoRef = await FirebaseFirestore.instance
        .collection('alumnos')
        .add(data);
    
    final alumnoId = alumnoRef.id;
    print('✅ Alumno creado con ID: $alumnoId');

    // 🔥 SEGUNDO: Guardar en historial
    await FirebaseFirestore.instance.collection('Publicaciones').add({
      ...data,
      'alumnoId': alumnoId,
      'fecha_registro': Timestamp.now(),
    });

    // 🔥 TERCERO: Registrar pago CON EL alumnoId
    await FirestoreService().addPago({
      'alumnoId': alumnoId, // ✅ ESTA ES LA CLAVE
      'nombre': '${_nombreCtrl.text.trim()} ${_apellidoCtrl.text.trim()}',
      'monto': monto,
      'curso': curso,
      'metodo': metodoPago,
      'tipo': 'inscripcion',
      'concepto': 'Inscripción',
      'dni': _dniCtrl.text.trim(), // ✅ Para referencia
    });

    // Mostrar boleta
    await PdfService.generarBoleta(
      context: context,
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      edad: edad,
      dni: _dniCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      celular: _celCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      esMenorEdad: _esMenorEdad,
      apoderado: _esMenorEdad ? _apoderadoCtrl.text.trim() : '',
      dniApoderado: _esMenorEdad ? _dniApoderadoCtrl.text.trim() : '',
      celularApoderado: _esMenorEdad ? _celApoderadoCtrl.text.trim() : '',
      curso: curso,
      plan: plan,
      turno: turno,
      promocion: promocion,
      monto: monto,
      metodoPago: metodoPago,
      fecha: DateTime.now(),
    );

    // Mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Alumno registrado con éxito'),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // Limpiar campos
    _resetForm();

  } catch (e) {
    print('❌ Error completo: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error: $e'),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  void _resetForm() {
    _nombreCtrl.clear();
    _apellidoCtrl.clear();
    _edadCtrl.clear();
    _dniCtrl.clear();
    _correoCtrl.clear();
    _celCtrl.clear();
    _direccionCtrl.clear();
    _apoderadoCtrl.clear();
    _dniApoderadoCtrl.clear();
    _celApoderadoCtrl.clear();
    _montoCtrl.clear();
    
    setState(() {
      curso = 'MMA';
      plan = 'Plan Fijo';
      turno = 'Mañana';
      promocion = 'Ninguna';
      metodoPago = 'Efectivo';
      fechaInicio = DateTime.now();
      fechaFin = DateTime.now().add(Duration(days: 30)); // Reset a 30 días
      _esMenorEdad = false;
    });
  }

  // Función para registrar pago en colección separada
//Future<void> _registrarPagoSeparado({
  //required String nombre,
 // required double monto,
  //required String curso,
  //required String metodo,
//}) async {
  //await FirestoreService().addPago({
    //'nombre': nombre,
    //'monto': monto,
    //'curso': curso,
    //'metodo': metodo,
    //'tipo': 'inscripcion', // Esto evita que tenga vencimiento
    //'concepto': 'Inscripción',
 // });
//}

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _edadCtrl.dispose();
    _celCtrl.dispose();
    _montoCtrl.dispose();
    _dniCtrl.dispose();
    _correoCtrl.dispose();
    _apoderadoCtrl.dispose();
    _dniApoderadoCtrl.dispose();
    _celApoderadoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }
}