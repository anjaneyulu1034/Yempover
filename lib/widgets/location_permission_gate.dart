import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

enum _GateState {
  checking,
  ready,
  locationServicesOff,
  denied,
  deniedForever,
}

class LocationPermissionGate extends StatefulWidget {
  const LocationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocationPermissionGate> createState() => _LocationPermissionGateState();
}

class _LocationPermissionGateState extends State<LocationPermissionGate>
    with WidgetsBindingObserver {
  _GateState _state = _GateState.checking;
  bool _busy = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 200), _refresh);
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _state = _GateState.checking);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      setState(() => _state = _GateState.locationServicesOff);
      return;
    }

    final status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      if (!mounted) return;
      setState(() => _state = _GateState.ready);
      return;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) return;
      setState(() => _state = _GateState.deniedForever);
      return;
    }

    if (!mounted) return;
    setState(() => _state = _GateState.denied);
  }

  Future<void> _requestPermission() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await Permission.location.request();
      if (!mounted) return;

      if (result.isGranted || result.isLimited) {
        setState(() => _state = _GateState.ready);
        return;
      }

      if (result.isPermanentlyDenied || result.isRestricted) {
        setState(() => _state = _GateState.deniedForever);
        return;
      }

      setState(() => _state = _GateState.denied);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAppSettings() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await openAppSettings();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLocationSettings() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Geolocator.openLocationSettings();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldBlock = _state != _GateState.ready;

    return Stack(
      children: [
        widget.child,
        if (shouldBlock)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: Material(
                color: Colors.white,
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 56,
                              color: Color(0xFF1A73E8),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _titleForState(_state),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _messageForState(_state),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            if (_state == _GateState.checking)
                              const Center(child: CircularProgressIndicator())
                            else ...[
                              if (_state == _GateState.locationServicesOff)
                                ElevatedButton(
                                  onPressed: _busy ? null : _openLocationSettings,
                                  child: const Text('Enable location services'),
                                )
                              else if (_state == _GateState.denied)
                                ElevatedButton(
                                  onPressed: _busy ? null : _requestPermission,
                                  child: const Text('Allow location permission'),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _busy ? null : _openAppSettings,
                                  child: const Text('Open settings'),
                                ),
                              const SizedBox(height: 10),
                              OutlinedButton(
                                onPressed: _busy ? null : _refresh,
                                child: const Text('I have enabled it — retry'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _titleForState(_GateState state) {
    switch (state) {
      case _GateState.checking:
        return 'Checking permissions';
      case _GateState.ready:
        return 'Ready';
      case _GateState.locationServicesOff:
        return 'Turn on location services';
      case _GateState.denied:
        return 'Location permission required';
      case _GateState.deniedForever:
        return 'Enable location permission';
    }
  }

  static String _messageForState(_GateState state) {
    switch (state) {
      case _GateState.checking:
        return 'Please wait…';
      case _GateState.ready:
        return '';
      case _GateState.locationServicesOff:
        return 'This app requires location services to be enabled to continue.';
      case _GateState.denied:
        return 'To continue using the app, please allow location permission.';
      case _GateState.deniedForever:
        return 'Location permission was permanently denied. Please enable it from Settings to continue.';
    }
  }

}
