[Back...](README.md)

# Create an HDT from a Wikidata dump

You need to have the [RDFHDT CLI](https://github.com/ate47/hdt-java/wiki/Part-1----Install-the-RDFHDT-Command-Line-Interface-(CLI)) or the [qEndpoint CLI](https://github.com/the-qa-company/qEndpoint#installation) to run the command described in this page.

## Dump download

You can download the latest dump from this link: https://dumps.wikimedia.org/wikidatawiki/entities/

You have 2 types of [dump formats](https://www.mediawiki.org/wiki/Wikibase/Indexing/RDF_Dump_Format)

- Truthy : Only contains truthy statements (~7 Billions triples (2022/12))
- all : Contains all the statements (~17.5 Billions triples (2022/12))

If you want to use the fast parser, you need to select the NTriples dump, depending on your disk, you can select between the BZIP and GZIP

- [latest-all.nt.gz](https://dumps.wikimedia.org/wikidatawiki/entities/latest-all.nt.gz)
- [latest-all.nt.bz2](https://dumps.wikimedia.org/wikidatawiki/entities/latest-all.nt.bz2)
- [latest-truthy.nt.gz](https://dumps.wikimedia.org/wikidatawiki/entities/latest-truthy.nt.gz)
- [latest-truthy.nt.bz2](https://dumps.wikimedia.org/wikidatawiki/entities/latest-truthy.nt.bz2)

## Config generation

Once this file is downloaded, you need to get to a location where you have at least 5 times the HDT size, the truthy HDT is 50GB and the all HDT 150GB

You can then create a config file to configure the HDT generation, this one will use the CatTree + k-HDTCat + GenDisk algorithms using 4 cores (one core is used to read the RDF file):

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

if you want to create a Multi Section Dictionary, you need to add this line to the option file:

```
dictionary.type=dictionaryMultiObj
```

It's also important to allocate at least 6GB to map the end HDT, but a least 10GB is recommended.

## Generation

Once this is prepared, you can start it with this command, On Windows, use `rdf2hdt.bat` (Cmd) or `rdf2hdt.ps1` (Powershell)), the `-multithread` can be used if you want to get the progress bars instead of lines of the progress.

```bash
rdf2hdt.sh -multithread -config opt.hdtspec latest-all.nt.gz wikidata.hdt
```

## Output

The output will be found in the `wikidata.hdt` file, you will also find in the `prof.opt` file the profiling information for benchmarking, you can read this file with the `Profiler` class of the RDFHDT-API library

## Results

On my computer Ryzen 5 5600 with 1TB SSD using 4 cores and 6GB:

- BSBM 700M Triples (2M product): 2h with kcat=20
- Truthy 7.2B Triples: 12h with kcat=20
- All 17.5B Triples: 48h with kcat=40


