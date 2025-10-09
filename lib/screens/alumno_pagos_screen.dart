import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/alumno_firestore_service.dart';
import '../services/user_type_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlumnoPagosScreen extends StatefulWidget {
  const AlumnoPagosScreen({super.key});

  @override
  State<AlumnoPagosScreen> createState() => _AlumnoPagosScreenState();
}

class _AlumnoPagosScreenState extends State<AlumnoPagosScreen> {
  final _alumnoFirestoreService = AlumnoFirestoreService();
  List<Map<String, dynamic>> _pagos = [];
  Map<String, dynamic> _datosAlumno = {};
  bool _cargando = true;
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

  @override
  void initState() {
    super.initState();
    _inicializarNotificaciones();
    _cargarDatos();
  }

  Future<void> _inicializarNotificaciones() async {
    tz.initializeTimeZones();
    
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'canal_membresias',
          channelName: 'Recordatorios de Membresía',
          channelDescription: 'Recordatorios cuando tu membresía está por vencer',
          defaultColor: _primaryColor,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        ),
      ],
    );
    
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  Future<void> _programarNotificacion(DateTime fechaVencimiento, int diasAntes) async {
    final fechaNotificacion = fechaVencimiento.subtract(Duration(days: diasAntes));
    
    if (fechaNotificacion.isAfter(DateTime.now())) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: diasAntes,
          channelKey: 'canal_membresias',
          title: '⚠️ Tu membresía está por vencer',
          body: 'Vence en $diasAntes días. ¡Renueva ahora!',
        ),
        schedule: NotificationCalendar.fromDate(date: fechaNotificacion),
      );
    }
  }

  Future<void> _cancelarNotificacionesAnteriores() async {
    await AwesomeNotifications().cancelAllSchedules();
  }

  Future<void> _programarRecordatorios(DateTime fechaVencimiento) async {
    await _cancelarNotificacionesAnteriores();
    await _programarNotificacion(fechaVencimiento, 7);
    await _programarNotificacion(fechaVencimiento, 3);
    await _programarNotificacion(fechaVencimiento, 1);
    
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'canal_membresias',
        title: '⏰ Tu membresía vence hoy',
        body: '¡Renueva ahora para continuar entrenando!',
      ),
      schedule: NotificationCalendar.fromDate(date: fechaVencimiento),
    );
  }

  Future<void> _mostrarNotificacionInmediata() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 999,
        channelKey: 'canal_membresias',
        title: '🔔 Recordatorio de Membresía',
        body: 'Tu membresía está activa. Te avisaremos cuando esté por vencer.',
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificación de prueba enviada'),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _cargarDatos() async {
    try {
      final datosUsuario = await UserTypeService.getDatosAlumno();
      final miNombre = datosUsuario['nombre'];
      final miCurso = datosUsuario['curso'];
      final miDni = datosUsuario['dni'];
      
      if (miDni != null) {
        final alumnoSnapshot = await FirebaseFirestore.instance
            .collection('alumnos')
            .where('dni', isEqualTo: miDni)
            .limit(1)
            .get();
        
        if (alumnoSnapshot.docs.isNotEmpty) {
          final alumnoData = alumnoSnapshot.docs.first.data();
          setState(() {
            _datosAlumno = alumnoData;
          });
        } else {
          setState(() {
            _datosAlumno = datosUsuario;
          });
        }
      } else {
        setState(() {
          _datosAlumno = datosUsuario;
        });
      }

      await _cargarPagos(miNombre, miCurso);
      await _calcularEstadoMembresia();

    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarPagos(String? miNombre, String? miCurso) async {
    try {
      List<Map<String, dynamic>> pagos = [];

      if (miCurso != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('pagos')
            .where('curso', isEqualTo: miCurso)
            .get();

        final misPagos = querySnapshot.docs.where((doc) {
          final data = doc.data();
          final nombrePago = data['nombre']?.toString().toLowerCase() ?? '';
          final nombreAlumno = miNombre?.toString().toLowerCase() ?? '';
          
          final nombresAlumno = nombreAlumno.split(' ');
          return nombresAlumno.any((nombre) => nombrePago.contains(nombre));
        }).toList();

        pagos = misPagos.map((doc) {
          final data = doc.data();
          return {'id': doc.id, ...data};
        }).toList();
      }

      setState(() => _pagos = pagos);
    } catch (e) {
      print('Error cargando pagos: $e');
    }
  }

  Future<void> _calcularEstadoMembresia() async {
    final fechaFin = _datosAlumno['fecha_fin'];
    if (fechaFin == null) {
      _estadoMembresia = 'Sin fecha de vencimiento';
      _colorEstado = _textSecondary;
      setState(() => _cargando = false);
      return;
    }

    DateTime fechaVencimiento;
    if (fechaFin is Timestamp) {
      fechaVencimiento = fechaFin.toDate();
    } else if (fechaFin is DateTime) {
      fechaVencimiento = fechaFin;
    } else {
      _estadoMembresia = 'Formato de fecha inválido';
      _colorEstado = _textSecondary;
      setState(() => _cargando = false);
      return;
    }

    _fechaVencimiento = fechaVencimiento;
    final ahora = DateTime.now();
    final diasRestantes = fechaVencimiento.difference(ahora).inDays;

    if (diasRestantes > 0) {
      await _programarRecordatorios(fechaVencimiento);
    }

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

    setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Mis Pagos', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 20,
          )),
        backgroundColor: _successColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_active_rounded, color: Colors.white),
            onPressed: _mostrarNotificacionInmediata,
            tooltip: 'Probar notificación',
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
    final totalPagado = _pagos.fold(0.0, (sum, pago) => sum + (pago['monto'] ?? 0.0));
    final pagosCompletados = _pagos.where((pago) => pago['estado'] == 'completado').length;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        children: [
          _buildAlertaMembresia(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildResumenFinanciero(totalPagado, pagosCompletados, isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildListaPagos(isMobile),
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
                  'Plan ${_datosAlumno['plan'] ?? 'No especificado'} • Vence ${_fechaVencimiento != null ? _formatearFecha(_fechaVencimiento!) : 'No definido'}',
                  style: TextStyle(
                    color: _textSecondary, 
                    fontSize: isMobile ? 13 : 14
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '🔔 Recibirás recordatorios automáticos',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenFinanciero(double totalPagado, int pagosCompletados, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaMetrica(
            'Total Pagado',
            'S/ ${totalPagado.toStringAsFixed(2)}',
            Icons.attach_money_rounded,
            _successColor,
            isMobile,
          ),
        ),
        SizedBox(width: isMobile ? 12 : 16),
        Expanded(
          child: _buildTarjetaMetrica(
            'Pagos Realizados',
            pagosCompletados.toString(),
            Icons.check_circle_rounded,
            _primaryColor,
            isMobile,
          ),
        ),
      ],
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

  Widget _buildListaPagos(bool isMobile) {
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
                  color: _successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.receipt_long_rounded, color: _successColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Historial de Pagos',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${_pagos.length} registros',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _pagos.isEmpty ? _buildSinPagos(isMobile) : Column(
            children: _pagos.map((pago) => _buildItemPago(pago, isMobile)).toList(),
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
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
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
                  'S/ ${(pago['monto'] ?? 0.0).toStringAsFixed(2)}',
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

  Widget _buildSinPagos(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.payment_rounded, size: isMobile ? 48 : 56, color: _textSecondary),
          SizedBox(height: 12),
          Text(
            'No hay pagos registrados',
            style: TextStyle(
              color: _textPrimary, 
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Los pagos aparecerán aquí una vez registrados',
            style: TextStyle(
              color: _textSecondary, 
              fontSize: isMobile ? 13 : 14
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
}