import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service for assessing app performance quality
class PerformanceAssessmentService {
  static final PerformanceAssessmentService _instance =
      PerformanceAssessmentService._internal();
  factory PerformanceAssessmentService() => _instance;
  PerformanceAssessmentService._internal();

  final Map<String, List<PerformanceMetric>> _metrics = {};
  final Map<String, PerformanceThresholds> _thresholds = {};
  final StreamController<PerformanceAlert> _alertController =
      StreamController.broadcast();

  /// Initialize performance thresholds
  void initializeThresholds() {
    _thresholds['response_time'] = PerformanceThresholds(
      excellent: 50,
      good: 100,
      acceptable: 200,
      poor: 300,
    );

    _thresholds['error_rate'] = PerformanceThresholds(
      excellent: 1,
      good: 3,
      acceptable: 5,
      poor: 10,
    );

    _thresholds['throughput'] = PerformanceThresholds(
      excellent: 100,
      good: 50,
      acceptable: 20,
      poor: 10,
    );

    _thresholds['memory_usage'] = PerformanceThresholds(
      excellent: 50,
      good: 100,
      acceptable: 200,
      poor: 500,
    );

    _thresholds['frame_rate'] = PerformanceThresholds(
      excellent: 60,
      good: 50,
      acceptable: 30,
      poor: 20,
    );
  }

  /// Record a performance metric
  void recordMetric(String metricName, double value, {String? context}) {
    final metric = PerformanceMetric(
      name: metricName,
      value: value,
      timestamp: DateTime.now(),
      context: context,
    );

    _metrics.putIfAbsent(metricName, () => []).add(metric);

    // Keep only last 1000 metrics per type
    if (_metrics[metricName]!.length > 1000) {
      _metrics[metricName]!.removeAt(0);
    }

    // Check for performance issues
    _checkPerformanceAlert(metricName, value);
  }

  /// Get performance assessment for a metric
  PerformanceAssessment getAssessment(String metricName) {
    final metrics = _metrics[metricName] ?? [];
    if (metrics.isEmpty) {
      return PerformanceAssessment(
        quality: PerformanceQuality.unknown,
        score: 0,
        message: 'No data available',
      );
    }

    final recentMetrics =
        metrics.length > 10 ? metrics.sublist(metrics.length - 10) : metrics;

    final avgValue =
        recentMetrics.map((m) => m.value).reduce((a, b) => a + b) /
        recentMetrics.length;

    final thresholds = _thresholds[metricName];
    if (thresholds == null) {
      return PerformanceAssessment(
        quality: PerformanceQuality.unknown,
        score: 0,
        message: 'No thresholds defined',
      );
    }

    final quality = _assessQuality(metricName, avgValue, thresholds);
    final score = _calculateScore(avgValue, thresholds);
    final message = _generateMessage(metricName, quality, avgValue);

    return PerformanceAssessment(
      quality: quality,
      score: score,
      message: message,
      averageValue: avgValue,
      trend: _calculateTrend(metrics),
    );
  }

  /// Get overall app performance assessment
  OverallPerformanceAssessment getOverallAssessment() {
    final assessments = <String, PerformanceAssessment>{};

    for (final metricName in _metrics.keys) {
      assessments[metricName] = getAssessment(metricName);
    }

    final overallScore =
        assessments.values.map((a) => a.score).reduce((a, b) => a + b) /
        assessments.length;

    final overallQuality = _determineOverallQuality(overallScore);
    final recommendations = _generateRecommendations(assessments);

    return OverallPerformanceAssessment(
      overallScore: overallScore,
      overallQuality: overallQuality,
      assessments: assessments,
      recommendations: recommendations,
    );
  }

