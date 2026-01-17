Launching lib/main.dart on SM S918B (wireless) in debug mode...
✓ Built build/app/outputs/flutter-apk/app-debug.apk
D/FlutterJNI(32421): Beginning load of flutter...
D/FlutterJNI(32421): flutter (null) was loaded normally!
I/flutter (32421): [IMPORTANT:flutter/shell/platform/android/android_context_vk_impeller.cc(62)] Using the Impeller rendering backend (Vulkan).
Connecting to VM Service at ws://127.0.0.1:52826/-URgUdWpCtc=/ws
Connected to the VM Service.
[GoRouter] setting initial location /
[GoRouter] Full paths for routes:
           ├─/ (WelcomeScreen)
           └─/main/home (MainNavigationScreen)
             └─/main/home/semester/:semesterId (SemesterOverviewScreen)
               └─/main/home/semester/:semesterId/subject/:subjectId (SubjectDetailScreen)
           known full paths for route names:
             welcome => /
             home => /main/home
             semester => /main/home/semester/:semesterId
             subject => /main/home/semester/:semesterId/subject/:subjectId
[GoRouter] Using WidgetsApp configuration
I/Choreographer(32421): Skipped 31 frames!  The application may be doing too much work on its main thread.
I/BLASTBufferQueue(32421): [e01ad54 SurfaceView[com.mantavyam.vaultscapes/com.mantavyam.vaultscapes.MainActivity]@0#1](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient(32421): apply transaction with the first frame. layerId: 63462, bufferData(ID: 139247134703628, frameNumber: 1)
I/SurfaceView(32421): 234990932 finishedDrawing
D/VRI[MainActivity]@4f96725(32421): Setup new sync=wmsSync-VRI[MainActivity]@4f96725#1
I/VRI[MainActivity]@4f96725(32421): Creating new active sync group VRI[MainActivity]@4f96725#2
D/VRI[MainActivity]@4f96725(32421): Draw frame after cancel
D/VRI[MainActivity]@4f96725(32421): registerCallbacksForSync syncBuffer=false
D/SurfaceView(32421): 234990932 updateSurfacePosition RenderWorker, frameNr = 1, position = [0, 0, 720, 1544] surfaceSize = 720x1544
I/SV[234990932 MainActivity](32421): uSP: rtp = Rect(0, 0 - 720, 1544) rtsw = 720 rtsh = 1544
I/SV[234990932 MainActivity](32421): onSSPAndSRT: pl = 0 pt = 0 sx = 1.0 sy = 1.0
I/SV[234990932 MainActivity](32421): aOrMT: VRI[MainActivity]@4f96725 t = android.view.SurfaceControl$Transaction@f0dcbac fN = 1 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932 android.graphics.RenderNode$CompositePositionUpdateListener.positionChanged:401
I/VRI[MainActivity]@4f96725(32421): mWNT: t=0xb400007bde3fc600 mBlastBufferQueue=0xb400007bde351000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.SurfaceView.applyOrMergeTransaction:1863 android.view.SurfaceView.-$$Nest$mapplyOrMergeTransaction:0 android.view.SurfaceView$SurfaceViewPositionUpdateListener.positionChanged:1932
D/VRI[MainActivity]@4f96725(32421): Received frameDrawingCallback syncResult=0 frameNum=1.
I/VRI[MainActivity]@4f96725(32421): mWNT: t=0xb400007b9047c080 mBlastBufferQueue=0xb400007bde351000 fn= 1 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl$12.onFrameDraw:15441 android.view.ThreadedRenderer$1.onFrameDraw:718 <bottom of call stack>
I/VRI[MainActivity]@4f96725(32421): Setting up sync and frameCommitCallback
I/BLASTBufferQueue(32421): [VRI[MainActivity]@4f96725#0](f:0,a:0,s:0) onFrameAvailable the first frame is available
I/SurfaceComposerClient(32421): apply transaction with the first frame. layerId: 63457, bufferData(ID: 139247134703633, frameNumber: 1)
I/VRI[MainActivity]@4f96725(32421): Received frameCommittedCallback lastAttemptedDrawFrameNum=1 didProduceBuffer=true
D/HWUI    (32421): CFMS:: SetUp Pid : 32421    Tid : 32453
D/VRI[MainActivity]@4f96725(32421): reportDrawFinished seqId=0
D/VRI[MainActivity]@4f96725(32421): mThreadedRenderer.initializeIfNeeded()#2 mSurface={isValid=true 0xb400007b90735d00}
D/InputMethodManagerUtils(32421): startInputInner - Id : 0
I/InputMethodManager(32421): startInputInner - IInputMethodManagerGlobalInvoker.startInputOrWindowGainedFocus
I/InputMethodManager(32421): handleMessage: setImeVisibility visible=false
D/InsetsController(32421): hide(ime(), fromIme=false)
I/ImeTracker(32421): com.mantavyam.vaultscapes:f543660f: onCancelled at PHASE_CLIENT_ALREADY_HIDDEN
D/InputTransport(32421): Input channel constructed: 'ClientS', fd=168
D/ProfileInstaller(32421): Installing profile for com.mantavyam.vaultscapes
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=high hint, reason=touch, vri=VRI[MainActivity]@4f96725
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=no preference, reason=boost timeout, vri=VRI[MainActivity]@4f96725
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=high hint, reason=touch, vri=VRI[MainActivity]@4f96725

════════ Exception caught by rendering library ═════════════════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 247 pixels on the right.

The relevant error-causing widget was:
    Row Row:file:///Users/mantavyam/Projects/Vaultscapes/lib/presentation/screens/onboarding/welcome_screen.dart:208:26

: To inspect this widget in Flutter DevTools, visit: http://127.0.0.1:9100/#/inspector?uri=http%3A%2F%2F127.0.0.1%3A52826%2F-URgUdWpCtc%3D%2F&inspectorRef=inspector-0

The overflowing RenderFlex has an orientation of Axis.horizontal.
The edge of the RenderFlex that is overflowing has been marked in the rendering with a yellow and black striped pattern. This is usually caused by the contents being too big for the RenderFlex.
Consider applying a flex factor (e.g. using an Expanded widget) to force the children of the RenderFlex to fit within the available space instead of being sized to their natural size.
This is considered an error condition because it indicates that there is content that cannot be seen. If the content is legitimately bigger than the available space, consider clipping it with a ClipRect widget before putting it in the flex, or using a scrollable container rather than a Flex, like a ListView.
The specific RenderFlex in question is: RenderFlex#3ff6a relayoutBoundary=up33 OVERFLOWING
    parentData: offset=Offset(0.0, 0.0) (can use size)
    constraints: BoxConstraints(0.0<=w<=228.9, 0.0<=h<=Infinity)
    size: Size(228.9, 50.0)
    direction: horizontal
    mainAxisAlignment: center
    mainAxisSize: max
    crossAxisAlignment: center
    textDirection: ltr
    verticalDirection: down
    spacing: 0.0
    child 1: RenderSemanticsAnnotations#a6cd1 relayoutBoundary=up34
        parentData: offset=Offset(0.0, 0.0); flex=null; fit=null (can use size)
        constraints: BoxConstraints(unconstrained)
        size: Size(50.0, 50.0)
        child: RenderExcludeSemantics#101f0 relayoutBoundary=up35
            parentData: <none> (can use size)
            constraints: BoxConstraints(unconstrained)
            size: Size(50.0, 50.0)
            excluding: true
            child: RenderConstrainedBox#40f1c relayoutBoundary=up36
                parentData: <none> (can use size)
                constraints: BoxConstraints(unconstrained)
                size: Size(50.0, 50.0)
                additionalConstraints: BoxConstraints(w=50.0, h=50.0)
                child: RenderPositionedBox#3fa18
                    parentData: <none> (can use size)
                    constraints: BoxConstraints(w=50.0, h=50.0)
                    size: Size(50.0, 50.0)
                    alignment: Alignment.center
                    textDirection: ltr
                    widthFactor: expand
                    heightFactor: expand
    child 2: RenderConstrainedBox#abc71 relayoutBoundary=up34
        parentData: offset=Offset(50.0, 25.0); flex=null; fit=null (can use size)
        constraints: BoxConstraints(unconstrained)
        size: Size(12.0, 0.0)
        additionalConstraints: BoxConstraints(w=12.0, 0.0<=h<=Infinity)
    child 3: RenderParagraph#4660c relayoutBoundary=up34
        parentData: offset=Offset(62.0, 2.5); flex=null; fit=null (can use size)
        constraints: BoxConstraints(unconstrained)
        size: Size(413.5, 45.0)
        textAlign: start
        textDirection: ltr
        softWrap: wrapping at box width
        overflow: clip
        locale: en_US
        maxLines: unlimited
        text: TextSpan
            inherit: true
            color: Color(alpha: 1.0000, red: 0.0941, green: 0.0941, blue: 0.1059, colorSpace: ColorSpace.sRGB)
            family: packages/shadcn_flutter/GeistSans
            size: 35.0
            weight: 500
            "Continue with Mock Auth"
◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤
════════════════════════════════════════════════════════════════════════════════

════════ Exception caught by rendering library ═════════════════════════════════
A RenderFlex overflowed by 431 pixels on the right.
The relevant error-causing widget was:
    Row Row:file:///Users/mantavyam/Projects/Vaultscapes/lib/presentation/screens/onboarding/welcome_screen.dart:225:20
════════════════════════════════════════════════════════════════════════════════
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=no preference, reason=boost timeout, vri=VRI[MainActivity]@4f96725
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=high hint, reason=touch, vri=VRI[MainActivity]@4f96725
W/WindowOnBackDispatcher(32421): sendCancelIfRunning: isInProgress=false callback=io.flutter.embedding.android.FlutterActivity$1@a2f766b
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=no preference, reason=boost timeout, vri=VRI[MainActivity]@4f96725
I/VRI[MainActivity]@4f96725(32421): call setFrameRateCategory for touch hint category=high hint, reason=touch, vri=VRI[MainActivity]@4f96725
D/Activity(32421): onBackInvoked, activity=com.mantavyam.vaultscapes.MainActivity@c17e45a, caller=android.app.Activity.$r8$lambda$fMMzRqFB89XgwJjEXdqIB9hd6X4:0 android.app.Activity$$ExternalSyntheticLambda0.onBackInvoked:0 android.window.WindowOnBackInvokedDispatcher$OnBackInvokedCallbackWrapper.lambda$onBackInvoked$4:615
D/WindowOnBackDispatcher(32421): onBackInvoked, callback=android.app.Activity$$ExternalSyntheticLambda0@75f92c6
I/ImeFocusController(32421): onPreWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
I/ImeFocusController(32421): onPostWindowFocus: skipped hasWindowFocus=false mHasImeFocus=true
D/InputTransport(32421): Input channel destroyed: 'ClientS', fd=168
I/VRI[MainActivity]@4f96725(32421): handleAppVisibility mAppVisible = true visible = false
D/VRI[MainActivity]@4f96725(32421): visibilityChanged oldVisibility=true newVisibility=false
I/SV[234990932 MainActivity](32421): onWindowVisibilityChanged(8) false io.flutter.embedding.android.FlutterSurfaceView{e01ad54 V.E...... ........ 0,0-720,1544} of VRI[MainActivity]@4f96725
I/SurfaceView(32421): 234990932 Changes: creating=false format=false size=false visible=true alpha=false hint=false left=false top=false z=false attached=true lifecycleStrategy=false
I/SurfaceView(32421): 234990932 Cur surface: Surface(name=null mNativeObject=-5476376616178059776)/@0x55bd68b
D/SurfaceComposerClient(32421): setCornerRadius ## e01ad54 SurfaceView[com.mantavyam.vaultscapes/com.mantavyam.vaultscapes.MainActivity]@0#63461 cornerRadius=0.000000
I/SurfaceView(32421): 234990932 surfaceDestroyed
I/SV[234990932 MainActivity](32421): surfaceDestroyed callback.size 1 #2 io.flutter.embedding.android.FlutterSurfaceView{e01ad54 V.E...... ........ 0,0-720,1544}
I/SV[234990932 MainActivity](32421): updateSurface: mVisible = false mSurface.isValid() = true
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
V/SurfaceView(32421): Layout: x=0 y=0 w=720 h=1544, frame=Rect(0, 0 - 720, 1544)
D/SurfaceView(32421): 87160288 windowPositionLost, frameNr = 0
D/HWUI    (32421): CacheManager::trimMemory(20)
I/VRI[MainActivity]@4f96725(32421): Relayout returned: old=(0,0,720,1544) new=(0,0,720,1544) relayoutAsync=false req=(720,1544)8 dur=5 res=0x2 s={false 0x0} ch=true seqId=0
I/SV[234990932 MainActivity](32421): windowStopped(true) false io.flutter.embedding.android.FlutterSurfaceView{e01ad54 V.E...... ........ 0,0-720,1544} of VRI[MainActivity]@4f96725
D/SV[234990932 MainActivity](32421): updateSurface: surface is not valid
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
D/VRI[MainActivity]@4f96725(32421): applyTransactionOnDraw applyImmediately
D/SV[234990932 MainActivity](32421): updateSurface: surface is not valid
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
D/VRI[MainActivity]@4f96725(32421): applyTransactionOnDraw applyImmediately
D/VRI[MainActivity]@4f96725(32421): Not drawing due to not visible. Reason=!mAppVisible && !mForceDecorViewVisibility
D/VRI[MainActivity]@4f96725(32421): Pending transaction will not be applied in sync with a draw due to view not visible
I/VRI[MainActivity]@4f96725(32421): mWNT: t=0xb400007be04cdb80 mBlastBufferQueue=0xnull fn= 0 HdrRenderState mRenderHdrSdrRatio=1.0 caller= android.view.ViewRootImpl.handleSyncRequestWhenNoAsyncDraw:6733 android.view.ViewRootImpl.performTraversals:5504 android.view.ViewRootImpl.doTraversal:3924
D/HWUI    (32421): CacheManager::trimMemory(40)
I/VRI[MainActivity]@4f96725(32421): stopped(true) old = false
D/VRI[MainActivity]@4f96725(32421): WindowStopped on com.mantavyam.vaultscapes/com.mantavyam.vaultscapes.MainActivity set to true
D/SV[234990932 MainActivity](32421): updateSurface: surface is not valid
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
D/VRI[MainActivity]@4f96725(32421): applyTransactionOnDraw applyImmediately
W/WindowOnBackDispatcher(32421): sendCancelIfRunning: isInProgress=false callback=android.app.Activity$$ExternalSyntheticLambda0@75f92c6
I/SurfaceView(32421): 234990932 Detaching SV
D/SV[234990932 MainActivity](32421): updateSurface: surface is not valid
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
D/VRI[MainActivity]@4f96725(32421): applyTransactionOnDraw applyImmediately
I/SV[234990932 MainActivity](32421): onDetachedFromWindow: tryReleaseSurfaces()
I/SV[234990932 MainActivity](32421): releaseSurfaces: viewRoot = VRI[MainActivity]@4f96725
D/VRI[MainActivity]@4f96725(32421): applyTransactionOnDraw applyImmediately
D/ViewRootImpl(32421): Skipping stats log for color mode
I/VRI[MainActivity]@4f96725(32421): dispatchDetachedFromWindow
D/InputTransport(32421): Input channel destroyed: 'efe9efe', fd=138
D/BBA2    (32421): setIsFg isFg = false; delayValue 3999ms
Lost connection to device.

Exited.
