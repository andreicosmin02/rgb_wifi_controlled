import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_hsvcolor_picker/flutter_hsvcolor_picker.dart';
import 'package:http/http.dart' as http;
import 'database_helper.dart';

void main() {
  _enablePlatformOverrideForDesktop();
  runApp(const MyApp());
}

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SelectColorScaffold(),
    );
  }
}

class SelectColorScaffold extends StatefulWidget {
  const SelectColorScaffold({super.key});

  @override
  State<SelectColorScaffold> createState() => _SelectColorScaffoldState();
}

class _SelectColorScaffoldState extends State<SelectColorScaffold> {
  String _connectionStatus = 'Unknown';
  final NetworkInfo _networkInfo = NetworkInfo();
  late Timer _timer;
  Color _currentColor = Colors.blue;
  Timer? _debounce;
  bool _isAlertShown = false;
  String? _currentProfileName;
  int? _currentProfileId;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _startPeriodicCheck();
    _initializeProfiles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showProfileSelectionDialog();
    });
  }

  Future<void> _initializeProfiles() async {
    List<Map<String, dynamic>> profiles =
        await _databaseHelper.getColorProfiles();
    if (profiles.isEmpty) {
      int id = await _databaseHelper.insertColorProfile(
          "Default profile", 0xFFFFFFFF);
      profiles = await _databaseHelper.getColorProfiles();
    }
    setState(() {
      if (profiles.isNotEmpty) {
        _currentColor = Color(profiles[0]['color']);
        _currentProfileId = profiles[0]['id'];
        _currentProfileName = profiles[0]['name'];
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  void _startPeriodicCheck() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    String? wifiName;
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        var status = await Permission.locationWhenInUse.status;
        if (!status.isGranted) {
          await Permission.locationWhenInUse.request();
        }
        if (await Permission.locationWhenInUse.isGranted) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = 'Unauthorized to get Wifi Name';
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      wifiName = 'Failed to get Wifi Name';
    }

    setState(() {
      _connectionStatus = wifiName ?? 'Unknown';
      if (_connectionStatus != "\"ESP32_AP\"") {
        if (!_isAlertShown) {
          _showAlert();
          _isAlertShown = true;
        }
      } else {
        _sendColorToESP32(_currentColor);
      }
    });
  }

  void _showAlert() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection Error'),
            content:
                const Text('Please connect to the ESP32_AP Wi-Fi network.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  _isAlertShown = false;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    });
  }

  void _sendColorToESP32(Color color) async {
    if (_connectionStatus != "\"ESP32_AP\"") return;

    final rgb = _colorToRgb(color);
    final url =
        'http://192.168.4.1/set_rgb?r=${rgb['r']}&g=${rgb['g']}&b=${rgb['b']}';

    print('Sending RGB values: R=${rgb['r']}, G=${rgb['g']}, B=${rgb['b']}');

    try {
      final response = await http.post(Uri.parse(url));
      if (response.statusCode == 200) {
        print(
            'Color updated successfully: R=${rgb['r']}, G=${rgb['g']}, B=${rgb['b']}');
      } else {
        print('Failed to update color');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Map<String, int> _colorToRgb(Color color) {
    return {
      'r': color.red,
      'g': color.green,
      'b': color.blue,
    };
  }

  void _onColorChanged(Color color) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _currentColor = color;
      });
      _sendColorToESP32(color);
      if (_currentProfileId != null) {
        await _databaseHelper.updateColorProfile(
            _currentProfileId!, _currentColor.value);
        print(
            'Profile updated: $_currentProfileName with color ${_currentColor.value.toRadixString(16)}');
      }
    });
  }

  void _showProfileDialog() {
    String profileName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Profile'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  onChanged: (value) {
                    profileName = value;
                  },
                  decoration:
                      const InputDecoration(hintText: "Enter profile name"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (profileName.isNotEmpty) {
                  int id = await _databaseHelper.insertColorProfile(
                      profileName, _currentColor.value);
                  setState(() {
                    _currentProfileId = id;
                    _currentProfileName = profileName;
                  });
                  print(
                      'Profile saved: $profileName with color ${_currentColor.value.toRadixString(16)}');
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showProfiles() async {
    List<Map<String, dynamic>> profiles =
        await _databaseHelper.getColorProfiles();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Row(
                    children: [
                      Text(profiles[index]['name']),
                      SizedBox(width: 10),
                      Container(
                        width: 20,
                        height: 20,
                        color: Color(profiles[index]['color']),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () async {
                      await _databaseHelper
                          .deleteColorProfile(profiles[index]['id']);
                      Navigator.of(context).pop(); // Close the menu
                      List<Map<String, dynamic>> updatedProfiles =
                          await _databaseHelper.getColorProfiles();
                      if (updatedProfiles.isEmpty) {
                        int id = await _databaseHelper.insertColorProfile(
                            "Default profile", 0xFFFFFFFF);
                        updatedProfiles =
                            await _databaseHelper.getColorProfiles();
                      }
                      setState(() {
                        if (updatedProfiles.isNotEmpty) {
                          _currentColor = Color(updatedProfiles[0]['color']);
                          _currentProfileId = updatedProfiles[0]['id'];
                          _currentProfileName = updatedProfiles[0]['name'];
                          _sendColorToESP32(_currentColor);
                        } else {
                          _currentColor = Colors.blue;
                          _currentProfileId = null;
                          _currentProfileName = null;
                        }
                      });
                    },
                  ),
                  onTap: () async {
                    setState(() {
                      _currentColor = Color(profiles[index]['color']);
                      _currentProfileId = profiles[index]['id'];
                      _currentProfileName = profiles[index]['name'];
                    });
                    print(
                        'Profile selected: ${profiles[index]['name']} with color ${profiles[index]['color'].toRadixString(16)}');
                    _sendColorToESP32(_currentColor);
                    Navigator.of(context).pop(); // Close the menu
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showProfileSelectionDialog() async {
    List<Map<String, dynamic>> profiles =
        await _databaseHelper.getColorProfiles();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Profile'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: profiles.map((profile) {
                  return ListTile(
                    title: Row(
                      children: [
                        Text(profile['name']),
                        SizedBox(width: 10),
                        Container(
                          width: 20,
                          height: 20,
                          color: Color(profile['color']),
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _currentColor = Color(profile['color']);
                        _currentProfileId = profile['id'];
                        _currentProfileName = profile['name'];
                      });
                      print(
                          'Profile selected: ${profile['name']} with color ${profile['color'].toRadixString(16)}');
                      _sendColorToESP32(_currentColor);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Color Picker",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: _showProfiles,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.blue[200],
          child: Column(
            children: [
              if (_currentProfileName != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Current Profile: $_currentProfileName',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsets.only(left: 10.0, top: 50.0, right: 10.0),
                child: Container(
                  alignment: Alignment.center,
                  child: ColorPicker(
                    color: _currentColor,
                    onChanged: _onColorChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showProfileDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
