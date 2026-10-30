
abstract final class TimeFormatter {
  TimeFormatter._();

  /// Converts a Duration into mm:ss format.
  /// Example: 185 seconds → 03:05
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Converts seconds into mm:ss format.
  static String formatSeconds(int seconds) {
    return formatDuration(Duration(seconds: seconds));
  }

  /// Returns the remaining time of a track.
  static String formatRemainingTime(
    Duration position,
    Duration duration,
  ) {
    final remaining = duration - position;

    if (remaining.isNegative) {
      return '-00:00';
    }

    return '-${formatDuration(remaining)}';
  }

  /// Returns a percentage between 0.0 and 1.0.
  static double calculateProgress(
    Duration position,
    Duration duration,
  ) {
    if (duration.inMilliseconds <= 0) {
      return 0.0;
    }

    final progress =
        position.inMilliseconds / duration.inMilliseconds;

    return progress.clamp(0.0, 1.0).toDouble();
  }
}
