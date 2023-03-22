[Back...](../README.md)

# HDT

HDT is a file format to store RDF dataset. the binary specs are described in [hdt.abs](hdt.abs), it can be combined with a co-index to handle non S?? queries described in [hdtIndex.abs](hdt.abs).

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
  - [ControlInfo](#controlinfo)
  - [SequenceLog](#sequencelog)
  - [PFCSection](#pfcsection)

# HDT components

Here are elements from the HDT data format

## string

A string is a UTF8 encoded string, it might be followed explicitly by a `(byte)'\0'` to know the end of the string.

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

## PFCSection

A PFC section is a section to store ordered strings, it is composed of chunks with the same number of strings `blocksize`.

For the block $i$, the sequence value $blocks_i = (void*)\&chunks[i] - (void*)\&chunks[0]$.

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