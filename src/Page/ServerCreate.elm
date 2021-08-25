module Page.ServerCreate exposing (Model, Msg, init, update, view)

import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import FeatherIcons
import Helpers.GetterSetters as GetterSetters
import Helpers.Helpers as Helpers
import Helpers.RemoteDataPlusPlus as RDPP
import Helpers.String
import Maybe
import OpenStack.Quotas as OSQuotas
import OpenStack.ServerNameValidator exposing (serverNameValidator)
import OpenStack.Types as OSTypes
import RemoteData
import ServerDeploy exposing (cloudInitUserDataTemplate)
import Style.Helpers as SH
import Style.Widgets.NumericTextInput.NumericTextInput exposing (numericTextInput)
import Style.Widgets.NumericTextInput.Types exposing (NumericTextInput(..))
import Types.HelperTypes as HelperTypes
    exposing
        ( FloatingIpAssignmentStatus(..)
        , FloatingIpOption(..)
        , FloatingIpReuseOption(..)
        )
import Types.Project exposing (Project)
import Types.Server exposing (NewServerNetworkOptions(..))
import Types.SharedMsg as SharedMsg
import Types.Workflow
    exposing
        ( CustomWorkflowSource
        , CustomWorkflowSourceRepository(..)
        )
import Url
import View.Helpers as VH exposing (edges)
import View.Types
import Widget


type alias Model =
    HelperTypes.CreateServerPageModel


type Msg
    = GotServerName String
    | GotCount Int
    | GotFlavorUuid OSTypes.FlavorUuid
    | GotVolSizeTextInput (Maybe NumericTextInput)
    | GotUserDataTemplate String
    | GotNetworkUuid (Maybe OSTypes.NetworkUuid)
    | GotCustomWorkflowSource (Maybe CustomWorkflowSource) (Maybe String)
    | GotShowAdvancedOptions Bool
    | GotKeypairName (Maybe String)
    | GotDeployGuacamole (Maybe Bool)
    | GotDeployDesktopEnvironment Bool
    | GotInstallOperatingSystemUpdates Bool
    | GotFloatingIpCreationOption FloatingIpOption
    | SharedMsg SharedMsg.SharedMsg
    | NoOp


init : OSTypes.ImageUuid -> String -> Maybe Bool -> Model
init imageUuid imageName deployGuacamole =
    { serverName = imageName
    , imageUuid = imageUuid
    , imageName = imageName
    , count = 1
    , flavorUuid = ""
    , volSizeTextInput = Nothing
    , userDataTemplate = cloudInitUserDataTemplate
    , networkUuid = Nothing
    , customWorkflowSource = Nothing
    , customWorkflowSourceInput = Nothing
    , showAdvancedOptions = False
    , keypairName = Nothing
    , deployGuacamole = deployGuacamole
    , deployDesktopEnvironment = False
    , installOperatingSystemUpdates = True
    , floatingIpCreationOption = HelperTypes.Automatic
    }


update : Msg -> Project -> Model -> ( Model, Cmd Msg, SharedMsg.SharedMsg )
update msg _ model =
    case msg of
        GotServerName name ->
            ( { model | serverName = name }, Cmd.none, SharedMsg.NoOp )

        GotCount count ->
            ( { model | count = count }, Cmd.none, SharedMsg.NoOp )

        GotFlavorUuid flavorUuid ->
            ( { model | flavorUuid = flavorUuid }, Cmd.none, SharedMsg.NoOp )

        GotVolSizeTextInput maybeVolSizeInput ->
            ( { model | volSizeTextInput = maybeVolSizeInput }, Cmd.none, SharedMsg.NoOp )

        GotUserDataTemplate userData ->
            ( { model | userDataTemplate = userData }, Cmd.none, SharedMsg.NoOp )

        GotNetworkUuid maybeNetworkUuid ->
            ( { model | networkUuid = maybeNetworkUuid }, Cmd.none, SharedMsg.NoOp )

        GotCustomWorkflowSource maybeCustomWorkflowSource maybeCustomWorkflowSourceInput ->
            ( { model
                | customWorkflowSource = maybeCustomWorkflowSource
                , customWorkflowSourceInput = maybeCustomWorkflowSourceInput
              }
            , Cmd.none
            , SharedMsg.NoOp
            )

        GotShowAdvancedOptions showAdvancedOptions ->
            ( { model | showAdvancedOptions = showAdvancedOptions }, Cmd.none, SharedMsg.NoOp )

        GotKeypairName maybeKeypairName ->
            ( { model | keypairName = maybeKeypairName }, Cmd.none, SharedMsg.NoOp )

        GotDeployGuacamole maybeDeployGuacamole ->
            ( { model | deployGuacamole = maybeDeployGuacamole }, Cmd.none, SharedMsg.NoOp )

        GotDeployDesktopEnvironment deployDesktopEnvironment ->
            ( { model | deployDesktopEnvironment = deployDesktopEnvironment }, Cmd.none, SharedMsg.NoOp )

        GotInstallOperatingSystemUpdates installUpdates ->
            ( { model | installOperatingSystemUpdates = installUpdates }, Cmd.none, SharedMsg.NoOp )

        GotFloatingIpCreationOption floatingIpOption ->
            ( { model | floatingIpCreationOption = floatingIpOption }, Cmd.none, SharedMsg.NoOp )

        SharedMsg sharedMsg ->
            ( model, Cmd.none, sharedMsg )

        NoOp ->
            ( model, Cmd.none, SharedMsg.NoOp )


