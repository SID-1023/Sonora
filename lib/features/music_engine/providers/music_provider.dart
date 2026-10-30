import '../models/music_provider_page.dart';

abstract interface class MusicProvider {
  String get id;

  String get displayName;

  bool get isEnabled;

  String? get disabledReason;

  Future<MusicProviderPage> search(
    String query, {
    required int offset,
    required int limit,
  });
}
