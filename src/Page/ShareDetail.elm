module Page.ShareDetail exposing (Model, Msg(..), init, update, view)

import DateFormat.Relative
import Dict
import Element
import Element.Border as Border
import Element.Font as Font
import FeatherIcons
import FormatNumber.Locales exposing (Decimals(..))
import Helpers.Formatting exposing (Unit(..), humanNumber)
import Helpers.GetterSetters as GetterSetters
import Helpers.RemoteDataPlusPlus as RDPP
import Helpers.String
import Helpers.Time
import Html
import Html.Attributes
import OpenStack.Types as OSTypes exposing (AccessRule, AccessRuleState(..), AccessRuleUuid, ExportLocation, Share, accessRuleAccessLevelToString, accessRuleAccessTypeToString, accessRuleStateToString)
import Style.Helpers as SH
import Style.Types as ST exposing (ExoPalette)
import Style.Widgets.Button as Button
import Style.Widgets.Card
import Style.Widgets.CopyableText exposing (copyableText, copyableTextAccessory)
import Style.Widgets.Icon as Icon
import Style.Widgets.Popover.Popover exposing (popover)
import Style.Widgets.Popover.Types exposing (PopoverId)
import Style.Widgets.Select as Select
import Style.Widgets.Spacer exposing (spacer)
import Style.Widgets.Text as Text
import Style.Widgets.ToggleTip
import Time
import Types.Project exposing (Project)
import Types.SharedMsg as SharedMsg
import Url
import View.Helpers as VH
import View.Types
import Widget


type alias Model =
    { shareUuid : OSTypes.ShareUuid
    , deletePendingConfirmation : Maybe OSTypes.ShareUuid
    , selectedAccessKey : Maybe OSTypes.AccessRuleUuid
    }


type Msg
    = GotDeleteNeedsConfirm (Maybe OSTypes.ShareUuid)
    | SelectAccessKey (Maybe OSTypes.AccessRuleUuid)
    | SharedMsg SharedMsg.SharedMsg


init : OSTypes.ShareUuid -> Model
init shareUuid =
    { shareUuid = shareUuid
    , deletePendingConfirmation = Nothing
    , selectedAccessKey = Nothing
    }


update : Msg -> Model -> ( Model, Cmd Msg, SharedMsg.SharedMsg )
update msg model =
    case msg of
        GotDeleteNeedsConfirm shareUuid ->
            ( { model | deletePendingConfirmation = shareUuid }, Cmd.none, SharedMsg.NoOp )

        SelectAccessKey accessKeyUuid ->
            ( { model | selectedAccessKey = accessKeyUuid }
            , Cmd.none
            , SharedMsg.NoOp
            )

        SharedMsg sharedMsg ->
            ( model, Cmd.none, sharedMsg )


popoverMsgMapper : PopoverId -> Msg
popoverMsgMapper popoverId =
    SharedMsg <| SharedMsg.TogglePopover popoverId


view : View.Types.Context -> Project -> ( Time.Posix, Time.Zone ) -> Model -> Element.Element Msg
view context project currentTimeAndZone model =
    VH.renderRDPP context
        project.shares
        context.localization.share
        (\_ ->
            {- Attempt to look up a given share uuid; if a share is found, call render. -}
            case GetterSetters.shareLookup project model.shareUuid of
                Just share ->
                    render context project currentTimeAndZone model share

                Nothing ->
                    Element.text <|
                        String.join " "
                            [ "No"
                            , context.localization.share
                            , "found"
                            ]
        )


createdAgoByWhomEtc :
    View.Types.Context
    ->
        { ago : ( String, Element.Element msg )
        , creator : String
        , size : String
        , shareProtocol : String
        , shareTypeName : String
        , visibility : String
        }
    -> Element.Element msg
