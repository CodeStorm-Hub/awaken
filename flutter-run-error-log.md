PS J:\GitHub\awaken> flutter run --dart-define-from-file=.env   
Launching lib\main.dart on sdk gphone16k x86 64 in debug mode...
WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): camera_android_camerax, flutter_timezone, wakelock_plus
Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Please check the changelogs of these plugins and upgrade to a version that supports Built-in Kotlin.
If no such version exists, report the issue to the plugin. If necessary, here is a guide on filing 
an issue against a plugin: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers#report-incompatible-kotlin-gradle-plugin-usage-to-plugin-authors

If you are a plugin author, please migrate your plugin to Built-in Kotlin using this guide: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-plugin-authors
e: Daemon compilation failed
java.lang.Exception
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:69)
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:65)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.compileWithDaemon(JvmCompilationOperationImpl.kt:303)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:152)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:69)
        at org.jetbrains.kotlin.buildtools.internal.CancellableBuildOperationImpl.executeImpl(CancellableBuildOperationImpl.kt:58)
        at org.jetbrains.kotlin.buildtools.internal.BuildOperationImpl.execute(BuildOperationImpl.kt:34)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation$lambda$1(KotlinToolchainsImpl.kt:70)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation(KotlinToolchainsImpl.kt:74)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.performCompilation(BuildToolsApiCompilationWork.kt:172)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.compileInDaemon(BuildToolsApiCompilationWork.kt:244)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.execute(BuildToolsApiCompilationWork.kt:285)
        at org.gradle.workers.internal.DefaultWorkerServer.execute(DefaultWorkerServer.java:68)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:66)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:62)
        at org.gradle.internal.classloader.ClassLoaderUtils.executeInClassloader(ClassLoaderUtils.java:100)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.lambda$execute$0(NoIsolationWorkerFactory.java:62)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:44)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:41)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:209)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:204)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:66)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:166)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.call(DefaultBuildOperationRunner.java:53)
        at org.gradle.workers.internal.AbstractWorker.executeWrappedInBuildOperation(AbstractWorker.java:41)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.execute(NoIsolationWorkerFactory.java:59)
        at org.gradle.workers.internal.DefaultWorkerExecutor.lambda$submitWork$0(DefaultWorkerExecutor.java:176)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runExecution(DefaultConditionalExecutionQueue.java:194)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.access$700(DefaultConditionalExecutionQueue.java:127)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner$1.run(DefaultConditionalExecutionQueue.java:169)
        at org.gradle.internal.Factories$1.create(Factories.java:31)
        at org.gradle.internal.work.DefaultWorkerLeaseService.withLocks(DefaultWorkerLeaseService.java:263)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:127)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:132)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runBatch(DefaultConditionalExecutionQueue.java:164)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.run(DefaultConditionalExecutionQueue.java:133)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.concurrent.ExecutorPolicy$CatchAndRecordFailures.onExecute(ExecutorPolicy.java:64)
        at org.gradle.internal.concurrent.AbstractManagedExecutor$1.run(AbstractManagedExecutor.java:47)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
        at java.base/java.lang.Thread.run(Unknown Source)
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:218)
        at org.jetbrains.kotlin.incremental.IncrementalCachesManager.close(IncrementalCachesManager.kt:58)
        at kotlin.io.CloseableKt.closeFinally(Closeable.kt:47)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compileNonIncrementally(IncrementalCompilerRunner.kt:296)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compile(IncrementalCompilerRunner.kt:131)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.execIncrementalCompiler(CompileServiceImpl.kt:764)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.access$execIncrementalCompiler(CompileServiceImpl.kt:107)
        at org.jetbrains.kotlin.daemon.CompileServiceImpl.compile(CompileServiceImpl.kt:2026)
        at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at java.rmi/sun.rmi.server.UnicastServerRef.dispatch(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport.serviceCall(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport.handleMessages(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run0(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.lambda$run$0(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run(Unknown Source)
        ... 3 more
Caused by: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:205)
        ... 22 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\class-fq-name-to-source.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\class-fq-name-to-source.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 43 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\source-to-classes.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\source-to-classes.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 44 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\internal-name-to-source.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\internal-name-to-source.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 44 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups: id-to-file.tab, file-to-id.tab
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.LookupStorage.close(LookupStorage.kt:155)
                ... 23 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\id-to-file.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\id-to-file.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\file-to-id.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\file-to-id.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs: source-to-output.tab
                ... 25 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs\source-to-output.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 24 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs\source-to-output.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more
warning: [options] source value 8 is obsolete and will be removed in a future release
warning: [options] target value 8 is obsolete and will be removed in a future release
warning: [options] To suppress warnings about obsolete options, use -Xlint:-options.
e: Daemon compilation failed
java.lang.Exception
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:69)
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:65)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.compileWithDaemon(JvmCompilationOperationImpl.kt:303)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:152)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:69)
        at org.jetbrains.kotlin.buildtools.internal.CancellableBuildOperationImpl.executeImpl(CancellableBuildOperationImpl.kt:58)
        at org.jetbrains.kotlin.buildtools.internal.BuildOperationImpl.execute(BuildOperationImpl.kt:34)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation$lambda$1(KotlinToolchainsImpl.kt:70)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation(KotlinToolchainsImpl.kt:74)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.performCompilation(BuildToolsApiCompilationWork.kt:172)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.compileInDaemon(BuildToolsApiCompilationWork.kt:244)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.execute(BuildToolsApiCompilationWork.kt:285)
        at org.gradle.workers.internal.DefaultWorkerServer.execute(DefaultWorkerServer.java:68)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:66)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:62)
        at org.gradle.internal.classloader.ClassLoaderUtils.executeInClassloader(ClassLoaderUtils.java:100)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.lambda$execute$0(NoIsolationWorkerFactory.java:62)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:44)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:41)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:209)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:204)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:66)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:166)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.call(DefaultBuildOperationRunner.java:53)
        at org.gradle.workers.internal.AbstractWorker.executeWrappedInBuildOperation(AbstractWorker.java:41)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.execute(NoIsolationWorkerFactory.java:59)
        at org.gradle.workers.internal.DefaultWorkerExecutor.lambda$submitWork$0(DefaultWorkerExecutor.java:176)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runExecution(DefaultConditionalExecutionQueue.java:194)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.access$700(DefaultConditionalExecutionQueue.java:127)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner$1.run(DefaultConditionalExecutionQueue.java:169)
        at org.gradle.internal.Factories$1.create(Factories.java:31)
        at org.gradle.internal.work.DefaultWorkerLeaseService.withLocks(DefaultWorkerLeaseService.java:263)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:127)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:132)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runBatch(DefaultConditionalExecutionQueue.java:164)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.run(DefaultConditionalExecutionQueue.java:133)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.concurrent.ExecutorPolicy$CatchAndRecordFailures.onExecute(ExecutorPolicy.java:64)
        at org.gradle.internal.concurrent.AbstractManagedExecutor$1.run(AbstractManagedExecutor.java:47)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
        at java.base/java.lang.Thread.run(Unknown Source)
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:218)
        at org.jetbrains.kotlin.incremental.IncrementalCachesManager.close(IncrementalCachesManager.kt:58)
        at kotlin.io.CloseableKt.closeFinally(Closeable.kt:47)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compileNonIncrementally(IncrementalCompilerRunner.kt:296)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compile(IncrementalCompilerRunner.kt:131)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.execIncrementalCompiler(CompileServiceImpl.kt:764)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.access$execIncrementalCompiler(CompileServiceImpl.kt:107)
        at org.jetbrains.kotlin.daemon.CompileServiceImpl.compile(CompileServiceImpl.kt:2026)
        at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at java.rmi/sun.rmi.server.UnicastServerRef.dispatch(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport.serviceCall(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport.handleMessages(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run0(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.lambda$run$0(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run(Unknown Source)
        ... 3 more
Caused by: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:205)
        ... 22 more
        Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
        Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
                at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
                at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
                at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
        Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
                at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
                at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:151)
                at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:142)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups: id-to-file.tab, file-to-id.tab
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.LookupStorage.close(LookupStorage.kt:155)
                ... 23 more
                Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                        at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                        at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                        at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                        at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:51)
                        at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:48)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
                Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                        at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                        at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                        at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                        at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
                        at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
                        at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
                        at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
                        at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs: source-to-output.tab
                ... 25 more
                Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\syedr\AppData\Local\Pub\Cache\hosted\pub.dev\package_info_plus-10.2.0\android\src\main\kotlin\dev\fluttercommunity\plus\packageinfo\PackageInfoPlugin.kt and J:\GitHub\awaken\android.
                        at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
                        at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
                        at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
                        at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
                        at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
                        at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
                        at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
                        at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 24 more
