import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AddPagoScreen extends StatefulWidget {
  final String alumnoId;
  final String nombre;
  final String curso;

  const AddPagoScreen({
    super.key,
    required this.alumnoId,
    required this.nombre,
    required this.curso,
  });

  @override
  State<AddPagoScreen> createState() => _AddPagoScreenState();
}

class _AddPagoScreenState extends State<AddPagoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  String metodo = "Efectivo";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Pago")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Alumno: ${widget.nombre}"),
              Text("Curso: ${widget.curso}"),
              const SizedBox(height: 16),

              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Monto (S/)"),
                validator: (v) =>
                    v!.isEmpty ? "Ingrese un monto válido" : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField(
                value: metodo,
                items: ["Efectivo", "Yape", "Plin", "Tarjeta"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => metodo = val!),
                decoration: const InputDecoration(labelText: "Método de pago"),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await FirestoreService().addPago({
                      'alumnoId': widget.alumnoId,
                      'nombre': widget.nombre,
                      'curso': widget.curso,
                      'monto': double.parse(_montoController.text),
                      'metodo': metodo,
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text("Guardar Pago"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
