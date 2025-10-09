import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/alumno_auth_service.dart';
import '../services/user_type_service.dart';
import '../services/alumno_firestore_service.dart';
import '../models/niveles_model.dart';
import 'alumno_pagos_screen.dart';
import 'alumno_perfil_screen.dart';

class AlumnoDashboardScreen extends StatefulWidget {
  const AlumnoDashboardScreen({super.key});

  @override
  State<AlumnoDashboardScreen> createState() => _AlumnoDashboardScreenState();
}

class _AlumnoDashboardScreenState extends State<AlumnoDashboardScreen> {
  final _alumnoAuthService = AlumnoAuthService();
  final _alumnoFirestoreService = AlumnoFirestoreService();
  Map<String, dynamic> _alumnoData = {};
  NivelAlumno? _nivelAlumno;
  List<Map<String, dynamic>> _ultimosPagos = [];
  Map<String, dynamic>? _perfilFisico;
  bool _cargando = true;
  double _deudaTotal = 0.0;
  bool _tienePagosPendientes = false;
  String _estadoMembresia = '';
  Color _colorEstado = Colors.grey;
  DateTime? _fechaVencimiento;

  // Colores del tema
  final Color _primaryColor = Color(0xFF6366F1);
  final Color _secondaryColor = Color(0xFF8B5CF6);
  final Color _successColor = Color(0xFF10B981);
  final Color _warningColor = Color(0xFFF59E0B);
  final Color _errorColor = Color(0xFFEF4444);
  final Color _backgroundColor = Color(0xFFF8FAFC);
  final Color _surfaceColor = Colors.white;
  final Color _textPrimary = Color(0xFF1E293B);
  final Color _textSecondary = Color(0xFF64748B);

