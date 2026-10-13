import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';

class HealthScore {
  const HealthScore({required this.value, required this.hasScore});
  final int value;
  final bool hasScore;

  factory HealthScore.fromJson(Map<String, dynamic> json) =>
      HealthScore(value: json['value'] as int, hasScore: json['hasScore'] as bool);
}

class DashboardSummary {
  const DashboardSummary({required this.totalSpentThisMonth, required this.healthScore});
  final double totalSpentThisMonth;
  final HealthScore healthScore;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) => DashboardSummary(
        totalSpentThisMonth: (json['totalSpentThisMonth'] as num).toDouble(),
        healthScore: HealthScore.fromJson(json['healthScore'] as Map<String, dynamic>),
      );
}

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/dashboard/summary');
  return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
});

final activeCycleProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/cycles/active');
  return response.data as Map<String, dynamic>?;
});
