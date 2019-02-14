module Notes exposing (main)

import Browser
import Browser.Dom as Dom
import Browser.Events exposing (onKeyDown)
import Css exposing (Color)
import Css.Global as Global
import Css.Transitions as Transitions
import Debug exposing (log, toString)
import Html.Events.Extra.Pointer as Pointer
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes as Attrs
import Html.Styled.Keyed as Keyed
import Html.Styled.Lazy as Lazy
import Json.Decode as JD exposing (Decoder, Value)
import List.Extra exposing (uncons)
import SyntaxHighlight
import Task


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



---- TYPES ----


type alias Show =
    { title : String
    , content : ( List Panel, Panel, List Panel )
    , background : Background
    }


type alias Panel =
    { id : String
    , background : Background
    , body : Content
    , notes : List String
    }


type Background
    = BackgroundColor Color
    | BackgroundImage String


type Content
    = Titled String Body
    | OnlyTitle String
    | OnlyBody Body


type Body
    = BodyText String
    | BodyList (List Body)
    | BodyImage String Float
    | BodyCode Language Code


type alias Language =
    String


type alias Code =
    String


type alias Model =
    { show : Show
    , pointerDown : ( Float, Float )
    }


type Msg
    = NoOp
    | NextPanel
    | PreviousPanel
    | PointerDown ( Bool, Float, Float )
    | PointerUp ( Bool, Float, Float )



---- INIT ----


init : () -> ( Model, Cmd Msg )
init _ =
    ( { show =
            { title = "How to Carl"
            , background = BackgroundColor colorGray
            , content =
                ( []
                , { id = "p1"
                  , background = BackgroundColor colorNone
                  , body = Titled "What is elm?" (BodyImage "/src/Elm_logo.svg.png" 3)
                  , notes =
                        [ "According to its website, \"A delightful language for reliable webapps\""
                        , "and, \"Delivers great performance with no runtime exceptions\""
                        ]
                  }
                , [ { id = "p2"
                    , background = BackgroundColor colorGreen
                    , body = OnlyTitle "Syntax at a Glance"
                    , notes =
                        []
                    }
                  , { id = "p3"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Functions" (BodyCode "elm" "add : Int -> Int -> Int\nadd a b =\n\ta + b")
                    , notes = []
                    }
                  , { id = "p4"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Imports" (BodyCode "elm" "import MyModule\nimport YourModule as Your\nimport Html exposing (Html, div)")
                    , notes = []
                    }
                  , { id = "p4"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Exports" (BodyCode "elm" "module Math exposing\n\t( add\n\t, subtract\n\t)")
                    , notes = []
                    }
                  , { id = "p4"
                    , background = BackgroundColor colorGreen
                    , body = Titled "TEA: The Elm Architecture" (BodyList [ BodyText "Model", BodyText "View", BodyText "Update", BodyText "and Subscriptions"])
                    , notes = []
                    }
                  , { id = "p20"
                    , background = BackgroundColor <| Css.rgb 50 60 201
                    , body = Titled "Beautiful Errors???" (BodyList [ BodyText "Show a pretty error!" ])
                    , notes = []
                    }
                  ]
                )
            }
      , pointerDown = ( 0, 0 )
      }
    , Cmd.none
    )



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyDown decodeKeyDown
        ]


decodeKeyDown : Decoder Msg
decodeKeyDown =
    JD.map2
        keyDownToMessage
        (JD.field "key" JD.string)
        (JD.field "repeat" JD.bool)


keyDownToMessage : String -> Bool -> Msg
keyDownToMessage key isRepeat =
    case ( key, isRepeat ) of
        ( "ArrowRight", False ) ->
            NextPanel

        ( " ", False ) ->
            NextPanel

        ( "Enter", False ) ->
            NextPanel

        ( "ArrowLeft", False ) ->
            PreviousPanel

        _ ->
            NoOp



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NextPanel ->
            ( { model | show = nextPanel model.show }
            , Cmd.none
            )

        PreviousPanel ->
            ( { model | show = previousPanel model.show }
            , Cmd.none
            )

        PointerDown ( isPrimary, x, y ) ->
            ( if isPrimary then
                { model | pointerDown = ( x, y ) }

              else
                model
            , Cmd.none
            )

        PointerUp ( isPrimary, x, y ) ->
            if isPrimary then
                let
                    ( xDist, yDist ) =
                        calcDistances model.pointerDown ( x, y )

                    magX =
                        abs xDist
                in
                ( { model | pointerDown = ( 0, 0 ) }
                , if magX > minTouchDistance then
                    Cmd.batch
                        [ Task.perform
                            (\_ ->
                                if xDist < 0 then
                                    NextPanel

                                else
                                    PreviousPanel
                            )
                            (Task.succeed ())
                        ]

                  else
                    Cmd.batch
                        [ Task.perform
                            (\{ viewport } ->
                                let
                                    { width } =
                                        viewport

                                    ( downX, downY ) =
                                        model.pointerDown
                                in
                                if downX < width / 2 then
                                    PreviousPanel

                                else
                                    NextPanel
                            )
                            Dom.getViewport
                        ]
                )

            else
                ( model, Cmd.none )


