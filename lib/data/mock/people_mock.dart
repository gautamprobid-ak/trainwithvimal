import '../../core/theme/app_colors.dart';
import '../models/people.dart';

/// People from the "Train With Vimal" design. Today in the design is Fri, 9 Oct 2026.
abstract final class PeopleMock {
  static const clients = <ClientSummary>[
    ClientSummary(
      id: 'riya',
      name: 'Riya Sharma',
      email: 'riya.sharma@email.com',
      trainer: 'Aman Verma',
      goal: 'Fat loss',
      status: ClientStatus.active,
      thisWeek: 'Done',
      phone: '+91 98201 11234',
      joined: '12 Jan 2026',
      nextCheckin: 'Sun, 11 Oct',
      lastActive: '2 h ago',
      program: 'Fat Loss Phase 1',
      adherence: 88,
    ),
    ClientSummary(
      id: 'rohan',
      name: 'Rohan Kapoor',
      email: 'rohan.kapoor@email.com',
      trainer: 'Aman Verma',
      goal: 'Muscle gain',
      status: ClientStatus.active,
      thisWeek: '40%',
      phone: '+91 98202 22345',
      joined: '3 Feb 2026',
      nextCheckin: 'Sun, 11 Oct',
      lastActive: '5 h ago',
      program: 'Hypertrophy · Push / Pull / Legs',
      adherence: 76,
    ),
    ClientSummary(
      id: 'neha',
      name: 'Neha Jain',
      email: 'neha@email.com',
      trainer: 'Aman Verma',
      goal: 'General fitness',
      status: ClientStatus.pending,
      thisWeek: 'Not started',
      phone: '+91 98203 33456',
      joined: '6 Oct 2026',
      nextCheckin: '—',
      lastActive: '1 d ago',
    ),
    ClientSummary(
      id: 'kabir',
      name: 'Kabir Mehta',
      email: 'kabir.mehta@email.com',
      trainer: 'Aman Verma',
      goal: 'Strength',
      status: ClientStatus.active,
      thisWeek: 'Done',
      phone: '+91 98204 44567',
      joined: '20 Mar 2026',
      nextCheckin: 'Mon, 12 Oct',
      lastActive: '1 h ago',
      program: 'Strength Foundations',
      adherence: 92,
    ),
    ClientSummary(
      id: 'ananya',
      name: 'Ananya Iyer',
      email: 'ananya.iyer@email.com',
      trainer: 'Aman Verma',
      goal: 'Fat loss',
      status: ClientStatus.paused,
      thisWeek: 'Done',
      phone: '+91 98205 55678',
      joined: '8 Apr 2026',
      nextCheckin: 'Paused',
      lastActive: '9 d ago',
      program: 'Fat Loss Phase 1',
      adherence: 81,
    ),
    ClientSummary(
      id: 'sana',
      name: 'Sana Khan',
      email: 'sana.khan@email.com',
      trainer: 'No trainer',
      goal: 'Fat loss',
      status: ClientStatus.active,
      thisWeek: '40%',
      phone: '+91 98206 66789',
      joined: '2 Oct 2026',
      nextCheckin: 'Sun, 11 Oct',
      lastActive: '3 h ago',
      adherence: 70,
    ),
    ClientSummary(
      id: 'aisha',
      name: 'Aisha Sheikh',
      email: 'aisha.sheikh@email.com',
      trainer: 'Meera Shah',
      goal: 'Recomp',
      status: ClientStatus.atRisk,
      thisWeek: 'Done',
      phone: '+91 98207 77890',
      joined: '15 May 2026',
      nextCheckin: 'Today',
      lastActive: '1 d ago',
      program: 'Beginner Full Body',
      adherence: 52,
    ),
    ClientSummary(
      id: 'priya',
      name: 'Priya Reddy',
      email: 'priya.reddy@email.com',
      trainer: 'Meera Shah',
      goal: 'Fat loss',
      status: ClientStatus.atRisk,
      thisWeek: '20%',
      phone: '+91 98208 88901',
      joined: '9 Jun 2026',
      nextCheckin: 'Overdue',
      lastActive: '5 d ago',
      program: 'Fat Loss Phase 1',
      adherence: 34,
    ),
  ];

  static const trainers = <Trainer>[
    Trainer(id: 'vimal', name: 'Vimal', initials: 'V', color: AvatarColor.c3, email: 'vimal@trainwithvimal.app', focus: 'Head coach', clients: 8, capacity: 10, pendingCheckins: 1, adherence: 91, access: 'Owner', active: true, since: 'Jan 2024', isYou: true),
    Trainer(id: 'aman', name: 'Aman Verma', initials: 'AV', color: AvatarColor.c2, email: 'aman.verma@email.com', focus: 'Strength, fat loss', clients: 24, capacity: 30, pendingCheckins: 3, adherence: 84, access: 'Assigned clients', active: true, since: '12 Mar 2025'),
    Trainer(id: 'neha', name: 'Neha Joshi', initials: 'NJ', color: AvatarColor.c5, email: 'neha.joshi@email.com', focus: 'Women’s strength, rehab', clients: 21, capacity: 30, pendingCheckins: 0, adherence: 88, access: 'All clients', active: true, since: '5 Jun 2025'),
    Trainer(id: 'sahil', name: 'Sahil Kapoor', initials: 'SK', color: AvatarColor.c1, email: 'sahil.kapoor@email.com', focus: 'Fat loss, nutrition', clients: 18, capacity: 30, pendingCheckins: 1, adherence: 79, access: 'Assigned clients', active: true, since: '20 Aug 2025'),
    Trainer(id: 'karan', name: 'Karan Mehta', initials: 'KM', color: AvatarColor.c3, email: 'karan.mehta@email.com', focus: 'Muscle gain', clients: 30, capacity: 30, pendingCheckins: 4, adherence: 74, access: 'Assigned clients', active: true, since: '15 Nov 2025'),
    Trainer(id: 'ritu', name: 'Ritu Malhotra', initials: 'RM', color: AvatarColor.c4, email: 'ritu.m@email.com', focus: 'PCOS, fat loss', clients: 16, capacity: 25, pendingCheckins: 2, adherence: 82, access: 'Custom · 12 of 18', active: true, since: '2 Feb 2026'),
    Trainer(id: 'meera', name: 'Meera Shah', initials: 'MS', color: AvatarColor.c6, email: 'meera.shah@email.com', focus: 'Beginners, yoga', clients: 12, capacity: 25, pendingCheckins: 0, adherence: 86, access: 'Assigned clients', active: true, since: '1 Apr 2026'),
    Trainer(id: 'varun', name: 'Varun Kohli', initials: 'VK', color: AvatarColor.c2, email: 'varun.kohli@email.com', focus: 'Beginners, home workouts', clients: 0, capacity: 30, pendingCheckins: 0, adherence: 0, access: 'Assigned clients', active: false, since: '10 Jan 2026'),
  ];

  static ClientSummary? clientById(String id) {
    for (final c in clients) {
      if (c.id == id) return c;
    }
    return null;
  }

  static Trainer? trainerById(String id) {
    for (final t in trainers) {
      if (t.id == id) return t;
    }
    return null;
  }
}
