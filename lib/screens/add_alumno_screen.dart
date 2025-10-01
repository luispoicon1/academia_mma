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
<<<<<<< HEAD
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
=======
  final _celCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
final _dniCtrl = TextEditingController();
final _correoCtrl = TextEditingController();

>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f

  String curso = 'MMA';
  String turno = 'Mañana';
  String plan = 'Plan Fijo';
  String promocion = 'Ninguna';
  DateTime fechaInicio = DateTime.now();
<<<<<<< HEAD
  bool _esMenorEdad = false;
=======
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f

  @override
  Widget build(BuildContext context) {
    DateTime fechaFin =
        DateTime(fechaInicio.year, fechaInicio.month + 1, fechaInicio.day);

    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(title: const Text('Agregar Alumno')),
=======
      appBar: AppBar(title: const Text('')),
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
<<<<<<< HEAD
                // Campo Nombre
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                
                // Campo Apellido
                TextFormField(
                  controller: _apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                
                // Campo Edad
                TextFormField(
                  controller: _edadCtrl,
                  decoration: const InputDecoration(labelText: 'Edad *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final edad = int.tryParse(value) ?? 0;
                    setState(() {
                      _esMenorEdad = edad < 18;
                    });
                  },
                ),
                const SizedBox(height: 10),
                
                // Campo DNI
                TextFormField(
                  controller: _dniCtrl,
                  decoration: const InputDecoration(labelText: 'DNI *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                
                // Campo Correo
                TextFormField(
                  controller: _correoCtrl,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                
                // Campo Celular
                TextFormField(
                  controller: _celCtrl,
                  decoration: const InputDecoration(labelText: 'Celular *'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                
                // Campo Dirección
                TextFormField(
                  controller: _direccionCtrl,
                  decoration: const InputDecoration(labelText: 'Dirección *'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // Campos para menores de edad
                if (_esMenorEdad) ...[
                  const SizedBox(height: 20),
                  const Text('Datos del Apoderado (Menor de edad)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _apoderadoCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del Apoderado *'),
                    validator: (value) {
                      if (_esMenorEdad && (value == null || value.isEmpty)) {
                        return 'Campo obligatorio para menores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _dniApoderadoCtrl,
                    decoration: const InputDecoration(labelText: 'DNI del Apoderado *'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (_esMenorEdad && (value == null || value.isEmpty)) {
                        return 'Campo obligatorio para menores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  
                  TextFormField(
                    controller: _celApoderadoCtrl,
                    decoration: const InputDecoration(labelText: 'Celular del Apoderado *'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (_esMenorEdad && (value == null || value.isEmpty)) {
                        return 'Campo obligatorio para menores';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Campos existentes
=======
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextFormField(
                  controller: _celCtrl,
                  decoration: const InputDecoration(labelText: 'Celular'),
                  keyboardType: TextInputType.phone,
                ),
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
                DropdownButtonFormField<String>(
                  value: plan,
                  items: ["Plan Fijo", "Plan Libre"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => plan = v!),
                  decoration: const InputDecoration(labelText: "Plan"),
                ),
<<<<<<< HEAD
                const SizedBox(height: 10),
                
=======
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
                DropdownButtonFormField<String>(
                  value: curso,
                  items: ["MMA", "Box", "Sanda", "Jiu Jitsu", "Muay Thai","Gym"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => curso = v!),
                  decoration: const InputDecoration(labelText: "Curso"),
                ),
<<<<<<< HEAD
                const SizedBox(height: 10),
                
=======
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
                DropdownButtonFormField<String>(
                  value: turno,
                  items: ['Mañana', 'Tarde', 'Noche']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => turno = v!),
                  decoration: const InputDecoration(labelText: "Turno"),
                ),
<<<<<<< HEAD
                const SizedBox(height: 10),
                
=======
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
                DropdownButtonFormField<String>(
                  value: promocion,
                  items: ['Ninguna', 'Promoción 1', 'Promoción 2']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => promocion = v!),
                  decoration: const InputDecoration(labelText: "Promoción"),
                ),
<<<<<<< HEAD
                const SizedBox(height: 10),
                
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto pagado *'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                
=======
                TextFormField(
                  controller: _montoCtrl,
                  decoration: const InputDecoration(labelText: 'Monto pagado'),
                  keyboardType: TextInputType.number,
                ),
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
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
<<<<<<< HEAD
                
                Text('Fin (automático): ${DateFormat('dd/MM/yyyy').format(fechaFin)}'),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  child: const Text('Guardar Alumno'),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

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
                      'fecha_inicio': Timestamp.fromDate(fechaInicio),
                      'fecha_fin': Timestamp.fromDate(fechaFin),
                      'estado': estado,
                      'monto_pagado': monto,
                      'promocion': promocion,
                      'fecha_registro': Timestamp.now(),
                    };

                    // ✅ Guardar en Firestore
                    await FirestoreService().addAlumno(data);

                    // ✅ Mostrar boleta inmediatamente
                    // Reemplaza esta parte en el onPressed del botón Guardar:
await PdfService.generarBoleta(
  context: context,
  nombre: _nombreCtrl.text.trim(),
  apellido: _apellidoCtrl.text.trim(),
  edad: int.tryParse(_edadCtrl.text) ?? 0,
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
  fecha: DateTime.now(),
);

                    // ✅ Mensaje de éxito
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Alumno registrado con éxito')),
                    );

                    // ✅ Limpiar campos
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
                      fechaInicio = DateTime.now();
                      _esMenorEdad = false;
                    });
                  },
                ),
=======
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


>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
              ],
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> c57bfee923dfd2b71ffb2fe65f79c159964dbf4f
