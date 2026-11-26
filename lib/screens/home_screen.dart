import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis gastos'), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () => AuthService().signOut()),
      ]),
      body: Center(child: Text('Hola, ${FirebaseAuth.instance.currentUser?.email}')),
    );
  }
}