createdAgoByWhomEtc context { ago, creator, size, shareProtocol, shareTypeName, visibility } =
    let
        ( agoWord, agoContents ) =
            ago

        subduedText =
            Font.color (context.palette.neutral.text.subdued |> SH.toElementColor)
    in
    Element.wrappedRow
        [ Element.width Element.fill, Element.spaceEvenly ]
    <|
        [ Element.row [ Element.padding spacer.px8 ]
            [ Element.el [ subduedText ] (Element.text <| agoWord ++ " ")
            , agoContents
            , Element.el [ subduedText ] (Element.text <| " by ")
            , Element.text creator
            ]
        , Element.row [ Element.padding spacer.px8 ]
            [ Element.el [ subduedText ] (Element.text <| "size ")
            , Element.text size
            ]
        , Element.row [ Element.padding spacer.px8 ]
            [ Element.el [ subduedText ] (Element.text <| "visibility ")
            , Element.text visibility
            ]
        , Element.row [ Element.padding spacer.px8 ]
            [ Element.el [ subduedText ] (Element.text <| "protocol ")
            , Element.text shareProtocol
            ]
        , Element.row [ Element.padding spacer.px8 ]
            [ Element.el [ subduedText ] (Element.text <| "type ")
            , Element.text shareTypeName
            ]
        ]


shareNameView : Share -> Element.Element Msg
shareNameView share =
    let
        name_ =
            VH.resourceName share.name share.uuid
    in
    Element.row
        [ Element.spacing spacer.px8 ]
        [ Text.text Text.ExtraLarge [] name_ ]


shareStatus : View.Types.Context -> Share -> Element.Element Msg
shareStatus context share =
    let
        statusBadge =
            VH.shareStatusBadge context.palette share.status
    in
    Element.row [ Element.spacing spacer.px16 ]
        [ statusBadge
        ]


renderConfirmation : View.Types.Context -> Maybe Msg -> Maybe Msg -> String -> List (Element.Attribute Msg) -> Element.Element Msg
renderConfirmation context actionMsg cancelMsg title closeActionsAttributes =
    Element.row
        [ Element.spacing spacer.px12, Element.width (Element.fill |> Element.minimum 280) ]
        [ Element.text title
        , Element.el
            (Element.alignRight :: closeActionsAttributes)
          <|
            Button.button
                Button.Danger
                context.palette
                { text = "Yes"
                , onPress = actionMsg
                }
        , Element.el
            [ Element.alignRight ]
          <|
            Button.button
                Button.Secondary
                context.palette
                { text = "No"
                , onPress = cancelMsg
                }
        ]


renderDeleteAction : View.Types.Context -> Model -> Maybe Msg -> Maybe (Element.Attribute Msg) -> Element.Element Msg
renderDeleteAction context model actionMsg closeActionsDropdown =
    case model.deletePendingConfirmation of
        Just _ ->
            let
                additionalBtnAttribs =
                    case closeActionsDropdown of
                        Just closeActionsDropdown_ ->
                            [ closeActionsDropdown_ ]

                        Nothing ->
                            []
            in
            renderConfirmation
                context
                actionMsg
                (Just <|
                    GotDeleteNeedsConfirm Nothing
                )
                "Are you sure?"
                additionalBtnAttribs

        Nothing ->
            Element.row
                [ Element.spacing spacer.px12, Element.width (Element.fill |> Element.minimum 280) ]
                [ Element.text ("Destroy " ++ context.localization.share ++ "?")
                , Element.el
                    [ Element.alignRight ]
                  <|
                    Button.button
                        Button.Danger
                        context.palette
                        { text = "Delete"
                        , onPress = Just <| GotDeleteNeedsConfirm <| Just model.shareUuid
                        }
                ]


