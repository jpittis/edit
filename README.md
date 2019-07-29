- Starting by re-implementing antirez's [Kilo](https://github.com/antirez/kilo)
  in Common Lisp.
- Might end up adding more features some day... who knows!
- Currently raw mode / keyboard input is working but that's about it.
- [Build Your Own Text Editor](https://viewsourcecode.org/snaptoken/kilo) is
  highly recommended.
- Use the `build` script to build an `edit` binary which launches the text
  editor. Building depends on SBCL.
- The editor binary is likely not portable. I've only tested it on Linux.
- You can use `C-q` to quit the editor... or `kill -9` lol.
