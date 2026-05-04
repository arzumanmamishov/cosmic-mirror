import 'package:cosmic_mirror/features/human_design/data/repositories/human_design_repository.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final humanDesignRepositoryProvider = Provider<HumanDesignRepository>(
  (ref) => HumanDesignRepository(ref.read(apiClientProvider)),
);

final humanDesignProvider =
    FutureProvider.autoDispose<HumanDesignChart>((ref) async {
  return ref.read(humanDesignRepositoryProvider).getChart();
});
