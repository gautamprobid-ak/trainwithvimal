import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Role { client, trainer, admin }

class Session {
  const Session({required this.role, required this.name, required this.email, required this.initials, this.onboarded = true});
  final Role role;
  final String name;
  final String email;
  final String initials;

  /// Client finished welcome / setup steps.
  final bool onboarded;

  Session copyWith({bool? onboarded}) =>
      Session(role: role, name: name, email: email, initials: initials, onboarded: onboarded ?? this.onboarded);
}

/// Demo accounts from the design. Any other email logs in as client Riya.
abstract final class DemoAccounts {
  static const admin = Session(role: Role.admin, name: 'Vimal', email: 'vimal@trainwithvimal.app', initials: 'V');
  static const trainer = Session(role: Role.trainer, name: 'Aman Verma', email: 'aman.verma@email.com', initials: 'AV');
  static const client = Session(role: Role.client, name: 'Riya Sharma', email: 'riya.sharma@email.com', initials: 'RS');

  static Session forEmail(String email) {
    final e = email.trim().toLowerCase();
    if (e == admin.email || e.startsWith('vimal')) return admin;
    if (e == trainer.email || e.startsWith('aman')) return trainer;
    return client;
  }
}

class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  void signIn(Session s) => state = s;

  void signInWithEmail(String email) => state = DemoAccounts.forEmail(email);

  void completeOnboarding() {
    final s = state;
    if (s != null) state = s.copyWith(onboarded: true);
  }

  void signOut() => state = null;
}

final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

/// Home route for a role.
String homeFor(Role r) => switch (r) {
      Role.client => '/c/home',
      Role.trainer => '/t/home',
      Role.admin => '/a/home',
    };
