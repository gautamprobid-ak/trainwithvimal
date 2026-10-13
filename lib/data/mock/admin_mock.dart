import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../models/admin.dart';
import '../models/people.dart';
import 'people_mock.dart';

/// Data from the admin (owner) designs: dashboard, clients, approvals,
/// calendar, trainers and activity log. Today in the design is Fri, 9 Oct 2026.
abstract final class AdminMock {
  // ------------------------------------------------------------- Dashboard
  static const dashboardStats = [
    ('Active clients', '142', '+8 this month', true),
    ('Pending approvals', '5', 'Oldest waiting 2 days', null),
    ('Check-in rate', '86%', '−2% vs last week', false),
    ('Avg adherence', '81%', '+3% vs last week', true),
  ];

  static const glance = [
    GlanceTile('156', 'Clients', '142 active · 14 paused'),
    GlanceTile('8', 'Trainers', '1 over capacity', warn: true),
    GlanceTile('12', 'Check-ins to review', '4 waiting over 48 h', warn: true),
    GlanceTile('5', 'Onboarding pending', '2 forms not complete'),
    GlanceTile('4', 'Nutrition plans pending', 'Clients without a meal plan'),
    GlanceTile('2', 'Programs ending', 'This week · plan what is next'),
  ];

  static const needsAction = [
    NeedsAction('a1', ActionKind.approval, '5 sign-ups waiting', "Ishaan and Rohit are ready · Pooja's health form is not done", 'Review'),
    NeedsAction('a2', ActionKind.checkin, '4 check-ins waiting over 48 hours', 'Aman Verma (3) · Arjun Rao (1)', 'Open'),
    NeedsAction('a3', ActionKind.client, '3 clients need a trainer', 'Joined this week · not assigned yet', 'Assign'),
    NeedsAction('a4', ActionKind.trainer, 'Arjun Rao is over capacity', '24 of 20 clients · move 4 to another trainer', 'Rebalance'),
    NeedsAction('a5', ActionKind.program, '2 programs end this week', 'Riya Sharma · Kabir Mehta · pick what comes next', 'Plan'),
    NeedsAction('a6', ActionKind.checkin, 'Aisha Sheikh flagged low energy', 'Energy 2/5 for two weeks · Meera Shah', 'Open'),
    NeedsAction('a7', ActionKind.client, '2 clients have not logged in 7 days', 'Ananya Iyer · Dev Patel', 'View'),
    NeedsAction('a8', ActionKind.approval, 'Neha Jain asked to change trainer', 'From Aman Verma · reason: timings', 'Review'),
    NeedsAction('a9', ActionKind.trainer, 'Meera Shah has 5 replies pending', 'Oldest from yesterday 7 pm', 'Open'),
  ];

  static const atRisk = [
    RiskClient('PR', AvatarColor.c5, 'Priya Reddy', 'No workout for 5 days · Meera Shah'),
    RiskClient('AS', AvatarColor.c2, 'Aisha Sheikh', 'Energy 2/5 for two weeks · Meera Shah'),
    RiskClient('AI', AvatarColor.c3, 'Ananya Iyer', 'Paused 9 days ago · Aman Verma'),
    RiskClient('DP', AvatarColor.c6, 'Dev Patel', 'No login for 7 days · Arjun Rao'),
    RiskClient('KM', AvatarColor.c1, 'Kabir Mehta', 'Missed 2 check-ins · Arjun Rao'),
    RiskClient('NJ', AvatarColor.c4, 'Neha Jain', 'Adherence 42% this week · Aman Verma'),
    RiskClient('RS', AvatarColor.c2, 'Riya Sharma', 'Program ends in 2 days, nothing next · Sahil Kapoor'),
  ];

  static const trainerPerformance = [
    TrainerPerformance('AR', AvatarColor.c3, 'Arjun Rao', 24, 71, '5.1 h'),
    TrainerPerformance('NK', AvatarColor.c2, 'Nikhil Kumar', 16, 74, '3.0 h'),
    TrainerPerformance('MS', AvatarColor.c5, 'Meera Shah', 15, 78, '2.4 h'),
    TrainerPerformance('PG', AvatarColor.c4, 'Pooja Gupta', 11, 80, '1.9 h'),
    TrainerPerformance('AV', AvatarColor.c1, 'Aman Verma', 18, 84, '1.2 h'),
    TrainerPerformance('RT', AvatarColor.c6, 'Rahul Tiwari', 9, 86, '1.0 h'),
    TrainerPerformance('SK', AvatarColor.c6, 'Sahil Kapoor', 12, 88, '0.8 h'),
    TrainerPerformance('DS', AvatarColor.c5, 'Divya Singh', 14, 90, '0.6 h'),
  ];

  static const recentActivity = [
    MiniActivity('AV', AvatarColor.c1, 'Aman Verma', "changed rest to 90 s in Rohan's Push day", '14m'),
    MiniActivity('RK', AvatarColor.c2, 'Rohan Kapoor', 'swapped paneer for tofu at lunch', '38m'),
    MiniActivity('S', AvatarColor.c4, 'System', 'sent check-in reminder to 18 clients', '1h'),
    MiniActivity('V', AvatarColor.c1, 'Vimal', 'approved Sana Khan', '2h'),
    MiniActivity('AR', AvatarColor.c3, 'Arjun Rao', 'added a note for Kabir Mehta', '3h'),
  ];

  // --------------------------------------------------------------- Clients
  /// Avatar colours used for each client in the design's table.
  static const clientColors = {
    'riya': AvatarColor.c1,
    'rohan': AvatarColor.c2,
    'neha': AvatarColor.c3,
    'kabir': AvatarColor.c4,
    'ananya': AvatarColor.c3,
    'sana': AvatarColor.c6,
    'aisha': AvatarColor.c2,
    'priya': AvatarColor.c5,
  };