  /// Check for performance alerts
  void _checkPerformanceAlert(String metricName, double value) {
    final thresholds = _thresholds[metricName];
    if (thresholds == null) return;

    if (value > thresholds.poor) {
      _alertController.add(
        PerformanceAlert(
          type: PerformanceAlertType.critical,
          metricName: metricName,
          value: value,
          message:
              'Critical performance issue detected: $metricName = ${value.toStringAsFixed(2)}',
          timestamp: DateTime.now(),
        ),
      );
    } else if (value > thresholds.acceptable) {
      _alertController.add(
        PerformanceAlert(
          type: PerformanceAlertType.warning,
          metricName: metricName,
          value: value,
          message:
              'Performance warning: $metricName = ${value.toStringAsFixed(2)}',
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// Assess quality based on thresholds
  PerformanceQuality _assessQuality(
    String metricName,
    double value,
    PerformanceThresholds thresholds,
  ) {
    // For response time and memory usage, lower is better
    if (metricName == 'response_time' || metricName == 'memory_usage') {
      if (value <= thresholds.excellent) return PerformanceQuality.excellent;
      if (value <= thresholds.good) return PerformanceQuality.good;
      if (value <= thresholds.acceptable) return PerformanceQuality.acceptable;
      return PerformanceQuality.poor;
    }

    // For throughput and frame rate, higher is better
    if (metricName == 'throughput' || metricName == 'frame_rate') {
      if (value >= thresholds.excellent) return PerformanceQuality.excellent;
      if (value >= thresholds.good) return PerformanceQuality.good;
      if (value >= thresholds.acceptable) return PerformanceQuality.acceptable;
      return PerformanceQuality.poor;
    }

    // For error rate, lower is better
    if (metricName == 'error_rate') {
      if (value <= thresholds.excellent) return PerformanceQuality.excellent;
      if (value <= thresholds.good) return PerformanceQuality.good;
      if (value <= thresholds.acceptable) return PerformanceQuality.acceptable;
      return PerformanceQuality.poor;
    }

    return PerformanceQuality.unknown;
  }

  /// Calculate performance score (0-100)
  double _calculateScore(double value, PerformanceThresholds thresholds) {
    if (value <= thresholds.excellent) return 100;
    if (value <= thresholds.good) return 80;
    if (value <= thresholds.acceptable) return 60;
    if (value <= thresholds.poor) return 40;
    return 20;
  }

  /// Generate performance message
  String _generateMessage(
    String metricName,
    PerformanceQuality quality,
    double value,
  ) {
    switch (quality) {
      case PerformanceQuality.excellent:
        return 'Excellent $metricName performance (${value.toStringAsFixed(2)})';
      case PerformanceQuality.good:
        return 'Good $metricName performance (${value.toStringAsFixed(2)})';
      case PerformanceQuality.acceptable:
        return 'Acceptable $metricName performance (${value.toStringAsFixed(2)})';
      case PerformanceQuality.poor:
        return 'Poor $metricName performance (${value.toStringAsFixed(2)}) - Needs optimization';
      case PerformanceQuality.unknown:
        return 'Unknown $metricName performance (${value.toStringAsFixed(2)})';
    }
  }

  /// Calculate performance trend
  PerformanceTrend _calculateTrend(List<PerformanceMetric> metrics) {
    if (metrics.length < 2) return PerformanceTrend.stable;

    final recent = metrics.sublist(metrics.length - 5);
    final older = metrics.sublist(0, 5);

    final recentAvg =
        recent.map((m) => m.value).reduce((a, b) => a + b) / recent.length;
    final olderAvg =
        older.map((m) => m.value).reduce((a, b) => a + b) / older.length;

    final change = ((recentAvg - olderAvg) / olderAvg) * 100;

    if (change > 10) return PerformanceTrend.declining;
    if (change < -10) return PerformanceTrend.improving;
    return PerformanceTrend.stable;
  }

  /// Determine overall quality
  PerformanceQuality _determineOverallQuality(double overallScore) {
    if (overallScore >= 90) return PerformanceQuality.excellent;
    if (overallScore >= 80) return PerformanceQuality.good;
    if (overallScore >= 60) return PerformanceQuality.acceptable;
    return PerformanceQuality.poor;
  }

  /// Generate performance recommendations
  List<String> _generateRecommendations(
    Map<String, PerformanceAssessment> assessments,
  ) {
    final recommendations = <String>[];

    for (final entry in assessments.entries) {
      final metricName = entry.key;
      final assessment = entry.value;

      if (assessment.quality == PerformanceQuality.poor) {
        switch (metricName) {
          case 'response_time':
            recommendations.add(
              'Optimize UI operations and use isolates for heavy tasks',
            );
            break;
          case 'error_rate':
            recommendations.add(
              'Improve error handling and add retry mechanisms',
            );
            break;
          case 'throughput':
            recommendations.add(
              'Optimize data processing and reduce blocking operations',
            );
            break;
          case 'memory_usage':
            recommendations.add(
              'Implement memory management and fix memory leaks',
            );
            break;
          case 'frame_rate':
            recommendations.add(
              'Optimize rendering and reduce widget rebuilds',
            );
            break;
        }
      }
    }

    return recommendations;
  }

  /// Get performance alerts stream
  Stream<PerformanceAlert> get alerts => _alertController.stream;

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Get metrics for a specific type
  List<PerformanceMetric> getMetrics(String metricName) {
    return List.unmodifiable(_metrics[metricName] ?? []);
  }

  /// Dispose resources
  void dispose() {
    _alertController.close();
  }
}

/// Performance thresholds for different metrics
class PerformanceThresholds {
  final double excellent;
  final double good;
  final double acceptable;
  final double poor;

  PerformanceThresholds({
    required this.excellent,
    required this.good,
    required this.acceptable,
    required this.poor,
  });
}

/// Performance metric data
class PerformanceMetric {
  final String name;
  final double value;
  final DateTime timestamp;
  final String? context;

  PerformanceMetric({
    required this.name,
    required this.value,
    required this.timestamp,
    this.context,
  });
}

/// Performance assessment result
class PerformanceAssessment {
  final PerformanceQuality quality;
  final double score;
  final String message;
  final double? averageValue;
  final PerformanceTrend? trend;

  PerformanceAssessment({
    required this.quality,
    required this.score,
    required this.message,
    this.averageValue,
    this.trend,
  });
}

/// Overall performance assessment
class OverallPerformanceAssessment {
  final double overallScore;
  final PerformanceQuality overallQuality;
  final Map<String, PerformanceAssessment> assessments;
  final List<String> recommendations;

  OverallPerformanceAssessment({
    required this.overallScore,
    required this.overallQuality,
    required this.assessments,
    required this.recommendations,
  });
}

/// Performance quality levels
enum PerformanceQuality { excellent, good, acceptable, poor, unknown }

/// Performance trend
enum PerformanceTrend { improving, stable, declining }

/// Performance alert
class PerformanceAlert {
  final PerformanceAlertType type;
  final String metricName;
  final double value;
  final String message;
  final DateTime timestamp;

  PerformanceAlert({
    required this.type,
    required this.metricName,
    required this.value,
    required this.message,
    required this.timestamp,
  });
}

/// Performance alert types
enum PerformanceAlertType { warning, critical }
