import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthController extends GetxController {
  final _sb = Supabase.instance.client;

  final weights = <Map<String, dynamic>>[].obs;
  final workouts = <Map<String, dynamic>>[].obs;

  final isLoadingWeights = false.obs;
  final isLoadingWorkouts = false.obs;

  String get _uid => _sb.auth.currentUser!.id;

  Map<String, dynamic>? get latestWeight =>
      weights.isEmpty ? null : weights.first;

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchWeights(), fetchWorkouts()]);
  }

  Future<void> fetchWeights() async {
    isLoadingWeights.value = true;
    try {
      final data = await _sb
          .from('health_weights')
          .select()
          .eq('user_id', _uid)
          .order('recorded_at', ascending: false)
          .order('created_at', ascending: false);

      weights.assignAll(List<Map<String, dynamic>>.from(data));
    } finally {
      isLoadingWeights.value = false;
    }
  }

  Future<void> addWeight({
    required double weightKg,
    required DateTime recordedAt,
    String? note,
  }) async {
    await _sb.from('health_weights').insert({
      'user_id': _uid,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String().substring(0, 10),
      'note': note,
    });
    await fetchWeights();
  }

  Future<void> updateWeight({
    required String id,
    required double weightKg,
    required DateTime recordedAt,
    String? note,
  }) async {
    await _sb.from('health_weights').update({
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String().substring(0, 10),
      'note': note,
    }).eq('id', id);
    await fetchWeights();
  }

  Future<void> deleteWeight(String id) async {
    await _sb.from('health_weights').delete().eq('id', id);
    await fetchWeights();
  }

  Future<void> fetchWorkouts() async {
    isLoadingWorkouts.value = true;
    try {
      final data = await _sb
          .from('health_workouts')
          .select()
          .eq('user_id', _uid)
          .order('day_of_week', ascending: true)
          .order('start_time', ascending: true);

      workouts.assignAll(List<Map<String, dynamic>>.from(data));
    } finally {
      isLoadingWorkouts.value = false;
    }
  }

  List<Map<String, dynamic>> workoutsForDay(int day) =>
      workouts.where((e) => e['day_of_week'] == day).toList();

  Future<void> addWorkout({
    required int dayOfWeek, // 1..6
    required String title,
    String? description,
    String? startTime, // "HH:mm:ss" atau "HH:mm"
    String? endTime,
  }) async {
    await _sb.from('health_workouts').insert({
      'user_id': _uid,
      'day_of_week': dayOfWeek,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
    });
    await fetchWorkouts();
  }

  Future<void> updateWorkout({
    required String id,
    required String title,
    String? description,
    String? startTime,
    String? endTime,
  }) async {
    await _sb.from('health_workouts').update({
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
    }).eq('id', id);
    await fetchWorkouts();
  }

  Future<void> deleteWorkout(String id) async {
    await _sb.from('health_workouts').delete().eq('id', id);
    await fetchWorkouts();
  }
}
