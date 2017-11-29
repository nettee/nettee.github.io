title: Compiling Android Source Code
tags: [Android, Linux]
---

# Android 6

### Installing OpenJDK 7

AOSP only accepts OpenJDK 7 as compiling Java version. No HotSpot (Oracle JDK).

http://forum.ubuntu.org.cn/viewtopic.php?f=48&t=477645

Install via PPA.

```Shell
sudo add-apt-repository ppa:openjdk-r/ppa  
sudo apt-get update   
sudo apt-get install openjdk-7-jre
```

### bison: No such file or directory

Error message:

```
/bin/bash: prebuilts/misc/linux-x86/bison/bison: No such file or directory
```

Solution:

```Shell
sudo apt-get install bison
sudo apt-get install  g++-multilib gcc-multilib
```

### Link error

Error message:

```
clang: error: linker command failed with exit code 1 (use -v to see invocation)
build/core/host_shared_library_internal.mk:51: recipe for target 'out/host/linux-x86/obj/lib/libart.so' failed
```

Solution:

```diff
diff --git a/build/Android.common_build.mk b/build/Android.common_build.mk
index b84154b..8cf41c0 100644
--- a/build/Android.common_build.mk
+++ b/build/Android.common_build.mk
@@ -74,7 +74,7 @@ ART_TARGET_CFLAGS :=
 ART_HOST_CLANG := false
 ifneq ($(WITHOUT_HOST_CLANG),true)
   # By default, host builds use clang for better warnings.
-  ART_HOST_CLANG := true
+  ART_HOST_CLANG := false
 endif
```

# Android 7

### OpenJDK 8

删除 openjdk-7-jre，安装 openjdk-8-jre。

### Out of memory

Error message:

```
[ 34% 12315/35670] Building with Jack: out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/with-local/classes.dex
FAILED: /bin/bash out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/with-local/classes.dex.rsp
Out of memory error (version 1.2-rc4 'Carnac' (298900 f95d7bdecfceb327f9d201a1348397ed8a843843 by android-jack-team@google.com)).
GC overhead limit exceeded.
Try increasing heap size with java option '-Xmx<size>'.
Warning: This may have produced partial or corrupted output.
ninja: build stopped: subcommand failed.
build/core/ninja.mk:148: recipe for target 'ninja_wrapper' failed
```

Solution:

```diff
diff --git prebuilts/sdk/tools/jack-admin prebuilts/sdk/tools/jack-admin
index ee193fc..3c9178a 100755
--- a/prebuilts/sdk/tools/jack-admin
+++ b/prebuilts/sdk/tools/jack-admin
@@ -451,7 +451,7 @@ case $COMMAND in
     if [ "$RUNNING" = 0 ]; then
       echo "Server is already running"
     else
-      JACK_SERVER_COMMAND="java -XX:MaxJavaStackTraceDepth=-1 -Djava.io.tmpdir=$TMPDIR $JACK_SERVER_VM_ARGUMENTS -cp $LAUNCHER_JAR $LAUNCHER_NAME"
+      JACK_SERVER_COMMAND="java -XX:MaxJavaStackTraceDepth=-1 -Djava.io.tmpdir=$TMPDIR $JACK_SERVER_VM_ARGUMENTS -Xmx4096m -cp $LAUNCHER_JAR $LAUNCHER_NAME"
       echo "Launching Jack server" $JACK_SERVER_COMMAND
       (
         trap "" SIGHUP
```

重启jack-admin

```Shell
./prebuilts/sdk/tools/jack-admin stop-server
./prebuilts/sdk/tools/jack-admin start-server
```