shareActionsDropdown : View.Types.Context -> Project -> Model -> Share -> Element.Element Msg
shareActionsDropdown context project model share =
    let
        dropdownId =
            [ "shareActionsDropdown", project.auth.project.uuid, share.uuid ]
                |> List.intersperse "-"
                |> String.concat

        dropdownContent closeDropdown =
            Element.column [ Element.spacing spacer.px8 ] <|
                [ renderDeleteAction context
                    model
                    (Just <|
                        SharedMsg <|
                            (SharedMsg.ProjectMsg (GetterSetters.projectIdentifier project) <|
                                SharedMsg.RequestDeleteShare share.uuid
                            )
                    )
                    (Just closeDropdown)
                ]

        dropdownTarget toggleDropdownMsg dropdownIsShown =
            Widget.iconButton
                (SH.materialStyle context.palette).button
                { text = "Actions"
                , icon =
                    Element.row
                        [ Element.spacing spacer.px4 ]
                        [ Element.text "Actions"
                        , Icon.sizedFeatherIcon 18 <|
                            if dropdownIsShown then
                                FeatherIcons.chevronUp

                            else
                                FeatherIcons.chevronDown
                        ]
                , onPress = Just toggleDropdownMsg
                }
    in
    popover context
        popoverMsgMapper
        { id = dropdownId
        , content = dropdownContent
        , contentStyleAttrs = [ Element.padding spacer.px24 ]
        , position = ST.PositionBottomRight
        , distanceToTarget = Nothing
        , target = dropdownTarget
        , targetStyleAttrs = []
        }


header : String -> Element.Element msg
header text =
    Element.el [ Font.heavy ] <| Element.text text


scrollableCell : List (Element.Attribute msg) -> Element.Element msg -> Element.Element msg
scrollableCell attrs msg =
    Element.el
        ([ Element.scrollbarX, Element.clipY ]
            ++ attrs
        )
        (Element.el
            [ -- HACK: A width needs to be set so that the cell expands responsively while having a horizontal scrollbar to contain overflow.
              Element.width (Element.px 0)
            ]
            msg
        )


accessRulesTable : ExoPalette -> List AccessRule -> Element.Element Msg
accessRulesTable palette accessRules =
    case List.length accessRules of
        0 ->
            Element.text "(none)"

        _ ->
            Element.table
                [ Element.spacing spacer.px16
                ]
                { data = accessRules
                , columns =
                    [ { header = header "State"
                      , width = Element.shrink
                      , view =
                            \item ->
                                Text.body <| accessRuleStateToString <| item.state
                      }
                    , { header = header "Type"
                      , width = Element.shrink
                      , view =
                            \item ->
                                Text.body <| accessRuleAccessTypeToString <| item.accessType
                      }
                    , { header = header "Level"
                      , width = Element.shrink
                      , view =
                            \item ->
                                Text.body <| accessRuleAccessLevelToString <| item.accessLevel
                      }
                    , { header = header "Access To"
                      , width = Element.fill
                      , view =
                            \item ->
                                scrollableCell
                                    []
                                    (Text.body <| item.accessTo)
                      }
                    , { header = header "Access Key"
                      , width = Element.fill
                      , view =
                            \item ->
                                let
                                    accessKey =
                                        Maybe.withDefault "(none)" <| item.accessKey
                                in
                                scrollableCell
                                    [ (copyableTextAccessory palette accessKey).id ]
                                    (Text.mono accessKey)
                      }
                    , { header = Element.none
                      , width = Element.shrink
                      , view =
                            \item ->
                                (copyableTextAccessory palette <| Maybe.withDefault "(none)" <| item.accessKey).accessory
                      }
                    ]
                }


copyableScript : ExoPalette -> String -> Element.Element msg
copyableScript palette script =
    let
        copyableAccessory =
            copyableTextAccessory palette script
    in
    Element.el
        [ Element.inFront <|
            Element.el
                [ Element.alignRight
                , Element.moveLeft <| toFloat spacer.px4
                , Element.moveDown <| toFloat spacer.px4
                ]
                copyableAccessory.accessory
        , copyableAccessory.id
        , Element.width Element.fill
        , Border.solid
        , Border.width 1
        , Border.color <| SH.toElementColor palette.muted.border
        , Element.padding spacer.px4
        , Text.fontFamily Text.Mono
        ]
    <|
        Element.html <|
            Html.pre
                [ Html.Attributes.style "margin" "0"
                , Html.Attributes.style "white-space" "pre-wrap"
                , Html.Attributes.style "word-wrap" "break-word"
                ]
                [ Html.text script ]


