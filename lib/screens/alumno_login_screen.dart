import 'package:flutter/material.dart';
import '../services/alumno_auth_service.dart';
import 'alumno_dashboard_screen.dart';

class AlumnoLoginScreen extends StatefulWidget {
  const AlumnoLoginScreen({super.key});

  @override
  State<AlumnoLoginScreen> createState() => _AlumnoLoginScreenState();
}

class _AlumnoLoginScreenState extends State<AlumnoLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _celularController = TextEditingController();
  final _alumnoAuthService = AlumnoAuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                SizedBox(height: 20),
                Text(
                  'Acceso Alumno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Ingresa tus datos para consultar tu información',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 40),
                
                TextFormField(
                  controller: _dniController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'DNI',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    prefixIcon: Icon(Icons.badge, color: Colors.grey[400]),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu DNI';
                    if (value.length != 8) return 'El DNI debe tener 8 dígitos';
                    return null;
                  },
                ),
                
                SizedBox(height: 20),
                
                TextFormField(
                  controller: _celularController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Celular',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue[700]!),
                    ),
                    prefixIcon: Icon(Icons.phone, color: Colors.grey[400]),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu celular';
                    if (value.length != 9) return 'El celular debe tener 9 dígitos';
                    return null;
                  },
                ),
                
                SizedBox(height: 40),
                
                if (_isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _loginAlumno,
                      child: Text(
                        'INGRESAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                
                Spacer(),
                
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Si tienes problemas para acceder, contacta con la administración.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loginAlumno() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _alumnoAuthService.loginAlumno(
          _dniController.text.trim(),
          _celularController.text.trim(),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AlumnoDashboardScreen()),
        );
        
      } catch (e) {
        setState(() => _isLoading = false);
        _mostrarError('Error: $e');
      }
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _dniController.dispose();
    _celularController.dispose();
    super.dispose();
  }
}