D/CCodecConfig(15849): c2 config diff is Dict {
D/CCodecConfig(15849):   c2::u32 coded.bitrate.value = 64000
D/CCodecConfig(15849):   c2::u32 input.buffers.max-size.value = 8192
D/CCodecConfig(15849):   c2::u32 input.delay.value = 0
D/CCodecConfig(15849):   string input.media-type.value = "audio/mpeg"
D/CCodecConfig(15849):   string output.media-type.value = "audio/raw"
D/CCodecConfig(15849):   c2::u32 raw.channel-count.value = 2
D/CCodecConfig(15849):   c2::u32 raw.sample-rate.value = 44100
D/CCodecConfig(15849): }
D/CXCP    (15849): Creating config for IMAGE_ANALYSIS
D/CXCP    (15849): Creating config for PREVIEW
D/CXCP    (15849): Creating config for IMAGE_CAPTURE
D/CXCP    (15849): Creating config for IMAGE_ANALYSIS
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9
D/SupportedOutputSizesCollector(15849): useCaseConfig = androidx.camera.core.impl.PreviewConfig@a2f4f47, candidateSizes = [3264x2448, 3184x2388, 3264x1836, 2448x2448, 3184x1792, 2384x2384, 2640x1980, 2576x1932, 3264x1468, 3184x1432, 1984x1984, 2640x1488, 2640x1188, 2400x1080, 1920x1080, 1440x1080, 1280x960, 1088x1088, 1280x720, 960x960, 960x720, 720x480, 640x480, 352x288, 320x240, 176x144]
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5
D/SupportedOutputSizesCollector(15849): useCaseConfig = androidx.camera.core.impl.ImageCaptureConfig@8369374, candidateSizes = [3264x2448, 3184x2388, 3264x1836, 2448x2448, 3184x1792, 2384x2384, 2640x1980, 2576x1932, 3264x1468, 3184x1432, 1984x1984, 2640x1488, 2640x1188, 2400x1080, 1920x1080, 1440x1080, 1280x960, 1088x1088, 1280x720, 960x960, 960x720, 720x480, 640x480, 352x288, 320x240, 176x144]
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c
D/SupportedOutputSizesCollector(15849): useCaseConfig = androidx.camera.core.impl.ImageAnalysisConfig@fe2509d, candidateSizes = [3264x2448, 3184x2388, 3264x1836, 2448x2448, 3184x1792, 2384x2384, 2640x1980, 2576x1932, 3264x1468, 3184x1432, 1984x1984, 2640x1488, 2640x1188, 2400x1080, 1920x1080, 1440x1080, 1280x960, 1088x1088, 1280x720, 960x960, 960x720, 720x480, 640x480, 352x288, 320x240, 176x144]
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5
I/MediaCodec(15849): MediaCodec will operate in async mode
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c
D/MediaCodec(15849): flushMediametrics
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c
D/CCodec  (15849): [c2.sec.mp3.decoder] buffers are bound to CCodec for this session
I/CCodec  (15849): appPid(15849) width(0) height(0)
D/CCodecConfig(15849): no c2 equivalents for log-session-id
D/CCodecConfig(15849): no c2 equivalents for flags
D/CXCP    (15849): DynamicRangeResolver: Resolved dynamic range for use case androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9 to no compatible HDR dynamic ranges.
D/CXCP    (15849): DynamicRange@98798e3{encoding=UNSPECIFIED, bitDepth=0}
D/CXCP    (15849): ->
D/CXCP    (15849): DynamicRange@e5a5912{encoding=SDR, bitDepth=8}
D/CXCP    (15849): resolvedDynamicRanges = {androidx.camera.core.impl.ImageCaptureConfig@8369374=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, androidx.camera.core.impl.ImageAnalysisConfig@fe2509d=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, androidx.camera.core.impl.PreviewConfig@a2f4f47=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}}
D/CXCP    (15849): getSuggestedStreamSpecifications: isPreviewStabilizationSupported = false, isFeatureComboInvocation = false
D/CCodecConfig(15849): config failed => CORRUPTED
W/Codec2Client(15849): query -- param skipped: index = 1107298332.
D/CXCP    (15849): resolveSpecsByCheckingMethod: checkingMethod = WITHOUT_FEATURE_COMBO
D/CCodec  (15849): client requested max input size 4096, which is smaller than what component recommended (8192); overriding with component recommendation.
W/CCodec  (15849): This behavior is subject to change. It is recommended that app developers double check whether the requested max input size is in reasonable range.
D/CCodec  (15849): encoding statistics level = 0
D/CCodec  (15849): setup formats input: AMessage(what = 0x00000000) = {
D/CCodec  (15849):   int32_t bitrate = 64000
D/CCodec  (15849):   int32_t channel-count = 2
D/CCodec  (15849):   int32_t max-input-size = 8192
D/CCodec  (15849):   string mime = "audio/mpeg"
D/CCodec  (15849):   int32_t sample-rate = 44100
D/CCodec  (15849): }
D/CCodec  (15849): setup formats output: AMessage(what = 0x00000000) = {
D/CCodec  (15849):   int32_t channel-count = 2
D/CCodec  (15849):   string mime = "audio/raw"
D/CCodec  (15849):   int32_t sample-rate = 44100
D/CCodec  (15849):   int32_t android._config-pcm-encoding = 2
D/CCodec  (15849): }
D/CXCP    (15849): resolveSpecsBySettings: featureSettings = FeatureSettings(cameraMode=0, requiredMaxBitDepth=8, hasVideoCapture=false, videoStabilization=UNSPECIFIED, isUltraHdrOn=false, isHighSpeedOn=false, isFeatureComboInvocation=false, requiresFeatureComboQuery=false, targetFpsRange=[0, 0], isStrictFpsRequired=false)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(STARTING)
D/CameraQuirks(15849): camera2 CameraQuirks = CloseCaptureSessionOnVideoQuirk | FinalizeSessionOnCloseQuirk
D/CameraQuirks(15849): camera2 CameraQuirks = CloseCaptureSessionOnVideoQuirk | FinalizeSessionOnCloseQuirk
D/CameraQuirks(15849): camera2 CameraQuirks = CloseCaptureSessionOnVideoQuirk | FinalizeSessionOnCloseQuirk
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
D/C2Store (15849): Using ION
D/CXCP    (15849): resolveSpecsBySettings: bestSizesAndFps = BestSizesAndMaxFpsForConfigs(bestSizes=[720x480, 720x480, 720x480], bestSizesForStreamUseCase=null, maxFpsForBestSizes=30, maxFpsForStreamUseCase=2147483647, maxFpsForAllSizes=2147483647)
W/CXCP    (15849): Detaching [] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>> (Ignored)
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9
D/Preview (15849): onSuggestedStreamSpecUpdated: primaryStreamSpec = StreamSpec{resolution=720x480, originalConfiguredResolution=720x480, dynamicRange=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, sessionType=0, expectedFrameRateRange=[0, 0], implementationOptions=androidx.camera.camera2.impl.Camera2ImplConfig@ebd415b, zslDisabled=false}, secondaryStreamSpec null
D/DeferrableSurface(15849): Surface created[total_surfaces=1, used_surfaces=0](androidx.camera.core.processing.SurfaceEdge$SettableSurface@7e0bdf8}
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] Created input block pool with allocatorID 16 => poolID 17 - OK (0)
D/DeferrableSurface(15849): Surface created[total_surfaces=2, used_surfaces=0](androidx.camera.core.SurfaceRequest$2@e5fc1a4}
D/DeferrableSurface(15849): New surface in use[total_surfaces=2, used_surfaces=1](androidx.camera.core.SurfaceRequest$2@e5fc1a4}
D/DeferrableSurface(15849): use count+1, useCount=1 androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5
D/ImageCapture(15849): onSuggestedStreamSpecUpdated: primaryStreamSpec = StreamSpec{resolution=720x480, originalConfiguredResolution=720x480, dynamicRange=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, sessionType=0, expectedFrameRateRange=[0, 0], implementationOptions=androidx.camera.camera2.impl.Camera2ImplConfig@d15db09, zslDisabled=false}, secondaryStreamSpec null
D/ImageCapture(15849): createPipeline(cameraId: 1, streamSpec: StreamSpec{resolution=720x480, originalConfiguredResolution=720x480, dynamicRange=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, sessionType=0, expectedFrameRateRange=[0, 0], implementationOptions=androidx.camera.camera2.impl.Camera2ImplConfig@d15db09, zslDisabled=false})
D/CompatibilityChangeReporter(15849): Compat change id reported: 236825255; UID 10653; state: ENABLED
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] Created output block pool with allocatorID 16 => poolID 35 - OK
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] Configured output block pool ids 35 => OK
D/DeferrableSurface(15849): Surface created[total_surfaces=3, used_surfaces=1](androidx.camera.core.impl.ImmediateSurface@d01310e}
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/UseCase (15849): applyFeaturesToConfig: mFeatureGroup = null, this = ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
D/ImageAnalysis(15849): onSuggestedStreamSpecUpdated: primaryStreamSpec = StreamSpec{resolution=720x480, originalConfiguredResolution=720x480, dynamicRange=DynamicRange@e5a5912{encoding=SDR, bitDepth=8}, sessionType=0, expectedFrameRateRange=[0, 0], implementationOptions=androidx.camera.camera2.impl.Camera2ImplConfig@7b7a13c, zslDisabled=false}, secondaryStreamSpec null
D/DeferrableSurface(15849): Surface created[total_surfaces=4, used_surfaces=1](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/CXCP    (15849): Attaching [Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9, ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5, ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>>
D/CXCP    (15849): Prepared UseCaseGraphContext (Deferred)
D/CXCP    (15849): Configured UseCaseCamera-1
D/CXCP    (15849): populateSurfaceToStreamUseCaseMapping() - streamUseCaseMap = {}
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = androidx.camera.camera2.impl.DeferredUseCaseCameraRequestControl@608dbd4
W/CXCP    (15849): Expected stream use case for androidx.camera.core.SurfaceRequest$2@e5fc1a4, null cannot be set!
D/CXCP    (15849): Notifying [] camera control ready
D/ImageCapture(15849): onCameraControlReady
W/CXCP    (15849): Expected stream use case for androidx.camera.core.impl.ImmediateSurface@d01310e, null cannot be set!
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = androidx.camera.camera2.impl.DeferredUseCaseCameraRequestControl@608dbd4
W/CXCP    (15849): Expected stream use case for androidx.camera.core.impl.ImmediateSurface@cb81ec5, null cannot be set!
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/CameraManager(15849): registerAvailabilityCallback: Is device callback = false
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 0 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 2 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 3 status STATUS_PRESENT
D/CXCP    (15849): Camera 1 has become available
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraAvailable(camera=CameraId-1)
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STOPPED@24dbd46, last camera error = null, camera availability = CameraAvailable(camera=CameraId-1), last camera priorities changed = null, current timestamp = TimestampNs(value=163286350020005).
I/CXCP    (15849): CameraGraph-1 (Camera 1)
I/CXCP    (15849):   Facing:    Front (Physical, Limited)
I/CXCP    (15849):   Mode:      Normal
I/CXCP    (15849): Outputs:
I/CXCP    (15849):   Stream-1    Output-1    720x480     PRIVATE          [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849):   Stream-2    Output-2    720x480     JPEG             [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849):   Stream-3    Output-3    720x480     YUV_420_888      [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849): Session Template: TEMPLATE_PREVIEW
I/CXCP    (15849): Session Parameters: (None)
I/CXCP    (15849): Default Template: TEMPLATE_PREVIEW
I/CXCP    (15849): Default Parameters
I/CXCP    (15849):   Metadata.Key(androidx.camera.camera2.pipe.captureRequestTag) android.hardware.camera2.CaptureRequest.setTag.CX
I/CXCP    (15849): Required Parameters: (None)
D/CXCP    (15849): Camera graph updated from null to CameraGraph-1
I/CXCP    (15849): Starting CameraGraph-1
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-1) onGraphStarting
D/CXCP    (15849): CameraGraph-1 state updated to GRAPH_STARTING
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=OPENING, error=null)
D/CXCP    (15849): PruningProcessingQueue: Pruning [RequestOpen(virtualCamera=VirtualCamera-1, sharedCameraIds=[], graphListener=GraphProcessor(cameraGraph: CameraGraph-1), isPrewarm=false, isForegroundObserver=androidx.camera.camera2.pipe.compat.Camera2CameraController$$ExternalSyntheticLambda4@4e91b07)]
D/CXCP    (15849): PruningProcessingQueue: Processing RequestOpen(virtualCamera=VirtualCamera-1, sharedCameraIds=[], graphListener=GraphProcessor(cameraGraph: CameraGraph-1), isPrewarm=false, isForegroundObserver=androidx.camera.camera2.pipe.compat.Camera2CameraController$$ExternalSyntheticLambda4@4e91b07)
I/CXCP    (15849): PruningCamera2DeviceManager#processRequestOpen(CameraId-1)
D/CXCP    (15849): Opening CameraId-1 with retries...
D/CXCP    (15849): Started Camera2CameraController(CameraGraph-1)
I/CXCP    (15849): Opening CameraId-1
D/CXCP    (15849): Setting up Surfaces with UseCaseSurfaceManager
I/CameraManager(15849): registerAvailabilityCallback: Is device callback = false
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 0 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 2 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 3 status STATUS_PRESENT
D/CXCP    (15849): CameraId-1 has become available! Notifying listeners...
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/DeferrableSurface(15849): New surface in use[total_surfaces=4, used_surfaces=2](androidx.camera.core.impl.ImmediateSurface@d01310e}
D/DeferrableSurface(15849): use count+1, useCount=1 androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): New surface in use[total_surfaces=4, used_surfaces=3](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/DeferrableSurface(15849): use count+1, useCount=1 androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/CXCP    (15849): Configured androidx.camera.camera2.impl.UseCaseCameraRequestControlImpl@9c1411b
D/CXCP    (15849): Configured Surface(name=null)/@0xfe991e9 for Stream-1
D/CXCP    (15849): UseCaseCameraRequestControlImpl#setParametersAsync: [DEFAULT] values = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, optionPriority = OPTIONAL
I/CXCP    (15849): Configured Stream-1 with Surface(name=null)/@0xfe991e9
D/CXCP    (15849): SurfaceActive androidx.camera.core.SurfaceRequest$2@e5fc1a4 in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count+1, useCount=3 androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/CXCP    (15849): Configured Surface(name=null)/@0xf0122b8 for Stream-2
I/CXCP    (15849): Configured Stream-2 with Surface(name=null)/@0xf0122b8
D/CXCP    (15849): SurfaceActive androidx.camera.core.impl.ImmediateSurface@d01310e in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.impl.ImmediateSurface@d01310e
D/CXCP    (15849): Configured Surface(name=null)/@0xe600891 for Stream-3
I/CXCP    (15849): Configured Stream-3 with Surface(name=null)/@0xe600891
D/CXCP    (15849): SurfaceActive androidx.camera.core.impl.ImmediateSurface@cb81ec5 in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.impl.ImmediateSurface@cb81ec5
I/CXCP    (15849): Surface setup complete
D/DeferrableSurface(15849): use count-1,  useCount=2 closed=false androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_OPENING for client com.example.awaken API Level 2 User Id 0
D/CXCP    (15849): UseCaseCameraRequestControlImpl#removeParametersAsync: [DEFAULT] keys = [CaptureRequest.Key(android.control.zoomRatio), CaptureRequest.Key(android.control.settingsOverride)]
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): UseCaseCameraRequestControlImpl#updateCamera2ConfigAsync
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [Stream-1], template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-1], template=RequestTemplate(value=1))@4404aef
D/CXCP    (15849): State3AControl.getFinalPreferredAeMode: preferAeMode = 1
D/CXCP    (15849): UseCaseCameraRequestControlImpl#setParametersAsync: [DEFAULT] values = {CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1}, optionPriority = OPTIONAL
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-1], template=RequestTemplate(value=1))@a0ee9fc
D/CXCP    (15849): UseCaseCameraState: Updating 3A modes: AE(AeMode(value=1), changed=true), AF(AfMode(value=0), changed=true), AWB(AwbMode(value=1), changed=true)
D/CXCP    (15849): Controller3A#update3A: cancelling previous request null
D/CXCP    (15849): UseCaseCameraRequestControlImpl#updateCamera2ConfigAsync
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-1], template=RequestTemplate(value=1))@633a6da
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [Stream-1, Stream-3], template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-1, Stream-3], template=RequestTemplate(value=1))@b5ea9e8
W/.example.awaken(15849): Accessing hidden method Landroid/media/AudioTrack;->getLatency()I (unsupported, reflection, allowed)
D/AudioTrack(15849): setVolume(1.000000, 1.000000) pid : 15849
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
D/CXCP    (15849): Camera 1 has become unavailable
I/CXCP    (15849): Unavailable camera 1 detected
I/CXCP    (15849): Loaded CameraIdList [CameraId-0, CameraId-1, CameraId-2, CameraId-3]
D/CXCP    (15849): Emitting camera ID list: [CameraId-0, CameraId-1, CameraId-2, CameraId-3]
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraUnavailable(camera=CameraId-1)
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = null, current timestamp = TimestampNs(value=163286508251984).
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_OPEN for client com.example.awaken API Level 2 User Id 0
I/CXCP    (15849): Opened CameraId-1 in 159.865 ms
D/CXCP    (15849): tryOpenCamera: openCamera() for CameraId-1 returned
D/CXCP    (15849): tryOpenCamera: CameraId-1 opened
I/CXCP    (15849): Camera open completed: OpenCameraResult(cameraState=CameraState-1, errorCode=null)
I/CXCP    (15849): PruningCameraDeviceManager: CameraId-1 opened successfully
I/CXCP    (15849): Creating CameraCaptureSession from CameraId-1 using CaptureSessionState-1 with {Stream-1=Surface(name=null)/@0xfe991e9, Stream-2=Surface(name=null)/@0xf0122b8, Stream-3=Surface(name=null)/@0xe600891}
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
D/AudioTrack(15849): setVolume(1.000000, 1.000000) pid : 15849
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
D/CXCP    (15849): CXCP#createCaptureSession-1 - 613.029 ms
W/.example.awaken(15849): Long monitor contention with owner CXCP-05 (19864) at void android.hardware.camera2.impl.CameraDeviceImpl.waitUntilIdle()(CameraDeviceImpl.java:1420) waiters=0 in void android.hardware.camera2.impl.CameraDeviceImpl$4.run() for 598ms
D/CXCP    (15849): CaptureSessionState-1 Configured
I/CXCP    (15849): Configured CaptureSessionState-1 in 621.903 ms
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-1) onGraphStarted
D/CXCP    (15849): CameraGraph-1 state updated to GRAPH_STARTED
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=OPEN, error=null)
D/CXCP    (15849): CaptureSessionState-1 Ready
D/CXCP    (15849): Building CaptureRequest for Request(streams=[Stream-1, Stream-3], template=RequestTemplate(value=1))@b5ea9e8
D/CXCP    (15849): CXCP#createCaptureRequest-1 - 0.515 ms
D/CXCP    (15849): GraphRequestProcessor-1 submitting Camera2CaptureSequence-1
D/CXCP    (15849): CaptureSessionState-1 Active
D/CXCP    (15849): CXCP#setRepeatingRequest-1 - 3.503 ms
D/CXCP    (15849): GraphRequestProcessor-1 submitted Camera2CaptureSequence-1
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_ACTIVE for client com.example.awaken API Level 2 User Id 0
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/ViewRootImpl@d61098b[MainActivity](15849): onDisplayChanged oldDisplayState=2 newDisplayState=2
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
I/Mp3Extractor(15849): Data size mismatch between stream (102131) and Xing frame (102003), using Xing value.
D/nativeloader(15849): Load /data/app/~~ZfYNhK4DkQWf2Ktq42LKMg==/com.example.awaken-bXThYhu4brDBVyp6li2chg==/base.apk!/lib/arm64-v8a/libimage_processing_util_jni.so using ns clns-4 from class loader (caller=/data/app/~~ZfYNhK4DkQWf2Ktq42LKMg==/com.example.awaken-bXThYhu4brDBVyp6li2chg==/base.apk): ok
W/LibraryVersion(15849): Failed to get app version for libraryName: shared-installation-id
W/LibraryVersion(15849): Failed to get app version for libraryName: shared-remote-config
D/MLKit RemoteConfigRestC(15849): Loaded cached remote config.
I/PoseTaskWithRes(15849): vision_pose_detection_enable_acceleration = true
I/PoseTaskWithRes(15849): vision_pose_detection_enable_acceleration_gpu = true
D/MLKit RemoteConfigRestC(15849): Got remote config.
I/.example.awaken(15849): Background young concurrent copying GC freed 890KB AllocSpace bytes, 40(13MB) LOS objects, 7% free, 23MB/26MB, paused 4.735ms,1.223ms total 101.998ms
I/.example.awaken(15849): Background concurrent copying GC freed 963KB AllocSpace bytes, 74(24MB) LOS objects, 49% free, 21MB/42MB, paused 991us,199us total 162.725ms
D/CompatibilityChangeReporter(15849): Compat change id reported: 247079863; UID 10653; state: ENABLED
I/PoseTaskWithRes(15849): graphVariant = 
D/nativeloader(15849): Load /data/app/~~ZfYNhK4DkQWf2Ktq42LKMg==/com.example.awaken-bXThYhu4brDBVyp6li2chg==/base.apk!/lib/arm64-v8a/libxeno_native.so using ns clns-4 from class loader (caller=/data/app/~~ZfYNhK4DkQWf2Ktq42LKMg==/com.example.awaken-bXThYhu4brDBVyp6li2chg==/base.apk!classes24.dex): ok
I/native  (15849): I0000 00:00:1783942857.637739   20028 register_natives.cc:68] Skipping registration and clearing exception. Class or native methods not found, may be unused and/or trimmed by Proguard.
I/native  (15849): I0000 00:00:1783942857.639632   20028 asset_manager_util.cc:61] Created global reference to asset manager.
W/.example.awaken(15849): Accessing hidden method Ldalvik/system/VMStack;->getStackClass2()Ljava/lang/Class; (unsupported, reflection, allowed)
I/native  (15849): I0000 00:00:1783942857.699385   20028 graph.cc:502] Start running the graph, waiting for inputs.
I/native  (15849): I0000 00:00:1783942857.699525   20028 gl_context_egl.cc:86] Successfully initialized EGL. Major : 1 Minor: 5
I/native  (15849): I0000 00:00:1783942857.709205   20040 gl_context.cc:374] GL version: 3.2 (OpenGL ES 3.2 V@0530.55.1 (GIT@9ad1b67875, Ib48d2dada6, 1746950435) (Date:05/11/25)), renderer: Adreno (TM) 642L
I/native  (15849): I0000 00:00:1783942857.757481   20033 resource_util_android.cc:82] Successfully loaded: mlkit_pose/pose_person_detector_f16.tflite
W/libc    (15849): Access denied finding property "ro.mediatek.platform"
I/tflite  (15849): Created TensorFlow Lite XNNPACK delegate for CPU.
I/tflite  (15849): Initialized TensorFlow Lite runtime.
I/tflite  (15849): Replacing 291 out of 291 node(s) with delegate (TfLiteXNNPackDelegate) node, yielding 1 partitions for the whole graph.
W/native  (15849): W0000 00:00:1783942857.971066   20033 inference_feedback_manager.cc:121] Feedback manager requires a model with a single signature inference. Disabling support for feedback tensors.
I/native  (15849): I0000 00:00:1783942858.023003   20036 resource_util_android.cc:82] Successfully loaded: mlkit_pose/pose_landmark_detector_lite_f16_inf.tflite
I/tflite  (15849): Replacing 283 out of 283 node(s) with delegate (TfLiteXNNPackDelegate) node, yielding 1 partitions for the whole graph.
W/native  (15849): W0000 00:00:1783942858.065991   20036 inference_feedback_manager.cc:121] Feedback manager requires a model with a single signature inference. Disabling support for feedback tensors.
I/.example.awaken(15849): NativeAlloc concurrent copying GC freed 523KB AllocSpace bytes, 80(28MB) LOS objects, 49% free, 21MB/42MB, paused 1.429ms,166us total 157.031ms
W/native  (15849): W0000 00:00:1783942858.283290   20039 landmark_projection_calculator.cc:189] Using NORM_RECT without IMAGE_DIMENSIONS is only supported for the square ROI. Provide IMAGE_DIMENSIONS or use PROJECTION_MATRIX.
I/native  (15849): I0000 00:00:1783942858.283939   20039 jni_util.cc:41] GetEnv: not attached
I/native  (15849): I0000 00:00:1783942858.477316   20035 jni_util.cc:41] GetEnv: not attached
I/native  (15849): I0000 00:00:1783942858.600969   20036 jni_util.cc:41] GetEnv: not attached
I/native  (15849): I0000 00:00:1783942858.751943   20033 jni_util.cc:41] GetEnv: not attached
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/InsetsSourceConsumer(15849): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
I/native  (15849): I0000 00:00:1783942859.898064   20037 jni_util.cc:41] GetEnv: not attached
I/native  (15849): I0000 00:00:1783942860.159948   20038 jni_util.cc:41] GetEnv: not attached
I/.example.awaken(15849): Background concurrent copying GC freed 492KB AllocSpace bytes, 80(29MB) LOS objects, 49% free, 22MB/45MB, paused 3.294ms,67us total 145.550ms
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 216/221 (recycle/alloc) - 6/432 (fetch/transfer)
I/.example.awaken(15849): Background concurrent copying GC freed 607KB AllocSpace bytes, 96(34MB) LOS objects, 48% free, 25MB/49MB, paused 285us,372us total 220.183ms
I/native  (15849): I0000 00:00:1783942862.328274   20034 jni_util.cc:41] GetEnv: not attached
I/.example.awaken(15849): Background concurrent copying GC freed 792KB AllocSpace bytes, 107(41MB) LOS objects, 49% free, 23MB/47MB, paused 113us,207us total 160.048ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background concurrent copying GC freed 493KB AllocSpace bytes, 94(35MB) LOS objects, 49% free, 20MB/40MB, paused 124us,428us total 127.172ms
I/.example.awaken(15849): Background concurrent copying GC freed 608KB AllocSpace bytes, 74(27MB) LOS objects, 48% free, 25MB/49MB, paused 90us,63us total 149.888ms
I/.example.awaken(15849): Background young concurrent copying GC freed 512KB AllocSpace bytes, 97(34MB) LOS objects, 52% free, 21MB/45MB, paused 305us,142us total 102.024ms
I/.example.awaken(15849): Background concurrent copying GC freed 751KB AllocSpace bytes, 101(37MB) LOS objects, 49% free, 14MB/29MB, paused 3.244ms,544us total 129.870ms
I/.example.awaken(15849): Background young concurrent copying GC freed 470KB AllocSpace bytes, 67(24MB) LOS objects, 43% free, 22MB/40MB, paused 6.804ms,71us total 126.332ms
I/.example.awaken(15849): Background concurrent copying GC freed 538KB AllocSpace bytes, 81(30MB) LOS objects, 47% free, 26MB/50MB, paused 8.950ms,71us total 107.741ms
I/native  (15849): I0000 00:00:1783942865.566513   20032 jni_util.cc:41] GetEnv: not attached
I/.example.awaken(15849): Background concurrent copying GC freed 579KB AllocSpace bytes, 108(39MB) LOS objects, 49% free, 20MB/41MB, paused 294us,431us total 141.859ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background young concurrent copying GC freed 517KB AllocSpace bytes, 84(31MB) LOS objects, 25% free, 30MB/41MB, paused 387us,72us total 119.737ms
I/.example.awaken(15849): Background concurrent copying GC freed 617KB AllocSpace bytes, 80(28MB) LOS objects, 43% free, 31MB/55MB, paused 75us,60us total 139.522ms
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 4(32768 size) used buffers - 432/437 (recycle/alloc) - 8/839 (fetch/transfer)
I/.example.awaken(15849): Background concurrent copying GC freed 672KB AllocSpace bytes, 128(46MB) LOS objects, 49% free, 20MB/40MB, paused 1.079ms,56us total 146.848ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 638/643 (recycle/alloc) - 9/1252 (fetch/transfer)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background concurrent copying GC freed 562KB AllocSpace bytes, 85(30MB) LOS objects, 47% free, 26MB/50MB, paused 215us,2.877ms total 145.110ms
I/.example.awaken(15849): Background young concurrent copying GC freed 560KB AllocSpace bytes, 96(34MB) LOS objects, 33% free, 33MB/50MB, paused 432us,166us total 138.625ms
W/.example.awaken(15849): Weak pointer dereference blocked for 12 milliseconds.
I/.example.awaken(15849): Background concurrent copying GC freed 749KB AllocSpace bytes, 170(63MB) LOS objects, 49% free, 19MB/39MB, paused 594us,65us total 267.021ms
I/.example.awaken(15849): Background young concurrent copying GC freed 598KB AllocSpace bytes, 67(24MB) LOS objects, 0% free, 50MB/50MB, paused 287us,78us total 266.616ms
I/.example.awaken(15849): Background concurrent copying GC freed 561KB AllocSpace bytes, 99(36MB) LOS objects, 49% free, 16MB/32MB, paused 199us,142us total 121.157ms
I/.example.awaken(15849): Background concurrent copying GC freed 424KB AllocSpace bytes, 84(30MB) LOS objects, 49% free, 15MB/30MB, paused 200us,64us total 130.803ms
I/.example.awaken(15849): Background concurrent copying GC freed 464KB AllocSpace bytes, 55(21MB) LOS objects, 49% free, 19MB/39MB, paused 230us,145us total 144.328ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background concurrent copying GC freed 598KB AllocSpace bytes, 70(26MB) LOS objects, 48% free, 25MB/49MB, paused 228us,62us total 119.264ms
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 853/858 (recycle/alloc) - 11/1668 (fetch/transfer)
I/.example.awaken(15849): Background concurrent copying GC freed 536KB AllocSpace bytes, 87(33MB) LOS objects, 50% free, 18MB/37MB, paused 113us,1.572ms total 114.648ms
I/.example.awaken(15849): Background concurrent copying GC freed 669KB AllocSpace bytes, 71(27MB) LOS objects, 47% free, 26MB/50MB, paused 841us,90us total 136.518ms
I/.example.awaken(15849): Background concurrent copying GC freed 612KB AllocSpace bytes, 98(36MB) LOS objects, 46% free, 27MB/51MB, paused 435us,131us total 165.528ms
I/.example.awaken(15849): Background concurrent copying GC freed 615KB AllocSpace bytes, 113(42MB) LOS objects, 49% free, 23MB/46MB, paused 66us,55us total 211.166ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background concurrent copying GC freed 522KB AllocSpace bytes, 90(33MB) LOS objects, 50% free, 22MB/44MB, paused 406us,85us total 141.754ms
I/.example.awaken(15849): Background concurrent copying GC freed 941KB AllocSpace bytes, 110(43MB) LOS objects, 49% free, 20MB/40MB, paused 145us,63us total 149.420ms
I/.example.awaken(15849): Background young concurrent copying GC freed 468KB AllocSpace bytes, 65(23MB) LOS objects, 46% free, 21MB/40MB, paused 948us,111us total 106.581ms
I/.example.awaken(15849): Background concurrent copying GC freed 656KB AllocSpace bytes, 88(32MB) LOS objects, 50% free, 19MB/39MB, paused 836us,69us total 111.592ms
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163311673890151), current timestamp = TimestampNs(value=163311673911141).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163311680484318), current timestamp = TimestampNs(value=163311680499422).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163311681866245), current timestamp = TimestampNs(value=163311681877287).
I/.example.awaken(15849): Background young concurrent copying GC freed 545KB AllocSpace bytes, 65(23MB) LOS objects, 48% free, 20MB/39MB, paused 268us,1.344ms total 171.407ms
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163311868340464), current timestamp = TimestampNs(value=163311868345985).
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163311873469631), current timestamp = TimestampNs(value=163311873475256).
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163312216418589), current timestamp = TimestampNs(value=163312216430360).
I/ViewRootImpl@d61098b[MainActivity](15849): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(15849): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163312360226453), current timestamp = TimestampNs(value=163312360231922).
I/ImeFocusController(15849): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ViewRootImpl@d61098b[MainActivity](15849): onDisplayChanged oldDisplayState=2 newDisplayState=2
I/ViewRootImpl@d61098b[MainActivity](15849): handleAppVisibility mAppVisible = true visible = false
I/SurfaceView@e8dde95(15849): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
I/SurfaceView(15849): 244178581 Changes: creating=false format=false size=false visible=true alpha=false hint=false visible=true left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView@e8dde95(15849): 244178581 Cur surface: Surface(name=null)/@0x69236ba
I/SurfaceView(15849): 244178581 surfaceDestroyed
I/SurfaceView@e8dde95(15849): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400}
I/SurfaceView@e8dde95(15849): updateSurface: mVisible = false mSurface.isValid() = true
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
V/SurfaceView@e8dde95(15849): Layout: x=0 y=0 w=1080 h=2400, frame=Rect(0, 0 - 1080, 2400)
I/ViewRootImpl@d61098b[MainActivity](15849): destroyHardwareResources: Callers=android.view.ViewRootImpl.performTraversals:3932 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 android.view.Choreographer.doCallbacks:1153 android.view.Choreographer.doFrame:1079 android.view.Choreographer$FrameDisplayEventReceiver.run:1646 android.os.Handler.handleCallback:958 android.os.Handler.dispatchMessage:99 
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 1062/1067 (recycle/alloc) - 12/2083 (fetch/transfer)
D/SurfaceView(15849): 21781337 windowPositionLost, frameNr = 0
D/OpenGLRenderer(15849): CacheManager::trimMemory(20)
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
I/.example.awaken(15849): Background concurrent copying GC freed 770KB AllocSpace bytes, 69(26MB) LOS objects, 49% free, 17MB/35MB, paused 105us,60us total 414.359ms
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163313012904265), current timestamp = TimestampNs(value=163313012934370).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163313015585307), current timestamp = TimestampNs(value=163313015616974).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163313026557963), current timestamp = TimestampNs(value=163313026575984).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163313029456661), current timestamp = TimestampNs(value=163313029506870).
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-1): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163313034966140), current timestamp = TimestampNs(value=163313034982182).
I/ViewRootImpl@d61098b[MainActivity](15849): Relayout returned: old=(0,0,1080,2400) new=(0,0,1080,2400) relayoutAsync=false req=(1080,2400)8 dur=18 res=0x402 s={false 0x0} ch=true seqId=0
I/SurfaceView@e8dde95(15849): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/OpenGLRenderer(15849): CacheManager::trimMemory(40)
D/OpenGLRenderer(15849): RenderThread::destroyRenderingContext()
I/Choreographer(15849): Skipped 68 frames!  The application may be doing too much work on its main thread.
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/InputTransport(15849): Input channel destroyed: 'ClientS', fd=157
D/CXCP    (15849): Detaching [Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9, ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5, ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>>
W/ScreenFlashWrapper(15849): completePendingScreenFlashClear: none pending!
D/CXCP    (15849): UseCaseCameraRequestControl: closed
D/CXCP    (15849): Closing UseCaseCamera-1
I/CXCP    (15849): Closing CameraGraph-1
D/CXCP    (15849): Closing GraphRequestProcessor-1
D/CXCP    (15849): Closed Camera2CameraController(CameraGraph-1)
D/CXCP    (15849): Closing GraphRequestProcessor-1
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-1) onGraphStopping
D/CXCP    (15849): CameraGraph-1 state updated to GRAPH_STOPPING
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=CLOSING, error=null)
D/CXCP    (15849): CaptureSessionState-1 Shutdown
D/CXCP    (15849): reset: videoUsage = 0
D/CXCP    (15849): LowLightBoostControl#setLowLightBoostAsync: lowLightBoost = false
D/CXCP    (15849): Camera2CaptureSequenceProcessor-1#stopRepeating
D/CXCP    (15849): CXCP#stopRepeating-1 - 8.890 ms
D/CXCP    (15849): Camera2CaptureSequenceProcessor-1#abortCaptures
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = null
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = null
I/ViewRootImpl@d61098b[MainActivity](15849): stopped(true) old = false
D/ViewRootImpl@d61098b[MainActivity](15849): WindowStopped on com.example.awaken/com.example.awaken.MainActivity set to true
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_IDLE for client com.example.awaken API Level 2 User Id 0
D/CXCP    (15849): CXCP#abortCaptures-1 - 151.428 ms
W/.example.awaken(15849): Long monitor contention with owner CXCP-BG-03 (19882) at void android.hardware.camera2.impl.CameraDeviceImpl.flush()(CameraDeviceImpl.java:1445) waiters=0 in void android.hardware.camera2.impl.CameraDeviceImpl$4.run() for 146ms
D/CXCP    (15849): Closing capture session for CaptureSessionState-1
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-1) onGraphStopped
D/CXCP    (15849): CameraGraph-1 state updated to GRAPH_STOPPED
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=CLOSED, error=null)
I/CXCP    (15849): Disconnecting VirtualCamera-1
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) is closed
D/CXCP    (15849): Camera2CameraController(CameraGraph-1) finalized
D/CXCP    (15849): CaptureSessionState-1 Closed
D/CXCP    (15849): CaptureSessionState-1 session finalizing
D/CXCP    (15849): Finalizing CaptureSessionState-1
D/CXCP    (15849): SurfaceInactive androidx.camera.core.SurfaceRequest$2@e5fc1a4 in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/CXCP    (15849): SurfaceInactive androidx.camera.core.impl.ImmediateSurface@d01310e in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count-1,  useCount=0 closed=false androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): Surface no longer in use[total_surfaces=4, used_surfaces=2](androidx.camera.core.impl.ImmediateSurface@d01310e}
D/CXCP    (15849): SurfaceInactive androidx.camera.core.impl.ImmediateSurface@cb81ec5 in androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6
D/DeferrableSurface(15849): use count-1,  useCount=0 closed=false androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/DeferrableSurface(15849): Surface no longer in use[total_surfaces=4, used_surfaces=1](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/CXCP    (15849): androidx.camera.camera2.impl.UseCaseSurfaceManager@2a603f6 remove surface listener
D/CXCP    (15849): CaptureSessionState-1 Ready
I/Choreographer(15849): Skipped 71 frames!  The application may be doing too much work on its main thread.
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/CXCP    (15849): PruningProcessingQueue: Pruning [RequestClose(activeCamera=ActiveCamera(cameraId=CameraId-1)@5ea533d)]
D/CXCP    (15849): PruningProcessingQueue: Processing RequestClose(activeCamera=ActiveCamera(cameraId=CameraId-1)@5ea533d)
I/CXCP    (15849): PruningCamera2DeviceManager#processRequestClose(CameraId-1)
D/CXCP    (15849): handleQuirksBeforeClosing(android.hardware.camera2.impl.CameraDeviceImpl@7e1a73d)
D/CXCP    (15849): CaptureSessionState-1 session disconnecting
D/CXCP    (15849): closeCameraDevice(1)
I/CXCP    (15849): Closing Camera 1
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_PRESENT
D/CXCP    (15849): Emitting camera ID list: [CameraId-0, CameraId-1, CameraId-2, CameraId-3]
D/CXCP    (15849): CXCP#CameraDevice-1#close - 181.475 ms
D/CXCP    (15849): CameraId-1: onClosed
D/CXCP    (15849): CameraState-1: onFinalized
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_CLOSED for client com.example.awaken API Level 2 User Id 0
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 1276/1281 (recycle/alloc) - 14/2492 (fetch/transfer)
I/ViewRootImpl@d61098b[MainActivity](15849): handleAppVisibility mAppVisible = false visible = true
I/ViewRootImpl@d61098b[MainActivity](15849): stopped(false) old = true
D/ViewRootImpl@d61098b[MainActivity](15849): WindowStopped on com.example.awaken/com.example.awaken.MainActivity set to false
D/CXCP    (15849): Attaching [Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9, ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5, ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>>
D/CXCP    (15849): Prepared UseCaseGraphContext (Deferred)
D/CXCP    (15849): Configured UseCaseCamera-2
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = androidx.camera.camera2.impl.DeferredUseCaseCameraRequestControl@def6e2c
D/CXCP    (15849): Notifying [] camera control ready
D/ImageCapture(15849): onCameraControlReady
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = androidx.camera.camera2.impl.DeferredUseCaseCameraRequestControl@def6e2c
D/CXCP    (15849): populateSurfaceToStreamUseCaseMapping() - streamUseCaseMap = {}
W/CXCP    (15849): Expected stream use case for androidx.camera.core.SurfaceRequest$2@e5fc1a4, null cannot be set!
W/CXCP    (15849): Expected stream use case for androidx.camera.core.impl.ImmediateSurface@d01310e, null cannot be set!
W/CXCP    (15849): Expected stream use case for androidx.camera.core.impl.ImmediateSurface@cb81ec5, null cannot be set!
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/SurfaceView@e8dde95(15849): onWindowVisibilityChanged(0) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/FlutterJNI(15849): Sending viewport metrics to the engine.
I/CameraManager(15849): registerAvailabilityCallback: Is device callback = false
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 0 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 2 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 3 status STATUS_PRESENT
D/CXCP    (15849): Camera 1 has become available
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraAvailable(camera=CameraId-1)
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STOPPED@24dbd46, last camera error = null, camera availability = CameraAvailable(camera=CameraId-1), last camera priorities changed = null, current timestamp = TimestampNs(value=163318552344628).
D/CXCP    (15849): Camera access priorities have changed
I/InsetsSourceConsumer(15849): applyRequestedVisibilityToControl: visible=true, type=navigationBars, host=com.example.awaken/com.example.awaken.MainActivity
I/InsetsSourceConsumer(15849): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STOPPED@24dbd46, last camera error = null, camera availability = CameraAvailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163318560993899), current timestamp = TimestampNs(value=163318561009263).
I/CXCP    (15849): CameraGraph-2 (Camera 1)
I/CXCP    (15849):   Facing:    Front (Physical, Limited)
I/CXCP    (15849):   Mode:      Normal
I/CXCP    (15849): Outputs:
I/CXCP    (15849):   Stream-4    Output-4    720x480     PRIVATE          [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849):   Stream-5    Output-5    720x480     JPEG             [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849):   Stream-6    Output-6    720x480     YUV_420_888      [DynamicRangeProfile(value=1)] [StreamUseHint(value=0)]
I/CXCP    (15849): Session Template: TEMPLATE_PREVIEW
I/CXCP    (15849): Session Parameters: (None)
I/CXCP    (15849): Default Template: TEMPLATE_PREVIEW
I/CXCP    (15849): Default Parameters
I/CXCP    (15849):   Metadata.Key(androidx.camera.camera2.pipe.captureRequestTag) android.hardware.camera2.CaptureRequest.setTag.CX
I/CXCP    (15849): Required Parameters: (None)
D/CXCP    (15849): Camera graph updated from CameraGraph-1 to CameraGraph-2
I/CXCP    (15849): Starting CameraGraph-2
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-2) onGraphStarting
D/CXCP    (15849): CameraGraph-2 state updated to GRAPH_STARTING
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=OPENING, error=null)
D/CXCP    (15849): Started Camera2CameraController(CameraGraph-2)
D/CXCP    (15849): PruningProcessingQueue: Pruning [RequestOpen(virtualCamera=VirtualCamera-2, sharedCameraIds=[], graphListener=GraphProcessor(cameraGraph: CameraGraph-2), isPrewarm=false, isForegroundObserver=androidx.camera.camera2.pipe.compat.Camera2CameraController$$ExternalSyntheticLambda4@dff9165)]
D/CXCP    (15849): Setting up Surfaces with UseCaseSurfaceManager
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/DeferrableSurface(15849): New surface in use[total_surfaces=4, used_surfaces=2](androidx.camera.core.impl.ImmediateSurface@d01310e}
D/DeferrableSurface(15849): use count+1, useCount=1 androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): New surface in use[total_surfaces=4, used_surfaces=3](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/DeferrableSurface(15849): use count+1, useCount=1 androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/CXCP    (15849): PruningProcessingQueue: Processing RequestOpen(virtualCamera=VirtualCamera-2, sharedCameraIds=[], graphListener=GraphProcessor(cameraGraph: CameraGraph-2), isPrewarm=false, isForegroundObserver=androidx.camera.camera2.pipe.compat.Camera2CameraController$$ExternalSyntheticLambda4@dff9165)
I/CXCP    (15849): PruningCamera2DeviceManager#processRequestOpen(CameraId-1)
D/CXCP    (15849): Opening CameraId-1 with retries...
I/CXCP    (15849): Opening CameraId-1
D/CXCP    (15849): Configured Surface(name=null)/@0xfe991e9 for Stream-4
D/CXCP    (15849): Configured androidx.camera.camera2.impl.UseCaseCameraRequestControlImpl@9cd2048
I/CXCP    (15849): Configured Stream-4 with Surface(name=null)/@0xfe991e9
D/CXCP    (15849): SurfaceActive androidx.camera.core.SurfaceRequest$2@e5fc1a4 in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count+1, useCount=3 androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/CXCP    (15849): UseCaseCameraRequestControlImpl#setParametersAsync: [DEFAULT] values = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, optionPriority = OPTIONAL
D/CXCP    (15849): Configured Surface(name=null)/@0xf0122b8 for Stream-5
I/CXCP    (15849): Configured Stream-5 with Surface(name=null)/@0xf0122b8
D/CXCP    (15849): SurfaceActive androidx.camera.core.impl.ImmediateSurface@d01310e in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.impl.ImmediateSurface@d01310e
D/CXCP    (15849): Configured Surface(name=null)/@0xe600891 for Stream-6
I/CXCP    (15849): Configured Stream-6 with Surface(name=null)/@0xe600891
D/CXCP    (15849): SurfaceActive androidx.camera.core.impl.ImmediateSurface@cb81ec5 in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count+1, useCount=2 androidx.camera.core.impl.ImmediateSurface@cb81ec5
I/CameraManager(15849): registerAvailabilityCallback: Is device callback = false
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 0 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_PRESENT
I/BufferQueueProducer(15849): [](id:3de900000005,api:0,p:-885016064,c:15849) setDequeueTimeout:2077252342
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 2 status STATUS_PRESENT
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 3 status STATUS_PRESENT
I/CXCP    (15849): Surface setup complete
I/BLASTBufferQueue_Java(15849): new BLASTBufferQueue, mName= ViewRootImpl@d61098b[MainActivity] mNativeObject= 0xb4000078db349f90 sc.mNativeObject= 0xb4000078eb315350 caller= android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3028 android.view.ViewRootImpl.relayoutWindow:10131 android.view.ViewRootImpl.performTraversals:4110 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 android.view.Choreographer.doCallbacks:1153 android.view.Choreographer.doFrame:1079 android.view.Choreographer$FrameDisplayEventReceiver.run:1646 
D/DeferrableSurface(15849): use count-1,  useCount=2 closed=false androidx.camera.core.SurfaceRequest$2@e5fc1a4
I/BLASTBufferQueue_Java(15849): update, w= 1080 h= 2400 mName = ViewRootImpl@d61098b[MainActivity] mNativeObject= 0xb4000078db349f90 sc.mNativeObject= 0xb4000078eb315350 format= -3 caller= android.graphics.BLASTBufferQueue.<init>:89 android.view.ViewRootImpl.updateBlastSurfaceIfNeeded:3028 android.view.ViewRootImpl.relayoutWindow:10131 android.view.ViewRootImpl.performTraversals:4110 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.impl.ImmediateSurface@cb81ec5
I/ViewRootImpl@d61098b[MainActivity](15849): Relayout returned: old=(0,0,1080,2400) new=(0,0,1080,2400) relayoutAsync=false req=(1080,2400)0 dur=16 res=0x403 s={true 0xb4000079fb34b420} ch=true seqId=0
D/CXCP    (15849): CameraId-1 has become available! Notifying listeners...
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/ViewRootImpl@d61098b[MainActivity](15849): mThreadedRenderer.initialize() mSurface={isValid=true 0xb4000079fb34b420} hwInitialized=true
I/SurfaceView(15849): 244178581 Changes: creating=false format=false size=false visible=false alpha=false hint=false visible=false left=false top=false z=false attached=true lifecycleStrategy=false
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraAvailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163318572148118), current timestamp = TimestampNs(value=163318572155149).
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
I/SurfaceView@e8dde95(15849): windowStopped(false) true io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
I/SurfaceView(15849): 244178581 Changes: creating=true format=false size=false visible=true alpha=false hint=false visible=true left=false top=false z=false attached=true lifecycleStrategy=false
D/CXCP    (15849): UseCaseCameraRequestControlImpl#setParametersAsync: [DEFAULT] values = {CaptureRequest.Key(android.control.zoomRatio)=1.0}, optionPriority = OPTIONAL
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): UseCaseCameraRequestControlImpl#updateCamera2ConfigAsync
I/BufferQueueProducer(15849): [](id:3de900000006,api:0,p:-885479168,c:15849) setDequeueTimeout:2077252342
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
I/BLASTBufferQueue_Java(15849): update, w= 1080 h= 2400 mName = null mNativeObject= 0xb4000078db352910 sc.mNativeObject= 0xb4000078eb3f0ad0 format= 4 caller= android.view.SurfaceView.createBlastSurfaceControls:1517 android.view.SurfaceView.updateSurface:1193 android.view.SurfaceView.setWindowStopped:403 android.view.SurfaceView.surfaceCreated:1994 android.view.ViewRootImpl.notifySurfaceCreated:2945 android.view.ViewRootImpl.performTraversals:4580 
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraAvailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163318575604211), current timestamp = TimestampNs(value=163318575610305).
I/SurfaceView@e8dde95(15849): 244178581 Cur surface: Surface(name=null)/@0x69236ba
I/SurfaceView@e8dde95(15849): pST: sr = Rect(0, 0 - 1080, 2400) sw = 1080 sh = 2400
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/SurfaceView@e8dde95(15849): 244178581 performSurfaceTransaction RenderWorker position = [0, 0, 1080, 2400] surfaceSize = 1080x2400
I/SurfaceView@e8dde95(15849): updateSurface: mVisible = true mSurface.isValid() = true
I/SurfaceView@e8dde95(15849): updateSurface: mSurfaceCreated = false surfaceChanged = true visibleChanged = true
I/SurfaceView(15849): 244178581 visibleChanged -- surfaceCreated
I/SurfaceView@e8dde95(15849): surfaceCreated 1 #1 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2400}
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): Using default SessionConfig
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [], template = RequestTemplate(value=1)
D/CXCP    (15849): State3AControl.getFinalPreferredAeMode: preferAeMode = 1
D/CXCP    (15849): UseCaseCameraRequestControlImpl#setParametersAsync: [DEFAULT] values = {CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1}, optionPriority = OPTIONAL
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): UseCaseCameraRequestControlImpl#updateCamera2ConfigAsync
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = null, template = RequestTemplate(value=1)
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [Stream-4], template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-4], template=RequestTemplate(value=1))@1b7f8f4
D/CXCP    (15849): UseCaseCameraState: Updating 3A modes: AE(AeMode(value=1), changed=true), AF(AfMode(value=0), changed=true), AWB(AwbMode(value=1), changed=true)
D/CXCP    (15849): Controller3A#update3A: cancelling previous request null
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_OPENING for client com.example.awaken API Level 2 User Id 0
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [Stream-4], template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-4], template=RequestTemplate(value=1))@67bfa92
D/CXCP    (15849): UseCaseCameraRequestControlImpl: Building SessionConfig...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: SessionConfig built. Updating state...
D/CXCP    (15849): UseCaseCameraRequestControlImpl: State update processing.
D/CXCP    (15849): UseCaseCameraState#updateState: parameters = {CaptureRequest.Key(android.control.aeExposureCompensation)=0, CaptureRequest.Key(android.control.aeMode)=1, CaptureRequest.Key(android.control.afMode)=0, CaptureRequest.Key(android.control.awbMode)=1, CaptureRequest.Key(android.control.zoomRatio)=1.0}, internalParameters = {Metadata.Key(camerax.tag_bundle)=android.hardware.camera2.CaptureRequest.setTag.CX}, streams = [Stream-4, Stream-6], template = RequestTemplate(value=1)
D/CXCP    (15849): Update RepeatingRequest: Request(streams=[Stream-4, Stream-6], template=RequestTemplate(value=1))@5d5b060
I/SurfaceView(15849): 244178581 surfaceChanged -- format=4 w=1080 h=2400
I/SurfaceView@e8dde95(15849): surfaceChanged (1080,2400) 1 #1 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ......ID 0,0-1080,2400}
I/SurfaceView(15849): 244178581 surfaceRedrawNeeded
V/SurfaceView@e8dde95(15849): Layout: x=0 y=0 w=1080 h=2400, frame=Rect(0, 0 - 1080, 2400)
D/ViewRootImpl@d61098b[MainActivity](15849): reportNextDraw android.view.ViewRootImpl.performTraversals:4718 android.view.ViewRootImpl.doTraversal:3288 android.view.ViewRootImpl$TraversalRunnable.run:11344 android.view.Choreographer$CallbackRecord.run:1689 android.view.Choreographer$CallbackRecord.run:1698 
I/ViewRootImpl@d61098b[MainActivity](15849): Setup new sync=wmsSync-ViewRootImpl@d61098b[MainActivity]#5
I/ViewRootImpl@d61098b[MainActivity](15849): Creating new active sync group ViewRootImpl@d61098b[MainActivity]#6
I/ViewRootImpl@d61098b[MainActivity](15849): registerCallbacksForSync syncBuffer=false
D/SurfaceView(15849): 244178581 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 1080, 2400] surfaceSize = 1080x2400
I/SurfaceView@e8dde95(15849): uSP: rtp = Rect(0, 0 - 1080, 2400) rtsw = 1080 rtsh = 2400
I/SurfaceView@e8dde95(15849): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SurfaceView@e8dde95(15849): aOrMT: ViewRootImpl@d61098b[MainActivity] t = android.view.SurfaceControl$Transaction@e55728c fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1666 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:369 
I/ViewRootImpl@d61098b[MainActivity](15849): mWNT: t=0xb4000078ab330e90 mBlastBufferQueue=0xb4000078db349f90 fn= 1 mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1598 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1666 
I/ViewRootImpl@d61098b[MainActivity](15849): Received frameDrawingCallback syncResult=0 frameNum=1.
I/ViewRootImpl@d61098b[MainActivity](15849): mWNT: t=0xb4000078ab388650 mBlastBufferQueue=0xb4000078db349f90 fn= 1 mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$8.onFrameDraw:13841 android.view.ThreadedRenderer$1.onFrameDraw:792 <bottom of call stack> 
I/ViewRootImpl@d61098b[MainActivity](15849): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(15849): [ViewRootImpl@d61098b[MainActivity]#2](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/ViewRootImpl@d61098b[MainActivity](15849): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
D/CXCP    (15849): Camera 1 has become unavailable
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraUnavailable(camera=CameraId-1)
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163318575604211), current timestamp = TimestampNs(value=163318705572388).
D/CXCP    (15849): tryOpenCamera: openCamera() for CameraId-1 returned
I/CXCP    (15849): Opened CameraId-1 in 139.420 ms
D/CXCP    (15849): tryOpenCamera: CameraId-1 opened
I/CXCP    (15849): Camera open completed: OpenCameraResult(cameraState=CameraState-2, errorCode=null)
I/CXCP    (15849): PruningCameraDeviceManager: CameraId-1 opened successfully
I/CXCP    (15849): Creating CameraCaptureSession from CameraId-1 using CaptureSessionState-2 with {Stream-4=Surface(name=null)/@0xfe991e9, Stream-5=Surface(name=null)/@0xf0122b8, Stream-6=Surface(name=null)/@0xe600891}
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
I/CXCP    (15849): Unavailable camera 1 detected
I/CameraManagerGlobal(15849): postSingleUpdate device: camera id 1 status STATUS_NOT_AVAILABLE
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_OPEN for client com.example.awaken API Level 2 User Id 0
I/CXCP    (15849): Loaded CameraIdList [CameraId-0, CameraId-1, CameraId-2, CameraId-3]
D/CXCP    (15849): Emitting camera ID list: [CameraId-0, CameraId-1, CameraId-2, CameraId-3]
I/BLASTBufferQueue(15849): [SurfaceView[com.example.awaken/com.example.awaken.MainActivity]@0#3](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/ViewRootImpl@d61098b[MainActivity](15849): reportDrawFinished seqId=0
I/SurfaceView(15849): 244178581 finishedDrawing
I/ViewRootImpl@d61098b[MainActivity](15849): handleWindowFocusChanged: 1 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
D/ViewRootImpl@d61098b[MainActivity](15849): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb4000079fb34b420}
D/InputMethodManagerUtils(15849): startInputInner - Id : 0
I/InputMethodManager(15849): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InsetsSourceConsumer(15849): applyRequestedVisibilityToControl: visible=false, type=ime, host=com.example.awaken/com.example.awaken.MainActivity
I/ViewRootImpl@d61098b[MainActivity](15849): Resizing android.view.ViewRootImpl@57803b7: frame = [0,0][1080,2400] reportDraw = false forceLayout = false syncSeqId = -1
I/ViewRootImpl@d61098b[MainActivity](15849): handleResized, msg = 4 frames=ClientWindowFrames{frame=[0,0][1080,2400] display=[0,0][1080,2400] parentFrame=[0,0][0,0]} forceNextWindowRelayout=false displayId=0 dragResizing=false compatScale=1.0 frameChanged=false attachedFrameChanged=false configChanged=false displayChanged=false compatScaleChanged=false
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163318953169680), current timestamp = TimestampNs(value=163318953198430).
D/CXCP    (15849): CaptureSessionState-2 Configured
D/CXCP    (15849): CaptureSessionState-2 Ready
D/CXCP    (15849): CXCP#createCaptureSession-1 - 364.907 ms
I/CXCP    (15849): Configured CaptureSessionState-2 in 367.291 ms
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-2) onGraphStarted
D/CXCP    (15849): CameraGraph-2 state updated to GRAPH_STARTED
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=OPEN, error=null)
D/CXCP    (15849): Building CaptureRequest for Request(streams=[Stream-4, Stream-6], template=RequestTemplate(value=1))@5d5b060
D/CXCP    (15849): CXCP#createCaptureRequest-1 - 0.611 ms
D/CXCP    (15849): GraphRequestProcessor-2 submitting Camera2CaptureSequence-2
D/CXCP    (15849): CaptureSessionState-2 Active
D/CXCP    (15849): CXCP#setRepeatingRequest-1 - 5.152 ms
D/CXCP    (15849): GraphRequestProcessor-2 submitted Camera2CaptureSequence-2
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_ACTIVE for client com.example.awaken API Level 2 User Id 0
I/ViewRootImpl@d61098b[MainActivity](15849): onDisplayChanged oldDisplayState=2 newDisplayState=2
I/.example.awaken(15849): Background concurrent copying GC freed 897KB AllocSpace bytes, 72(27MB) LOS objects, 48% free, 24MB/48MB, paused 261us,98us total 140.038ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/.example.awaken(15849): Background concurrent copying GC freed 806KB AllocSpace bytes, 120(45MB) LOS objects, 49% free, 14MB/29MB, paused 81us,61us total 118.961ms
I/.example.awaken(15849): Background concurrent copying GC freed 806KB AllocSpace bytes, 72(28MB) LOS objects, 45% free, 28MB/52MB, paused 353us,279us total 172.231ms
I/InsetsSourceConsumer(15849): applyRequestedVisibilityToControl: visible=true, type=statusBars, host=com.example.awaken/com.example.awaken.MainActivity
I/.example.awaken(15849): Background concurrent copying GC freed 479KB AllocSpace bytes, 87(32MB) LOS objects, 49% free, 19MB/38MB, paused 85us,83us total 124.992ms
I/.example.awaken(15849): Background concurrent copying GC freed 582KB AllocSpace bytes, 92(35MB) LOS objects, 49% free, 13MB/27MB, paused 225us,151us total 127.978ms
I/.example.awaken(15849): Background concurrent copying GC freed 404KB AllocSpace bytes, 66(23MB) LOS objects, 50% free, 19MB/38MB, paused 110us,60us total 130.945ms
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 1491/1496 (recycle/alloc) - 16/2910 (fetch/transfer)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
D/BufferPoolAccessor2.0(15849): bufferpool2 0xb4000079db3d9968 : 5(40960 size) total buffers - 1(8192 size) used buffers - 1701/1706 (recycle/alloc) - 17/3326 (fetch/transfer)
I/.example.awaken(15849): Background concurrent copying GC freed 471KB AllocSpace bytes, 85(32MB) LOS objects, 49% free, 19MB/39MB, paused 5.298ms,328us total 85.567ms
D/WindowOnBackDispatcher(15849): onBackInvoked, owner=ViewRootImpl@d61098b[MainActivity], callback=android.view.ViewRootImpl$$ExternalSyntheticLambda19@6743edc
I/ViewRootImpl@d61098b[MainActivity](15849): ViewPostIme key 0
D/Activity(15849): onKeyDown(KEYCODE_BACK)
I/ViewRootImpl@d61098b[MainActivity](15849): ViewPostIme key 1
D/Activity(15849): onKeyUp(KEYCODE_BACK) isTracking()=true isCanceled()=false hasCallback=false
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/ViewRootImpl@d61098b[MainActivity](15849): handleWindowFocusChanged: 0 0 call from android.view.ViewRootImpl.-$$Nest$mhandleWindowFocusChanged:0
I/ImeFocusController(15849): onPreWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(15849): onPostWindowFocus: skipped, hasWindowFocus=false mHasImeFocus=true
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330293070509), current timestamp = TimestampNs(value=163330293084103).
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330363833998), current timestamp = TimestampNs(value=163330363861186).
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330395643321), current timestamp = TimestampNs(value=163330395667332).
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330419878426), current timestamp = TimestampNs(value=163330419893894).
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330424303842), current timestamp = TimestampNs(value=163330424326707).
D/CXCP    (15849): Camera access priorities have changed
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) (CameraId-1) camera status changed: CameraPrioritiesChanged
D/CXCP    (15849): Camera2CameraController(CameraGraph-2): Not restarting. Controller state = androidx.camera.camera2.pipe.CameraController$ControllerState$STARTED@9687c94, last camera error = null, camera availability = CameraUnavailable(camera=CameraId-1), last camera priorities changed = TimestampNs(value=163330672620665), current timestamp = TimestampNs(value=163330672636602).
D/InputTransport(15849): Input channel destroyed: 'ClientS', fd=172
I/ViewRootImpl@d61098b[MainActivity](15849): handleAppVisibility mAppVisible = true visible = false
D/CXCP    (15849): Detaching [Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9, ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5, ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>>
W/ScreenFlashWrapper(15849): completePendingScreenFlashClear: none pending!
D/CXCP    (15849): UseCaseCameraRequestControl: closed
D/CXCP    (15849): Closing UseCaseCamera-2
I/CXCP    (15849): Closing CameraGraph-2
D/CXCP    (15849): Closing GraphRequestProcessor-2
D/CXCP    (15849): Closed Camera2CameraController(CameraGraph-2)
D/CXCP    (15849): Closing GraphRequestProcessor-2
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-2) onGraphStopping
D/CXCP    (15849): CameraGraph-2 state updated to GRAPH_STOPPING
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=CLOSING, error=null)
D/CXCP    (15849): CaptureSessionState-2 Shutdown
D/CXCP    (15849): Camera2CaptureSequenceProcessor-2#stopRepeating
D/CXCP    (15849): CXCP#stopRepeating-1 - 0.994 ms
D/CXCP    (15849): Camera2CaptureSequenceProcessor-2#abortCaptures
D/CXCP    (15849): reset: videoUsage = 0
D/CXCP    (15849): LowLightBoostControl#setLowLightBoostAsync: lowLightBoost = false
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = null
D/CXCP    (15849): setFlashAsync: flashMode = 2, requestControl = null
I/ViewRootImpl@d61098b[MainActivity](15849): stopped(true) old = false
D/ViewRootImpl@d61098b[MainActivity](15849): WindowStopped on com.example.awaken/com.example.awaken.MainActivity set to true
D/OpenGLRenderer(15849): CacheManager::trimMemory(20)
D/SurfaceView(15849): 9678814 windowPositionLost, frameNr = 0
I/SurfaceView@e8dde95(15849): aOrMT: ViewRootImpl@d61098b[MainActivity] t = android.view.SurfaceControl$Transaction@22bb5bf fN = 0 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:1696 android.graphics.RenderNode$CompositePositionUpdateListener.positionLost:376 
I/ViewRootImpl@d61098b[MainActivity](15849): mWNT: t=0xb4000078ab3351f0 mBlastBufferQueue=0xb4000078db349f90 fn= 0 mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1598 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionLost:1696 
I/SurfaceView@e8dde95(15849): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
I/SurfaceView(15849): 244178581 Changes: creating=false format=false size=false visible=true alpha=false hint=false visible=true left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView@e8dde95(15849): 244178581 Cur surface: Surface(name=null)/@0x69236ba
I/SurfaceView(15849): 244178581 surfaceDestroyed
I/SurfaceView@e8dde95(15849): surfaceDestroyed callback.size 1 #1 io.flutter.embedding.android.FlutterSurfaceView{e8dde95 V.E...... ........ 0,0-1080,2400}
I/CameraManagerGlobal(15849): Camera 1 facing CAMERA_FACING_FRONT state now CAMERA_STATE_IDLE for client com.example.awaken API Level 2 User Id 0
I/SurfaceView@e8dde95(15849): updateSurface: mVisible = false mSurface.isValid() = true
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
V/SurfaceView@e8dde95(15849): Layout: x=0 y=0 w=1080 h=2400, frame=Rect(0, 0 - 1080, 2400)
D/CXCP    (15849): CXCP#abortCaptures-1 - 61.071 ms
D/CXCP    (15849): Closing capture session for CaptureSessionState-2
D/CXCP    (15849): GraphProcessor(cameraGraph: CameraGraph-2) onGraphStopped
D/CXCP    (15849): CameraGraph-2 state updated to GRAPH_STOPPED
D/CXCP    (15849): Updated current camera internal state to CombinedCameraState(state=CLOSED, error=null)
I/CXCP    (15849): Disconnecting VirtualCamera-2
D/CXCP    (15849): CaptureSessionState-2 Closed
D/CXCP    (15849): CaptureSessionState-2 session finalizing
D/CXCP    (15849): Finalizing CaptureSessionState-2
D/CXCP    (15849): SurfaceInactive androidx.camera.core.SurfaceRequest$2@e5fc1a4 in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count-1,  useCount=1 closed=false androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) is closed
D/CXCP    (15849): SurfaceInactive androidx.camera.core.impl.ImmediateSurface@d01310e in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count-1,  useCount=0 closed=false androidx.camera.core.impl.ImmediateSurface@d01310e
D/CXCP    (15849): Camera2CameraController(CameraGraph-2) finalized
D/DeferrableSurface(15849): Surface no longer in use[total_surfaces=4, used_surfaces=2](androidx.camera.core.impl.ImmediateSurface@d01310e}
D/CXCP    (15849): SurfaceInactive androidx.camera.core.impl.ImmediateSurface@cb81ec5 in androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb
D/DeferrableSurface(15849): use count-1,  useCount=0 closed=false androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/DeferrableSurface(15849): Surface no longer in use[total_surfaces=4, used_surfaces=1](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/CXCP    (15849): androidx.camera.camera2.impl.UseCaseSurfaceManager@b0f7aeb remove surface listener
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/DeferrableSurface(15849): surface closed,  useCount=1 closed=true androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/DeferrableSurface(15849): surface closed,  useCount=0 closed=true androidx.camera.core.processing.SurfaceEdge$SettableSurface@7e0bdf8
D/DeferrableSurface(15849): Surface terminated[total_surfaces=3, used_surfaces=1](androidx.camera.core.processing.SurfaceEdge$SettableSurface@7e0bdf8}
D/DeferrableSurface(15849): use count-1,  useCount=0 closed=true androidx.camera.core.SurfaceRequest$2@e5fc1a4
D/DeferrableSurface(15849): Surface no longer in use[total_surfaces=3, used_surfaces=0](androidx.camera.core.SurfaceRequest$2@e5fc1a4}
D/DeferrableSurface(15849): Surface terminated[total_surfaces=2, used_surfaces=0](androidx.camera.core.SurfaceRequest$2@e5fc1a4}
D/CXCP    (15849): CaptureSessionState-2 Ready
W/ScreenFlashWrapper(15849): completePendingScreenFlashClear: none pending!
D/ImageCapture(15849): clearPipeline
D/DeferrableSurface(15849): surface closed,  useCount=0 closed=true androidx.camera.core.impl.ImmediateSurface@d01310e
D/DeferrableSurface(15849): Surface terminated[total_surfaces=1, used_surfaces=0](androidx.camera.core.impl.ImmediateSurface@d01310e}
D/DeferrableSurface(15849): surface closed,  useCount=0 closed=true androidx.camera.core.impl.ImmediateSurface@cb81ec5
D/DeferrableSurface(15849): Surface terminated[total_surfaces=0, used_surfaces=0](androidx.camera.core.impl.ImmediateSurface@cb81ec5}
D/CXCP    (15849): Detaching [Preview:androidx.camera.core.Preview-6b546cd9-6851-4d02-8051-ebf0f22dafe9, ImageCapture:androidx.camera.core.ImageCapture-1512f44a-a7fc-4860-90aa-160a69d0d7c5, ImageAnalysis:androidx.camera.core.ImageAnalysis-6f9e38e5-f79e-4fff-ad48-db260147ce8c] from UseCaseManager<CameraGraphConfigProvider<CameraId-1>>
D/FlutterGeolocator(15849): Detaching Geolocator from activity
I/ExoPlayerImpl(15849): Release c872f39 [AndroidXMedia3/1.9.0] [a52sxq, SM-A528B, samsung, 34] [media3.common, media3.exoplayer, media3.decoder, media3.datasource, media3.extractor]
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(FLUSHED)
D/CCodecBuffers(15849): [c2.sec.mp3.decoder#283:1D-Output.Impl[N]] Client returned a buffer it does not own according to our record: 0
D/MediaCodec(15849): keep callback message for reclaim
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RESUMING)
I/CCodecConfig(15849): query failed after returning 7 values (BAD_INDEX)
I/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] 4 initial input buffers available
W/Codec2Client(15849): query -- param skipped: index = 1342179345.
W/Codec2Client(15849): query -- param skipped: index = 2415921170.
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RUNNING)
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RELEASING)
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] MediaCodec discarded an unknown buffer
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] MediaCodec discarded an unknown buffer
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] MediaCodec discarded an unknown buffer
D/CCodecBufferChannel(15849): [c2.sec.mp3.decoder#283] MediaCodec discarded an unknown buffer
I/CCodec  (15849): [c2.sec.mp3.decoder] state->set(RELEASED)
I/hw-BpHwBinder(15849): onLastStrongRef automatically unlinking death recipients
I/MediaCodec(15849): Codec shutdown complete
D/MediaCodec(15849): flushMediametrics
D/MediaCodec(15849): flushMediametrics
W/MediaCodec(15849): no metrics handle found
D/FlutterGeolocator(15849): Flutter engine disconnected. Connected engine count 1
D/FlutterGeolocator(15849): Disposing Geolocator services
E/FlutterGeolocator(15849): Geolocator position updates stopped
E/FlutterGeolocator(15849): There is still another flutter engine connected, not stopping location service
W/WindowOnBackDispatcher(15849): sendCancelIfRunning: isInProgress=falsecallback=android.view.ViewRootImpl$$ExternalSyntheticLambda19@6743edc
I/SurfaceView@e8dde95(15849): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{e8dde95 G.E...... ......I. 0,0-1080,2400} of ViewRootImpl@d61098b[MainActivity]
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/SurfaceView(15849): 244178581 Detaching SV
D/SurfaceView@e8dde95(15849): updateSurface: surface is not valid
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
I/SurfaceView@e8dde95(15849): onDetachedFromWindow: tryReleaseSurfaces()
I/SurfaceView@e8dde95(15849): releaseSurfaces: viewRoot = ViewRootImpl@d61098b[MainActivity]
D/OpenGLRenderer(15849): CacheManager::trimMemory(20)
I/ViewRootImpl@d61098b[MainActivity](15849): dispatchDetachedFromWindow
D/InputTransport(15849): Input channel destroyed: 'a68c885', fd=130
I/Choreographer(15849): Skipped 93 frames!  The application may be doing too much work on its main thread.
D/OpenGLRenderer(15849): CacheManager::trimMemory(40)
D/OpenGLRenderer(15849): RenderThread::destroyRenderingContext()
W/PigeonInstanceManager(15849): The manager was used after calls to the PigeonFinalizationListener has been stopped.
W/PigeonProxyApiBaseCodec(15849): Failed to create new Dart proxy instance of PlaneProxy: androidx.camera.core.AndroidImageProxy$PlaneProxy@766a390. io.flutter.plugins.camerax.CameraXError: Calls to Dart are being ignored.
W/PigeonInstanceManager(15849): The manager was used after calls to the PigeonFinalizationListener has been stopped.
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849): Failed to handle message
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849): java.lang.IllegalArgumentException: Unsupported value: 'androidx.camera.core.AndroidImageProxy$PlaneProxy@766a390' of type 'androidx.camera.core.AndroidImageProxy$PlaneProxy'
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.CameraXLibraryPigeonProxyApiBaseCodec.writeValue(CameraXLibrary.g.kt:1219)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugin.common.StandardMessageCodec.writeValue(StandardMessageCodec.java:276)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.CameraXLibraryPigeonCodec.writeValue(CameraXLibrary.g.kt:1617)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.CameraXLibraryPigeonProxyApiBaseCodec.writeValue(CameraXLibrary.g.kt:883)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugin.common.StandardMessageCodec.writeValue(StandardMessageCodec.java:276)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.CameraXLibraryPigeonCodec.writeValue(CameraXLibrary.g.kt:1617)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.CameraXLibraryPigeonProxyApiBaseCodec.writeValue(CameraXLibrary.g.kt:883)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugin.common.StandardMessageCodec.encodeMessage(StandardMessageCodec.java:76)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugin.common.BasicMessageChannel$IncomingMessageHandler$1.reply(BasicMessageChannel.java:266)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.PigeonApiImageProxy$Companion.setUpMessageHandlers$lambda$0$0(CameraXLibrary.g.kt:5625)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.PigeonApiImageProxy$Companion.$r8$lambda$DAAggSgPjVvunZpe4VAuoteccec(Unknown Source:0)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugins.camerax.PigeonApiImageProxy$Companion$$ExternalSyntheticLambda0.onMessage(D8$$SyntheticClass:0)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.plugin.common.BasicMessageChannel$IncomingMessageHandler.onMessage(BasicMessageChannel.java:261)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:286)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:313)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run(D8$$SyntheticClass:0)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at android.os.Handler.handleCallback(Handler.java:958)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at android.os.Handler.dispatchMessage(Handler.java:99)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at android.os.Looper.loopOnce(Looper.java:230)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at android.os.Looper.loop(Looper.java:319)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at android.app.ActivityThread.main(ActivityThread.java:8919)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at java.lang.reflect.Method.invoke(Native Method)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:578)
E/BasicMessageChannel#dev.flutter.pigeon.camera_android_camerax.ImageProxy.getPlanes(15849):    at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1103)
W/FlutterJNI(15849): Tried to send a platform message response, but FlutterJNI was detached from native C++. Could not send. Response ID: 5791
D/AndroidRuntime(15849): Shutting down VM
E/AndroidRuntime(15849): FATAL EXCEPTION: main
E/AndroidRuntime(15849): Process: com.example.awaken, PID: 15849
E/AndroidRuntime(15849): java.lang.RuntimeException: Cannot execute operation because FlutterJNI is not attached to native.
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.FlutterJNI.ensureAttachedToNative(FlutterJNI.java:515)
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.FlutterJNI.scheduleFrame(FlutterJNI.java:1025)
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.renderer.FlutterRenderer.scheduleEngineFrame(FlutterRenderer.java:1364)
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.renderer.FlutterRenderer$ImageReaderSurfaceProducer.onImage(FlutterRenderer.java:660)
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.renderer.FlutterRenderer$ImageReaderSurfaceProducer$PerImageReader.lambda$new$0$io-flutter-embedding-engine-renderer-FlutterRenderer$ImageReaderSurfaceProducer$PerImageReader(FlutterRenderer.java:544)
E/AndroidRuntime(15849):        at io.flutter.embedding.engine.renderer.FlutterRenderer$ImageReaderSurfaceProducer$PerImageReader$$ExternalSyntheticLambda0.onImageAvailable(D8$$SyntheticClass:0)
E/AndroidRuntime(15849):        at android.media.ImageReader$1.run(ImageReader.java:947)
E/AndroidRuntime(15849):        at android.os.Handler.handleCallback(Handler.java:958)
E/AndroidRuntime(15849):        at android.os.Handler.dispatchMessage(Handler.java:99)
E/AndroidRuntime(15849):        at android.os.Looper.loopOnce(Looper.java:230)
E/AndroidRuntime(15849):        at android.os.Looper.loop(Looper.java:319)
E/AndroidRuntime(15849):        at android.app.ActivityThread.main(ActivityThread.java:8919)
E/AndroidRuntime(15849):        at java.lang.reflect.Method.invoke(Native Method)
E/AndroidRuntime(15849):        at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:578)
E/AndroidRuntime(15849):        at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:1103)
I/Process (15849): Sending signal. PID: 15849 SIG: 9