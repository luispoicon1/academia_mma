import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RenovarMensualidadScreen extends StatefulWidget {
  final String alumnoId;
  final Map<String, dynamic> alumnoData;

  const RenovarMensualidadScreen({
    super.key,
    required this.alumnoId,
    required this.alumnoData,
  });

  @override
  State<RenovarMensualidadScreen> createState() => _RenovarMensualidadScreenState();
}

class _RenovarMensualidadScreenState extends State<RenovarMensualidadScreen> {
  final _montoCtrl = TextEditingController();
  DateTime _fechaFin = DateTime.now().add(Duration(days: 30));
  String _metodoPago = 'Efectivo';
  String _concepto = 'Mensualidad';
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    // Pre-cargar datos del alumno
    _cargarDatosPrevios();
  }

  void _cargarDatosPrevios() {
    // Pre-cargar método de pago anterior si existe
    if (widget.alumnoData['metodo_pago'] != null) {
      _metodoPago = widget.alumnoData['metodo_pago'];
    }
    
    // Sugerir monto similar al anterior
    final montoAnterior = widget.alumnoData['monto_pagado'] ?? 0;
    if (montoAnterior > 0) {
      _montoCtrl.text = montoAnterior.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔄 Renovar Mensualidad'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _procesando
          ? const Center(child: CircularProgressIndicator())
          : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TARJETA INFORMACIÓN ALUMNO
          _buildInfoAlumno(),
          
          const SizedBox(height: 24),
          
          // FORMULARIO DE RENOVACIÓN
          _buildFormularioRenovacion(),
          
          const SizedBox(height: 30),
          
          // BOTÓN DE ACCIÓN
          _buildBotonRenovar(),
        ],
      ),
    );
  }

  Widget _buildInfoAlumno() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.alumnoData['nombre']} ${widget.alumnoData['apellido']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.alumnoData['curso']} • ${widget.alumnoData['dni']}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Celular: ${widget.alumnoData['celular'] ?? 'No registrado'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioRenovacion() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Datos de Renovación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // MONTO
            TextFormField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto de renovación *',
                prefixText: 'S/ ',
                border: OutlineInputBorder(),
                icon: Icon(Icons.attach_money, color: Colors.green),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Ingrese el monto';
                if (double.tryParse(value) == null) return 'Monto inválido';
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // FECHA DE VENCIMIENTO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de vencimiento *',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_fechaFin),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${_calcularDiasRestantes()} días',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _seleccionarFecha,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Cambiar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // MÉTODO DE PAGO
            DropdownButtonFormField(
              value: _metodoPago,
              items: ['Efectivo', 'Yape', 'Transferencia', 'Plin'].map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) => setState(() => _metodoPago = value!),
              decoration: const InputDecoration(
                labelText: 'Método de pago *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.payment, color: Colors.blue),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // CONCEPTO
            DropdownButtonFormField(
              value: _concepto,
              items: ['Mensualidad', 'Inscripción', 'Matrícula', 'Otros'].map((concept) {
                return DropdownMenuItem(
                  value: concept,
                  child: Text(concept),
                );
              }).toList(),
              onChanged: (value) => setState(() => _concepto = value!),
              decoration: const InputDecoration(
                labelText: 'Concepto *',
                border: OutlineInputBorder(),
                icon: Icon(Icons.description, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonRenovar() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _procesarRenovacion,
        icon: const Icon(Icons.autorenew),
        label: const Text(
          'CONFIRMAR RENOVACIÓN',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }

  String _calcularDiasRestantes() {
    final diferencia = _fechaFin.difference(DateTime.now()).inDays;
    return diferencia.toString();
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() => _fechaFin = fecha);
    }
  }

  Future<void> _procesarRenovacion() async {
    // Validaciones
    if (_montoCtrl.text.isEmpty) {
      _mostrarError('Ingrese el monto de renovación');
      return;
    }

    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      _mostrarError('Ingrese un monto válido mayor a 0');
      return;
    }

    setState(() => _procesando = true);

    try {
      // 1. ACTUALIZAR ALUMNO EN FIRESTORE
      await FirebaseFirestore.instance
          .collection('alumnos')
          .doc(widget.alumnoId)
          .update({
        'fecha_fin': Timestamp.fromDate(_fechaFin),
        'estado': 'Activo',
        'metodo_pago': _metodoPago,
        'monto_pagado': monto,
        'fecha_ultima_renovacion': Timestamp.now(),
      });

      // 2. REGISTRAR PAGO EN COLECCIÓN SEPARADA
      await FirebaseFirestore.instance.collection('pagos').add({
        'alumnoId': widget.alumnoId,
        'nombre': '${widget.alumnoData['nombre']} ${widget.alumnoData['apellido']}',
        'dni': widget.alumnoData['dni'],
        'monto': monto,
        'curso': widget.alumnoData['curso'],
        'metodo': _metodoPago,
        'tipo': 'renovacion',
        'concepto': _concepto,
        'fecha_pago': Timestamp.now(),
        'mes_correspondiente': DateFormat('MMMM yyyy').format(DateTime.now()),
        'fecha_vencimiento': Timestamp.fromDate(_fechaFin),
      });

      // 3. MOSTRAR CONFIRMACIÓN
      _mostrarExito();

    } catch (e) {
      _mostrarError('Error al procesar renovación: $e');
    } finally {
      setState(() => _procesando = false);
    }
  }

  void _mostrarExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Mensualidad renovada exitosamente'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Regresar después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $mensaje'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }
}