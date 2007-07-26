{-
Copyright (C) 2006-7 John MacFarlane <jgm@berkeley.edu>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
-}

{- |
   Module      : Text.Pandoc.Writers.HTML 
   Copyright   : Copyright (C) 2006-7 John MacFarlane
   License     : GNU GPL, version 2 or above 

   Maintainer  : John MacFarlane <jgm@berkeley.edu>
   Stability   : alpha
   Portability : portable

Conversion of 'Pandoc' documents to HTML.
-}
module Text.Pandoc.Writers.HTML ( writeHtml, writeHtmlString ) where
import Text.Pandoc.Definition
import Text.Pandoc.ASCIIMathML
import Text.Pandoc.Shared
import Text.Pandoc.Entities (decodeEntities)
import Text.Regex ( mkRegex, matchRegex )
import Numeric ( showHex )
import Data.Char ( ord, toLower )
import Data.List ( isPrefixOf, partition, intersperse )
import Control.Monad.State
import Text.XHtml.Strict

data WriterState = WriterState
    { stNotes            :: [Html]   -- ^ List of notes
    , stIds              :: [String] -- ^ List of header identifiers
    , stHead             :: [Html]   -- ^ Html to include in header
    } deriving Show

-- | Convert Pandoc document to Html string.
writeHtmlString :: WriterOptions -> Pandoc -> String
writeHtmlString opts = 
  if writerStandalone opts
     then renderHtml . (writeHtml opts)
     else renderHtmlFragment . (writeHtml opts)

