import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'alumno_login_screen.dart';

class LoginSelectorScreen extends StatelessWidget {
  const LoginSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo principal - Si no tienes la imagen, usa un placeholder
              _buildLogo(),
              const SizedBox(height: 30),
              
              // Título principal
              Text(
                'TIGRE AZUL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
              SizedBox(height: 10),
              
              // Subtítulo
              Text(
                'ACCESO AL SISTEMA',
                style: TextStyle(
                  color: Colors.orange[400],
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 5),
              
              // Descripción
              Text(
                'Consulta tu información',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 50),
              
              // Botón Admin
              _buildLoginButton(
                title: 'ACCESO ADMIN',
                subtitle: 'Personal autorizado',
                icon: Icons.admin_panel_settings,
                color: Colors.orange[700]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
              ),
              
              SizedBox(height: 20),
              
              // Botón Alumno
              _buildLoginButton(
                title: 'ACCESO ALUMNO',
                subtitle: 'Consulta tu información',
                icon: Icons.person,
                color: Colors.blue[700]!,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AlumnoLoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    try {
      return Image.asset("assets/logo.jpg", height: 150);
    } catch (e) {
      // Si no existe la imagen, usa un placeholder
      return Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.orange[400],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.sports_martial_arts,
          color: Colors.white,
          size: 80,
        ),
      );
    }
  }

  Widget _buildLoginButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[900],
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}