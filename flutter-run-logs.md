PS J:\GitHub\awaken> flutter run --dart-define-from-file=.env
Launching lib\main.dart on sdk gphone16k x86 64 in debug mode...
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): camera_android_camerax, flutter_timezone, wakelock_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.       
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
Running Gradle task 'assembleDebug'...                             17.3s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          960ms
I/FlutterActivityAndFragmentDelegate(10013): If you are attempting to set --enable-dart-profiling via Intent extras to launch a Flutter component outside of using the Flutter CLI, note that support for setting engine flags on Android via Intent will soon be dropped; see https://github.com/flutter/flutter/issues/180686 for more information on this breaking change. To migrate, set --enable-dart-profiling or any other flags specified via Intent extras on the command line instead or see https://github.com/flutter/flutter/blob/main/docs/engine/Flutter-Android-Engine-Flags.md for alternative methods.
D/FlutterJNI(10013): Beginning load of flutter...
D/FlutterJNI(10013): flutter (null) was loaded normally!
I/flutter (10013): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(10013): Attaching Geolocator to activity
D/FlutterRenderer(10013): Width is zero. 0,0
I/Choreographer(10013): Skipped 114 frames!  The application may be doing too much work on its main thread.
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b978f2c
I/WindowExtensionsImpl(10013): Initializing Window Extensions, vendor API level=10, activity embedding enabled=true
W/UiContextUtils(10013): Requested context is a non-UI Context. Creating a UI-Context with display: 0. Context: Context=android.app.Application@e5dac, of which baseContext=android.app.ContextImpl@cea4160
D/VRI[MainActivity](10013): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
D/FlutterRenderer(10013): Width is zero. 0,0
I/Surface (10013): Creating surface for consumer unnamed-10013-0 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer VRI[MainActivity]#0(BLAST Consumer)0 with slotExpansion=1 for 64 slots
D/FlutterJNI(10013): Sending viewport metrics to the engine.
I/Surface (10013): Creating surface for consumer unnamed-10013-1 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer cb052ea SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#1(BLAST Consumer)1 with slotExpansion=1 for 64 slots
I/.example.awaken(10013): Compiler allocated 5239KB to compile void android.view.ViewRootImpl.performTraversals(long)
Syncing files to device sdk gphone16k x86 64...                    147ms

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on sdk gphone16k x86 64 is available at: http://127.0.0.1:59938/gxwysjLfJ0A=/
The Flutter DevTools debugger and profiler on sdk gphone16k x86 64 is available at:
http://127.0.0.1:59938/gxwysjLfJ0A=/devtools/?uri=ws://127.0.0.1:59938/gxwysjLfJ0A=/ws
D/FlutterGeolocator(10013): Creating service.
D/FlutterGeolocator(10013): Binding to location service.
I/Choreographer(10013): Skipped 33 frames!  The application may be doing too much work on its main thread.
I/flutter (10013): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
D/FlutterGeolocator(10013): Geolocator foreground service connected
D/FlutterGeolocator(10013): Initializing Geolocator services
D/FlutterGeolocator(10013): Flutter engine connected. Connected engine count 1
D/WindowLayoutComponentImpl(10013): Register WindowLayoutInfoListener on Context=com.example.awaken.MainActivity@8d49f51, of which baseContext=android.app.ContextImpl@b96838e
D/FlutterJNI(10013): Sending viewport metrics to the engine.
I/HWUI    (10013): Using FreeType backend (prop=Auto)
D/FlutterJNI(10013): Sending viewport metrics to the engine.
I/Choreographer(10013): Skipped 82 frames!  The application may be doing too much work on its main thread.
D/InsetsController(10013): hide(ime())
I/ImeTracker(10013): com.example.awaken:554d26db: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/ProfileInstaller(10013): Installing profile for com.example.awaken
I/.example.awaken(10013): Background concurrent mark compact GC freed 3103KB AllocSpace bytes, 10(352KB) LOS objects, 49% free, 3615KB/7230KB, paused 1.347ms,7.306ms total 22.769ms
D/InsetsController(10013): hide(ime())
I/ImeTracker(10013): com.example.awaken:453a7778: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
E/FlutterGeolocator(10013): Geolocator position updates started
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@c12e477
I/.example.awaken(10013): Background young concurrent mark compact GC freed 3305KB AllocSpace bytes, 0(0B) LOS objects, 43% free, 4096KB/7230KB, paused 4.427ms,13.201ms total 134.632ms
I/.example.awaken(10013): Background young concurrent mark compact GC freed 2912KB AllocSpace bytes, 0(0B) LOS objects, 40% free, 4320KB/7230KB, paused 8.533ms,20.314ms total 77.457ms
I/.example.awaken(10013): Background young concurrent mark compact GC freed 4016KB AllocSpace bytes, 0(0B) LOS objects, 48% free, 4239KB/8255KB, paused 1.452ms,5.188ms total 17.859ms

