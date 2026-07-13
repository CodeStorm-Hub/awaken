Running Gradle task 'assembleDebug'...                             19.5s
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...          43.4s
I/FlutterActivityAndFragmentDelegate(23369): If you are attempting to set --enable-dart-profiling via Intent extras to launch a Flutter component outside of using the Flutter CLI, note that support for setting engine flags on Android via Intent will soon be dropped; see https://github.com/flutter/flutter/issues/180686 for more information on this breaking change. To migrate, set --enable-dart-profiling or any other flags specified via Intent extras on the command line instead or see https://github.com/flutter/flutter/blob/main/docs/engine/Flutter-Android-Engine-Flags.md for alternative methods.
D/FlutterJNI(23369): Beginning load of flutter...
D/FlutterJNI(23369): flutter (null) was loaded normally!
I/flutter (23369): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I/flutter (23369): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(23369): Attaching Geolocator to activity
D/FlutterRenderer(23369): Width is zero. 0,0
D/FlutterRenderer(23369): Width is zero. 0,0
D/FlutterJNI(23369): Sending viewport metrics to the engine.
I/SurfaceView(23369): 244178581 surfaceChanged -- format=4 w=1080 h=2358
I/SurfaceView@e8dde95(23369): surfaceChanged (1080,2358) 1 #8 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2358}
I/SurfaceView(23369): 244178581 surfaceRedrawNeeded
V/SurfaceView@e8dde95(23369): Layout: x=0 y=0 w=1080 h=2358, frame=Rect(0, 0 - 1080, 2358)
D/FlutterGeolocator(23369): Creating service.
D/FlutterGeolocator(23369): Binding to location service.
D/OpenGLRenderer(23369): HWUI - treat SMPTE_170M as sRGB
I/flutter (23369): supabase.supabase_flutter: INFO: ***** Supabase init completed ***** 
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.example.awaken.MainActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
D/FlutterGeolocator(23369): Geolocator foreground service connected
D/FlutterGeolocator(23369): Initializing Geolocator services
D/FlutterGeolocator(23369): Flutter engine connected. Connected engine count 1
D/FlutterJNI(23369): Sending viewport metrics to the engine.
D/FlutterJNI(23369): Sending viewport metrics to the engine.
I/BLASTBufferQueue_Java(23369): update, w= 1080 h= 2400 mName = ViewRootImpl@d61098b[MainActivity] mNativeObject= 0xb4000078db322e90 sc.mNativeObject= 0xb4000078eb336410 format= -3 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3017 android.view.ViewRootImpl.relayoutWindow:10131 android.view.ViewRootImpl.performTraversals:4110 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 
I/ViewRootImpl@d61098b[MainActivity](23369): Relayout returned: old=(0,0,1080,2400) new=(0,0,1080,2400) relayoutAsync=false req=(1080,2400)0 dur=3 res=0x401 s={true 0xb4000079fb35c4a0} ch=false seqId=0
D/FlutterJNI(23369): Sending viewport metrics to the engine.
D/FlutterJNI(23369): Sending viewport metrics to the engine.
I/SurfaceView(23369): 244178581 Changes: creating=false format=false size=true visible=false alpha=false hint=false visible=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView@e8dde95(23369): 244178581 Cur surface: Surface(name=null)/@0x4cdfbe5
I/BLASTBufferQueue_Java(23369): update, w= 1080 h= 2400 mName = null mNativeObject= 0xb4000078db3237f0 sc.mNativeObject= 0xb4000078eb32d950 format= 4 caller= android.view.SurfaceView.setBufferSize:1438 android.view.SurfaceView.performSurfaceTransaction:994 android.view.SurfaceView.updateSurface:1210 android.view.SurfaceView.setFrame:559 android.view.View.layout:25765 android.widget.FrameLayout.layoutChildren:332 
I/SurfaceView@e8dde95(23369): pST: sr = Rect(0, 0 - 1080, 2400) sw = 1080 sh = 2400
D/SurfaceView@e8dde95(23369): 244178581 performSurfaceTransaction RenderWorker position = [0, 0, 1080, 2400] surfaceSize = 1080x2400
I/SurfaceView@e8dde95(23369): updateSurface: mVisible = true mSurface.isValid() = true
I/SurfaceView@e8dde95(23369): updateSurface: mSurfaceCreated = true surfaceChanged = false visibleChanged = false
I/SurfaceView(23369): 244178581 surfaceChanged -- format=4 w=1080 h=2400
I/SurfaceView@e8dde95(23369): surfaceChanged (1080,2400) 1 #5 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2400}
I/SurfaceView(23369): 244178581 surfaceRedrawNeeded
V/SurfaceView@e8dde95(23369): Layout: x=0 y=0 w=1080 h=2400, frame=Rect(0, 0 - 1080, 2400)
D/ViewRootImpl@d61098b[MainActivity](23369): reportNextDraw android.view.ViewRootImpl.performTraversals:4718 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 
Syncing files to device SM A528B...                                211ms