  static AvatarColor colorFor(ClientSummary c) => clientColors[c.id] ?? AvatarColor.of(c.initials);

  static const clientFilters = [
    FilterGroup('tr', 'Trainer', ['Anyone', 'Aman Verma', 'Meera Shah', 'Neha Joshi', 'Sahil Kapoor', 'No trainer']),
    FilterGroup('goal', 'Goal', ['Any', 'Fat loss', 'Muscle gain', 'Strength', 'Recomp', 'General fitness']),
    FilterGroup('onb', 'Onboarding', ['Any', 'Done', 'Not started', 'In progress']),
    FilterGroup('ci', 'Next check-in', ['Any', 'Today', 'This week', 'Overdue']),
    FilterGroup('joined', 'Joined', ['Any time', 'Last 30 days', 'This year']),
  ];

  /// Trainers you can move a client to (Change trainer).
  static const trainerNames = ['Aman Verma', 'Neha Joshi', 'Sahil Kapoor', 'Karan Mehta', 'Ritu Malhotra', 'Meera Shah', 'Vimal'];

  // ---------------------------------------------------------- Invite links
  static const inviteLinks = [
    InviteLink(code: 'AMAN-4821', name: '', trainer: 'Aman Verma', made: 'Made 9 Oct', till: '30 days · till 8 Nov', tillShort: 'till 8 Nov', max: 'No limit', plan: 'Quarterly plan', joined: 6, waiting: 1, status: LinkStatus.on),
    InviteLink(code: 'VIMAL-0007', name: 'Website', trainer: 'Vimal', made: 'Made 1 Jan', till: 'No end date', tillShort: 'no end date', max: 'No limit', plan: 'Quarterly plan', joined: 41, waiting: 1, status: LinkStatus.on),
    InviteLink(code: 'NEHA-3307', name: 'Instagram · Sept', trainer: 'Neha Joshi', made: 'Made 20 Sep', till: '30 days · till 20 Oct', tillShort: 'till 20 Oct', max: '20 people · 3 used', plan: 'Monthly plan', joined: 3, waiting: 1, status: LinkStatus.on),
    InviteLink(code: 'SAHIL-1190', name: '', trainer: 'Sahil Kapoor', made: 'Made 15 Sep', till: '30 days · till 15 Oct', tillShort: 'till 15 Oct', max: 'No limit', plan: 'Monthly plan', joined: 9, waiting: 1, status: LinkStatus.on),
    InviteLink(code: 'MEERA-2210', name: 'Yoga batch', trainer: 'Meera Shah', made: 'Made 1 Oct', till: '7 days · till 8 Oct', tillShort: 'ended 8 Oct', max: '10 people · 4 used', plan: 'Quarterly plan', joined: 4, waiting: 1, status: LinkStatus.ended),
  ];

  static const newInviteLink = InviteLink(code: 'AMAN-5530', name: 'Instagram · October', trainer: 'Aman Verma', made: 'Made today', till: '30 days · till 8 Nov', tillShort: 'till 8 Nov', max: 'No limit', plan: 'Quarterly plan', joined: 0, waiting: 0, status: LinkStatus.on);

  /// 12 × 12 QR pattern drawn in the invite link card.
  static const qr =
      '110010101111110001101111110000001111000110001100100101001011010010100100110001100010000000000001000110001101110101001011110010100101110001100010';

  // ------------------------------------------------------------- Approvals
  static const signups = [
    SignupRequest(
      id: 'pooja', name: 'Pooja Nair', initials: 'PN', color: AvatarColor.c5, email: 'pooja.nair@email.com', phone: '99300 45612',
      invitedBy: 'Vimal', inviterInitials: 'V', inviterColor: AvatarColor.c3, code: 'VIMAL-0007', plan: 'Quarterly plan', device: 'Web', steps: 3,
      wait: '2 days', when: 'Signed up Wed, 7 Oct, 9:15 am', waitLevel: WaitLevel.late, hoursWaiting: 50,
      answers: [('Goal', 'Lose fat'), ('Body', '82 kg · 158 cm · 41 years'), ('Trains', 'Home · 3 days a week · new'), ('Food', 'Vegetarian')],
      healthNote: 'High blood pressure, on medicine. Ask for a doctor note before hard sessions.',
    ),
    SignupRequest(
      id: 'ishaan', name: 'Ishaan Mehta', initials: 'IM', color: AvatarColor.c1, email: 'ishaan.m@email.com', phone: '98200 11223',
      invitedBy: 'Aman Verma', inviterInitials: 'AV', inviterColor: AvatarColor.c2, code: 'AMAN-4821', plan: 'Monthly plan', device: 'iPhone app', steps: 5,
      wait: '1 day', when: 'Signed up yesterday, 8:10 pm', waitLevel: WaitLevel.old, hoursWaiting: 26,
      answers: [('Goal', 'Build muscle'), ('Body', '68 kg · 176 cm · 27 years'), ('Trains', 'Gym · 5 days a week · 1 year'), ('Food', 'Eats eggs and chicken')],
      healthNote: '',
    ),
    SignupRequest(
      id: 'neha', name: 'Neha Jain', initials: 'NJ', color: AvatarColor.c4, email: 'neha.jain@email.com', phone: '98765 00004',
      invitedBy: 'Meera Shah', inviterInitials: 'MS', inviterColor: AvatarColor.c6, code: 'MEERA-2210', plan: 'Quarterly plan', device: 'Android app', steps: 2,
      wait: '5 h', when: 'Signed up today, 11:40 am', waitLevel: WaitLevel.normal, hoursWaiting: 5, answers: [], healthNote: '',
    ),
    SignupRequest(
      id: 'ananya', name: 'Ananya Gupta', initials: 'AG', color: AvatarColor.c2, email: 'ananya.g@email.com', phone: '97690 33456',
      invitedBy: 'Neha Joshi', inviterInitials: 'NJ', inviterColor: AvatarColor.c5, code: 'NEHA-3307', plan: 'Monthly plan', device: 'iPhone app', steps: 4,
      wait: '3 h', when: 'Signed up today, 1:20 pm', waitLevel: WaitLevel.normal, hoursWaiting: 3,
      answers: [('Goal', 'Get stronger after pregnancy'), ('Body', '64 kg · 165 cm · 32 years'), ('Trains', 'Home · 3 days a week · new'), ('Food', 'Vegetarian, eats eggs')],
      healthNote: 'Baby is 7 months old. Doctor has cleared her for exercise.',
    ),
    SignupRequest(
      id: 'rohit', name: 'Rohit Sinha', initials: 'RS', color: AvatarColor.c6, email: 'rohit.sinha@email.com', phone: '98111 77001',
      invitedBy: 'Sahil Kapoor', inviterInitials: 'SK', inviterColor: AvatarColor.c1, code: 'SAHIL-1190', plan: 'Monthly plan', device: 'Android app', steps: 5,
      wait: '40 min', when: 'Signed up today, 3:55 pm', waitLevel: WaitLevel.normal, hoursWaiting: .7,
      answers: [('Goal', 'Lose fat'), ('Body', '91 kg · 180 cm · 34 years'), ('Trains', 'Gym · 4 days a week · 6 months'), ('Food', 'Vegetarian, no onion or garlic')],
      healthNote: '',
    ),
  ];

