/// Represents the evaluated outcome of a geofence entry or exit event.
class GeofenceEventResult {
  final Map<String, dynamic> zone;
  final String message;
  final String eventType;
  final bool isSimulated;
  final bool notificationAllowed;
  final DateTime timestamp;
  final String? suppressionReason;

  GeofenceEventResult({
    required this.zone,
    required this.message,
    required this.eventType,
    this.isSimulated = false,
    required this.notificationAllowed,
    DateTime? timestamp,
    this.suppressionReason,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service evaluating geofence events against safety rules:
/// - Cooldown window (60 minutes per risk zone)
/// - Quiet hours suppression (10:00 PM – 7:00 AM)
/// - Supportive message generation
class GeofenceService {
  static final GeofenceService _instance = GeofenceService._internal();
  factory GeofenceService() => _instance;
  GeofenceService._internal();

  /// Cooldown duration between notifications for the same zone.
  static const int cooldownMinutes = 60;

  /// Quiet hours window (10:00 PM to 7:00 AM).
  static const int quietHoursStartHour = 22;
  static const int quietHoursEndHour = 7;

  final Map<String, DateTime> _lastTriggerTimes = {};

  /// Checks if given time falls into user quiet hours (10 PM to 7 AM).
  bool isQuietHours(DateTime time) {
    final hour = time.hour;
    return hour >= quietHoursStartHour || hour < quietHoursEndHour;
  }

  /// Checks if a zone is currently subject to cooldown.
  bool isInCooldown(String zoneId, DateTime now) {
    final lastTime = _lastTriggerTimes[zoneId];
    if (lastTime == null) return false;
    return now.difference(lastTime) < const Duration(minutes: cooldownMinutes);
  }

  /// Evaluates an entry event for the specified risk zone.
  GeofenceEventResult evaluateEntry(
    Map<String, dynamic> zone, {
    bool isSimulated = false,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final zoneName = zone['name'] ?? 'Smoking Risk Area';
    final riskLevel = zone['risk_level'] ?? 'medium';
    final zoneId = (zone['id'] ?? zoneName).toString();

    // 1. Check Quiet Hours rule (10 PM – 7 AM)
    if (isQuietHours(now)) {
      return GeofenceEventResult(
        zone: zone,
        message: 'You have entered "$zoneName". Staying calm during quiet hours.',
        eventType: 'entry',
        isSimulated: isSimulated,
        notificationAllowed: false,
        timestamp: now,
        suppressionReason: 'Quiet hours active (10:00 PM – 7:00 AM)',
      );
    }

    // 2. Check Cooldown rule (60 minutes)
    if (isInCooldown(zoneId, now)) {
      final lastTime = _lastTriggerTimes[zoneId]!;
      final elapsed = now.difference(lastTime);
      final remaining = cooldownMinutes - elapsed.inMinutes;
      return GeofenceEventResult(
        zone: zone,
        message: 'You have entered "$zoneName". Cooldown in effect.',
        eventType: 'entry',
        isSimulated: isSimulated,
        notificationAllowed: false,
        timestamp: now,
        suppressionReason: 'Cooldown active (60 mins interval — ${remaining > 0 ? remaining : 1}m remaining)',
      );
    }

    // 3. Notification allowed — record trigger time
    _lastTriggerTimes[zoneId] = now;

    return GeofenceEventResult(
      zone: zone,
      message: 'You are near "$zoneName" ($riskLevel risk). Take 3 deep breaths and remember your motivation to quit.',
      eventType: 'entry',
      isSimulated: isSimulated,
      notificationAllowed: true,
      timestamp: now,
      suppressionReason: null,
    );
  }

  /// Evaluates an exit event for the specified risk zone.
  GeofenceEventResult evaluateExit(
    Map<String, dynamic> zone, {
    bool isSimulated = false,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final zoneName = zone['name'] ?? 'Smoking Risk Area';

    return GeofenceEventResult(
      zone: zone,
      message: 'You have exited "$zoneName". Well done staying mindful!',
      eventType: 'exit',
      isSimulated: isSimulated,
      notificationAllowed: true,
      timestamp: now,
      suppressionReason: null,
    );
  }

  /// Clears stored cooldown timestamps (useful for testing and reset).
  void clearCooldowns() {
    _lastTriggerTimes.clear();
  }
}
