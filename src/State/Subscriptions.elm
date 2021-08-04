module State.Subscriptions exposing (subscriptions)

import Browser.Events
import Time
import Types.Msg exposing (Msg(..))
import Types.Types
    exposing
        ( SharedModel
        )


subscriptions : SharedModel -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every (5 * 1000) (Tick 5)
        , Time.every (10 * 1000) (Tick 10)
        , Time.every (60 * 1000) (Tick 60)
        , Time.every (300 * 1000) (Tick 300)
        , Browser.Events.onResize MsgChangeWindowSize
        ]
