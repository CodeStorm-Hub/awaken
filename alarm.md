# Building an Android Alarm App in Flutter

Building a reliable alarm application in Flutter for Android requires handling background execution and precise time scheduling. The most robust approach is using the `alarm` package, which manages native Android background execution, audio loop playback, and system volume overrides.

---

## 1. Dependencies Setup

Add the required packages to your `pubspec.yaml` file to handle system alarms and native runtime permissions.

```yaml
dependencies:
  flutter:
    sdk: flutter
  alarm: ^5.2.1 # Coordinates system alarms and background playback
  permission_handler: ^11.3.1 # Handles Android runtime permissions
```

---

## 2. Android Manifest Configuration

Android requires specific permissions to wake the device, trigger exact alarms, and play audio when the app is closed. 

Open `android/app/src/main/AndroidManifest.xml` and insert these rules inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

To ensure the alarm displays over the lock screen on modern Android versions, add these properties directly inside the `<activity>` tag of your main activity:

```xml
android:showWhenLocked="true"
android:turnScreenOn="true"
```

---

## 3. Application Initialization

Initialize the alarm engine service inside your entry point before rendering the widget tree. 

Modify your `lib/main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Must be called before running the application
  await Alarm.init(); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Alarm App Ready')),
      ),
    );
  }
}
```

---

## 4. Scheduling and Canceling Alarms

Define your alarm configuration and register it to the native system loop using a dedicated helper class or function.

```dart
import 'package:alarm/alarm.dart';

class AlarmService {
  // Schedules a new system alarm
  static Future<void> scheduleAlarm(DateTime targetTime) async {
    final alarmSettings = AlarmSettings(
      id: 42, // Unique identifier used to modify or cancel this alarm
      dateTime: targetTime,
      assetAudioPath: 'assets/alarm.mp3', // Place your local sound file here
      loopAudio: true,
      vibrate: true,
      volume: 0.8,
      fadeDuration: 3.0, // Smoothly transitions volume over 3 seconds
      notificationTitle: 'Time is up!',
      notificationBody: 'Your scheduled alarm is ringing.',
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  // Disables the scheduled system task
  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id); 
  }
}
```

---

## 5. Runtime Permissions Handling

Modern Android architectures treat notification delivery and exact scheduling as highly sensitive actions. Request these explicitly before setting an alarm:

```dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestPermissions() async {
    // Request notification permissions
    await Permission.notification.request();

    // Required for exact execution accuracy on Android 13 and above
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }
}
```
