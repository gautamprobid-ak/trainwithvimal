import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/badges.dart';
import '../models/people.dart';
import '../models/trainer_app.dart';
import 'people_mock.dart';

/// Data from the trainer app designs (TrainerDashboard, TrainerClients,
/// TrainerCheckins, TrainerCalendar, TrainerMore, TrainerMe).
/// The dashboard shows Thu 8 Oct, 17:50. The calendar's "today" is Fri 9 Oct.
abstract final class TrainerMock {
  static const me = 'Aman Verma';
  static const meInitials = 'AV';

  // ---------------------------------------------------------------- clients

  /// Aman's clients in the design that are not in [PeopleMock] (or belong to
  /// another trainer there).
  static const _extraClients = <ClientSummary>[
    ClientSummary(
      id: 'sana',
      name: 'Sana Khan',
      email: 'sana.khan@email.com',
      trainer: me,
      goal: 'Fat loss',
      status: ClientStatus.active,
      thisWeek: '40%',
      phone: '+91 98206 66789',
      joined: '2 Oct 2026',
      nextCheckin: 'Sun, 11 Oct',
      lastActive: '3 h ago',
      program: 'Beginner Full Body',
      adherence: 70,
    ),
    ClientSummary(
      id: 'priya-nair',
      name: 'Priya Nair',
      email: 'priya.nair@email.com',
      trainer: me,
      goal: 'Recomp',
      status: ClientStatus.atRisk,
      thisWeek: 'Done',
      phone: '+91 98207 77890',
      joined: '15 May 2026',
      nextCheckin: 'Today',
      lastActive: '1 d ago',
      program: 'Fat Loss Phase 1',
      adherence: 52,
    ),
    ClientSummary(
      id: 'vikram',
      name: 'Vikram Singh',
      email: 'vikram.singh@email.com',
      trainer: me,
      goal: 'Fat loss',
      status: ClientStatus.atRisk,
      thisWeek: '20%',
      phone: '+91 98208 88901',
      joined: '9 Jun 2026',
      nextCheckin: 'Overdue',
      lastActive: '5 d ago',
      program: 'Strength Base',
      adherence: 34,
    ),
  ];

  /// "My clients" — the first 8 of Aman's 24 clients, in design order.
  static final List<ClientSummary> myClients = [
    ...PeopleMock.clients.where((c) => c.trainer == me),
    ..._extraClients,
  ];

  /// Totals shown in the header and tabs (the full list has 24 clients).
  static const clientTotal = 24;
  static const clientCapacity = 30;
  static const statusCounts = <ClientStatus?, int>{
    null: 24,
    ClientStatus.active: 21,
    ClientStatus.pending: 1,
    ClientStatus.paused: 1,
    ClientStatus.atRisk: 2,
  };

  /// Avatar colours used for each client in the trainer designs.
  static const _colors = <String, AvatarColor>{
    'Riya Sharma': AvatarColor.c1,
    'Rohan Kapoor': AvatarColor.c2,
    'Neha Jain': AvatarColor.c3,
    'Kabir Mehta': AvatarColor.c4,
    'Ananya Iyer': AvatarColor.c3,
    'Sana Khan': AvatarColor.c6,
    'Priya Nair': AvatarColor.c4,
    'Vikram Singh': AvatarColor.c3,
    'Aditya Rao': AvatarColor.c4,
    'Tanvi Desai': AvatarColor.c2,
    'Dev Malhotra': AvatarColor.c1,
    'Ishita Bose': AvatarColor.c2,
    'Vikram Rao': AvatarColor.c6,
  };

  static AvatarColor colorFor(String name) => _colors[name] ?? AvatarColor.of(name);

  /// Client id for profile links (falls back to a slug of the name).
  static String clientIdFor(String name) {
    for (final c in myClients) {
      if (c.name == name) return c.id;
    }
    return name.toLowerCase().replaceAll(' ', '-');
  }

  /// Client list filters (Filter menu).
  static const clientFilters = <(String, List<String>)>[
    ('Goal', ['Any', 'Fat loss', 'Muscle gain', 'Strength', 'Recomp', 'General fitness']),
    ('Onboarding', ['Any', 'Done', 'Not started', 'In progress']),
    ('Next check-in', ['Any', 'Today', 'This week', 'Overdue']),
    ('Joined', ['Any time', 'Last 30 days', 'This year']),
  ];

  // -------------------------------------------------------------- dashboard

  static const dashboardDate = 'Thu, 8 Oct · Trainer workspace';

  /// "Now" on the dashboard: 17:50.
  static const dashboardNow = 17 * 60 + 50;

