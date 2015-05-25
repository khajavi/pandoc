#summary List of cases where `Markdown.pl` fails and Pandoc does the right thing.

## Babelmark test cases ##

[Babelmark](http://babelmark.bobtfish.net) is a web page that allows you to compare
various markdown implementations (thanks to Michel Fortin and Tom Doran).
Here are some of my favorites:

  * [Unordered list followed by ordered list](http://babelmark.bobtfish.net/?markdown=-+foo%0D%0A-+bar%0D%0A%0D%0A1.+first%0D%0A2.+second%0D%0A&normalize=on)
  * [Indented code in list item](http://babelmark.bobtfish.net/?markdown=%2B+++item+1%0D%0A%0D%0A++++%2B+++item+2%0D%0A%0D%0A+*+++*+++*+++*+++*&normalize=on)
  * [Right-aligned list numbering](http://babelmark.bobtfish.net/?markdown=+8.+item+1%0D%0A+9.+item+2%0D%0A10.+item+2a&normalize=on)
  * [Unescaped >](http://babelmark.bobtfish.net/?markdown=x%3Cmax(a%2Cb)%0D%0A&normalize=on)
  * [Nested strong and emph](http://babelmark.bobtfish.net/?markdown=***bold**+in+ital*%0D%0A%0D%0A***ital*+in+bold**%0D%0A&normalize=on)

## Indentation in multiple blocks in list items ##

http://thread.gmane.org/gmane.text.markdown.general/2341/focus=2342

## Indented code in list item ##

```
Just a small test

     This is some code

         and some indented code

and this is the end

1.  Just a small test

         This is some code

             and some indented code

     and this is the end
```

`Markdown.pl` yields

```
<p>Just a small test</p>

<pre><code> This is some code

     and some indented code
</code></pre>

<p>and this is the end</p>

<ol>
<li><p>Just a small test</p>

<pre><code> This is some code


<pre><code> and some indented code
</code></pre>

</code></pre>

<p>and this is the end</p></li>
</ol>
```

## Nested divs ##

```
<div>
<div>
text
</div>
</div>
```

`Markdown.pl` yields

```
<div>
<div>
text
</div>

<p></div></p>
```

**Note:**  This is fixed in Markdown.pl 1.0.2.

## Unordered list followed by ordered list ##

```
This should be an unordered list followed by an ordered one:

 - foo
 - bar

 1. first
 1. second
```

`Markdown.pl` yields

```
<h1>Test case</h1>

<p>This should be an unordered list followed by an ordered one:</p>

<ul>
<li>foo</li>
<li><p>bar</p></li>
<li><p>first</p></li>
<li>second</li>
</ul>
```

**See also:** http://bugs.debian.org/368413

## Unordered lists and horizontal rules ##

Input:
```
+   item 1

    +   item 2

  *   *   *   *   *
```

Markdown.pl's output:
```
<ul>
<li><p>item 1</p>

<ul><li><p>item 2</p></li>
<li><ul><li><ul><li><ul><li>*</li></ul></li></ul></li></ul></li></ul></li>
</ul>
```

## Unpredictable sublists ##

(Courtesy of Allan Odgaard)

```
   * item 1
 * item 1a
   * item 2
* item 2a
 * item 2b
  * item 2c
   * item 3
```

And

```
 8. item 1
 9. item 2
10. item 2a
```

In both cases, `Markdown.pl` produces sublists (in the
way indicated by the item numbering) and pandoc does not.

## Nested emphasis and strong emphasis ##

```
***bold** in italics*
```

Markdown.pl's output:
```
<p><strong><em>bold</strong> in italics</em></p>
```

## Failure to escape < in certain contexts ##

`Markdown.pl` turns
```
x<max(a,b)
```
into
```
<p>x<max(a,b)</p>
```
where it should be
```
<p>x&lt;max(a,b)</p>
```