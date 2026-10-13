import 'package:flutter/material.dart' show IconData, Icons;

import '../../core/theme/app_colors.dart';

/// Data for the welcome, log in, invite and setup screens (ClientWelcome, ClientLogin,
/// ClientJoinLink, ClientVerifyEmail, ClientResetPassword, ClientHealth,
/// ClientPermissions, ClientIntro designs).

/// A titled line (title + subtitle).
class TitledLine {
  const TitledLine(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

/// A support option in the "Need help?" sheet.
class HelpOption {
  const HelpOption(this.title, this.subtitle, this.icon, this.toastTitle, this.toastSubtitle);
  final String title;
  final String subtitle;
  final IconData icon;
  final String toastTitle;
  final String toastSubtitle;
}

/// Label → value row.
class KeyValue {
  const KeyValue(this.label, this.value);
  final String label;
  final String value;
}

/// Main goal card in setup step 1.
class GoalOption {
  const GoalOption(this.name, this.subtitle, this.hint, this.icon);
  final String name;
  final String subtitle;
  final String hint;
  final IconData icon;
}

/// Food preference card (veg / non-veg dot colour).
enum DietMark { green, amber, red }

class DietOption {
  const DietOption(this.name, this.subtitle, this.mark);
  final String name;
  final String subtitle;
  final DietMark mark;
}

/// Body basics stepper (age, height, weight, target).
class BodyField {
  const BodyField(this.label, this.initial, this.step, this.min, this.max, this.unit);
  final String label;
  final double initial;
  final double step;
  final double min;
  final double max;
  final String unit;
}

/// One onboarding step.
class SetupStep {
  const SetupStep(this.title, this.short, this.subtitle);
  final String title;
  final String short;
  final String subtitle;
}

/// A broken invite / login link.
class BadLink {
  const BadLink({
    required this.title,
    required this.message,
    required this.hint,
    required this.url,
    required this.goLabel,
    required this.loginLabel,
    this.secure = false,
  });
  final String title;
  final String message;
  final String hint;
  final String url;
  final String goLabel;
  final String loginLabel;
  final bool secure;
}

/// A perk line on a permission screen.
class PermPerk {
  const PermPerk(this.icon, this.text, this.tint);
  final IconData icon;
  final String text;
  final Tint tint;
}

/// A phone permission we ask for, with the copy for each state.
class PermissionKind {
  const PermissionKind({
    required this.key,
    required this.when,
    required this.icon,
    required this.title,
    required this.allowLabel,
    required this.body,
    required this.perks,
    required this.systemQuestion,
    required this.systemWhat,
    required this.okBody,
    required this.noBody,
  });
  final String key;
  final String when;
  final IconData icon;
  final String title;
  final String allowLabel;
  final String body;
  final List<PermPerk> perks;
  final String systemQuestion;
  final String systemWhat;
  final String okBody;
  final String noBody;
}

/// Welcome guide slide.
class IntroSlide {
  const IntroSlide(this.kicker, this.title, this.body, this.points, this.icon);
  final String kicker;
  final String title;
  final String body;
  final List<KeyValue> points;
  final IconData icon;
}

abstract final class AuthMock {
  static const email = 'riya.sharma@email.com';
  static const firstName = 'Riya';
  static const coach = 'Aman';
  static const coachFull = 'Aman Verma';

  // ---------------- Welcome / log in ----------------

  static const welcomePills = <(IconData, String)>[
    (Icons.fitness_center_rounded, 'Workouts'),
    (Icons.restaurant_rounded, 'Meals'),
    (Icons.trending_up_rounded, 'Progress'),
  ];

  /// Where a client lands after log in (design demo row).
  static const afterLogin = ['Waiting for approval', 'Setup not done', 'All set'];

  /// Help sheet on the welcome / log in board.
  static const welcomeHelp = <HelpOption>[
    HelpOption('Call the gym', 'Front desk · 9 am – 9 pm', Icons.call_rounded, 'Calling Train With Vimal…', 'The front desk picks up in a minute'),
    HelpOption('WhatsApp support', 'Usually replies in 10 minutes', Icons.chat_rounded, 'Opening WhatsApp', 'Chat with the gym support team'),
    HelpOption('Email support', 'They usually reply within an hour', Icons.mail_rounded, 'Email draft opened', 'To support@trainwithvimal.app'),
  ];

  /// Help sheet on the verify / reset / setup / permission / invite boards.
  static const accountHelp = <HelpOption>[
    HelpOption('WhatsApp support', '+91 70874 03476 · usually replies in 10 minutes', Icons.chat_rounded, 'Opening WhatsApp', 'Train With Vimal support'),
    HelpOption('Call support', 'Mon–Sat, 9 am – 9 pm', Icons.call_rounded, 'Calling Train With Vimal…', 'Train With Vimal support'),
    HelpOption('Email support', 'trainwithvimal@gmail.com', Icons.mail_rounded, 'Email draft opened', 'Train With Vimal support'),
  ];

  static const welcomeTerms = <TitledLine>[
    TitledLine('Your data, your control', 'We keep only the data coaching needs: workouts, meals, check-ins and progress.'),
    TitledLine('Progress photos stay private', 'Only you and your coach see them.'),
    TitledLine('Health waiver', 'You confirm that you are fit to exercise and will tell your coach about any injury or pain.'),
    TitledLine('Leaving', 'You can delete your account and data any time from My account.'),
  ];

  // ---------------- Onboarding ----------------

  static const steps = <SetupStep>[
    SetupStep('Your goal', 'Goal', 'Main goal and training experience'),
    SetupStep('About you', 'About you', 'Age, height, weight, where you train'),
    SetupStep('Training days', 'Schedule', 'Days, session length, wake-up time'),
    SetupStep('Health & injuries', 'Health', 'Injuries, conditions, activity, doctor’s OK'),
    SetupStep('Food preferences', 'Food', 'Diet, meals per day, foods you avoid'),
  ];

  static const goals = <GoalOption>[
    GoalOption('Lose fat', 'Lean down, keep muscle', 'Calorie deficit with strength training: lose fat, keep muscle.', Icons.local_fire_department_rounded),
    GoalOption('Build muscle', 'Size & shape', 'A small surplus with progressive overload: size and shape.', Icons.fitness_center_rounded),
    GoalOption('Get stronger', 'Hit new PRs', 'Low reps and heavy compound lifts to beat your records.', Icons.emoji_events_rounded),
    GoalOption('Recomp', 'Lose fat + gain muscle', 'Slow and steady: fat down, muscle up.', Icons.sync_alt_rounded),
    GoalOption('Fitness & health', 'Energy, stamina', 'Focus on stamina, energy and daily movement.', Icons.favorite_rounded),
    GoalOption('Event prep', 'Wedding, shoot, trek', 'A plan built around a date, so you peak before your event.', Icons.event_rounded),
  ];

  static const levels = <TitledLine>[
    TitledLine('Beginner', '0–6 months'),
    TitledLine('Intermediate', '6 months – 2 yrs'),
    TitledLine('Advanced', '2+ years'),
  ];

  static const body = <BodyField>[
    BodyField('Age', 29, 1, 14, 80, 'yrs'),
    BodyField('Height', 162, 1, 120, 220, 'cm'),
    BodyField('Weight', 78, .5, 35, 200, 'kg'),
    BodyField('Target weight', 68, .5, 35, 200, 'kg'),
  ];

  static const places = <TitledLine>[
    TitledLine('Gym', 'Full equipment'),
    TitledLine('Home', 'Little or none'),
    TitledLine('Both', 'Mix of the two'),
  ];
  static const placeNames = ['Gym', 'Home', 'Gym and home'];

  static const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const defaultDays = [0, 1, 3, 4];
  static const lengths = ['30 min', '45 min', '60 min', '75 min'];
  static const wakeTimes = ['5:30 am', '6:30 am', '7:30 am', '8:30 am'];

  static const injuries = ['None', 'Knee', 'Lower back', 'Shoulder', 'Neck', 'Wrist', 'Ankle'];
  static const conditions = ['None', 'Diabetes', 'Thyroid', 'High BP', 'PCOS', 'Asthma', 'Heart condition'];
  static const injuryNotes = <String, List<String>>{
    'Knee': ['Right knee hurts on deep squats', 'Left knee hurts on stairs'],
    'Lower back': ['Lower back stiff after sitting'],
    'Shoulder': ['Shoulder pain on overhead press'],
    'Neck': ['Neck stiff from desk work'],
    'Wrist': ['Wrist pain on push-ups'],
    'Ankle': ['Ankle rolled last year'],
  };

  static const activity = <TitledLine>[
    TitledLine('Desk job', 'Mostly sitting, under 5,000 steps'),
    TitledLine('On my feet', 'Walking or standing a lot'),
    TitledLine('Very active', 'Physical work or sport most days'),
  ];

  static const diets = <DietOption>[
    DietOption('Vegetarian', 'No meat, fish or eggs', DietMark.green),
    DietOption('Eggetarian', 'Vegetarian + eggs', DietMark.amber),
    DietOption('Non-veg', 'Eats meat and fish', DietMark.red),
    DietOption('Vegan', 'No animal products', DietMark.green),
    DietOption('Jain', 'No root vegetables', DietMark.green),
  ];

  static const avoidFoods = ['Eggs', 'Mushrooms', 'Onion & garlic', 'Dairy', 'Peanuts', 'Gluten'];
  static const defaultAvoid = ['Eggs', 'Mushrooms'];

  /// "Remind me" options in the Finish later sheet: label, when.
  static const reminders = <(String, String)>[
    ('Tonight', 'tonight, 8 pm'),
    ('Tomorrow', 'tomorrow, 9 am'),
    ('In 3 days', 'in 3 days, 9 am'),
    ('Off', ''),
  ];

  // ---------------- Verify email ----------------

  /// Change email sheet: tap the field to cycle, with the error each one shows.
  static const changeEmails = <(String, String)>[
    ('riya.sharma@gmail.com', ''),
    ('riya.sharma@gmial.com', 'Check the spelling: did you mean gmail.com?'),
    ('vimal@trainwithvimal.com', 'This email already has an account'),
  ];

  // ---------------- Passwords (demo typing) ----------------

  static const demoP1 = ['', 'riya2026', 'Riya@2026x'];
  static const demoP2 = ['', 'Riya@2025x', 'Riya@2026x'];

  // ---------------- Invite / login link ----------------

  static const inviteUrl = 'trainwithvimal.app/join/AMAN-4821';
  static const loginUrl = 'trainwithvimal.app/start/K7Q2-9XP4';

  static const invite = <KeyValue>[
    KeyValue('Invited by', 'Aman Verma'),
    KeyValue('Includes', 'Workouts, meals, check-ins'),
    KeyValue('Invite valid till', '8 Nov 2026'),
  ];

  static const inviteHow = ['Make your account here', 'Confirm your email with one tap', 'Aman approves you, usually within a day'];

  static const registerDefaults = <String, String>{
    'name': 'Riya Sharma',
    'email': 'riya.sharma@email.com',
    'phone': '+91 98201 11234',
  };
  static const registerPlaceholders = <String, String>{
    'name': 'Your full name',
    'email': 'you@email.com',
    'phone': '+91 98765 43210',
  };
  static const registerErrors = <String, String>{
    'name': 'Enter your full name',
    'email': 'Enter a valid email',
    'phone': 'Enter a 10-digit mobile number',
  };
  static const registerTypo = 'riya.sharma@emal';

  static const addedAccount = <KeyValue>[
    KeyValue('Name', 'Kavya Menon'),
    KeyValue('Mobile (you log in with this)', '+91 98450 22118'),
    KeyValue('Email', 'kavya.menon@email.com'),
  ];

  static const badLinks = <BadLink>[
    BadLink(
      title: 'This invite has expired',
      message: 'Aman’s invite AMAN-4821 worked till 8 Nov 2026. Ask him for a new link.',
      hint: 'Invite links work for the time your coach picks, then stop.',
      url: inviteUrl,
      goLabel: 'Ask Aman for a new link',
      loginLabel: 'I already have an account',
    ),
    BadLink(
      title: 'This invite was turned off',
      message: 'Aman turned this link off, so it can’t make new accounts. Ask him for a new one.',
      hint: 'Coaches turn a link off when it was shared by mistake.',
      url: inviteUrl,
      goLabel: 'Ask Aman for a new link',
      loginLabel: 'I already have an account',
    ),
    BadLink(
      title: 'This invite is full',
      message: 'All 10 places on this link are taken. Ask Aman to add you or send a new link.',
      hint: 'Coaches can limit how many people join from one link.',
      url: inviteUrl,
      goLabel: 'Ask Aman for a new link',
      loginLabel: 'I already have an account',
    ),
    BadLink(
      title: 'This link was already used',
      message: 'Your password is already set. Log in with your mobile number, or reset your password if you forgot it.',
      hint: 'Login links work once, for 7 days.',
      url: loginUrl,
      goLabel: 'Message Aman',
      loginLabel: 'Log in',
      secure: true,
    ),
  ];

  static const joinTerms = <TitledLine>[
    TitledLine('Coaching, not medical care', 'Your coach gives training and food advice. See a doctor for medical problems.'),
    TitledLine('Your account', 'Keep your password safe. One account per person.'),
    TitledLine('Health waiver', 'You confirm you are fit to exercise and will tell your coach about any injury or pain.'),
    TitledLine('Your data', 'Only you and your coach see your photos and logs. We never sell your data.'),
  ];

  /// "Details not right?" sheet: title, subtitle, icon, toast title, toast subtitle.
  static const wrongDetails = <HelpOption>[
    HelpOption('Fix my name or email', 'You can change these yourself after you log in', Icons.edit_rounded, 'No problem', 'You can edit them in More › My account'),
    HelpOption('This is not me', 'We tell Aman and close this link', Icons.person_off_rounded, 'Thanks for telling us', 'Aman was told. This link is now off'),
  ];

  // ---------------- Permissions ----------------

  static const permissions = <PermissionKind>[
    PermissionKind(
      key: 'notifications',
      when: 'After you verify your email',
      icon: Icons.notifications_rounded,
      title: 'Stay on track',
      allowLabel: 'Allow notifications',
      body: 'Get a nudge at the right time, and know the moment your coach replies.',
      perks: [
        PermPerk(Icons.notifications_rounded, 'Account approved and check-in due alerts', Tint.blue),
        PermPerk(Icons.calendar_today_rounded, 'Workout and meal reminders, at your times', Tint.green),
        PermPerk(Icons.check_circle_rounded, 'Replies and plan updates from your coach', Tint.purple),
      ],
      systemQuestion: 'Allow Train With Vimal to send you notifications?',
      systemWhat: 'Show notifications',
      okBody: 'We will remind you at your times and ping you when Aman approves you.',
      noBody: 'Your phone blocked it. The app still works, you just won’t get alerts. We still send emails.',
    ),
    PermissionKind(
      key: 'camera',
      when: 'When you first take a progress photo',
      icon: Icons.photo_camera_rounded,
      title: 'Use your camera',
      allowLabel: 'Allow camera',
      body: 'Take progress and meal photos right inside the app.',
      perks: [
        PermPerk(Icons.photo_camera_rounded, 'Front, side and back progress photos', Tint.blue),
        PermPerk(Icons.restaurant_rounded, 'Snap a meal for your coach to check', Tint.green),
        PermPerk(Icons.lock_rounded, 'Photos stay private to you and your coach', Tint.purple),
      ],
      systemQuestion: 'Allow Train With Vimal to take pictures and record video?',
      systemWhat: 'Use your camera',
      okBody: 'We will open the camera when you add a photo.',
      noBody: 'Your phone blocked it. The app still works, you just can’t take photos in the app.',
    ),
    PermissionKind(
      key: 'photos',
      when: 'When you first pick a photo',
      icon: Icons.image_rounded,
      title: 'Pick from your photos',
      allowLabel: 'Allow photos',
      body: 'Choose photos you already took, like last month’s progress shot.',
      perks: [
        PermPerk(Icons.image_rounded, 'Add older progress photos to compare', Tint.blue),
        PermPerk(Icons.lock_rounded, 'Only the photos you pick are uploaded', Tint.green),
        PermPerk(Icons.bar_chart_rounded, 'See your change side by side', Tint.purple),
      ],
      systemQuestion: 'Allow Train With Vimal to access photos on this device?',
      systemWhat: 'See your photos',
      okBody: 'We will open your photos when you add one.',
      noBody: 'Your phone blocked it. The app still works, you just can’t pick photos from this device.',
    ),
  ];

  // ---------------- Welcome guide ----------------

  static const intro = <IntroSlide>[
    IntroSlide('WHY IT MATTERS', 'Good health is your real wealth',
        'More energy for work and family, better sleep and a calmer mind. A strong body makes every day easier.',
        [KeyValue('Energy', 'for the whole day'), KeyValue('Sleep', 'deeper and longer'), KeyValue('Mood', 'less stress')],
        Icons.self_improvement_rounded),
    IntroSlide('SMALL STEPS', 'Small steps, every single day',
        'You do not need a perfect week. Train a little, eat right, drink water and sleep well. It adds up fast.',
        [KeyValue('Train', '3–5 days a week'), KeyValue('Eat', 'simple, home food'), KeyValue('Rest', '7–8 hours')],
        Icons.directions_walk_rounded),
    IntroSlide('MEET YOUR COACH', 'Hi, I’m Vimal',
        'Certified nutritionist and personal trainer. I help people build strength and muscle the natural way, fully online.',
        [KeyValue('10+', 'years coaching'), KeyValue('300+', 'transformations'), KeyValue('17,000+', 'followers')],
        Icons.sports_gymnastics_rounded),
    IntroSlide('HOW IT WORKS', 'Your plan, made for you',
        'Tell us about you once. Your coach builds your workouts and meals, you log them here, and we check in every week.',
        [KeyValue('1', 'Answer a few questions'), KeyValue('2', 'Get your plan'), KeyValue('3', 'Log and check in')],
        Icons.assignment_turned_in_rounded),
  ];
}