  static const todaySessions = <TodaySession>[
    TodaySession(id: 's1', time: '07:00', minutes: 60, client: 'Rohan Kapoor', initials: 'RK', color: AvatarColor.c2, what: 'Push A · Gym floor', clientId: 'rohan'),
    TodaySession(id: 's2', time: '08:30', minutes: 45, client: 'Neha Jain', initials: 'NJ', color: AvatarColor.c5, what: 'Lower body · Gym floor', clientId: 'neha'),
    TodaySession(id: 's3', time: '18:30', minutes: 45, client: 'Riya Sharma', initials: 'RS', color: AvatarColor.c1, what: 'Upper A · Gym floor', clientId: 'riya'),
    TodaySession(id: 's4', time: '19:30', minutes: 60, client: 'Vikram Singh', initials: 'VS', color: AvatarColor.c3, what: 'Strength test · Gym floor', clientId: 'vikram'),
    TodaySession(id: 's5', time: '20:45', minutes: 30, client: 'Sana Khan', initials: 'SK', color: AvatarColor.c6, what: 'Form check · Video call', videoCall: true, clientId: 'sana'),
  ];

  /// Sessions already done when the dashboard opens.
  static const todayDone = {'s1', 's2'};

  static const notices = <TrainerNotice>[
    TrainerNotice('RS', AvatarColor.c1, 'Riya Sharma sent her weekly check-in', '2 days ago'),
    TrainerNotice('SK', AvatarColor.c6, 'It’s Sana Khan’s birthday today', '9:00'),
    TrainerNotice('V', AvatarColor.c3, 'Vimal gave you 2 new clients: Priya Nair, Aditya Rao', 'Yesterday'),
    TrainerNotice('RK', AvatarColor.c2, 'Rohan Kapoor swapped paneer for tofu at lunch', 'Yesterday'),
  ];

  static const attention = <AttentionItem>[
    AttentionItem(id: 'a1', name: 'Ananya Iyer', initials: 'AI', color: AvatarColor.c3, kind: AttentionKind.notLogging, why: 'No workout or meal logged in 7 days', action: AttentionAction.remind, clientId: 'ananya'),
    AttentionItem(id: 'a2', name: 'Priya Nair', initials: 'PN', color: AvatarColor.c4, kind: AttentionKind.missed, why: 'Missed 3 workouts this week · 1 of 4 done', action: AttentionAction.remind, clientId: 'priya-nair'),
    AttentionItem(id: 'a3', name: 'Riya Sharma', initials: 'RS', color: AvatarColor.c1, kind: AttentionKind.planEnding, why: 'Fat Loss Phase 1 ends on Sunday · nothing up next', action: AttentionAction.plan, clientId: 'riya'),
    AttentionItem(id: 'a4', name: 'Sana Khan', initials: 'SK', color: AvatarColor.c6, kind: AttentionKind.feelingLow, why: 'Energy 2 / 5 two weeks in a row', action: AttentionAction.open, clientId: 'sana'),
    AttentionItem(id: 'a5', name: 'Vikram Singh', initials: 'VS', color: AvatarColor.c3, kind: AttentionKind.missed, why: '2 of 4 workouts done · last one Monday', action: AttentionAction.remind, clientId: 'vikram'),
    AttentionItem(id: 'a6', name: 'Aditya Rao', initials: 'AR', color: AvatarColor.c4, kind: AttentionKind.planEnding, why: 'Meal plan ends in 3 days', action: AttentionAction.plan, clientId: 'aditya-rao'),
  ];

  static const thisWeek = <(String, String)>[
    ('Sessions held', '12 of 14'),
    ('Check-ins reviewed', '18 of 21'),
    ('Plans changed', '5'),
    ('New clients', '2 · Priya, Aditya'),
  ];

  static const tasks = <TrainerTask>[
    TrainerTask('t1', 'Call Ananya Iyer', 'From automation · Inactive for 7 days', due: 'Today', fromAutomation: true, dueToday: true),
    TrainerTask('t2', 'Wish Sana Khan a happy birthday', 'From automation · Birthday', due: 'Today', fromAutomation: true, dueToday: true),
    TrainerTask('t3', 'Send Riya her next plan', 'From automation · Plan ends', due: 'Sun', fromAutomation: true),
    TrainerTask('t4', 'Check Rohan’s deadlift video', 'Added by you', due: 'Tomorrow'),
    TrainerTask('t5', 'Ask Priya about her knee before leg day', 'Added by you', due: 'Fri'),
    TrainerTask('t6', 'Weigh-in reminder for Vikram', 'Added by you', due: 'Yesterday', late: true),
  ];

  /// Tasks already ticked when the dashboard opens.
  static const tasksDone = {'t6'};

