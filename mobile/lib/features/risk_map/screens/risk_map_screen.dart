import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as ll;
import 'package:go_router/go_router.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/location_service.dart';
import '../../../services/geofence_service.dart';

enum MapEngine {
  openStreetMap,
  googleMaps,
}

class RiskMapScreen extends ConsumerStatefulWidget {
  const RiskMapScreen({super.key});

  @override
  ConsumerState<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends ConsumerState<RiskMapScreen> {
  final LocationService _locationService = LocationService();
  final GeofenceService _geofenceService = GeofenceService();
  final fmap.MapController _fmapController = fmap.MapController();

  MapEngine _mapEngine = MapEngine.openStreetMap;
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  bool _isLocating = false;
  bool _showLegend = false;
  LatLng? _currentPosition;
  LatLng? _pinnedLocation;
  LocationStatus _locationStatus = LocationStatus.notRequested;

  // Default fallback center (New Delhi / India coordinates, matching demo seed)
  static const LatLng _defaultCenter = LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    // 1. Load risk zones
    await _loadZones();

    // 2. Check location status
    final status = await _locationService.checkPermissionStatus();
    if (mounted) {
      setState(() => _locationStatus = status);
    }

    if (status == LocationStatus.granted) {
      _fetchCurrentLocation(animateCamera: true);
    } else if (status == LocationStatus.notRequested) {
      _showLocationConsentDialog();
    }
  }

  Future<void> _loadZones() async {
    try {
      final repo = ref.read(locationRepoProvider);
      final zones = await repo.getRiskZones();
      if (mounted) {
        ref.read(riskZonesProvider.notifier).state = zones;
      }
    } catch (_) {
      if (mounted) {
        final demo = ref.read(demoServiceProvider);
        ref.read(riskZonesProvider.notifier).state = demo.riskZones;
      }
    }
  }

  void _adaptDemoZonesToUserLocation(double userLat, double userLng) {
    final zones = ref.read(riskZonesProvider);
    if (zones.isEmpty) return;

    final firstLat = (zones[0]['latitude'] as num?)?.toDouble() ?? 0.0;
    final firstLng = (zones[0]['longitude'] as num?)?.toDouble() ?? 0.0;
    final distFromFirst = _locationService.distanceBetween(userLat, userLng, firstLat, firstLng);

    // If demo zones are far (> 30 km) from user's device location, anchor them near the user
    if (distFromFirst > 30000) {
      final adapted = [
        {
          ...zones[0],
          'latitude': userLat + 0.0024,
          'longitude': userLng + 0.0019,
          'name': 'Work / Office Break Area',
        },
        if (zones.length > 1)
          {
            ...zones[1],
            'latitude': userLat - 0.0020,
            'longitude': userLng + 0.0025,
            'name': 'Corner Tea Stall / Kiosk',
          },
        if (zones.length > 2)
          {
            ...zones[2],
            'latitude': userLat + 0.0016,
            'longitude': userLng - 0.0028,
            'name': 'Bus / Metro Transit Stop',
          },
      ];
      for (int i = 3; i < zones.length; i++) {
        adapted.add(zones[i]);
      }
      ref.read(riskZonesProvider.notifier).state = adapted;
    }
  }

