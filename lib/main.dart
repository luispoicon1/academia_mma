import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_selector_screen.dart';
import 'screens/alumno_dashboard_screen.dart';
import 'services/user_type_service.dart';
// Cambia esta importación:
import '../models/user_type.dart'; // ← así porque models está al mismo nivel que lib

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academia MMA',
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder<UserType>(
              future: UserTypeService.determinarTipoUsuario(),
              builder: (context, typeSnapshot) {
                if (typeSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingScreen();
                }
                
                if (typeSnapshot.hasData) {
                  switch (typeSnapshot.data!) {
                    case UserType.admin:
                      return const DashboardScreen();
                    case UserType.alumno:
                      return const AlumnoDashboardScreen();
                  }
                }
                
                return const LoginSelectorScreen();
              },
            );
          }
          
          return const LoginSelectorScreen();
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
            ),
            SizedBox(height: 20),
            Text(
              'Cargando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}