  static const setupSteps = [
    ('Account made', 'Email and phone checked'),
    ('Basic details', 'Name, age, city'),
    ('Goal and body', 'Goal, weight, height'),
    ('Health and PAR-Q', '7 health questions'),
    ('Food preferences', 'Diet, allergies'),
  ];

  static const trainerChoices = [
    TrainerChoice('Aman Verma', 'AV', AvatarColor.c2, 'Strength, fat loss', 24, 30),
    TrainerChoice('Sahil Kapoor', 'SK', AvatarColor.c1, 'Fat loss, nutrition', 18, 30),
    TrainerChoice('Neha Joshi', 'NJ', AvatarColor.c5, 'Women’s strength, rehab', 21, 30),
    TrainerChoice('Meera Shah', 'MS', AvatarColor.c6, 'Beginners, yoga', 12, 25),
    TrainerChoice('Ritu Malhotra', 'RM', AvatarColor.c4, 'PCOS, fat loss', 16, 25),
    TrainerChoice('Vimal', 'V', AvatarColor.c3, 'Head coach', 8, 10),
    TrainerChoice('Karan Mehta', 'KM', AvatarColor.c3, 'Muscle gain', 30, 30),
  ];

  /// Best trainer for each sign-up.
  static const goodFit = {'neha': 'Meera Shah', 'ishaan': 'Karan Mehta', 'pooja': 'Neha Joshi', 'rohit': 'Sahil Kapoor', 'ananya': 'Neha Joshi'};

  static const rejectReasons = [
    HintOption('fit', 'Not a fit for our coaching', 'Her goal or health needs a specialist'),
    HintOption('dup', 'Already has an account', 'Signed up twice with another email'),
    HintOption('wrong', 'Wrong or fake details', 'Name, phone or photos do not look right'),
    HintOption('full', 'No trainer free right now', 'She can sign up again later'),
    HintOption('other', 'Something else', 'Write it in the message'),
  ];

  static List<HintOption> askItems(int stepsDone) => [
        HintOption('setup', 'Finish profile setup', '${5 - stepsDone} steps left in the app'),
        const HintOption('parq', 'Fill the health form again', 'Some PAR-Q answers are missing'),
        const HintOption('doc', 'Send a doctor note', 'Needed for blood pressure, heart or recent surgery'),
        const HintOption('photo', 'Add a profile photo', 'So her trainer can recognise her'),
        const HintOption('phone', 'Check her phone number', 'The OTP did not go through'),
      ];

  static const history = [
    DecisionRecord(name: 'Kavya Rao', initials: 'KR', color: AvatarColor.c4, signedUp: 'Mon, 5 Oct', decision: Decision.approved, why: 'Trainer Neha Joshi', by: 'Vimal', when: 'Tue, 6 Oct', daysAgo: 3),
    DecisionRecord(name: 'Arjun Das', initials: 'AD', color: AvatarColor.c1, signedUp: 'Sun, 4 Oct', decision: Decision.approved, why: 'Trainer Aman Verma', by: 'Aman Verma', when: 'Mon, 5 Oct', daysAgo: 4),
    DecisionRecord(name: 'Sneha Kulkarni', initials: 'SK', color: AvatarColor.c5, signedUp: 'Sat, 3 Oct', decision: Decision.rejected, why: 'Already has an account', by: 'Vimal', when: 'Sat, 3 Oct', daysAgo: 6),
    DecisionRecord(name: 'Manish Yadav', initials: 'MY', color: AvatarColor.c6, signedUp: 'Thu, 1 Oct', decision: Decision.approved, why: 'Trainer Karan Mehta', by: 'Vimal', when: 'Fri, 2 Oct', daysAgo: 7),
    DecisionRecord(name: 'Tanvi Shah', initials: 'TS', color: AvatarColor.c2, signedUp: 'Wed, 30 Sep', decision: Decision.rejected, why: 'Not a fit: needs a physio first', by: 'Neha Joshi', when: 'Thu, 1 Oct', daysAgo: 8),
    DecisionRecord(name: 'Riya Sharma', initials: 'RS', color: AvatarColor.c1, signedUp: 'Mon, 12 Jan', decision: Decision.approved, why: 'Trainer Aman Verma', by: 'Vimal', when: 'Mon, 12 Jan', daysAgo: 270),
  ];

