import 'package:flutter/material.dart';
import 'add_alumno_screen.dart';
import 'alumnos_list_screen.dart';
import 'reporte_screen.dart'; // 👈 Importa tu pantalla de reportes

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AddAlumnoScreen(),
    AlumnosListScreen(),
    ReporteScreen(), // 👈 Agregado
  ];

  final List<String> _titles = [
    "Registrar Alumno",
    "Lista de Alumnos",
    "Reporte", // 👈 Agregado
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.person_add),
                label: Text("Registrar"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list),
                label: Text("Alumnos"),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bar_chart), // 👈 Nuevo icono
                label: Text("Reporte"),
              ),
            ],
          ),

          // 🔹 Contenido principal
          Expanded(
            child: Scaffold(
              appBar: AppBar(
                title: Text(_titles[_selectedIndex]),
              ),
              body: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
