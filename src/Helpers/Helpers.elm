module Helpers.Helpers exposing
    ( alwaysRegex
    , checkFloatingIpState
    , getBootVol
    , httpErrorToString
    , isBootVol
    , newServerMetadata
    , newServerNetworkOptions
    , pipelineCmd
    , renderUserDataTemplate
    , serverFromThisExoClient
    , serverLessThanThisOld
    , serverNeedsFrequentPoll
    , serverOrigin
    , serviceCatalogToEndpoints
    , stringIsUuidOrDefault
    , volDeviceToMountpoint
    )

-- Many functions which get and set things in the data model have been moved from here to GetterSetters.elm.
-- Getter/setter functions that remain here are too "smart" (too much business logic) for GetterSetters.elm.

import Dict
import Helpers.GetterSetters as GetterSetters
import Helpers.RemoteDataPlusPlus as RDPP
import Helpers.Time exposing (iso8601StringToPosix)
import Http
import Json.Decode as Decode
import Json.Encode
import OpenStack.Types as OSTypes
import Regex
import RemoteData
import ServerDeploy
import Time
import Types.Guacamole as GuacTypes
import Types.Types
    exposing
        ( Endpoints
        , ExoServerVersion
        , ExoSetupStatus(..)
        , FloatingIpState(..)
        , JetstreamProvider(..)
        , Model
        , Msg(..)
        , NewServerNetworkOptions(..)
        , Project
        , Server
        , ServerFromExoProps
        , ServerOrigin(..)
        , ServerUiStatus(..)
        )
import UUID


alwaysRegex : String -> Regex.Regex
alwaysRegex regexStr =
    Regex.fromString regexStr |> Maybe.withDefault Regex.never


stringIsUuidOrDefault : String -> Bool
stringIsUuidOrDefault str =
    -- We accept some login fields from user (e.g. Keystone domains) that could be a name or a UUID.
    -- Further, OpenStack treats "default" as a special case that can be passed in UUID fields.
    -- This function helps functions like Rest.requestAuthToken specify the right JSON field (name or ID).
    let
        stringIsUuid =
            let
                strNoHyphens =
                    String.filter (\c -> c /= '-') str

                isValidHex : Char -> Bool
                isValidHex c =
                    String.any (\h -> c == h) "0123456789abcdef"

                isValidLength =
                    String.length strNoHyphens == 32
            in
            String.all isValidHex strNoHyphens && isValidLength

        stringIsDefault =
            str == "default"
    in
    stringIsUuid || stringIsDefault


serviceCatalogToEndpoints : OSTypes.ServiceCatalog -> Result String Endpoints
serviceCatalogToEndpoints catalog =
    let
        novaUrlWithMicroversionSupport : String -> String
        novaUrlWithMicroversionSupport url =
            -- Future optimization, use a real URL parser
            if String.contains "/v2/" url then
                String.replace "/v2/" "/v2.1/" url

            else if String.contains "/v2.0/" url then
                String.replace "/v2.0/" "/v2.1/" url

            else
                url

        maybeEndpointsDict : Dict.Dict String (Maybe String)
        maybeEndpointsDict =
            Dict.fromList
                [ ( "cinder", GetterSetters.getServicePublicUrl "volumev3" catalog )
                , ( "glance", GetterSetters.getServicePublicUrl "image" catalog )
                , ( "keystone", GetterSetters.getServicePublicUrl "identity" catalog )
                , ( "nova", GetterSetters.getServicePublicUrl "compute" catalog |> Maybe.map novaUrlWithMicroversionSupport )
                , ( "neutron", GetterSetters.getServicePublicUrl "network" catalog )
                ]
    in
    -- I am not super proud of this factoring
    case
        [ "cinder", "glance", "keystone", "nova", "neutron" ]
            |> List.map (\k -> Dict.get k maybeEndpointsDict)
            |> List.map (Maybe.withDefault Nothing)
    of
        [ Just cinderUrl, Just glanceUrl, Just keystoneUrl, Just novaUrl, Just neutronUrl ] ->
            Ok <| Endpoints cinderUrl glanceUrl keystoneUrl novaUrl neutronUrl

        _ ->
            let
                unfoundServices =
                    Dict.filter (\_ v -> v == Nothing) maybeEndpointsDict
                        |> Dict.keys
            in
            Err
                ("Could not locate URL(s) in service catalog for the following service(s): "
                    ++ String.join ", " unfoundServices
                )