view : View.Types.Context -> Project -> Model -> Element.Element Msg
view context project model =
    let
        invalidNameReasons =
            serverNameValidator (Just context.localization.virtualComputer) model.serverName

        renderInvalidNameReasons =
            case invalidNameReasons of
                Just reasons ->
                    Element.column
                        [ Font.color (SH.toElementColor context.palette.error)
                        , Font.size 14
                        , Element.alignRight
                        , Element.moveDown 6
                        ]
                    <|
                        List.map Element.text reasons

                Nothing ->
                    Element.none

        maybeNetworkGuidance =
            case Helpers.newServerNetworkOptions project of
                NetworksLoading ->
                    Just "Loading networks, please wait a moment."

                AutoSelectedNetwork _ ->
                    Nothing

                ManualNetworkSelection ->
                    case model.networkUuid of
                        Just _ ->
                            Nothing

                        Nothing ->
                            Just <|
                                String.join " "
                                    [ "Exosphere could not determine a suitable network to create a server."
                                    , "Please select a network in the advanced options."
                                    ]

                NoneAvailable ->
                    Just <|
                        String.join " "
                            [ "No networks to create a server available."
                            , "Please contact your cloud administrator."
                            ]

        renderNetworkGuidance =
            case maybeNetworkGuidance of
                Nothing ->
                    Element.none

                Just guidanceText ->
                    Element.paragraph
                        [ Font.color (SH.toElementColor context.palette.error)
                        , Element.alignRight
                        ]
                        [ Element.text guidanceText
                        ]

        createOnPress =
            let
                invalidVolSizeTextInput =
                    case model.volSizeTextInput of
                        Just input ->
                            case input of
                                ValidNumericTextInput _ ->
                                    False

                                InvalidNumericTextInput _ ->
                                    True

                        Nothing ->
                            False

                invalidWorkflowTextInput =
                    case ( model.customWorkflowSourceInput, model.customWorkflowSource ) of
                        ( Just _, Nothing ) ->
                            True

                        ( _, _ ) ->
                            False

                invalidInputs =
                    invalidVolSizeTextInput || invalidWorkflowTextInput
            in
            case ( invalidNameReasons, invalidInputs, model.networkUuid ) of
                ( Nothing, False, Just netUuid ) ->
                    Just <| SharedMsg (SharedMsg.ProjectMsg project.auth.project.uuid (SharedMsg.RequestCreateServer model netUuid))

                ( _, _, _ ) ->
                    Nothing

        contents flavor computeQuota volumeQuota =
            [ Input.text
                (VH.inputItemAttributes context.palette.background)
                { text = model.serverName
                , placeholder =
                    Just
                        (Input.placeholder
                            []
                            (Element.text <|
                                String.join " "
                                    [ "My"
                                    , context.localization.virtualComputer
                                        |> Helpers.String.toTitleCase
                                    ]
                            )
                        )
                , onChange = GotServerName
                , label = Input.labelLeft [] (Element.text "Name")
                }
            , renderInvalidNameReasons
            , Element.row VH.exoRowAttributes
                [ Element.text <|
                    String.concat
                        [ context.localization.staticRepresentationOfBlockDeviceContents
                            |> Helpers.String.toTitleCase
                        , ": "
                        ]
                , Element.text model.imageName
                ]
            , flavorPicker context project model computeQuota
            , volBackedPrompt context model volumeQuota flavor
            , countPicker context model computeQuota volumeQuota flavor
            , desktopEnvironmentPicker context project model
            , customWorkflowInput context model
            , Element.column
                VH.exoColumnAttributes
              <|
                [ Input.radioRow [ Element.spacing 10 ]
                    { label = Input.labelAbove [ Element.paddingXY 0 12, Font.bold ] (Element.text "Advanced Options")
                    , onChange = GotShowAdvancedOptions
                    , options =
                        [ Input.option False (Element.text "Hide")
                        , Input.option True (Element.text "Show")

                        {- -}
                        ]
                    , selected = Just model.showAdvancedOptions
                    }
                ]
                    ++ (if not model.showAdvancedOptions then
                            [ Element.none ]

                        else
                            [ skipOperatingSystemUpdatesPicker context model
                            , guacamolePicker context model
                            , networkPicker context project model
                            , floatingIpPicker context project model
                            , keypairPicker context project model
                            , userDataInput context model
                            ]
                       )
            , renderNetworkGuidance
            , Element.el [ Element.alignRight ] <|
                Widget.textButton
                    (SH.materialStyle context.palette).primaryButton
                    { text = "Create"
                    , onPress = createOnPress
                    }
            ]
    in
    Element.column
        (VH.exoColumnAttributes ++ [ Element.width Element.fill ])
    <|
        [ Element.el
            (VH.heading2 context.palette)
            (Element.text <|
                String.join " "
                    [ "Create"
                    , context.localization.virtualComputer
                        |> Helpers.String.toTitleCase
                    ]
            )
        , Element.column VH.formContainer <|
            case
                ( GetterSetters.flavorLookup project model.flavorUuid
                , project.computeQuota
                , project.volumeQuota
                )
            of
                ( Just flavor, RemoteData.Success computeQuota, RemoteData.Success volumeQuota ) ->
                    contents flavor computeQuota volumeQuota

                ( _, _, RemoteData.Loading ) ->
                    -- TODO deduplicate this with code below
                    [ Element.row [ Element.spacing 15 ]
                        [ Widget.circularProgressIndicator
                            (SH.materialStyle context.palette).progressIndicator
                            Nothing
                        , Element.text "Loading..."
                        ]
                    ]

                ( _, RemoteData.Loading, _ ) ->
                    [ Element.row [ Element.spacing 15 ]
                        [ Widget.circularProgressIndicator
                            (SH.materialStyle context.palette).progressIndicator
                            Nothing
                        , Element.text "Loading..."
                        ]
                    ]

                ( _, _, _ ) ->
                    [ Element.text "oops, we shouldn't be here" ]
        ]


