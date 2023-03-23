- [Abstract Binary specification](#abstract-binary-specification)
  - [Block](#block)
    - [Type](#type)
      - [Integers](#integers)
      - [Structure](#structure)
      - [Enum](#enum)
      - [Union](#union)
    - [Inheritance](#inheritance)
    - [Initialization](#initialization)
    - [Literals](#literals)
    - [Enum reference](#enum-reference)
  - [File format](#file-format)
  - [Include other ABS file](#include-other-abs-file)

# Abstract Binary specification

The abstract binary specification is an abstract way to express binary files. The suggested file extension is `.abs`.

## Block

### Type

#### Integers

The integers are defined using these keywords

| keyword              | bits |
| -------------------- | ---- |
| int8, byte, char     | 8    |
| int16, short, char16 | 16   |
| int32, int, char32   | 32   |
| int64, long          | 64   |

#### Structure

A structure is an anonymous block used as a type, the syntax is `struct { BLOCK_ITEMS } item;` and can be used inside blocks.

**Example**

```regex
MyStruct {
    struct {
        int element;
    } header;
    int element;
}
```

#### Enum

An enum is an user custom data type, it needs to have a datatype attached to it to know how we represent it.

**Syntax**

```regex
enum ENUM_NAME : DATA_TYPE {
    ENUM_CONST_NAME = ENUM_INIT_VALUE
    (, ENUM_CONST_NAME = ENUM_INIT_VALUE)*
}
```

The enum name can then be used like all other datatypes, it will use the attached datatype size to be stored.

**Example**

```regex
enum MyEnum : byte {
    MY_ENUM_VAR_1 = 0,
    MY_ENUM_VAR_2 = 1,
    MY_ENUM_VAR_4 = 4
}

MyStruct {
    MyEnum enum_value = MY_ENUM_VAR_2;
}
```

#### Union

Union are for blocks with an unknown type at compile time, but can only be from multiple types, it is described in a `union` block or as an anonymous type.

**Example**

```regex
union Number {
    int integer_value;
    long integer_long_value;
}

MyStruct {
    union {
        int32 value32;
        int8 value8;
    } myvalue;
}
```

Values are accessed using `Number.integer_value`.

### Inheritance

Inheritance is an option to expand a block with another block, it is done by adding `: INHERITED_BLOCK` after a block name

The vocabulary is described by:

- `A : B {}`
  - `B` block is inherited from `A`
  - `A` is derived from `B`.
  - `B` is the parent of `A`.
  - `A` is the child of `B`.
- `A : B {} B : C {}`
  - `C` is a parent of `A`
  - `A` is a child of `C`

All the variables from the inherited block should be considered as if they were put first in the derived block.

If a non struct variable can't be defined if a inherited block is defining a variable with the same name.

If a struct variable is defined with the same name as a inherited block variable, it will be considered as child from the parent struct. If a variable was put after the parent struct variable in the child block, it will be considered as put after the child block.

**Example**

```regex
MyStructParent {
    struct {
        int type;
    } header;
}
MyStruct : MyStructParent {
    struct {
        int data_length;
    } header;
    int data;
}
```

is the same as considering

```regex
MyStruct {
    struct {
        int type;
        int data_length;
    } header;
    int data;
}
```

### Initialization

TODO

### Literals

TODO

### Enum reference

TODO

## File format

TODO

## Include other ABS file

You can reference another file, it is done using the `#include` object, it should be contained in one line.

You can reference a relative or absolute path from the current file between 2 `"`,

**Example**

```abs
#include "my/relative/path.abs"
#include "/my/absolute/path.abs"
```

You can reference an URI by specifying the URI between a `<` and a `>`, the URI should contain a `:` character

**Example**

```abs
#include <http://example.org/demo.abs>
```

You can reference a path from an included directory between a `<` and a `>`, the path shouldn't contain the `:` character

**Example**

```abs
#include <binaries.abs>
```

The referenced file would be considered empty if it was already referenced previously in the file or in another previously referenced reference, if another file is referencing the current file, it will also be considered as an empty file.

Otherwise it should be considered like if it replacing the `#include` line.

**Example**

**demo.abs**

```abs
MyStruct {
    int id;
}
```

**demo_include.abs**

```abs
#include "demo.abs"

MyOtherStruct : MyStruct(id = 1) {
    int a;
    int b;
}
```

Will be replaced to

```abs
MyStruct {
    int id;
}

MyOtherStruct : MyStruct(id = 1) {
    int a;
    int b;
}
```

But

**demo.abs**

```abs
#include "demo_include.abs"

MyStruct {
    int id;
}
```

**demo_include.abs**

```abs
#include "demo.abs"
#include "demo.abs"

MyOtherStruct : MyStruct(id = 1) {
    int a;
    int b;
}
```

Will be replaced to

```abs
MyStruct {
    int id;
}

MyOtherStruct : MyStruct(id = 1) {
    int a;
    int b;
}
```
