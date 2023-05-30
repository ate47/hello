[Back...](../README.md)

# HDT

HDT is a file format to store RDF dataset. the binary specs are described in [hdt.abs](hdt.abs), it can be combined with a co-index to handle non S?? queries described in [hdtIndex.abs](hdt.abs).

**Others**

- [Create an HDT from a Wikidata dump](hdt_wikidata_dump.md)
- [HDT RPL Dict specification](hdt_dict_rpl.md)

**Cool links**

- [Website](https://www.rdfhdt.org/)
- [Java library](https://github.com/rdfhdt/hdt-java)
- [C++ library](https://github.com/rdfhdt/hdt-cpp)
- [Rust library](https://github.com/KonradHoeffner/hdt)
- [Specifications](https://www.w3.org/Submission/2011/03/)

**Cool papers**

- Fernández, J.D., Martínez-Prieto, M.A., Gutierrez, C. (2010). Compact Representation of Large RDF Data Sets for Publishing and Exchange. In: , et al. The Semantic Web – ISWC 2010. ISWC 2010. Lecture Notes in Computer Science, vol 6496. Springer, Berlin, Heidelberg. https://doi.org/10.1007/978-3-642-17746-0_13
- Martínez-Prieto, M.A., Arias Gallego, M., Fernández, J.D. (2012). Exchange and Consumption of Huge RDF Data. In: Simperl, E., Cimiano, P., Polleres, A., Corcho, O., Presutti, V. (eds) The Semantic Web: Research and Applications. ESWC 2012. Lecture Notes in Computer Science, vol 7295. Springer, Berlin, Heidelberg. https://doi.org/10.1007/978-3-642-30284-8_36
- Diefenbach, D., Giménez-García, J.M. (2020). HDTCat: Let’s Make HDT Generation Scale. In: , et al. The Semantic Web – ISWC 2020. ISWC 2020. Lecture Notes in Computer Science(), vol 12507. Springer, Cham. https://doi.org/10.1007/978-3-030-62466-8_2

# HDT specification

- [HDT](#hdt)
- [HDT specification](#hdt-specification)
- [HDT components](#hdt-components)
  - [string](#string)
  - [vlong](#vlong)
    - [svlong](#svlong)
    - [padded vlong](#padded-vlong)
  - [CRC](#crc)
  - [ControlInfo](#controlinfo)
  - [SequenceLog](#sequencelog)
  - [Dictionary](#dictionary)
    - [PFCSection](#pfcsection)
    - [Four section dictionary](#four-section-dictionary)
    - [Prefix AND Suffix front-coded four section dictionary](#prefix-and-suffix-front-coded-four-section-dictionary)
    - [Multisection dictionary](#multisection-dictionary)

# HDT components

Here are elements from the HDT data format

## string

A string is a UTF8 encoded string, it might be followed explicitly by a `(byte)'\0'` to know the end of the string.

**It is important to keep in mind that the strings are sorted with their UTF8 encoded value, not the string value, Java for example isn't sorting correctly the strings when you reach characters using more than 16 bytes (some programming languages are using UTF16 strings)**

## vlong

A vlong is a variable-byte int representation. Each byte is used to store 7 bits, the 8th bit is used to say if we need to read the next bit.

```
0 <= X < 128 : BBBAAAA
0BBB AAAA

128 <= X < 16,384 : DDCCCCBBBBAAAA
1DDC CCCB
0BBB AAAA

16384 <= X < 2,097,152 : FEEEEDDDDCCCCBBBBAAAA
1FEE EEDD
1DDC CCCB
0BBB AAAA

```

You can find the Java implementation in the [org.rdfhdt.hdt.compact.integer.VByte](https://github.com/rdfhdt/hdt-java/blob/master/hdt-java-core/src/main/java/org/rdfhdt/hdt/compact/integer/VByte.java) class.

### svlong

A signed vlong is an extention of a unsigned vlong used to store signed integers.

All the bits are shifted by 1 bit. Then the 1st bit is set to 1 if the number is positive and 0 if the number is negative. If the number is negative, its bits are also negated.

```c++
encode_svlong(x) =
    x >= 0 ?
        encode_vlong(x << 1)
    :   encode_vlong(~(x << 1))
```

```c++
decode_svlong(x) =
    decode_vlong(x) & 1 == 0 ?
        decode_vlong(x) >>> 1
    :   ~(decode_vlong(x) >>> 1)
```

### padded vlong

By default a vlong has a variable number of bits (mindblowing, isn't it?), but in fast, it is possible to create a padded vlong to use previous algorithm while allowing to update the value later.

Use case example: I want to write a SequenceLog from an iterator without a known size while reading only once the iterator, the header containing a vlong, we can't know the size, so we can't write the blocks, with a padded vlong, we can put a 0 padded, write our blocks and then seak our file pointer to the padded vlong and write our size padded.

To do that, you need to know the maximum bit size of your number B, you will need to write at most $N = \lceil B / 7 \rceil$ bytes with it.

To write you incoming number, you write it like with a vlong, but if your last byte isn't the $N$-th one, you put a 0 in the 8th bit of your byte and you write `1000_0000` bytes until reaching the $N - 1$ byte, and you write a `0`.

**example**

Using B = 21, N = 3

```
0 <= X < 128 : BBBAAAA
1BBB AAAA
1000 0000
0000 0000

128 <= X < 16,384 : DDCCCCBBBBAAAA
1DDC CCCB
&BBB AAAA
0000 0000

16384 <= X < 2,097,152 : FEEEEDDDDCCCCBBBBAAAA
1FEE EEDD
1DDC CCCB
0BBB AAAA
```

As you can see, our 3 numbers are using the same amount of bytes, it is also important to notice that the number of used bit is higher than a regular int<n> write on disk, so this method should only be used for compatibility with previous algorithm, new algorithm should use int<n> or vlong

## CRC

Read that: https://en.wikipedia.org/wiki/Cyclic_redundancy_check

basically it's a way to compute a checksum for a large amount of data, HDT is using 8, 16 and 32 bytes crc, they are named crc8, crc16 and crc32 in the specifications.

You can find the Java implementation in the [org.rdfhdt.hdt.util.crc](https://github.com/rdfhdt/hdt-java/tree/master/hdt-java-core/src/main/java/org/rdfhdt/hdt/util/crc) package.

## ControlInfo

Tool to store information in a stream, it stores a control Type, a format string and a list of properties with the format `(key=value;)*`.

```c++
enum ControlInfoType : byte {
    UNKNOWN = 0,
    GLOBAL = 1,
    HEADER = 2,
    DICTIONARY = 3,
    TRIPLES = 4,
    INDEX = 5
}

ControlInfo {
    string cookie = "$HDT";
    ControlInfoType type;
    string format;
    byte formatEnd = '\0';
    string keys; // (key=value;)*
    byte keysEnd = '\0';
    crc16 crc;
}
```

You can find the Java implementation in the [org.rdfhdt.hdt.options.ControlInformation](https://github.com/rdfhdt/hdt-java/blob/master/hdt-java-core/src/main/java/org/rdfhdt/hdt/options/ControlInformation.java) class.

## SequenceLog

A SequenceLog is a integer array using `header.numbits` per entry, reducing the amount of unused bits.

```c++
SequenceLog {
    struct {
        byte type;
        byte numbits;
        vlong numentries;
    } header;
    crc8 headerCrc;
    int<header.numbits>[header.numentries] data;
    crc32 dataCrc;
}
```

You can find the Java implementation in the [org.rdfhdt.hdt.compact.sequence](https://github.com/rdfhdt/hdt-java/tree/master/hdt-java-core/src/main/java/org/rdfhdt/hdt/compact/sequence) package.

## Dictionary

An HDT dictionary is a structure to store the strings for the triple part.

It should be able to answer 2 important functions:

```c#
string idToString(ulong id, RDFRole position);
ulong stringToId(string str, RDFRole position);
```

`RDFRole` is the role in the RDF context: Subject, Predicate or Object.

It is composed with a header to store the type of the dictionary.

```c++
Dictionary {
    ControlInfo ci{type = DICTIONARY};
}
```

### PFCSection

A PFC section is a section to store ordered strings, it is composed of chunks with the same number of strings `blocksize`. Most of the dictionary implementations are using PFCSection.

The size of a PFC section chunk isn't static because it is storing strings, to find the start index of a chunk $i$, you need to read the index $i$ of the `blocks` sequence.

A chunk is composed of a first null-terminated UTF-8 string.

Then `blocksize - 1` prefix front coded strings with the delta from the previous string.

**example**

We are storing these 4 ordered elements. In HDT the IRI are stored without the `<`/`>`.

```
"Jean-Michel"
"Jean-Pierre"
http://atesab.fr/#ate
http://example.org/#antoine
```

Now with `block = 4`

```turtle
"Jean-Michel",0
6,Pierre",0
0,http://atesab.fr/#ate,0
7,example.org/#antoine,0
```

Here we can see the first string `"Jean-Michel"`, then we search the common prefix (PFC) with the next element `"Jean-Pierre"\0`, which is `"Jean` with a length of 6, so we can write 6 in a vlong and `"Jean-Pierre"` without its 6 first characters `Pierre"` with the end byte `0`. We do the same for all the other elements.

We can see that for close elements, we can save the common size minus the size to store the vlong. Knowing our elements are ordered, it is easy to assume that we we have at least one common byte. A vlong is using 1 byte for values from 0-127, 2 bytes for 128-16383, so the bigger the common part is, the bigger the save will be.

```c++
PFCSection {
    struct {
        byte type;
        vlong numstrings;
        vlong bytes;
        bytes blocksize;
    } header;
    crc8 headerCrc;
    SequenceLog blocks;
    PFCSectionDataChunk<header.blocksize>[] chunks;
    crc32 chunksCrc;
}
PFCSectionDataChunk<blocksize> {
    string firstStr;
    byte firstStrEnd = '\0';
    delta[blocksize] {
        vlong delta;
        string str;
        byte strEnd = '\0';
    }
}
```

### Four section dictionary

Type = `<http://purl.org/HDT/hdt#dictionaryFour>`, a four section dictionary is the default implementation of the HDT dictionary.

It will store the 3 RDF roles into 4 PFCSections, the shared, subject, predicate and object sections.

The shared section is composed of the shared elements from the subject and object sections.

The subject and object sections are composed of the subjects and the objects that aren't in the shared section.

The predicate section is composed of all the predicates.

In an RDF perpective, it is most likely that a subject can also be an object, but less likely that a subject/object is a predicate. So we don't need to store more than that.

It is also important because if a element is in a shared section, it can be easier for a SPARQL request to link it with a subject/object.

```c++
FourSectionDictionary : Dictionary{ci.format = "<http://purl.org/HDT/hdt#dictionaryFour>"} {
    DictionarySection shared;
    DictionarySection subjects;
    DictionarySection predicates;
    DictionarySection objects;
}
```

The Id mapping is implemented as follow:

```c#
string idToString(ulong id, RDFRole position) {
    switch (position) {
        case PREDICATE: return predicates.idToString(id);
        case SUBJECT:
            if (id <= shared.getNumberOfElements()) {
                return shared.idToString(id);
            }
            return subjects.idToString(id - shared.getNumberOfElements());
        case OBJECT:
            if (id <= shared.getNumberOfElements()) {
                return shared.idToString(id);
            }
            return objects.idToString(id - shared.getNumberOfElements());
    }
}
ulong stringToId(string str, RDFRole position) {
    switch (position) {
        case PREDICATE: return predicates.stringToId(str);
        case SUBJECT:
            ulong id = shared.stringToId(str);
            if (id == 0) {
                id = subject.stringToId(str);
                if (id != 0) {
                    return id + shared.getNumberOfElements();
                }
            }
            return id;
        case OBJECT:
            ulong id = shared.stringToId(str);
            if (id == 0) {
                id = object.stringToId(str);
                if (id != 0) {
                    return id + shared.getNumberOfElements();
                }
            }
            return id;
    }
}
```

### Prefix AND Suffix front-coded four section dictionary

Type = `<http://purl.org/HDT/hdt#dictionaryFourPsfc>`, a Prefix AND Suffix Front-Coded (PSFC) Four Section dictionary is an extension of the Four Section dictionary where the literals are prefixed by their type or language tag,

**example**

The elements

```turtle
"antoine"^^<http://example.org/#cool>
"voiture"@fr
"bike"
```

Are stored into PSFC format into:

```turtle
^^<http://example.org/#cool>"antoine"
@fr"voiture"
"bike"
```

```c#
string idToString(ulong id, RDFRole position) {
    return PSFCEncode(super.idToString(id, position));
}

ulong stringToId(string str, RDFRole position) {
    return super.stringToId(PSFCDecode(str), position);
}
```

It is useful to store the typed literals to avoid using the space to store same suffix using prefix coding.

It isn't used because of the multi-section dictionary

### Multisection dictionary

Type = `<http://purl.org/HDT/hdt#dictionaryMult>`, a Multisection dictionary is a version of the Four Section dictionary where the object section is splitted into multiple sections to depending on they type. Knowing a subject can't have a type, the shared section isn't impacted, it is only replacing the object section.

The object section is converted into multiple PFCSection, we first encode the ordered types into a table `types` before writing the typed sections in the same order. The particular type `NO_DATATYPE` is used to store the elements without a type, the language type is used to describe literals with language.

```c++
MultiSectionDictionary : Dictionary{ci.format = "<http://purl.org/HDT/hdt#dictionaryMult>"} {
    DictionarySection shared;
    DictionarySection subject;
    DictionarySection predicate;
    vlong typeCount;
    struct {
        vlong strSize;
        byte[] str;
    }[] types;
    DictionarySection[] objects;
}
```
