# chalk

Chalk is a basic compiler from a toy language into CHIP-8 bytecode.
It supports some higher-level constructs like looks and if-statements,
and has some higher-level functions for drawing numbers and sprites.

## Installation

To compile chalk, simply run
```Bash
crystal build --release src/chalk.cr
```

## Usage
### Syntax
Chalk has minimal syntax. All code goes into functions, which are declared as follows:
```
fun function(param, another_param): return_type {

}
```
All parameters are assumed to be of type `u8`, an unsigned byte.
The return type can be either `u8` or `u0`, the latter being the same as `void` in C.
Users can declare variables using the `var` keyword:
```
var name = 5;
```
Assigning to existing variables is performed as such:
```
name = 6;
```
It's possible to call another function, which uses the CHIP-8 stack. This stack
is used exclusively for function calls, and may not exceed 12, as per the specifications
of the CHIP-8 virtual machine.
```
var result = double(name);
```
Additionally, to ensure that user-defined variables stored
in registers are not modified, chalk uses its own custom stack, placed at the end of the program.
This stack is accessed by modifying a stack pointer register, which holds the offset from the beginning of the stack. Because CHIP-8 registers can only hold up 8-bit unsinged numbers, the stack is therefore limited to 254 items.

If statements take "truthy" values to be those that have a nonzero value. As such,
`if (0) {}` will never run, while `while(5) {}` will never terminate. Input can be awaited
using the `get_key` function, which returns the number of the next key pressed.

Sprites can be declared using a quasi-visual syntax:
```
sprite dum [
`  x  x  `
`  x  x  `
`  x  x  `
`        `
`x      x`
` xxxxxx `
]
```
These sprites can then be used in calls to `draw_sprite(sprite, x, y)`.

## Contributing

1. Fork it (<https://github.com/DanilaFe/chalk/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [DanilaFe](https://github.com/DanilaFe) Danila Fedorin - creator, maintainer
