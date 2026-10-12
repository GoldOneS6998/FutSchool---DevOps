import 'package:flutter/material.dart';

import '../features/home/presentation/welcome_page.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/domain/admin_access.dart';
import '../features/admin/domain/admin_repository.dart';
import '../features/admin/presentation/admin_page.dart';
import 'theme.dart';

class FutSchoolApp extends StatelessWidget {
  const FutSchoolApp({super.key, this.auth, this.adminRepository});
  final AuthService? auth;
  final AdminRepository? adminRepository;

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
                    ? _AuthenticatedHome(
                        auth: auth!,
                        repository: adminRepository,
                      )
                    : LoginPage(auth: auth);
              },
            ),
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({required this.auth, this.repository});
  final AuthService auth;
  final AdminRepository? repository;

  @override
  State<_AuthenticatedHome> createState() => _AuthenticatedHomeState();
}

class _AuthenticatedHomeState extends State<_AuthenticatedHome> {
  Stream<bool>? _roles;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    if (widget.auth case final AdminAccess access) {
      _roles = access.adminChanges;
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      await (widget.auth as AdminAccess).refreshAdminAccess();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron comprobar los permisos.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_roles == null || widget.repository == null) {
      return WelcomePage(onSignOut: widget.auth.signOut);
    }
    return StreamBuilder<bool>(
      stream: _roles,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No se pudieron verificar los permisos.'),
                    TextButton(
                      onPressed: _refreshing ? null : _refresh,
                      child: const Text('Reintentar'),
                    ),
                    TextButton(
                      onPressed: widget.auth.signOut,
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) {
          return WelcomePage(
            onSignOut: widget.auth.signOut,
            onRefreshAccess: _refreshing ? null : _refresh,
          );
        }
        // Nested navigator is discarded on role revocation or sign-out,
        // including any open admin forms. Security Rules remain authoritative.
        return Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => AdminPage(
              repository: widget.repository!,
              onSignOut: widget.auth.signOut,
            ),
          ),
        );
      },
    );
  }
}
