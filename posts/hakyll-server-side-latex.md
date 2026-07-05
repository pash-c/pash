---
title: Server-side LaTeX Rendering (and Sidenotes) with Hakyll
date: 2026-07-02
tags: [tag1, tag2]
---

In the process of setting up this blog, two slightly tricky things to set up were:

  1. Server-side rendering of latex.
  2. Generating sidenotes instead of footnotes.

I figured I would share the Haskell code I used to accomplish these things in case it is helpful to anyone else (and because I am in need of content to post).

For the first problem I was very grateful that there were some examples of how to accomplish this online[^1]. You can't avoid javascript entirely and need to install [KaTeX](https://katex.org/docs/node) to render the math. You also have to link the KaTeX css with:

```html
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
```
Then the solution I settled on is a small chunk of code, and is relatively self-explanatory:

[^1]: Helpful posts by [Ifaz Kabir](https://ifazk.com/blog/2018-11-20-JavaScript-free-Hakyll-site.html) and [Tony Zorman](https://tony-zorman.com/posts/katex-with-hakyll)

```haskell
hlKaTeX :: Pandoc -> Compiler Pandoc
hlKaTeX pandoc = recompilingUnsafeCompiler do
  (`walkM` pandoc) \case
    Math mathType (T.unwords . T.lines . T.strip -> text) -> do

      -- determine which type of math it is (display or inline)
      let flag = case mathType of
                  DisplayMath -> "--display-mode"
                  InlineMath  -> ""
                  
      -- call KaTex through the CLI, turns math into HTML 
      htmlOutput <- readCreateProcess (shell $ "katex " <> flag) (T.unpack text)
      
      -- put the html string right back into the Pandoc AST
      pure $ RawInline (Format "html") (T.pack htmlOutput)
      
    otherInline -> pure otherInline
```

and then you can pass the above function to a custom pandoc compiler in your site.hs file:

```haskell
pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler =
  pandocCompilerWithTransformM
    defaultHakyllReaderOptions
    (defaultHakyllWriterOptions { writerReferenceLocation = EndOfBlock})
    hlKaTeX 
```

The line: ```defaultHakyllWriterOptions { writerReferenceLocation = EndOfBlock}``` solves problem number 2, and places footnotes right after the block they are placed in, instead of at the end of the html. Some custom CSS can then turn them into the sidenotes you see in this post. The full source is on my GitHub.

Boom, we have pretty pre-rendered math equations[^2]:

$$
\int_{\partial M} \omega = \int_M d\omega.
$$

[^2]: and nice sidenotes.