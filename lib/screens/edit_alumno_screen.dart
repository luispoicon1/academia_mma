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
  late TextEditingController _celCtrl;
  late TextEditingController _montoCtrl;

  String curso = '';
  String turno = '';
  String plan = '';
  String promocion = '';
  String metodoPago = 'Efectivo'; // NUEVO: Método de pago
  late DateTime fechaInicio;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.data['nombre']);
    _celCtrl = TextEditingController(text: widget.data['celular']);
    _montoCtrl = TextEditingController(text: widget.data['monto_pagado']?.toString() ?? '0');

    curso = widget.data['curso'] ?? 'MMA';
    turno = widget.data['turno'] ?? 'Mañana';
    plan = widget.data['plan'] ?? 'Plan Fijo';
    promocion = widget.data['promocion'] ?? 'Ninguna';
    metodoPago = widget.data['metodo_pago'] ?? 'Efectivo'; // NUEVO: Cargar método de pago existente
    fechaInicio = (widget.data['fecha_inicio'] as Timestamp).toDate();
  }

  @override
  Widget build(BuildContext context) {
    DateTime fechaFin = DateTime(fechaInicio.year, fechaInicio.month + 1, fechaInicio.day);

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Alumno')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                
                TextFormField(
                  controller: _celCtrl,
                  decoration: const InputDecoration(labelText: 'Celular'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 10),

                // NUEVO: Método de Pago
                DropdownButtonFormField<String>(
                  value: metodoPago,
                  items: ['Efectivo', 'Yape']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => metodoPago = v!),
                  decoration: const InputDecoration(labelText: "Método de Pago"),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: plan,
                  items: ["Plan Fijo", "Plan Libre"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => plan = v!),
                  decoration: const InputDecoration(labelText: "Plan"),
                ),
                const SizedBox(height: 10),
                
                DropdownButtonFormField<String>(
                  value: curso,
                  items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai", "Gym"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => curso = v!),
                  decoration: const InputDecoration(labelText: "Curso"),
                ),
                const SizedBox(height: 10),
                
                DropdownButtonFormField<String>(
                  value: turno,
                  items: ['Mañana', 'Tarde', 'Noche']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => turno = v!),
                  decoration: const InputDecoration(labelText: "Turno"),
                ),
                const SizedBox(height: 10),
                
                DropdownButtonFormField<String>(
                  value: promocion,
                  items: ['Ninguna', 'Promoción 1', 'Promoción 2']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => promocion = v!),
                  decoration: const InputDecoration(labelText: "Promoción"),
                ),
                const SizedBox(height: 10),
                
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto pagado'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                
                Row(
                  children: [
                    Text('Inicio: ${DateFormat('dd/MM/yyyy').format(fechaInicio)}'),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      child: const Text('Cambiar fecha'),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => fechaInicio = d);
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                Text('Fin (automático): ${DateFormat('dd/MM/yyyy').format(fechaFin)}'),
                
                const SizedBox(height: 20),
                ElevatedButton(
                  child: const Text('Guardar cambios'),
                  onPressed: () async {
                    final estado = FirestoreService.calcularEstado(fechaFin);
                    final monto = double.tryParse(_montoCtrl.text.trim()) ?? 0.0;
                    
                    final updatedData = {
                      'nombre': _nombreCtrl.text.trim(),
                      'curso': curso,
                      'turno': turno,
                      'plan': plan,
                      'celular': _celCtrl.text.trim(),
                      'metodo_pago': metodoPago, // NUEVO: Guardar método de pago
                      'fecha_inicio': Timestamp.fromDate(fechaInicio),
                      'fecha_fin': Timestamp.fromDate(fechaFin),
                      'estado': estado,
                      'monto_pagado': monto,
                      'promocion': promocion,
                    };

                    await FirestoreService().updateAlumno(widget.alumnoId, updatedData);

                    // NUEVO: Actualizar también en la colección de pagos si existe
                    await _actualizarPagoEnHistorial(updatedData);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alumno actualizado con éxito')),
                    );

                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // NUEVO: Función para actualizar el pago en la colección de pagos
  Future<void> _actualizarPagoEnHistorial(Map<String, dynamic> updatedData) async {
    try {
      // Buscar el pago correspondiente a este alumno
      final pagosSnapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('nombre', isEqualTo: '${widget.data['nombre']} ${widget.data['apellido'] ?? ''}')
          .where('tipo', isEqualTo: 'inscripcion')
          .get();

      if (pagosSnapshot.docs.isNotEmpty) {
        // Actualizar el pago existente
        final pagoDoc = pagosSnapshot.docs.first;
        await pagoDoc.reference.update({
          'nombre': '${updatedData['nombre']} ${widget.data['apellido'] ?? ''}',
          'monto': updatedData['monto_pagado'],
          'curso': updatedData['curso'],
          'metodo': updatedData['metodo_pago'],
        });
      }
    } catch (e) {
      print('Error actualizando pago en historial: $e');
      // No mostrar error al usuario, es opcional
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _celCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }
}