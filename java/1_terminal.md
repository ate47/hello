# Terminal

In a terminal Java env, you can't use GUI tools.

## JCMD

jcmd is a powerful tool to retreive information from JVMs.

### Get process

You can get the list of the the running Java processes with

```
$ jcmd
2098147 fr.atesab.hdtgendisktest.HDTCatTest alubm/ 2 alubm/ opt.hdtspec
2098185 jdk.jcmd/sun.tools.jcmd.JCmd
```

### Get VM states

You can then use `jcmd [pid]` to get information from the VM:

```
$ jcmd 2098147
2098147:
The following commands are available:
Compiler.CodeHeap_Analytics
[...]
help

For more information about a specific command use 'help <command>'.
```

The `Thread.print` is usually my go to, it shows the current status of the threads.

```
$ jcmd 2098147 Thread.print
2098147:
2023-01-05 14:01:33
Full thread dump OpenJDK 64-Bit Server VM (17.0.5+8-Ubuntu-2ubuntu122.04 mixed mode, sharing):

Threads class SMR info:
_java_thread_list=0x00007f0f240042f0, length=16, elements={
0x00007f0fc0013920, 0x00007f0fc00d9620, 0x00007f0fc00daa00, 0x00007f0fc00dfb80,
0x00007f0fc00e0f30, 0x00007f0fc00e2340, 0x00007f0fc00e3cf0, 0x00007f0fc00e5220,
0x00007f0fc00e6690, 0x00007f0fc010dd70, 0x00007f0fc01119d0, 0x00007f0fc027c640,
0x00007f0fc02bc590, 0x00007f0f24001730, 0x00007f0f24002c80, 0x00007f0f6c000fe0
}

"main" #1 prio=5 os_prio=0 cpu=382,27ms elapsed=393,32s tid=0x00007f0fc0013920 nid=0x2003e4 in Object.wait()  [0x00007f0fc4454000]
   java.lang.Thread.State: WAITING (on object monitor)
        at java.lang.Object.wait(java.base@17.0.5/Native Method)
        - waiting on <0x0000000680091ea8> (a org.rdfhdt.hdt.util.concurrent.KWayMerger$Worker)
        at java.lang.Thread.join(java.base@17.0.5/Thread.java:1304)
        - locked <0x0000000680091ea8> (a org.rdfhdt.hdt.util.concurrent.KWayMerger$Worker)
        at java.lang.Thread.join(java.base@17.0.5/Thread.java:1372)
        at org.rdfhdt.hdt.util.concurrent.KWayMerger.waitResult(KWayMerger.java:101)
        at org.rdfhdt.hdt.hdt.impl.diskimport.SectionCompressor.compressToFile(SectionCompressor.java:114)
        at org.rdfhdt.hdt.hdt.impl.diskimport.SectionCompressor.compress(SectionCompressor.java:173)
        at org.rdfhdt.hdt.hdt.impl.HDTDiskImporter.compressDictionary(HDTDiskImporter.java:192)
        at org.rdfhdt.hdt.hdt.impl.HDTDiskImporter.runAllSteps(HDTDiskImporter.java:348)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doGenerateHDTDisk0(HDTManagerImpl.java:308)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doGenerateHDTDisk(HDTManagerImpl.java:299)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doGenerateHDT(HDTManagerImpl.java:212)
        at org.rdfhdt.hdt.hdt.HDTManager.generateHDT(HDTManager.java:294)
        at org.rdfhdt.hdt.hdt.HDTSupplier.lambda$memory$0(HDTSupplier.java:34)
        at org.rdfhdt.hdt.hdt.HDTSupplier$$Lambda$108/0x0000000800c9d0b8.doGenerateHDT(Unknown Source)
        at org.rdfhdt.hdt.hdt.impl.diskimport.CatTreeImpl.doGenerationSync(CatTreeImpl.java:234)
        at org.rdfhdt.hdt.hdt.impl.diskimport.CatTreeImpl.doGeneration(CatTreeImpl.java:175)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doHDTCatTree(HDTManagerImpl.java:392)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doHDTCatTree(HDTManagerImpl.java:385)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doHDTCatTree(HDTManagerImpl.java:377)
        at org.rdfhdt.hdt.hdt.HDTManagerImpl.doGenerateHDT(HDTManagerImpl.java:162)
        at org.rdfhdt.hdt.hdt.HDTManager.generateHDT(HDTManager.java:280)
        at fr.atesab.hdtgendisktest.HDTCatTest.main(HDTCatTest.java:267)

[...]
```