checkFloatingIpState : OSTypes.ServerDetails -> FloatingIpState -> FloatingIpState
checkFloatingIpState serverDetails floatingIpState =
    let
        hasFixedIp =
            List.filter (\a -> a.openstackType == OSTypes.IpAddressFixed) serverDetails.ipAddresses
                |> List.isEmpty
                |> not

        hasFloatingIp =
            List.filter (\a -> a.openstackType == OSTypes.IpAddressFloating) serverDetails.ipAddresses
                |> List.isEmpty
                |> not

        isActive =
            serverDetails.openstackStatus == OSTypes.ServerActive
    in
    case floatingIpState of
        RequestedWaiting ->
            if hasFloatingIp then
                Success

            else
                RequestedWaiting

        Failed ->
            Failed

        Success ->
            Success

        _ ->
            if hasFloatingIp then
                Success

            else if hasFixedIp && isActive then
                Requestable

            else
                NotRequestable


renderUserDataTemplate : Project -> String -> Maybe String -> Bool -> Bool -> Bool -> String
renderUserDataTemplate project userDataTemplate maybeKeypairName deployGuacamole deployDesktopEnvironment installOperatingSystemUpdates =
    -- Configure cloud-init user data based on user's choice for SSH keypair and Guacamole
    let
        getPublicKeyFromKeypairName : String -> Maybe String
        getPublicKeyFromKeypairName keypairName =
            project.keypairs
                |> RemoteData.withDefault []
                |> List.filter (\kp -> kp.name == keypairName)
                |> List.head
                |> Maybe.map .publicKey

        authorizedKeysYaml : String
        authorizedKeysYaml =
            case maybeKeypairName |> Maybe.andThen getPublicKeyFromKeypairName of
                Just key ->
                    "\n    ssh-authorized-keys:\n      - " ++ key ++ "\n"

                Nothing ->
                    "\n"

        guacamoleSetupCmdsYaml : String
        guacamoleSetupCmdsYaml =
            if deployGuacamole then
                ServerDeploy.guacamoleUserData

            else
                "echo \"Not deploying Guacamole\"\n"

        ansibleExtraVars : String
        ansibleExtraVars =
            if deployDesktopEnvironment then
                -- JSON format is required to pass boolean values to Ansible as extra vars at runtime
                """{\\"gui_enabled\\":true}"""

            else
                """{\\"gui_enabled\\":false}"""

        desktopEnvironmentSetupCmdsYaml : String
        desktopEnvironmentSetupCmdsYaml =
            if deployDesktopEnvironment then
                ServerDeploy.desktopEnvironmentUserData

            else
                "echo \"Not deploying a desktop environment\"\n"

        installOperatingSystemUpatesYaml : String
        installOperatingSystemUpatesYaml =
            if installOperatingSystemUpdates then
                "true"

            else
                "false"
    in
    [ ( "{ssh-authorized-keys}\n", authorizedKeysYaml )
    , ( "{guacamole-setup}\n", guacamoleSetupCmdsYaml )
    , ( "{ansible-extra-vars}", ansibleExtraVars )
    , ( "{desktop-environment-setup}\n", desktopEnvironmentSetupCmdsYaml )
    , ( "{install-os-updates}", installOperatingSystemUpatesYaml )
    ]
        |> List.foldl (\t -> String.replace (Tuple.first t) (Tuple.second t)) userDataTemplate


newServerMetadata : ExoServerVersion -> UUID.UUID -> Bool -> Bool -> String -> List ( String, Json.Encode.Value )
newServerMetadata exoServerVersion exoClientUuid deployGuacamole deployDesktopEnvironment exoCreatorUsername =
    let
        guacMetadata =
            if deployGuacamole then
                [ ( "exoGuac"
                  , Json.Encode.string <|
                        Json.Encode.encode 0 <|
                            Json.Encode.object
                                [ ( "v", Json.Encode.int 1 )
                                , ( "ssh", Json.Encode.bool True )
                                , ( "vnc", Json.Encode.bool deployDesktopEnvironment )
                                ]
                  )
                ]

            else
                []
    in
    List.concat
        [ guacMetadata
        , [ ( "exoServerVersion"
            , Json.Encode.string (String.fromInt exoServerVersion)
            )
          , ( "exoClientUuid"
            , Json.Encode.string (UUID.toString exoClientUuid)
            )
          , ( "exoCreatorUsername"
            , Json.Encode.string exoCreatorUsername
            )
          , ( "exoSetup"
            , Json.Encode.string "waiting"
            )
          ]
        ]


