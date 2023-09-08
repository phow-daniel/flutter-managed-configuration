import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

const String getManagedConfiguration = "getManagedConfigurations";
const String reportKeyedAppState = "reportKeyedAppState";

enum Severity { SEVERITY_INFO, SEVERITY_ERROR }

extension SeverityExtensions on Severity {
  int toInteger() {
    switch (this) {
      case Severity.SEVERITY_INFO:
        return 1;
      case Severity.SEVERITY_ERROR:
        return 2;
    }
  }
}

class ManagedConfigurations {
  static const MethodChannel _managedConfigurationMethodChannel =
      MethodChannel('managed_configurations_method');
  static const EventChannel _managedConfigurationEventChannel =
      EventChannel('managed_configurations_event');

  static final _mangedConfigurationsController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static final _managedConfigurationsStream =
      _mangedConfigurationsController.stream.asBroadcastStream();

  /// Returns a broadcast stream which calls on managed app configuration changes
  /// Json will be returned
  /// Call [dispose] when stream is not more necessary
  static Stream<Map<String, dynamic>?> get mangedConfigurationsStream {
    _actionApplicationRestrictionsChangedSubscription ??=
        _managedConfigurationEventChannel
            .receiveBroadcastStream()
            .listen((newManagedConfigurations) {
      if (newManagedConfigurations != null) {
        _mangedConfigurationsController
            .add(json.decode(newManagedConfigurations));
      }
    });
    return _managedConfigurationsStream;
  }

  static StreamSubscription<dynamic>?
      _actionApplicationRestrictionsChangedSubscription;

  /// Returns managed app configurations as Json
  static Future<Map<String, dynamic>?> get getManagedConfigurations async {
    final String? rawJson = await _managedConfigurationMethodChannel
        .invokeMethod(getManagedConfiguration);
    if (rawJson != null) {
      return json.decode(rawJson);
    } else {
      return null;
    }
  }

  /// This method is only supported on Android Platform
  static Future<void> reportKeyedAppStates(
    String key,
    Severity severity,
    String? message,
    String? data,
  ) async {
    if (Platform.isAndroid) {
      await _managedConfigurationMethodChannel.invokeMethod(
        reportKeyedAppState,
        {
          'key': key,
          'severity': severity.toInteger(),
          'message': message,
          'data': data,
        },
      );
    }
  }

  static dispose() {
    _actionApplicationRestrictionsChangedSubscription?.cancel();
  }
}
