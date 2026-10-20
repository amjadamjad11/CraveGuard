import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/demo_service.dart';

class RiskMapScreen extends ConsumerStatefulWidget {
  const RiskMapScreen({super.key});
  @override
  ConsumerState<RiskMapScreen> createState() => _RiskMapScreenState();
}

class _RiskMapScreenState extends ConsumerState<RiskMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(demoModeProvider)) {
        ref.read(riskZonesProvider.notifier).state = DemoService().riskZones;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(riskZonesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Risk Map')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Map placeholder
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.navyLight),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: AppColors.textTertiaryDark),
                      const SizedBox(height: 8),
                      const Text('Map View', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('Requires Google Maps API key for live map', style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12)),
                      const SizedBox(height: 12),
                      const Text('📍 Simulated risk zones shown below', style: TextStyle(color: AppColors.teal, fontSize: 12)),
                    ],
                  ),
                ),
                // Simulated zone markers
                ...zones.asMap().entries.map((e) {
                  final i = e.key;
                  final z = e.value;
                  final color = z['risk_level'] == 'high' ? AppColors.coral : z['risk_level'] == 'medium' ? AppColors.amber : AppColors.teal;
                  return Positioned(
                    left: 40.0 + i * 80,
                    top: 60.0 + i * 30,
                    child: _mapPin(color, z['name'] ?? ''),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppColors.coral, 'High Risk'),
              const SizedBox(width: 16),
              _legendDot(AppColors.amber, 'Medium'),
              const SizedBox(width: 16),
              _legendDot(AppColors.teal, 'Low'),
            ],
          ),
          const SizedBox(height: 24),
          // Geofence simulator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.science, color: AppColors.amber, size: 18),
                  SizedBox(width: 8),
                  Text('Geofence Simulator', style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                const Text('Test what happens when you enter a risk zone:', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _simulateGeofence(zones.isNotEmpty ? zones[0] : null),
                    icon: const Icon(Icons.location_on),
                    label: const Text('Simulate Zone Entry'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.amber, side: const BorderSide(color: AppColors.amber)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Risk zones list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Risk Zones', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: () => _showAddZoneDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Zone'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (zones.isEmpty)
            _emptyState()
          else
            ...zones.map((z) => _riskZoneCard(z)),
        ],
      ),
    );
  }

  Widget _mapPin(Color color, String name) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.cardDarkElevated, borderRadius: BorderRadius.circular(4)),
        child: Text(name, style: const TextStyle(fontSize: 9, color: AppColors.textPrimaryDark)),
      ),
      Icon(Icons.location_on, color: color, size: 28),
    ],
  );

  Widget _legendDot(Color c, String label) => Row(
    children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark)),
    ],
  );

  Widget _riskZoneCard(Map<String, dynamic> zone) {
    final color = zone['risk_level'] == 'high' ? AppColors.coral : zone['risk_level'] == 'medium' ? AppColors.amber : AppColors.teal;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.location_on, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(zone['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                if (zone['is_user_confirmed'] == true)
                  const Icon(Icons.verified, size: 14, color: AppColors.mintGreen)
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text('Suggested', style: TextStyle(fontSize: 9, color: AppColors.amber)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(zone['trigger_reason'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Text((zone['risk_level'] ?? '').toString().toUpperCase(),
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: AppColors.cardDark, borderRadius: BorderRadius.circular(16)),
    child: Column(
      children: [
        const Icon(Icons.add_location_alt, size: 48, color: AppColors.textTertiaryDark),
        const SizedBox(height: 12),
        const Text('No risk zones yet', style: TextStyle(color: AppColors.textSecondaryDark)),
        const SizedBox(height: 4),
        const Text('Add places where you tend to smoke to get timely support',
          style: TextStyle(color: AppColors.textTertiaryDark, fontSize: 12), textAlign: TextAlign.center),
      ],
    ),
  );

  void _simulateGeofence(Map<String, dynamic>? zone) {
    final name = zone?['name'] ?? 'Test Zone';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🔔 Risk Zone Alert'),
        content: Text('You\'ve entered "$name".\n\nWould you like to try a breathing exercise to stay on track?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss')),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushNamed(context, '/craving-support'); },
            child: const Text('Yes, help me')),
        ],
      ),
    );
  }

  void _showAddZoneDialog() {
    final nameCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String riskLevel = 'medium';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Risk Zone', style: Theme.of(ctx).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Location name', prefixIcon: Icon(Icons.place))),
            const SizedBox(height: 12),
            TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Why is this a trigger?', prefixIcon: Icon(Icons.psychology))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: riskLevel, dropdownColor: AppColors.cardDark,
              decoration: const InputDecoration(labelText: 'Risk level'),
              items: ['high', 'medium', 'low'].map((v) => DropdownMenuItem(value: v, child: Text(v.toUpperCase()))).toList(),
              onChanged: (v) => setSheetState(() => riskLevel = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final zones = List<Map<String, dynamic>>.from(ref.read(riskZonesProvider));
                  zones.add({
                    'id': zones.length + 1, 'name': nameCtrl.text,
                    'latitude': 28.615 + zones.length * 0.005, 'longitude': 77.210 + zones.length * 0.005,
                    'radius_meters': 100, 'risk_level': riskLevel, 'trigger_reason': reasonCtrl.text,
                    'is_user_confirmed': true, 'is_active': true, 'cooldown_minutes': 60,
                  });
                  ref.read(riskZonesProvider.notifier).state = zones;
                  Navigator.pop(ctx);
                }
              }, child: const Text('Add Zone')),
            ),
          ],
        ),
      )),
    );
  }
}