renderMountTileContents : View.Types.Context -> Model -> Share -> ( List ExportLocation, List AccessRule ) -> Element.Element Msg
renderMountTileContents context model share ( exportLocations, accessRules ) =
    case List.head exportLocations of
        Nothing ->
            noExportLocationNotice context

        Just exportLocation ->
            renderMountTileContents_ context model share ( exportLocation, accessRules )


noExportLocationNotice : View.Types.Context -> Element.Element msg
noExportLocationNotice context =
    Element.paragraph []
        [ Element.text <|
            "Contact your administrator to request an export location added to your "
                ++ context.localization.share
        ]


renderMountTileContents_ : View.Types.Context -> Model -> Share -> ( ExportLocation, List AccessRule ) -> Element.Element Msg
renderMountTileContents_ context model share ( exportLocation, accessRules ) =
    let
        getUserSelectedAccessRule : List AccessRule -> Maybe AccessRule
        getUserSelectedAccessRule rules =
            model.selectedAccessKey
                |> Maybe.andThen
                    (\uuid ->
                        List.filter (\r -> r.uuid == uuid) rules
                            |> List.head
                    )

        ( ruleSelector, accessRule ) =
            case accessRules of
                [] ->
                    -- This won't be very helpful, maybe later we should provide a notice (like we do with export locations)
                    ( Element.none, Nothing )

                singleRule :: [] ->
                    -- If there is only a single access rule, no need to make the user select one
                    ( Element.none, Just singleRule )

                multipleRules ->
                    ( accessRuleSelector context model accessRules
                    , getUserSelectedAccessRule multipleRules
                    )

        mountScriptElements_ =
            case accessRule of
                Just rule ->
                    mountScriptElements context share exportLocation rule

                Nothing ->
                    []
    in
    Element.column [ Element.spacing spacer.px12, Element.width Element.fill ] <|
        List.concat
            [ [ ruleSelector ]
            , mountScriptElements_
            ]


mountScriptElements : View.Types.Context -> Share -> ExportLocation -> AccessRule -> List (Element.Element msg)
mountScriptElements context share exportLocation accessRule =
    let
        { baseUrl, urlPathPrefix } =
            context

        scriptUrl =
            Url.toString
                { baseUrl
                    | path =
                        String.join "/"
                            [ urlPathPrefix
                                |> Maybe.map (\prefix -> "/" ++ prefix)
                                |> Maybe.withDefault ""
                            , "assets"
                            , "scripts"
                            , "mount_ceph.py"
                            ]
                }

        shareName =
            share.name |> Maybe.withDefault context.localization.share |> GetterSetters.sanitizeMountpoint

        mountPoint =
            "/media/share/" ++ shareName

        mountScript =
            String.join " \\\n  "
                [ "curl " ++ scriptUrl ++ " | sudo python3 - mount"
                , "--access-rule-name=\"" ++ accessRule.accessTo ++ "\""
                , "--access-rule-key=\"" ++ (accessRule.accessKey |> Maybe.withDefault "nokey") ++ "\""
                , "--share-path=\"" ++ exportLocation.path ++ "\""
                , "--share-name=\"" ++ shareName ++ "\""
                ]

        unmountScript =
            String.join " \\\n  "
                [ "curl " ++ scriptUrl ++ " | sudo python3 - unmount"
                , "--share-name=\"" ++ shareName ++ "\""
                ]
    in
    [ Element.paragraph [] <|
        VH.renderMarkdown context.palette
            (String.join " "
                [ "Run the following command on your"
                , context.localization.virtualComputer
                , "to mount this"
                , context.localization.share
                , "at"
                , "`" ++ mountPoint ++ "`"
                ]
            )
    , copyableScript context.palette mountScript
    , Element.paragraph []
        [ Element.text <|
            "To unmount this "
                ++ context.localization.share
                ++ ", this command may be used"
        ]
    , copyableScript context.palette unmountScript
    ]


