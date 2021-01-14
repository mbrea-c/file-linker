# File linker

Simple program that parses _linkconfig_ formatted configuration files and creates 
symbolic links accordingly. Can be used to maintain dotfiles in a repository and
update links into your home directory as necessary.

## Usage

To compile and execute a linkconfig file called ```config.link```:
```
$ linker config.link
```

## linkconfig format

A linkconfig file (```.link``` extension) consists of a number of lines where each line
is one of the following (NOTE: all paths are supposed to be quote delimited strings and 
environment variable substitution is supported. Example: ```"$HOME/.config/foo"```):
 - __link__ directive:  ```link SOURCE TARGET```, where _SOURCE_ and _TARGET_ are either absoluted paths or 
 paths relative to the directory the linkconfig file is located in. Creates a symlink in _TARGET_ pointing to _SOURCE_.
 - __include__ directive: ```include FILE```, parses and executes the linkconfig file _FILE_.
 - An empty line.
 - Comment, starting with ```#```.
