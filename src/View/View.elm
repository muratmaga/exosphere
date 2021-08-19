module View.View exposing (view)

import Browser
import Element
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FeatherIcons
import Helpers.GetterSetters as GetterSetters
import Helpers.String
import Helpers.Url as UrlHelpers
import Html
import Page.AllResourcesList
import Page.FloatingIpAssign
import Page.FloatingIpList
import Page.GetSupport
import Page.HelpAbout
import Page.ImageList
import Page.KeypairCreate
import Page.KeypairList
import Page.LoginJetstream
import Page.LoginOpenstack
import Page.LoginPicker
import Page.MessageLog
import Page.SelectProjects
import Page.ServerCreate
import Page.ServerCreateImage
import Page.ServerDetail
import Page.ServerList
import Page.Settings
import Page.Toast
import Page.VolumeAttach
import Page.VolumeCreate
import Page.VolumeDetail
import Page.VolumeList
import Page.VolumeMountInstructions
import Style.Helpers as SH
import Style.Toast
import Toasty
import Types.HelperTypes exposing (ProjectIdentifier, WindowSize)
import Types.OuterModel exposing (OuterModel)
import Types.OuterMsg exposing (OuterMsg(..))
import Types.Project exposing (Project)
import Types.SharedModel exposing (SharedModel)
import Types.SharedMsg as SharedMsg exposing (SharedMsg(..))
import Types.View exposing (LoginView(..), NonProjectViewConstructor(..), ProjectViewConstructor(..), ViewState(..))
import View.Helpers as VH
import View.Nav
import View.PageTitle
import View.Types
import Widget


view : OuterModel -> Browser.Document OuterMsg
view outerModel =
    let
        context =
            VH.toViewContext outerModel.sharedModel
    in
    { title =
        View.PageTitle.pageTitle outerModel context
    , body =
        [ view_ outerModel context ]
    }


view_ : OuterModel -> View.Types.Context -> Html.Html OuterMsg
view_ outerModel context =
    Element.layout
        [ Font.size 17
        , Font.family
            [ Font.typeface "Open Sans"
            , Font.sansSerif
            ]
        , Font.color <| SH.toElementColor <| context.palette.on.background
        , Background.color <| SH.toElementColor <| context.palette.background
        ]
        (elementView outerModel.sharedModel.windowSize outerModel context)


elementView : WindowSize -> OuterModel -> View.Types.Context -> Element.Element OuterMsg
elementView windowSize outerModel context =
    let
        mainContentContainerView =
            Element.column
                [ Element.padding 10
                , Element.alignTop
                , Element.width <|
                    Element.px (windowSize.width - View.Nav.navMenuWidth)
                , Element.height Element.fill
                , Element.scrollbars
                ]
                [ case outerModel.viewState of
                    NonProjectView viewConstructor ->
                        case viewConstructor of
                            GetSupport model ->
                                Page.GetSupport.view context outerModel.sharedModel model
                                    |> Element.map GetSupportMsg

                            HelpAbout ->
                                Page.HelpAbout.view outerModel.sharedModel context

                            LoadingUnscopedProjects _ ->
                                -- TODO put a fidget spinner here
                                Element.text <|
                                    String.join " "
                                        [ "Loading"
                                        , context.localization.unitOfTenancy
                                            |> Helpers.String.pluralize
                                            |> Helpers.String.toTitleCase
                                        ]

                            Login loginView ->
                                case loginView of
                                    LoginOpenstack model ->
                                        Page.LoginOpenstack.view context model
                                            |> Element.map LoginOpenstackMsg

                                    LoginJetstream model ->
                                        Page.LoginJetstream.view context model
                                            |> Element.map LoginJetstreamMsg

                            LoginPicker ->
                                Page.LoginPicker.view context outerModel.sharedModel
                                    |> Element.map LoginPickerMsg

                            MessageLog model ->
                                Page.MessageLog.view context outerModel.sharedModel model
                                    |> Element.map MessageLogMsg

                            PageNotFound ->
                                Element.text "Error: page not found. Perhaps you are trying to reach an invalid URL."

                            SelectProjects model ->
                                Page.SelectProjects.view context outerModel.sharedModel model
                                    |> Element.map SelectProjectsMsg

                            Settings ->
                                Page.Settings.view context outerModel.sharedModel ()
                                    |> Element.map SettingsMsg

                    ProjectView projectName projectViewParams viewConstructor ->
                        case GetterSetters.projectLookup outerModel.sharedModel projectName of
                            Nothing ->
                                Element.text <|
                                    String.join " "
                                        [ "Oops!"
                                        , context.localization.unitOfTenancy
                                            |> Helpers.String.toTitleCase
                                        , "not found"
                                        ]

                            Just project_ ->
                                project
                                    outerModel.sharedModel
                                    context
                                    project_
                                    projectViewParams
                                    viewConstructor
                , Element.html
                    (Toasty.view Style.Toast.toastConfig
                        (Page.Toast.view context outerModel.sharedModel)
                        (\m -> SharedMsg <| ToastyMsg m)
                        outerModel.sharedModel.toasties
                    )
                ]
    in
    Element.row
        [ Element.padding 0
        , Element.spacing 0
        , Element.width Element.fill
        , Element.height <|
            Element.px windowSize.height
        ]
        [ Element.column
            [ Element.padding 0
            , Element.spacing 0
            , Element.width Element.fill
            , Element.height <|
                Element.px windowSize.height
            ]
            [ Element.el
                [ Border.shadow { offset = ( 0, 0 ), size = 1, blur = 5, color = Element.rgb 0.1 0.1 0.1 }
                , Element.width Element.fill
                ]
                (View.Nav.navBar outerModel context)
            , Element.row
                [ Element.padding 0
                , Element.spacing 0
                , Element.width Element.fill
                , Element.height <|
                    Element.px (windowSize.height - View.Nav.navBarHeight)
                ]
                [ View.Nav.navMenu outerModel context
                , mainContentContainerView
                ]
            ]
        ]



--


type alias ProjectPageModel =
    { createPopup : Bool
    }


project :
    SharedModel
    -> View.Types.Context
    -> Project
    -> ProjectPageModel
    -> Types.View.ProjectViewConstructor
    -> Element.Element OuterMsg
project model context p projectPageModel viewConstructor =
    let
        v =
            case viewConstructor of
                AllResourcesList model_ ->
                    Page.AllResourcesList.view
                        context
                        p
                        model_
                        |> Element.map AllResourcesListMsg

                FloatingIpAssign model_ ->
                    Page.FloatingIpAssign.view
                        context
                        p
                        model_
                        |> Element.map FloatingIpAssignMsg

                FloatingIpList model_ ->
                    Page.FloatingIpList.view context
                        p
                        model_
                        True
                        |> Element.map FloatingIpListMsg

                ImageList model_ ->
                    Page.ImageList.view context p model_
                        |> Element.map ImageListMsg

                KeypairCreate model_ ->
                    Page.KeypairCreate.view context model_
                        |> Element.map KeypairCreateMsg

                KeypairList model_ ->
                    Page.KeypairList.view context
                        p
                        model_
                        True
                        |> Element.map KeypairListMsg

                ServerCreate createServerViewParams ->
                    Page.ServerCreate.view context p createServerViewParams
                        |> Element.map ServerCreateMsg

                ServerCreateImage model_ ->
                    Page.ServerCreateImage.view context model_
                        |> Element.map ServerCreateImageMsg

                ServerDetail model_ ->
                    Page.ServerDetail.view context p ( model.clientCurrentTime, model.timeZone ) model_
                        |> Element.map ServerDetailMsg

                ServerList model_ ->
                    Page.ServerList.view context
                        True
                        p
                        model_
                        |> Element.map ServerListMsg

                VolumeAttach model_ ->
                    Page.VolumeAttach.view context p model_
                        |> Element.map VolumeAttachMsg

                VolumeCreate model_ ->
                    Page.VolumeCreate.view context p model_
                        |> Element.map VolumeCreateMsg

                VolumeDetail model_ ->
                    Page.VolumeDetail.view context p model_ True
                        |> Element.map VolumeDetailMsg

                VolumeList model_ ->
                    Page.VolumeList.view context
                        True
                        p
                        model_
                        |> Element.map VolumeListMsg

                VolumeMountInstructions attachment ->
                    Page.VolumeMountInstructions.view context p attachment
                        |> Element.map SharedMsg
    in
    Element.column
        (Element.width Element.fill
            :: VH.exoColumnAttributes
        )
        [ projectNav context p projectPageModel
        , v
        ]


projectNav : View.Types.Context -> Project -> ProjectPageModel -> Element.Element OuterMsg
projectNav context p viewParams =
    let
        edges =
            VH.edges

        removeText =
            String.join " "
                [ "Remove"
                , Helpers.String.toTitleCase context.localization.unitOfTenancy
                ]
    in
    Element.row [ Element.width Element.fill, Element.spacing 10, Element.paddingEach { edges | bottom = 10 } ]
        [ Element.el
            (VH.heading2 context.palette
                -- Removing bottom border from this heading because it runs into buttons to the right and looks weird
                ++ [ Border.width 0
                   ]
            )
          <|
            Element.text <|
                UrlHelpers.hostnameFromUrl p.endpoints.keystone
                    ++ " - "
                    ++ p.auth.project.name
        , Element.el
            [ Element.alignRight ]
          <|
            Widget.iconButton
                (SH.materialStyle context.palette).button
                { icon =
                    Element.row [ Element.spacing 10 ]
                        [ Element.text removeText
                        , FeatherIcons.logOut |> FeatherIcons.toHtml [] |> Element.html |> Element.el []
                        ]
                , text = removeText
                , onPress =
                    Just <| SharedMsg <| SharedMsg.ProjectMsg p.auth.project.uuid SharedMsg.RemoveProject
                }
        , Element.el
            [ Element.alignRight
            , Element.paddingEach
                { top = 0
                , right = 15
                , bottom = 0
                , left = 0
                }
            ]
            (createButton context p.auth.project.uuid viewParams.createPopup)
        ]


createButton : View.Types.Context -> ProjectIdentifier -> Bool -> Element.Element OuterMsg
createButton context projectId expanded =
    let
        materialStyle =
            (SH.materialStyle context.palette).button

        buttonStyle =
            { materialStyle
                | container = Element.width Element.fill :: materialStyle.container
            }

        renderButton : Element.Element Never -> String -> Maybe OuterMsg -> Element.Element OuterMsg
        renderButton icon_ text onPress =
            Widget.iconButton
                buttonStyle
                { icon =
                    Element.row
                        [ Element.spacing 10
                        , Element.width Element.fill
                        ]
                        [ Element.el [] icon_
                        , Element.text text
                        ]
                , text =
                    text
                , onPress =
                    onPress
                }

        dropdown =
            Element.column
                [ Element.alignRight
                , Element.moveDown 5
                , Element.spacing 5
                , Element.paddingEach
                    { top = 5
                    , right = 6
                    , bottom = 5
                    , left = 6
                    }
                , Background.color <| SH.toElementColor context.palette.background
                , Border.shadow
                    { blur = 10
                    , color = SH.toElementColorWithOpacity context.palette.muted 0.2
                    , offset = ( 0, 2 )
                    , size = 1
                    }
                , Border.width 1
                , Border.color <| SH.toElementColor context.palette.muted
                , Border.rounded 4
                ]
                [ renderButton
                    (FeatherIcons.server |> FeatherIcons.toHtml [] |> Element.html)
                    (context.localization.virtualComputer
                        |> Helpers.String.toTitleCase
                    )
                    (Just <| SetProjectView projectId <| ImageList Page.ImageList.init)
                , renderButton
                    (FeatherIcons.hardDrive |> FeatherIcons.toHtml [] |> Element.html)
                    (context.localization.blockDevice
                        |> Helpers.String.toTitleCase
                    )
                    (Just <| SharedMsg <| SharedMsg.NavigateToView <| SharedMsg.VolumeCreate projectId)
                , renderButton
                    (FeatherIcons.key |> FeatherIcons.toHtml [] |> Element.html)
                    (context.localization.pkiPublicKeyForSsh
                        |> Helpers.String.toTitleCase
                    )
                    (Just <| SharedMsg <| SharedMsg.NavigateToView <| SharedMsg.KeypairCreate projectId)
                ]

        ( attribs, icon ) =
            if expanded then
                ( [ Element.below dropdown ]
                , FeatherIcons.chevronUp
                )

            else
                ( []
                , FeatherIcons.chevronDown
                )
    in
    Element.column
        attribs
        [ Widget.iconButton
            (SH.materialStyle context.palette).primaryButton
            { text = "Create"
            , icon =
                Element.row
                    [ Element.spacing 5 ]
                    [ Element.text "Create"
                    , Element.el []
                        (icon
                            |> FeatherIcons.toHtml []
                            |> Element.html
                        )
                    ]
            , onPress =
                Just <|
                    SharedMsg <|
                        SharedMsg.ProjectMsg projectId <|
                            SharedMsg.ToggleCreatePopup
            }
        ]
