This input

```
# Introduction

... text ...

## The *easy* problem
```

would produce this output:

```
<a id="Introduction></a>
<h1>Introduction</h1>

... text ...

<a id="The_easy_problem"></a>
<h2>The <emph>easy</emph> problem</h2>
```

You can then create a link that jumps to the Introduction as follows:
```
[back to Introduction](#Introduction)
```