PS J:\GitHub\awaken> flutter run --dart-define-from-file=.env
Launching lib\main.dart on sdk gphone16k x86 64 in debug mode...
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): flutter_timezone, wakelock_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
Running Gradle task 'assembleDebug'...                             16.5s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          847ms
I/FlutterActivityAndFragmentDelegate(11035): If you are attempting to set --enable-dart-profiling via Intent extras to launch a Flutter component outside of using the Flutter CLI, note that support for setting engine flags on Android via Intent will soon be dropped; see https://github.com/flutter/flutter/issues/180686 for more information on this breaking change. To migrate, set --enable-dart-profiling or any other flags specified via Intent extras on the command line instead or see https://github.com/flutter/flutter/blob/main/docs/engine/Flutter-Android-Engine-Flags.md for alternative methods.
D/FlutterJNI(11035): Beginning load of flutter...
D/FlutterJNI(11035): flutter (null) was loaded normally!
I/flutter (11035): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(11035): Attaching Geolocator to activity
D/FlutterRenderer(11035): Width is zero. 0,0
D/FlutterGeolocator(11035): Creating service.
D/FlutterGeolocator(11035): Binding to location service.
D/FlutterRenderer(11035): Width is zero. 0,0
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/.example.awaken(11035): Compiler allocated 5239KB to compile void android.view.ViewRootImpl.performTraversals(long)
Syncing files to device sdk gphone16k x86 64...                    143ms

Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on sdk gphone16k x86 64 is available at: http://127.0.0.1:57038/oUdpVCkM1mA=/
The Flutter DevTools debugger and profiler on sdk gphone16k x86 64 is available at:
http://127.0.0.1:57038/oUdpVCkM1mA=/devtools/?uri=ws://127.0.0.1:57038/oUdpVCkM1mA=/ws
I/flutter (11035): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
D/FlutterGeolocator(11035): Geolocator foreground service connected
D/FlutterGeolocator(11035): Initializing Geolocator services
D/FlutterGeolocator(11035): Flutter engine connected. Connected engine count 1
I/Choreographer(11035): Skipped 36 frames!  The application may be doing too much work on its main thread.
D/WindowLayoutComponentImpl(11035): Register WindowLayoutInfoListener on Context=com.example.awaken.MainActivity@4d1a8d9, of which baseContext=android.app.ContextImpl@8710a38
I/HWUI    (11035): Using FreeType backend (prop=Auto)
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/Choreographer(11035): Skipped 47 frames!  The application may be doing too much work on its main thread.
I/HWUI    (11035): Davey! duration=832ms; Flags=1, FrameTimelineVsyncId=910230, IntendedVsync=2525913024276, Vsync=2526696357578, InputEventId=0, HandleInputStart=2526698027936, AnimationStart=2526698028588, PerformTraversalsStart=2526698028916, DrawStart=2526700098226, FrameDeadline=2525929690942, FrameStartTime=2526696769813, FrameInterval=16666666, WorkloadTarget=16666666, AnimationTime=2526696357578, SyncQueued=2526700696834, SyncStart=2526701315464, IssueDrawCommandsStart=2526701586500, SwapBuffers=2526707605473, FrameCompleted=2526745781426, DequeueBufferDuration=35878528, QueueBufferDuration=333580, GpuCompleted=2526714581550, SwapBuffersCompleted=2526745781426, DisplayPresentTime=135953153091728, CommandSubmissionCompleted=2526707605473,
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:9b2d89ee: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
I/FLTFireBGExecutor(11035): Creating background FlutterEngine instance, with args: [--enable-dart-profiling]
W/libc    (11035): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/FLTFireContextHolder(11035): received application context.
I/flutter (11035): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
W/libc    (11035): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/FlutterGeolocator(11035): Geolocator foreground service connected
D/FlutterGeolocator(11035): Initializing Geolocator services
D/FlutterGeolocator(11035): Flutter engine connected. Connected engine count 2
I/FLTFireMsgService(11035): FlutterFirebaseMessagingBackgroundService started!
D/ProfileInstaller(11035): Installing profile for com.example.awaken
I/TRuntime.CctTransportBackend(11035): Making request to: https://firebaselogging.googleapis.com/v0cc/log/batch?format=json_proto3
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:6499f9ee: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
I/TRuntime.CctTransportBackend(11035): Status Code: 200
D/DesktopExperienceFlags(11035): Toggle override initialized to: false
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b02b1fd
D/VRI[SignInHubActivity](11035): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
I/Surface (11035): Creating surface for consumer unnamed-11035-2 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer VRI[SignInHubActivity]#2(BLAST Consumer)2 with slotExpansion=1 for 64 slots
D/VRI[SignInHubActivity](11035): visibilityChanged oldVisibility=true newVisibility=false
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): null
D/ViewRootImpl(11035): Skipping stats log for color mode
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:d2870618: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54        
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
I/flutter (11035): supabase.auth: INFO: Signing out user with scope: local 
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b03b526
D/VRI[SignInHubActivity](11035): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
I/Surface (11035): Creating surface for consumer unnamed-11035-3 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer VRI[SignInHubActivity]#3(BLAST Consumer)3 with slotExpansion=1 for 64 slots
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:350982aa: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/VRI[SignInHubActivity](11035): visibilityChanged oldVisibility=true newVisibility=false
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:59b2f6bd: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): null
D/ViewRootImpl(11035): Skipping stats log for color mode
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54        
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
I/flutter (11035): supabase.auth: INFO: Signing out user with scope: local 
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
I/ImeTracker(11035): com.example.awaken:693698e8: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT fromUser false userId 0 displayId 0
D/InsetsController(11035): show(ime())
D/InsetsController(11035): Setting requestedVisibleTypes to 511 (was 503)
D/InputConnectionAdaptor(11035): The input method toggled cursor monitoring on
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.view.ImeBackAnimationController@7b62347
D/FlutterJNI(11035): Sending viewport metrics to the engine.
W/InteractionJankMonitor(11035): Initializing without READ_DEVICE_CONFIG permission. enabled=false, interval=1, missedFrameThreshold=3, frameTimeThreshold=64, package=com.example.awaken
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/ImeTracker(11035): system_server:e39509c8: onShown
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
W/.example.awaken(11035): Cleared Reference was only reachable from finalizer (only reported once)
I/.example.awaken(11035): Background young concurrent mark compact GC freed 2564KB AllocSpace bytes, 26(1600KB) LOS objects, 43% free, 5344KB/9468KB, paused 133us,6.347ms total 30.528ms
I/ImeTracker(11035): com.example.awaken:79f7c577: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT fromUser false userId 0 displayId 0
D/InsetsController(11035): show(ime())
I/ImeTracker(11035): com.example.awaken:79f7c577: onCancelled at PHASE_CLIENT_APPLY_ANIMATION
I/ImeTracker(11035): com.example.awaken:706ac1fa: onRequestShow at ORIGIN_CLIENT reason SHOW_SOFT_INPUT fromUser false userId 0 displayId 0
D/InsetsController(11035): show(ime())
I/ImeTracker(11035): com.example.awaken:706ac1fa: onCancelled at PHASE_CLIENT_APPLY_ANIMATION
D/InputConnectionAdaptor(11035): The input method toggled cursor monitoring on
I/ImeTracker(11035): com.example.awaken:8cb4921a: onRequestHide at ORIGIN_CLIENT reason HIDE_SOFT_INPUT fromUser false userId 0 displayId 0
D/InsetsController(11035): hide(ime())
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48       
D/InsetsController(11035): Setting requestedVisibleTypes to 503 (was 511)
D/CompatChangeReporter(11035): Compat change id reported: 395521150; UID 10241; state: ENABLED
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/ImeTracker(11035): system_server:85f5cd3f: onCancelled at PHASE_CLIENT_ON_CONTROLS_CHANGED
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@7b1b54
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@4efed48
W/Activity(11035): Can request only one set of permissions at a time
I/Geolocator(11035): The grantResults array is empty. This can happen when the user cancels the permission request
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:fb611b72: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
E/FlutterGeolocator(11035): Geolocator position updates started
E/FlutterGeolocator(11035): Geolocator position updates stopped
E/FlutterGeolocator(11035): There is still another flutter engine connected, not stopping location service
E/FlutterGeolocator(11035): Geolocator position updates started using Android foreground service
D/FlutterGeolocator(11035): Start service in foreground mode.
D/VRI[MainActivity](11035): visibilityChanged oldVisibility=true newVisibility=false
I/Surface (11035): Creating surface for consumer unnamed-11035-4 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer VRI[MainActivity]#4(BLAST Consumer)4 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer unnamed-11035-5 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer 9933352 SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#5(BLAST Consumer)5 with slotExpansion=1 for 64 slots
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:e5f91ba0: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/VRI[MainActivity](11035): visibilityChanged oldVisibility=true newVisibility=false
D/ViewRootImpl(11035): Skipping stats log for color mode
I/Surface (11035): Creating surface for consumer unnamed-11035-6 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer VRI[MainActivity]#6(BLAST Consumer)6 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer unnamed-11035-7 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer 9933352 SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#7(BLAST Consumer)7 with slotExpansion=1 for 64 slots
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:b678942f: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:4775edcc: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/VRI[MainActivity](11035): visibilityChanged oldVisibility=true newVisibility=false
D/FlutterGeolocator(11035): Detaching Geolocator from activity
D/FlutterGeolocator(11035): Flutter engine disconnected. Connected engine count 1
D/FlutterGeolocator(11035): Disposing Geolocator services
E/FlutterGeolocator(11035): Geolocator position updates stopped
E/FlutterGeolocator(11035): There is still another flutter engine connected, not stopping location service
W/libc    (11035): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): null
D/ViewRootImpl(11035): Skipping stats log for color mode
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 177
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 178
W/libc    (11035): Access denied finding property "vendor.mesa.virtgpu.kumquat"
I/flutter (11035): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
W/libc    (11035): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/FLTFireContextHolder(11035): received application context.
D/FlutterGeolocator(11035): Attaching Geolocator to activity
D/FlutterRenderer(11035): Width is zero. 0,0
D/FlutterGeolocator(11035): Geolocator foreground service connected
D/FlutterGeolocator(11035): Initializing Geolocator services
D/FlutterGeolocator(11035): Flutter engine connected. Connected engine count 2
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@98717e4       
D/VRI[MainActivity](11035): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
D/FlutterRenderer(11035): Width is zero. 0,0
I/Surface (11035): Creating surface for consumer unnamed-11035-8 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer VRI[MainActivity]#8(BLAST Consumer)8 with slotExpansion=1 for 64 slots
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/Surface (11035): Creating surface for consumer unnamed-11035-9 with slotExpansion=1 for 64 slots
I/Surface (11035): Creating surface for consumer 3677c13 SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#9(BLAST Consumer)9 with slotExpansion=1 for 64 slots
I/flutter (11035): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
I/Choreographer(11035): Skipped 42 frames!  The application may be doing too much work on its main thread.
D/WindowLayoutComponentImpl(11035): Register WindowLayoutInfoListener on Context=com.example.awaken.MainActivity@3f76849, of which baseContext=android.app.ContextImpl@12b7f7c
D/FlutterJNI(11035): Sending viewport metrics to the engine.
I/Choreographer(11035): Skipped 59 frames!  The application may be doing too much work on its main thread.
D/FlutterJNI(11035): Sending viewport metrics to the engine.
D/InsetsController(11035): hide(ime())
I/ImeTracker(11035): com.example.awaken:7c796de2: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
E/FlutterGeolocator(11035): Geolocator position updates started using Android foreground service
D/FlutterGeolocator(11035): Service already in foreground mode.
W/FLTFireMsgService(11035): Attempted to start a duplicate background isolate. Returning...
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 179
D/WindowOnBackDispatcher(11035): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@2553262
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 180
I/.example.awaken(11035): NativeAlloc concurrent mark compact GC freed 1779KB AllocSpace bytes, 2(128KB) LOS objects, 49% free, 5444KB/10MB, paused 120us,18.765ms to10MB, paused 120us,18.765ms total 31.596ms
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 181
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 182
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 183
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 184
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 185
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 186
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 187
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 188
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 189
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 190
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 191
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 192
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 193
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 194
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 195
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 196
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 197
W/FlutterJNI(11035): Tried to send a platform message to Flutter, but FlutterJNI was detached from native C++. Could not send. Channel: flutter.baseflow.com/geolocator_updates_android. Response ID: 198