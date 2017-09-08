title: Compiling Android Source Code
tags: [Android, Linux]
---

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