  static const waitFilters = [
    FilterGroup('inv', 'Invited by', ['Anyone', 'Vimal', 'Aman Verma', 'Meera Shah', 'Neha Joshi', 'Sahil Kapoor']),
    FilterGroup('setup', 'Profile setup', ['Any', 'All 5 done', 'Not finished']),
    FilterGroup('wait', 'Waiting', ['Any time', 'Over 1 day', 'Over 2 days']),
    FilterGroup('health', 'Health note', ['Any', 'Has a health note', 'No health note']),
    FilterGroup('dev', 'Signed up from', ['Any', 'Web', 'Android app', 'iPhone app']),
  ];

  static const historyFilters = [
    FilterGroup('dec', 'Decision', ['Any', 'Approved', 'Rejected']),
    FilterGroup('by', 'Decided by', ['Anyone', 'Vimal', 'Aman Verma', 'Neha Joshi']),
    FilterGroup('when', 'When', ['All time', 'Last 7 days', 'Last 30 days']),
  ];

  // -------------------------------------------------------------- Calendar
  static const calTrainers = ['Vimal', 'Aman Verma', 'Neha Joshi', 'Sahil Kapoor', 'Karan Mehta', 'Ritu Malhotra', 'Meera Shah'];

  /// Client → their trainer.
  static const clientTrainer = {
    'Riya Sharma': 'Aman Verma',
    'Rohan Kapoor': 'Aman Verma',
    'Kabir Mehta': 'Aman Verma',
    'Dev Malhotra': 'Aman Verma',
    'Aisha Sheikh': 'Meera Shah',
    'Ishita Bose': 'Aman Verma',
    'Sana Khan': 'Neha Joshi',
    'Vikram Rao': 'Sahil Kapoor',
    'Ananya Iyer': 'Ritu Malhotra',
    'Arjun Nair': 'Karan Mehta',
    'Pooja Nair': 'Vimal',
  };

