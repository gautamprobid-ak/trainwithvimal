import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/engage.dart';

/// Data for Forms & check-ins, Automations, Emails & alerts and Settings
/// (admin app), taken from the design scripts.
abstract final class EngageMock {
  // -------------------------------------------------------------------------
  // Forms
  // -------------------------------------------------------------------------

  static const forms = <FormDef>[
    FormDef(
      id: 'f-onboarding',
      name: 'New client questionnaire',
      kind: FormKind.onboarding,
      automations: ['Client onboarding · on approval'],
      published: true,
      updated: '18 Sep',
      questions: [
        FormQuestion(
            text: 'What is your main goal?',
            type: QuestionType.singleChoice,
            required: true,
            options: ['Fat loss', 'Muscle gain', 'Strength', 'General fitness', 'Event or sport prep']),
        FormQuestion(text: 'Why now? What made you start?', type: QuestionType.longText, help: 'A sentence or two is enough'),
        FormQuestion(text: 'Current weight (kg)', type: QuestionType.number, help: 'Morning, empty stomach', required: true),
        FormQuestion(text: 'Height (cm)', type: QuestionType.number, required: true),
        FormQuestion(
            text: 'How many days a week can you train?', type: QuestionType.singleChoice, required: true, options: ['2', '3', '4', '5', '6']),
        FormQuestion(
            text: 'Where will you train?',
            type: QuestionType.singleChoice,
            required: true,
            options: ['Gym', 'Home with equipment', 'Home, no equipment']),
        FormQuestion(
            text: 'How long have you trained with weights?',
            type: QuestionType.singleChoice,
            required: true,
            options: ['Never', 'Under 1 year', '1 to 3 years', 'More than 3 years']),
        FormQuestion(
            text: 'What do you eat?',
            type: QuestionType.dropdown,
            required: true,
            options: ['Vegetarian', 'Eggetarian', 'Non-vegetarian', 'Vegan', 'Jain'],
            other: true),
        FormQuestion(text: 'Foods you do not eat or are allergic to', type: QuestionType.shortText, help: 'e.g. mushrooms, peanuts'),
        FormQuestion(text: 'How many meals do you eat on a normal day?', type: QuestionType.number, required: true),
        FormQuestion(text: 'Average sleep per night (hours)', type: QuestionType.number, required: true),
        FormQuestion(text: 'Stress level in a normal week', type: QuestionType.scale, help: '1 = calm, 5 = very stressed', required: true),
        FormQuestion(
            text: 'What does your work day look like?',
            type: QuestionType.singleChoice,
            required: true,
            options: ['Desk job', 'On my feet', 'Shift work', 'Travel often'],
            other: true),
        FormQuestion(text: 'Do you take any supplements?', type: QuestionType.yesNo),
        FormQuestion(
            text: 'Anything else your coach should know?', type: QuestionType.longText, help: 'Travel, festivals, past diets that did not work'),
      ],
    ),
    FormDef(
      id: 'f-parq',
      name: 'PAR-Q health screening',
      kind: FormKind.onboarding,
      automations: ['Client onboarding · on approval'],
      published: true,
      updated: '2 Aug',
      questions: [
        FormQuestion(text: 'Has a doctor ever said you have a heart condition?', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Do you feel chest pain during physical activity?', type: QuestionType.yesNo, required: true),
        FormQuestion(
            text: 'Do you lose balance because of dizziness, or ever lose consciousness?', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Do you have a bone or joint problem that exercise could make worse?', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Are you taking medicine for blood pressure or a heart condition?', type: QuestionType.yesNo, required: true),
        FormQuestion(
            text: 'Any of these apply to you?',
            type: QuestionType.multiChoice,
            help: 'Tick all that apply',
            options: ['Diabetes', 'Thyroid', 'PCOS', 'Asthma', 'Pregnant or recently delivered', 'Surgery in the last 12 months']),
        FormQuestion(
            text: 'Past injuries or surgeries', type: QuestionType.longText, help: 'What, when, and whether it still bothers you'),
      ],
    ),
    FormDef(
      id: 'f-weekly',
      name: 'Weekly check-in',
      kind: FormKind.weekly,
      automations: ['Weekly check-in · Sundays 9 am', 'Reminder after 24 h'],
      published: true,
      updated: '27 Sep',
      questions: [
        FormQuestion(text: 'Morning weight (kg)', type: QuestionType.number, help: 'Empty stomach, same scale', required: true),
        FormQuestion(text: 'Energy this week', type: QuestionType.scale, help: '1 = drained, 5 = great', required: true),
        FormQuestion(text: 'Sleep quality', type: QuestionType.scale, help: '1 = poor, 5 = deep', required: true),
        FormQuestion(text: 'How closely did you follow the diet?', type: QuestionType.scale, help: '1 = off plan, 5 = on point', required: true),
        FormQuestion(text: 'Waist (cm)', type: QuestionType.number, help: 'At the navel, relaxed'),
        FormQuestion(
            text: 'Progress photos: front, side and back', type: QuestionType.photo, help: 'Same light and same spot as last time'),
        FormQuestion(text: 'Did you miss any workouts?', type: QuestionType.yesNo, required: true),
        FormQuestion(
            text: 'What got in the way this week?',
            type: QuestionType.multiChoice,
            help: 'Pick all that apply',
            options: ['Work', 'Travel', 'Low energy', 'Eating out'],
            other: true),
        FormQuestion(text: 'Anything for your coach?', type: QuestionType.longText, help: 'Pain, travel, stress, wins'),
      ],
    ),
    FormDef(
      id: 'f-morning',
      name: 'Morning check-in',
      kind: FormKind.daily,
      automations: ['Daily check-in · 7 am'],
      published: true,
      updated: '11 Sep',
      questions: [
        FormQuestion(text: 'Morning weight (kg)', type: QuestionType.number, help: 'Empty stomach'),
        FormQuestion(text: 'Hours of sleep last night', type: QuestionType.number, required: true),
        FormQuestion(text: 'Energy right now', type: QuestionType.scale, help: '1 = very low, 5 = great', required: true),
        FormQuestion(text: 'Any soreness or pain?', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Anything off today?', type: QuestionType.shortText),
      ],
    ),
    FormDef(
      id: 'f-bridal',
      name: 'Bridal Shred intake',
      kind: FormKind.onboarding,
      published: true,
      updated: '30 Sep',
      questions: [
        FormQuestion(text: 'Wedding date', type: QuestionType.shortText, help: 'e.g. 14 Feb 2027', required: true),
        FormQuestion(
            text: 'What do you want to change the most?',
            type: QuestionType.multiChoice,
            required: true,
            options: ['Arms', 'Waist', 'Back', 'Posture', 'Overall fat loss', 'Energy']),
        FormQuestion(text: 'Current weight (kg)', type: QuestionType.number, required: true),
        FormQuestion(text: 'How many functions will you attend in the last two weeks?', type: QuestionType.number),
        FormQuestion(
            text: 'How many days a week can you train?', type: QuestionType.singleChoice, required: true, options: ['3', '4', '5']),
        FormQuestion(text: 'Have you tried a crash diet before?', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Anything we should plan around?', type: QuestionType.longText, help: 'Travel, fittings, family events'),
      ],
    ),
    FormDef(
      id: 'f-nps',
      name: 'Monthly feedback',
      kind: FormKind.survey,
      updated: '1 Oct',
      questions: [
        FormQuestion(
            text: 'How likely are you to recommend us to a friend?',
            type: QuestionType.scale,
            help: '1 = not at all, 5 = definitely',
            required: true),
        FormQuestion(text: 'What is working well for you?', type: QuestionType.longText),
        FormQuestion(text: 'What should we improve?', type: QuestionType.longText),
        FormQuestion(text: 'How is your trainer doing?', type: QuestionType.scale, help: '1 = poor, 5 = excellent', required: true),
      ],
    ),
    FormDef(
      id: 'f-waiver',
      name: 'Liability waiver',
      kind: FormKind.waiver,
      published: true,
      updated: '14 Jun',
      questions: [
        FormQuestion(
            text: 'I understand that exercise carries a risk of injury and I take part at my own risk.',
            type: QuestionType.yesNo,
            required: true),
        FormQuestion(text: 'I have shared every medical condition my coach should know about.', type: QuestionType.yesNo, required: true),
        FormQuestion(text: 'Full name, as a signature', type: QuestionType.shortText, required: true),
      ],
    ),
    FormDef(
      id: 'f-photo-consent',
      name: 'Photo consent',
      kind: FormKind.waiver,
      published: true,
      updated: '14 Jun',
      questions: [
        FormQuestion(text: 'Can we share your progress photos?', type: QuestionType.yesNo, help: 'Your face is never shown without asking'),
        FormQuestion(text: 'Where may we use your results?', type: QuestionType.multiChoice, options: ['Instagram', 'Website', 'Nowhere']),
      ],
    ),
  ];

  /// Form builder "Answers so far" (value, label).
  static const formStats = [('38', 'sent this month'), ('31', 'answered'), ('82%', 'answer rate')];

  /// Template questions for a new form of [kind] (the first design form of that kind).
  static List<FormQuestion> templateFor(FormKind kind) {
    for (final f in forms) {
      if (f.kind == kind) return f.questions;
    }
    return const [];
  }

  // -------------------------------------------------------------------------
  // Automations
  // -------------------------------------------------------------------------

  /// Message templates by id (TPL).
  static const templateNames = {
    'invite': 'Client invite',
    'welcome': 'Welcome',
    'password': 'Password reset',
    'onboarding-reminder': 'Onboarding form reminder',
    'checkin-reminder': 'Check-in reminder',
    'missed-workouts': 'Missed workouts nudge',
    'feedback': 'Coach feedback',
    'birthday': 'Birthday wish',
    'renewal': 'Renewal reminder',
    'trainer-invite': 'Trainer invite',
  };

  /// Forms an automation can send (FORMS).
  static const formNames = {
    'f-onboarding': 'New client questionnaire',
    'f-weekly': 'Weekly check-in',
    'f-morning': 'Morning check-in',
    'f-parq': 'PAR-Q health screening',
  };

  static const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static const automations = <Automation>[
    Automation(
      id: 'a-onboarding',
      name: 'Client onboarding',
      trigger: TriggerKind.clientApproved,
      steps: [
        AutoStep.form('f-onboarding', [Channel.push, Channel.email]),
        AutoStep.wait(1, 'days'),
        AutoStep.message('onboarding-reminder', [Channel.whatsapp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Call the client about the onboarding form'),
      ],
      status: AutoStatus.on,
      changed: '20 Sep',
      running: 3,
      finished: 41,
    ),
    Automation(
      id: 'a-weekly',
      name: 'Weekly check-in',
      trigger: TriggerKind.weeklyCheckInDay,
      value: 7,
      steps: [
        AutoStep.form('f-weekly', [Channel.push, Channel.whatsapp]),
        AutoStep.wait(24, 'hours'),
        AutoStep.message('checkin-reminder', [Channel.push, Channel.whatsapp]),
        AutoStep.task('Review the weekly check-in'),
      ],
      status: AutoStatus.on,
      package: 'Quarterly Transformation',
      changed: '27 Sep',
      running: 38,
      finished: 412,
    ),
    Automation(
      id: 'a-inactive',
      name: 'Missed workouts nudge',
      trigger: TriggerKind.workoutsMissed,
      value: 3,
      steps: [
        AutoStep.message('missed-workouts', [Channel.push, Channel.inApp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Check in with the client'),
      ],
      status: AutoStatus.off,
      stopOnReply: false,
      changed: '12 Sep',
      running: 0,
      finished: 17,
    ),
    Automation(
      id: 'a-renewal',
      name: 'Renewal reminder',
      trigger: TriggerKind.renewalDue,
      value: 7,
      steps: [
        AutoStep.message('renewal', [Channel.email, Channel.whatsapp]),
        AutoStep.wait(4, 'days'),
        AutoStep.message('renewal', [Channel.push, Channel.whatsapp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Call the client before the package ends'),
      ],
      status: AutoStatus.on,
      changed: '25 Sep',
      running: 2,
      finished: 26,
    ),
    Automation(
      id: 'a-birthday',
      name: 'Birthday wish',
      trigger: TriggerKind.birthday,
      steps: [
        AutoStep.message('birthday', [Channel.push, Channel.whatsapp]),
        AutoStep.task('Send a personal birthday note'),
      ],
      status: AutoStatus.draft,
      stopOnReply: false,
      changed: '30 Aug',
    ),
  ];

  static const starters = <AutomationStarter>[
    AutomationStarter(
      id: 'st-onboarding',
      name: 'Client onboarding',
      trigger: TriggerKind.clientApproved,
      value: 0,
      steps: [
        AutoStep.form('f-onboarding', [Channel.push, Channel.email]),
        AutoStep.wait(1, 'days'),
        AutoStep.message('onboarding-reminder', [Channel.whatsapp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Call the client about the onboarding form'),
      ],
      note: 'Sends the onboarding form on approval, reminds on WhatsApp, then asks the trainer to call.',
    ),
    AutomationStarter(
      id: 'st-weekly',
      name: 'Weekly check-in',
      trigger: TriggerKind.weeklyCheckInDay,
      value: 7,
      steps: [
        AutoStep.form('f-weekly', [Channel.push, Channel.whatsapp]),
        AutoStep.wait(24, 'hours'),
        AutoStep.message('checkin-reminder', [Channel.push, Channel.whatsapp]),
        AutoStep.task('Review the weekly check-in'),
      ],
      note: 'Sends the check-in every Sunday, reminds after 24 hours, then gives the trainer a review task.',
    ),
    AutomationStarter(
      id: 'st-reminder',
      name: 'Missed check-in reminder',
      trigger: TriggerKind.checkInMissed,
      value: 24,
      steps: [
        AutoStep.message('checkin-reminder', [Channel.push, Channel.whatsapp]),
        AutoStep.wait(12, 'hours'),
        AutoStep.task('Call the client about the check-in'),
      ],
      note: 'A short reminder flow that works with any check-in.',
    ),
    AutomationStarter(
      id: 'st-missed',
      name: 'Missed workouts nudge',
      trigger: TriggerKind.workoutsMissed,
      value: 3,
      steps: [
        AutoStep.message('missed-workouts', [Channel.push, Channel.inApp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Check in with the client'),
      ],
      note: 'A friendly nudge first, then the trainer checks in.',
    ),
    AutomationStarter(
      id: 'st-renewal',
      name: 'Renewal reminder',
      trigger: TriggerKind.renewalDue,
      value: 7,
      steps: [
        AutoStep.message('renewal', [Channel.email, Channel.whatsapp]),
        AutoStep.wait(4, 'days'),
        AutoStep.message('renewal', [Channel.push, Channel.whatsapp]),
        AutoStep.wait(2, 'days'),
        AutoStep.task('Call the client before the package ends'),
      ],
      note: 'Two reminders before the package ends, then a call from the trainer.',
    ),
    AutomationStarter(
      id: 'st-welcome',
      name: 'Welcome week',
      trigger: TriggerKind.clientApproved,
      value: 0,
      steps: [
        AutoStep.message('welcome', [Channel.email, Channel.push]),
        AutoStep.wait(2, 'days'),
        AutoStep.form('f-parq', [Channel.push]),
        AutoStep.wait(5, 'days'),
        AutoStep.task('Ask how the first week went'),
      ],
      note: 'A welcome message, the health screening on day 2 and a first-week call.',
    ),
    AutomationStarter(
      id: 'st-birthday',
      name: 'Birthday wish',
      trigger: TriggerKind.birthday,
      value: 0,
      steps: [
        AutoStep.message('birthday', [Channel.push, Channel.whatsapp]),
        AutoStep.task('Send a personal birthday note'),
      ],
      note: 'A birthday message at 9 am and a reminder for the trainer.',
    ),
  ];

  /// Automations list stat cards: "Messages this month" and "Tasks for trainers".
  static const messagesThisMonth = ('214', '96% delivered · 61% opened');
  static const trainerTasks = ('9', '4 still open');

  /// Builder side card "Last 30 days".
  static const runStats = [('41', 'started'), ('36', 'finished'), ('5', 'stopped early')];
  static const runLog = <AutomationRun>[
    AutomationRun('Riya Sharma', 'Sent the form · stopped at step 1', '2 d ago'),
    AutomationRun('Neha Jain', 'Waiting · step 2 of 5', '5 h ago'),
    AutomationRun('Ishaan Mehta', 'Trainer task made · step 5', '3 d ago'),
    AutomationRun('Sana Khan', 'Finished', '6 d ago'),
  ];

  /// WhatsApp / push preview text of a message step (PREV).
  static const messagePreview = {
    'onboarding-reminder': 'Hi Sana, a quick reminder: Coach Meera needs your onboarding form to finish your plan. It takes about 5 minutes.',
    'checkin-reminder': 'Good morning Sana. Your weekly check-in is due today. Coach Meera is waiting for it.',
    'welcome': 'Hi Sana, your Train With Vimal account is active. Coach Meera has your plan ready.',
  };

  /// Note under a trigger (TNOTE).
  static const triggerNotes = {
    TriggerKind.goalReached: 'Uses the goal weight in each client’s profile.',
    TriggerKind.inactive: 'Opening the app, logging a meal or a workout all count as activity.',
    TriggerKind.streak: 'Starts once per streak, on the day it is reached.',
    TriggerKind.clientApproved: 'Runs once for each client.',
    TriggerKind.planStarts: 'Runs on the start date of the plan, at 9 am.',
    TriggerKind.checkInMissed: 'Counts from the time the check-in was due.',
  };

  /// Short trigger line used in the list ("When 3 workouts in a row are missed").
  static String triggerLine(TriggerKind? t, int v) => switch (t) {
        null => 'Pick what starts it',
        TriggerKind.clientApproved => 'When a new client is approved',
        TriggerKind.weeklyCheckInDay => 'Every ${days[v == 0 ? 7 : v]} at 9 am',
        TriggerKind.checkInMissed => 'When a check-in is not sent within $v hours',
        TriggerKind.workoutsMissed => 'When $v workouts in a row are missed',
        TriggerKind.renewalDue => '$v days before a package ends',
        TriggerKind.birthday => 'On the client’s birthday at 9 am',
        _ => t.label,
      };

  static String channelsLine(List<Channel> c) => c.isEmpty ? 'No channel yet' : c.map((x) => x.label).join(' and ');

  /// Plain-words line for a step.
  static String stepLine(AutoStep s) => switch (s.kind) {
        StepKind.wait => 'Wait ${s.amount} ${s.amount == 1 ? s.unit.replaceAll(RegExp(r's$'), '') : s.unit}',
        StepKind.form => 'Send the form “${formNames[s.ref] ?? s.ref}” by ${channelsLine(s.channels)}',
        StepKind.message => 'Send “${templateNames[s.ref] ?? s.ref}” by ${channelsLine(s.channels)}',
        StepKind.assign => 'Task for the ${s.unit == 'owner' ? 'owner' : 'assigned trainer'}: ${s.ref}',
      };

  /// Step chip in the automations list ("1 day", "Push + WhatsApp", "Task").
  static String stepChip(AutoStep s) => switch (s.kind) {
        StepKind.wait => '${s.amount} ${s.unit == 'hours' ? 'h' : (s.amount == 1 ? 'day' : 'days')}',
        StepKind.form => 'Form',
        StepKind.message => s.channels.isEmpty ? 'Message' : s.channels.map((x) => x.label).join(' + '),
        StepKind.assign => 'Task',
      };

  // -------------------------------------------------------------------------
  // Emails & alerts
  // -------------------------------------------------------------------------

  static const templateGroups = ['Access', 'Coaching', 'Packages', 'Team'];

  static const templates = <MsgTemplate>[
    MsgTemplate(id: 'invite', name: 'Client invite', group: 'Access', when: 'When you send an invite to a client', texts: {
      Channel.email: MsgText('{{coach_name}} invited you to {{gym_name}}',
          'Hi {{first_name}},\n\n{{coach_name}} has invited you to {{gym_name}}. Create your account to see your plan: {{package_name}}.\n\nThe invite is valid until {{date}}.'),
      Channel.whatsapp: MsgText('',
          'Hi {{first_name}}, {{coach_name}} has invited you to {{gym_name}}. Open the invite to create your account. It is valid until {{date}}.'),
    }),
    MsgTemplate(id: 'welcome', name: 'Welcome', group: 'Access', when: 'When a client is approved', texts: {
      Channel.email: MsgText('You are in! Your {{gym_name}} account is active',
          'Hi {{first_name}},\n\nYour account is approved and Coach {{coach_name}} has your plan ready.\n\nOpen the app to see your first workout.'),
      Channel.push: MsgText('Welcome aboard, {{first_name}}', 'Your account is active. Say hi to Coach {{coach_name}}.'),
      Channel.whatsapp: MsgText('',
          'Hi {{first_name}}, your {{gym_name}} account is active. Coach {{coach_name}} has your plan ready. Open the app to see your first workout.'),
      Channel.inApp: MsgText('Welcome aboard, {{first_name}}', 'Coach {{coach_name}} has your plan ready. Start with your first workout.'),
    }),
    MsgTemplate(id: 'password', name: 'Password reset', group: 'Access', when: 'When someone asks to reset their password', texts: {
      Channel.email: MsgText('Reset your {{gym_name}} password',
          'Hi {{first_name}},\n\nUse the link in this email to set a new password. It works for 30 minutes.\n\nIf you did not ask for this, you can ignore this email.'),
    }),
    MsgTemplate(id: 'onboarding-reminder', name: 'Onboarding form reminder', group: 'Coaching', when: 'When the onboarding form is still open', texts: {
      Channel.email: MsgText('Your onboarding form is waiting',
          'Hi {{first_name}},\n\nCoach {{coach_name}} needs your onboarding form to finish your plan. It takes about 5 minutes.'),
      Channel.push: MsgText('Finish your onboarding form', 'Coach {{coach_name}} needs it to build your plan. About 5 minutes.'),
      Channel.whatsapp: MsgText('',
          'Hi {{first_name}}, a quick reminder: Coach {{coach_name}} needs your onboarding form to finish your plan. It takes about 5 minutes.'),
    }),
    MsgTemplate(id: 'checkin-reminder', name: 'Check-in reminder', group: 'Coaching', when: 'When a check-in is due or was missed', texts: {
      Channel.email: MsgText('Weekly check-in time, {{first_name}}',
          'Hi {{first_name}},\n\nIt takes 2 minutes: your weight, measurements and how the week went. Coach {{coach_name}} replies with feedback.'),
      Channel.push: MsgText('Check-in time', 'Your weekly check-in is due today. It takes 2 minutes.'),
      Channel.whatsapp: MsgText('', 'Good morning {{first_name}}. Your weekly check-in is due today. Coach {{coach_name}} is waiting for it.'),
      Channel.inApp: MsgText('Check-in time', 'Share your weight and how the week went. It takes 2 minutes.'),
    }),
    MsgTemplate(id: 'missed-workouts', name: 'Missed workouts nudge', group: 'Coaching', when: 'When workouts are missed in a row', texts: {
      Channel.push: MsgText('All good, {{first_name}}?', 'A 20-minute workout is ready whenever you are.'),
      Channel.whatsapp: MsgText('',
          'Hi {{first_name}}, we noticed a few missed workouts. All good? A short 20-minute session is ready when you are.'),
      Channel.inApp: MsgText('Ease back in', 'A 20-minute workout is ready. Start small today.'),
    }),
    MsgTemplate(id: 'feedback', name: 'Coach feedback', group: 'Coaching', when: 'When the coach replies to a check-in', texts: {
      Channel.push: MsgText('Coach {{coach_name}} replied', 'Your check-in feedback is ready.'),
      Channel.inApp: MsgText('Coach {{coach_name}} replied', 'Read the feedback on your latest check-in.'),
    }),
    MsgTemplate(id: 'birthday', name: 'Birthday wish', group: 'Coaching', when: 'On the client’s birthday', texts: {
      Channel.push: MsgText('Happy birthday, {{first_name}}', 'Have a great day. Wishes from Coach {{coach_name}} and the team.'),
      Channel.whatsapp: MsgText('',
          'Happy birthday, {{first_name}}! Wishing you a strong and healthy year. Coach {{coach_name}} and the {{gym_name}} team.'),
    }),
    MsgTemplate(id: 'renewal', name: 'Renewal reminder', group: 'Packages', when: 'Before a package ends', texts: {
      Channel.email: MsgText('Your {{package_name}} ends on {{date}}',
          'Hi {{first_name}},\n\nYour {{package_name}} ends on {{date}}. Renew to keep training with Coach {{coach_name}}.'),
      Channel.push: MsgText('Your plan ends soon', '{{package_name}} ends on {{date}}. Renew to keep going.'),
      Channel.whatsapp: MsgText('', 'Hi {{first_name}}, your {{package_name}} ends on {{date}}. Renew to keep training with Coach {{coach_name}}.'),
    }),
    MsgTemplate(id: 'trainer-invite', name: 'Trainer invite', group: 'Team', when: 'When you invite a trainer', texts: {
      Channel.email: MsgText('Join {{gym_name}} as a trainer',
          'Hi {{first_name}},\n\nYou have been invited to join {{gym_name}} as a trainer. Set up your profile in about 3 minutes. The invite is valid until {{date}}.'),
    }),
  ];

  static const templateUses = {
    'onboarding-reminder': [TemplateUse('Client onboarding', 'Step 3 · WhatsApp')],
    'checkin-reminder': [TemplateUse('Weekly check-in', 'Step 3 · Push and WhatsApp'), TemplateUse('Missed check-in reminder', 'Step 1 · Push and WhatsApp')],
    'missed-workouts': [TemplateUse('Missed workouts nudge', 'Step 1 · Push and In-app')],
    'renewal': [TemplateUse('Renewal reminder', 'Steps 1 and 3')],
    'birthday': [TemplateUse('Birthday wish', 'Step 1 · Push and WhatsApp')],
  };

  static const systemSends = {
    'invite': 'Sent by the app when you invite a client from Clients or Approvals',
    'welcome': 'Sent by the app when you approve someone in Approvals',
    'password': 'Sent by the app on Forgot password',
    'feedback': 'Sent by the app when a trainer replies to a check-in',
    'trainer-invite': 'Sent by the app when you add a trainer',
  };

  /// Sample values for the preview.
  static const sampleVars = {
    'first_name': 'Sana',
    'coach_name': 'Meera',
    'gym_name': 'Train With Vimal',
    'package_name': 'Quarterly Transformation',
    'date': '7 Oct',
  };

  static String fillVars(String s) =>
      s.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (m) => sampleVars[m.group(1)] ?? m.group(0)!);

  static const channelHint = {
    Channel.email: 'Subject and a longer message',
    Channel.push: 'Short title and text on the phone',
    Channel.whatsapp: 'From your WhatsApp number',
    Channel.inApp: 'In the app\'s notifications',
  };

  static const teamAlerts = <TeamAlert>[
    TeamAlert(id: 'new-client', name: 'New client', description: 'Sign-up or invite accepted', channels: {Channel.email, Channel.push, Channel.inApp}),
    TeamAlert(id: 'checkin', name: 'Check-in submitted', description: 'Weekly check-in by a client', channels: {Channel.push, Channel.inApp}),
    TeamAlert(id: 'plan-updated', name: 'Plan updated', description: 'Trainer edits a program or meal plan', channels: {Channel.inApp}),
    TeamAlert(
        id: 'missed-workout',
        name: 'Missed workout',
        description: '2+ workouts skipped in a row',
        channels: {Channel.push, Channel.whatsapp, Channel.inApp}),
  ];

  // -------------------------------------------------------------------------
  // Settings
  // -------------------------------------------------------------------------

  static const permissions = <RolePermission>[
    RolePermission('View all clients', trainer: false, client: false),
    RolePermission('View assigned clients', trainer: true, client: false),
    RolePermission('Assign / reassign clients', trainer: false, client: false),
    RolePermission('Create programs & meal plans', trainer: true, client: false),
    RolePermission('Daily + weekly check-ins', trainer: true, client: true),
    RolePermission('Manage content library', trainer: true, client: false),
    RolePermission('Schedule sessions', trainer: true, client: false),
    RolePermission('Add trainers', trainer: false, client: false),
    RolePermission('Automations & settings', trainer: false, client: false),
  ];

  static const roles = <RoleInfo>[
    RoleInfo(
      name: 'Admin',
      count: 'Owner · only one · you',
      scope: 'Everything: clients, trainers, plans, content and settings',
      note: 'There is exactly one admin per gym. Ownership cannot be moved from inside the app, and trainers cannot be given admin access.',
      tint: Tint.blue,
      icon: Icons.admin_panel_settings_rounded,
    ),
    RoleInfo(
      name: 'Trainer',
      count: '11 members',
      scope: 'Assigned clients, programs, meal plans, daily and weekly check-ins',
      note: 'A trainer\'s access level is set on the trainer\'s own profile.',
      tint: Tint.green,
      icon: Icons.sports_rounded,
      link: 'trainers',
      linkLabel: 'Open trainers',
    ),
    RoleInfo(
      name: 'Client',
      count: '142 active',
      scope: 'Own plan, logging and check-ins',
      note: 'Clients only ever see their own plan and data.',
      tint: Tint.amber,
      icon: Icons.person_rounded,
      link: 'clients',
      linkLabel: 'Open clients',
    ),
  ];

  static const integrations = <Integration>[
    Integration(
      id: 'whatsapp',
      short: 'WA',
      name: 'WhatsApp Business',
      description: 'Reminders, check-in nudges and invites on WhatsApp, from your business number.',
      used: [IntegrationUse('5 automations', 'automations'), IntegrationUse('8 client messages', 'emails'), IntegrationUse('Invite links', 'approvals')],
      bg: Color(0xFFDCF8E7),
      fg: Color(0xFF0B6B3A),
      steps: [
        ('Connect a business number', 'The number must be registered with the WhatsApp Business API.'),
        ('Display name review', 'Meta reviews the display name, usually within 24 hours.'),
        ('Message templates', 'Reminders and nudges are sent from approved templates.'),
      ],
    ),
    Integration(
      id: 'email',
      short: 'EM',
      name: 'Email sending',
      description: 'Welcome emails, check-in reminders and alerts from your own address.',
      used: [IntegrationUse('10 client messages', 'emails'), IntegrationUse('Team alerts and digest', 'emails'), IntegrationUse('Forms sent by email', 'forms')],
      bg: Color(0xFFE0EAFF),
      fg: Color(0xFF1E40AF),
      steps: [
        ('Add your domain', 'Tell us the domain your emails should come from, for example trainwithvimal.com.'),
        ('Add three DNS records', 'SPF, DKIM and DMARC records go into your domain provider (GoDaddy, Hostinger and others).'),
        ('We verify the records', 'DNS changes take 15 minutes to 48 hours. Until then emails keep going from the platform address.'),
      ],
    ),
    Integration(
      id: 'health',
      short: 'HC',
      name: 'Apple Health / Health Connect',
      description: 'Steps, sleep, heart rate and workouts from client phones.',
      used: [IntegrationUse('Client profiles', 'clientProfile'), IntegrationUse('Habits (steps)', 'habits'), IntegrationUse('Daily check-in', 'forms')],
      bg: Color(0xFFFDE7EE),
      fg: Color(0xFFA3123E),
    ),
  ];

  static const integrationStates = {'whatsapp': IntegrationState.on, 'email': IntegrationState.dns, 'health': IntegrationState.off};

  /// DNS records (type, host, status, verified).
  static const dnsRecords = [('SPF', 'TXT · @', 'Verified', true), ('DKIM', 'TXT · twv._domainkey', 'Verified', true), ('DMARC', 'TXT · _dmarc', 'Waiting', false)];

  /// Health data the client app can read (key, label, help).
  static const healthData = [
    ('steps', 'Steps', 'Daily step count on the client profile and in Today'),
    ('sleep', 'Sleep', 'Hours slept, next to the daily check-in'),
    ('hr', 'Heart rate', 'Resting heart rate on the progress tab'),
    ('wo', 'Workouts', 'Runs and rides done outside the app'),
  ];

  static const brandSwatches = [
    Color(0xFF2563EB),
    Color(0xFF4F46E5),
    Color(0xFF0D9488),
    Color(0xFF16A34A),
    Color(0xFFEA580C),
    Color(0xFFDC2626),
    Color(0xFFDB2777),
    Color(0xFF111111),
  ];

  static const gymName = 'Train With Vimal';
  static const gymEmail = 'hello@trainwithvimal.com';
  static const gymPhone = '+91 98200 12345';
  static const gymAddress = '2nd floor, Linking Road, Bandra West, Mumbai 400050';
  static const gymWeb = 'instagram.com/trainwithvimal';

  /// Tint used for the "t1..t4" tones of the design.
  static const tones = [Tint.blue, Tint.green, Tint.amber, Tint.purple];

}
