import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:managed_configurations/managed_configurations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _managedAppConfigurations = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String managedAppConfigurations;
    try {
      managedAppConfigurations = json.encode(
          await ManagedConfigurations.getManagedConfigurations ??
              'no managed app configurations');
    } on PlatformException {
      managedAppConfigurations = 'Failed to get managed app configurations.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _managedAppConfigurations = managedAppConfigurations;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Managed App Config'),
        ),
        body: Center(
          child: ListView(
            children: [
              ListTile(
                title: const Text('Initial managed configuration:'),
                subtitle: Text('$_managedAppConfigurations\n'),
              ),
              StreamBuilder<Map<String, dynamic>?>(
                stream: ManagedConfigurations.mangedConfigurationsStream,
                builder: (context, snapshot) {
                  return ListTile(
                      title: const Text('Live managed configuraiton:'),
                      subtitle: snapshot.hasData
                          ? Text(json.encode(snapshot.data))
                          : const Text("No changes at the moment"));
                },
              ),
              OutlinedButton(
                  onPressed: () {
                    //only Android
                    ManagedConfigurations.reportKeyedAppStates(
                      "some_key",
                      Severity.SEVERITY_INFO,
                      "Applied managed config",
                      json.encode(
                        {
                          "prop1": true,
                          "datetime": DateTime.now().toIso8601String()
                        },
                      ),
                    );
                  },
                  child: const Text("Report app state"))
            ],
          ),
        ),
      ),
    );
  }
}
