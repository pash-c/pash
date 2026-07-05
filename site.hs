{-# LANGUAGE OverloadedStrings #-}

import Hakyll
import           Hakyll.Core.Compiler.Internal
import KaTeXify (hlKaTeX)
import Text.Pandoc (WriterOptions(..), ReferenceLocation(..))

main :: IO()
main = hakyll $ do

  match "css/*" $ do
    route idRoute
    compile copyFileCompiler
  
  match "js/*" $ do
    route idRoute
    compile copyFileCompiler

  match "images/downsampled/*" $ do
    route idRoute
    compile copyFileCompiler

  match "posts/*" $ do
    route $ setExtension "html"
    compile $
      pandocMathCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let ctx =
                    listField "posts" postCtx (pure posts) `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/post-list.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

  -- create index/ home page 
  match "index.html" $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (pure posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

  -- load templatesS
  match "templates/*" $ compile templateBodyCompiler



-- post fields
postCtx :: Context String
postCtx =
  dateField "date" "%Y-%m-%d"
    <> defaultContext

pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler =
  pandocCompilerWithTransformM
    defaultHakyllReaderOptions
    (defaultHakyllWriterOptions { writerReferenceLocation = EndOfBlock})
    hlKaTeX 
