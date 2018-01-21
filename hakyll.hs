{-# LANGUAGE OverloadedStrings #-}

module Main where

import Hakyll
import Text.Pandoc.Options
import System.Environment (getArgs)

main :: IO ()
main = do
  (action:_) <- getArgs
  let
    postsPattern =
      if action == "watch"
      then "posts/*" .||. "drafts/*"
      else "posts/*"

  hakyll $ do

    match "images/*" $ do
      route idRoute
      compile copyFileCompiler

    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
      route $ setExtension "html"
      compile
        $ pandocMathCompiler
        >>= loadAndApplyTemplate "templates/default.html" defaultContext
        >>= relativizeUrls

    match postsPattern $ do
      route $ setExtension "html"
      compile
        $ pandocMathCompiler
        >>= loadAndApplyTemplate "templates/post.html"    postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

    create ["archive.html"] $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll postsPattern
        let
          archiveCtx =
            listField "posts" postCtx (return posts) `mappend`
            constField "title" "Archives" `mappend`
            defaultContext

        makeItem ""
          >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
          >>= loadAndApplyTemplate "templates/default.html" archiveCtx
          >>= relativizeUrls

    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll postsPattern
        let
          indexCtx =
            listField "posts" postCtx (return posts) `mappend`
            constField "title" "Home" `mappend`
            defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    match "templates/*" $
      compile templateCompiler

--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
  dateField "date" "%B %e, %Y" `mappend`
  defaultContext

pandocMathCompiler :: Compiler (Item String)
pandocMathCompiler =
  let
    mathExtensions =
      [ Ext_tex_math_dollars
      , Ext_tex_math_double_backslash
      , Ext_latex_macros
      ]
    defaultExtensions = writerExtensions defaultHakyllWriterOptions
    newExtensions = foldr enableExtension defaultExtensions mathExtensions
    writerOptions =
      defaultHakyllWriterOptions
      { writerExtensions = newExtensions
      , writerHTMLMathMethod = MathJax ""
      }
  in pandocCompilerWith defaultHakyllReaderOptions writerOptions
