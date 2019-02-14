module Show exposing
    ( Background(..)
    , Body(..)
    , Code
    , Content(..)
    , Language
    , Panel
    , Show
    )

import Css exposing (Color)


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
    | BodyLink Url String
    | BodyList (List Body)
    | BodyImage String Float
    | BodyCode Language Code


type alias Language =
    String


type alias Code =
    String


type alias Url =
    String
