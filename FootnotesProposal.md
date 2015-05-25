# Problems with current syntax #

First, it's somewhat ugly, especially when there's a string of ^ characters on the left
side of the footnote text.

Second, it's nonstandard.  The emerging de facto standard for markdown footnotes seems to
be that documented at http://rephrase.net/box/word/footnotes/,
http://rephrase.net/box/word/footnotes/syntax/, and
http://six.pairlist.net/pipermail/markdown-discuss/2005-August/001442.html.

Third, it's hard to write.  To make a note, you have to choose a unique identifier, then
move down and type the note block, then return to your text.  There's also a problem with
the implementation (in HTML), which does not auto-number footnotes:  if you use numbers
for your references, and you delete or add a note in the middle, you have to renumber all
the rest.

Autonumbered inline notes would be much easier to write.  On the other hand, notes
shouldn't be _required_ to be inline, because markdown is supposed to be easy to read, and
a paragraph with many long inline notes could be hard to read.

Ideally, then, we should _allow_ inline notes, while also providing a syntax for separated
notes.  The implementation should auto-number notes.  And we should stay as close as
possible to the emerging de facto standard.

# Proposed syntax #

Reference-style footnotes:

```
Here's a note.[^1]  You can also use more memorable identifiers.[^remember]

[^1]:  Here's the text of the note.  It can consist of multiple blocks, but
subsequent blocks must be indented (at least in the first line).

    So, this would be the second paragraph of the note.

[^remember]:  Here's the second note.  It contains a code block, indented twice:

        (my code)
```

Inline footnotes:

```
Here's an inline note.^[Quick aside.]
```

# Implementation #

Definition:

```
data Inline = ...
    | Note String [Block]
    ...
```

For inline notes with no identifier, the string will be empty.  For notes with no inline
content, the list of blocks will be empty.

Markdown reader:

  * First pass:  parse a note contents block by adding the identifier and contents (list
of blocks) to a list.
  * Second pass: whenever a non-inline note is encountered, lookup contents in this list.
> The first item with that identifier in the list gets selected.  Identifiers need not be
unique; they'll be processed in order.

HTML writer:  Ignore the identifiers and autogenerate labels.  Here is the output from
CL-Markdown's footnote system:

```
<p>Maybe people<sup id="fnr0-2006-12-18"><a href="#fn0-2006-12-18">1</a>
</sup> find CL-Markdown  to be the bees knees</p>
<div class="footnotes">
<ol>
<li id="fn0-2006-12-18">Well, at least one person
<a href="#fnr0-2006-12-18" class="footnoteBacklink"
title="Jump back to footnote 1 in the text">&#8617;</a></li>
</ol>
```

LaTeX writer:  trivial - footnotes inline anyway.

Markdown writer:  produce all footnotes at end.  Autogenerate numerical identifiers.

RST writer:

RTF writer: