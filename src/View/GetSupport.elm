module View.GetSupport exposing (getSupport, viewStateToSupportableItem)

import Element
import Element.Font as Font
import Element.Input as Input
import Helpers.Helpers as Helpers
import Helpers.RemoteDataPlusPlus as RDPP
import RemoteData
import Set
import Style.Helpers as SH
import Style.Types
import Style.Widgets.Select
import Types.HelperTypes as HelperTypes
import Types.Types
    exposing
        ( Model
        , Msg(..)
        , NonProjectViewConstructor(..)
        , ProjectIdentifier
        , ProjectViewConstructor(..)
        , SupportableItemType(..)
        , ViewState(..)
        )
import View.Helpers as VH
import Widget
import Widget.Style.Material


getSupport :
    Model
    -> Style.Types.ExoPalette
    -> Maybe ( SupportableItemType, Maybe HelperTypes.Uuid )
    -> String
    -> Bool
    -> Element.Element Msg
getSupport model palette maybeSupportableResource requestDescription isSubmitted =
    Element.column (VH.exoColumnAttributes ++ [ Element.spacing 30 ])
        [ Element.el VH.heading2 <| Element.text ("Get Support for " ++ model.style.appTitle)
        , case model.style.supportInfoMarkdown of
            Just markdown ->
                VH.renderMarkdown palette (Helpers.appIsElectron model) markdown

            Nothing ->
                Element.none
        , Input.radio
            VH.exoColumnAttributes
            { onChange =
                \option ->
                    SetNonProjectView <| GetSupport (Maybe.map (\option_ -> ( option_, Nothing )) option) requestDescription isSubmitted
            , selected =
                maybeSupportableResource
                    |> Maybe.map Tuple.first
                    |> Just
            , label = Input.labelAbove [] (Element.text "What do you need help with?")
            , options =
                [ Input.option (Just SupportableServer) (Element.text "A server")
                , Input.option (Just SupportableVolume) (Element.text "A volume")
                , Input.option (Just SupportableImage) (Element.text "An image")
                , Input.option (Just SupportableProject) (Element.text "A project")
                , Input.option Nothing (Element.text "None of these things")
                ]
            }
        , case maybeSupportableResource of
            Nothing ->
                Element.none

            Just ( supportableItemType, _ ) ->
                Element.text ("Which " ++ supportableItemTypeStr supportableItemType ++ " do you need help with?")
        , case maybeSupportableResource of
            Nothing ->
                Element.none

            Just ( supportableItemType, maybeSupportableItemUuid ) ->
                let
                    onChange value =
                        let
                            newMaybeSupportableItemUuid =
                                if value == "" then
                                    Nothing

                                else
                                    Just value
                        in
                        SetNonProjectView <|
                            GetSupport
                                (Just ( supportableItemType, newMaybeSupportableItemUuid ))
                                requestDescription
                                isSubmitted

                    options =
                        case supportableItemType of
                            SupportableProject ->
                                model.projects
                                    |> List.map
                                        (\proj ->
                                            ( proj.auth.project.uuid
                                            , VH.friendlyProjectTitle model proj
                                            )
                                        )

                            SupportableImage ->
                                model.projects
                                    |> List.map .images
                                    |> List.concat
                                    |> List.map
                                        (\image ->
                                            ( image.uuid
                                            , image.name
                                            )
                                        )
                                    -- This removes duplicate values, heh
                                    |> Set.fromList
                                    |> Set.toList
                                    |> List.sortBy Tuple.second

                            SupportableServer ->
                                model.projects
                                    |> List.map .servers
                                    |> List.map (RDPP.withDefault [])
                                    |> List.concat
                                    |> List.map
                                        (\server ->
                                            ( server.osProps.uuid
                                            , server.osProps.name
                                            )
                                        )
                                    |> List.sortBy Tuple.second

                            SupportableVolume ->
                                model.projects
                                    |> List.map .volumes
                                    |> List.map (RemoteData.withDefault [])
                                    |> List.concat
                                    |> List.map
                                        (\volume ->
                                            ( volume.uuid
                                            , volume.name
                                            )
                                        )
                                    |> List.sortBy Tuple.second

                    label =
                        "Select a " ++ supportableItemTypeStr supportableItemType
                in
                Style.Widgets.Select.select
                    []
                    { onChange =
                        onChange
                    , options = options
                    , selected = maybeSupportableItemUuid
                    , label = label
                    }
        , Input.multiline
            (VH.exoElementAttributes ++ [ Element.height <| Element.px 200 ])
            { onChange =
                \newVal -> SetNonProjectView <| GetSupport maybeSupportableResource newVal isSubmitted
            , text = requestDescription
            , placeholder = Nothing
            , label = Input.labelAbove [] (Element.text "Please describe exactly what you need help with.")
            , spellcheck = True
            }
        , Widget.textButton
            (Widget.Style.Material.containedButton (SH.toMaterialPalette palette))
            { text = "Build Support Request"
            , onPress =
                if String.isEmpty requestDescription then
                    Nothing

                else
                    Just <| SetNonProjectView <| GetSupport maybeSupportableResource requestDescription True
            }
        , if isSubmitted then
            -- TODO build support request body, show it to user with a "copy to clipboard" button, ask them to paste it into an email message to the email address passed in via flags.
            Element.column
                [ Element.spacing 10 ]
                [ Element.paragraph
                    []
                    [ Element.text "Please copy all of the following text and paste it into an email message to "
                    , case model.style.userSupportEmail of
                        Just emailAddress ->
                            Element.el [ Font.extraBold ] <| Element.text emailAddress

                        Nothing ->
                            Element.none
                    , Element.text ". Someone will respond and assist you."
                    ]
                , Input.multiline
                    (VH.exoElementAttributes
                        ++ [ Element.height <| Element.px 200
                           , Element.spacing 5
                           , Font.family [ Font.monospace ]
                           , Font.size 10
                           ]
                    )
                    { onChange = \_ -> NoOp
                    , text = buildSupportRequest model maybeSupportableResource requestDescription
                    , placeholder = Nothing
                    , label = Input.labelHidden "Support request"
                    , spellcheck = False
                    }
                ]

          else
            Element.none
        ]


