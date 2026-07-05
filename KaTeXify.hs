{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ViewPatterns      #-}
{-# LANGUAGE BangPatterns      #-}
{-# LANGUAGE BlockArguments    #-}

module KaTeXify (hlKaTeX) where

import qualified Data.Text    as T
import qualified Data.Text.IO as T
import GHC.IO.Handle (BufferMode (NoBuffering), Handle, hSetBuffering)
import Hakyll
import System.Process (runInteractiveCommand, readCreateProcess, shell)
import Text.Pandoc.Definition (Block (..), Inline (..), MathType (..), Pandoc, Format (..))
import Text.Pandoc.Walk (walkM)
import Text.Pandoc.Walk (walk)

hlKaTeX :: Pandoc -> Compiler Pandoc
hlKaTeX pandoc = recompilingUnsafeCompiler do
  (`walkM` pandoc) \case
    Math mathType (T.unwords . T.lines . T.strip -> text) -> do

      -- determine cli flag
      let flag = case mathType of
                  DisplayMath -> "--display-mode"
                  InlineMath  -> ""
                  
      -- call KaTex through the CLI (convert T.Text to String)
      htmlOutput <- readCreateProcess (shell $ "katex " <> flag) (T.unpack text)
      
      -- standard output string put back into Pandoc AST
      pure $ RawInline (Format "html") (T.pack htmlOutput)
      
    otherInline -> pure otherInline


  