import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_type_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Añade esta importación
import 'package:flutter/services.dart'; // Para Clipboard

class AlumnoPeleasScreen extends StatefulWidget {
  const AlumnoPeleasScreen({super.key});

  @override
  State<AlumnoPeleasScreen> createState() => _AlumnoPeleasScreenState();
}

class _AlumnoPeleasScreenState extends State<AlumnoPeleasScreen> {
  Map<String, dynamic> _datosAlumno = {};
  List<dynamic> _historialPeleas = [];
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
            _historialPeleas = alumnoData['historial_peleas'] ?? [];
            _cargando = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando datos de peleas: $e');
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Mis Peleas', 
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w600,
            fontSize: 20,
          )),
        backgroundColor: _errorColor,
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
          _buildResumenPeleas(isMobile),
          SizedBox(height: isMobile ? 20 : 24),
          _buildHistorialPeleas(isMobile),
        ],
      ),
    );
  }

  Widget _buildResumenPeleas(bool isMobile) {
    final totalPeleas = _datosAlumno['peleas_totales'] ?? 0;
    
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
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.emoji_events_rounded, color: _errorColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Resumen de Peleas',
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
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Total: $totalPeleas',
                  style: TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildContadorPeleas('MMA', _datosAlumno['peleas_mma'] ?? 0, _errorColor, isMobile),
              _buildContadorPeleas('Sanda', _datosAlumno['peleas_sanda'] ?? 0, _warningColor, isMobile),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildContadorPeleas('Jiu-Jitsu', _datosAlumno['peleas_jiujitsu'] ?? 0, _primaryColor, isMobile),
              _buildContadorPeleas('Boxeo', _datosAlumno['peleas_boxeo'] ?? 0, _successColor, isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContadorPeleas(String tipo, int cantidad, Color color, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            cantidad.toString(),
            style: TextStyle(
              color: color, 
              fontSize: isMobile ? 16 : 18, 
              fontWeight: FontWeight.w700
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          tipo, 
          style: TextStyle(
            color: _textSecondary, 
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w500,
          )
        ),
      ],
    );
  }

  Widget _buildHistorialPeleas(bool isMobile) {
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
                child: Icon(Icons.history_rounded, color: _warningColor, size: isMobile ? 18 : 20),
              ),
              SizedBox(width: 8),
              Text(
                'Historial de Peleas',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${_historialPeleas.length} registros',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _historialPeleas.isEmpty ? _buildSinPeleas(isMobile) : Column(
            children: _historialPeleas.map((pelea) => _buildItemPelea(pelea, isMobile)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemPelea(Map<String, dynamic> pelea, bool isMobile) {
    Color colorResultado = pelea['resultado'] == 'Victoria' 
        ? _successColor 
        : pelea['resultado'] == 'Derrota' 
            ? _errorColor 
            : _warningColor;

    IconData iconoResultado = pelea['resultado'] == 'Victoria' 
        ? Icons.emoji_events_rounded 
        : pelea['resultado'] == 'Derrota' 
            ? Icons.sports_mma_rounded 
            : Icons.draw_rounded;

    bool tieneVideo = pelea['video_url'] != null && pelea['video_url'].isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorResultado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconoResultado, color: colorResultado, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${pelea['tipo']}',
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: isMobile ? 14 : 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorResultado.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            pelea['resultado'],
                            style: TextStyle(
                              color: colorResultado,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'vs ${pelea['oponente']}',
                      style: TextStyle(
                        color: _textSecondary, 
                        fontSize: isMobile ? 12 : 13
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '${pelea['evento']} • ${_formatearFecha(pelea['fecha'])}',
                      style: TextStyle(
                        color: _textSecondary, 
                        fontSize: isMobile ? 11 : 12
                      ),
                    ),
                    if (pelea['metodo'] != null)
                      Text(
                        'Método: ${pelea['metodo']}',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: isMobile ? 11 : 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          // ✅ NUEVA SECCIÓN PARA EL VIDEO
          if (tieneVideo) ...[
            SizedBox(height: 12),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 8),
            _buildSeccionVideo(pelea['video_url'], isMobile),
          ],
        ],
      ),
    );
  }

  // ✅ NUEVO WIDGET PARA LA SECCIÓN DE VIDEO
  Widget _buildSeccionVideo(String videoUrl, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.videocam_rounded, size: 16, color: _primaryColor),
            SizedBox(width: 6),
            Text(
              'Video disponible',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _mostrarOpcionesVideo(videoUrl),
                icon: Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(
                  'Ver Video',
                  style: TextStyle(fontSize: isMobile ? 13 : 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () => _copiarUrlVideo(videoUrl),
              icon: Icon(Icons.copy_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: _backgroundColor,
                padding: EdgeInsets.all(10),
              ),
              tooltip: 'Copiar URL',
            ),
          ],
        ),
        if (isMobile) SizedBox(height: 4),
        if (isMobile)
          Text(
            'Toca para ver opciones de reproducción',
            style: TextStyle(
              fontSize: 10,
              color: _textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  // ✅ MÉTODO PARA MOSTRAR OPCIONES DE VIDEO
  void _mostrarOpcionesVideo(String url) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ver Video de la Pelea',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Elige cómo quieres ver el video:',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 20),
            _buildOpcionVideo(
              icon: Icons.open_in_browser_rounded,
              titulo: 'Abrir en Navegador',
              subtitulo: 'Abre el video en tu navegador preferido',
              onTap: () => _abrirEnNavegador(url),
              color: _primaryColor,
            ),
            SizedBox(height: 12),
            _buildOpcionVideo(
              icon: Icons.content_copy_rounded,
              titulo: 'Copiar Enlace',
              subtitulo: 'Copia la URL para compartir o ver después',
              onTap: () => _copiarUrlVideo(url),
              color: _secondaryColor,
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET PARA OPCIÓN DE VIDEO
  Widget _buildOpcionVideo({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 12,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: _backgroundColor,
    );
  }

  // ✅ MÉTODO PARA ABRIR EN NAVEGADOR
  Future<void> _abrirEnNavegador(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _mostrarError('No se pudo abrir el enlace');
      }
    } catch (e) {
      _mostrarError('Error al abrir el video: $e');
    }
  }

  // ✅ MÉTODO PARA COPIAR URL
  void _copiarUrlVideo(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ URL copiada al portapapeles'),
        backgroundColor: _successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ✅ MÉTODO PARA MOSTRAR ERRORES
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSinPeleas(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.sports_mma_rounded, size: isMobile ? 48 : 56, color: _textSecondary),
          SizedBox(height: 12),
          Text(
            'Aún no tienes peleas registradas',
            style: TextStyle(
              color: _textPrimary, 
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tu historial de combates aparecerá aquí',
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

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Fecha no disponible';
    if (fecha is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(fecha.toDate());
    }
    return fecha.toString();
  }
}