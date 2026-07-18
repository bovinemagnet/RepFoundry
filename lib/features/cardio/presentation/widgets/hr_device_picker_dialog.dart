import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:rep_foundry/l10n/generated/app_localizations.dart';

import '../../data/heart_rate_service.dart';
import '../../data/scan_error.dart';
import 'hr_setup_guide_dialog.dart';

class HrDevicePickerDialog extends StatefulWidget {
  final HeartRateService heartRateService;

  const HrDevicePickerDialog({
    super.key,
    required this.heartRateService,
  });

  @override
  State<HrDevicePickerDialog> createState() => _HrDevicePickerDialogState();
}

class _HrDevicePickerDialogState extends State<HrDevicePickerDialog> {
  List<DiscoveredHrDevice>? _devices;
  bool _scanning = true;
  ScanErrorKind? _errorKind;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _scanning = true;
      _errorKind = null;
      _devices = null;
    });

    try {
      final devices = await widget.heartRateService
          .scanForDevices(timeout: const Duration(seconds: 10));
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _scanning = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKind = classifyScanError(e);
        _scanning = false;
      });
    }
  }

  String _errorMessage(S s, ScanErrorKind kind) {
    switch (kind) {
      case ScanErrorKind.permissionDenied:
        return s.hrScanPermissionDenied;
      case ScanErrorKind.locationServicesOff:
        return s.hrScanLocationOff;
      case ScanErrorKind.bluetoothOff:
        return s.hrScanBluetoothOff;
      case ScanErrorKind.unknown:
        return s.hrScanFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                s.hrDevicePickerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (_scanning) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    s.scanning,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ] else if (_errorKind != null) ...[
                Text(
                  _errorMessage(s, _errorKind!),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_errorKind == ScanErrorKind.permissionDenied) ...[
                      TextButton(
                        onPressed: () => AppSettings.openAppSettings(),
                        child: Text(s.openSettings),
                      ),
                      const SizedBox(width: 8),
                    ],
                    TextButton(
                      onPressed: _startScan,
                      child: Text(s.retry),
                    ),
                  ],
                ),
              ] else if (_devices != null && _devices!.isEmpty) ...[
                Flexible(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            s.noDevicesFound,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: _startScan,
                              child: Text(s.scanAgain),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => showHrSetupGuide(context),
                              child: Text(s.setupHelp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _devices!.length,
                    itemBuilder: (context, index) {
                      final device = _devices![index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name),
                        subtitle: Text(device.id),
                        onTap: () => Navigator.of(context).pop(device),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<DiscoveredHrDevice?> showHrDevicePicker({
  required BuildContext context,
  required HeartRateService heartRateService,
}) {
  return showModalBottomSheet<DiscoveredHrDevice>(
    context: context,
    isScrollControlled: true,
    builder: (_) => HrDevicePickerDialog(
      heartRateService: heartRateService,
    ),
  );
}