calcDistances : ( Float, Float ) -> ( Float, Float ) -> ( Float, Float )
calcDistances ( x1, y1 ) ( x2, y2 ) =
    ( x2 - x1, y2 - y1 )


minTouchDistance : Float
minTouchDistance =
    70


nextPanel : Show -> Show
nextPanel ({ content } as show) =
    let
        ( past, present, future ) =
            content
    in
    case uncons future of
        Just ( next, remaining ) ->
            { show
                | content = ( present :: past, next, remaining )
            }

        Nothing ->
            show


previousPanel : Show -> Show
previousPanel ({ content } as show) =
    let
        ( past, present, future ) =
            content
    in
    case uncons past of
        Just ( next, remaining ) ->
            { show
                | content = ( remaining, next, present :: future )
            }

        Nothing ->
            show



---- VIEW ----


view : Model -> Browser.Document Msg
view { show } =
    { title = "Showtime - " ++ show.title
    , body =
        [ Html.toUnstyled <| Lazy.lazy viewShow show
        ]
    }


viewShow : Show -> Html Msg
viewShow { content, background } =
    let
        ( past, present, future ) =
            content

        pastLength =
            List.length past
    in
    Keyed.node
        "div"
        [ Attrs.css
            [ Css.position Css.absolute
            , Css.top <| Css.px 0
            , Css.bottom <| Css.px 0
            , Css.left <| Css.px 0
            , Css.right <| Css.px 0
            , Css.fontFamilies [ "Source Sans Pro", "Trebuchet MS", "Lucida Grande", "Bitstream Vera Sans", "Helvetica Neue", "sans-serif" ]
            , Css.fontSize <| Css.px 48
            , Css.displayFlex
            , Css.alignItems Css.center
            , Css.justifyContent Css.center
            , case background of
                BackgroundColor color ->
                    Css.backgroundColor color

                BackgroundImage img ->
                    Css.backgroundImage <| Css.url img
            ]
        , Attrs.style "touch-action" "none"
        , Attrs.fromUnstyled <| Pointer.onDown (relativePos >> PointerDown)
        , Attrs.fromUnstyled <| Pointer.onUp (relativePos >> PointerUp)
        ]
        (List.indexedMap (\i panel -> viewPanel (-100 * toFloat (pastLength - i)) panel) (List.reverse past)
            ++ [ viewPanel 0 present ]
            ++ List.indexedMap (\i panel -> viewPanel (100 * toFloat (i + 1)) panel) future
        )


viewPanel : Float -> Panel -> ( String, Html Msg )
viewPanel xOffset { body, background, id } =
    ( id
    , Html.div
        [ Attrs.css
            [ case background of
                BackgroundColor color ->
                    Css.backgroundColor color

                BackgroundImage img ->
                    Css.backgroundImage <| Css.url img
            , Css.height <| Css.vh 100
            , Css.width <| Css.vw 100
            , Css.position Css.fixed
            , Transitions.transition
                [ Transitions.left3 500 0 Transitions.easeInOut
                ]
            , Css.left <| Css.vw xOffset
            , Css.displayFlex
            , Css.flexDirection Css.column
            , Css.alignItems Css.center
            , Css.justifyContent Css.center
            ]
        ]
      <|
        case body of
            OnlyTitle title ->
                [ viewTitle title ]

            Titled title content ->
                [ viewTitle title
                , viewBody content
                ]

            OnlyBody content ->
                [ viewBody content ]
    )


relativePos : Pointer.Event -> ( Bool, Float, Float )
relativePos event =
    let
        ( x, y ) =
            event.pointer.offsetPos
    in
    ( event.isPrimary, x, y )


colorGray : Color
colorGray =
    Css.rgb 128 128 128


colorNone : Color
colorNone =
    Css.rgba 0 0 0 0


colorRed : Color
colorRed =
    Css.rgb 205 70 70


colorGreen : Color
colorGreen =
    Css.rgb 90 214 169


viewTitle : String -> Html Msg
viewTitle str =
    Html.div
        [ Attrs.css
            [ Css.fontSize <| Css.em 1.75
            , Css.fontWeight Css.bold
            , Css.textDecoration Css.underline
            , Css.textAlign Css.center
            ]
        ]
        [ Html.text str ]


viewBody : Body -> Html Msg
viewBody body =
    case body of
        BodyText str ->
            Html.text str

        BodyImage img size ->
            Html.img
                [ Attrs.src img
                , Attrs.css
                    [ Css.width <| Css.em size
                    , Css.height <| Css.em size
                    ]
                ]
                []

        BodyCode lang code ->
            Html.div
                []
                [ Html.fromUnstyled <| SyntaxHighlight.useTheme SyntaxHighlight.monokai
                , Html.fromUnstyled <|
                    (SyntaxHighlight.elm code
                        |> Result.map (SyntaxHighlight.toBlockHtml Nothing)
                        |> Result.withDefault
                            (Html.toUnstyled <| Html.text code)
                    )
                ]

        BodyList list ->
            Html.ul
                []
            <|
                List.map
                    (\item ->
                        Html.li
                            []
                            [ viewBody item ]
                    )
                    list
