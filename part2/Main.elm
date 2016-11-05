module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


model =
    { result =
        { id = 1
        , name = "TheSeamau5/elm-checkerboardgrid-tutorial"
        , stars = 66
        }
    }


main =
    let
        elmHubHeader =
            header []
                [ h1 [] [ text "ElmHub" ]
                , span [ class "tagline" ] [ text "Like GitHub, but for Elm things." ]
                ]

        stars =
            model.result.stars

        ghubLink =
            "https://github.com/" ++ model.result.name
    in
        div [ class "content" ]
            [ elmHubHeader
            , ul [ class "results" ]
                [ li []
                    [ span [ class "star-count" ] [ text (toString stars) ]
                    , a [ href ghubLink ] [ text ghubLink ]
                    ]
                ]
            ]