3 warnings
e: Daemon compilation failed
java.lang.Exception
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:69)
        at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:65)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.compileWithDaemon(JvmCompilationOperationImpl.kt:303)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:152)
        at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:69)
        at org.jetbrains.kotlin.buildtools.internal.CancellableBuildOperationImpl.executeImpl(CancellableBuildOperationImpl.kt:58)
        at org.jetbrains.kotlin.buildtools.internal.BuildOperationImpl.execute(BuildOperationImpl.kt:34)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation$lambda$1(KotlinToolchainsImpl.kt:70)
        at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation(KotlinToolchainsImpl.kt:74)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.performCompilation(BuildToolsApiCompilationWork.kt:172)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.compileInDaemon(BuildToolsApiCompilationWork.kt:244)
        at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.execute(BuildToolsApiCompilationWork.kt:285)
        at org.gradle.workers.internal.DefaultWorkerServer.execute(DefaultWorkerServer.java:68)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:66)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:62)
        at org.gradle.internal.classloader.ClassLoaderUtils.executeInClassloader(ClassLoaderUtils.java:100)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.lambda$execute$0(NoIsolationWorkerFactory.java:62)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:44)
        at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:41)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:209)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:204)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:66)
        at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:166)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:59)
        at org.gradle.internal.operations.DefaultBuildOperationRunner.call(DefaultBuildOperationRunner.java:53)
        at org.gradle.workers.internal.AbstractWorker.executeWrappedInBuildOperation(AbstractWorker.java:41)
        at org.gradle.workers.internal.NoIsolationWorkerFactory$1.execute(NoIsolationWorkerFactory.java:59)
        at org.gradle.workers.internal.DefaultWorkerExecutor.lambda$submitWork$0(DefaultWorkerExecutor.java:176)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runExecution(DefaultConditionalExecutionQueue.java:194)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.access$700(DefaultConditionalExecutionQueue.java:127)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner$1.run(DefaultConditionalExecutionQueue.java:169)
        at org.gradle.internal.Factories$1.create(Factories.java:31)
        at org.gradle.internal.work.DefaultWorkerLeaseService.withLocks(DefaultWorkerLeaseService.java:263)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:127)
        at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:132)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runBatch(DefaultConditionalExecutionQueue.java:164)
        at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.run(DefaultConditionalExecutionQueue.java:133)
        at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Unknown Source)
        at java.base/java.util.concurrent.FutureTask.run(Unknown Source)
        at org.gradle.internal.concurrent.ExecutorPolicy$CatchAndRecordFailures.onExecute(ExecutorPolicy.java:64)
        at org.gradle.internal.concurrent.AbstractManagedExecutor$1.run(AbstractManagedExecutor.java:47)
        at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(Unknown Source)
        at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(Unknown Source)
        at java.base/java.lang.Thread.run(Unknown Source)
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:218)
        at org.jetbrains.kotlin.incremental.IncrementalCachesManager.close(IncrementalCachesManager.kt:58)
        at kotlin.io.CloseableKt.closeFinally(Closeable.kt:47)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compileNonIncrementally(IncrementalCompilerRunner.kt:296)
        at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compile(IncrementalCompilerRunner.kt:131)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.execIncrementalCompiler(CompileServiceImpl.kt:764)
        at org.jetbrains.kotlin.daemon.CompileServiceImplBase.access$execIncrementalCompiler(CompileServiceImpl.kt:107)
        at org.jetbrains.kotlin.daemon.CompileServiceImpl.compile(CompileServiceImpl.kt:2026)
        at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(Unknown Source)
        at java.base/java.lang.reflect.Method.invoke(Unknown Source)
        at java.rmi/sun.rmi.server.UnicastServerRef.dispatch(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport$1.run(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.Transport.serviceCall(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport.handleMessages(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run0(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.lambda$run$0(Unknown Source)
        at java.base/java.security.AccessController.doPrivileged(Unknown Source)
        at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run(Unknown Source)
        ... 3 more
Caused by: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
        at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:205)
        ... 22 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\class-fq-name-to-source.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\class-fq-name-to-source.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 43 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\source-to-classes.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\source-to-classes.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 44 more
        Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\internal-name-to-source.tab] is already registered
                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                ... 24 more
                Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin\internal-name-to-source.tab] registration stack trace
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                        ... 44 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups: id-to-file.tab, file-to-id.tab
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
                at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
                at org.jetbrains.kotlin.incremental.LookupStorage.close(LookupStorage.kt:155)
                ... 23 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\id-to-file.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\id-to-file.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\file-to-id.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 25 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups\file-to-id.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more
        Suppressed: java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs: source-to-output.tab
                ... 25 more
                Suppressed: java.lang.IllegalStateException: Storage for [J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs\source-to-output.tab] is already registered
                        at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:410)
                        at org.jetbrains.kotlin.com.intellij.util.io.PagedFileStorage.<init>(PagedFileStorage.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.ResizeableMappedFile.<init>(ResizeableMappedFile.java:71)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentBTreeEnumerator.<init>(PersistentBTreeEnumerator.java:130)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentEnumerator.createDefaultEnumerator(PersistentEnumerator.java:53)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:166)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.<init>(PersistentMapImpl.java:141)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.buildImplementation(PersistentMapBuilder.java:91)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapBuilder.build(PersistentMapBuilder.java:74)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:44)
                        at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.<init>(PersistentHashMap.java:70)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.createMap(LazyStorage.kt:62)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.getStorageOrCreateNew(LazyStorage.kt:59)
                        at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
                        at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
                        at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
                        at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
                        at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
                        ... 24 more
                        Suppressed: java.lang.Exception: Storage[J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs\source-to-output.tab] registration stack trace
                                at org.jetbrains.kotlin.com.intellij.util.io.FilePageCache.registerPagedFileStorage(FilePageCache.java:437)
                                ... 44 more

FAILURE: Build completed with 3 failures.

1: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':flutter_timezone:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\flutter_timezone\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to generate a Build Scan (Powered by Develocity).
> Get more help at https://help.gradle.org.
==============================================================================

2: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':package_info_plus:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to generate a Build Scan (Powered by Develocity).
> Get more help at https://help.gradle.org.
==============================================================================

3: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':camera_android_camerax:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in J:\GitHub\awaken\build\camera_android_camerax\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to generate a Build Scan (Powered by Develocity).
> Get more help at https://help.gradle.org.
==============================================================================

BUILD FAILED in 24s
Running Gradle task 'assembleDebug'...                             24.9s
Error: Gradle task assembleDebug failed with exit code 1