accessRuleSelector : View.Types.Context -> Model -> List AccessRule -> Element.Element Msg
accessRuleSelector context model accessRules =
    let
        getOption : AccessRule -> Maybe ( AccessRuleUuid, String )
        getOption accessRule =
            case accessRule.state of
                Active ->
                    Just
                        ( accessRule.uuid
                        , accessRule.accessTo
                            ++ " ("
                            ++ accessRuleAccessLevelToString accessRule.accessLevel
                            ++ ")"
                        )

                _ ->
                    Nothing

        options =
            List.filterMap getOption accessRules
    in
    Select.select []
        context.palette
        { onChange = SelectAccessKey
        , selected = model.selectedAccessKey
        , label = "Select an Access Rule"
        , options = options
        }


exportLocationsTable : ExoPalette -> List ExportLocation -> Element.Element Msg
exportLocationsTable palette exportLocations =
    case List.length exportLocations of
        0 ->
            Element.text "(none)"

        _ ->
            Element.table
                [ Element.spacing spacer.px16
                ]
                { data = exportLocations
                , columns =
                    [ { header = header "Path"
                      , width = Element.fill
                      , view =
                            \item ->
                                scrollableCell
                                    [ (copyableTextAccessory palette item.path).id ]
                                    (Text.body item.path)
                      }
                    , { header = Element.none
                      , width = Element.shrink
                      , view =
                            \item ->
                                (copyableTextAccessory palette item.path).accessory
                      }
                    ]
                }


