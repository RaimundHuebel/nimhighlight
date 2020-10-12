# Nim Highligter

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble.png)](https://github.com/yglukhov/nimble-tag)



## Introduction

Provides a tool and a library to colorize the output of cli-tools.
This project is inspired by the ruby-gem colorize (https://github.com/fazibear/colorize).



## Get Started

Install Nim Highlighter

   ```shell
   $ nimble install nimhighlight
   ```


Using cli-tool hightlight:

   ```shell
   # Show help ...
   $ highlight --help

   # Colorize Std-Input ...
   $ echo "hello dude world" | highlight -e=".+:blue" -e=ello:green -e="l:red" -e=worl:magenta:yellow

   # Example: Highlight keywords in source-file ...
   $ cat src/highlight.nim | dist/release/highlight -e="^.+:black" -e="while|true|false|when|type|case:yellow" -e="#.+:green" -n

   # Create and use config file ...
   $ highlight --init -e=".+:blue" -e=ello:green -e="l:red" -e=worl:magenta:yellow
   $ echo "hello dude world" | highlight
   ```

Using Nim Highlighter as library

   ```nim
   import highlightpkg/colorize

   echo "Hello World".green
   echo "Hello World".onYellow
   echo "Hello World".yellow.onBlue
   ```

## Develop

### Running Tests

   ```shell
   $ nimble test
   ```



## Links

- [Repository of Nim Highlight](https://github.com/RaimundHuebel/nimhighlight)
