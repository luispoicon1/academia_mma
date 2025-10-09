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
  final _conceptoController = TextEditingController();
  String metodo = "Efectivo";
  String tipoPago = "Mensualidad"; // Nuevo campo
  DateTime fechaPago = DateTime.now();
  bool _isLoading = false;

  // Método para seleccionar fecha
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fechaPago,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != fechaPago) {
      setState(() {
        fechaPago = picked;
      });
    }
  }

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
              // Información del alumno
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Alumno: ${widget.nombre}", 
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Curso: ${widget.curso}"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de pago
              DropdownButtonFormField(
                value: tipoPago,
                items: ["Mensualidad", "Inscripción", "Otro"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => tipoPago = val!),
                decoration: const InputDecoration(labelText: "Tipo de pago"),
              ),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Monto (S/)",
                  prefixText: "S/ ",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Ingrese un monto";
                  final monto = double.tryParse(v);
                  if (monto == null || monto <= 0) {
                    return "Ingrese un monto válido mayor a 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de pago
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Fecha de pago",
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${fechaPago.day}/${fechaPago.month}/${fechaPago.year}"),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Método de pago
              DropdownButtonFormField(
                value: metodo,
                items: ["Efectivo", "Yape", "Plin", "Tarjeta", "Transferencia"]
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => metodo = val!),
                decoration: const InputDecoration(labelText: "Método de pago"),
              ),
              const SizedBox(height: 16),

              // Concepto
              TextFormField(
                controller: _conceptoController,
                decoration: const InputDecoration(
                  labelText: "Concepto (opcional)",
                  hintText: "Ej: Mensualidad marzo, Matrícula, etc.",
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarPago,
                  child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Guardar Pago"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarPago() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        // Determinar el tipo para el vencimiento
        final tipo = tipoPago == "Inscripción" ? "inscripcion" : "mensualidad";
        final concepto = _conceptoController.text.isEmpty 
            ? tipoPago 
            : _conceptoController.text;

        await FirestoreService().addPago({
          'alumnoId': widget.alumnoId,
          'nombre': widget.nombre,
          'curso': widget.curso,
          'monto': double.parse(_montoController.text),
          'metodo': metodo,
          'tipo': tipo,
          'concepto': concepto,
          'fecha': fechaPago, // Para calcular vencimiento
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Pago registrado exitosamente")),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error al registrar pago: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _conceptoController.dispose();
    super.dispose();
  }
}