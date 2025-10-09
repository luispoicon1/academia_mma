import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/alumno_firestore_service.dart';
import '../services/user_type_service.dart';
import 'alumno_peleas_screen.dart';

class AlumnoPerfilScreen extends StatefulWidget {
  const AlumnoPerfilScreen({super.key});

  @override
  State<AlumnoPerfilScreen> createState() => _AlumnoPerfilScreenState();
}

class _AlumnoPerfilScreenState extends State<AlumnoPerfilScreen> {
  final _alumnoFirestoreService = AlumnoFirestoreService();
  Map<String, dynamic>? _perfilActual;
  List<Map<String, dynamic>> _historialPerfiles = [];
  Map<String, dynamic>? _datosAlumno;
  bool _cargando = true;

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final datosUsuario = await UserTypeService.getDatosAlumno();
      final alumnoId = datosUsuario['id'];
      final miDni = datosUsuario['dni'];
      
      if (alumnoId != null) {
        final perfil = await _alumnoFirestoreService.obtenerPerfilFisico(alumnoId);
        final historial = await _alumnoFirestoreService.obtenerHistorialPerfiles(alumnoId);
        
        Map<String, dynamic> datosAlumno;
        if (miDni != null) {
          final alumnoSnapshot = await FirebaseFirestore.instance
              .collection('alumnos')
              .where('dni', isEqualTo: miDni)
              .limit(1)
              .get();
          
          if (alumnoSnapshot.docs.isNotEmpty) {
            datosAlumno = alumnoSnapshot.docs.first.data();
          } else {
            datosAlumno = datosUsuario;
          }
        } else {
          datosAlumno = datosUsuario;
        }
        
        setState(() {
          _perfilActual = perfil;
          _historialPerfiles = historial;
          _datosAlumno = datosAlumno;
          _cargando = false;
        });
      }
    } catch (e) {
      print('Error cargando datos perfil: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Mi Perfil Físico', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 20,
          )),
        backgroundColor: _warningColor,
        elevation: 0,
        centerTitle: false,
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
          _buildInfoAlumno(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _perfilActual != null 
              ? _buildPerfilActual(isMobile) 
              : _buildSinPerfil(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          if (_historialPerfiles.length > 1) _buildHistorial(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildSeccionPeleas(isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoAlumno(bool isMobile) {
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
                  '${_datosAlumno?['nombre'] ?? ''} ${_datosAlumno?['apellido'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'DNI: ${_datosAlumno?['dni'] ?? ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8), 
                    fontSize: isMobile ? 14 : 16
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Curso: ${_datosAlumno?['curso'] ?? ''}',
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

  Widget _buildPerfilActual(bool isMobile) {
    final peso = _perfilActual!['peso']?.toDouble() ?? 0.0;
    final altura = _perfilActual!['altura']?.toDouble() ?? 0.0;
    final pesoObjetivo = _perfilActual!['pesoObjetivo']?.toDouble();
    
    double alturaCm = altura < 3 ? altura * 100 : altura;
    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));
    final fechaRegistro = _perfilActual!['fechaRegistro'] as Timestamp?;
    final objetivoAlcanzado = pesoObjetivo != null && peso <= pesoObjetivo;

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
                  color: _warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.fitness_center_rounded, color: _warningColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Perfil Actual',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              if (fechaRegistro != null)
                Text(
                  DateFormat('dd/MM/yyyy').format(fechaRegistro.toDate()),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          
          // Métricas principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricaGrande('Peso', '$peso kg', Icons.monitor_weight_rounded, _primaryColor, isMobile),
              _buildMetricaGrande('Altura', '${alturaCm.toStringAsFixed(0)} cm', Icons.height_rounded, _successColor, isMobile),
              _buildMetricaGrande('IMC', imc.toStringAsFixed(1), Icons.calculate_rounded, _obtenerColorIMC(imc), isMobile),
            ],
          ),
          SizedBox(height: 20),
          
          // Objetivo de peso
          if (pesoObjetivo != null && pesoObjetivo > 0)
            Container(
              width: double.infinity,
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
                    size: 24
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
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
          
          // Medidas corporales
          if (_tieneMedidasCorporales(_perfilActual!)) ...[
            SizedBox(height: 20),
            _buildMedidasCorporales(isMobile),
          ],
          
          // Observaciones
          if (_perfilActual!['observaciones'] != null && _perfilActual!['observaciones'].isNotEmpty) ...[
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Observaciones', 
                  style: TextStyle(
                    color: _textPrimary, 
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  )
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _perfilActual!['observaciones'],
                    style: TextStyle(color: _textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricaGrande(String titulo, String valor, IconData icono, Color color, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: isMobile ? 24 : 28),
        ),
        SizedBox(height: 8),
        Text(
          titulo, 
          style: TextStyle(
            color: _textSecondary, 
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w500,
          )
        ),
        SizedBox(height: 4),
        Text(
          valor, 
          style: TextStyle(
            color: color, 
            fontSize: isMobile ? 16 : 18, 
            fontWeight: FontWeight.w700
          )
        ),
      ],
    );
  }

  bool _tieneMedidasCorporales(Map<String, dynamic> perfil) {
    return (perfil['cintura'] != null && perfil['cintura'] > 0) ||
           (perfil['pecho'] != null && perfil['pecho'] > 0) ||
           (perfil['espalda'] != null && perfil['espalda'] > 0) ||
           (perfil['hombros'] != null && perfil['hombros'] > 0) ||
           (perfil['brazo'] != null && perfil['brazo'] > 0) ||
           (perfil['pierna'] != null && perfil['pierna'] > 0);
  }

  Widget _buildMedidasCorporales(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medidas Corporales', 
          style: TextStyle(
            color: _textPrimary, 
            fontWeight: FontWeight.w600,
            fontSize: 16,
          )
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMedidaItem('Cintura', _perfilActual!['cintura'], _primaryColor),
            _buildMedidaItem('Pecho', _perfilActual!['pecho'], _successColor),
            _buildMedidaItem('Espalda', _perfilActual!['espalda'], _warningColor),
            _buildMedidaItem('Hombros', _perfilActual!['hombros'], _errorColor),
            _buildMedidaItem('Brazo', _perfilActual!['brazo'], _secondaryColor),
            _buildMedidaItem('Pierna', _perfilActual!['pierna'], _primaryColor),
          ],
        ),
      ],
    );
  }

  Widget _buildMedidaItem(String nombre, dynamic valor, Color color) {
    if (valor == null || valor <= 0) return SizedBox();
    
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
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$nombre: $valor cm',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinPerfil(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
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
        children: [
          Icon(Icons.fitness_center_rounded, size: isMobile ? 60 : 80, color: _textSecondary),
          SizedBox(height: 16),
          Text(
            'No tienes perfil físico registrado',
            style: TextStyle(
              color: _textPrimary, 
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Contacta con tu entrenador para crear tu primer perfil físico',
            style: TextStyle(
              color: _textSecondary, 
              fontSize: isMobile ? 14 : 16
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorial(bool isMobile) {
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
                  color: _secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history_rounded, color: _secondaryColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Historial de Perfiles',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${_historialPerfiles.length - 1} registros',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Column(
            children: _historialPerfiles.skip(1).take(3).map((perfil) => _buildItemHistorial(perfil, isMobile)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHistorial(Map<String, dynamic> perfil, bool isMobile) {
    final fecha = perfil['fechaRegistro'] as Timestamp?;
    final peso = perfil['peso']?.toDouble() ?? 0.0;
    final altura = perfil['altura']?.toDouble() ?? 0.0;
    
    double alturaCm = altura < 3 ? altura * 100 : altura;
    final imc = peso / ((alturaCm / 100) * (alturaCm / 100));

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
              color: _secondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today_rounded, color: _secondaryColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fecha != null)
                  Text(
                    DateFormat('dd/MM/yyyy').format(fecha.toDate()),
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                SizedBox(height: 4),
                Text(
                  '$peso kg • ${alturaCm.toStringAsFixed(0)} cm • IMC: ${imc.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _textSecondary, 
                    fontSize: isMobile ? 12 : 13
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionPeleas(bool isMobile) {
    final totalPeleas = _datosAlumno?['peleas_totales'] ?? 0;
    final metas = {
      'MMA': _datosAlumno?['peleas_mma'] ?? 0,
      'Sanda': _datosAlumno?['peleas_sanda'] ?? 0,
      'Jiu-Jitsu': _datosAlumno?['peleas_jiujitsu'] ?? 0,
      'Boxeo': _datosAlumno?['peleas_boxeo'] ?? 0,
    };

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
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_mma_rounded, color: _errorColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Mis Peleas',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: $totalPeleas',
                  style: TextStyle(
                    color: _errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Grid de disciplinas
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildDisciplinaPelea('MMA', metas['MMA']!, _errorColor),
              _buildDisciplinaPelea('Sanda', metas['Sanda']!, _warningColor),
              _buildDisciplinaPelea('Jiu-Jitsu', metas['Jiu-Jitsu']!, _primaryColor),
              _buildDisciplinaPelea('Boxeo', metas['Boxeo']!, _successColor),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Botón para ver historial completo
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => AlumnoPeleasScreen())
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _errorColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ver Historial Completo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisciplinaPelea(String disciplina, int cantidad, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            disciplina,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            cantidad.toString(),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'peleas',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
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
}