module OpenStack.ConsoleLog exposing (requestConsoleLog)

import Helpers.Error exposing (ErrorContext, ErrorLevel(..))
import Helpers.Helpers as Helpers
import Http
import Json.Decode
import Json.Encode
import Rest.Helpers exposing (expectJsonWithErrorBody, openstackCredentialedRequest)
import Types.Types
    exposing
        ( HttpRequestMethod(..)
        , Msg(..)
        , Project
        , ProjectSpecificMsgConstructor(..)
        , ProjectViewConstructor(..)
        , Server
        )


requestConsoleLog : Project -> Server -> Int -> Cmd Msg
requestConsoleLog project server length =
    let
        body =
            Json.Encode.object
                [ ( "os-getConsoleOutput"
                  , Json.Encode.object
                        [ ( "length"
                          , Json.Encode.int length
                          )
                        ]
                  )
                ]

        errorContext =
            ErrorContext
                ("request console log for server " ++ server.osProps.uuid)
                ErrorCrit
                Nothing

        resultToMsg result =
            ProjectMsg (Helpers.getProjectId project) <|
                ReceiveConsoleLog errorContext server.osProps.uuid result
    in
    openstackCredentialedRequest
        project
        Post
        Nothing
        (project.endpoints.nova ++ "/servers/" ++ server.osProps.uuid ++ "/action")
        (Http.jsonBody body)
        (expectJsonWithErrorBody
            resultToMsg
            decodeConsoleLog
        )


decodeConsoleLog : Json.Decode.Decoder String
decodeConsoleLog =
    Json.Decode.field "output" Json.Decode.string
