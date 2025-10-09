import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_alumno_screen.dart';
import 'alumnos_list_screen.dart';
//import 'reporte_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _userData;
  int _totalAlumnos = 0;
  int _totalPagosHoy = 0;
  double _ingresosHoy = 0;

 // POR ESTO:
final List<Widget> _screens = [
  AddAlumnoScreen(),
  AlumnosListScreen(),
  // Solo 2 screens ahora
];

  final List<String> _titles = [
  "Registrar Alumno",
  "Lista de Alumnos",
  // Solo 2 títulos ahora
];

  final List<IconData> _icons = [
  Icons.person_add_alt_1,
  Icons.people_alt,
  // Solo 2 íconos ahora
];

  // NUEVO: Controlador para el drawer móvil
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      setState(() {
        _userData = doc.data();
      });
    }
  }

  Future<void> _loadStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      
      final sede = userDoc.data()?['sede'] ?? 'chincha';
      final coleccionAlumnos = userDoc.data()?['coleccion_alumnos'] ?? 'chincha_alumnos';

      final alumnosSnapshot = await FirebaseFirestore.instance
          .collection(coleccionAlumnos)
          .get();
      
      final hoy = DateTime.now();
      final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
      
      final pagosSnapshot = await FirebaseFirestore.instance
          .collection('pagos')
          .where('fecha_pago', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioDia))
          .get();

      setState(() {
        _totalAlumnos = alumnosSnapshot.size;
        _totalPagosHoy = pagosSnapshot.size;
        _ingresosHoy = pagosSnapshot.docs
            .fold(0.0, (sum, doc) => sum + (doc.data()['monto'] ?? 0.0));
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  // NUEVO: Método para determinar si es móvil
  bool get _isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    // Si es móvil, usar Scaffold con Drawer
    if (_isMobile) {
      return _buildMobileLayout();
    }
    // Si es desktop/tablet, usar layout con sidebar fijo
    return _buildDesktopLayout();
  }

  // LAYOUT PARA MÓVIL
  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          // User avatar en appbar para móvil
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, color: Colors.blueAccent, size: 18),
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: _buildMobileDrawer(),
      body: _buildContent(),
    );
  }

  // LAYOUT PARA DESKTOP
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar para desktop
          _buildDesktopSidebar(),
          
          // Contenido principal
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF8FAFD),
                    Color(0xFFEFF3F6),
                    Color(0xFFF8FAFD),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // AppBar para desktop
                  _buildDesktopAppBar(),
                  
                  // Contenido
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SIDEBAR PARA DESKTOP
  Widget _buildDesktopSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF050D27),
            Color(0xFF050D27),
            Color(0xFF050D27),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          
          // Logo
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.amber, Colors.orange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF0D1B2A),
              child: CircleAvatar(
                radius: 45,
                backgroundImage: AssetImage("assets/logo.jpg"),
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          Text(
            "TIGRE AZUL",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            _userData?['nombre_sede'] ?? 'Sede',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          
          // Stats rápidos
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            
          ),
          
          const SizedBox(height: 20),

          // Menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildMenuItem(Icons.person_add_alt_1, "Registrar Alumno", 0),
                _buildMenuItem(Icons.people_alt_outlined, "Lista de Alumnos", 1),
              ],
            ),
          ),

          // Cerrar sesión
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text("Cerrar Sesión",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // DRAWER PARA MÓVIL
  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: Color(0xFF0D1B2A),
      child: Column(
        children: [
          // Header del drawer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage("assets/logo.jpg"),
                ),
                const SizedBox(height: 10),
                Text(
                  "TIGRE AZUL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['nombre_sede'] ?? 'Sede',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Stats móviles
       

          // Menú móvil
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMobileMenuItem(Icons.person_add_alt_1, "Registrar Alumno", 0),
                _buildMobileMenuItem(Icons.people_alt_outlined, "Lista de Alumnos", 1),
              ],
            ),
          ),

          // Cerrar sesión móvil
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade800],
              ),
            ),
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.white, size: 20),
              title: Text("Cerrar Sesión",
                  style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  // APP BAR PARA DESKTOP
  Widget _buildDesktopAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icons[_selectedIndex],
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _titles[_selectedIndex],
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B263B),
                    ),
                  ),
                  Text(
                    _userData?['nombre_sede'] ?? 'Sede',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // User info desktop
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Administrador',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    _userData?['email'] ?? 'Usuario',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.person, color: Colors.blue.shade700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CONTENIDO PRINCIPAL (compartido entre móvil y desktop)
  Widget _buildContent() {
    return Padding(
      padding: _isMobile 
          ? const EdgeInsets.all(8.0)  // Menos padding en móvil
          : const EdgeInsets.all(20),   // Más padding en desktop
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_isMobile ? 8 : 20),
          boxShadow: _isMobile ? [] : [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF8FAFD),
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_isMobile ? 8 : 20),
          child: Container(
            decoration: BoxDecoration(
              border: _isMobile ? null : Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: _screens[_selectedIndex],
          ),
        ),
      ),
    );
  }

  // ============ WIDGETS AUXILIARES ============

  Widget _buildMenuItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [Colors.amber.shade400, Colors.orange.shade400],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 22,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: () {
            setState(() => _selectedIndex = index);
            if (_isMobile) {
              Navigator.pop(context); // Cerrar drawer en móvil
            }
          },
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.amber : Colors.white70,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.amber : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      tileColor: isSelected ? Colors.white12 : Colors.transparent,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Cerrar drawer
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.amber,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}