══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following CancellationException was thrown:
Cancelled

When the exception was thrown, this was the stack:
#0      TileLoader._renderTile (package:vector_map_tiles/src/raster/tile_loader.dart:72:7)
#1      TileLoader._renderJob (package:vector_map_tiles/src/raster/tile_loader.dart:66:40)
#2      ImmediateExecutor.submit (package:executor_lib/src/immdediate_executor.dart:17:44)
#3      ConcurrencyExecutor._startJob (package:executor_lib/src/concurrency_executor.dart:74:10)
#4      ConcurrencyExecutor._startJobs (package:executor_lib/src/concurrency_executor.dart:59:7)
#5      ConcurrencyExecutor._startJob.<anonymous closure>
(package:executor_lib/src/concurrency_executor.dart:81:7)
<asynchronous suspension>
(elided 5 frames from dart:async)
════════════════════════════════════════════════════════════════════════════════════════════════════       

I/.example.awaken(10013): Background young concurrent mark compact GC freed 4029KB AllocSpace bytes, 0(0B) LOS objects, 48% free, 4239KB/8255KB, paused 1.139ms,5.610ms total 17.146ms
E/FlutterGeolocator(10013): Geolocator position updates stopped
E/FlutterGeolocator(10013): There is still another flutter engine connected, not stopping location service
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b978f2c
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@c12e477
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b978f2c
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@c12e477
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b978f2c
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@c12e477
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@b978f2c
D/VRI[MainActivity](10013): visibilityChanged oldVisibility=true newVisibility=false
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): null
D/FlutterGeolocator(10013): Detaching Geolocator from activity
D/FlutterGeolocator(10013): Flutter engine disconnected. Connected engine count 0
D/FlutterGeolocator(10013): Disposing Geolocator services
E/FlutterGeolocator(10013): Geolocator position updates stopped
D/FlutterGeolocator(10013): Stopping location service.
W/libc    (10013): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/ViewRootImpl(10013): Skipping stats log for color mode
D/FlutterGeolocator(10013): Unbinding from location service.
D/FlutterGeolocator(10013): Destroying location service.
D/FlutterGeolocator(10013): Stopping location service.
D/FlutterGeolocator(10013): Destroyed location service.
I/GFXSTREAM(10013): [eglDisplay.cpp(297)] Opening libGLESv1_CM_emulation.so
I/GFXSTREAM(10013): [eglDisplay.cpp(297)] Opening libGLESv2_emulation.so
W/libc    (10013): Access denied finding property "vendor.mesa.virtgpu.kumquat"
W/HWUI    (10013): Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED, retrying without...
W/HWUI    (10013): Failed to initialize 101010-2 format, error = EGL_SUCCESS
W/libc    (10013): Access denied finding property "vendor.mesa.virtgpu.kumquat"
I/flutter (10013): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
W/libc    (10013): Access denied finding property "vendor.mesa.virtgpu.kumquat"
D/FlutterGeolocator(10013): Attaching Geolocator to activity
D/FlutterRenderer(10013): Width is zero. 0,0
W/FlutterJNI(10013): Tried to send a platform message response, but FlutterJNI was detached from native C++. Could not send. Response ID: 176
W/FlutterJNI(10013): Tried to send a platform message response, but FlutterJNI was detached from native C++. Could not send. Response ID: 172
D/FlutterGeolocator(10013): Creating service.
D/FlutterGeolocator(10013): Binding to location service.
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): android.app.Activity$$ExternalSyntheticLambda0@d9b51e8
D/VRI[MainActivity](10013): WindowInsets changed: 1080x2424 statusBars:[0,142,0,0] navigationBars:[0,0,0,63] mandatorySystemGestures:[0,174,0,84]
D/FlutterRenderer(10013): Width is zero. 0,0
I/Surface (10013): Creating surface for consumer unnamed-10013-2 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer VRI[MainActivity]#2(BLAST Consumer)2 with slotExpansion=1 for 64 slots
D/FlutterJNI(10013): Sending viewport metrics to the engine.
I/Surface (10013): Creating surface for consumer unnamed-10013-3 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer 44370e7 SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#3(BLAST Consumer)3 with slotExpansion=1 for 64 slots
D/FlutterGeolocator(10013): Geolocator foreground service connected
D/FlutterGeolocator(10013): Initializing Geolocator services
D/FlutterGeolocator(10013): Flutter engine connected. Connected engine count 1
I/flutter (10013): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
I/Choreographer(10013): Skipped 30 frames!  The application may be doing too much work on its main thread.
D/WindowLayoutComponentImpl(10013): Register WindowLayoutInfoListener on Context=com.example.awaken.MainActivity@59e5b3d, of which baseContext=android.app.ContextImpl@e9a6e39
D/FlutterJNI(10013): Sending viewport metrics to the engine.
I/Choreographer(10013): Skipped 74 frames!  The application may be doing too much work on its main thread.
D/FlutterJNI(10013): Sending viewport metrics to the engine.
D/InsetsController(10013): hide(ime())
I/ImeTracker(10013): com.example.awaken:d5882d1c: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/VRI[MainActivity](10013): visibilityChanged oldVisibility=true newVisibility=false
D/ViewRootImpl(10013): Skipping stats log for color mode
I/Surface (10013): Creating surface for consumer unnamed-10013-4 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer VRI[MainActivity]#4(BLAST Consumer)4 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer unnamed-10013-5 with slotExpansion=1 for 64 slots
I/Surface (10013): Creating surface for consumer 44370e7 SurfaceView[com.example.awaken/com.example.awaken.MainActivity]#5(BLAST Consumer)5 with slotExpansion=1 for 64 slots
D/InsetsController(10013): hide(ime())
I/ImeTracker(10013): com.example.awaken:3d9bf022: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN

══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following CancellationException was thrown:
Cancelled

When the exception was thrown, this was the stack
════════════════════════════════════════════════════════════════════════════════════════════════════

Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
E/flutter (10013): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Cancelled
E/flutter (10013): 
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled

Performing hot restart...                                               
Restarted application in 3,031ms.
I/flutter (10013): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
E/FlutterGeolocator(10013): Geolocator position updates started

══╡ EXCEPTION CAUGHT BY IMAGE RESOURCE SERVICE ╞════════════════════════════════════════════════════
The following CancellationException was thrown:
Cancelled

When the exception was thrown, this was the stack
════════════════════════════════════════════════════════════════════════════════════════════════════

Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
Another exception was thrown: Cancelled
D/WindowOnBackDispatcher(10013): setTopOnBackInvokedCallback (unwrapped): io.flutter.embedding.android.FlutterActivity$1@920ba87
W/.example.awaken(10013): Reducing the number of considered missed Gc histogram windows from 232 to 100
