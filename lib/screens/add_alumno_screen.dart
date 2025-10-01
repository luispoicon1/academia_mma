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
  final _celCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
final _dniCtrl = TextEditingController();
final _correoCtrl = TextEditingController();


  String curso = 'MMA';
  String turno = 'Mañana';
  String plan = 'Plan Fijo';
  String promocion = 'Ninguna';
  DateTime fechaInicio = DateTime.now();

  @override
  Widget build(BuildContext context) {
    DateTime fechaFin =
        DateTime(fechaInicio.year, fechaInicio.month + 1, fechaInicio.day);

    return Scaffold(
      appBar: AppBar(title: const Text('')),
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
                  items: ["Plan Fijo", "Plan Libre"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => plan = v!),
                  decoration: const InputDecoration(labelText: "Plan"),
                ),
                DropdownButtonFormField<String>(
                  value: curso,
                  items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai","Gym"]
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
                const SizedBox(height: 10),
                Text('Fin (automático): ${DateFormat('dd/MM/yyyy').format(fechaFin)}'),
                const SizedBox(height: 20),
                ElevatedButton(
  child: const Text('Guardar'),
  onPressed: () async {
    final estado = FirestoreService.calcularEstado(fechaFin);
    final monto = double.tryParse(_montoCtrl.text) ?? 0;

    final data = {
      'nombre': _nombreCtrl.text.trim(),
      'apellido': _apellidoCtrl.text.trim(),
      'correo': _correoCtrl.text.trim(),
      'dni': _dniCtrl.text.trim(),
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

    // ✅ Guardar en Firestore
    await FirestoreService().addAlumno(data);

    // ✅ Mostrar boleta inmediatamente
    await PdfService.generarBoleta(
      context: context,
      nombre: _nombreCtrl.text.trim(),
      curso: curso,
      plan: plan,
      monto: monto,
      fecha: DateTime.now(),
    );

    // ✅ Mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alumno registrado con éxito')),
    );

    // ✅ Limpiar campos
    _nombreCtrl.clear();
    _celCtrl.clear();
    _montoCtrl.clear();
    setState(() {
      curso = 'MMA';
      plan = 'Plan Fijo';
      turno = 'Mañana';
      promocion = 'Ninguna';
      fechaInicio = DateTime.now();
    });
  },
),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