flavorPicker : View.Types.Context -> Project -> Model -> OSTypes.ComputeQuota -> Element.Element Msg
flavorPicker context project model computeQuota =
    let
        -- This is a kludge. Input.radio is intended to display a group of multiple radio buttons,
        -- but we want to embed a button in each table row, so we define several Input.radios,
        -- each containing just a single option.
        -- https://elmlang.slack.com/archives/C4F9NBLR1/p1539909855000100
        radioButton flavor =
            let
                radio_ =
                    Input.radio
                        []
                        { label = Input.labelHidden flavor.name
                        , onChange = GotFlavorUuid
                        , options = [ Input.option flavor.uuid (Element.text " ") ]
                        , selected =
                            if flavor.uuid == model.flavorUuid then
                                Just flavor.uuid

                            else
                                Nothing
                        }
            in
            -- Only allow selection if there is enough available quota
            case OSQuotas.computeQuotaFlavorAvailServers computeQuota flavor of
                Nothing ->
                    radio_

                Just availServers ->
                    if availServers < 1 then
                        Element.text "X"

                    else
                        radio_

        paddingRight =
            Element.paddingEach { edges | right = 15 }

        headerAttribs =
            [ paddingRight
            , Font.bold
            , Font.center
            ]

        columns =
            [ { header = Element.none
              , width = Element.fill
              , view = \r -> radioButton r
              }
            , { header = Element.el (headerAttribs ++ [ Font.alignLeft ]) (Element.text "Name")
              , width = Element.fill
              , view = \r -> Element.el [ paddingRight ] (Element.text r.name)
              }
            , { header = Element.el headerAttribs (Element.text "CPUs")
              , width = Element.fill
              , view = \r -> Element.el [ paddingRight, Font.alignRight ] (Element.text (String.fromInt r.vcpu))
              }
            , { header = Element.el headerAttribs (Element.text "RAM (GB)")
              , width = Element.fill
              , view = \r -> Element.el [ paddingRight, Font.alignRight ] (Element.text (r.ram_mb // 1024 |> String.fromInt))
              }
            , { header = Element.el headerAttribs (Element.text "Root Disk")
              , width = Element.fill
              , view =
                    \r ->
                        Element.el
                            [ paddingRight, Font.alignRight ]
                            (if r.disk_root == 0 then
                                Element.text "- *"

                             else
                                Element.text (String.fromInt r.disk_root ++ " GB")
                            )
              }
            , { header = Element.el headerAttribs (Element.text "Ephemeral Disk")
              , width = Element.fill
              , view =
                    \r ->
                        Element.el
                            [ paddingRight, Font.alignRight ]
                            (if r.disk_ephemeral == 0 then
                                Element.text "none"

                             else
                                Element.text (String.fromInt r.disk_ephemeral ++ " GB")
                            )
              }
            ]

        zeroRootDiskExplainText =
            case List.filter (\f -> f.disk_root == 0) project.flavors |> List.head of
                Just _ ->
                    String.concat
                        [ "* No default root disk size is defined for this "
                        , context.localization.virtualComputer
                        , " "
                        , context.localization.virtualComputerHardwareConfig
                        , ", see below"
                        ]

                Nothing ->
                    ""

        flavorEmptyHint =
            if model.flavorUuid == "" then
                [ VH.hint context <|
                    String.join
                        " "
                        [ "Please pick a"
                        , context.localization.virtualComputerHardwareConfig
                        ]
                ]

            else
                []

        anyFlavorsTooLarge =
            project.flavors
                |> List.map (OSQuotas.computeQuotaFlavorAvailServers computeQuota)
                |> List.filterMap (Maybe.map (\x -> x < 1))
                |> List.isEmpty
                |> not
    in
    Element.column
        VH.exoColumnAttributes
        [ Element.el
            [ Font.bold ]
            (Element.text <| Helpers.String.toTitleCase context.localization.virtualComputerHardwareConfig)
        , Element.table
            flavorEmptyHint
            { data = GetterSetters.sortedFlavors project.flavors
            , columns = columns
            }
        , if anyFlavorsTooLarge then
            Element.text <|
                String.join " "
                    [ context.localization.virtualComputerHardwareConfig
                        |> Helpers.String.pluralize
                        |> Helpers.String.toTitleCase
                    , "marked 'X' are too large for your available"
                    , context.localization.maxResourcesPerProject
                    ]

          else
            Element.none
        , Element.paragraph [ Font.size 12 ] [ Element.text zeroRootDiskExplainText ]
        ]


volBackedPrompt : View.Types.Context -> Model -> OSTypes.VolumeQuota -> OSTypes.Flavor -> Element.Element Msg
volBackedPrompt context model volumeQuota flavor =
    let
        ( volumeCountAvail, volumeSizeGbAvail ) =
            OSQuotas.volumeQuotaAvail volumeQuota

        canLaunchVolBacked =
            let
                tooSmall quotaItem minVal =
                    case quotaItem of
                        Just val ->
                            minVal > val

                        Nothing ->
                            False
            in
            not (tooSmall volumeCountAvail 1 || tooSmall volumeSizeGbAvail 2)

        flavorRootDiskSize =
            flavor.disk_root

        nonVolBackedOptionText =
            if flavorRootDiskSize == 0 then
                String.join " "
                    [ "Default for selected"
                    , context.localization.staticRepresentationOfBlockDeviceContents
                    , "(warning, could be too small for your work)"
                    ]

            else
                String.concat
                    [ String.fromInt flavorRootDiskSize
                    , " GB (default for selected "
                    , context.localization.virtualComputerHardwareConfig
                    , ")"
                    ]

        defaultVolSizeGB =
            10

        defaultVolNumericInputParams =
            { labelText = "Root disk size (GB)"
            , minVal = Just 2
            , maxVal = volumeSizeGbAvail
            , defaultVal = Just defaultVolSizeGB
            }

        radioInput =
            Input.radio []
                { label = Input.labelHidden "Root disk size"
                , onChange =
                    \new ->
                        let
                            newVolSizeTextInput =
                                if new == True then
                                    Just <| ValidNumericTextInput defaultVolSizeGB

                                else
                                    Nothing
                        in
                        GotVolSizeTextInput newVolSizeTextInput
                , options =
                    [ Input.option False (Element.text nonVolBackedOptionText)
                    , Input.option True
                        (Element.text <|
                            String.concat
                                [ "Custom disk size ("
                                , context.localization.blockDevice
                                , "-backed)"
                                ]
                        )
                    ]
                , selected =
                    case model.volSizeTextInput of
                        Just _ ->
                            Just True

                        Nothing ->
                            Just False
                }
    in
    Element.column VH.exoColumnAttributes
        [ Element.text "Choose a root disk size"
        , if canLaunchVolBacked then
            radioInput

          else
            Element.text <|
                String.concat
                    [ "(N/A: "
                    , context.localization.blockDevice
                    , " "
                    , context.localization.maxResourcesPerProject
                    , " exhausted, cannot launch a "
                    , context.localization.blockDevice
                    , "-backed instance)"
                    ]
        , case model.volSizeTextInput of
            Nothing ->
                Element.none

            Just volSizeTextInput ->
                Element.row VH.exoRowAttributes
                    [ numericTextInput
                        context.palette
                        (VH.inputItemAttributes context.palette.background)
                        volSizeTextInput
                        defaultVolNumericInputParams
                        (\newInput -> GotVolSizeTextInput <| Just newInput)
                    , case ( volumeSizeGbAvail, volSizeTextInput ) of
                        ( Just volumeSizeAvail_, ValidNumericTextInput i ) ->
                            if i == volumeSizeAvail_ then
                                Element.text ("(" ++ context.localization.maxResourcesPerProject ++ " max)")

                            else
                                Element.none

                        ( _, _ ) ->
                            Element.none
                    ]
        ]


countPicker :
    View.Types.Context
    -> Model
    -> OSTypes.ComputeQuota
    -> OSTypes.VolumeQuota
    -> OSTypes.Flavor
    -> Element.Element Msg
countPicker context model computeQuota volumeQuota flavor =
    let
        countAvail =
            OSQuotas.overallQuotaAvailServers
                (model.volSizeTextInput
                    |> Maybe.andThen Style.Widgets.NumericTextInput.NumericTextInput.toMaybe
                )
                flavor
                computeQuota
                volumeQuota
    in
    Element.column VH.exoColumnAttributes
        [ Element.text <|
            String.concat
                [ "How many "
                , context.localization.virtualComputer
                    |> Helpers.String.pluralize
                    |> Helpers.String.toTitleCase
                , "?"
                ]
        , case countAvail of
            Just countAvail_ ->
                Element.text <|
                    String.join " "
                        [ "Your"
                        , context.localization.maxResourcesPerProject
                        , "supports up to"
                        , String.fromInt countAvail_
                        , "of these."
                        ]

            Nothing ->
                Element.none
        , Element.row VH.exoRowAttributes
            [ Input.slider
                [ Element.height (Element.px 30)
                , Element.width (Element.px 100 |> Element.minimum 200)

                -- Here is where we're creating/styling the "track"
                , Element.behindContent
                    (Element.el
                        [ Element.width Element.fill
                        , Element.height (Element.px 2)
                        , Element.centerY
                        , Background.color (SH.toElementColor context.palette.on.background)
                        , Border.rounded 2
                        ]
                        Element.none
                    )
                ]
                { onChange = \c -> GotCount <| round c
                , label = Input.labelHidden "How many?"
                , min = 1
                , max = countAvail |> Maybe.withDefault 20 |> toFloat
                , step = Just 1
                , value = toFloat model.count
                , thumb =
                    Input.defaultThumb
                }
            , Element.el
                [ Element.width Element.shrink ]
                (Element.text <| String.fromInt model.count)
            , case countAvail of
                Just countAvail_ ->
                    if model.count == countAvail_ then
                        Element.text ("(" ++ context.localization.maxResourcesPerProject ++ " max)")

                    else
                        Element.none

                Nothing ->
                    Element.none
            ]
        ]


customWorkflowInput : View.Types.Context -> Model -> Element.Element Msg
customWorkflowInput context model =
    if context.experimentalFeaturesEnabled then
        customWorkflowInputExperimental context model

    else
        Element.none


customWorkflowInputExperimental : View.Types.Context -> Model -> Element.Element Msg
customWorkflowInputExperimental context model =
    let
        clearButton =
            Widget.textButton
                (SH.materialStyle context.palette).button
                { text = "Remove workflow"
                , onPress =
                    model.customWorkflowSource
                        |> Maybe.map (\_ -> GotCustomWorkflowSource Nothing Nothing)
                }

        workFlowInputToWorkflow : String -> Maybe CustomWorkflowSource
        workFlowInputToWorkflow workflowInputString =
            Url.fromString workflowInputString
                |> Maybe.map
                    (\url ->
                        { repository =
                            GitRepository
                                url
                                Nothing
                        , path = Nothing
                        }
                    )

        workflowInput =
            Input.text
                (VH.inputItemAttributes context.palette.background)
                { text = model.customWorkflowSourceInput |> Maybe.withDefault ""
                , placeholder =
                    Just
                        (Input.placeholder
                            []
                            (Element.text "https://github.com/binder-examples/minimal-dockerfile")
                        )
                , onChange =
                    \n ->
                        if n == "" then
                            GotCustomWorkflowSource Nothing Nothing

                        else
                            GotCustomWorkflowSource (workFlowInputToWorkflow n) (Just n)
                , label = Input.labelLeft [] (Element.text "Git repository URL")
                }

        warning =
            Element.paragraph
                ([ Background.color (SH.toElementColor context.palette.warn), Font.color (SH.toElementColor context.palette.on.warn) ]
                    ++ VH.exoElementAttributes
                )
                [ Element.text "Note: Workflows is an experimental feature"
                ]
    in
    Element.column
        (VH.exoColumnAttributes
            ++ [ Element.width Element.fill
               , Element.spacingXY 0 12
               ]
        )
    <|
        [ Element.el
            (VH.heading4
                ++ [ Font.size 17
                   ]
            )
            (Element.text ("Launch a workflow in the " ++ context.localization.virtualComputer))
        , warning
        , workflowInput
        , clearButton
        ]


desktopEnvironmentPicker : View.Types.Context -> Project -> Model -> Element.Element Msg
desktopEnvironmentPicker context project model =
    let
        warnings : List (Element.Element Msg)
        warnings =
            [ Just <|
                Element.text <|
                    String.concat
                        [ "Warning: this is an alpha feature that currently only supports "
                        , context.localization.staticRepresentationOfBlockDeviceContents
                            |> Helpers.String.pluralize
                        , " based on CentOS 8. Support for other operating systems is coming soon, but if you choose "
                        , context.localization.staticRepresentationOfBlockDeviceContents
                            |> Helpers.String.indefiniteArticle
                        , " "
                        , context.localization.staticRepresentationOfBlockDeviceContents
                        , " based on a different operating system now, it is unlikely to work."
                        ]
            , let
                warningMaxGB =
                    12

                rootDiskWarnText =
                    String.join " "
                        [ "Warning: root disk may be too small for a graphical desktop environment. Please select a"
                        , context.localization.virtualComputerHardwareConfig
                        , "with a"
                        , String.fromInt warningMaxGB
                        , "GB or larger root disk, or select a volume-backed root disk at least"
                        , String.fromInt warningMaxGB
                        , "GB in size."
                        ]
              in
              case model.volSizeTextInput of
                Nothing ->
                    case GetterSetters.flavorLookup project model.flavorUuid of
                        Just flavor ->
                            if flavor.disk_root < warningMaxGB then
                                Just <| Element.text rootDiskWarnText

                            else
                                Nothing

                        Nothing ->
                            Nothing

                Just numericTextInput ->
                    case numericTextInput of
                        ValidNumericTextInput rootVolSize ->
                            if rootVolSize < warningMaxGB then
                                Just <| Element.text rootDiskWarnText

                            else
                                Nothing

                        _ ->
                            Nothing
            , if model.deployDesktopEnvironment then
                Just <|
                    Element.text <|
                        String.join " "
                            [ "Warning: If selected"
                            , context.localization.staticRepresentationOfBlockDeviceContents
                            , "does not already include a graphical desktop environment,"
                            , context.localization.virtualComputer
                            , "can take 30 minutes or longer to deploy."
                            ]

              else
                Nothing
            ]
                |> List.filterMap identity
    in
    Element.column VH.exoColumnAttributes
        [ Input.radioRow VH.exoElementAttributes
            { label =
                Input.labelAbove [ Element.paddingXY 0 12, Font.bold ]
                    (Element.text <|
                        String.concat
                            [ "Enable "
                            , context.localization.graphicalDesktopEnvironment
                            , "?"
                            ]
                    )
            , onChange = GotDeployDesktopEnvironment
            , options =
                [ Input.option False (Element.text "No")
                , Input.option True (Element.text "Yes")
                ]
            , selected = Just model.deployDesktopEnvironment
            }
        , if model.deployDesktopEnvironment then
            Element.column
                ([ Background.color (SH.toElementColor context.palette.warn), Font.color (SH.toElementColor context.palette.on.warn) ]
                    ++ VH.exoElementAttributes
                )
                (List.map (\warning -> Element.paragraph [] [ warning ]) warnings)

          else
            Element.none
        ]


guacamolePicker : View.Types.Context -> Model -> Element.Element Msg
guacamolePicker context model =
    case model.deployGuacamole of
        Nothing ->
            Element.text <|
                String.concat
                    [ "Guacamole deployment is not supported for this "
                    , context.localization.openstackWithOwnKeystone
                    , "."
                    ]

        Just deployGuacamole ->
            Element.column VH.exoColumnAttributes
                [ Input.radioRow [ Element.spacing 10 ]
                    { label = Input.labelAbove [ Element.paddingXY 0 12, Font.bold ] (Element.text "Deploy Guacamole for easy remote access?")
                    , onChange = \new -> GotDeployGuacamole <| Just new
                    , options =
                        [ Input.option True (Element.text "Yes")
                        , Input.option False (Element.text "No")

                        {- -}
                        ]
                    , selected = Just deployGuacamole
                    }
                ]


skipOperatingSystemUpdatesPicker : View.Types.Context -> Model -> Element.Element Msg
skipOperatingSystemUpdatesPicker context model =
    Element.column VH.exoColumnAttributes
        [ Input.radioRow [ Element.spacing 10 ]
            { label = Input.labelAbove [ Element.paddingXY 0 12, Font.bold ] (Element.text "Install operating system updates?")
            , onChange = GotInstallOperatingSystemUpdates
            , options =
                [ Input.option True (Element.text "Yes")
                , Input.option False (Element.text "No")

                {- -}
                ]
            , selected = Just model.installOperatingSystemUpdates
            }
        , if not model.installOperatingSystemUpdates then
            Element.paragraph
                ([ Background.color (SH.toElementColor context.palette.warn), Font.color (SH.toElementColor context.palette.on.warn) ]
                    ++ VH.exoElementAttributes
                )
                [ Element.text <|
                    String.concat
                        [ "Warning: Skipping operating system updates is a security risk, especially when launching "
                        , Helpers.String.indefiniteArticle context.localization.virtualComputer
                        , " "
                        , context.localization.virtualComputer
                        , " from an older "
                        , context.localization.staticRepresentationOfBlockDeviceContents
                        , ". Do not use this "
                        , context.localization.virtualComputer
                        , " for any sensitive information or workloads."
                        ]
                ]

          else
            Element.none
        ]


networkPicker : View.Types.Context -> Project -> Model -> Element.Element Msg
networkPicker context project model =
    let
        networkOptions =
            Helpers.newServerNetworkOptions project

        guidance =
            let
                maybeStr =
                    if networkOptions == ManualNetworkSelection && model.networkUuid == Nothing then
                        Just "Please choose a network."

                    else
                        Just "Please only change this if you know what you are doing."
            in
            case maybeStr of
                Just str ->
                    Element.paragraph
                        [ Font.color (context.palette.error |> SH.toElementColor) ]
                        [ Element.text str ]

                Nothing ->
                    Element.none

        picker =
            let
                networkAsInputOption network =
                    Input.option network.uuid (Element.text network.name)
            in
            Input.radio []
                { label = Input.labelHidden "Choose a Network"
                , onChange = \networkUuid -> GotNetworkUuid <| Just networkUuid
                , options =
                    case project.networks.data of
                        RDPP.DoHave networks _ ->
                            List.map networkAsInputOption networks

                        RDPP.DontHave ->
                            []
                , selected = model.networkUuid
                }
    in
    Element.column
        VH.exoColumnAttributes
        [ Element.el [ Font.bold ] <| Element.text "Network"
        , guidance
        , picker
        ]


floatingIpPicker : View.Types.Context -> Project -> Model -> Element.Element Msg
floatingIpPicker context project model =
    let
        optionPicker =
            let
                options =
                    [ Input.option Automatic (Element.text "Automatic")
                    , Input.option (UseFloatingIp CreateNewFloatingIp Unknown)
                        (Element.text <|
                            String.join " "
                                [ "Assign a"
                                , context.localization.floatingIpAddress
                                , "to this"
                                , context.localization.virtualComputer
                                ]
                        )
                    , Input.option DoNotUseFloatingIp
                        (Element.text <|
                            String.join " "
                                [ "Do not create or assign a"
                                , context.localization.floatingIpAddress
                                ]
                        )
                    ]
            in
            Input.radio []
                { label =
                    Input.labelHidden <|
                        String.join " "
                            [ "Choose a"
                            , context.localization.floatingIpAddress
                            , "option"
                            ]
                , onChange = GotFloatingIpCreationOption
                , options =
                    options
                , selected = Just model.floatingIpCreationOption
                }

        reuseOptionPicker =
            case model.floatingIpCreationOption of
                UseFloatingIp reuseOption _ ->
                    let
                        unassignedFloatingIpOptions =
                            project.floatingIps
                                |> RDPP.withDefault []
                                |> List.filter (\ip -> ip.portUuid == Nothing)
                                |> List.map
                                    (\ip ->
                                        Input.option
                                            (UseExistingFloatingIp ip.uuid)
                                            (Element.text <| String.join " " [ "Use existing", ip.address ])
                                    )

                        options =
                            List.concat
                                [ [ Input.option
                                        CreateNewFloatingIp
                                        (Element.text <|
                                            String.join " " [ "Create a new", context.localization.floatingIpAddress ]
                                        )
                                  ]
                                , unassignedFloatingIpOptions
                                ]
                    in
                    Element.column
                        [ Element.paddingXY 0 10, Element.spacingXY 0 10 ]
                        [ Element.el [ Font.bold ] <|
                            Element.text <|
                                String.join " "
                                    [ Helpers.String.toTitleCase context.localization.floatingIpAddress
                                    , "Reuse Option"
                                    ]
                        , Input.radio []
                            { label =
                                Input.labelHidden <|
                                    String.join " "
                                        [ "Choose whether to create a new"
                                        , context.localization.floatingIpAddress
                                        , "or re-use an existing one"
                                        ]
                            , onChange = \option -> GotFloatingIpCreationOption <| UseFloatingIp option Unknown
                            , options = options
                            , selected =
                                Just reuseOption
                            }
                        ]

                _ ->
                    Element.none
    in
    Element.column
        VH.exoColumnAttributes
        [ Element.el [ Font.bold ] <|
            Element.text <|
                Helpers.String.toTitleCase context.localization.floatingIpAddress
        , optionPicker
        , reuseOptionPicker
        ]


keypairPicker : View.Types.Context -> Project -> Model -> Element.Element Msg
keypairPicker context project model =
    let
        keypairAsOption keypair =
            Input.option keypair.name (Element.text keypair.name)

        renderKeypairs keypairs =
            if List.isEmpty keypairs then
                Element.text <|
                    String.concat
                        [ "(This "
                        , context.localization.unitOfTenancy
                        , " has no "
                        , context.localization.pkiPublicKeyForSsh
                            |> Helpers.String.pluralize
                        , " to choose from, but you can still create "
                        , Helpers.String.indefiniteArticle context.localization.virtualComputer
                        , " "
                        , context.localization.virtualComputer
                        , "!)"
                        ]

            else
                Input.radio []
                    { label =
                        Input.labelAbove
                            [ Element.paddingXY 0 12 ]
                            (Element.text <|
                                String.join " "
                                    [ "Choose"
                                    , Helpers.String.indefiniteArticle context.localization.pkiPublicKeyForSsh
                                    , context.localization.pkiPublicKeyForSsh
                                    , "(this is optional, skip if unsure)"
                                    ]
                            )
                    , onChange = \keypairName -> GotKeypairName <| Just keypairName
                    , options = List.map keypairAsOption keypairs
                    , selected = Just (Maybe.withDefault "" model.keypairName)
                    }
    in
    Element.column
        VH.exoColumnAttributes
        [ Element.el
            [ Font.bold ]
            (Element.text
                (Helpers.String.toTitleCase context.localization.pkiPublicKeyForSsh)
            )
        , VH.renderWebData
            context
            project.keypairs
            (Helpers.String.pluralize context.localization.pkiPublicKeyForSsh)
            renderKeypairs
        , let
            text =
                String.concat [ "Upload a new ", context.localization.pkiPublicKeyForSsh ]
          in
          Widget.iconButton
            (SH.materialStyle context.palette).button
            { text = text
            , icon =
                Element.row
                    [ Element.spacing 5 ]
                    [ Element.text text
                    , Element.el []
                        (FeatherIcons.chevronRight
                            |> FeatherIcons.toHtml []
                            |> Element.html
                        )
                    ]
            , onPress =
                Just <|
                    SharedMsg <|
                        SharedMsg.NavigateToView <|
                            SharedMsg.ProjectPage project.auth.project.uuid <|
                                SharedMsg.KeypairCreate
            }
        ]


userDataInput : View.Types.Context -> Model -> Element.Element Msg
userDataInput context model =
    Element.column
        VH.exoColumnAttributes
        [ Element.el
            [ Font.bold ]
            (Element.text
                (Helpers.String.toTitleCase context.localization.cloudInitData)
            )
        , Input.multiline
            (VH.inputItemAttributes context.palette.background
                ++ [ Element.width Element.fill
                   , Element.height (Element.px 500)
                   , Element.spacing 3
                   , Font.family [ Font.monospace ]
                   ]
            )
            { onChange = GotUserDataTemplate
            , text = model.userDataTemplate
            , placeholder =
                Just
                    (Input.placeholder []
                        (Element.text <|
                            String.join
                                " "
                                [ "#!/bin/bash\n\n# Your"
                                , context.localization.cloudInitData
                                , "here"
                                ]
                        )
                    )
            , label =
                Input.labelHidden <| Helpers.String.toTitleCase context.localization.cloudInitData
            , spellcheck = False
            }
        ]