  Future<void> _fetchCurrentLocation({bool animateCamera = false}) async {
    setState(() => _isLocating = true);
    final pos = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _isLocating = false;
        if (pos != null) {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
          _locationStatus = LocationStatus.granted;
        }
      });
      if (pos != null) {
        _adaptDemoZonesToUserLocation(pos.latitude, pos.longitude);
        if (animateCamera) {
          _recenterMap(pos.latitude, pos.longitude);
        }
      }
    }
  }

  void _recenterMap(double lat, double lng) {
    if (_mapEngine == MapEngine.openStreetMap) {
      _fmapController.move(ll.LatLng(lat, lng), 15.5);
    } else if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 15.5),
        ),
      );
    }
  }

  void _showLocationConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.teal),
            SizedBox(width: 10),
            Text('Location Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CraveGuard uses your device location to:',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            SizedBox(height: 10),
            Text('• Show your real-time position on the live map.\n'
                '• Help you identify places where you frequently experience cravings.\n'
                '• Deliver timely, discreet coping reminders near confirmed triggers.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Privacy First: Your location data stays strictly on your device. We never sell or track your background movement without explicit consent.',
              style: TextStyle(fontSize: 11, color: AppColors.mintGreen, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _locationStatus = LocationStatus.denied);
            },
            child: const Text('Explore Manually', style: TextStyle(color: AppColors.textSecondaryDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final status = await _locationService.requestPermission();
              setState(() => _locationStatus = status);
              if (status == LocationStatus.granted) {
                _fetchCurrentLocation(animateCamera: true);
              }
            },
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Map<String, dynamic>> zones) {
    final markers = <Marker>{};

    for (final zone in zones) {
      final id = zone['id']?.toString() ?? UniqueKey().toString();
      final lat = (zone['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (zone['longitude'] as num?)?.toDouble() ?? 0.0;
      if (lat == 0.0 && lng == 0.0) continue;

      final isConfirmed = zone['is_user_confirmed'] == true;
      final riskLevel = (zone['risk_level'] as String?)?.toLowerCase() ?? 'medium';

      double hue;
      if (!isConfirmed) {
        hue = BitmapDescriptor.hueYellow;
      } else if (riskLevel == 'high') {
        hue = BitmapDescriptor.hueRed;
      } else if (riskLevel == 'medium') {
        hue = BitmapDescriptor.hueOrange;
      } else {
        hue = BitmapDescriptor.hueCyan;
      }

      markers.add(
        Marker(
          markerId: MarkerId(id),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: zone['name'] ?? 'Risk Zone',
            snippet: isConfirmed ? '${riskLevel.toUpperCase()} RISK • Tap for details' : 'SUGGESTED TRIGGER • Tap to review',
            onTap: () => _showZoneDetailsSheet(zone),
          ),
          onTap: () => _showZoneDetailsSheet(zone),
        ),
      );
    }

    // Pinned marker if in manual pin-drop mode
    if (_pinnedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('manual_pin'),
          position: _pinnedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'New Zone Pin', snippet: 'Tap "Add Zone" below to save'),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildCircles(List<Map<String, dynamic>> zones) {
    final circles = <Circle>{};

    for (final zone in zones) {
      final id = zone['id']?.toString() ?? UniqueKey().toString();
      final lat = (zone['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (zone['longitude'] as num?)?.toDouble() ?? 0.0;
      final radius = (zone['radius_meters'] as num?)?.toDouble() ?? 100.0;
      if (lat == 0.0 && lng == 0.0) continue;

      final isConfirmed = zone['is_user_confirmed'] == true;
      final riskLevel = (zone['risk_level'] as String?)?.toLowerCase() ?? 'medium';

      Color color;
      if (!isConfirmed) {
        color = AppColors.amber;
      } else if (riskLevel == 'high') {
        color = AppColors.coral;
      } else if (riskLevel == 'medium') {
        color = AppColors.amber;
      } else {
        color = AppColors.teal;
      }

      circles.add(
        Circle(
          circleId: CircleId('circle_$id'),
          center: LatLng(lat, lng),
          radius: radius,
          strokeWidth: 2,
          strokeColor: color.withValues(alpha: 0.8),
          fillColor: color.withValues(alpha: 0.15),
        ),
      );
    }

    // Pinned location circle preview
    if (_pinnedLocation != null) {
      circles.add(
        Circle(
          circleId: const CircleId('circle_pinned'),
          center: _pinnedLocation!,
          radius: 100,
          strokeWidth: 2,
          strokeColor: AppColors.lavender.withValues(alpha: 0.8),
          fillColor: AppColors.lavender.withValues(alpha: 0.15),
        ),
      );
    }

    return circles;
  }

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(riskZonesProvider);
    final confirmedZones = zones.where((z) => z['is_user_confirmed'] == true).toList();
    final suggestedZones = zones.where((z) => z['is_user_confirmed'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoking Risk Map'),
        actions: [
          // Developer Simulator Button
          IconButton(
            tooltip: 'Geofence Test Simulator',
            icon: const Icon(Icons.science_outlined, color: AppColors.amber),
            onPressed: () => _showGeofenceSimulatorSheet(zones),
          ),
          // Map Style / Layers
          IconButton(
            tooltip: 'Change Map Style / Provider',
            icon: const Icon(Icons.layers_outlined),
            onPressed: _showMapStyleDialog,
          ),
          // Legend Toggle
          IconButton(
            tooltip: 'Map Legend',
            icon: Icon(_showLegend ? Icons.info : Icons.info_outline, color: _showLegend ? AppColors.teal : null),
            onPressed: () => setState(() => _showLegend = !_showLegend),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Real Interactive Map (OpenStreetMap or Google Maps)
          if (_mapEngine == MapEngine.openStreetMap)
            _buildOpenStreetMap(zones)
          else
            _buildGoogleMap(zones),

          // 2. Permission / GPS Disabled Banner (Non-intrusive)
          if (_locationStatus == LocationStatus.denied ||
              _locationStatus == LocationStatus.deniedForever ||
              _locationStatus == LocationStatus.serviceDisabled)
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: _buildLocationNoticeBanner(),
            ),

          // 3. Map Legend Card
          if (_showLegend)
            Positioned(
              top: _locationStatus == LocationStatus.granted ? 12 : 70,
              left: 14,
              child: _buildLegendCard(),
            ),

          // 4. Floating Action Controls
          Positioned(
            right: 14,
            bottom: 120,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Add Risk Zone FAB
                FloatingActionButton.small(
                  heroTag: 'add_zone_fab',
                  backgroundColor: AppColors.mintGreen,
                  foregroundColor: Colors.white,
                  tooltip: 'Add Risk Zone',
                  onPressed: () => _showAddZoneSheet(presetLatLng: _pinnedLocation ?? _currentPosition),
                  child: const Icon(Icons.add_location_alt),
                ),
                const SizedBox(height: 10),
                // Recenter to Current Location FAB
                FloatingActionButton.small(
                  heroTag: 'recenter_fab',
                  backgroundColor: AppColors.cardDark,
                  foregroundColor: _isLocating ? AppColors.amber : AppColors.teal,
                  tooltip: 'Recenter to My Location',
                  onPressed: () => _fetchCurrentLocation(animateCamera: true),
                  child: _isLocating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // 5. Collapsible Bottom Risk Zones Sheet
          _buildDraggableRiskZonesSheet(confirmedZones, suggestedZones),
        ],
      ),
    );
  }

  Widget _buildLocationNoticeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off, color: AppColors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _locationStatus == LocationStatus.serviceDisabled
                  ? 'Device GPS is disabled. Tap to enable.'
                  : 'Location access is off. Explore map manually or grant access.',
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryDark),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_locationStatus == LocationStatus.serviceDisabled) {
                await _locationService.openLocationSettings();
              } else if (_locationStatus == LocationStatus.deniedForever) {
                await _locationService.openAppSettings();
              } else {
                final status = await _locationService.requestPermission();
                setState(() => _locationStatus = status);
                if (status == LocationStatus.granted) {
                  _fetchCurrentLocation(animateCamera: true);
                }
              }
            },
            child: const Text('Enable', style: TextStyle(color: AppColors.mintGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyLight),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Marker Legend', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondaryDark)),
          const SizedBox(height: 6),
          _legendItem(AppColors.coral, 'Confirmed High Risk'),
          _legendItem(AppColors.amber, 'Confirmed Medium Risk'),
          _legendItem(AppColors.teal, 'Confirmed Low Risk'),
          _legendItem(Colors.yellowAccent, 'Suggested (Awaiting Confirmation)'),
          if (_pinnedLocation != null) _legendItem(AppColors.lavender, 'Dropped Pin (Tap to Save)'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textPrimaryDark)),
      ],
    ),
  );

  Widget _buildDraggableRiskZonesSheet(
    List<Map<String, dynamic>> confirmed,
    List<Map<String, dynamic>> suggested,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.16,
      minChildSize: 0.08,
      maxChildSize: 0.65,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, -3))],
            border: Border(top: BorderSide(color: AppColors.navyLight.withValues(alpha: 0.6))),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            children: [
              // Drag Pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Identified Risk Zones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${confirmed.length} Confirmed • ${suggested.length} Suggested',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                      foregroundColor: AppColors.teal,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.add_location, size: 16),
                    label: const Text('Add Zone', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showAddZoneSheet(presetLatLng: _pinnedLocation ?? _currentPosition),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Suggested Section (if any)
              if (suggested.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.amber, size: 16),
                          SizedBox(width: 8),
                          Text('AI Trigger Suggestions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.amber)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Based on your recorded cravings and smoking logs, these places look like recurring triggers. Review and confirm below:',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 10),
                      ...suggested.map((z) => _buildZoneTile(z, isSuggested: true)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Confirmed Zones Section
              if (confirmed.isEmpty && suggested.isEmpty)
                _buildEmptyState()
              else ...[
                if (confirmed.isNotEmpty) const Text('Confirmed Personal Zones', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondaryDark)),
                const SizedBox(height: 8),
                ...confirmed.map((z) => _buildZoneTile(z, isSuggested: false)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoneTile(Map<String, dynamic> zone, {required bool isSuggested}) {
    final riskLevel = (zone['risk_level'] as String?)?.toLowerCase() ?? 'medium';
    Color color = isSuggested
        ? AppColors.amber
        : (riskLevel == 'high' ? AppColors.coral : riskLevel == 'medium' ? AppColors.amber : AppColors.teal);

    final smokingCount = zone['smoking_events_count'] ?? 0;
    final cravingCount = zone['craving_events_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.cardDarkElevated,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.location_on, color: color, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(zone['name'] ?? 'Unnamed Area', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(isSuggested ? 'SUGGESTED' : riskLevel.toUpperCase(),
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(zone['trigger_reason'] ?? 'Identified smoking trigger', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('🚬 $smokingCount logged', style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
                  const SizedBox(width: 10),
                  Text('🔥 $cravingCount cravings', style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark)),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.center_focus_strong, size: 18, color: AppColors.teal),
          tooltip: 'Focus on Map',
          onPressed: () {
            final lat = (zone['latitude'] as num?)?.toDouble();
            final lng = (zone['longitude'] as num?)?.toDouble();
            if (lat != null && lng != null) {
              _recenterMap(lat, lng);
            }
          },
        ),
        onTap: () => _showZoneDetailsSheet(zone),
      ),
    ),
  );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(Icons.add_location_alt_outlined, size: 40, color: AppColors.textTertiaryDark),
          const SizedBox(height: 10),
          const Text('No Risk Zones Added Yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          const Text('Drop a pin on the real map or tap "Add Zone" to identify triggers.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // --- Detailed Bottom Sheet when Marker/Card is Tapped ---
  void _showZoneDetailsSheet(Map<String, dynamic> zone) {
    final zoneId = zone['id'] as int? ?? 0;
    final isConfirmed = zone['is_user_confirmed'] == true;
    final riskLevel = (zone['risk_level'] as String?)?.toLowerCase() ?? 'medium';
    final name = zone['name'] ?? 'Risk Zone';
    final trigger = zone['trigger_reason'] ?? 'Identified trigger';
    final radius = zone['radius_meters'] ?? 100;
    final smokingCount = zone['smoking_events_count'] ?? 0;
    final cravingCount = zone['craving_events_count'] ?? 0;
    final explanation = zone['explanation'] ?? 'Classified based on recorded smoking and craving observations.';
    final remindersEnabled = zone['reminders_enabled'] ?? true;

    Color color = isConfirmed
        ? (riskLevel == 'high' ? AppColors.coral : riskLevel == 'medium' ? AppColors.amber : AppColors.teal)
        : AppColors.amber;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),

              // Title and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.location_on, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                              child: Text(isConfirmed ? '${riskLevel.toUpperCase()} RISK' : 'SUGGESTED TRIGGER',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                            ),
                            const SizedBox(width: 8),
                            Text('Geofence radius: ${radius}m', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Trigger Reason Callout
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.deepNavy, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trigger Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.teal)),
                    const SizedBox(height: 4),
                    Text(trigger, style: const TextStyle(fontSize: 13, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(explanation, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Statistics Row
              Row(
                children: [
                  Expanded(
                    child: _statPill('Smoking Episodes', '$smokingCount', Icons.smoking_rooms, AppColors.coral),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill('Craving Urges', '$cravingCount', Icons.local_fire_department, AppColors.amber),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statPill('Reminders', remindersEnabled ? 'Active' : 'Paused', Icons.notifications_active, AppColors.mintGreen),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // If Suggested: Prompt to Confirm or Reject
              if (!isConfirmed) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mark this as a confirmed smoking trigger?',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.amber),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Confirming allows CraveGuard to help you plan coping strategies and discreetly support you when nearby.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.coral)),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await ref.read(locationRepoProvider).deleteRiskZone(zoneId);
                                await _loadZones();
                              },
                              child: const Text('Dismiss', style: TextStyle(color: AppColors.coral)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintGreen),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(this.context);
                                Navigator.pop(ctx);
                                await ref.read(locationRepoProvider).confirmRiskZone(zoneId);
                                await _loadZones();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('"$name" confirmed as your personal risk zone.')),
                                  );
                                }
                              },
                              child: const Text('Confirm Trigger'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Core Actions
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  icon: const Icon(Icons.smart_toy_outlined),
                  label: const Text('Help me avoid smoking here (Ask Coach)', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/coach');
                  },
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.air, size: 16),
                      label: const Text('Coping Exercise', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.push('/craving-support');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.coral),
                      label: const Text('Delete Zone', style: TextStyle(fontSize: 12, color: AppColors.coral)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(locationRepoProvider).deleteRiskZone(zoneId);
                        await _loadZones();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: AppColors.cardDarkElevated, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textTertiaryDark), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // --- Add Risk Zone Bottom Sheet ---
  void _showAddZoneSheet({LatLng? presetLatLng}) {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String riskLevel = 'medium';
    double radiusMeters = 100.0;
    bool reminders = true;
    LatLng? selectedLatLng = presetLatLng ?? _currentPosition ?? _defaultCenter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Text('Add Smoking Risk Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Identify a location that triggers smoking urges to get timely support.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
              const SizedBox(height: 16),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location Name',
                  hintText: 'e.g. Office Balcony, Chai Corner',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Why is this a trigger?',
                  hintText: 'e.g. Work stress, smoking with friends',
                  prefixIcon: Icon(Icons.psychology_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Risk Level Selector
              DropdownButtonFormField<String>(
                initialValue: riskLevel,
                dropdownColor: AppColors.cardDark,
                decoration: const InputDecoration(labelText: 'Risk Level', prefixIcon: Icon(Icons.warning_amber_rounded)),
                items: const [
                  DropdownMenuItem(value: 'high', child: Text('High Risk (Strong Urges)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium Risk (Habitual Breaks)')),
                  DropdownMenuItem(value: 'low', child: Text('Low Risk (Occasional Urges)')),
                ],
                onChanged: (v) => setSheetState(() => riskLevel = v!),
              ),
              const SizedBox(height: 12),

              // Geofence Radius
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Geofence Radius:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  Text('${radiusMeters.round()} meters', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.teal)),
                ],
              ),
              Slider(
                value: radiusMeters,
                min: 50,
                max: 300,
                divisions: 5,
                label: '${radiusMeters.round()}m',
                activeColor: AppColors.teal,
                onChanged: (v) => setSheetState(() => radiusMeters = v),
              ),

              // Use My Current Location Pill
              if (_currentPosition != null)
                TextButton.icon(
                  icon: const Icon(Icons.my_location, size: 16, color: AppColors.mintGreen),
                  label: Text('Use Current Coordinates (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 11, color: AppColors.mintGreen)),
                  onPressed: () {
                    setSheetState(() => selectedLatLng = _currentPosition);
                  },
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.mintGreen, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a location name')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    final newZone = {
                      'id': DateTime.now().millisecondsSinceEpoch,
                      'name': nameCtrl.text.trim(),
                      'latitude': selectedLatLng?.latitude ?? _defaultCenter.latitude,
                      'longitude': selectedLatLng?.longitude ?? _defaultCenter.longitude,
                      'radius_meters': radiusMeters.round(),
                      'risk_level': riskLevel,
                      'trigger_reason': reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : 'Identified trigger',
                      'is_user_confirmed': true,
                      'is_active': reminders,
                      'cooldown_minutes': 60,
                      'smoking_events_count': 0,
                      'craving_events_count': 0,
                      'explanation': 'Manually registered risk zone by user.',
                      'reminders_enabled': reminders,
                    };

                    final messenger = ScaffoldMessenger.of(this.context);
                    await ref.read(locationRepoProvider).addRiskZone(newZone);
                    setState(() => _pinnedLocation = null);
                    await _loadZones();
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Risk zone "${nameCtrl.text}" saved.')),
                      );
                    }
                  },
                  child: const Text('Save Risk Zone', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Developer Geofence Simulator (Modal Sheet) ---
  void _showGeofenceSimulatorSheet(List<Map<String, dynamic>> zones) {
    if (zones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a risk zone first before testing the simulator.')),
      );
      return;
    }

    Map<String, dynamic> selectedZone = zones.first;
    GeofenceEventResult? lastResult;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.navyLight, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.science, color: AppColors.amber),
                  SizedBox(width: 8),
                  Text('Geofence Testing Simulator', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.amber)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Developer mode: Test entering risk zones to verify notification timing, cooldown rules, and quiet hours. Simulated events are flagged as test data.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark, height: 1.4),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<Map<String, dynamic>>(
                initialValue: selectedZone,
                dropdownColor: AppColors.cardDark,
                decoration: const InputDecoration(labelText: 'Choose Risk Zone to Test'),
                items: zones.map((z) => DropdownMenuItem(
                  value: z,
                  child: Text(z['name'] ?? 'Zone'),
                )).toList(),
                onChanged: (v) => setSheetState(() {
                  if (v != null) selectedZone = v;
                }),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black87),
                      icon: const Icon(Icons.login),
                      label: const Text('Simulate Entry'),
                      onPressed: () {
                        final res = _geofenceService.evaluateEntry(selectedZone, isSimulated: true);
                        setSheetState(() => lastResult = res);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.textSecondaryDark)),
                      icon: const Icon(Icons.logout),
                      label: const Text('Simulate Exit'),
                      onPressed: () {
                        setSheetState(() {
                          lastResult = GeofenceEventResult(
                            zone: selectedZone,
                            message: 'You have exited "${selectedZone['name']}". Well done staying mindful!',
                            eventType: 'exit',
                            isSimulated: true,
                            notificationAllowed: true,
                            timestamp: DateTime.now(),
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (lastResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.deepNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Evaluation Result:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.teal)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('SIMULATED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.amber)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Status: ${lastResult!.notificationAllowed ? "🔔 Notification Triggered" : "🚫 Suppressed"}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lastResult!.notificationAllowed ? AppColors.mintGreen : AppColors.coral)),
                      if (lastResult!.suppressionReason != null)
                        Text('Reason: ${lastResult!.suppressionReason}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
                      const SizedBox(height: 6),
                      Text('Message Preview:\n"${lastResult!.message}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(List<Map<String, dynamic>> zones) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentPosition ?? (zones.isNotEmpty
            ? LatLng(
                (zones[0]['latitude'] as num?)?.toDouble() ?? _defaultCenter.latitude,
                (zones[0]['longitude'] as num?)?.toDouble() ?? _defaultCenter.longitude,
              )
            : _defaultCenter),
        zoom: 15.0,
      ),
      mapType: _currentMapType,
      myLocationEnabled: _locationStatus == LocationStatus.granted,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      markers: _buildMarkers(zones),
      circles: _buildCircles(zones),
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentPosition != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
        }
      },
      onTap: (latLng) => _handleMapTap(latLng.latitude, latLng.longitude),
    );
  }

  Widget _buildOpenStreetMap(List<Map<String, dynamic>> zones) {
    final center = _currentPosition != null
        ? ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : (zones.isNotEmpty
            ? ll.LatLng(
                (zones[0]['latitude'] as num?)?.toDouble() ?? _defaultCenter.latitude,
                (zones[0]['longitude'] as num?)?.toDouble() ?? _defaultCenter.longitude,
              )
            : ll.LatLng(_defaultCenter.latitude, _defaultCenter.longitude));

    return fmap.FlutterMap(
      mapController: _fmapController,
      options: fmap.MapOptions(
        initialCenter: center,
        initialZoom: 15.2,
        onTap: (tapPosition, point) => _handleMapTap(point.latitude, point.longitude),
      ),
      children: [
        // Live OpenStreetMap Street Tiles Layer
        fmap.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.craveguard.craveguard',
        ),

        // Geofence Radius Circles
        fmap.CircleLayer(
          circles: [
            for (final zone in zones)
              if (((zone['latitude'] as num?)?.toDouble() ?? 0.0) != 0.0 &&
                  ((zone['longitude'] as num?)?.toDouble() ?? 0.0) != 0.0)
                fmap.CircleMarker(
                  point: ll.LatLng(
                    (zone['latitude'] as num).toDouble(),
                    (zone['longitude'] as num).toDouble(),
                  ),
                  radius: (zone['radius_meters'] as num?)?.toDouble() ?? 100.0,
                  useRadiusInMeter: true,
                  color: (zone['is_user_confirmed'] != true
                          ? AppColors.lavender
                          : (zone['risk_level'] == 'high'
                              ? AppColors.coral
                              : zone['risk_level'] == 'medium'
                                  ? AppColors.amber
                                  : AppColors.teal))
                      .withValues(alpha: 0.18),
                  borderColor: (zone['is_user_confirmed'] != true
                          ? AppColors.lavender
                          : (zone['risk_level'] == 'high'
                              ? AppColors.coral
                              : zone['risk_level'] == 'medium'
                                  ? AppColors.amber
                                  : AppColors.teal))
                      .withValues(alpha: 0.8),
                  borderStrokeWidth: 2,
                ),

            if (_pinnedLocation != null)
              fmap.CircleMarker(
                point: ll.LatLng(_pinnedLocation!.latitude, _pinnedLocation!.longitude),
                radius: 100.0,
                useRadiusInMeter: true,
                color: AppColors.lavender.withValues(alpha: 0.18),
                borderColor: AppColors.lavender.withValues(alpha: 0.8),
                borderStrokeWidth: 2,
              ),
          ],
        ),

        // Interactive Markers Layer
        fmap.MarkerLayer(
          markers: [
            // Real Current Device Location Marker (Native Blue Pulse)
            if (_currentPosition != null && _locationStatus == LocationStatus.granted)
              fmap.Marker(
                point: ll.LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.navigation, size: 14, color: Colors.white),
                  ),
                ),
              ),

            // Smoking Risk Zones
            for (final zone in zones)
              if (((zone['latitude'] as num?)?.toDouble() ?? 0.0) != 0.0 &&
                  ((zone['longitude'] as num?)?.toDouble() ?? 0.0) != 0.0)
                fmap.Marker(
                  point: ll.LatLng(
                    (zone['latitude'] as num).toDouble(),
                    (zone['longitude'] as num).toDouble(),
                  ),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showZoneDetailsSheet(zone),
                    child: Container(
                      decoration: BoxDecoration(
                        color: zone['is_user_confirmed'] != true
                            ? AppColors.lavender
                            : (zone['risk_level'] == 'high'
                                ? AppColors.coral
                                : zone['risk_level'] == 'medium'
                                    ? AppColors.amber
                                    : AppColors.teal),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: (zone['is_user_confirmed'] != true
                                    ? AppColors.lavender
                                    : (zone['risk_level'] == 'high'
                                        ? AppColors.coral
                                        : zone['risk_level'] == 'medium'
                                            ? AppColors.amber
                                            : AppColors.teal))
                                .withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        zone['is_user_confirmed'] == true ? Icons.smoking_rooms : Icons.help_outline,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

            // Dropped Pin Marker
            if (_pinnedLocation != null)
              fmap.Marker(
                point: ll.LatLng(_pinnedLocation!.latitude, _pinnedLocation!.longitude),
                width: 44,
                height: 44,
                child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 44),
              ),
          ],
        ),
      ],
    );
  }

  void _handleMapTap(double latitude, double longitude) {
    final latLng = LatLng(latitude, longitude);
    setState(() => _pinnedLocation = latLng);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pin dropped at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}'),
        action: SnackBarAction(
          label: 'Add Zone',
          textColor: AppColors.mintGreen,
          onPressed: () => _showAddZoneSheet(presetLatLng: latLng),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showMapStyleDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Map Provider & Style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.map, color: AppColors.teal),
              title: const Text('OpenStreetMap (Live Streets)'),
              subtitle: const Text('Instant street maps with zero API key or setup needed (Recommended)', style: TextStyle(fontSize: 11)),
              trailing: _mapEngine == MapEngine.openStreetMap ? const Icon(Icons.check_circle, color: AppColors.teal) : null,
              onTap: () {
                setState(() => _mapEngine = MapEngine.openStreetMap);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.layers, color: AppColors.mintGreen),
              title: const Text('Google Maps (Standard)'),
              subtitle: const Text('Requires Maps API key in android/local.properties', style: TextStyle(fontSize: 11)),
              trailing: _mapEngine == MapEngine.googleMaps && _currentMapType == MapType.normal
                  ? const Icon(Icons.check_circle, color: AppColors.teal)
                  : null,
              onTap: () {
                setState(() {
                  _mapEngine = MapEngine.googleMaps;
                  _currentMapType = MapType.normal;
                });
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite_alt, color: AppColors.amber),
              title: const Text('Google Maps (Satellite)'),
              subtitle: const Text('High-resolution aerial satellite imagery', style: TextStyle(fontSize: 11)),
              trailing: _mapEngine == MapEngine.googleMaps && _currentMapType == MapType.satellite
                  ? const Icon(Icons.check_circle, color: AppColors.teal)
                  : null,
              onTap: () {
                setState(() {
                  _mapEngine = MapEngine.googleMaps;
                  _currentMapType = MapType.satellite;
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
