[Back...](README.md)

# HDT file generation

(This is for the Java library)

To index into an HDT file, the `rdf2hdt` tool is here, but it come with some options, I suggest you to put all of these options into one file and run it with the `-config options.hdtspec"`, but you can also use the `-options "options"` argument.

I usually run this one:

[**opt.hdtspec**](opt.hdtspec)

```yml
# GenDisk + K-HC
loader.cattree.futureHDTLocation=cfuture.hdt
loader.cattree.loadertype=disk
loader.cattree.location=cattree
loader.cattree.memoryFaultFactor=1
loader.disk.futureHDTLocation=future_msd.hdt
loader.disk.location=gen
loader.type=cat
parser.ntSimpleParser=true
loader.disk.compressWorker=3
loader.cattree.kcat=20
# k-HDTDiffCat
hdtcat.location=catgen
hdtcat.location.future=catgen.hdt
# Indexing part
bitmaptriples.sequence.disk=true
bitmaptriples.indexmethod=disk
bitmaptriples.sequence.disk.location=bitmaptripleseq
# Profiling
profiler=true
profiler.output=prof.opt
```

But you can remove or add some parts if required

## Canonical parser

The [canonical parser](https://www.w3.org/TR/n-triples/#canonical-ntriples) can be used with this option

```yml
parser.ntSimpleParser=true
```

this parser is usually 4 to 10 times faster than the default parser (Using Jena Riot), so if you are parsing a canonical ntriples file (like the Wikidata dump files), you should definetely consider it.

**Important**: Only the space between the nodes should be respected, but no verification are made with this parser.

## Profiler

You can profile the steps during the HDT generation with this option:

```yml
profiler=true
```

It will write the profiling information after generating the HDT, but you can also write it to disk with 

```yml
profiler.output=prof.opt
```

This can then be used with the library using the `Profiler` class.

## Disk Loader

To select an algorithm, you can use this option:

```yml
loader.type=ALGORITHM
```

By default the HDT generation is done using the `one-pass` algorithm, fast, but using a lot of memory.

### Two pass

Id: `two-pass`

The `two-pass` algorithm can be used, it takes less memory, but need to read twice the file, so you can't use streamed value, but you can trick your system with a fifo file

```bash
mkfifo mypipe.nt
# send the cat twice to the pipe
(cat myfile1.nt myfile2.nt > mypipe.nt ; cat myfile1.nt myfile2.nt > mypipe.nt) &
rdf2hdt mypipe.nt myhdt.hdt
# don't forget to remove it ;)
rm mypipe.nt
```

### CatTree

Id: `cat`

This is a basic algorithm creating small HDTs a merge them with HDTCat, you can select few things with this algorithm:

Using the k-HDTCat algorithm with the `loader.cattree.kcat` option, it will set the maximum number of HDT merged at the same time, 20 is an acceptable value for an SSD

```yml
loader.cattree.kcat=20
```

You can then select the sub HDT generation method with the `loader.cattree.loadertype` option, `disk` or `memory`, the disk generation is the best choice because it can handle an higher number of triples per sub HDT for a small difference compared to the memory implementation. But you need to configure the same options as the disk algorithm.

```yml
loader.cattree.loadertype=disk
```

The location of the sub HDTs and the future location of the HDT can be selected, by default the HDT is loaded into memory, so for big dataset, a future location is usually required if the final HDT can't be loaded into memory.

```yml
loader.cattree.futureHDTLocation=cfuture.hdt
loader.cattree.location=cattree
```

k-HDTCat also need a location to cat and map the final HDT, so it's better to add them to the options:

```yml
hdtcat.location=catgen
hdtcat.location.future=catgen.hdt
```

### Disk

Id: `disk`

The disk generation algorithm is an algorithm to generate the HDT file using the disk instead of the memory, but this algorithm has a limit, if the number of triples is too high, the algorithm will try its best, but the algorithm will be slower than creating two HDTs and then cat them using k-HDTCat, so the usage of CatTree is better with the disk implementation.

This algorithm is running some parts in parallel, but with many sequential parts, so after more than 4 threads, the speed increase won't be visible as said by the [Amdahl's law](https://en.wikipedia.org/wiki/Amdahl%27s_law), you can set this number with `loader.disk.compressWorker` option.

You can also select the generation with the `loader.disk.location`, by default this is done in a temporary directory.

Like with the CatTree algorithm, you can select the future HDT location to map the hdt instead of loading it for faster results

The options are:

```yml
loader.disk.futureHDTLocation=future_msd.hdt
loader.disk.location=gen
loader.disk.compressWorker=3
```

### Disk co-indexing

```yml
bitmaptriples.indexmethod=disk
bitmaptriples.sequence.disk=true
bitmaptriples.sequence.disk.location=bitmaptripleseq
```

You can specify the [HDT FOQ index](https://link.springer.com/chapter/10.1007/978-3-642-30284-8_36) generation using a disk method, it'll use the disk sorting to create the co-index, it is slower for small dataset and faster for large dataset in low memory envs. The sub index for the bitmaps can be defined using

```yml
bitmaptriples.sequence.disk.subindex=true
```

But i'm not using it.

## WIP with pwsh

If you are using Powershell, you can use this ~~simple~~ command to check the current created HDTs in the `loader.cattree.location/hdt-store` location
```powershell
$date = [datetime]::Parse("2023-01-31Z16:31:00"); $date; "`ntriples: $("{0:N0}" -f (Get-Content -TotalCount 10 * | Select-String "<http://rdfs.org/ns/void#triples>" -Raw | % {$s = $_.Split(" ")[2] ; [long]($s.substring(1, $s.Length - 2)) } | Measure-Object -Sum).Sum) triples ($(((Get-Content -TotalCount 10 * | Select-String "<http://rdfs.org/ns/void#triples>" -Raw | % {$s = $_.Split(" ")[2] ; [long]($s.substring(1, $s.Length - 2)) })) -join ", "))`ndtime:   $((((ls).LastWriteTime | Measure-Object -Maximum).Maximum - $date).TotalHours)h`nsize:    $("{0:N}" -f ((ls | % {$_.Length} | Measure-Object -Sum).Sum / 1000000000))GB`nfiles:   $((ls | %{"$($_.Name) ($($_.LastWriteTime))"}) -join ", ")`n"
```

It will give you this result for example:
```
mardi 31 janvier 2023 17:31:00

triples: 334 740 035 triples (111464180, 111423283, 111852572)
dtime:   1.12650158547222h
size:    3,27GB
files:   hdt-1.hdt (01/31/2023 17:55:54), hdt-2.hdt (01/31/2023 18:18:09), hdt-3.hdt (01/31/2023 18:38:35)
```

Which can be translated to:

```
CURRENT DATE (my system is in french)

triples: NUMBER_OF_TRIPLES_PARSED triples (TRIPLES_IN_HDT1, TRIPLES_IN_HDT2, ... TRIPLES_IN_HDTK)
dtime:   HOURS_SINCE_$date
size:    SIZE_OF_THE_DIRECTORY GB
files:   HDT_1 (DATE_1), HDT_2 (DATE_2), ... HDT_K (DATE_K)
```