render : View.Types.Context -> Project -> ( Time.Posix, Time.Zone ) -> Model -> Share -> Element.Element Msg
render context project ( currentTime, _ ) model share =
    let
        whenCreated =
            let
                timeDistanceStr =
                    DateFormat.Relative.relativeTime currentTime share.createdAt

                createdTimeText =
                    let
                        createdTimeFormatted =
                            Helpers.Time.humanReadableDateAndTime share.createdAt
                    in
                    Element.text ("Created on: " ++ createdTimeFormatted)

                toggleTipContents =
                    Element.column [] [ createdTimeText ]
            in
            Element.row
                [ Element.spacing spacer.px4 ]
                [ Element.text timeDistanceStr
                , Style.Widgets.ToggleTip.toggleTip
                    context
                    popoverMsgMapper
                    (Helpers.String.hyphenate
                        [ "createdTimeTip"
                        , project.auth.project.uuid
                        , share.uuid
                        ]
                    )
                    toggleTipContents
                    ST.PositionBottomLeft
                ]

        creator =
            if share.userUuid == project.auth.user.uuid then
                "me"

            else
                "another user"

        sizeString =
            let
                locale =
                    context.locale

                ( sizeDisplay, sizeLabel ) =
                    -- The share size, in GiBs.
                    humanNumber { locale | decimals = Exact 0 } GibiBytes share.size
            in
            sizeDisplay ++ " " ++ sizeLabel

        description =
            case share.description of
                Just str ->
                    Element.row [ Element.padding spacer.px8 ]
                        [ Element.paragraph [ Element.width Element.fill ] <|
                            [ Element.text <| str ]
                        ]

                Nothing ->
                    Element.none

        tile : List (Element.Element Msg) -> List (Element.Element Msg) -> Element.Element Msg
        tile headerContents contents =
            Style.Widgets.Card.exoCard context.palette
                (Element.column
                    [ Element.width Element.fill
                    , Element.padding spacer.px16
                    , Element.spacing spacer.px16
                    ]
                    (List.concat
                        [ [ Element.row
                                (Text.subheadingStyleAttrs context.palette
                                    ++ Text.typographyAttrs Text.Large
                                    ++ [ Border.width 0 ]
                                )
                                headerContents
                          ]
                        , contents
                        ]
                    )
                )

        accessRules =
            case Dict.get share.uuid project.shareAccessRules of
                Just accessRulesRDPP ->
                    VH.renderRDPP context
                        accessRulesRDPP
                        (context.localization.accessRule |> Helpers.String.pluralize)
                        (accessRulesTable context.palette)

                Nothing ->
                    Element.none

        exportLocations =
            case Dict.get share.uuid project.shareExportLocations of
                Just exportLocationsRDPP ->
                    VH.renderRDPP context
                        exportLocationsRDPP
                        (context.localization.exportLocation |> Helpers.String.pluralize)
                        (exportLocationsTable context.palette)

                Nothing ->
                    Element.none

        mountTileContents =
            case ( Dict.get share.uuid project.shareExportLocations, Dict.get share.uuid project.shareAccessRules ) of
                ( Just exportLocationsRDPP, Just accessRulesRDPP ) ->
                    VH.renderRDPP context
                        (RDPP.map2 Tuple.pair exportLocationsRDPP accessRulesRDPP)
                        (context.localization.exportLocation |> Helpers.String.pluralize)
                        (renderMountTileContents context model share)

                _ ->
                    Element.none
    in
    Element.column [ Element.spacing spacer.px24, Element.width Element.fill ]
        [ Element.row (Text.headingStyleAttrs context.palette)
            [ FeatherIcons.share2 |> FeatherIcons.toHtml [] |> Element.html |> Element.el []
            , Text.text Text.ExtraLarge
                []
                (context.localization.share
                    |> Helpers.String.toTitleCase
                )
            , shareNameView share
            , Element.row [ Element.alignRight, Text.fontSize Text.Body, Font.regular, Element.spacing spacer.px16 ]
                [ shareStatus context share
                , shareActionsDropdown context project model share
                ]
            ]
        , tile
            [ FeatherIcons.database |> FeatherIcons.toHtml [] |> Element.html |> Element.el []
            , Element.text "Info"
            , Element.el
                [ Text.fontSize Text.Tiny
                , Font.color (SH.toElementColor context.palette.neutral.text.subdued)
                , Element.alignBottom
                ]
                (copyableText context.palette
                    [ Element.width (Element.shrink |> Element.minimum 240) ]
                    share.uuid
                )
            ]
            [ description
            , createdAgoByWhomEtc
                context
                { ago = ( "created", whenCreated )
                , creator = creator
                , size = sizeString
                , shareProtocol = OSTypes.shareProtocolToString share.shareProtocol
                , shareTypeName = share.shareTypeName
                , visibility = OSTypes.shareVisibilityToString share.visibility
                }
            ]
        , tile
            [ FeatherIcons.cloud
                |> FeatherIcons.toHtml []
                |> Element.html
                |> Element.el []
            , context.localization.exportLocation
                |> Helpers.String.pluralize
                |> Helpers.String.toTitleCase
                |> Element.text
            ]
            [ exportLocations
            ]
        , tile
            [ FeatherIcons.lock
                |> FeatherIcons.toHtml []
                |> Element.html
                |> Element.el []
            , context.localization.accessRule
                |> Helpers.String.pluralize
                |> Helpers.String.toTitleCase
                |> Element.text
            ]
            [ accessRules
            ]
        , tile
            [ FeatherIcons.folder
                |> FeatherIcons.toHtml []
                |> Element.html
                |> Element.el []
            , Text.text Text.Large
                []
                ("Mount your "
                    ++ context.localization.share
                    |> Helpers.String.toTitleCase
                )
            ]
            [ mountTileContents ]
        ]
