import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class PagosListScreen extends StatelessWidget {
  const PagosListScreen({super.key});

  

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text("Pagos Registrados")),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.streamPagos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No hay pagos aún"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final fecha = (data['fecha_pago'] as Timestamp).toDate();
              return ListTile(
                title: Text("${data['nombre']} - S/ ${data['monto']}"),
                subtitle: Text("${data['curso']} | ${data['metodo']}"),
                trailing: Text(DateFormat("dd/MM/yyyy").format(fecha)),
              );
            },
          );
        },
      ),
    );
  }
}

