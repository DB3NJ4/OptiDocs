import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'home_screen.dart'; // COMENTAR TEMPORALMENTE
// import 'auth/login_screen.dart'; // COMENTAR TEMPORALMENTE

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          // Usuario logueado - mostrar home temporal
          return Scaffold(
            appBar: AppBar(title: const Text('OptiDocs - Logged In')),
            body: const Center(
              child: Text('Usuario autenticado - Home screen en desarrollo'),
            ),
          );
        } else {
          // Usuario no logueado - mostrar login temporal
          return Scaffold(
            appBar: AppBar(title: const Text('OptiDocs - Login')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pantalla de login en desarrollo'),
                  ElevatedButton(
                    onPressed: () {
                      // Login temporal
                      FirebaseAuth.instance.signInAnonymously();
                    },
                    child: const Text('Entrar como invitado'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