-- | Convert Pandoc document to Html structure.
writeHtml :: WriterOptions -> Pandoc -> Html
writeHtml opts (Pandoc (Meta tit authors date) blocks) = 
  let titlePrefix = writerTitlePrefix opts
      topTitle    = evalState (inlineListToHtml opts tit) 
                    (WriterState {stNotes = [], stIds = [], stHead = []})
      topTitle'   = if null titlePrefix
                        then topTitle
                        else titlePrefix +++ " - " +++ topTitle
      metadata    = thetitle topTitle' +++ 
                    meta ! [httpequiv "Content-Type", 
                            content "text/html; charset=UTF-8"] +++
                    meta ! [name "generator", content "pandoc"] +++
                    (toHtmlFromList $ 
                    map (\a -> meta ! [name "author", content a]) authors) +++
                    (if null date
                       then noHtml
                       else meta ! [name "date", content date]) 
      titleHeader = if (writerStandalone opts) && (not (null tit)) && 
                    (not (writerS5 opts))
                        then h1 ! [theclass "title"] $ topTitle
                        else noHtml
      headerBlocks = filter isHeaderBlock blocks
      ids = uniqueIdentifiers $ map (\(Header _ lst) -> lst) headerBlocks
      toc = if writerTableOfContents opts 
               then tableOfContents opts headerBlocks ids
               else noHtml
      (blocks', newstate) = 
                    runState (blockListToHtml opts blocks)
                    (WriterState {stNotes = [], stIds = ids, stHead = []})
      head        = header $ metadata +++ toHtmlFromList (stHead newstate) +++ 
                             primHtml (writerHeader opts)
      notes       = reverse (stNotes newstate)
      before      = primHtml $ writerIncludeBefore opts
      after       = primHtml $ writerIncludeAfter opts
      thebody     = before +++ titleHeader +++ toc +++ blocks' +++
                    footnoteSection opts notes +++ after
  in  if writerStandalone opts
         then head +++ (body thebody)
         else thebody

-- | Construct table of contents from list of header blocks and identifiers.
-- Assumes there are as many identifiers as header blocks.
tableOfContents :: WriterOptions -> [Block] -> [String] -> Html
tableOfContents opts headers ids =
  let opts' = opts { writerIgnoreNotes = True }
      contentsTree = hierarchicalize headers
      contents = evalState (mapM (elementToListItem opts') contentsTree) 
                 (WriterState {stNotes= [], stIds = ids, stHead = []})
  in  thediv ! [identifier "toc"] $ unordList contents

-- | Converts an Element to a list item for a table of contents,
-- retrieving the appropriate identifier from state.
elementToListItem :: WriterOptions -> Element -> State WriterState Html
elementToListItem opts (Blk _) = return noHtml
elementToListItem opts (Sec headerText subsecs) = do
  st <- get
  let ids = stIds st
  let (id, rest) = if null ids
                      then ("", [])
                      else (head ids, tail ids)
  put $ st {stIds = rest}
  txt <- inlineListToHtml opts headerText
  subHeads <- mapM (elementToListItem opts) subsecs
  let subList = if null subHeads
                   then noHtml
                   else unordList subHeads 
  return $ (anchor ! [href ("#" ++ id), identifier ("TOC-" ++ id)] $ txt) +++ subList

-- | Convert list of Note blocks to a footnote <div>.
-- Assumes notes are sorted.
footnoteSection :: WriterOptions -> [Html] -> Html
footnoteSection opts notes =
  if null notes 
     then noHtml
     else thediv ! [theclass "footnotes"] $
                   hr +++ (olist << notes)

-- | Obfuscate a "mailto:" link using Javascript.
obfuscateLink :: WriterOptions -> Html -> String -> Html
obfuscateLink opts text src =
  let emailRegex = mkRegex "mailto:*([^@]*)@(.*)"
      text' = show $ text
      src'  = map toLower src in
  case (matchRegex emailRegex src') of
    (Just [name, domain]) ->
      let domain'  = substitute "." " dot " domain
          at'      = obfuscateChar '@'
          linkText = if src' == ("mailto:" ++ text')
                        then "e"
                        else "'" ++ text' ++ "'" 
          altText  = if src' == ("mailto:" ++ text')
                        then name ++ " at " ++ domain'
                        else text' ++ " (" ++ name ++ " at " ++ 
                             domain' ++ ")" in 
      if writerStrictMarkdown opts
        then -- need to use primHtml or &'s are escaped to &amp; in URL
             primHtml $ "<a href=\"" ++ (obfuscateString src')
             ++ "\">" ++ (obfuscateString text') ++ "</a>"
        else (script ! [thetype "text/javascript"] $
             primHtml ("\n<!--\nh='" ++ 
             obfuscateString domain ++ "';a='" ++ at' ++ "';n='" ++ 
             obfuscateString name ++ "';e=n+a+h;\n" ++
             "document.write('<a h'+'ref'+'=\"ma'+'ilto'+':'+e+'\">'+" ++ 
             linkText  ++ "+'<\\/'+'a'+'>');\n// -->\n")) +++  
             noscript (primHtml $ obfuscateString altText)
    _ -> anchor ! [href src] $ text  -- malformed email

-- | Obfuscate character as entity.
obfuscateChar :: Char -> String
obfuscateChar char = 
  let num = ord char in
  let numstr = if even num then (show num) else ("x" ++ (showHex num "")) in
  "&#" ++ numstr ++ ";"

-- | Obfuscate string using entities.
obfuscateString :: String -> String
obfuscateString = (concatMap obfuscateChar) . decodeEntities

-- | True if character is a punctuation character (unicode).
isPunctuation :: Char -> Bool
isPunctuation c =
  let c' = ord c in
  if (c `elem` "!\"'()*,-./:;<>?[\\]`{|}~") || (c' >= 0x2000 && c' <= 0x206F) ||
     (c' >= 0xE000 && c' <= 0xE0FF)
     then True
     else False

-- | Add Html to document header.
addToHeader :: Html -> State WriterState ()
addToHeader item = do
  st <- get
  let current = stHead st
  put $ st {stHead = (item:current)}

-- | Convert Pandoc inline list to plain text identifier.
inlineListToIdentifier :: [Inline] -> String
inlineListToIdentifier [] = ""
inlineListToIdentifier (x:xs) = 
  xAsText ++ inlineListToIdentifier xs
  where xAsText = case x of
                       Str s          -> filter 
                                         (\c -> (c == '-') || not (isPunctuation c)) $
                                         concat $ intersperse "-" $ words $ map toLower s
                       Emph lst       -> inlineListToIdentifier lst
                       Strikeout lst  -> inlineListToIdentifier lst
                       Superscript lst -> inlineListToIdentifier lst
                       Subscript lst  -> inlineListToIdentifier lst
                       Strong lst     -> inlineListToIdentifier lst
                       Quoted _ lst   -> inlineListToIdentifier lst
                       Code s         -> s
                       Space          -> "-"
                       EmDash         -> "-"
                       EnDash         -> "-"
                       Apostrophe     -> ""
                       Ellipses       -> ""
                       LineBreak      -> "-"
                       TeX _          -> ""
                       HtmlInline _   -> ""
                       Link lst _     -> inlineListToIdentifier lst
                       Image lst _    -> inlineListToIdentifier lst
                       Note _         -> ""

-- | Return unique identifiers for list of inline lists.
uniqueIdentifiers :: [[Inline]] -> [String]
uniqueIdentifiers ls =
  let addIdentifier (nonuniqueIds, uniqueIds) l =
        let new = inlineListToIdentifier l
            matches = length $ filter (== new) nonuniqueIds
            new' = new ++ if matches > 0 then ("-" ++ show matches) else ""
        in  (new:nonuniqueIds, new':uniqueIds)
  in  reverse $ snd (foldl addIdentifier ([],[]) $ ls)

-- | Convert Pandoc block element to HTML.
blockToHtml :: WriterOptions -> Block -> State WriterState Html
blockToHtml opts block = 
  case block of
    (Null)            -> return $ noHtml
    (Plain lst)       -> inlineListToHtml opts lst
    (Para lst)        -> inlineListToHtml opts lst >>= (return . paragraph)
    (RawHtml str)     -> return $ primHtml str
    (HorizontalRule)  -> return $ hr
    (CodeBlock str)   -> return $ pre $ thecode << (str ++ "\n") 
                       -- the final \n for consistency with Markdown.pl
    (BlockQuote blocks) ->  -- in S5, treat list in blockquote specially
                            -- if default is incremental, make it nonincremental; 
                            -- otherwise incremental
       if writerS5 opts
          then let inc = not (writerIncremental opts) in
               case blocks of 
                  [BulletList lst]  -> blockToHtml (opts {writerIncremental = inc})
                                       (BulletList lst)
                  [OrderedList lst] -> blockToHtml (opts {writerIncremental = inc})
                                       (OrderedList lst)
                  otherwise         -> blockListToHtml opts blocks >>= 
                                       (return . blockquote)
          else blockListToHtml opts blocks >>= (return . blockquote)
    (Header level lst) -> do contents <- inlineListToHtml opts lst
                             st <- get
                             let ids = stIds st
                             let (id, rest) = if null ids
                                                 then ("", [])
                                                 else (head ids, tail ids)
                             put $ st {stIds = rest}
                             let attribs = [identifier id]
                             let headerHtml = case level of
                                         1 -> h1 contents ! attribs
                                         2 -> h2 contents ! attribs
                                         3 -> h3 contents ! attribs
                                         4 -> h4 contents ! attribs
                                         5 -> h5 contents ! attribs
                                         6 -> h6 contents ! attribs
                                         _ -> paragraph contents ! attribs
                             let headerHtml' = if writerTableOfContents opts
                                                  then anchor ! [href ("#TOC-" ++ id)] $
                                                       headerHtml
                                                  else headerHtml
                             return headerHtml'
    (BulletList lst)   -> do contents <- mapM (blockListToHtml opts) lst
                             let attribs = if writerIncremental opts
                                              then [theclass "incremental"]
                                              else []
                             return $ unordList ! attribs $ contents
    (OrderedList lst)  -> do contents <- mapM (blockListToHtml opts) lst
                             let attribs = if writerIncremental opts
                                              then [theclass "incremental"]
                                              else []
                             return $ ordList ! attribs $ contents
    (DefinitionList lst) -> do contents <- mapM (\(term, def) ->
                                                 do term' <- inlineListToHtml opts term
                                                    def' <- blockListToHtml opts def
                                                    return $ (term', def'))
                                                 lst
                               let attribs = if writerIncremental opts
                                                then [theclass "incremental"]
                                                else []
                               return $ defList ! attribs $ contents
    (Table capt aligns widths headers rows) ->
                            do let alignStrings = map alignmentToString aligns
                               captionDoc <- if null capt
                                                then return noHtml
                                                else inlineListToHtml opts capt >>=
                                                     (return . caption)
                               colHeads <- colHeadsToHtml opts alignStrings 
                                                          widths headers
                               rows' <- mapM (tableRowToHtml opts alignStrings) rows
                               return $ table $ captionDoc +++ colHeads +++ rows'

colHeadsToHtml opts alignStrings widths headers =
  do heads <- sequence $ zipWith3 
                         (\align width item -> tableItemToHtml opts th align width item) 
                         alignStrings widths headers
     return $ tr $ toHtmlFromList heads

alignmentToString alignment = case alignment of
                                 AlignLeft    -> "left"
                                 AlignRight   -> "right"
                                 AlignCenter  -> "center"
                                 AlignDefault -> "left"

tableRowToHtml opts aligns cols =
  do contents <- sequence $ zipWith3 (tableItemToHtml opts td) aligns (repeat 0) cols 
     return $ tr $ toHtmlFromList contents

tableItemToHtml opts tag align' width item =
  do contents <- blockListToHtml opts item
     let attrib = [align align'] ++ 
                  if (width /= 0) 
                    then [thestyle ("{width: " ++ show (truncate (100*width)) ++ "%;}")]
                    else [] 
     return $ tag ! attrib $ contents

blockListToHtml :: WriterOptions -> [Block] -> State WriterState Html
blockListToHtml opts lst = mapM (blockToHtml opts) lst >>= (return . toHtmlFromList)

-- | Convert list of Pandoc inline elements to HTML.
inlineListToHtml :: WriterOptions -> [Inline] -> State WriterState Html
inlineListToHtml opts lst = mapM (inlineToHtml opts) lst >>= (return . toHtmlFromList)

-- | Convert Pandoc inline element to HTML.
inlineToHtml :: WriterOptions -> Inline -> State WriterState Html
inlineToHtml opts inline =
  case inline of  
    (Str str)        -> return $ stringToHtml str
    (Space)          -> return $ stringToHtml " "
    (LineBreak)      -> return $ br
    (EmDash)         -> return $ primHtmlChar "mdash"
    (EnDash)         -> return $ primHtmlChar "ndash"
    (Ellipses)       -> return $ primHtmlChar "hellip"
    (Apostrophe)     -> return $ primHtmlChar "rsquo"
    (Emph lst)       -> inlineListToHtml opts lst >>= (return . emphasize)
    (Strong lst)     -> inlineListToHtml opts lst >>= (return . strong)
    (Code str)       -> return $ thecode << str
    (Strikeout lst)  -> addToHeader (style ! [thetype "text/css"] $ (stringToHtml 
                        ".strikeout { text-decoration: line-through; }")) >> 
                        inlineListToHtml opts lst >>=
                        (return . (thespan ! [theclass "strikeout"]))
    (Superscript lst) -> inlineListToHtml opts lst >>= (return . sup)
    (Subscript lst)   -> inlineListToHtml opts lst >>= (return . sub)
    (Quoted quoteType lst) ->
                        let (leftQuote, rightQuote) = case quoteType of
                              SingleQuote -> (primHtmlChar "lsquo", 
                                              primHtmlChar "rsquo")
                              DoubleQuote -> (primHtmlChar "ldquo", 
                                              primHtmlChar "rdquo") in 
                        do contents <- inlineListToHtml opts lst
                           return $ leftQuote +++ contents +++ rightQuote
    (TeX str)        -> do if writerUseASCIIMathML opts
                              then addToHeader $
                                   case writerASCIIMathMLURL opts of
                                        Just path -> script !  [src path, 
                                                     thetype "text/javascript"] $
                                                     noHtml
                                        Nothing   -> primHtml asciiMathMLScript
                              else return ()
                           return $ stringToHtml str
    (HtmlInline str) -> return $ primHtml str 
    (Link txt (src,tit)) ->
                        do linkText <- inlineListToHtml opts txt
                           return $ if (isPrefixOf "mailto:" src)
                                      then obfuscateLink opts linkText src 
                                      else anchor ! ([href src] ++ 
                                                     if null tit 
                                                        then [] 
                                                        else [title tit]) $ 
                                           linkText
    (Image txt (source,tit)) ->
                        do alternate <- inlineListToHtml opts txt
                           let alternate' = renderHtmlFragment alternate
                           let attributes = [src source, title tit] ++ 
                                            if null txt then [] else [alt alternate']
                           return $ image ! attributes 
                           -- note:  null title included, as in Markdown.pl 
    (Note contents)  -> do st <- get
                           let notes = stNotes st
                           let number = (length notes) + 1
                           let ref = show number
                           htmlContents <- blockListToNote opts ref contents 
                           put $ st {stNotes = (htmlContents:notes)} -- push contents onto front of notes
                           return $ anchor ! [href ("#fn" ++ ref),
                                              theclass "footnoteRef",
                                              identifier ("fnref" ++ ref)] << sup << ref

blockListToNote :: WriterOptions -> String -> [Block] -> State WriterState Html
blockListToNote opts ref blocks =
  -- If last block is Para or Plain, include the backlink at the end of
  -- that block. Otherwise, insert a new Plain block with the backlink.
  let backlink = [HtmlInline $ " <a href=\"#fnref" ++ ref ++ 
                 "\" class=\"footnoteBackLink\"" ++
                 " title=\"Jump back to footnote " ++ ref ++ "\">&#8617;</a>"]
      blocks'  = if null blocks
                    then []
                    else let lastBlock   = last blocks
                             otherBlocks = init blocks
                         in  case lastBlock of
                                  (Para lst)  -> otherBlocks ++
                                                 [Para (lst ++ backlink)]
                                  (Plain lst) -> otherBlocks ++
                                                 [Plain (lst ++ backlink)]
                                  _           -> otherBlocks ++ [lastBlock,
                                                 Plain backlink]
  in do contents <- blockListToHtml opts blocks'
        return $ li ! [identifier ("fn" ++ ref)] $ contents
