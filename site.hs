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
    -- destinationDirectory = "_site" we blanco this out because we need to generate files to docs for github to render
    destinationDirectory = "docs"
}


compressJsCompiler :: Compiler (Item String)
compressJsCompiler = do
    let minifyJS = C.unpack . minify . C.pack . itemBody
    s <- getResourceString
    return $ itemSetBody (minifyJS s) s


postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext


-- clean url extensions (www.xyz/about.html -> www.xyz/about)
-- https://github.com/sakshamsharma/acehack/blob/d2cdfbaffa8eeee548b52dcf20b71822c361848b/site.hs#L242
cleanRoute :: Bool -> Routes
cleanRoute isTopLevel =
  customRoute $
  (++ "/index.html") . takeWhile (/= '.') . adjustPath isTopLevel . toFilePath
  where
    adjustPath False = id
    adjustPath True  = reverse . takeWhile (/= '/') . reverse


main :: IO ()
main = hakyllWith config $ do
    match "images/favicon/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "images/others/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "index.html" $ do
        route   idRoute
        compile $ pandocCompiler 
                >>= loadAndApplyTemplate"templates/default.html" postCtx

    match (fromList["about.md"]) $ do
        route $ cleanRoute True
        compile $ pandocCompiler
                >>= loadAndApplyTemplate "templates/about.html" postCtx
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls









    -- match "index.html" $ do
    --     route   idRoute
    --     compile $ do
    --         posts <- recentFirst =<< loadAll "posts/*"
    --         let indexCtx =
    --                 listField "posts" postCtx (return posts) `mappend`
    --                 constField "title" "Welcome to my personal space!"           `mappend`
    --                 defaultContext

    --         getResourceBody
    --             >>= applyAsTemplate indexCtx
    --             >>= loadAndApplyTemplate "templates/default.html" indexCtx
    --             >>= relativizeUrls

    -- match "about.html" $ do
    --     route idRoute
    --     compile $ 
        


    -- create ["about.html"] $ do
    --     route   idRoute
    --     compile $ do
    --         let aboutCtx =
    --                 -- listField "posts" postCtx (return posts) `mappend`
    --                 constField "title" "Who exactly is this guy???" `mappend`
    --                 defaultContext

    --         -- getResourceBody
    --         makeItem ""
    --             -- >>= applyAsTemplate aboutCtx
    --             >>= loadAndApplyTemplate "templates/about.html" aboutCtx
    --             >>= loadAndApplyTemplate "templates/default.html" aboutCtx
    --             >>= relativizeUrls






    -- create ["archive.html"] $ do
    --     route   idRoute
    --     compile $ do
    --         posts <- recentFirst =<< loadAll "posts/*"
    --         let archiveCtx =
    --                 listField "posts" postCtx (return posts) `mappend`
    --                 constField "title" "Archives"            `mappend`
    --                 defaultContext

    --         makeItem ""
    --             >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
    --             >>= loadAndApplyTemplate "templates/default.html" archiveCtx
    --             >>= relativizeUrls








    -- match (fromList ["resume.md"]) $ do
    --     route   $ setExtension "html"
    --     compile $ pandocCompiler
    --         >>= loadAndApplyTemplate "templates/default.html" defaultContext
    --         >>= relativizeUrls



    match (fromList["resume.md"]) $ do
        route $ cleanRoute True
        compile $ pandocCompiler
                -- >>= loadAndApplyTemplate "templates/about.html" postCtx
                >>= loadAndApplyTemplate "templates/default.html" defaultContext
                >>= relativizeUrls






    match "posts/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    -- https://github.com/ccressent/cressent.org-hakyll/commit/8c5603453a5f968e600cf3317cd10037e3f45b55
    match "css/*" $
        compile $ liftM (fmap compressCss) $
            getResourceFilePath
            >>= \fp -> unixFilter "sass" ["--scss", fp] ""
            >>= makeItem

    -- match "css/default.scss" $
    --     compile $ liftM (fmap compsCss) $
    --         getResourceFilePath
    --         >>= \fp -> unixFilter "sass" ["--scss", fp] ""
    --         >>= makeItem

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

    -- match "index.html" $ do
    --     route   idRoute
    --     compile $ do
    --         posts <- recentFirst =<< loadAll "posts/*"
    --         let indexCtx =
    --                 listField "posts" postCtx (return posts) `mappend`
    --                 constField "title" "Welcome to my personal space!"           `mappend`
    --                 defaultContext

            -- getResourceBody
    --             >>= applyAsTemplate indexCtx
    --             >>= loadAndApplyTemplate "templates/default.html" indexCtx
    --             >>= relativizeUrls

    

    match "templates/*" $ compile templateCompiler


--------------------------------------------------------------------------------
-- postCtx :: Context String
-- postCtx =
--     dateField "date" "%B %e, %Y" `mappend`
--     defaultContext