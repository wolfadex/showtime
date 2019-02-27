port module Main exposing (main)

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
import Json.Encode as JE
import List.Extra exposing (uncons)
import Process
import Show exposing (..)
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
    | OpenNotes
    | UpdateNotes



---- INIT ----


init : () -> ( Model, Cmd Msg )
init _ =
    ( { show =
            { title = "elm"
            , background = BackgroundColor colorGray
            , content =
                ( []
                , { id = "p1"
                  , background = BackgroundColor colorNone
                  , body = Titled "I got `NaN` problems but elm ain’t one" (BodyImage "./src/Elm_logo.svg.png" 3)
                  , notes =
                        [ "According to its website, 'A delightful language for reliable webapps'"
                        , "and, 'Delivers great performance with no runtime exceptions'"
                        , "'Beginner' friendly, doesn't expect you to memorize obscure function names or syntax"
                        , "Borrowed the title from `erlandsona` on elmlang.slack.com #general"
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
                    , body = Titled "Functions" (BodyCode "elm" """add : Int -> Int -> Int
add a b =
    a + b""")
                    , notes =
                        [ "Everything is an expression"
                        , "Pure: given the same input you always get the same output"
                        , "Typed"
                        ]
                    }
                  , { id = "p4"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Types: Aliases" (BodyCode "elm" """type alias Url = String

type alias Name = String""")
                    , notes =
                        [ "Still treated as a String"
                        , "Prevents you from assigning a say a Name to a URL"
                        , "Makes your code more clear. E.g. a function that take a Url and not any string"
                        ]
                    }
                  , { id = "p5"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Types: Records" (BodyCode "elm" """type alias Person =
    { name : String
    , age : Int
    }""")
                    , notes =
                        [ "Analagous to JavaScript objects"
                        , "Not allowed to change the number of keys or their type at runtime"
                        ]
                    }
                  , { id = "p6"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Types: Custom" (BodyCode "elm" """type Direction
    = Left
    | Right
    | Up
    | Down

type Result err a
    = Ok a
    | Err err""")
                    , notes =
                        [ "Similar to enums"
                        , "Can carry or contain data"
                        , "A request returns a result, forced to handle the result"
                        ]
                    }
                  , { id = "p7"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Conditionals & Branching" (BodyCode "elm" """case someResult of
    Ok value ->
        -- Handle the value
    Err err ->
        -- Handle the error""")
                    , notes = [ "Required to handle every case", "Catch all with underscore or named variable", "Also has if/else" ]
                    }
                  , { id = "p8"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Imports" (BodyCode "elm" """import MyModule
import YourModule as Your
import Html exposing (Html, div)""")
                    , notes =
                        [ "Import just the module, access types and functions with module name dot function name"
                        , "Rename modules on import"
                        , "Expose types and functions, after the 'as' rename"
                        ]
                    }
                  , { id = "p9"
                    , background = BackgroundColor colorGreen
                    , body = Titled "Exports" (BodyCode "elm" """module Math exposing
    ( add
    , subtract
    )""")
                    , notes =
                        [ "Everything listed her becomes accesible by others that import your module"
                        , "elm format alphabetizes these for you"
                        ]
                    }
                  , { id = "p10"
                    , background = BackgroundColor colorGreen
                    , body = Titled "TEA: The Elm Architecture" (BodyList [ BodyText "Model", BodyText "View", BodyText "Update", BodyText "and Subscriptions" ])
                    , notes = []
                    }
                  , { id = "p20"
                    , background = BackgroundColor colorRed
                    , body = Titled "Beautiful Errors???" (BodyLink "https://ellie-app.com/new" "Ellie")
                    , notes =
                        [ "https://elm-lang.org/blog/compiler-errors-for-humans"
                        , "Shows you the code you wrote and what was expected, possibly a suggestion or hint"
                        ]
                    }
                  , { id = "demo"
                    , background = BackgroundColor colorRed
                    , body = Titled "Demo" (BodyLink "https://ellie-app.com/4QRN6mxQBZKa1" "Photo App")
                    , notes =
                        [ "Http request"
                        , "Decoding JSON to elm types"
                        , "CSS"
                        ]
                    }
                  , { id = "final1"
                    , background = BackgroundColor <| Css.rgb 100 222 80
                    , body =
                        Titled "Parting Thoughts"
                            (BodyList
                                [ BodyText "Super small when comppiled"
                                , BodyText "Unit and fuzz testing"
                                , BodyText "\"After 2 years and 200,000 lines of production elm code, we got our first production runtime exception.\""
                                ]
                            )
                    , notes =
                        [ "Real world app (https://github.com/gothinkster/realworld) only 29 kb"
                        , "Real world app is a Medium clone written in most languages"
                        , "1 elm bug: (We [NoRedInk] wrote code that called Debug.crash and shipped it. That function does what it says on the tin. 😅)"
                        , "elm won't compile to production code while you use the Debug module"
                        ]
                    }
                  , { id = "final2"
                    , background = BackgroundColor <| Css.rgb 100 222 80
                    , body =
                        Titled "Learn More"
                            (BodyList
                                [ BodyText "elm-lang.org"
                                , BodyText "guide.elm-lang.org"
                                , BodyText "ellie-app.com"
                                , BodyText "Slack"
                                ]
                            )
                    , notes =
                        [ "website"
                        , "main/basic guide"
                        , "write basic examples/snippets for demos or sharing"
                        , "Super friendly"
                        ]
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
        , nextSlide (\_ -> NextPanel)
        , previousSlide (\_ -> PreviousPanel)
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

        ( "n", _ ) ->
            OpenNotes

        _ ->
            NoOp



---- PORTS ----
-- OUTGOING


port openNotes : () -> Cmd msg


port updateNotes : Value -> Cmd msg


encodeNotes : List String -> Value
encodeNotes =
    JE.list JE.string



--INCOMING


port nextSlide : (Value -> msg) -> Sub msg


port previousSlide : (Value -> msg) -> Sub msg



---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateNotes ->
            let
                ( past, present, future ) =
                    model.show.content
            in
            ( model
            , updateNotes <| encodeNotes present.notes
            )

        OpenNotes ->
            let
                ( past, present, future ) =
                    model.show.content
            in
            ( model
            , Cmd.batch
                [ openNotes ()
                , Process.sleep 800
                    |> Task.andThen (always <| Task.succeed UpdateNotes)
                    |> Task.perform identity
                ]
            )

        NextPanel ->
            let
                nextShow =
                    nextPanel model.show

                ( past, present, future ) =
                    nextShow.content
            in
            ( { model | show = nextShow }
            , updateNotes <| encodeNotes present.notes
            )

        PreviousPanel ->
            let
                nextShow =
                    previousPanel model.show

                ( past, present, future ) =
                    nextShow.content
            in
            ( { model | show = nextShow }
            , updateNotes <| encodeNotes present.notes
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

        BodyLink url str ->
            Html.a
                [ Attrs.href url, Attrs.target "_blank" ]
                [ Html.text str ]

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
