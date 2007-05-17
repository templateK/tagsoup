
module Example.Example where

import Data.Html.TagSoup
import Control.Monad
import Data.List
import Data.Char


{-
<div class="printfooter">
<p>Retrieved from "<a href="http://haskell.org/haskellwiki/Haskell">http://haskell.org/haskellwiki/Haskell</a>"</p>

<p>This page has been accessed 507,753 times. This page was last modified 08:05, 24 January 2007. Recent content is available under <a href="/haskellwiki/HaskellWiki:Copyrights" title="HaskellWiki:Copyrights">a simple permissive license</a>.</p>
</div>
-}
haskellHitCount :: IO ()
haskellHitCount = do
        tags <- liftM parseTagsNoPos $ openURL "http://haskell.org/haskellwiki/Haskell"
        let count = fromFooter $ head $ sections (~== TagOpen "div" [("class","printfooter")]) tags
        putStrLn $ "haskell.org has been hit " ++ show count ++ " times"
    where
        fromFooter x = read (filter isDigit num) :: Int
            where
                num = ss !! (i - 1)
                Just i = findIndex (== "times.") ss
                ss = words s
                TagText s = sections (isTagOpenName "p") x !! 1 !! 1


{-
<a href="http://www.cbc.ca/technology/story/2007/04/10/tech-bloggers.html" id=r-5_1115205181>
<b>Blogger code of conduct proposed</b>
-}
googleTechNews :: IO ()
googleTechNews = do
        tags <- liftM parseTagsNoPos $ openURL "http://news.google.com/?ned=us&topic=t"
        let links = map extract $ sections match tags
        putStr $ unlines links
    where
        extract xs = innerText (xs !! 2)

        match (TagOpen "a" y)
            = case lookup "id" y of
                   Just z -> "r" `isPrefixOf` z && 'i' `notElem` z
                   _ -> False
        match _ = False


spjPapers :: IO ()
spjPapers = do
        tags <- liftM parseTagsNoPos $ openURL "http://research.microsoft.com/~simonpj/"
        let links = map f $ sections (isTagOpenName "a") $
                    takeWhile (~/= TagOpen "a" [("name","haskell")]) $
                    drop 5 $ dropWhile (~/= TagOpen "a" [("name","current")]) tags
        putStr $ unlines links
    where
        f :: [Tag] -> String
        f = dequote . unwords . words . innerText . head . filter isTagText

        dequote ('\"':xs) | last xs == '\"' = init xs
        dequote x = x


ndmPapers :: IO ()
ndmPapers = do
        tags <- liftM parseTagsNoPos $ openURL "http://www-users.cs.york.ac.uk/~ndm/downloads/"
        let papers = map f $ sections (~== TagOpen "li" [("class","paper")]) tags
        putStr $ unlines papers
    where
        f :: [Tag] -> String
        f xs = innerText (xs !! 2)


currentTime :: IO ()
currentTime = do
        tags <- liftM parseTagsNoPos $ openURL "http://www.timeanddate.com/worldclock/city.html?n=136"
        let time = innerText (dropWhile (~/= TagOpen "strong" [("id","ct")]) tags !! 1)
        putStrLn time



type Section = String
data Package = Package {name :: String, desc :: String, href :: String}
               deriving Show

hackage :: IO [(Section,[Package])]
hackage = do
    tags <- liftM parseTagsNoPos $ openURL "http://hackage.haskell.org/packages/archive/pkg-list.html"
    return $ map parseSect $ partitions (isTagOpenName "h3") tags
    where
        parseSect xs = (nam, packs)
            where
                nam = innerText $ xs !! 2
                packs = map parsePackage $ partitions (isTagOpenName "li") xs

        parsePackage xs = Package (innerText $ xs !! 2)
                                  (drop 2 $ dropWhile (/= ':') $ innerText $ xs !! 4)
                                  (fromAttrib "href" $ xs !! 1)

-- getTagContent Example ( prints content of first td as text
-- should print "header"
getTagContentExample :: IO ()
getTagContentExample = print . innerText . getTagContent "tr" [] $
  parseTagsNoPos "<table><tr><td><th>header</th></td><td></tr><tr><td>2</td></tr>...</table>"

tests :: IO ()
tests =
  if and [
        TagText "test" ~== TagText ""
      , TagText "test" ~== TagText "test"
      , TagText "test" ~== TagText "soup" == False
      , TagOpen "table" [ ("id", "name")] ~== TagOpen "table" []
      , TagOpen "table" [ ("id", "name")] ~== TagOpen "table"[ ("id", "name")]
      , TagOpen "table" [ ("id", "name")] ~== TagOpen "table"[ ("id", "")]
      , TagOpen "table" [ ("id", "other name")] ~== TagOpen "table"[ ("id", "name")] == False
      , TagOpen "table" [] ~== "table"
      , TagClose "table"   ~== "/table"
      , TagOpen "table" [( "id", "frog")] ~== "table id=frog"
      ]
    then print "test successful"
    else print "test failed !!"

