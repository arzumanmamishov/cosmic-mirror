import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/daily_reading/data/models/daily_reading_model.dart';
import 'package:cosmic_mirror/features/daily_reading/domain/entities/daily_reading.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
