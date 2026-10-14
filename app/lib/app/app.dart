import 'package:flutter/material.dart';

import '../features/home/presentation/welcome_page.dart';
import '../features/auth/domain/auth_service.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/domain/admin_access.dart';
import '../features/admin/domain/admin_repository.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/admin/domain/admin_management_repository.dart';
import '../features/captain/domain/captain_repository.dart';
import '../features/captain/presentation/captain_page.dart';
import '../features/auth/domain/account_access.dart';
import '../features/auth/presentation/verification_page.dart';
import '../features/privacy/domain/privacy_repository.dart';
import 'theme.dart';

class FutSchoolApp extends StatelessWidget {
  const FutSchoolApp({
    super.key,
    this.auth,
    this.adminRepository,
    this.managementRepository,
    this.captainRepository,
    this.privacyRepository,
  });
  final AuthService? auth;
  final AdminRepository? adminRepository;
  final AdminManagementRepository? managementRepository;
  final CaptainRepository? captainRepository;
  final PrivacyRepository? privacyRepository;

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
                    ? _IdentityGate(
                        auth: auth!,
                        repository: adminRepository,
                        management: managementRepository,
                        captain: captainRepository,
                        privacy: privacyRepository,
                      )
                    : LoginPage(auth: auth, privacy: privacyRepository);
              },
            ),
    );
  }
}

class _IdentityGate extends StatefulWidget {
  const _IdentityGate({
    required this.auth,
    this.repository,
    this.management,
    this.captain,
    this.privacy,
  });
  final AuthService auth;
  final AdminRepository? repository;
  final AdminManagementRepository? management;
  final CaptainRepository? captain;
  final PrivacyRepository? privacy;
  @override
  State<_IdentityGate> createState() => _IdentityGateState();
}

class _IdentityGateState extends State<_IdentityGate> {
  late final Stream<String?>? _identities = widget.auth is SessionIdentityAccess
      ? (widget.auth as SessionIdentityAccess).identityChanges
      : null;
  @override
  Widget build(BuildContext context) {
    Widget home(String? uid) => _VerificationGate(
      key: ValueKey(uid),
      auth: widget.auth,
      repository: widget.repository,
      management: widget.management,
      captain: widget.captain,
    );
    if (_identities == null) return home(null);
    return StreamBuilder<String?>(
      stream: _identities,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'No se pudo comprobar la identidad. Cierra y vuelve a abrir la aplicación.',
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return LoginPage(auth: widget.auth, privacy: widget.privacy);
        }
        // Discards every role route, stream and draft when A changes to B,
        // even when Firebase never emits a signed-out state between them.
        return home(snapshot.data);
      },
    );
  }
}

class _VerificationGate extends StatefulWidget {
  const _VerificationGate({
    super.key,
    required this.auth,
    this.repository,
    this.management,
    this.captain,
  });
  final AuthService auth;
  final AdminRepository? repository;
  final AdminManagementRepository? management;
  final CaptainRepository? captain;
  @override
  State<_VerificationGate> createState() => _VerificationGateState();
}

class _VerificationGateState extends State<_VerificationGate> {
  late final Stream<bool>? _verification = widget.auth is AccountAccess
      ? (widget.auth as AccountAccess).verifiedChanges
      : null;
  @override
  Widget build(BuildContext context) {
    Widget home() => _AuthenticatedHome(
      auth: widget.auth,
      repository: widget.repository,
      management: widget.management,
      captain: widget.captain,
    );
    if (_verification == null) return home();
    return StreamBuilder<bool>(
      stream: _verification,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return VerificationPage(
            account: widget.auth as AccountAccess,
            onSignOut: widget.auth.signOut,
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.data!) {
          return VerificationPage(
            account: widget.auth as AccountAccess,
            onSignOut: widget.auth.signOut,
          );
        }
        return home();
      },
    );
  }
}

class _AuthenticatedHome extends StatefulWidget {
  const _AuthenticatedHome({
    required this.auth,
    this.repository,
    this.management,
    this.captain,
  });
  final AuthService auth;
  final AdminRepository? repository;
  final AdminManagementRepository? management;
  final CaptainRepository? captain;

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
          if (widget.captain != null) {
            return Navigator(
              key: const ValueKey('captain-routes'),
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => CaptainPage(
                  repository: widget.captain!,
                  onSignOut: widget.auth.signOut,
                  onRefreshAccess: _refreshing ? null : _refresh,
                ),
              ),
            );
          }
          return WelcomePage(
            onSignOut: widget.auth.signOut,
            onRefreshAccess: _refreshing ? null : _refresh,
          );
        }
        // Nested navigator is discarded on role revocation or sign-out,
        // including any open admin forms. Security Rules remain authoritative.
        return Navigator(
          key: const ValueKey('admin-routes'),
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => AdminPage(
              repository: widget.repository!,
              onSignOut: widget.auth.signOut,
              managementRepository: widget.management,
            ),
          ),
        );
      },
    );
  }
}
