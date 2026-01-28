E/flutter (31182): [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: PlatformException(PdfRendererException, io.scer.pdfx.PdfRendererException: Can't open file, Cause: null, Stacktrace: io.scer.pdfx.PdfRendererException: Can't open file
E/flutter (31182): 	at io.scer.pdfx.Messages.openDocumentData(Messages.kt:54)
E/flutter (31182): 	at dev.flutter.pigeon.Pigeon$PdfxApi.lambda$setup$0(Pigeon.java:1151)
E/flutter (31182): 	at dev.flutter.pigeon.Pigeon$PdfxApi$$ExternalSyntheticLambda0.onMessage(D8$$SyntheticClass:0)
E/flutter (31182): 	at io.flutter.plugin.common.BasicMessageChannel$IncomingMessageHandler.onMessage(BasicMessageChannel.java:261)
E/flutter (31182): 	at io.flutter.embedding.engine.dart.DartMessenger.invokeHandler(DartMessenger.java:292)
E/flutter (31182): 	at io.flutter.embedding.engine.dart.DartMessenger.lambda$dispatchMessageToQueue$0$io-flutter-embedding-engine-dart-DartMessenger(DartMessenger.java:319)
E/flutter (31182): 	at io.flutter.embedding.engine.dart.DartMessenger$$ExternalSyntheticLambda0.run(D8$$SyntheticClass:0)
E/flutter (31182): 	at android.os.Handler.handleCallback(Handler.java:995)
E/flutter (31182): 	at android.os.Handler.dispatchMessage(Handler.java:103)
E/flutter (31182): 	at android.os.Looper.loopOnce(Looper.java:273)
E/flutter (31182): 	at android.os.Looper.loop(Looper.java:363)
E/flutter (31182): 	at android.app.ActivityThread.main(ActivityThread.java:10060)
E/flutter (31182): 	at java.lang.reflect.Method.invoke(Native Method)
E/flutter (31182): 	at com.android.internal.os.RuntimeInit$MethodAndArgsCaller.run(RuntimeInit.java:632)
E/flutter (31182): 	at com.android.internal.os.ZygoteInit.main(ZygoteInit.java:975)
E/flutter (31182): , null)
E/flutter (31182): #0      PdfxApi.openDocumentData (package:pdfx/src/renderer/io/pigeon.dart:544:7)
pigeon.dart:544
E/flutter (31182): <asynchronous suspension>
E/flutter (31182): #1      PdfxPlatformPigeon.openData (package:pdfx/src/renderer/io/platform_pigeon.dart:52:9)
platform_pigeon.dart:52
E/flutter (31182): <asynchronous suspension>
E/flutter (31182): 