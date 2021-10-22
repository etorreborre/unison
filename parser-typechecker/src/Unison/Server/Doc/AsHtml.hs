{-| Render Unison.Server.Doc and embedded source to Html
-}
{-# LANGUAGE OverloadedStrings #-}

module Unison.Server.Doc.AsHtml where

import Data.Maybe
import Data.Text (Text)
import qualified Data.Text as Text
import Unison.Codebase.Editor.DisplayObject (DisplayObject (..))
import Unison.Server.Doc
import Unison.Server.Syntax (SyntaxText)
import qualified Unison.Server.Syntax as Syntax
import Lucid
import qualified Lucid as L
import Data.Foldable

data NamedLinkHref
  = Href Text
  | ReferenceHref Text
  | InvalidHref

data EmbeddedSource
  = EmbeddedSource SyntaxText SyntaxText
  | Builtin SyntaxText

embeddedSource :: Ref (UnisonHash, DisplayObject SyntaxText Src) -> Maybe EmbeddedSource
embeddedSource ref =
  let embeddedSource' (_, displayObj) =
        case displayObj of
          BuiltinObject s -> Just (Builtin s)
          UserObject (Src sum det) -> Just (EmbeddedSource sum det)
          MissingObject _ -> Nothing
   in case ref of
        Term s -> embeddedSource' s
        Type s -> embeddedSource' s

inlineCode :: [Attribute] -> Html () -> Html ()
inlineCode attrs =
  pre_ (class_ "inline-code" : attrs) . code_ []

codeBlock :: [Attribute] -> Html () -> Html ()
codeBlock attrs =
  pre_ attrs . code_ []

normalizeHref :: NamedLinkHref -> Doc -> NamedLinkHref
normalizeHref href doc =
  case doc of
    Word w ->
      case href of
        InvalidHref ->
          Href w
        Href h ->
          Href (h <> w)
        ReferenceHref _ ->
          href
    Group d_ ->
      normalizeHref href d_
    Join ds ->
      foldl' normalizeHref href ds

    Special (Link syntax) ->
      let folder acc seg =
            case acc of
              Nothing ->
                Syntax.reference seg
              _ ->
                acc
       in maybe InvalidHref ReferenceHref (Syntax.foldl folder Nothing syntax)
    _ ->
      href

data IsFolded
  = IsFolded Bool [Html ()] [Html ()]
  | Disabled (Html ())

foldedToHtml :: [Attribute] -> IsFolded -> Html ()
foldedToHtml attrs isFolded =
  case isFolded of
    Disabled summary ->
      details_ attrs $ summary_ summary
    IsFolded isFolded summary details ->
      let attrsWithOpen =
            if isFolded
              then open_ "open" : attrs
              else attrs
       in details_ attrsWithOpen $ summary_ [] $ sequence_ $ summary ++ details

foldedToHtmlSource :: Bool -> EmbeddedSource -> Html ()
foldedToHtmlSource isFolded source =
  case source of
    Builtin summary ->
      foldedToHtml
        [class_ "rich source"]
        ( Disabled
            ( div_
                [class_ "builtin-summary"] $ do
                  codeBlock [] $ Syntax.toHtml summary
                  badge $ do
                    span_ [] $ strong_ [] "Built-in"
                    span_ [] "provided by the Unison runtime"
                
            )
        )
    EmbeddedSource summary details ->
      foldedToHtml [class_ "rich source"] $ IsFolded
            isFolded
            [codeBlock [] $ Syntax.toHtml summary]
            [codeBlock [] $ Syntax.toHtml details]
        

{-| Merge adjacent Word elements in a list to 1 element with a string of words
separated by space— useful for rendering to the dom without creating dom
elements for each and every word in the doc, but instead rely on textNodes 
-}
mergeWords :: [Doc] -> [Doc]
mergeWords = foldr merge_ [] where
  merge_ :: Doc -> [Doc] -> [Doc]
  merge_ d acc =
    case (d, acc) of
      (Word w, Word w_ : rest) ->
          Word (w <> " " <> w_) : rest

      _ ->
            d : acc

toHtml :: Doc -> Html ()
toHtml document =
  let toHtml_ sectionLevel doc =
        let -- Make it simple to retain the sectionLevel when recurring.
            -- the Section variant increments it locally
            currentSectionLevelToHtml =
              toHtml_ sectionLevel

            sectionContentToHtml renderer doc_ =
              case doc_ of
                Paragraph _ ->
                  p_ [] $ renderer doc_
                _ ->
                  renderer doc_
         in case doc of
              Word word ->
                span_ [class_ "word"] (L.toHtml word)
              Code code ->
                span_ [class_ "rich source inline-code"] $ inlineCode [] (currentSectionLevelToHtml code)
              CodeBlock lang code ->
                div_ [class_ "rich source code", class_ $ textToClass lang] $ codeBlock [] (currentSectionLevelToHtml code)
              Bold d ->
                strong_ [] $ currentSectionLevelToHtml d
              Italic d ->
                span_ [class_ "italic"] $ currentSectionLevelToHtml d
              Strikethrough d ->
                span_ [class_ "strikethrough"] $ currentSectionLevelToHtml d
              Style cssclass_ d ->
                span_ [class_ $ textToClass cssclass_] $ currentSectionLevelToHtml d
              Anchor id' d ->
                a_ [id_ id', target_ id'] $ currentSectionLevelToHtml d
              Blockquote d ->
                blockquote_ [] $ currentSectionLevelToHtml d
              Blankline ->
                div_ [] $ do 
                  br_ []
                  br_ []
              Linebreak ->
                br_ []
              SectionBreak ->
                hr_ []
              Tooltip triggerContent tooltipContent ->
                span_
                  [class_ "tooltip below arrow-start"] $ do
                    span_ [class_ "tooltip-trigger"] $ currentSectionLevelToHtml triggerContent
                    div_ [class_ "tooltip-bubble", style_ "display: none"] $ currentSectionLevelToHtml tooltipContent
                  
              Aside d ->
                span_
                  [class_ "aside-anchor"] $
                    aside_ [] $ currentSectionLevelToHtml d
                  
              Callout icon content ->
                let (cls, ico) =
                      case icon of
                        Just (Word emoji) ->
                          (class_ "callout callout-with-icon", div_ [class_ "callout-icon"] $ L.toHtml emoji)
                        _ ->
                          (class_ "callout", "")
                 in div_ [cls] $ do
                      ico
                      div_ [class_ "callout-content"] $ currentSectionLevelToHtml content
              Table rows ->
                let cellToHtml =
                      td_ [] . currentSectionLevelToHtml

                    rowToHtml cells =
                      tr_ [] $ mapM_ cellToHtml $ mergeWords cells
                 in table_ [] $ tbody_ [] $ mapM_ rowToHtml rows
              Folded isFolded summary details ->
                let content =
                      if isFolded
                        then [currentSectionLevelToHtml summary]
                        else
                          [ currentSectionLevelToHtml summary,
                            currentSectionLevelToHtml details
                          ]
                 in foldedToHtml [] (IsFolded isFolded content [])
              Paragraph docs ->
                case docs of
                  [d] ->
                    currentSectionLevelToHtml d
                  ds ->
                    span_ [class_ "span"] $ mapM_ currentSectionLevelToHtml $ mergeWords ds
              BulletedList items ->
                let itemToHtml  =
                      li_ [] . currentSectionLevelToHtml
                 in ul_ [] $ mapM_ itemToHtml $ mergeWords items
              NumberedList startNum items ->
                let itemToHtml  =
                      li_ [] . currentSectionLevelToHtml
                 in ol_ [start_ $ Text.pack $ show startNum] $ mapM_ itemToHtml $ mergeWords items
              Section title docs ->
                let titleEl = 
                      h sectionLevel $ currentSectionLevelToHtml title
                 in section_ [] $ sequence_ (titleEl : map (sectionContentToHtml (toHtml_ (sectionLevel + 1))) docs)
              NamedLink label href ->
                case normalizeHref InvalidHref href of
                  Href h ->
                    a_ [class_ "named-link", href_ h, rel_ "noopener", target_ "_blank"] $ currentSectionLevelToHtml label
                  ReferenceHref ref ->
                    a_ [class_ "named-link", data_ "ref" ref] $ currentSectionLevelToHtml label
                  InvalidHref ->
                    span_ [class_ "named-link invalid-href"] $ currentSectionLevelToHtml label
              Image altText src caption ->
                let altAttr =
                      case altText of
                        Word t ->
                          [alt_ t]
                        _ ->
                          []

                    image =
                      case src of
                        Word s ->
                          img_ (altAttr ++ [src_ s ])
                        _ ->
                          ""

                    imageWithCaption c =
                      div_
                        [class_ "image-with-caption"] $ do
                          image
                          div_ [class_ "caption"] $ currentSectionLevelToHtml c
                 in maybe image imageWithCaption caption
              Special specialForm ->
                case specialForm of
                  Source sources ->
                    let
                      sources' =
                        mapMaybe 
                          (fmap (foldedToHtmlSource False) . embeddedSource)
                          sources
                    in
                    div_ [class_ "folded-sources"] $ sequence_ sources'
                  FoldedSource sources ->
                    let
                      sources' =
                        mapMaybe 
                          (fmap (foldedToHtmlSource True) . embeddedSource)
                          sources
                    in
                    div_ [class_ "folded-sources"] $ sequence_ sources'
                  Example syntax ->
                    span_ [class_ "source rich example-inline"] $ inlineCode [] (Syntax.toHtml syntax)
                  ExampleBlock syntax ->
                    div_ [class_ "source rich example"] $ codeBlock [] (Syntax.toHtml syntax)
                  Link syntax ->
                    inlineCode [class_ "rich source"] (Syntax.toHtml syntax)
                  Signature signatures ->
                    div_
                      [class_ "rich source signatures"]
                      ( mapM_
                          (div_ [class_ "signature"] . Syntax.toHtml)
                          signatures
                      )
                  SignatureInline sig ->
                    span_ [class_ "rich source signature-inline"] $ Syntax.toHtml sig
                  Eval source result ->
                    div_ [class_ "source rich eval"] $
                      codeBlock [] $
                        div_ [] $ do 
                          Syntax.toHtml source
                          div_ [class_ "result"] $ do
                            "⧨"
                            div_ [] $ Syntax.toHtml result
                  EvalInline source result ->
                    span_ [class_ "source rich eval-inline"] $
                      inlineCode [] $
                        span_ [] $ do
                          Syntax.toHtml source
                          span_ [class_ "result"] $ do
                            "⧨"
                            Syntax.toHtml result
                  Embed syntax ->
                    div_ [class_ "source rich embed"] $ codeBlock [] (Syntax.toHtml syntax)
                  EmbedInline syntax ->
                    span_ [class_ "source rich embed-inline"] $ inlineCode [] (Syntax.toHtml syntax)
              Join docs ->
                span_ [class_ "join"] (mapM_ currentSectionLevelToHtml (mergeWords docs))
              UntitledSection docs ->
                section_ [] (mapM_ (sectionContentToHtml currentSectionLevelToHtml) docs)
              Column docs ->
                ul_
                  [class_ "column"]
                  ( mapM_
                      (li_ [] . currentSectionLevelToHtml)
                      (mergeWords docs)
                  )
              Group content ->
                span_ [class_ "group"] $ currentSectionLevelToHtml content
   in article_ [class_ "unison-doc"] $ toHtml_ 1 document

-- HELPERS --------------------------------------------------------------------

{-| Unison Doc allows endlessly deep section nesting with
titles, but HTML only supports to h1-h6, so we clamp
the sectionLevel when converting
-}
h :: Nat -> (Html () -> Html ())
h n =
  case n of
    1 -> h1_
    2 -> h2_
    3 -> h3_
    4 -> h4_
    5 -> h5_
    6 -> h6_
    _ -> h6_

badge :: Html () -> Html ()
badge =
  span_ [class_ "badge"]

textToClass :: Text -> Text
textToClass =
  Text.replace " " "__"
