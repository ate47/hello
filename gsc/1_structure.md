# GSC - Structure

GSC scripts are like C, but with namespaces, threads, events and no type.

- [GSC - Structure](#gsc---structure)
  - [Variables](#variables)
    - [Special values](#special-values)
    - [Special variable](#special-variable)
  - [Functions](#functions)
    - [Internal functions](#internal-functions)
  - [Includes](#includes)

## Variables

You can create a variable using

```gsc
// create a simple variable
my_var = "my value";
```

You can specify strings, hashes, number, struct, array or boolean

```gsc
// string
my_var = "my value";
// hash
my_var = #"my_hashed_string";
// boolean
my_var = false;
// struct
my_var = {
    #my_param1: "my_param_value",
    #my_param2: 12
};
my_var = array(1, 2, 3);
```

### Special values

- `undefined`: It is the value of a variable that isn't defined, should only be used to clear a variable, you can test if a variable is undefined with `isdefined(your_variable)`
- `true`: Shortcut for 1 in boolean context
- `false`: Shortcut for 0 in boolean context

### Special variable

You have predefined variable to use in your functions.

- `self`: The caller variable of the current function
- `level`: The level object
- `world`: The world object

## Functions

All of the code has to be in functions, you can declare a function like this:

```gsc
function_name() {
    // your code
}
```

You can add parameter or return like in C

```gsc
function_name(param1, param2) {
    return false;
}
```

You can call a function using 2 methods, from the same thread, from another thread to run it at the same time as the current function.

```gsc
function_name(param1, param2) {
    // you code
}

calling_function() {
    // call your function from the same thread
    function_name("param1", "param2");
    // call your function from another thread
    thread function_name("param1", "param2");
}
```

You can call a function using a caller object, for example the internal function iPrintLn(text) is asking for a player caller.

This can be done by putting the caller object before the function call

```gsc
calling_function() {
    my_object = {
    };
    // call your function from the same thread with my_object as a caller object
    my_object function_name("param1", "param2");
    // call your function from another thread with my_object as a caller object
    my_object thread function_name("param1", "param2");
}
```

### Internal functions

Here a list of usefull internal functions,

if it is prefixed by `<type>` it is because it asks for a caller of a particular type, I've added a particular syntax `param: type` to describe the type of a
param, but it is only to help the reading, it is not possible to describe a type in GSC.

- `hash(str)`, return the hash of the string str, can be used if you don't know the full string at compile time, otherwise use `#"your_string"` instead.
- `<player> iPrintLn(text: string)`, send text to the caller object
- `<player> iPrintLnBold(text: string)`, print text to the caller object screen
- `<player> iPrintLnBold(text: string)`, print text to the caller object screen
- `<player> getCurrentWeapon() -> weapon|undefined`, return the current weapon of the caller object
- `getweapon(weapon: hash) -> weapon|undefined`, return the weapon described by this hash
- `<player> giveWeapon(weapon: weapon)`, give a weapon to the caller object
- `<player> setSpecialistIndex(character_id: int)`, set the specialist index of the player

## Includes
