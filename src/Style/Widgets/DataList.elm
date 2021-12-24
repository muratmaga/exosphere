module Style.Widgets.DataList exposing (DataRecord, Model, Msg, init, update, view)

import Element
import Element.Border as Border
import Element.Input as Input
import Set
import Style.Widgets.Icon as Icon


type alias Model =
    { selectedRowIds : Set.Set String }


init : Model
init =
    { selectedRowIds = Set.empty }


type Msg
    = ChangeRowSelection String Bool
    | ChangeAllRowsSelection (Set.Set String)
    | NoOp


update : Msg -> Model -> Model
update msg model =
    case msg of
        ChangeRowSelection rowId isSelected ->
            if isSelected then
                { model | selectedRowIds = Set.insert rowId model.selectedRowIds }

            else
                { model | selectedRowIds = Set.remove rowId model.selectedRowIds }

        ChangeAllRowsSelection newSelectedRowIds ->
            { model
                | selectedRowIds = newSelectedRowIds
            }

        NoOp ->
            model


type alias DataRecord record =
    { record
        | id : String
        , selectable : Bool
    }


idsSet : List (DataRecord record) -> Set.Set String
idsSet dataRecords =
    Set.fromList <| List.map (\dataRecord -> dataRecord.id) dataRecords


view :
    Model
    -> (Msg -> msg) -- convert local Msg to a consumer's msg
    -> List (Element.Attribute msg)
    -> (DataRecord record -> Element.Element msg)
    -> List (DataRecord record)
    -> List (Set.Set String -> Element.Element msg)
    -> Element.Element msg
view model toMsg styleAttrs listItemView data bulkActions =
    let
        defaultRowStyle =
            [ Element.padding 24
            , Element.spacing 20
            , Border.widthEach { top = 0, bottom = 1, left = 0, right = 0 }
            , Border.color <| Element.rgba255 0 0 0 0.16
            , Element.width Element.fill
            ]

        rowStyle : Int -> List (Element.Attribute msg)
        rowStyle i =
            if i == List.length data - 1 then
                -- Don't show divider (bottom border) for last row
                defaultRowStyle ++ [ Border.width 0 ]

            else
                defaultRowStyle
    in
    Element.column
        ([ Element.width Element.fill
         , Border.width 1
         , Border.color (Element.rgba255 0 0 0 0.1)
         , Border.rounded 4
         ]
            -- Add or override default style with passed style attributes
            ++ styleAttrs
        )
        (toolbarView model toMsg defaultRowStyle data bulkActions
            :: List.indexedMap (rowView model toMsg rowStyle listItemView) data
        )


rowView :
    Model
    -> (Msg -> msg) -- convert local Msg to a consumer's msg
    -> (Int -> List (Element.Attribute msg))
    -> (DataRecord record -> Element.Element msg)
    -> Int
    -> DataRecord record
    -> Element.Element msg
rowView model toMsg rowStyle listItemView i dataRecord =
    let
        rowCheckbox =
            if dataRecord.selectable then
                Input.checkbox [ Element.width Element.shrink ]
                    { checked = Set.member dataRecord.id model.selectedRowIds
                    , onChange = \isChecked -> ChangeRowSelection dataRecord.id isChecked
                    , icon = Input.defaultCheckbox
                    , label = Input.labelHidden ("select row " ++ String.fromInt i)
                    }

            else
                Input.checkbox [ Element.width Element.shrink ]
                    { checked = False
                    , onChange = \_ -> NoOp
                    , icon = \_ -> Icon.lock (Element.rgb255 42 42 42) 14 -- TODO: use color from context
                    , label = Input.labelHidden "locked row cannot be selected"
                    }
    in
    Element.row (rowStyle i)
        -- TODO: show rowCheckbox only when bulkActions is something
        [ rowCheckbox |> Element.map toMsg
        , listItemView dataRecord -- consumer-provided view already returns consumer's msg
        ]


toolbarView :
    Model
    -> (Msg -> msg) -- convert local Msg to a consumer's msg
    -> List (Element.Attribute msg)
    -> List (DataRecord record)
    -> List (Set.Set String -> Element.Element msg)
    -> Element.Element msg
toolbarView model toMsg rowStyle data bulkActions =
    let
        selectedRowIds : List (DataRecord record) -> Set.Set String
        selectedRowIds dataRecords =
            -- Remove those records' Ids that were deleted after being selected
            -- (This is because there seems no direct way to update the model
            -- as the data passed to the view changes)
            Set.filter
                (\selectedRowId -> Set.member selectedRowId (idsSet dataRecords))
                model.selectedRowIds

        selectableRecords =
            List.filter (\record -> record.selectable) data

        areAllRowsSelected =
            if List.isEmpty selectableRecords then
                False

            else
                selectedRowIds selectableRecords == idsSet selectableRecords
    in
    Element.row rowStyle
        ([ -- Checkbox to select all rows
           Input.checkbox [ Element.width Element.shrink ]
            { checked = areAllRowsSelected
            , onChange =
                \isChecked ->
                    if isChecked then
                        ChangeAllRowsSelection <| idsSet selectableRecords

                    else
                        ChangeAllRowsSelection Set.empty
            , icon = Input.defaultCheckbox
            , label = Input.labelRight [] (Element.text "Select All")
            }
            |> Element.map toMsg
         , Element.text
            (String.fromInt (Set.size (selectedRowIds selectableRecords))
                ++ " row(s) selected"
            )
         ]
            ++ List.map (\bulkAction -> bulkAction model.selectedRowIds)
                bulkActions
        )
