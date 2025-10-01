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
                TextFormField(
                  controller: _celCtrl,
                  decoration: const InputDecoration(labelText: 'Celular'),
                  keyboardType: TextInputType.phone,
                ),
                DropdownButtonFormField<String>(
                  value: plan,
                  items: ["Plan Fijo", "Plan Libre"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => plan = v!),
                  decoration: const InputDecoration(labelText: "Plan"),
                ),
                DropdownButtonFormField<String>(
                  value: curso,
                  items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => curso = v!),
                  decoration: const InputDecoration(labelText: "Curso"),
                ),
                DropdownButtonFormField<String>(
                  value: turno,
                  items: ['Mañana', 'Tarde', 'Noche']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => turno = v!),
                  decoration: const InputDecoration(labelText: "Turno"),
                ),
                DropdownButtonFormField<String>(
                  value: promocion,
                  items: ['Ninguna', 'Promoción 1', 'Promoción 2']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => promocion = v!),
                  decoration: const InputDecoration(labelText: "Promoción"),
                ),
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto pagado'),
                  keyboardType: TextInputType.number,
                ),
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
                      'fecha_inicio': Timestamp.fromDate(fechaInicio),
                      'fecha_fin': Timestamp.fromDate(fechaFin),
                      'estado': estado,
                      'monto_pagado': monto,
                      'promocion': promocion,
                    };

                    await FirestoreService().updateAlumno(widget.alumnoId, updatedData);

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
}
