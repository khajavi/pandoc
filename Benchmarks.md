#summary Benchmarks comparing Pandoc to Markdown.pl.

This benchmark uses the sources for Allan Odgaard's
[TextMate manual](http://macromates.com/textmate/manual/), available at
http://macromates.com/textmate/manual/source.tbz. These sources were
concatenated into a single file, `textmate_manual.txt`, 178K in size. The
test machine is an Intel Core Duo 1.66GHz, 1G RAM, running Ubuntu linux.
Pandoc was compiled with the '-O0' optimization flag.

## Markdown.pl ##

```
$ Markdown.pl --version

This is Markdown, version 1.0.2b8.
Copyright 2004 John Gruber
http://daringfireball.net/projects/markdown/

$ time Markdown.pl textmate_manual.txt >/dev/null

real    0m15.470s
user    0m15.457s
sys     0m0.012s

$ markdown --version

This is Markdown, version 1.0.1.
Copyright 2004 John Gruber
http://daringfireball.net/projects/markdown/

$ time markdown textmate_manual.txt >/dev/null

real    0m10.300s
user    0m10.249s
sys     0m0.020s
```

## pandoc [r983](https://code.google.com/p/pandoc/source/detail?r=983) ##

```
$ time ./pandoc --strict textmate_manual.txt >/dev/null 
real    0m0.908s
user    0m0.888s
sys     0m0.016s
```

## pandoc [r979](https://code.google.com/p/pandoc/source/detail?r=979) ##

```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m1.089s
user    0m1.064s
sys     0m0.012s
```


## pandoc [r969](https://code.google.com/p/pandoc/source/detail?r=969) ##

Compiled with -O0:
```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m1.462s
user    0m1.440s
sys     0m0.020s
```

Compiled with -O2 (much slower compile, much bigger executable):
```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m1.293s
user    0m1.248s
sys     0m0.020s
```

## pandoc [r940](https://code.google.com/p/pandoc/source/detail?r=940) ##

```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m2.010s
user    0m1.988s
sys     0m0.016s
```

## pandoc [r836](https://code.google.com/p/pandoc/source/detail?r=836) ##

```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m4.005s
user    0m3.984s
sys     0m0.016s
$ 
```

## pandoc 0.42 ##

```
$ time ./pandoc --strict textmate_manual.txt >/dev/null

real    0m5.135s
user    0m5.124s
sys     0m0.008s
```