  static const newSessionLengths = [30, 45, 60, 90];
  static const newSessionPlaces = ['Gym floor', 'Video call'];

  // --------------------------------------------------------------- check-ins

  static const quickReplies = ['Great week, keep going!', 'Let’s talk at your next session.', 'I’ve updated your plan.'];

  static const checkinKinds = <(String, String)>[
    ('all', 'All types'),
    ('Weekly', 'Weekly'),
    ('Daily', 'Daily'),
    ('Monthly progress', 'Monthly'),
  ];

  static const checkins = <TrainerCheckin>[
    TrainerCheckin(
      id: 'c1',
      client: 'Riya Sharma',
      initials: 'RS',
      color: AvatarColor.c1,
      kind: 'Weekly',
      line: 'Weight 61.8 kg · energy 3/5 · knees sore',
      age: '2 d',
      hours: 50,
      sent: 'Tue 6 Oct, 7:40 pm',
      plan: 'Fat Loss Phase 1 · week 6',
      kpis: [CheckinKpi('Weight', '61.8 kg'), CheckinKpi('Change', '−0.6 kg', Trend.up), CheckinKpi('Workouts', '3 of 4'), CheckinKpi('Meals on plan', '82%')],
      answers: [
        CheckinAnswer('Energy', '3 / 5', '4 / 5', Trend.down),
        CheckinAnswer('Sleep', '6 h a night', '6.5 h', Trend.down),
        CheckinAnswer('Hunger', '4 / 5', '3 / 5', Trend.down),
        CheckinAnswer('Stress', '3 / 5', '3 / 5'),
        CheckinAnswer('Water', '2.5 L a day', '2.5 L'),
        CheckinAnswer('Steps', '7,400 a day', '6,900', Trend.up),
      ],
      note: 'Knees hurt a bit on walking lunges. Lunch at office is hard on Thursdays.',
      photos: ['Front', 'Side', 'Back'],
      clientId: 'riya',
      lastPhotoDate: 'Tue 29 Sep',
      lastWeight: '62.4 kg',
    ),
    TrainerCheckin(
      id: 'c2',
      client: 'Rohan Kapoor',
      initials: 'RK',
      color: AvatarColor.c2,
      kind: 'Weekly',
      line: 'Weight 74.2 kg · bench up 2.5 kg',
      age: '1 d',
      hours: 26,
      sent: 'Wed 7 Oct, 3:50 pm',
      plan: 'Hypertrophy PPL · week 3',
      kpis: [CheckinKpi('Weight', '74.2 kg'), CheckinKpi('Change', '+0.3 kg', Trend.up), CheckinKpi('Workouts', '5 of 5'), CheckinKpi('Meals on plan', '90%')],
      answers: [
        CheckinAnswer('Energy', '4 / 5', '4 / 5'),
        CheckinAnswer('Sleep', '7.5 h a night', '7 h', Trend.up),
        CheckinAnswer('Hunger', '3 / 5', '3 / 5'),
        CheckinAnswer('Stress', '2 / 5', '3 / 5', Trend.up),
        CheckinAnswer('Water', '3 L a day', '3 L'),
        CheckinAnswer('Steps', '9,100 a day', '8,800', Trend.up),
      ],
      note: 'Bench felt strong. Can we add one more arm day?',
      photos: ['Front', 'Side'],
      clientId: 'rohan',
      lastPhotoDate: 'Wed 30 Sep',
      lastWeight: '73.9 kg',
    ),
    TrainerCheckin(
      id: 'c3',
      client: 'Sana Khan',
      initials: 'SK',
      color: AvatarColor.c6,
      kind: 'Weekly',
      line: 'Weight 68.4 kg · sleep 5 h',
      age: '6 h',
      hours: 6,
      sent: 'Today, 11:45 am',
      plan: 'Beginner Full Body · week 2',
      kpis: [CheckinKpi('Weight', '68.4 kg'), CheckinKpi('Change', '−0.2 kg', Trend.up), CheckinKpi('Workouts', '2 of 3'), CheckinKpi('Meals on plan', '71%', Trend.down)],
      answers: [
        CheckinAnswer('Energy', '2 / 5', '3 / 5', Trend.down),
        CheckinAnswer('Sleep', '5 h a night', '6 h', Trend.down),
        CheckinAnswer('Hunger', '3 / 5', '3 / 5'),
        CheckinAnswer('Stress', '4 / 5', '3 / 5', Trend.down),
        CheckinAnswer('Water', '1.5 L a day', '2 L', Trend.down),
        CheckinAnswer('Steps', '4,800 a day', '5,600', Trend.down),
      ],
      note: 'Exams this week, very tired.',
      photos: [],
      clientId: 'sana',
    ),
    TrainerCheckin(
      id: 'c4',
      client: 'Aditya Rao',
      initials: 'AR',
      color: AvatarColor.c4,
      kind: 'Monthly progress',
      line: 'Waist −2 cm · 4 photos',
      age: '3 h',
      hours: 3,
      sent: 'Today, 2:40 pm',
      plan: 'Strength Base · week 8',
      kpis: [CheckinKpi('Weight', '82.0 kg'), CheckinKpi('Change', '−1.8 kg', Trend.up), CheckinKpi('Workouts', '14 of 16'), CheckinKpi('Meals on plan', '86%')],
      answers: [
        CheckinAnswer('Waist', '88 cm', '90 cm', Trend.up),
        CheckinAnswer('Chest', '101 cm', '101 cm'),
        CheckinAnswer('Hips', '99 cm', '100 cm', Trend.up),
        CheckinAnswer('Energy', '4 / 5', '4 / 5'),
        CheckinAnswer('Sleep', '7 h a night', '7 h'),
        CheckinAnswer('Steps', '8,200 a day', '7,500', Trend.up),
      ],
      note: '',
      photos: ['Front', 'Side', 'Back', 'Flex'],
      clientId: 'aditya-rao',
      lastPhotoDate: 'Thu 10 Sep',
      lastWeight: '83.8 kg',
    ),
    TrainerCheckin(
      id: 'c5',
      client: 'Neha Jain',
      initials: 'NJ',
      color: AvatarColor.c5,
      kind: 'Weekly',
      line: 'Weight 58.9 kg · all workouts done',
      age: 'Yesterday',
      hours: 30,
      sent: 'Wed 7 Oct, 9:10 am',
      plan: 'Women’s Strength · week 4',
      kpis: [CheckinKpi('Weight', '58.9 kg'), CheckinKpi('Change', '−0.4 kg', Trend.up), CheckinKpi('Workouts', '4 of 4'), CheckinKpi('Meals on plan', '88%')],
      answers: [
        CheckinAnswer('Energy', '4 / 5', '3 / 5', Trend.up),
        CheckinAnswer('Sleep', '7 h a night', '7 h'),
        CheckinAnswer('Hunger', '2 / 5', '3 / 5', Trend.up),
        CheckinAnswer('Stress', '2 / 5', '2 / 5'),
        CheckinAnswer('Water', '3 L a day', '2.5 L', Trend.up),
        CheckinAnswer('Steps', '10,200 a day', '9,000', Trend.up),
      ],
      note: 'Loving the new squat routine!',
      photos: ['Front', 'Side'],
      reviewedReply: 'Great week, keep going! Next week we add 2.5 kg on squats.',
      reviewedWhen: 'yesterday, 6:05 pm',
      reviewed: true,
      clientId: 'neha',
      lastPhotoDate: 'Wed 30 Sep',
      lastWeight: '59.3 kg',
    ),
    TrainerCheckin(
      id: 'c6',
      client: 'Vikram Singh',
      initials: 'VS',
      color: AvatarColor.c3,
      kind: 'Daily',
      line: 'Slept 6 h · skipped evening walk',
      age: 'Yesterday',
      hours: 28,
      sent: 'Wed 7 Oct, 10:30 pm',
      plan: 'Strength Base · week 3',
      kpis: [CheckinKpi('Sleep', '6 h'), CheckinKpi('Energy', '3 / 5'), CheckinKpi('Workout', 'Rest day'), CheckinKpi('Steps', '5,100', Trend.down)],
      answers: [
        CheckinAnswer('Mood', 'Okay', 'Good', Trend.down),
        CheckinAnswer('Water', '2 L', '2.5 L', Trend.down),
        CheckinAnswer('Meals on plan', '3 of 4', '4 of 4', Trend.down),
        CheckinAnswer('Soreness', 'Low', 'Medium', Trend.up),
      ],
      note: 'Long day at work.',
      photos: [],
      reviewedReply: 'Rest is fine. Try a 15 min walk after dinner tomorrow.',
      reviewedWhen: 'today, 8:15 am',
      reviewed: true,
      clientId: 'vikram',
    ),
    TrainerCheckin(
      id: 'c7',
      client: 'Priya Nair',
      initials: 'PN',
      color: AvatarColor.c4,
      kind: 'Weekly',
      line: 'Weight 64.1 kg · knee pain on squats',
      age: '2 d',
      hours: 52,
      sent: 'Tue 6 Oct, 6:20 pm',
      plan: 'Fat Loss Phase 1 · week 2',
      kpis: [CheckinKpi('Weight', '64.1 kg'), CheckinKpi('Change', '+0.2 kg', Trend.down), CheckinKpi('Workouts', '1 of 4', Trend.down), CheckinKpi('Meals on plan', '64%', Trend.down)],
      answers: [
        CheckinAnswer('Energy', '3 / 5', '3 / 5'),
        CheckinAnswer('Sleep', '6.5 h a night', '7 h', Trend.down),
        CheckinAnswer('Hunger', '4 / 5', '4 / 5'),
        CheckinAnswer('Stress', '4 / 5', '3 / 5', Trend.down),
        CheckinAnswer('Water', '2 L a day', '2 L'),
        CheckinAnswer('Steps', '6,000 a day', '6,400', Trend.down),
      ],
      note: 'Right knee hurts on squats, so I skipped leg day.',
      photos: [],
      reviewedReply: 'Thanks for telling me. I swapped squats for leg press, let’s check your knee on Friday.',
      reviewedWhen: 'Tue 6 Oct, 9:00 pm',
      reviewed: true,
      clientId: 'priya-nair',
    ),
    TrainerCheckin(
      id: 'c8',
      client: 'Tanvi Desai',
      initials: 'TD',
      color: AvatarColor.c2,
      kind: 'Monthly progress',
      line: 'Weight −1.2 kg this month',
      age: '5 d',
      hours: 120,
      sent: 'Sat 3 Oct, 8:00 am',
      plan: 'Recomp 3-day · week 9',
      kpis: [CheckinKpi('Weight', '57.3 kg'), CheckinKpi('Change', '−1.2 kg', Trend.up), CheckinKpi('Workouts', '11 of 12'), CheckinKpi('Meals on plan', '84%')],
      answers: [
        CheckinAnswer('Waist', '74 cm', '76 cm', Trend.up),
        CheckinAnswer('Hips', '94 cm', '95 cm', Trend.up),
        CheckinAnswer('Energy', '2 / 5', '3 / 5', Trend.down),
        CheckinAnswer('Sleep', '6 h a night', '7 h', Trend.down),
      ],
      note: 'Feeling a bit low on energy lately.',
      photos: ['Front', 'Side', 'Back'],
      reviewedReply: 'Good progress! Let’s add 100 kcal on training days for energy.',
      reviewedWhen: 'Sat 3 Oct, 1:30 pm',
      reviewed: true,
      clientId: 'tanvi-desai',
      lastPhotoDate: 'Thu 3 Sep',
      lastWeight: '58.5 kg',
    ),
  ];