supportableItemTypeStr : SupportableItemType -> String
supportableItemTypeStr supportableItemType =
    case supportableItemType of
        SupportableProject ->
            "project"

        SupportableImage ->
            "image"

        SupportableServer ->
            "server"

        SupportableVolume ->
            "volume"


viewStateToSupportableItem : ViewState -> Maybe ( SupportableItemType, Maybe HelperTypes.Uuid )
viewStateToSupportableItem viewState =
    let
        supportableProjectItem :
            ProjectIdentifier
            -> ProjectViewConstructor
            -> ( SupportableItemType, Maybe HelperTypes.Uuid )
        supportableProjectItem projectUuid projectViewConstructor =
            case projectViewConstructor of
                CreateServer createServerViewParams ->
                    ( SupportableImage, Just createServerViewParams.imageUuid )

                ServerDetail serverUuid _ ->
                    ( SupportableServer, Just serverUuid )

                CreateServerImage serverUuid _ ->
                    ( SupportableServer, Just serverUuid )

                VolumeDetail volumeUuid _ ->
                    ( SupportableVolume, Just volumeUuid )

                AttachVolumeModal _ maybeVolumeUuid ->
                    maybeVolumeUuid
                        |> Maybe.map (\uuid -> ( SupportableVolume, Just uuid ))
                        |> Maybe.withDefault ( SupportableProject, Just projectUuid )

                MountVolInstructions attachment ->
                    ( SupportableServer, Just attachment.serverUuid )

                _ ->
                    ( SupportableProject, Just projectUuid )
    in
    case viewState of
        NonProjectView _ ->
            Nothing

        ProjectView projectUuid _ projectViewConstructor ->
            Just <| supportableProjectItem projectUuid projectViewConstructor


buildSupportRequest : Model -> Maybe ( SupportableItemType, Maybe HelperTypes.Uuid ) -> String -> String
buildSupportRequest model maybeSupportableResource requestDescription =
    String.concat
        [ "# Support Request From "
        , model.style.appTitle
        , "\n\n"
        , "## Applicable Resource"
        , "\n"
        , case maybeSupportableResource of
            Nothing ->
                "Community member did not specify a resource with this support request."

            Just ( itemType, maybeUuid ) ->
                String.concat
                    [ supportableItemTypeStr itemType
                    , case maybeUuid of
                        Just uuid ->
                            " with UUID " ++ uuid

                        Nothing ->
                            ""
                    ]
        , "\n\n"
        , "## Request Description"
        , "\n"
        , requestDescription
        , "\n\n"
        , "## Logged-in Projects"
        , "\n"
        , model.projects
            |> List.map
                (\p ->
                    String.concat
                        [ "- "
                        , p.auth.project.name
                        , " (UUID: "
                        , p.auth.project.uuid
                        , ") as user "
                        , p.auth.user.name
                        , "\n"
                        ]
                )
            |> String.concat

        -- TODO recent (15 mins?) log messages in the app
        -- TODO app URL?
        -- TODO Exosphere client UUID
        -- TODO timestamp
        ]
