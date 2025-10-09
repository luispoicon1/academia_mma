import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class EditAlumnoScreen extends StatefulWidget {
  final String alumnoId;
  final Map<String, dynamic> data;

  const EditAlumnoScreen({super.key, required this.alumnoId, required this.data});

  @override
  State<EditAlumnoScreen> createState() => _EditAlumnoScreenState();
}

class _EditAlumnoScreenState extends State<EditAlumnoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidoCtrl;
  late TextEditingController _celCtrl;
  late TextEditingController _montoCtrl;
  late TextEditingController _edadCtrl;
  late TextEditingController _dniCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _direccionCtrl;

  String curso = '';
  String turno = '';
  String plan = '';
  String promocion = '';
  String metodoPago = 'Efectivo';
  late DateTime fechaInicio;
  late DateTime fechaFin; // Fecha fin manual
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.data['nombre']);
    _apellidoCtrl = TextEditingController(text: widget.data['apellido'] ?? '');
    _celCtrl = TextEditingController(text: widget.data['celular']);
    _montoCtrl = TextEditingController(text: widget.data['monto_pagado']?.toString() ?? '0');
    _edadCtrl = TextEditingController(text: widget.data['edad']?.toString() ?? '');
    _dniCtrl = TextEditingController(text: widget.data['dni'] ?? '');
    _correoCtrl = TextEditingController(text: widget.data['correo'] ?? '');
    _direccionCtrl = TextEditingController(text: widget.data['direccion'] ?? '');

    curso = widget.data['curso'] ?? 'MMA';
    turno = widget.data['turno'] ?? 'Mañana';
    plan = widget.data['plan'] ?? 'Plan Fijo';
    promocion = widget.data['promocion'] ?? 'Ninguna';
    metodoPago = widget.data['metodo_pago'] ?? 'Efectivo';
    fechaInicio = (widget.data['fecha_inicio'] as Timestamp).toDate();
    
    // ✅ CARGAR FECHA FIN DESDE LOS DATOS (si existe), si no, calcular automático
    if (widget.data['fecha_fin'] != null) {
      fechaFin = (widget.data['fecha_fin'] as Timestamp).toDate();
    } else {
      fechaFin = DateTime(fechaInicio.year, fechaInicio.month + 1, fechaInicio.day);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Editar Alumno'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.edit, size: 40, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        'Editando: ${widget.data['nombre']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Actualiza la información del alumno',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Información Personal
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
                            label: 'Apellido',
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
                            label: 'Edad',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: _buildTextField(
                            controller: _dniCtrl,
                            label: 'DNI',
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
                      label: 'Dirección',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Información del Curso
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
                            icon: Icons.assignment,
                            onChanged: (v) => setState(() => plan = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            value: curso,
                            items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai", "Gym"],
                            label: "Curso",
                            icon: Icons.school,
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
                            icon: Icons.access_time,
                            onChanged: (v) => setState(() => turno = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            value: promocion,
                            items: ['Ninguna', 'Promoción 1', 'Promoción 2'],
                            label: "Promoción",
                            icon: Icons.local_offer,
                            onChanged: (v) => setState(() => promocion = v!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Información de Pago
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
                            icon: Icons.payment,
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
                    
                    // ✅ FECHA DE FIN MANUAL (ACTUALIZADA)
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
                                firstDate: fechaInicio, // No permite fechas antes del inicio
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

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 56,
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
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'GUARDAR CAMBIOS',
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
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
            offset: const Offset(0, 2),
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
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) {
          return 'Campo obligatorio';
        }
        return null;
      } : null,
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 14)),
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
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
      ),
      icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ VALIDAR QUE FECHA FIN NO SEA ANTERIOR A FECHA INICIO
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
      // ✅ USAR LA FECHA DE FIN MANUAL
      final estado = FirestoreService.calcularEstado(fechaFin);
      final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
      final edad = int.tryParse(_edadCtrl.text.trim()) ?? 0;

      final updatedData = {
        'nombre': _nombreCtrl.text.trim(),
        'apellido': _apellidoCtrl.text.trim(),
        'edad': edad,
        'dni': _dniCtrl.text.trim(),
        'correo': _correoCtrl.text.trim(),
        'celular': _celCtrl.text.trim(),
        'direccion': _direccionCtrl.text.trim(),
        'curso': curso,
        'turno': turno,
        'plan': plan,
        'metodo_pago': metodoPago,
        'fecha_inicio': Timestamp.fromDate(fechaInicio),
        'fecha_fin': Timestamp.fromDate(fechaFin), // ✅ FECHA MANUAL
        'estado': estado,
        'monto_pagado': monto,
        'promocion': promocion,
      };

      await FirestoreService().updateAlumno(widget.alumnoId, updatedData);

      // Actualizar también en la colección de pagos si existe
      await _actualizarPagoEnHistorial(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Alumno actualizado con éxito'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {
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

  Future<void> _actualizarPagoEnHistorial(Map<String, dynamic> updatedData) async {
    try {
      final pagosSnapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('nombre', isEqualTo: '${widget.data['nombre']} ${widget.data['apellido'] ?? ''}')
          .where('tipo', isEqualTo: 'inscripcion')
          .get();

      if (pagosSnapshot.docs.isNotEmpty) {
        final pagoDoc = pagosSnapshot.docs.first;
        await pagoDoc.reference.update({
          'nombre': '${updatedData['nombre']} ${updatedData['apellido'] ?? ''}',
          'monto': updatedData['monto_pagado'],
          'curso': updatedData['curso'],
          'metodo': updatedData['metodo_pago'],
        });
      }
    } catch (e) {
      print('Error actualizando pago en historial: $e');
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _celCtrl.dispose();
    _montoCtrl.dispose();
    _edadCtrl.dispose();
    _dniCtrl.dispose();
    _correoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }
}