  // ---------------------------------------------------------------- calendar

  /// Monday of the current week (5 Oct 2026). Today is Friday (index 4).
  static final weekStart = DateTime(2026, 10, 5);
  static const todayIndex = 4;

  /// Red "now" line: 18:10.
  static const nowMinute = 1090;

  static const calendarSessions = <CalSession>[
    CalSession(id: 's1', day: 0, start: 420, kind: CalKind.session, client: 'Riya Sharma', trainer: me, minutes: 60, place: 'Andheri gym floor', note: 'Check the left knee before squats', done: true, bookedBy: me),
    CalSession(id: 's2', day: 0, start: 540, kind: CalKind.call, client: 'Rohan Kapoor', trainer: me, minutes: 15, place: '', note: '', done: true, bookedBy: me),
    CalSession(id: 's3', day: 0, start: 600, kind: CalKind.review, client: 'Sana Khan', trainer: me, minutes: 30, place: '', note: '', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's4', day: 0, start: 1080, kind: CalKind.session, client: 'Vikram Rao', trainer: 'Sahil Kapoor', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Sahil Kapoor'),
    CalSession(id: 's5', day: 1, start: 450, kind: CalKind.session, client: 'Kabir Mehta', trainer: me, minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: me),
    CalSession(id: 's6', day: 1, start: 660, kind: CalKind.review, client: 'Ananya Iyer', trainer: me, minutes: 30, place: '', note: 'Restart plan after the pause', done: true, bookedBy: 'Ritu Malhotra'),
    CalSession(id: 's7', day: 1, start: 1110, kind: CalKind.session, client: 'Aisha Sheikh', trainer: 'Meera Shah', minutes: 60, place: 'Yoga room', note: '', done: true, bookedBy: 'Meera Shah'),
    CalSession(id: 's8', day: 2, start: 420, kind: CalKind.session, client: 'Riya Sharma', trainer: me, minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: me),
    CalSession(id: 's9', day: 2, start: 435, kind: CalKind.session, client: 'Arjun Nair', trainer: 'Karan Mehta', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Karan Mehta'),
    CalSession(id: 's10', day: 2, start: 900, kind: CalKind.call, client: 'Pooja Nair', trainer: 'Vimal', minutes: 15, place: '', note: 'Welcome call', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's11', day: 3, start: 480, kind: CalKind.review, client: 'Dev Malhotra', trainer: me, minutes: 30, place: '', note: 'New trainer, go over his program', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's12', day: 3, start: 1140, kind: CalKind.session, client: 'Vikram Rao', trainer: 'Sahil Kapoor', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Sahil Kapoor'),
    CalSession(id: 's13', day: 4, start: 420, kind: CalKind.session, client: 'Kabir Mehta', trainer: me, minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: me),
    CalSession(id: 's14', day: 4, start: 600, kind: CalKind.call, client: 'Riya Sharma', trainer: me, minutes: 15, place: '', note: 'Week 6 check-in questions', done: true, bookedBy: me),
    CalSession(id: 's15', day: 4, start: 1140, kind: CalKind.session, client: 'Riya Sharma', trainer: me, minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: me),
    CalSession(id: 's16', day: 4, start: 1215, kind: CalKind.call, client: 'Ishita Bose', trainer: me, minutes: 15, place: '', note: '', done: false, bookedBy: me),
    CalSession(id: 's17', day: 4, start: 1200, kind: CalKind.session, client: 'Aisha Sheikh', trainer: 'Meera Shah', minutes: 60, place: 'Yoga room', note: '', done: false, bookedBy: 'Meera Shah'),
    CalSession(id: 's18', day: 5, start: 540, kind: CalKind.session, client: 'Rohan Kapoor', trainer: me, minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: me),
    CalSession(id: 's19', day: 5, start: 600, kind: CalKind.review, client: 'Sana Khan', trainer: me, minutes: 30, place: '', note: '', done: false, bookedBy: 'Neha Joshi'),
    CalSession(id: 's20', day: 5, start: 660, kind: CalKind.session, client: 'Arjun Nair', trainer: 'Karan Mehta', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Karan Mehta'),
  ];

  /// Clients Aman can book (New session › Client).
  static const bookableClients = [
    'Riya Sharma', 'Rohan Kapoor', 'Kabir Mehta', 'Sana Khan', 'Priya Nair',
    'Vikram Singh', 'Ananya Iyer', 'Dev Malhotra', 'Ishita Bose', 'Neha Jain',
  ];

  static const clientPlans = <String, String>{
    'Riya Sharma': 'Fat loss · week 6 of 12',
    'Rohan Kapoor': 'Muscle gain · week 3 of 16',
    'Kabir Mehta': 'Strength · week 9 of 12',
    'Sana Khan': 'Fat loss · week 4 of 12',
    'Ananya Iyer': 'Fat loss · paused at week 5',
    'Dev Malhotra': 'General fitness · week 1 of 8',
    'Ishita Bose': 'Recomp · week 2 of 12',
  };

  /// Aman's working hours, Monday first.
  static const workingHours = <WorkDay>[
    WorkDay(true, 390, 1200),
    WorkDay(true, 390, 1200),
    WorkDay(true, 390, 1200),
    WorkDay(true, 390, 1200),
    WorkDay(true, 390, 1260),
    WorkDay(true, 480, 780),
    WorkDay.off(),
  ];

  // ---------------------------------------------------------------- me page

  static const meStats = <TrainerStat>[
    TrainerStat(Icons.group_rounded, 'My clients', '24 / 30', '6 spots free'),
    TrainerStat(Icons.assignment_rounded, 'Check-ins to review', '3', 'Oldest from yesterday'),
    TrainerStat(Icons.trending_up_rounded, 'Avg adherence', '84%', '+2% vs last month', good: true),
    TrainerStat(Icons.schedule_rounded, 'Avg reply time', '3 h', 'Team average 4 h', good: true),
  ];

  static const specialities = ['Strength', 'Fat loss', 'Powerlifting'];

  static const professional = <(String, String)>[
    ('Experience', '6 years · since 2020'),
    ('Trains', 'Gym and online'),
    ('Languages', 'Hindi, English'),
    ('Gender', 'Male'),
    ('Best with', 'Beginners and busy office workers'),
  ];

  static const bio =
      'Former state-level powerlifter. Focuses on simple strength plans and steady fat loss. Likes to keep check-ins short and reply the same day.';
  static const shortBio = 'Former state-level powerlifter. Focuses on simple strength plans and steady fat loss.';

  static const socials = <(IconData, String, String)>[
    (Icons.camera_alt_rounded, '@aman.lifts', '12.4k'),
    (Icons.smart_display_rounded, 'Aman Verma Fitness', '3.1k'),
    (Icons.language_rounded, 'amanlifts.in', ''),
  ];

  static const contact = <(String, String)>[
    ('Mobile', '+91 98201 55432'),
    ('Email', 'aman.verma@email.com'),
    ('Joined', '12 Mar 2025'),
    ('Last login', 'Today, 9:40 am · Android app'),
    ('Most clients', '30'),
  ];

  static const meWeek = <(String, String)>[
    ('Check-ins reviewed', '18 of 21'),
    ('Avg reply time', '3 h'),
    ('Plans changed', '5'),
    ('Sessions held', '12'),
  ];

  static const needsYou = <NeedsYou>[
    NeedsYou('Vikram Rao', 'VR', AvatarColor.c6, 'No check-in for 4 days', 'At risk', BadgeTone.bad),
    NeedsYou('Dev Malhotra', 'DM', AvatarColor.c1, 'Missed 3 workouts this week', 'At risk', BadgeTone.bad),
    NeedsYou('Neha Jain', 'NJ', AvatarColor.c3, 'Waiting for her first plan', 'New', BadgeTone.info),
  ];

  static const permissions = <PermissionGroup>[
    PermissionGroup('Clients', [
      Permission('View assigned clients', 'Profile, plans and logs', true),
      Permission('View all clients', 'Every client of the gym', false),
      Permission('Approve sign-ups', 'Only people invited by you', false),
      Permission('Pause or resume clients', '', false),
    ]),
    PermissionGroup('Training', [
      Permission('Create and edit programs', 'For your clients', true),
      Permission('Use gym templates', 'Copy master programs', true),
      Permission('Edit gym templates', 'Changes master programs', false),
      Permission('Add custom exercises', '', true),
    ]),
    PermissionGroup('Nutrition', [
      Permission('Meal plans', 'Make and change', true),
      Permission('Add foods and recipes', '', true),
      Permission('Supplement plans', '', true),
      Permission('See food logs', '', true),
    ]),
    PermissionGroup('Check-ins', [
      Permission('Review daily check-ins', '', true),
      Permission('Review weekly check-ins', '', true),
      Permission('Edit check-in forms', 'Changes master forms', false),
      Permission('Progress photos', '', true),
    ]),
    PermissionGroup('Schedule', [
      Permission('Manage own calendar', '', true),
      Permission('Book sessions for clients', '', true),
    ]),
  ];

  static const accessAsks = <AccessAsk>[
    AccessAsk('all', 'See all clients', 'To cover other trainers'),
    AccessAsk('tpl', 'Edit gym templates', 'Change master programs and meal plans'),
    AccessAsk('forms', 'Edit check-in forms', 'Change the gym’s forms'),
    AccessAsk('pause', 'Pause or resume clients', ''),
  ];

  static const activity = <ActivityDay>[
    ActivityDay('Today', 0, [
      ActivityItem(ActivityKind.checkin, 'Reviewed', 'Riya Sharma', '’s daily check-in', '9:52 am', note: 'Replied: “Good sleep this week. Keep steps above 8k.”'),
      ActivityItem(ActivityKind.login, 'Logged in', '', '', '9:40 am', note: 'Android app'),
    ]),
    ActivityDay('Yesterday', 1, [
      ActivityItem(ActivityKind.plan, 'Changed', 'Riya Sharma', '’s Thursday leg day', '6:20 pm', from: 'Walking lunges', to: 'Split squats'),
      ActivityItem(ActivityKind.checkin, 'Reviewed 6 weekly check-ins', '', '', '5:05 pm', note: '2 of them need a plan change'),
      ActivityItem(ActivityKind.client, 'Got a new client,', 'Neha Jain', '', '11:40 am', note: 'Assigned by Vimal from Approvals'),
    ]),
    ActivityDay('Mon, 5 Oct', 4, [
      ActivityItem(ActivityKind.plan, 'Made a meal plan for', 'Ishita Bose', '', '4:30 pm', note: '1,700 kcal, high protein'),
      ActivityItem(ActivityKind.client, 'Moved', 'Dev Malhotra', ' to a new program', '7:45 am', from: 'Beginner Full Body', to: 'Strength Base'),
    ]),
    ActivityDay('Fri, 2 Oct', 7, [
      ActivityItem(ActivityKind.checkin, 'Reviewed', 'Vikram Rao', '’s weekly check-in', '6:40 pm', note: 'Asked him to log meals daily'),
      ActivityItem(ActivityKind.plan, 'Changed', 'Kabir Mehta', '’s rest time', '10:10 am', from: '60 s', to: '90 s'),
    ]),
    ActivityDay('Mon, 28 Sep', 11, [
      ActivityItem(ActivityKind.client, 'Got a new client,', 'Dev Malhotra', '', '12:30 pm', note: 'Moved from Karan Mehta (full)'),
      ActivityItem(ActivityKind.login, 'Logged in', '', '', '8:05 am', note: 'Web, Chrome'),
    ]),
    ActivityDay('Sat, 19 Sep', 20, [
      ActivityItem(ActivityKind.plan, 'Started a new program for', 'Vikram Rao', '', '9:00 am', note: 'Fat Loss Phase 1, 8 weeks'),
    ]),
    ActivityDay('Sun, 30 Aug', 40, [
      ActivityItem(ActivityKind.checkin, 'Reviewed 9 weekly check-ins', '', '', '8:30 pm', note: 'All replied the same day'),
    ]),
  ];

  static const activityRanges = <(String, int)>[
    ('Today', 0),
    ('Last 7 days', 7),
    ('Last 30 days', 30),
    ('Last 3 months', 90),
    ('All time', 99999),
  ];

  static const docs = <TrainerDoc>[
    TrainerDoc(name: 'ACE Certified Personal Trainer', by: 'American Council on Exercise', type: DocType.cert, kind: 'Certificate', issued: 'Jun 2021', validTill: 'Jun 2027', status: 'Verified', tone: BadgeTone.ok, file: 'ace-cpt-aman.pdf', clientsSee: true, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 412 KB'),
    TrainerDoc(name: 'Precision Nutrition Level 1', by: 'Precision Nutrition', type: DocType.cert, kind: 'Certificate', issued: 'Feb 2023', validTill: 'No end date', status: 'Verified', tone: BadgeTone.ok, file: 'pn-l1.pdf', clientsSee: true, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 380 KB'),
    TrainerDoc(name: 'First aid and CPR', by: 'Indian Red Cross', type: DocType.cert, kind: 'Certificate', issued: 'Nov 2024', validTill: 'Nov 2026', status: 'Expires in 33 days', tone: BadgeTone.warn, file: 'first-aid-2024.jpg', clientsSee: true, uploaded: '2 Dec 2024 by Aman', size: 'JPG, 1.2 MB', expiring: true),
    TrainerDoc(name: 'Diploma in Sports Nutrition', by: 'K11 Academy', type: DocType.cert, kind: 'Certificate', issued: 'Aug 2020', validTill: 'No end date', status: 'Not checked', tone: BadgeTone.neutral, file: 'k11-diploma.pdf', clientsSee: false, uploaded: 'Yesterday by Aman', size: 'PDF, 650 KB'),
    TrainerDoc(name: 'Aadhaar card', by: 'UIDAI', type: DocType.id, kind: 'ID proof', issued: 'Mar 2025', validTill: 'No end date', status: 'Verified', tone: BadgeTone.ok, file: 'aadhaar-aman.pdf', clientsSee: false, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 220 KB'),
    TrainerDoc(name: 'Trainer agreement', by: 'Train With Vimal', type: DocType.file, kind: 'Contract', issued: '12 Mar 2025', validTill: '11 Mar 2027', status: 'Signed', tone: BadgeTone.ok, file: 'agreement-signed.pdf', clientsSee: false, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 96 KB'),
  ];

  static const visibility = <VisibilityRow>[
    VisibilityRow('name', 'Photo and name', 'Clients always see this', locked: true),
    VisibilityRow('spec', 'Speciality', 'Strength, Fat loss, Powerlifting'),
    VisibilityRow('exp', 'Experience', '6 years'),
    VisibilityRow('about', 'About', 'Short bio'),
    VisibilityRow('lang', 'Languages', 'Hindi, English'),
    VisibilityRow('certs', 'Certificates', 'Only verified ones you allow'),
    VisibilityRow('soc', 'Social media', 'Instagram, YouTube'),
    VisibilityRow('mob', 'Mobile number', 'Only you and admins see it', on: false),
    VisibilityRow('mail', 'Email', '', on: false),
  ];

  static const devices = <LoginDevice>[
    LoginDevice('d1', 'Android app · Pixel 7', 'Mumbai · active now', isThis: true, phone: true),
    LoginDevice('d2', 'Chrome on Windows', 'Mumbai · yesterday, 6:10 pm'),
    LoginDevice('d3', 'Safari on iPad', 'Pune · Sat 3 Oct'),
  ];

  static const notifPrefs = <NotifPref>[
    NotifPref('ci', 'New check-in', 'When a client sends a check-in', true),
    NotifPref('miss', 'Missed workouts', 'When a client misses 2 in a row', true),
    NotifPref('new', 'New client', 'When the admin gives you a client', true),
    NotifPref('sess', 'Session reminders', '30 minutes before each session', true),
    NotifPref('sum', 'Daily summary', 'Email at 8:00 am with your day', false),
    NotifPref('news', 'Gym news', 'Notices from Vimal', true),
  ];
}