  Color _obtenerColorNivel(String nivel) {
    switch (nivel.toLowerCase()) {
      case 'blanco': return Colors.grey[300]!;
      case 'azul': return Colors.blue;
      case 'morado': return Colors.purple;
      case 'marrón': return Colors.brown;
      case 'negro': return Colors.black;
      case 'amarillo': return Color(0xFFF59E0B);
      case 'verde': return _successColor;
      case 'rojo': return _errorColor;
      case 'principiante': return _successColor;
      case 'intermedio': return _warningColor;
      case 'avanzado': return _errorColor;
      case 'amateur': return Colors.blue;
      case 'semi-profesional': return _warningColor;
      case 'profesional': return _errorColor;
      default: return _primaryColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarDatosAlumno();
  }

  Future<void> _cargarDatosAlumno() async {
    try {
      final datos = await UserTypeService.getDatosAlumno();
      setState(() {
        _alumnoData = Map<String, dynamic>.from(datos);
      });

      if (datos['id'] != null) {
        await _cargarDatosCompletosAlumno(datos['dni']);
        final niveles = await _alumnoFirestoreService.obtenerNivelesAlumno(datos['id']!);
        final pagos = await _cargarPagosAlumno(datos['nombre'], datos['curso']);
        final perfil = await _alumnoFirestoreService.obtenerPerfilFisico(datos['id']!);
        
        await _calcularEstadoMembresia();
        
        setState(() {
          _nivelAlumno = niveles;
          _ultimosPagos = pagos;
          _perfilFisico = perfil;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarDatosCompletosAlumno(String? dni) async {
    try {
      if (dni != null) {
        final alumnoSnapshot = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('dni', isEqualTo: dni)
            .limit(1)
            .get();
        
        if (alumnoSnapshot.docs.isNotEmpty) {
          final alumnoData = alumnoSnapshot.docs.first.data();
          setState(() {
            _alumnoData.addAll(alumnoData);
          });
        }
      }
    } catch (e) {
      print('Error cargando datos completos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _cargarPagosAlumno(String? miNombre, String? miCurso) async {
    try {
      List<Map<String, dynamic>> pagos = [];

      if (miCurso != null && miNombre != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('pagos')
            .where('curso', isEqualTo: miCurso)
            .get();

        final misPagos = querySnapshot.docs.where((doc) {
          final data = doc.data();
          final nombrePago = data['nombre']?.toString().toLowerCase() ?? '';
          final nombreAlumno = miNombre.toString().toLowerCase();
          
          final nombresAlumno = nombreAlumno.split(' ');
          return nombresAlumno.any((nombre) => nombrePago.contains(nombre));
        }).toList();

        pagos = misPagos.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();

        _deudaTotal = pagos
            .where((pago) => pago['estado'] == 'pendiente')
            .fold(0.0, (sum, pago) => sum + (pago['monto'] ?? 0.0));
        
        _tienePagosPendientes = pagos.any((pago) => pago['estado'] == 'pendiente');
      }

      return pagos;
    } catch (e) {
      print('❌ Error cargando pagos: $e');
      return [];
    }
  }

  Future<void> _calcularEstadoMembresia() async {
    final fechaFin = _alumnoData['fecha_fin'];
    
    if (fechaFin == null) {
      _estadoMembresia = 'Sin fecha de vencimiento';
      _colorEstado = _textSecondary;
      return;
    }

    DateTime? fechaVencimiento;
    
    try {
      if (fechaFin is Timestamp) {
        fechaVencimiento = fechaFin.toDate();
      } else if (fechaFin is DateTime) {
        fechaVencimiento = fechaFin;
      } else if (fechaFin is String) {
        fechaVencimiento = DateTime.tryParse(fechaFin);
        
        if (fechaVencimiento == null) {
          try {
            fechaVencimiento = DateFormat('dd/MM/yyyy').parse(fechaFin);
          } catch (e) {
            try {
              fechaVencimiento = DateFormat('yyyy-MM-dd').parse(fechaFin);
            } catch (e) {
              print('❌ No se pudo parsear la fecha: $fechaFin');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error procesando fecha: $e');
    }

    if (fechaVencimiento == null) {
      _estadoMembresia = 'Fecha inválida';
      _colorEstado = _textSecondary;
      return;
    }

    _fechaVencimiento = fechaVencimiento;
    final ahora = DateTime.now();
    final diasRestantes = fechaVencimiento.difference(ahora).inDays;

    if (diasRestantes < 0) {
      _estadoMembresia = 'VENCIDO';
      _colorEstado = _errorColor;
    } else if (diasRestantes <= 3) {
      _estadoMembresia = 'VENCE PRONTO';
      _colorEstado = _errorColor;
    } else if (diasRestantes <= 7) {
      _estadoMembresia = 'VENCE EN $diasRestantes DÍAS';
      _colorEstado = _warningColor;
    } else {
      _estadoMembresia = 'VIGENTE';
      _colorEstado = _successColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('TIGRE AZUL', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 20,
          )),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _cargando
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primaryColor),
              ),
            )
          : _buildContenido(isMobile),
    );
  }

  Widget _buildContenido(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          _buildHeader(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildAlertaMembresia(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
        
          SizedBox(height: isMobile ? 20 : 24),
          if (!isMobile) _buildDesktopLayout() else _buildMobileLayout(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildSeccionPerfilFisico(false),
              SizedBox(height: 24),
              _buildSeccionNiveles(false),
            ],
          ),
        ),
        SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildSeccionPagos(false),
              SizedBox(height: 24),
              _buildAccesosRapidos(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildSeccionPerfilFisico(true),
        SizedBox(height: 20),
        _buildSeccionNiveles(true),
        SizedBox(height: 20),
        _buildSeccionPagos(true),
        SizedBox(height: 20),
        _buildAccesosRapidos(true),
      ],
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _secondaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 60 : 80,
            height: isMobile ? 60 : 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, 
              size: isMobile ? 30 : 40, 
              color: Colors.white
            ),
          ),
          SizedBox(width: isMobile ? 16 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _alumnoData['nombre']?.toString() ?? 'Alumno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'DNI: ${_alumnoData['dni']?.toString() ?? 'No disponible'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8), 
                    fontSize: isMobile ? 14 : 16
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Curso: ${_alumnoData['curso']?.toString() ?? 'No asignado'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8), 
                    fontSize: isMobile ? 14 : 16
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaMembresia(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _colorEstado.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _colorEstado.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _colorEstado == _errorColor ? Icons.warning_rounded : 
              _colorEstado == _warningColor ? Icons.info_outline_rounded : 
              Icons.check_circle_rounded,
              color: _colorEstado,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _estadoMembresia,
                  style: TextStyle(
                    color: _colorEstado,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 16 : 18,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Plan ${_alumnoData['plan']?.toString() ?? 'No especificado'} • Vence ${_fechaVencimiento != null ? _formatearFecha(_fechaVencimiento!) : 'No definido'}',
                  style: TextStyle(
                    color: _textSecondary, 
                    fontSize: isMobile ? 13 : 14
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaMetrica(String titulo, String valor, IconData icono, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: isMobile ? 20 : 24),
              ),
              Spacer(),
              if (titulo == 'Por Pagar' && _deudaTotal > 0)
                Icon(Icons.warning_amber_rounded, color: _warningColor, size: 18),
            ],
          ),
          SizedBox(height: 12),
          Text(
            titulo,
            style: TextStyle(
              color: _textSecondary, 
              fontSize: isMobile ? 13 : 14, 
              fontWeight: FontWeight.w500
            ),
          ),
          SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              color: _textPrimary, 
              fontSize: isMobile ? 18 : 20, 
              fontWeight: FontWeight.w700
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPerfilFisico(bool isMobile) {
    return _buildSeccion(
      titulo: 'Perfil Físico',
      icono: Icons.fitness_center_rounded,
      color: _warningColor,
      isMobile: isMobile,
      child: _perfilFisico == null ? _buildSinPerfilFisico(isMobile) : _buildDatosPerfilFisico(isMobile),
    );
  }

  Widget _buildSinPerfilFisico(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: isMobile ? 48 : 56, color: _textSecondary),
          SizedBox(height: 12),
          Text(
            'Completa tu perfil físico',
            style: TextStyle(
              color: _textPrimary, 
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Registra tus medidas para hacer seguimiento de tu progreso',
            style: TextStyle(color: _textSecondary, fontSize: isMobile ? 13 : 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _irAPerfilFisico,
            style: ElevatedButton.styleFrom(
              backgroundColor: _warningColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Crear Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosPerfilFisico(bool isMobile) {
    final peso = _perfilFisico!['peso']?.toDouble() ?? 0.0;
    final altura = _perfilFisico!['altura']?.toDouble() ?? 0.0;
    final pesoObjetivo = _perfilFisico!['pesoObjetivo']?.toDouble();
    
    double alturaCm = altura < 3 ? altura * 100 : altura;
    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));
    final objetivoAlcanzado = pesoObjetivo != null && peso <= pesoObjetivo;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricaPerfil('Peso', '$peso kg', Icons.monitor_weight_rounded, _primaryColor, isMobile),
            _buildMetricaPerfil('Altura', '${alturaCm.toStringAsFixed(0)} cm', Icons.height_rounded, _successColor, isMobile),
            _buildMetricaPerfil('IMC', imc.toStringAsFixed(1), Icons.calculate_rounded, _obtenerColorIMC(imc), isMobile),
          ],
        ),
        SizedBox(height: 16),
        
        if (pesoObjetivo != null && pesoObjetivo > 0)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.flag_rounded, 
                  color: objetivoAlcanzado ? _successColor : _warningColor, 
                  size: 20
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objetivo de peso', 
                        style: TextStyle(
                          color: _textSecondary, 
                          fontSize: 13
                        )
                      ),
                      Text(
                        '$pesoObjetivo kg', 
                        style: TextStyle(
                          color: _textPrimary, 
                          fontWeight: FontWeight.w600
                        )
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: objetivoAlcanzado ? _successColor.withOpacity(0.1) : _warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    objetivoAlcanzado ? '¡Logrado!' : 'En progreso',
                    style: TextStyle(
                      color: objetivoAlcanzado ? _successColor : _warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        SizedBox(height: 16),
        
        OutlinedButton(
          onPressed: _irAPerfilFisico,
          style: OutlinedButton.styleFrom(
            foregroundColor: _warningColor,
            side: BorderSide(color: _warningColor),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('Ver perfil completo'),
        ),
      ],
    );
  }

  Widget _buildMetricaPerfil(String titulo, String valor, IconData icono, Color color, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: isMobile ? 20 : 24),
        ),
        SizedBox(height: 8),
        Text(
          titulo, 
          style: TextStyle(
            color: _textSecondary, 
            fontSize: 12, 
            fontWeight: FontWeight.w500
          )
        ),
        SizedBox(height: 4),
        Text(
          valor, 
          style: TextStyle(
            color: _textPrimary, 
            fontSize: isMobile ? 14 : 16, 
            fontWeight: FontWeight.w700
          )
        ),
      ],
    );
  }

  Widget _buildSeccionNiveles(bool isMobile) {
    if (_nivelAlumno == null) return SizedBox();

    return _buildSeccion(
      titulo: 'Mis Niveles',
      icono: Icons.emoji_events_rounded,
      color: _secondaryColor,
      isMobile: isMobile,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildNivelChip('Jiu Jitsu', _nivelAlumno!.cinturonJiujitsu, isMobile),
          _buildNivelChip('MMA', _nivelAlumno!.nivelMma, isMobile),
          _buildNivelChip('Box', _nivelAlumno!.nivelBox, isMobile),
          _buildNivelChip('Muay Thai', _nivelAlumno!.nivelMuayThai, isMobile),
          _buildNivelChip('Sanda', _nivelAlumno!.nivelSanda, isMobile),
        ],
      ),
    );
  }

  Widget _buildNivelChip(String disciplina, String nivel, bool isMobile) {
    final color = _obtenerColorNivel(nivel);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$disciplina: $nivel',
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPagos(bool isMobile) {
    final pagosRecientes = _ultimosPagos.take(3).toList();

    return _buildSeccion(
      titulo: 'Últimos Pagos',
      icono: Icons.payment_rounded,
      color: _successColor,
      isMobile: isMobile,
      accion: TextButton(
        onPressed: _irAPagos,
        style: TextButton.styleFrom(foregroundColor: _primaryColor),
        child: Text('Ver todos'),
      ),
      child: _ultimosPagos.isEmpty ? _buildSinPagos(isMobile) : Column(
        children: pagosRecientes.map((pago) => _buildItemPago(pago, isMobile)).toList(),
      ),
    );
  }

  Widget _buildSinPagos(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_rounded, size: isMobile ? 48 : 56, color: _textSecondary),
          SizedBox(height: 12),
          Text(
            'No hay pagos registrados',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPago(Map<String, dynamic> pago, bool isMobile) {
    final estado = pago['estado'] ?? 'completado';
    final colorEstado = estado == 'completado' ? _successColor : _warningColor;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              estado == 'completado' ? Icons.check_circle_rounded : Icons.pending_rounded,
              color: colorEstado,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'S/ ${pago['monto']?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 17, 
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${pago['concepto'] ?? 'Mensualidad'} • ${pago['metodo'] ?? 'Efectivo'}',
                  style: TextStyle(
                    color: _textSecondary, 
                    fontSize: isMobile ? 12 : 13
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatearFechaPago(pago['fecha_pago']),
                style: TextStyle(
                  color: _textSecondary, 
                  fontSize: isMobile ? 11 : 12
                ),
              ),
              SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  estado == 'completado' ? 'Pagado' : 'Pendiente',
                  style: TextStyle(
                    color: colorEstado, 
                    fontSize: isMobile ? 10 : 11, 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccesosRapidos(bool isMobile) {
    return _buildSeccion(
      titulo: 'Accesos Rápidos',
      icono: Icons.dashboard_rounded,
      color: _primaryColor,
      isMobile: isMobile,
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildTarjetaAcceso('Mis Pagos', Icons.payment_rounded, _successColor, _irAPagos, isMobile),
          _buildTarjetaAcceso('Perfil Físico', Icons.fitness_center_rounded, _warningColor, _irAPerfilFisico, isMobile),
          _buildTarjetaAcceso('Estado Cuenta', Icons.account_balance_wallet_rounded, _primaryColor, _irAEstadoCuenta, isMobile),
          _buildTarjetaAcceso('Mi Progreso', Icons.trending_up_rounded, _secondaryColor, _irAProgreso, isMobile),
        ],
      ),
    );
  }

  Widget _buildTarjetaAcceso(String titulo, IconData icono, Color color, VoidCallback onTap, bool isMobile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: color, size: isMobile ? 24 : 28),
              ),
              SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  color: _textPrimary,
                  fontSize: isMobile ? 13 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Color color,
    required Widget child,
    required bool isMobile,
    Widget? accion,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: color, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              if (accion != null) accion,
            ],
          ),
          SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Color _obtenerColorIMC(double imc) {
    if (imc < 18.5) return Colors.blue;
    if (imc < 25) return _successColor;
    if (imc < 30) return _warningColor;
    return _errorColor;
  }

  String _formatearFechaPago(dynamic fecha) {
    if (fecha == null) return 'N/A';
    if (fecha is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(fecha.toDate());
    }
    return fecha.toString();
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'N/A';
    try {
      if (fecha is DateTime) {
        return DateFormat('dd/MM/yyyy').format(fecha);
      } else if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy').format(fecha.toDate());
      } else if (fecha is String) {
        final parsed = DateTime.tryParse(fecha);
        if (parsed != null) {
          return DateFormat('dd/MM/yyyy').format(parsed);
        }
        return fecha;
      }
      return fecha.toString();
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _irAPagos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlumnoPagosScreen()),
    );
  }

  void _irAPerfilFisico() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlumnoPerfilScreen()),
    );
  }

  void _irAEstadoCuenta() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de cuenta - Próximamente'),
        backgroundColor: _primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _irAProgreso() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mi progreso - Próximamente'),
        backgroundColor: _secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _alumnoAuthService.logout();
    Navigator.pushReplacementNamed(context, '/');
  }
}