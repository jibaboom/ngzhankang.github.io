--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import Control.Monad (liftM)
import qualified Data.ByteString.Lazy.Char8 as C
import           Data.Monoid (mappend)
import           Hakyll
import           Text.Jasmine


--------------------------------------------------------------------------------
config :: Configuration
config = defaultConfiguration { 
    destinationDirectory = "_site"
}


compressJsCompiler :: Compiler (Item String)
compressJsCompiler = do
    let minifyJS = C.unpack . minify . C.pack . itemBody
    s <- getResourceString
    return $ itemSetBody (minifyJS s) s


main :: IO ()
main = hakyllWith config $ do
    match "images/favicon/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/others/*" $ do
        route   idRoute
        compile copyFileCompiler

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    match "css/default.scss" $
        compile $ liftM (fmap compressCss) $
            getResourceFilePath
            >>= \fp -> unixFilter "sass" ["--scss", fp] ""
            >>= makeItem

    create ["default.css"] $ do
        route idRoute
        compile $ do
            items <- loadAll "css/*"
            makeItem $ concatMap itemBody (items :: [Item String])

    match "index.js" $ do
        route idRoute
        compile compressJsCompiler

    create ["archive.html"] $ do
        route   idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    match "index.html" $ do
        route   idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Welcome to my personal space!"           `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext