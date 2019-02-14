port module Notes exposing (main)

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
    { notes : List String
    , pointerDown : ( Float, Float )
    }


type Msg
    = NoOp
    | NextPanel
    | PreviousPanel
    | PointerDown ( Bool, Float, Float )
    | PointerUp ( Bool, Float, Float )
    | UpdateNotes (Result JD.Error (List String))



---- INIT ----


init : () -> ( Model, Cmd Msg )
init _ =
    ( { notes = []
      , pointerDown = ( 0, 0 )
      }
    , Cmd.none
    )



---- SUBSCRIPTIONS ----


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyDown decodeKeyDown
        , updateNotes (decodeNotes >> UpdateNotes)
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



---- PORTS ----
-- OUTGOING


port nextSlide : () -> Cmd msg


port previousSlide : () -> Cmd msg



--INCOMING


port updateNotes : (Value -> msg) -> Sub msg


decodeNotes : Value -> Result JD.Error (List String)
decodeNotes =
    JD.decodeValue
        (JD.list JD.string)


---- UPDATE ----


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        NextPanel ->
            ( model
            , nextSlide ()
            )

        PreviousPanel ->
            ( model
            , previousSlide ()
            )

        UpdateNotes res ->
            case res of
                Ok notes ->
                    ( { model | notes = notes }, Cmd.none )
                Err _ ->
                    ( { model | notes = [ "Error loading notes" ] }, Cmd.none )

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
view { notes } =
    { title = "Showtime - Notes"
    , body =
        [ Html.toUnstyled <| Lazy.lazy viewNotes notes
        ]
    }


viewNotes : List String -> Html Msg
viewNotes notes =
    Html.div
        [ Attrs.style "touch-action" "none"
        , Attrs.fromUnstyled <| Pointer.onDown (relativePos >> PointerDown)
        , Attrs.fromUnstyled <| Pointer.onUp (relativePos >> PointerUp)
        , Attrs.css
            [ Css.position Css.fixed
            , Css.top <| Css.px 0
            , Css.bottom <| Css.px 0
            , Css.left <| Css.px 0
            , Css.right <| Css.px 0
            , Css.fontFamilies [ "Source Sans Pro", "Trebuchet MS", "Lucida Grande", "Bitstream Vera Sans", "Helvetica Neue", "sans-serif" ]
            ]
        ]
        [ Html.div
            [ Attrs.css
                [ Css.backgroundColor colorGray
                , Css.fontWeight Css.bold
                , Css.fontSize <| Css.em 2
                , Css.padding2 (Css.rem 1) (Css.rem 2)
                ]
            ]
            [ Html.text "Notes:" ]
        , Html.ul
            [ ]
            <| List.map
                (\note ->
                    Html.li
                        [ Attrs.css
                            [ Css.fontSize <| Css.em 1.5 ]
                        ]
                        [ Html.text note ]
                )
                notes
        ]


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