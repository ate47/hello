# HDT RPL Dict specification

- [HDT RPL Dict specification](#hdt-rpl-dict-specification)
- [RPL HDT](#rpl-hdt)
  - [RPL dictionary](#rpl-dictionary)
  - [LiteralSections section](#literalsections-section)

# RPL HDT

## RPL dictionary

An RPL dictionary is a version of the Multi-Section Dictionary (**MSD**) also splitting the languages and ordering the number by their values instead of their strings.

```c++
RPLDictionary {
    ControlInfo ci;
    PFCSection R;
    PFCSection P;
    LiteralSections L;
}
```

## LiteralSections section

```c++
LiteralSections {

}
```
