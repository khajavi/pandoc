See http://fletcherpenney.net/MultiMarkdown_Syntax_Guide#anchorandimageattributes

Example:
```
This is a formatted ![image][] and a [link][] with attributes.

[image]: http://path.to/image "Image title" width=40px height=400px
[link]:  http://path.to/link.html "Some Link" class=external
         style="border: solid black 1px;"
```

Possible abbreviation:
```
[image]: http://path.to/image "Image title" 40x400
```

One question:  How do we deal with these in LaTeX and ConTeXt, where
the pixel sizes will be inappropriate?

According to
http://amath.colorado.edu/documentation/LaTeX/reference/figures.html
LaTeX's graphicx package uses 72 pixels/inch as a default size for
bitmap images. So I suppose we could just have pandoc convert the sizes
to inches using that ratio...

roktas: It looks like 72dpi is a common assumption implicitly used in almost all
LaTeX packages, and it stems from a rather old practice.  But concerning
the screen resolution, today's defacto standard is 96dpi which is, at
least, what Microsoft, most modern desktops (including GNOME and KDE) and
web designers use.
```
        $ xdpyinfo | grep resolution
        resolution:    96x96 dots per inch
```

This 72 vs 96 mismatch causes a slight distortion at the pdflatex output.
So we might want to use 96 dpi instead of 72 in converting...