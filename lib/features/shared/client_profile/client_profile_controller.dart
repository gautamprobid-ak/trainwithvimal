import 'package:flutter/material.dart';

import 'package:train_with_vimal/data/mock/client_profile_mock.dart';
import 'package:train_with_vimal/data/mock/people_mock.dart';
import 'package:train_with_vimal/data/models/client_profile.dart';
import 'package:train_with_vimal/data/models/people.dart';

/// Who is looking at the profile. Admin can change the trainer and passwords; a trainer cannot.
enum ProfileRole { admin, trainer }

/// State shared by every tab and sheet of the client profile.
class ClientProfileController extends ChangeNotifier {
  ClientProfileController({required String clientId, required this.role})
      : client = PeopleMock.clients.firstWhere((c) => c.id == clientId, orElse: () => PeopleMock.clients.first) {
    trainer = client.trainer;
    status = client.status;
  }

  final ProfileRole role;
  final ClientSummary client;
  late String trainer;
  late ClientStatus status;

  bool get isAdmin => role == ProfileRole.admin;
  String get name => client.name;
  String get first => client.name.split(' ').first;
  String get initials => client.initials;

  /// Puts this client's name into the design copy (written for Riya Sharma).
  String r(String s) => s.replaceAll('Riya Sharma', name).replaceAll('Riya', first);

  // ── Navigation inside the profile ──
  String tab = 'overview';
  String planTab = 'workout';
  String logTab = 'workouts';
  String range = '30';
  bool compare = false;
  String form = 'onb';

  /// Plan editor (Edit for Riya) and "Duplicate and edit" mode.
  bool planEdit = false;
  bool dup = false;

  /// Form editor.
  bool formEdit = false;
  bool formDup = false;

  void goTab(String t) {
    tab = t;
    notifyListeners();
  }

  void setPlanTab(String p) {
    planTab = p;
    planEdit = false;
    dup = false;
    notifyListeners();
  }

  void setLogTab(String l) {
    logTab = l;
    notifyListeners();
  }

  void setRange(String r) {
    range = r;
    notifyListeners();
  }

  void setCompare(bool v) {
    compare = v;
    notifyListeners();
  }

  void setForm(String f) {
    form = f;
    formEdit = false;
    formDup = false;
    notifyListeners();
  }

  void openFormEdit({bool duplicate = false}) {
    formEdit = true;
    formDup = duplicate;
    notifyListeners();
  }

  void closeFormEdit() {
    formEdit = false;
    formDup = false;
    notifyListeners();
  }

  void openPlanEdit({String? plan, bool duplicate = false, String? day}) {
    tab = 'plans';
    if (plan != null) planTab = plan;
    planEdit = true;
    dup = duplicate;
    if (day != null && workoutDays.any((d) => d.day == day)) editDay = day;
    notifyListeners();
  }

  void closePlanEdit() {
    planEdit = false;
    dup = false;
    notifyListeners();
  }

  // ── Header changes ──
  void setTrainer(String t) {
    trainer = t;
    notifyListeners();
  }

  void setStatus(ClientStatus s) {
    status = s;
    notifyListeners();
  }

  // ── Plans: workout view + editor ──
  String viewDay = 'Tue';
  String mealDay = 'Wed';
  String editDay = 'Tue';
  List<WorkoutDay> workoutDays = [...ClientProfileMock.workoutDays];

  void setViewDay(String d) {
    viewDay = d;
    notifyListeners();
  }

  void setMealDay(String d) {
    mealDay = d;
    notifyListeners();
  }

  void setEditDay(String d) {
    editDay = d;
    notifyListeners();
  }

  WorkoutDay get currentEditDay => workoutDays.firstWhere((d) => d.day == editDay);

  void updateEditDay(List<WorkoutExercise> exercises) {
    workoutDays = [
      for (final d in workoutDays) d.day == editDay ? d.copyWith(edited: true, exercises: exercises) : d,
    ];
    notifyListeners();
  }

  void restoreWorkout(List<WorkoutDay> days) {
    workoutDays = days;
    notifyListeners();
  }

  // ── Plans: meal editor ──
  List<PlanMeal> meals = [...ClientProfileMock.editorMeals];

  void setMeals(List<PlanMeal> m) {
    meals = m;
    notifyListeners();
  }

  // ── Notes ──
  List<ProfileNote> notes = [...ClientProfileMock.notes];

  void addNote(ProfileNote n) {
    final flags = notes.where((x) => x.flag).toList();
    final rest = notes.where((x) => !x.flag).toList();
    notes = n.flag ? [n, ...flags, ...rest] : [...flags, n, ...rest];
    notifyListeners();
  }

  /// Latest non-flag note (Overview "Latest note").
  ProfileNote get latestNote => notes.firstWhere((n) => !n.flag, orElse: () => notes.first);

  // ── Content hidden for this client ──
  final Set<String> hiddenContent = {};

  void hideContent(String title) {
    hiddenContent.add(title);
    notifyListeners();
  }

  void showContent(String title) {
    hiddenContent.remove(title);
    notifyListeners();
  }
}

/// Gives every widget under the profile access to [ClientProfileController].
class ProfileScope extends InheritedNotifier<ClientProfileController> {
  const ProfileScope({super.key, required ClientProfileController controller, required super.child}) : super(notifier: controller);

  static ClientProfileController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileScope>()!.notifier!;

  /// Read without listening (for callbacks).
  static ClientProfileController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ProfileScope>()!.notifier!;
}
