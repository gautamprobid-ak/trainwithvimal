import '../../core/theme/app_colors.dart';

enum ClientStatus { active, pending, atRisk, paused }

extension ClientStatusX on ClientStatus {
  String get label => switch (this) {
        ClientStatus.active => 'Active',
        ClientStatus.pending => 'Pending',
        ClientStatus.atRisk => 'At risk',
        ClientStatus.paused => 'Paused',
      };
}

/// A client as shown in client lists (admin Clients, trainer My clients).
class ClientSummary {
  const ClientSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.trainer,
    required this.goal,
    required this.status,
    required this.thisWeek,
    required this.phone,
    required this.joined,
    required this.nextCheckin,
    required this.lastActive,
    this.program,
    this.adherence,
  });

  final String id;
  final String name;
  final String email;
  final String trainer;
  final String goal;
  final ClientStatus status;

  /// This week's progress ("Done", "40%", "Not started").
  final String thisWeek;
  final String phone;
  final String joined;
  final String nextCheckin;
  final String lastActive;
  final String? program;
  final int? adherence;

  String get initials {
    final p = name.split(' ');
    return p.length > 1 ? '${p.first[0]}${p.last[0]}' : p.first[0];
  }

  ClientSummary copyWith({String? trainer, ClientStatus? status}) => ClientSummary(
        id: id,
        name: name,
        email: email,
        trainer: trainer ?? this.trainer,
        goal: goal,
        status: status ?? this.status,
        thisWeek: thisWeek,
        phone: phone,
        joined: joined,
        nextCheckin: nextCheckin,
        lastActive: lastActive,
        program: program,
        adherence: adherence,
      );
}

/// A coach on the team.
class Trainer {
  const Trainer({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.email,
    required this.focus,
    required this.clients,
    required this.capacity,
    required this.pendingCheckins,
    required this.adherence,
    required this.access,
    required this.active,
    required this.since,
    this.isYou = false,
  });

  final String id;
  final String name;
  final String initials;
  final AvatarColor color;
  final String email;
  final String focus;
  final int clients;
  final int capacity;
  final int pendingCheckins;
  final int adherence;
  final String access;
  final bool active;
  final String since;
  final bool isYou;

  bool get isFull => clients >= capacity;
}
