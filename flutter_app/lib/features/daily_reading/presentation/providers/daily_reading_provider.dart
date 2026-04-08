import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../data/models/daily_reading_model.dart';
import '../../domain/entities/daily_reading.dart';

final dailyReadingProvider =
    FutureProvider.autoDispose<DailyReading>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.dailyReading,
  );
  return DailyReadingModel.fromJson(data);
});

final readingByDateProvider =
    FutureProvider.autoDispose.family<DailyReading, String>((ref, date) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get<Map<String, dynamic>>(
    ApiEndpoints.dailyReadingByDate(date),
  );
  return DailyReadingModel.fromJson(data);
});