Flutter run key commands.
r Hot reload. 
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

A Dart VM Service on SM A528B is available at: http://127.0.0.1:64545/nWeYLObRmM8=/
The Flutter DevTools debugger and profiler on SM A528B is available at: http://127.0.0.1:64545/nWeYLObRmM8=/devtools/?uri=ws://127.0.0.1:64545/nWeYLObRmM8=/ws
I/BLASTBufferQueue(23369): [SurfaceView[com.example.awaken/com.example.awaken.MainActivity]@0#1](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/Choreographer(23369): Skipped 262 frames!  The application may be doing too much work on its main thread.
I/SurfaceView(23369): 244178581 finishedDrawing
I/SurfaceView(23369): 244178581 finishedDrawing
D/CompatibilityChangeReporter(23369): Compat change id reported: 194532703; UID 10653; state: ENABLED
D/CompatibilityChangeReporter(23369): Compat change id reported: 253665015; UID 10653; state: ENABLED
I/Choreographer(23369): Skipped 54 frames!  The application may be doing too much work on its main thread.
I/ViewRootImpl@d61098b[MainActivity](23369): Setup new sync=wmsSync-ViewRootImpl@d61098b[MainActivity]#2
I/ViewRootImpl@d61098b[MainActivity](23369): Creating new active sync group ViewRootImpl@d61098b[MainActivity]#3
I/ViewRootImpl@d61098b[MainActivity](23369): registerCallbacksForSync syncBuffer=false
D/SurfaceView(23369): 244178581 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2400] surfaceSize = 1080x2400
I/SurfaceView@e8dde95(23369): uSP: rtp = Rect(0, 0 - 1080, 2400) rtsw = 1080 rtsh = 2400
I/SurfaceView@e8dde95(23369): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SurfaceView@e8dde95(23369): aOrMT: ViewRootImpl@d61098b[MainActivity] t = android.view.SurfaceControl$Transaction@7f834c2 fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1666 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:369 
I/ViewRootImpl@d61098b[MainActivity](23369): mWNT: t=0xb4000078ab331990 mBlastBufferQueue=0xb4000078db322e90 fn= 1 mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1598 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1666 
I/ViewRootImpl@d61098b[MainActivity](23369): Received frameDrawingCallback syncResult=0 frameNum=1.
I/ViewRootImpl@d61098b[MainActivity](23369): mWNT: t=0xb4000078ab369750 mBlastBufferQueue=0xb4000078db322e90 fn= 1 mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$8.onFrameDraw:13841 android.view.ThreadedRenderer$1.onFrameDraw:792 <bottom of call stack> 
I/ViewRootImpl@d61098b[MainActivity](23369): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(23369): [ViewRootImpl@d61098b[MainActivity]#0](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/ViewRootImpl@d61098b[MainActivity](23369): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
D/OpenGLRenderer(23369): CFMS:: SetUp Pid : 23369    Tid : 23438
I/ViewRootImpl@d61098b[MainActivity](23369): reportDrawFinished seqId=0
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 1 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
D/ViewRootImpl@d61098b[MainActivity](23369): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb4000079fb35c4a0}
D/InputMethodManagerUtils(23369): startInputInner - Id : 0
I/InputMethodManager(23369): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
D/InputMethodManagerUtils(23369): startInputInner - Id : 0
I/InsetsController(23369): onStateChanged: host=com.example.awaken/com.example.awaken.MainActivity, from=android.view.ViewRootImpl$ViewRootHandler.handleMessageImpl:7209, state=InsetsState: {mDisplayFrame=Rect(0, 0 - 1080, 2400), mDisplayCutout=DisplayCutout{insets=Rect(0, 88 - 0, 0) waterfall=Insets{left=0, top=0, right=0, bottom=0} boundingRect={Bounds=[Rect(0, 0 - 0, 0), Rect(512, 0 - 568, 88), Rect(0, 0 - 0, 0), Rect(0, 0 - 0, 0)]} cutoutPathParserInfo={CutoutPathParserInfo{displayWidth=1080 displayHeight=2400 physicalDisplayWidth=1080 physicalDisplayHeight=2400 density={2.8125} cutoutSpec={M 0,0 M 0,11.43427858034597 a 9.899054752987353,9.899054752987353 0 1,0 0,19.79810950597471 a 9.899054752987353,9.899054752987353 0 1,0 0,-19.79810950597471 Z @dp} rotation={0} scale={1.0} physicalPixelDisplaySizeRatio={1.0}}}}, mRoundedCorners=RoundedCorners{[RoundedCorner{position=TopLeft, radius=0, center=Point(0, 0)}, RoundedCorner{position=TopRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomLeft, radius=0, center=Point(0, 0)}]}  mRoundedCornerFrame=Rect(0, 0 - 1080, 2400), mPrivacyIndicatorBounds=PrivacyIndicatorBounds {static bounds=Rect(956, 0 - 1080, 88) rotation=0}, mDisplayShape=DisplayShape{ spec=-311912193 displayWidth=1080 displayHeight=2400 physicalPixelDisplaySizeRatio=1.0 rotation=0 offsetX=0 offsetY=0 scale=1.0}, mSources= { InsetsSource: {c9350000 mType=statusBars mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {c9350005 mType=mandatorySystemGestures mFrame=[0,0][1080,122] mVisible=true mFlags=[]}, InsetsSource: {c9350006 mType=tappableElement mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {e4a00001 mType=navigationBars mFrame=[0,2358][1080,2400] mVisible=true mFlags=[SUPPRESS_SCRIM]}, InsetsSource: {e4a00004 mType=systemGestures mFrame=[0,0][84,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00005 mType=mandatorySystemGestures mFrame=[0,2310][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00006 mType=tappableElement mFrame=[0,0][0,0] mVisible=true mFlags=[]}, InsetsSource: {e4a00024 mType=systemGestures mFrame=[996,0][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {3 mType=ime mFrame=[0,0][0,0] mVisible=false mFlags=[]}, InsetsSource: {27 mType=displayCutout mFrame=[0,0][1080,88] mVisible=true mFlags=[]} }
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=false, type=ime, host=com.example.awaken/com.example.awaken.MainActivity
I/FLTFireBGExecutor(23369): Creating background FlutterEngine instance, with args: [--enable-dart-profiling]
D/FLTFireContextHolder(23369): received application context.
I/AdrenoVK-0(23369): QUALCOMM build          : 9ad1b67875, Ib48d2dada6
I/AdrenoVK-0(23369): Build Date              : 05/11/25
I/AdrenoVK-0(23369): Shader Compiler Version : EV031.35.01.12
I/AdrenoVK-0(23369): Local Branch            : 
I/AdrenoVK-0(23369): Remote Branch           : refs/tags/AU_LINUX_ANDROID_LA.UM.9.14.11.00.00.571.148
I/AdrenoVK-0(23369): Remote Branch           : NONE
I/AdrenoVK-0(23369): Reconstruct Branch      : NOTHING
I/AdrenoVK-0(23369): Build Config            : S P 10.0.7 AArch64
I/AdrenoVK-0(23369): Driver Path             : /vendor/lib64/hw/vulkan.adreno.so
I/flutter (23369): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
I/flutter (23369): [IMPORTANT:flutter/shell/platform/android/android_context_gl_impeller.cc(104)] Using the Impeller rendering backend (OpenGLES).
D/FlutterGeolocator(23369): Geolocator foreground service connected
D/FlutterGeolocator(23369): Initializing Geolocator services
D/FlutterGeolocator(23369): Flutter engine connected. Connected engine count 2
I/FLTFireMsgService(23369): FlutterFirebaseMessagingBackgroundService started!
D/ProfileInstaller(23369): Installing profile for com.example.awaken
W/WindowOnBackDispatcher(23369): OnBackInvokedCallback is not enabled for the application.
W/WindowOnBackDispatcher(23369): Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.
I/flutter (23369): supabase.auth: INFO: Signing out user with scope: local 
W/WindowOnBackDispatcher(23369): OnBackInvokedCallback is not enabled for the application.
W/WindowOnBackDispatcher(23369): Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.
W/WindowOnBackDispatcher(23369): OnBackInvokedCallback is not enabled for the application.
W/WindowOnBackDispatcher(23369): Set 'android:enableOnBackInvokedCallback="true"' in the application manifest.
I/DecorView(23369): setWindowBackground: isPopOver=false color=0 d=android.graphics.drawable.ColorDrawable@15dfe05
D/NativeCustomFrequencyManager(23369): [NativeCFMS] BpCustomFrequencyManager::BpCustomFrequencyManager()
I/InsetsController(23369): onStateChanged: host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity, from=android.view.ViewRootImpl.setView:1753, state=InsetsState: {mDisplayFrame=Rect(0, 0 - 1080, 2400), mDisplayCutout=DisplayCutout{insets=Rect(0, 88 - 0, 0) waterfall=Insets{left=0, top=0, right=0, bottom=0} boundingRect={Bounds=[Rect(0, 0 - 0, 0), Rect(512, 0 - 568, 88), Rect(0, 0 - 0, 0), Rect(0, 0 - 0, 0)]} cutoutPathParserInfo={CutoutPathParserInfo{displayWidth=1080 displayHeight=2400 physicalDisplayWidth=1080 physicalDisplayHeight=2400 density={2.8125} cutoutSpec={M 0,0 M 0,11.43427858034597 a 9.899054752987353,9.899054752987353 0 1,0 0,19.79810950597471 a 9.899054752987353,9.899054752987353 0 1,0 0,-19.79810950597471 Z @dp} rotation={0} scale={1.0} physicalPixelDisplaySizeRatio={1.0}}}}, mRoundedCorners=RoundedCorners{[RoundedCorner{position=TopLeft, radius=0, center=Point(0, 0)}, RoundedCorner{position=TopRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomLeft, radius=0, center=Point(0, 0)}]}  mRoundedCornerFrame=Rect(0, 0 - 1080, 2400), mPrivacyIndicatorBounds=PrivacyIndicatorBounds {static bounds=Rect(956, 0 - 1080, 88) rotation=0}, mDisplayShape=DisplayShape{ spec=-311912193 displayWidth=1080 displayHeight=2400 physicalPixelDisplaySizeRatio=1.0 rotation=0 offsetX=0 offsetY=0 scale=1.0}, mSources= { InsetsSource: {c9350000 mType=statusBars mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {c9350005 mType=mandatorySystemGestures mFrame=[0,0][1080,122] mVisible=true mFlags=[]}, InsetsSource: {c9350006 mType=tappableElement mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {e4a00001 mType=navigationBars mFrame=[0,2358][1080,2400] mVisible=true mFlags=[SUPPRESS_SCRIM]}, InsetsSource: {e4a00004 mType=systemGestures mFrame=[0,0][84,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00005 mType=mandatorySystemGestures mFrame=[0,2310][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00006 mType=tappableElement mFrame=[0,0][0,0] mVisible=true mFlags=[]}, InsetsSource: {e4a00024 mType=systemGestures mFrame=[996,0][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {27 mType=displayCutout mFrame=[0,0][1080,88] mVisible=true mFlags=[]} }
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): synced displayState. AttachInfo displayState=2
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): setView = com.android.internal.policy.DecorView@23e33fe TM=true
D/OpenGLRenderer(23369): HWUI - treat SMPTE_170M as sRGB
I/InsetsController(23369): onStateChanged: host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity, from=android.view.ViewRootImpl.relayoutWindow:10072, state=InsetsState: {mDisplayFrame=Rect(0, 0 - 1080, 2400), mDisplayCutout=DisplayCutout{insets=Rect(0, 88 - 0, 0) waterfall=Insets{left=0, top=0, right=0, bottom=0} boundingRect={Bounds=[Rect(0, 0 - 0, 0), Rect(512, 0 - 568, 88), Rect(0, 0 - 0, 0), Rect(0, 0 - 0, 0)]} cutoutPathParserInfo={CutoutPathParserInfo{displayWidth=1080 displayHeight=2400 physicalDisplayWidth=1080 physicalDisplayHeight=2400 density={2.8125} cutoutSpec={M 0,0 M 0,11.43427858034597 a 9.899054752987353,9.899054752987353 0 1,0 0,19.79810950597471 a 9.899054752987353,9.899054752987353 0 1,0 0,-19.79810950597471 Z @dp} rotation={0} scale={1.0} physicalPixelDisplaySizeRatio={1.0}}}}, mRoundedCorners=RoundedCorners{[RoundedCorner{position=TopLeft, radius=0, center=Point(0, 0)}, RoundedCorner{position=TopRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomRight, radius=0, center=Point(0, 0)}, RoundedCorner{position=BottomLeft, radius=0, center=Point(0, 0)}]}  mRoundedCornerFrame=Rect(0, 0 - 1080, 2400), mPrivacyIndicatorBounds=PrivacyIndicatorBounds {static bounds=Rect(956, 0 - 1080, 88) rotation=0}, mDisplayShape=DisplayShape{ spec=-311912193 displayWidth=1080 displayHeight=2400 physicalPixelDisplaySizeRatio=1.0 rotation=0 offsetX=0 offsetY=0 scale=1.0}, mSources= { InsetsSource: {c9350000 mType=statusBars mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {c9350005 mType=mandatorySystemGestures mFrame=[0,0][1080,122] mVisible=true mFlags=[]}, InsetsSource: {c9350006 mType=tappableElement mFrame=[0,0][1080,88] mVisible=true mFlags=[]}, InsetsSource: {e4a00001 mType=navigationBars mFrame=[0,2358][1080,2400] mVisible=true mFlags=[SUPPRESS_SCRIM]}, InsetsSource: {e4a00004 mType=systemGestures mFrame=[0,0][84,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00005 mType=mandatorySystemGestures mFrame=[0,2310][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {e4a00006 mType=tappableElement mFrame=[0,0][0,0] mVisible=true mFlags=[]}, InsetsSource: {e4a00024 mType=systemGestures mFrame=[996,0][1080,2400] mVisible=true mFlags=[]}, InsetsSource: {3 mType=ime mFrame=[0,0][0,0] mVisible=false mFlags=[]}, InsetsSource: {27 mType=displayCutout mFrame=[0,0][1080,88] mVisible=true mFlags=[]} }
I/BufferQueueProducer(23369): [](id:5b4900000002,api:0,p:0,c:23369) setDequeueTimeout:2077252342
I/BLASTBufferQueue_Java(23369): new BLASTBufferQueue, mName= ViewRootImpl@2f93e03[SignInHubActivity] mNativeObject= 0xb4000078db3506b0 sc.mNativeObject= 0xb4000078eb359f90 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3028 android.view.ViewRootImpl.relayoutWindow:10131 android.view.ViewRootImpl.performTraversals:4110 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 android.view.Choreographer.doCallbacks:1153 android.view.Choreographer.doFrame:1079 android.view.Choreographer$FrameDisplayEventReceiver.run:1646 
I/BLASTBufferQueue_Java(23369): update, w= 1080 h= 2400 mName = ViewRootImpl@2f93e03[SignInHubActivity] mNativeObject= 0xb4000078db3506b0 sc.mNativeObject= 0xb4000078eb359f90 format= -2 caller= android.graphics.BLASTBufferQueue.<init>:89 android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3028 android.view.ViewRootImpl.relayoutWindow:10131 android.view.ViewRootImpl.performTraversals:4110 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Relayout returned: old=(0,0,1080,2400) new=(0,0,1080,2400) relayoutAsync=false req=(1080,2400)0 dur=9 res=0x403 s={true 0xb4000079fb38b200} ch=true seqId=0
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): performConfigurationChange setNightDimText nightDimLevel=0
D/ViewRootImpl@2f93e03[SignInHubActivity](23369): mThreadedRenderer.initialize() mSurface={isValid=true 0xb4000079fb38b200} hwInitialized=true
D/ViewRootImpl@2f93e03[SignInHubActivity](23369): reportNextDraw android.view.ViewRootImpl.performTraversals:4718 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Setup new sync=wmsSync-ViewRootImpl@2f93e03[SignInHubActivity]#4
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Creating new active sync group ViewRootImpl@2f93e03[SignInHubActivity]#5
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): registerCallbacksForSync syncBuffer=false
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Received frameDrawingCallback syncResult=0 frameNum=1.
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): mWNT: t=0xb4000078ab3774b0 mBlastBufferQueue=0xb4000078db3506b0 fn= 1 mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$8.onFrameDraw:13841 android.view.ThreadedRenderer$1.onFrameDraw:792 <bottom of call stack> 
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(23369): [ViewRootImpl@2f93e03[SignInHubActivity]#2](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
D/OpenGLRenderer(23369): CFMS:: SetUp Pid : 23369    Tid : 23438
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): reportDrawFinished seqId=0
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(23369): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(23369): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.example.awaken.MainActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
D/InputTransport(23369): Input channel destroyed: 'ClientS', fd=166
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity
D/CompatibilityChangeReporter(23369): Compat change id reported: 78294732; UID 10653; state: ENABLED
I/ViewRootImpl@d61098b[MainActivity](23369): Resizing android.view.ViewRootImpl@4cd4ab0: frame = [0,0][1080,2400] reportDraw = true forceLayout = false syncSeqId = -1
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(23369): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(23369): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.example.awaken.MainActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
I/ViewRootImpl@d61098b[MainActivity](23369): handleResized, msg = 5 frames=ClientWindowFrames{frame=[0,0][1080,2400] display=[0,0][1080,2400] parentFrame=[0,0][0,0]} forceNextWindowRelayout=false displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false
I/ViewRootImpl@d61098b[MainActivity](23369): handleResized mSyncSeqId = 0
D/ViewRootImpl@d61098b[MainActivity](23369): reportNextDraw android.view.ViewRootImpl.handleResized:2530 android.view.ViewRootImpl.-$$Nest$mhandleResized:0 android.view.ViewRootImpl$ViewRootHandler.handleMessageImpl:7197 android.view.ViewRootImpl$ViewRootHandler.handleMessage:7166 android.os.Handler.dispatchMessage:106 
D/FlutterJNI(23369): Sending viewport metrics to the engine.
I/ViewRootImpl@d61098b[MainActivity](23369): Setup new sync=wmsSync-ViewRootImpl@d61098b[MainActivity]#6
I/ViewRootImpl@d61098b[MainActivity](23369): Creating new active sync group ViewRootImpl@d61098b[MainActivity]#7
I/ViewRootImpl@d61098b[MainActivity](23369): registerCallbacksForSync syncBuffer=false
I/ViewRootImpl@d61098b[MainActivity](23369): Received frameDrawingCallback syncResult=0 frameNum=3.
I/ViewRootImpl@d61098b[MainActivity](23369): mWNT: t=0xb4000078ab3698b0 mBlastBufferQueue=0xb4000078db322e90 fn= 3 mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$8.onFrameDraw:13841 android.view.ThreadedRenderer$1.onFrameDraw:792 <bottom of call stack> 
I/ViewRootImpl@d61098b[MainActivity](23369): Setting up sync and frameCommitCallback
I/ViewRootImpl@d61098b[MainActivity](23369): Received frameCommittedCallback lastAttemptedDrawFrameNum=3 didProduceBuffer=true
I/ViewRootImpl@d61098b[MainActivity](23369): reportDrawFinished seqId=0
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 1 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
D/ViewRootImpl@d61098b[MainActivity](23369): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb4000079fb35c4a0}
D/InputMethodManagerUtils(23369): startInputInner - Id : 0
I/InputMethodManager(23369): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): handleAppVisibility mAppVisible = true visible = false
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): stopped(true) old = false
D/ViewRootImpl@2f93e03[SignInHubActivity](23369): WindowStopped on com.example.awaken/com.google.android.gms.auth.api.signin.internal.SignInHubActivity set to true
W/WindowOnBackDispatcher(23369): sendCancelIfRunning: isInProgress=falsecallback=android.view.ViewRootImpl$$ExternalSyntheticLambda19@445920a
I/ViewRootImpl@2f93e03[SignInHubActivity](23369): dispatchDetachedFromWindow
D/InputTransport(23369): Input channel destroyed: 'd2e7c4c', fd=150
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=false, type=ime, host=com.example.awaken/com.example.awaken.MainActivity
D/SmartClipDataCropperImpl(23369): doExtractSmartClipData : Extraction start! reqId = 13  Cropped area = Rect(540, 1200 - 541, 1201)  Package = com.example.awaken
D/SmartClipDataCropperImpl(23369): addAppMetaTag : package name is com.example.awaken
D/SmartClipDataCropperImpl(23369): sendExtractionResultToSmartClipService : -- Extracted SmartClip data information --
D/SmartClipDataCropperImpl(23369): sendExtractionResultToSmartClipService : Request Id : 13
D/SmartClipDataCropperImpl(23369): sendExtractionResultToSmartClipService : Extraction mode : 1
D/SemSmartClipDataRepository(23369): ----- Start of SmartClip repository informations -----
D/SemSmartClipDataRepository(23369): ** Content type : image
D/SemSmartClipDataRepository(23369): ** Meta area rect : Rect(0, 0 - 0, 0)
D/SemSmartClipDataRepository(23369): ** Captured image file path : null
D/SemSmartClipDataRepository(23369): ----- End of SmartClip repository informations -----
D/SmartClipDataCropperImpl(23369): sendExtractionResultToSmartClipService : Elapsed = 9
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(23369): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(23369): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
D/SmartClipRemoteRequestDispatcher(23369): dispatchScrollableAreaInfo : windowRect = Rect(0, 0 - 1080, 2400)
D/SmartClipRemoteRequestDispatcher(23369): dispatchScrollableAreaInfo : Scrollable view count = 1
D/SmartClipRemoteRequestDispatcher(23369): dispatchScrollableAreaInfo : Unscrollable view count = 0
D/SmartClipRemoteRequestDispatcher(23369): dispatchScrollableAreaInfo : Pkg=com.example.awaken Activity=null
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 1 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
D/ViewRootImpl@d61098b[MainActivity](23369): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb4000079fb35c4a0}
D/InputMethodManagerUtils(23369): startInputInner - Id : 0
I/InputMethodManager(23369): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.example.awaken.MainActivity
I/InsetsSourceConsumer(23369): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
I/ViewRootImpl@d61098b[MainActivity](23369): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(23369): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(23369): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ViewRootImpl@d61098b[MainActivity](23369): handleAppVisibility mAppVisible = true visible = false
I/ViewRootImpl@d61098b[MainActivity](23369): stopped(true) old = false
D/ViewRootImpl@d61098b[MainActivity](23369): WindowStopped on com.example.awaken/com.example.awaken.MainActivity set to true
D/OpenGLRenderer(23369): CacheManager::trimMemory(20)
D/SurfaceView(23369): 67702900 windowPositionLost, frameNr = 0
I/SurfaceView@e8dde95(23369): aOrMT: ViewRootImpl@d61098b[MainActivity] t = android.view.SurfaceControl$Transaction@897899d fN = 0 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:1696 android.graphics.RenderNode$CompositePositionUpdateListener.positionLost:376 
I/ViewRootImpl@d61098b[MainActivity](23369): mWNT: t=0xb4000078ab33bff0 mBlastBufferQueue=0xb4000078db322e90 fn= 0 mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1598 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:1696 
I/SurfaceView@e8dde95(23369): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
I/SurfaceView(23369): 244178581 Changes: creating=false format=false size=false visible=true alpha=false hint=false visible=true left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView@e8dde95(23369): 244178581 Cur surface: Surface(name=null)/@0x4cdfbe5
I/SurfaceView(23369): 244178581 surfaceDestroyed
I/SurfaceView@e8dde95(23369): surfaceDestroyed callback.size 1 #1 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400}
I/SurfaceView@e8dde95(23369): updateSurface: mVisible = false mSurface.isValid() = true
I/SurfaceView@e8dde95(23369): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
V/SurfaceView@e8dde95(23369): Layout: x=0 y=0 w=1080 h=2400, frame=Rect(0, 0 - 1080, 2400)
D/SurfaceView@e8dde95(23369): updateSurface: surface is not valid
I/SurfaceView@e8dde95(23369): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/SurfaceView@e8dde95(23369): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 G.E...... ......I. 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
D/SurfaceView@e8dde95(23369): updateSurface: surface is not valid
I/SurfaceView@e8dde95(23369): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/ViewRootImpl@d61098b[MainActivity](23369): destroyHardwareResources: Callers=android.view.ViewRootImpl.performTraversals:3932 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 android.view.Choreographer.doCallbacks:1153 android.view.Choreographer.doFrame:1079 android.view.Choreographer$FrameDisplayEventReceiver.run:1646 android.os.Handler.handleCallback:958 android.os.Handler.dispatchMessage:99 
D/OpenGLRenderer(23369): CacheManager::trimMemory(20)
I/ViewRootImpl@d61098b[MainActivity](23369): Relayout returned: old=(0,0,1080,2400) new=(0,0,1080,2400) relayoutAsync=false req=(1080,2400)8 dur=6 res=0x402 s={false 0x0} ch=false seqId=0
D/SurfaceView@e8dde95(23369): updateSurface: surface is not valid
I/SurfaceView@e8dde95(23369): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/OpenGLRenderer(23369): CacheManager::trimMemory(20)
D/InputTransport(23369): Input channel destroyed: 'ClientS', fd=153
D/SurfaceView@e8dde95(23369): updateSurface: surface is not valid
I/SurfaceView@e8dde95(23369): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
Lost connection to device.