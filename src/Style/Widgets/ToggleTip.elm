module Style.Widgets.ToggleTip exposing (toggleTip)

import Element
import Element.Border as Border
import Element.Events as Events
import Element.Font as Font
import FeatherIcons
import Html.Attributes
import Set
import Style.Helpers as SH exposing (spacer)
import Style.Types exposing (ExoPalette)
import Style.Widgets.Popover.Popover exposing (popover)
import Style.Widgets.Popover.Types exposing (PopoverId)


toggleTip :
    { viewContext | palette : ExoPalette, showPopovers : Set.Set PopoverId }
    -> (PopoverId -> msg)
    -> PopoverId
    -> Element.Element msg
    -> Style.Types.PopoverPosition
    -> Element.Element msg
toggleTip context msgMapper id content position =
    let
        tipStyle =
            [ Element.htmlAttribute (Html.Attributes.style "pointerEvents" "none")
            , Border.rounded 4
            , Font.color (SH.toElementColor context.palette.neutral.text.subdued)
            , Font.size 15
            ]

        btnClickOrHoverStyle =
            [ -- darken the icon color
              Font.color (context.palette.neutral.text.default |> SH.toElementColor)
            ]

        tipIconBtn toggleMsg tipIsShown =
            FeatherIcons.info
                |> FeatherIcons.withSize 20
                |> FeatherIcons.toHtml []
                |> Element.html
                |> Element.el
                    ([ Element.paddingXY spacer.px4 0
                     , Events.onClick toggleMsg
                     , Element.pointer
                     , Font.color (context.palette.neutral.icon |> SH.toElementColor)
                     , Element.mouseOver btnClickOrHoverStyle
                     ]
                        ++ (if tipIsShown then
                                btnClickOrHoverStyle

                            else
                                []
                           )
                    )
    in
    popover context
        msgMapper
        { id = id
        , content = \_ -> content
        , contentStyleAttrs = tipStyle
        , position = position
        , distanceToTarget = Nothing
        , target = tipIconBtn
        , targetStyleAttrs = []
        }