  static const sessions = [
    CalSession(id: 's1', day: 0, start: 420, kind: SessionKind.session, client: 'Riya Sharma', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: 'Check the left knee before squats', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's2', day: 0, start: 540, kind: SessionKind.call, client: 'Rohan Kapoor', trainer: 'Aman Verma', minutes: 15, place: '', note: '', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's3', day: 0, start: 600, kind: SessionKind.review, client: 'Sana Khan', trainer: 'Neha Joshi', minutes: 30, place: '', note: '', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's4', day: 0, start: 1080, kind: SessionKind.session, client: 'Vikram Rao', trainer: 'Sahil Kapoor', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Sahil Kapoor'),
    CalSession(id: 's5', day: 1, start: 450, kind: SessionKind.session, client: 'Kabir Mehta', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's6', day: 1, start: 660, kind: SessionKind.review, client: 'Ananya Iyer', trainer: 'Ritu Malhotra', minutes: 30, place: '', note: 'Restart plan after the pause', done: true, bookedBy: 'Ritu Malhotra'),
    CalSession(id: 's7', day: 1, start: 1110, kind: SessionKind.session, client: 'Aisha Sheikh', trainer: 'Meera Shah', minutes: 60, place: 'Yoga room', note: '', done: true, bookedBy: 'Meera Shah'),
    CalSession(id: 's8', day: 2, start: 420, kind: SessionKind.session, client: 'Riya Sharma', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's9', day: 2, start: 435, kind: SessionKind.session, client: 'Arjun Nair', trainer: 'Karan Mehta', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Karan Mehta'),
    CalSession(id: 's10', day: 2, start: 900, kind: SessionKind.call, client: 'Pooja Nair', trainer: 'Vimal', minutes: 15, place: '', note: 'Welcome call', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's11', day: 3, start: 480, kind: SessionKind.review, client: 'Dev Malhotra', trainer: 'Aman Verma', minutes: 30, place: '', note: 'New trainer, go over his program', done: true, bookedBy: 'Vimal'),
    CalSession(id: 's12', day: 3, start: 1140, kind: SessionKind.session, client: 'Vikram Rao', trainer: 'Sahil Kapoor', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Sahil Kapoor'),
    CalSession(id: 's13', day: 4, start: 420, kind: SessionKind.session, client: 'Kabir Mehta', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: '', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's14', day: 4, start: 600, kind: SessionKind.call, client: 'Riya Sharma', trainer: 'Aman Verma', minutes: 15, place: '', note: 'Week 6 check-in questions', done: true, bookedBy: 'Aman Verma'),
    CalSession(id: 's15', day: 4, start: 1140, kind: SessionKind.session, client: 'Riya Sharma', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Aman Verma'),
    CalSession(id: 's16', day: 4, start: 1215, kind: SessionKind.call, client: 'Ishita Bose', trainer: 'Aman Verma', minutes: 15, place: '', note: '', done: false, bookedBy: 'Aman Verma'),
    CalSession(id: 's17', day: 4, start: 1200, kind: SessionKind.session, client: 'Aisha Sheikh', trainer: 'Meera Shah', minutes: 60, place: 'Yoga room', note: '', done: false, bookedBy: 'Meera Shah'),
    CalSession(id: 's18', day: 5, start: 540, kind: SessionKind.session, client: 'Rohan Kapoor', trainer: 'Aman Verma', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Aman Verma'),
    CalSession(id: 's19', day: 5, start: 600, kind: SessionKind.review, client: 'Sana Khan', trainer: 'Neha Joshi', minutes: 30, place: '', note: '', done: false, bookedBy: 'Neha Joshi'),
    CalSession(id: 's20', day: 5, start: 660, kind: SessionKind.session, client: 'Arjun Nair', trainer: 'Karan Mehta', minutes: 60, place: 'Andheri gym floor', note: '', done: false, bookedBy: 'Karan Mehta'),
  ];

  /// Sessions shown for a week offset from this week (the design fakes other weeks).
  static List<CalSession> sessionsForWeek(int offset) {
    if (offset == 0) return sessions;
    if (offset == -1) {
      return [for (var i = 0; i < sessions.length; i++) if (i.isEven) sessions[i].copyWith(done: true)];
    }
    if (offset == 1) {
      return [for (var i = 0; i < sessions.length; i++) if (i % 3 == 0) sessions[i].copyWith(done: false)];
    }
    return const [];
  }

  static const amanHours = [
    DayHours(true, 390, 1200),
    DayHours(true, 390, 1200),
    DayHours(true, 390, 1200),
    DayHours(true, 390, 1200),
    DayHours(true, 390, 1260),
    DayHours(true, 480, 780),
    DayHours(false, 0, 0),
  ];

  static const defaultHours = [
    DayHours(true, 420, 1260),
    DayHours(true, 420, 1260),
    DayHours(true, 420, 1260),
    DayHours(true, 420, 1260),
    DayHours(true, 420, 1260),
    DayHours(true, 480, 840),
    DayHours(false, 0, 0),
  ];

  static List<DayHours> hoursOf(String trainer) => trainer == 'Aman Verma' ? amanHours : defaultHours;

  // -------------------------------------------------------------- Activity
  static const activityKinds = ['All', 'Check-in', 'Plan', 'Workout', 'Meal', 'Body', 'Client', 'Content', 'System'];

  static const activityFilters = [
    FilterGroup('role', 'Who', ['Everyone', 'Team', 'Clients', 'Automations']),
    FilterGroup('by', 'Person', ['Anyone', 'Vimal', 'Aman Verma', 'Sahil Kapoor', 'Meera Shah']),
  ];

  static const activityRanges = [('Today', 0), ('Last 7 days', 7), ('Last 30 days', 30), ('Last 3 months', 90), ('All time', 99999)];

  static const activity = [
    ActivityDay('Today', 0, [
      ActivityEntry(icon: ActivityIcon.edit, kind: 'Plan', who: 'Vimal', post: ' changed Kabir Mehta’s program', when: '2 min ago', old: 'Beginner Full Body', now: 'Hypertrophy PPL', role: ActivityRole.admin),
      ActivityEntry(icon: ActivityIcon.edit, kind: 'Plan', who: 'Aman Verma', post: ' changed rest time in Rohan’s Push day', when: '14 min ago', old: '60 s', now: '90 s'),
      ActivityEntry(icon: ActivityIcon.food, kind: 'Meal', who: 'Rohan Kapoor', post: ' swapped a food at lunch', when: '38 min ago', old: 'Paneer 100 g', now: 'Tofu 160 g', role: ActivityRole.client),
      ActivityEntry(icon: ActivityIcon.bolt, kind: 'System', who: 'Automation', post: ' sent the check-in reminder', when: '1 h ago', note: 'To 18 clients, by push and WhatsApp', role: ActivityRole.system),
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', who: 'Vimal', post: ' approved Sana Khan', when: '2 h ago', note: 'Trainer: Aman Verma', role: ActivityRole.admin),
      ActivityEntry(icon: ActivityIcon.edit, kind: 'Plan', who: 'Sahil Kapoor', post: ' set a new calorie target for Riya Sharma', when: '4 h ago', old: '1,800 kcal', now: '1,650 kcal'),
    ]),
    ActivityDay('Yesterday', 1, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', who: 'Meera Shah', post: ' replied to Aisha Sheikh’s check-in', when: '7:40 pm', note: '“Add 30 g carbs before training, legs on Saturday.”'),
      ActivityEntry(icon: ActivityIcon.dumbbell, kind: 'Workout', who: 'Riya Sharma', post: ' finished Upper A', when: '7:12 pm', note: '18 of 18 sets, 52 min', role: ActivityRole.client),
      ActivityEntry(icon: ActivityIcon.edit, kind: 'Plan', who: 'Aman Verma', post: ' removed an exercise from Kabir Mehta’s Leg day', when: '5:15 pm', note: 'Walking lunges'),
      ActivityEntry(icon: ActivityIcon.scale, kind: 'Body', who: 'Dev Patel', post: ' logged body weight', when: '9:02 am', old: '82.4 kg', now: '81.9 kg', role: ActivityRole.client),
    ]),
    ActivityDay('Wed, 7 Oct', 2, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', who: 'Kabir Mehta', post: ' sent the week 9 check-in', when: '8:30 pm', note: '78.2 kg, 3 photos', role: ActivityRole.client),
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', who: 'Vimal', post: ' moved Dev Malhotra to Aman Verma', when: '6:10 pm', note: 'Karan Mehta was full', role: ActivityRole.admin),
      ActivityEntry(icon: ActivityIcon.bolt, kind: 'System', who: 'Automation', post: ' paused Ananya Iyer', when: '12:00 am', note: 'No check-in for 14 days', role: ActivityRole.system),
    ]),
    ActivityDay('Mon, 5 Oct', 4, [
      ActivityEntry(icon: ActivityIcon.play, kind: 'Content', who: 'Vimal', post: ' added a PDF to the library', when: '4:45 pm', note: 'Sleep better in 7 days', role: ActivityRole.admin),
      ActivityEntry(icon: ActivityIcon.edit, kind: 'Plan', who: 'Aman Verma', post: ' made a meal plan for Ishita Bose', when: '4:30 pm', note: '1,700 kcal, high protein'),
      ActivityEntry(icon: ActivityIcon.food, kind: 'Meal', who: 'Sana Khan', post: ' logged breakfast', when: '8:15 am', note: 'Oats with whey, 420 kcal', role: ActivityRole.client),
    ]),
    ActivityDay('Thu, 1 Oct', 8, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', who: 'Sahil Kapoor', post: ' reviewed 7 weekly check-ins', when: '6:00 pm', note: 'All replied the same day'),
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', who: 'Vimal', post: ' added Neha Jain', when: '11:20 am', note: 'Sent to Approvals', role: ActivityRole.admin),
    ]),
    ActivityDay('Mon, 21 Sep', 18, [
      ActivityEntry(icon: ActivityIcon.dumbbell, kind: 'Workout', who: 'Meera Shah', post: ' made a new program', when: '3:00 pm', note: 'Yoga Strength, 6 weeks'),
      ActivityEntry(icon: ActivityIcon.bolt, kind: 'System', who: 'Automation', post: ' sent birthday wishes', when: '9:00 am', note: 'To Riya Sharma', role: ActivityRole.system),
    ]),
    ActivityDay('Tue, 1 Sep', 38, [
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', who: 'Vimal', post: ' added a trainer, Meera Shah', when: '10:30 am', note: 'Access: Assigned clients', role: ActivityRole.admin),
    ]),
  ];

  // -------------------------------------------------------------- Trainers
  static const trainerFilters = [
    FilterGroup('acc', 'Access', ['Any', 'Assigned clients', 'All clients', 'Custom']),
    FilterGroup('space', 'Space', ['Any', 'Has space', 'Full']),
    FilterGroup('spec', 'Speciality', ['Any', 'Fat loss', 'Strength', 'Muscle gain', 'Women’s', 'Beginners']),
    FilterGroup('ci', 'Check-ins', ['Any', 'Has check-ins to review', 'All reviewed']),
  ];

  static const accessModes = [
    ('assigned', 'Assigned clients', 'Only the clients you give them: their plans and check-ins. Best for new trainers.'),
    ('all', 'All clients', 'Every client of the gym. For senior trainers who cover for others.'),
    ('custom', 'Custom', 'Pick each permission yourself after adding. Starts the same as Assigned clients.'),
  ];

  // ------------------------------------------------------- Trainer profile
  static const permissionGroups = [
    PermissionGroup('Clients', [
      ('View assigned clients', 'Profile, plans and logs', true),
      ('View all clients', 'Every client of the gym', false),
      ('Approve sign-ups', 'Only people invited by him', false),
      ('Pause or resume clients', '', false),
    ]),
    PermissionGroup('Training', [
      ('Create and edit programs', 'For his clients', true),
      ('Use gym templates', 'Copy master programs', true),
      ('Edit gym templates', 'Changes master programs', false),
      ('Add custom exercises', '', true),
    ]),
    PermissionGroup('Nutrition', [
      ('Meal plans', 'Make and change', true),
      ('Add foods and recipes', '', true),
      ('Supplement plans', '', true),
      ('See food logs', '', true),
    ]),
    PermissionGroup('Check-ins', [
      ('Review daily check-ins', '', true),
      ('Review weekly check-ins', '', true),
      ('Edit check-in forms', 'Changes master forms', false),
      ('Progress photos', '', true),
    ]),
    PermissionGroup('Schedule', [
      ('Manage own calendar', '', true),
      ('Book sessions for clients', '', true),
    ]),
  ];

  static const trainerClients = [
    TrainerClientRow('Riya Sharma', 'RS', AvatarColor.c1, 'Fat loss', 'Fat Loss Phase 1 · wk 6', 86, 'Today, 8:10 am', 'Active', '12 Jan 2026'),
    TrainerClientRow('Rohan Kapoor', 'RK', AvatarColor.c2, 'Muscle gain', 'Hypertrophy 4-day · wk 3', 78, 'Yesterday', 'Active', '3 Feb 2026'),
    TrainerClientRow('Neha Jain', 'NJ', AvatarColor.c3, 'General fitness', 'Not started', 0, '—', 'Pending', '6 Oct 2026'),
    TrainerClientRow('Kabir Mehta', 'KM', AvatarColor.c4, 'Strength', 'Strength Base · wk 9', 91, 'Today, 7:30 am', 'Active', '20 Mar 2026'),
    TrainerClientRow('Ananya Iyer', 'AI', AvatarColor.c5, 'Fat loss', 'Fat Loss Phase 2 · paused', 0, '2 weeks ago', 'Paused', '8 Apr 2026'),
    TrainerClientRow('Vikram Rao', 'VR', AvatarColor.c6, 'Fat loss', 'Fat Loss Phase 1 · wk 2', 58, '4 days ago', 'At risk', '22 Sep 2026'),
    TrainerClientRow('Ishita Bose', 'IB', AvatarColor.c2, 'Recomp', 'Recomp 3-day · wk 5', 82, 'Today, 6:55 am', 'Active', '1 Aug 2026'),
    TrainerClientRow('Dev Malhotra', 'DM', AvatarColor.c1, 'Strength', 'Strength Base · wk 1', 64, '3 days ago', 'At risk', '2 Oct 2026'),
  ];

  static const trainerClientFilters = [
    FilterGroup('st', 'Status', ['Any', 'Active', 'At risk', 'Paused', 'Pending']),
    FilterGroup('goal', 'Goal', ['Any', 'Fat loss', 'Muscle gain', 'Strength', 'Recomp']),
  ];

  static const attention = [
    AttentionClient('Vikram Rao', 'VR', AvatarColor.c6, 'No check-in for 4 days', 'At risk'),
    AttentionClient('Dev Malhotra', 'DM', AvatarColor.c1, 'Missed 3 workouts this week', 'At risk'),
    AttentionClient('Neha Jain', 'NJ', AvatarColor.c3, 'Waiting for her first plan', 'New'),
  ];

  static const trainerActivityKinds = ['All', 'Check-in', 'Plan', 'Client', 'Login'];

  static const trainerActivity = [
    ActivityDay('Today', 0, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', pre: 'Reviewed', who: 'Riya Sharma', post: '’s daily check-in', when: '9:52 am', note: 'Replied: “Good sleep this week. Keep steps above 8k.”'),
      ActivityEntry(icon: ActivityIcon.login, kind: 'Login', pre: 'Logged in', who: '', when: '9:40 am', note: 'Android app'),
    ]),
    ActivityDay('Yesterday', 1, [
      ActivityEntry(icon: ActivityIcon.db, kind: 'Plan', pre: 'Changed', who: 'Riya Sharma', post: '’s Thursday leg day', when: '6:20 pm', old: 'Walking lunges', now: 'Split squats'),
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', pre: 'Reviewed 6 weekly check-ins', who: '', when: '5:05 pm', note: '2 of them need a plan change'),
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', pre: 'Got a new client,', who: 'Neha Jain', when: '11:40 am', note: 'Assigned by Vimal from Approvals'),
    ]),
    ActivityDay('Mon, 5 Oct', 4, [
      ActivityEntry(icon: ActivityIcon.db, kind: 'Plan', pre: 'Made a meal plan for', who: 'Ishita Bose', when: '4:30 pm', note: '1,700 kcal, high protein'),
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', pre: 'Moved', who: 'Dev Malhotra', post: ' to a new program', when: '7:45 am', old: 'Beginner Full Body', now: 'Strength Base'),
    ]),
    ActivityDay('Fri, 2 Oct', 7, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', pre: 'Reviewed', who: 'Vikram Rao', post: '’s weekly check-in', when: '6:40 pm', note: 'Asked him to log meals daily'),
      ActivityEntry(icon: ActivityIcon.db, kind: 'Plan', pre: 'Changed', who: 'Kabir Mehta', post: '’s rest time', when: '10:10 am', old: '60 s', now: '90 s'),
    ]),
    ActivityDay('Mon, 28 Sep', 11, [
      ActivityEntry(icon: ActivityIcon.users, kind: 'Client', pre: 'Got a new client,', who: 'Dev Malhotra', when: '12:30 pm', note: 'Moved from Karan Mehta (full)'),
      ActivityEntry(icon: ActivityIcon.login, kind: 'Login', pre: 'Logged in', who: '', when: '8:05 am', note: 'Web, Chrome'),
    ]),
    ActivityDay('Sat, 19 Sep', 20, [
      ActivityEntry(icon: ActivityIcon.db, kind: 'Plan', pre: 'Started a new program for', who: 'Vikram Rao', when: '9:00 am', note: 'Fat Loss Phase 1, 8 weeks'),
    ]),
    ActivityDay('Sun, 30 Aug', 40, [
      ActivityEntry(icon: ActivityIcon.clip, kind: 'Check-in', pre: 'Reviewed 9 weekly check-ins', who: '', when: '8:30 pm', note: 'All replied the same day'),
    ]),
  ];