newServerNetworkOptions : Project -> NewServerNetworkOptions
newServerNetworkOptions project =
    {- When creating a new server, make a reasonable choice of project network, if we can. -}
    let
        projectNets =
            -- Filter on networks that are status ACTIVE, adminStateUp, and not external
            case project.networks.data of
                RDPP.DoHave networks _ ->
                    networks
                        |> List.filter (\n -> n.status == "ACTIVE")
                        |> List.filter (\n -> n.adminStateUp == True)
                        |> List.filter (\n -> n.isExternal == False)

                RDPP.DontHave ->
                    []

        maybeProjectNameNet =
            projectNets
                |> List.filter
                    (\n ->
                        String.contains
                            (String.toLower project.auth.project.name)
                            (String.toLower n.name)
                    )
                |> List.head
    in
    -- Prefer auto-allocated network topology that we get/create
    case project.autoAllocatedNetworkUuid.data of
        RDPP.DoHave netUuid _ ->
            AutoSelectedNetwork netUuid

        RDPP.DontHave ->
            case project.autoAllocatedNetworkUuid.refreshStatus of
                RDPP.Loading _ ->
                    NetworksLoading

                RDPP.NotLoading maybeError ->
                    case maybeError of
                        Nothing ->
                            -- We haven't gotten auto-allocated network yet, say "loading" anyway
                            NetworksLoading

                        Just _ ->
                            -- auto-allocation API call failed, so look through list of networks
                            case
                                projectNets
                                    |> List.filter (\n -> n.name == "auto_allocated_network")
                                    |> List.head
                            of
                                Just net ->
                                    AutoSelectedNetwork net.uuid

                                Nothing ->
                                    case maybeProjectNameNet of
                                        Just projectNameNet ->
                                            AutoSelectedNetwork projectNameNet.uuid

                                        Nothing ->
                                            case project.networks.refreshStatus of
                                                RDPP.Loading _ ->
                                                    NetworksLoading

                                                RDPP.NotLoading _ ->
                                                    if List.isEmpty projectNets then
                                                        NoneAvailable

                                                    else
                                                        ManualNetworkSelection


isBootVol : Maybe OSTypes.ServerUuid -> OSTypes.Volume -> Bool
isBootVol maybeServerUuid volume =
    -- If a serverUuid is passed, determines whether volume backs that server; otherwise just determines whether volume backs any server
    volume.attachments
        |> List.filter
            (\a ->
                case maybeServerUuid of
                    Just serverUuid ->
                        a.serverUuid == serverUuid

                    Nothing ->
                        True
            )
        |> List.filter
            (\a ->
                List.member
                    a.device
                    [ "/dev/sda", "/dev/vda" ]
            )
        |> List.isEmpty
        |> not


getBootVol : List OSTypes.Volume -> OSTypes.ServerUuid -> Maybe OSTypes.Volume
getBootVol vols serverUuid =
    vols
        |> List.filter (isBootVol <| Just serverUuid)
        |> List.head


volDeviceToMountpoint : OSTypes.VolumeAttachmentDevice -> Maybe String
volDeviceToMountpoint device =
    -- Converts e.g. "/dev/sdc" to "/media/volume/sdc"
    device
        |> String.split "/"
        |> List.reverse
        |> List.head
        |> Maybe.map (String.append "/media/volume/")


