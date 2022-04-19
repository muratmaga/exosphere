module DesignSystem.Stories.ColorPalette exposing (stories)

import Color
import Color.Convert exposing (colorToHex)
import Element
import Element.Background as Background
import Element.Font as Font
import Html
import Style.Helpers as SH
import Style.Types
import Style.Widgets.Text as Text
import UIExplorer exposing (storiesOf)
import UIExplorer.ColorMode exposing (ColorMode(..))


{-| Creates stores for UIExplorer.

    renderer – An elm-ui to html converter
    palette  – Takes a UIExplorer.Model and produces an ExoPalette
    plugins  – UIExplorer plugins (can be empty {})

-}
stories : (Style.Types.ExoPalette -> Element.Element msg -> Html.Html msg) -> (UIExplorer.Model { model | deployerColors : Style.Types.DeployerColorThemes } msg plugins -> Style.Types.ExoPalette) -> plugins -> UIExplorer.UI { model | deployerColors : Style.Types.DeployerColorThemes } msg plugins
stories renderer palette plugins =
    storiesOf
        "Color Palette"
        [ ( "brand"
          , \m ->
                renderer (palette m) <|
                    collection
                        [ swatch
                            [ namedBlock "primary" <| (palette m).primary
                            , namedBlock "secondary" <| (palette m).secondary
                            , namedBlock "background" <| (palette m).background
                            , namedBlock "surface" <| (palette m).surface
                            , namedBlock "error" <| (palette m).error
                            , namedBlock "warn" <| (palette m).warn
                            , namedBlock "readyGood" <| (palette m).readyGood
                            , namedBlock "muted" <| (palette m).muted
                            ]
                        , swatch
                            [ namedBlock "on.primary" <| (palette m).on.primary
                            , namedBlock "on.secondary" <| (palette m).on.secondary
                            , namedBlock "on.background" <| (palette m).on.background
                            , namedBlock "on.surface" <| (palette m).on.surface
                            , namedBlock "on.error" <| (palette m).on.error
                            , namedBlock "on.warn" <| (palette m).on.warn
                            , namedBlock "on.readyGood" <| (palette m).on.readyGood
                            , namedBlock "on.muted" <| (palette m).on.muted
                            ]
                        , swatch
                            [ wcagBlock "primary" (palette m).on.primary (palette m).primary
                            , wcagBlock "secondary" (palette m).on.secondary (palette m).secondary
                            , wcagBlock "background" (palette m).on.background (palette m).background
                            , wcagBlock "surface" (palette m).on.surface (palette m).surface
                            , wcagBlock "error" (palette m).on.error (palette m).error
                            , wcagBlock "warn" (palette m).on.warn (palette m).warn
                            , wcagBlock "readyGood" (palette m).on.readyGood (palette m).readyGood
                            , wcagBlock "muted" (palette m).on.muted (palette m).muted
                            ]
                        ]
          , plugins
          )
        , ( "menu"
          , \m ->
                renderer (palette m) <|
                    collection
                        [ swatch
                            [ namedBlock "background" <| (palette m).menu.background
                            , namedBlock "surface" <| (palette m).menu.surface
                            , namedBlock "secondary" <| (palette m).menu.secondary
                            ]
                        , swatch
                            [ namedBlock "on.background" <| (palette m).menu.on.background
                            , namedBlock "on.surface" <| (palette m).menu.on.surface
                            ]
                        , swatch
                            [ wcagBlock "background" (palette m).menu.on.background (palette m).menu.background
                            , wcagBlock "surface" (palette m).menu.on.surface (palette m).menu.surface
                            ]
                        ]
          , plugins
          )

        --TODO: material palette
        ]


{-| The size of the square blocks in the view.
-}
blockSize : number
blockSize =
    120


{-| A square block of a solid color.
-}
block : Color.Color -> Element.Element msg
block color =
    Element.row
        [ Background.color <| SH.toElementColor <| color
        , Element.width (Element.px blockSize)
        , Element.height (Element.px blockSize)
        ]
        []


{-| A labelled block with its hex colour code.
-}
namedBlock : String -> Color.Color -> Element.Element msg
namedBlock label color =
    Element.column
        [ Element.spacing 4 ]
        [ block color, Text.bold label, Text.mono <| colorToHex color ]


{-| This WCAG content block uses foreground & background palette colours to test readability.

---

WCAG are Web Content Accessibility Guidelines.
(Check out the [official quick reference](https://www.w3.org/WAI/WCAG21/quickref/) or
read a [summary on Wikipedia](https://en.wikipedia.org/wiki/Web_Content_Accessibility_Guidelines).)

In particular, this visual test supports:

**Guideline 1.4 – Distinguishable**
"Make it easier for users to see and hear content including separating foreground from background."

-}
wcagBlock : String -> Color.Color -> Color.Color -> Element.Element msg
wcagBlock label foreground background =
    Element.row
        [ Background.color <| SH.toElementColor <| background
        , Element.width (Element.px blockSize)
        , Element.height (Element.px blockSize)
        ]
        [ Text.text Text.Body [ Font.color <| SH.toElementColor <| foreground, Element.centerX ] label ]


{-| A row of colored blocks, like a color swatch.
-}
swatch : List (Element.Element msg) -> Element.Element msg
swatch blocks =
    Element.row
        [ Element.spacing 10 ]
        blocks


{-| A row of colored blocks, like a color swatch.
-}
collection : List (Element.Element msg) -> Element.Element msg
collection swatches =
    Element.column
        [ Element.spacing 30 ]
        swatches
