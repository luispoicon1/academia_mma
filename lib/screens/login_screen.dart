import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart'; // 👈 Asegúrate de importar el Dashboard

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedSede = 'chincha';
  bool _isLoading = false; // 👈 Agregar control de carga

  final Map<String, Map<String, String>> _sedesConfig = {
    'chincha': {
      'email': 'teamlanhu@gmail.com',
      'password': 'chincha123',
      'coleccion': 'chincha_alumnos',
      'nombre': 'Chincha'
    },
  };

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = _sedesConfig[_selectedSede]!['email']!;
    _passCtrl.text = _sedesConfig[_selectedSede]!['password']!;
  }

  Future<void> _login() async {
    if (_isLoading) return; // 👈 Evitar múltiples clics
    
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (userCredential.user != null) {
        await _guardarConfiguracionUsuario(_selectedSede);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Bienvenido a Tigre Azul - Sede $_selectedSede")),
        );

        // 👇 NAVEGACIÓN AL DASHBOARD DESPUÉS DEL LOGIN EXITOSO
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarConfiguracionUsuario(String sede) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set({
        'sede': sede,
        'coleccion_alumnos': _sedesConfig[sede]!['coleccion'],
        'nombre_sede': _sedesConfig[sede]!['nombre'],
        'email': user.email,
        'ultimo_login': DateTime.now(),
      }, SetOptions(merge: true));
    }
  }

  void _cambiarSede(String sede) {
    setState(() {
      _selectedSede = sede;
      _emailCtrl.text = _sedesConfig[sede]!['email']!;
      _passCtrl.text = _sedesConfig[sede]!['password']!;
    });
  }

  void _volverASeleccion() {
    if (!_isLoading) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380),
            child: Card(
              color: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con botón de retroceso
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.black54),
                          onPressed: _volverASeleccion,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "Acceso Administrativo",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 48), // Para balancear el espacio del IconButton
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Logo
                    Image.asset("assets/logo.jpg", height: 80),
                    const SizedBox(height: 16),

                    Text(
                      "Academia Tigre Azul",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "MMA • Muay Thai • Box • Jiu Jitsu • Sanda • Gym",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón login
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _login, // 👈 Deshabilitar durante carga
                      icon: _isLoading 
                          ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.login),
                      label: Text(_isLoading 
                          ? "Cargando..." 
                          : "Entrar - ${_sedesConfig[_selectedSede]!['nombre']}"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedSede == 'chincha'
                            ? Colors.blue
                            : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Botón secundario para volver
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _volverASeleccion,
                      icon: Icon(Icons.arrow_back, size: 18),
                      label: Text("Volver a selección"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonSede(String sede, String nombre, Color color) {
    final isSelected = _selectedSede == sede;
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _cambiarSede(sede), // 👈 Deshabilitar durante carga
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(nombre),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}