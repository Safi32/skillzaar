import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _measurements = {};
  final Map<String, int> _counters = {};
  final Map<String, DateTime> _lastActivity = {};

  /// Start timing a performance metric
  void startTimer(String name) {
    _timers[name] = Stopwatch()..start();
    _lastActivity[name] = DateTime.now();
  }

  /// Stop timing and record the measurement
  Duration? stopTimer(String name) {
    final timer = _timers.remove(name);
    if (timer == null) return null;

    timer.stop();
    final duration = timer.elapsed;

    _measurements.putIfAbsent(name, () => []).add(duration);
    _counters[name] = (_counters[name] ?? 0) + 1;

    if (kDebugMode) {
      developer.log(
        'Performance: $name took ${duration.inMilliseconds}ms',
        name: 'PerformanceMonitor',
      );
    }

    return duration;
  }

  /// Record a performance measurement
  void recordMeasurement(String name, Duration duration) {
    _measurements.putIfAbsent(name, () => []).add(duration);
    _counters[name] = (_counters[name] ?? 0) + 1;
    _lastActivity[name] = DateTime.now();
  }

  /// Increment a counter
  void incrementCounter(String name, [int amount = 1]) {
    _counters[name] = (_counters[name] ?? 0) + amount;
    _lastActivity[name] = DateTime.now();
  }

  /// Get average duration for a metric
  double? getAverageDuration(String name) {
    final measurements = _measurements[name];
    if (measurements == null || measurements.isEmpty) return null;

    final totalMs = measurements.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return totalMs / measurements.length;
  }

  /// Get total count for a metric
  int getCount(String name) => _counters[name] ?? 0;

  /// Get all performance metrics
  Map<String, Map<String, dynamic>> getAllMetrics() {
    final metrics = <String, Map<String, dynamic>>{};

    for (final name in _measurements.keys) {
      final measurements = _measurements[name]!;
      final count = _counters[name] ?? 0;
      final average = getAverageDuration(name);
      final lastActivity = _lastActivity[name];

      metrics[name] = {
        'count': count,
        'averageMs': average,
        'totalMeasurements': measurements.length,
        'lastActivity': lastActivity?.toIso8601String(),
        'minMs':
            measurements.isNotEmpty
                ? measurements
                    .map((d) => d.inMilliseconds)
                    .reduce((a, b) => a < b ? a : b)
                : null,
        'maxMs':
            measurements.isNotEmpty
                ? measurements
                    .map((d) => d.inMilliseconds)
                    .reduce((a, b) => a > b ? a : b)
                : null,
      };
    }

    return metrics;
  }

  /// Clear all metrics
  void clearMetrics() {
    _timers.clear();
    _measurements.clear();
    _counters.clear();
    _lastActivity.clear();
  }

  /// Clear specific metric
  void clearMetric(String name) {
    _timers.remove(name);
    _measurements.remove(name);
    _counters.remove(name);
    _lastActivity.remove(name);
  }

  /// Log performance summary
  void logSummary() {
    if (kDebugMode) {
      developer.log('=== Performance Summary ===', name: 'PerformanceMonitor');
      final metrics = getAllMetrics();

      for (final entry in metrics.entries) {
        final name = entry.key;
        final data = entry.value;
        developer.log(
          '$name: ${data['count']} calls, avg: ${data['averageMs']?.toStringAsFixed(2)}ms',
          name: 'PerformanceMonitor',
        );
      }
    }
  }
}

/// Widget performance monitoring mixin
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  final Map<String, Stopwatch> _widgetTimers = {};

  /// Start monitoring widget build time
  void startBuildTimer(String widgetName) {
    _widgetTimers[widgetName] = Stopwatch()..start();
  }

  /// End monitoring widget build time
  void endBuildTimer(String widgetName) {
    final timer = _widgetTimers.remove(widgetName);
    if (timer != null) {
      timer.stop();
      _monitor.recordMeasurement('widget_build_$widgetName', timer.elapsed);
    }
  }

  /// Monitor method execution time
  Future<R> monitorMethod<R>(
    String methodName,
    Future<R> Function() method,
  ) async {
    _monitor.startTimer(methodName);
    try {
      final result = await method();
      return result;
    } finally {
      _monitor.stopTimer(methodName);
    }
  }

  /// Monitor synchronous method execution time
  R monitorSyncMethod<R>(String methodName, R Function() method) {
    _monitor.startTimer(methodName);
    try {
      final result = method();
      return result;
    } finally {
      _monitor.stopTimer(methodName);
    }
  }

  @override
  void dispose() {
    _widgetTimers.clear();
    super.dispose();
  }
}

/// Performance overlay widget for debugging
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay>
    with TickerProviderStateMixin {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  late AnimationController _animationController;
  bool _isVisible = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isVisible = !_isVisible;
                  if (_isVisible) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.speed, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (_isVisible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              right: 10,
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animationController.value,
                    child: Opacity(
                      opacity: _animationController.value,
                      child: Container(
                        width: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildPerformanceInfo(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceInfo() {
    final metrics = _monitor.getAllMetrics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Performance Metrics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...metrics.entries.map((entry) {
          final name = entry.key;
          final data = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '$name: ${data['averageMs']?.toStringAsFixed(1)}ms (${data['count']})',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          );
        }),
        if (metrics.isEmpty)
          const Text(
            'No metrics recorded',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: () {
                _monitor.clearMetrics();
                setState(() {});
              },
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _monitor.logSummary();
              },
              child: const Text(
                'Log',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Performance-aware ListView.builder
class PerformanceListView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const PerformanceListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }
}

/// Performance-aware GridView.builder
class PerformanceGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final SliverGridDelegate gridDelegate;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const PerformanceGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.gridDelegate,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: gridDelegate,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: itemBuilder(context, index));
      },
    );
  }
}