serverOrigin : OSTypes.ServerDetails -> ServerOrigin
serverOrigin serverDetails =
    let
        exoServerVersion =
            let
                maybeDecodedVersion =
                    List.filter (\i -> i.key == "exoServerVersion") serverDetails.metadata
                        |> List.head
                        |> Maybe.map .value
                        |> Maybe.andThen String.toInt

                version0 =
                    List.filter (\i -> i.key == "exouserPassword") serverDetails.metadata
                        |> List.isEmpty
                        |> not
            in
            case maybeDecodedVersion of
                Just v ->
                    Just v

                Nothing ->
                    if version0 then
                        Just 0

                    else
                        Nothing

        exoSetupStatus =
            let
                maybeStrStatus =
                    List.filter (\i -> i.key == "exoSetup") serverDetails.metadata
                        |> List.head
                        |> Maybe.map .value
            in
            case maybeStrStatus of
                Nothing ->
                    ExoSetupUnknown

                Just strStatus ->
                    case strStatus of
                        "waiting" ->
                            ExoSetupWaiting

                        "running" ->
                            ExoSetupRunning

                        "complete" ->
                            ExoSetupComplete

                        "error" ->
                            ExoSetupError

                        _ ->
                            ExoSetupUnknown

        exoSetupStatusRDPP =
            RDPP.RemoteDataPlusPlus (RDPP.DoHave exoSetupStatus (Time.millisToPosix 0)) (RDPP.NotLoading Nothing)

        decodeGuacamoleProps : Decode.Decoder GuacTypes.LaunchedWithGuacProps
        decodeGuacamoleProps =
            Decode.map3
                GuacTypes.LaunchedWithGuacProps
                (Decode.field "ssh" Decode.bool)
                (Decode.field "vnc" Decode.bool)
                (Decode.succeed RDPP.empty)

        guacamoleStatus =
            case
                List.filter (\i -> i.key == "exoGuac") serverDetails.metadata
                    |> List.head
            of
                Nothing ->
                    GuacTypes.NotLaunchedWithGuacamole

                Just item ->
                    case Decode.decodeString decodeGuacamoleProps item.value of
                        Ok launchedWithGuacProps ->
                            GuacTypes.LaunchedWithGuacamole launchedWithGuacProps

                        Err _ ->
                            GuacTypes.NotLaunchedWithGuacamole

        creatorName =
            List.filter (\i -> i.key == "exoCreatorUsername") serverDetails.metadata
                |> List.head
                |> Maybe.map .value
    in
    case exoServerVersion of
        Just v ->
            ServerFromExo <|
                ServerFromExoProps v exoSetupStatusRDPP RDPP.empty guacamoleStatus creatorName

        Nothing ->
            ServerNotFromExo


serverFromThisExoClient : UUID.UUID -> Server -> Bool
serverFromThisExoClient clientUuid server =
    -- Determine if server was created by this Exosphere client
    List.member (OSTypes.MetadataItem "exoClientUuid" (UUID.toString clientUuid)) server.osProps.details.metadata


serverNeedsFrequentPoll : Server -> Bool
serverNeedsFrequentPoll server =
    case
        ( server.exoProps.deletionAttempted
        , server.exoProps.targetOpenstackStatus
        , server.exoProps.serverOrigin
        )
    of
        ( False, Nothing, ServerNotFromExo ) ->
            case server.osProps.details.openstackStatus of
                OSTypes.ServerBuilding ->
                    True

                _ ->
                    False

        ( False, Nothing, ServerFromExo exoOriginProps ) ->
            case server.osProps.details.openstackStatus of
                OSTypes.ServerBuilding ->
                    True

                _ ->
                    case exoOriginProps.exoSetupStatus.data of
                        RDPP.DoHave exoSetupStatus _ ->
                            case exoSetupStatus of
                                ExoSetupWaiting ->
                                    True

                                ExoSetupRunning ->
                                    True

                                _ ->
                                    False

                        RDPP.DontHave ->
                            True

        _ ->
            True


serverLessThanThisOld : Server -> Time.Posix -> Int -> Bool
serverLessThanThisOld server currentTime maxServerAgeMillis =
    let
        curTimeMillis =
            Time.posixToMillis currentTime
    in
    case iso8601StringToPosix server.osProps.details.created of
        -- Defaults to False if cannot determine server created time
        Err _ ->
            False

        Ok createdTime ->
            (curTimeMillis - Time.posixToMillis createdTime) < maxServerAgeMillis


{-| This one helps string functions together in Rest.ApiModelHelpers and other places
-}
pipelineCmd : (Model -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
pipelineCmd fn ( model, cmd ) =
    let
        ( newModel, newCmd ) =
            fn model
    in
    ( newModel, Cmd.batch [ cmd, newCmd ] )


httpErrorToString : Http.Error -> String
httpErrorToString httpError =
    case httpError of
        Http.BadUrl url ->
            "BadUrl: " ++ url

        Http.Timeout ->
            "Timeout"

        Http.NetworkError ->
            "NetworkError"

        Http.BadStatus int ->
            "BadStatus: " ++ String.fromInt int

        Http.BadBody string ->
            "BadBody: " ++ string