  static const trainerDocs = [
    TrainerDoc(name: 'ACE Certified Personal Trainer', by: 'American Council on Exercise', kind: DocKind.cert, kindLabel: 'Certificate', issued: 'Jun 2021', validTill: 'Jun 2027', status: 'Verified', clientsSee: true, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 412 KB', file: 'ace-cpt-aman.pdf'),
    TrainerDoc(name: 'Precision Nutrition Level 1', by: 'Precision Nutrition', kind: DocKind.cert, kindLabel: 'Certificate', issued: 'Feb 2023', validTill: 'No end date', status: 'Verified', clientsSee: true, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 380 KB', file: 'pn-l1.pdf'),
    TrainerDoc(name: 'First aid and CPR', by: 'Indian Red Cross', kind: DocKind.cert, kindLabel: 'Certificate', issued: 'Nov 2024', validTill: 'Nov 2026', status: 'Expires in 33 days', clientsSee: true, uploaded: '2 Dec 2024 by Aman', size: 'JPG, 1.2 MB', file: 'first-aid-2024.jpg', expiring: true),
    TrainerDoc(name: 'Diploma in Sports Nutrition', by: 'K11 Academy', kind: DocKind.cert, kindLabel: 'Certificate', issued: 'Aug 2020', validTill: 'No end date', status: 'Not checked', clientsSee: false, uploaded: 'Yesterday by Aman', size: 'PDF, 650 KB', file: 'k11-diploma.pdf'),
    TrainerDoc(name: 'Aadhaar card', by: 'UIDAI', kind: DocKind.id, kindLabel: 'ID proof', issued: 'Mar 2025', validTill: 'No end date', status: 'Verified', clientsSee: false, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 220 KB', file: 'aadhaar-aman.pdf'),
    TrainerDoc(name: 'Trainer agreement', by: 'Train With Vimal', kind: DocKind.file, kindLabel: 'Contract', issued: '12 Mar 2025', validTill: '11 Mar 2027', status: 'Signed', clientsSee: false, uploaded: '12 Mar 2025 by Vimal', size: 'PDF, 96 KB', file: 'agreement-signed.pdf'),
  ];

  static const clientViewRows = [
    ClientViewRow('name', 'Photo and name', 'Clients always see this', true, locked: true),
    ClientViewRow('spec', 'Speciality', 'Strength, Fat loss, Powerlifting', true),
    ClientViewRow('exp', 'Experience', '6 years', true),
    ClientViewRow('about', 'About', 'Short bio', true),
    ClientViewRow('lang', 'Languages', 'Hindi, English', true),
    ClientViewRow('certs', 'Certificates', 'Only verified ones you allow', true),
    ClientViewRow('soc', 'Social media', 'Instagram, YouTube', true),
    ClientViewRow('mob', 'Mobile number', 'Only you and admins see it', false),
    ClientViewRow('mail', 'Email', '', false),
  ];

  static const assignCandidates = [
    AssignCandidate('Sana Khan', 'SK', AvatarColor.c4, 'Fat loss · signed up 2 Oct', 'No trainer', false),
    AssignCandidate('Farhan Ali', 'FA', AvatarColor.c2, 'Muscle gain · from Karan Mehta (full)', 'Karan Mehta', true),
    AssignCandidate('Tanya Desai', 'TD', AvatarColor.c5, 'Strength · signed up 29 Sep', 'No trainer', false),
    AssignCandidate('Rahul Nair', 'RN', AvatarColor.c1, 'Fat loss · from Karan Mehta (full)', 'Karan Mehta', true),
    AssignCandidate('Meghna Rao', 'MR', AvatarColor.c6, 'Recomp · with Sahil Kapoor', 'Sahil Kapoor', true),
    AssignCandidate('Omar Shaikh', 'OS', AvatarColor.c3, 'General fitness · signed up 5 Oct', 'No trainer', false),
    AssignCandidate('Pooja Nair', 'PN', AvatarColor.c2, 'Fat loss · signed up 6 Oct', 'No trainer', false),
    AssignCandidate('Aditya Singh', 'AS', AvatarColor.c4, 'Muscle gain · signed up 7 Oct', 'No trainer', false),
    AssignCandidate('Zoya Khan', 'ZK', AvatarColor.c5, 'Recomp · from Karan Mehta (full)', 'Karan Mehta', true),
    AssignCandidate('Nikhil Joshi', 'NJ', AvatarColor.c1, 'Strength · with Meera Shah', 'Meera Shah', true),
  ];
}

// =========================================================================
// State that must survive navigation / is shared between admin screens
// =========================================================================

/// The admin's client list (Clients tab). Pause, change trainer, delete and
/// add all go through here.
class AdminClientsNotifier extends Notifier<List<ClientSummary>> {
  @override
  List<ClientSummary> build() => List.of(PeopleMock.clients);

  void add(ClientSummary c) => state = [c, ...state];

  /// Removes a client and returns its old index (for undo).
  int remove(String id) {
    final i = state.indexWhere((c) => c.id == id);
    if (i >= 0) state = [...state]..removeAt(i);
    return i;
  }

  void insert(int index, ClientSummary c) {
    final list = [...state];
    list.insert(index.clamp(0, list.length), c);
    state = list;
  }

  void replace(ClientSummary c) => state = [for (final x in state) x.id == c.id ? c : x];

  void setStatus(String id, ClientStatus s) => state = [for (final c in state) c.id == id ? c.copyWith(status: s) : c];

  void setTrainer(String id, String trainer) => state = [for (final c in state) c.id == id ? c.copyWith(trainer: trainer) : c];
}

final adminClientsProvider = NotifierProvider<AdminClientsNotifier, List<ClientSummary>>(AdminClientsNotifier.new);

/// Invite links (shared by the Clients and Approvals pages).
class InviteLinksNotifier extends Notifier<List<InviteLink>> {
  @override
  List<InviteLink> build() => List.of(AdminMock.inviteLinks);

  bool get hasNew => state.any((l) => l.code == AdminMock.newInviteLink.code);

  void create() {
    if (!hasNew) state = [AdminMock.newInviteLink, ...state];
  }

  void toggle(String code) => state = [
        for (final l in state)
          if (l.code == code && l.status != LinkStatus.ended)
            l.copyWith(status: l.status == LinkStatus.on ? LinkStatus.off : LinkStatus.on)
          else
            l,
      ];

  void toggleApprovals(String code) => state = [for (final l in state) l.code == code ? l.copyWith(approvals: !l.approvals) : l];

  void delete(String code) => state = state.where((l) => l.code != code).toList();
}

final inviteLinksProvider = NotifierProvider<InviteLinksNotifier, List<InviteLink>>(InviteLinksNotifier.new);

/// Approvals: who is waiting and what was decided.
class ApprovalsState {
  const ApprovalsState({required this.waiting, required this.history});
  final List<SignupRequest> waiting;
  final List<DecisionRecord> history;
}

class ApprovalsNotifier extends Notifier<ApprovalsState> {
  @override
  ApprovalsState build() => ApprovalsState(waiting: List.of(AdminMock.signups), history: List.of(AdminMock.history));

  /// A client added by the admin with "Send to Approvals".
  void addWaiting(SignupRequest r) => state = ApprovalsState(waiting: [r, ...state.waiting], history: state.history);

  void decide(SignupRequest r, Decision d, String why) {
    state = ApprovalsState(
      waiting: state.waiting.where((x) => x.id != r.id).toList(),
      history: [
        DecisionRecord(name: r.name, initials: r.initials, color: r.color, signedUp: r.when.replaceFirst('Signed up ', '').split(',').first, decision: d, why: why, by: 'Vimal', when: 'Today', daysAgo: 0),
        ...state.history,
      ],
    );
  }

  /// Undo a decision made in this session.
  void undo(SignupRequest r, int index) {
    state = ApprovalsState(
      waiting: [...state.waiting]..insert(index.clamp(0, state.waiting.length), r),
      history: state.history.where((h) => h.name != r.name || h.when != 'Today').toList(),
    );
  }

  /// Move someone from History back to Waiting.
  void moveBack(DecisionRecord h) {
    final req = SignupRequest(
      id: 'back-${h.name}', name: h.name, initials: h.initials, color: h.color, email: '${h.first.toLowerCase()}@email.com', phone: '98000 00000',
      invitedBy: h.by, inviterInitials: h.by == 'Vimal' ? 'V' : h.by.split(' ').map((p) => p[0]).join(), inviterColor: AvatarColor.c3,
      code: 'VIMAL-0007', plan: 'Monthly plan', device: 'Web', steps: 5, wait: 'Moved back', when: 'Signed up ${h.signedUp}',
      waitLevel: WaitLevel.normal, answers: const [], healthNote: '', hoursWaiting: 0, movedBack: true,
    );
    state = ApprovalsState(waiting: [req, ...state.waiting], history: state.history.where((x) => x != h).toList());
  }
}

final approvalsProvider = NotifierProvider<ApprovalsNotifier, ApprovalsState>(ApprovalsNotifier.new);

/// Trainers switched off (Deactivate / Reactivate). Varun starts inactive.
class InactiveTrainersNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'varun'};

  void deactivate(String id) => state = {...state, id};
  void reactivate(String id) => state = {...state}..remove(id);
}

final inactiveTrainersProvider = NotifierProvider<InactiveTrainersNotifier, Set<String>>(InactiveTrainersNotifier.new);
