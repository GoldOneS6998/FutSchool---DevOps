import 'package:flutter/material.dart';

import '../features/home/presentation/welcome_page.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/login_page.dart';
import 'theme.dart';

class FutSchoolApp extends StatelessWidget {
  const FutSchoolApp({super.key, this.auth});
  final AuthService? auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FutSchool',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: auth == null
          ? const LoginPage()
          : StreamBuilder<bool>(
              stream: auth!.sessionChanges,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Scaffold(
                    body: Center(
                      child: Text(
                        'No se pudo recuperar la sesión. Reinicia la aplicación.',
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return snapshot.data!
                    ? WelcomePage(onSignOut: auth!.signOut)
                    : LoginPage(auth: auth);
              },
            ),
    );
  }
}
