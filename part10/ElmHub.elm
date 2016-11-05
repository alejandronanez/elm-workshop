port module ElmHub exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, target, href, defaultValue, type', checked, placeholder, value)
import Html.Events exposing (..)
import Html.App as Html
import Auth
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (..)
import String


responseDecoder : Decoder (List SearchResult)
responseDecoder =
    Json.Decode.at [ "items" ] (Json.Decode.list searchResultDecoder)


searchResultDecoder : Decoder SearchResult
searchResultDecoder =
    decode SearchResult
        |> required "id" Json.Decode.int
        |> required "full_name" Json.Decode.string
        |> required "stargazers_count" Json.Decode.int


type alias Model =
    { query : String
    , results : List SearchResult
    , errorMessage : Maybe String
    , options : SearchOptions
    }


type alias SearchOptions =
    { minStars : Int
    , minStarsError : Maybe String
    , searchIn : String
    , userFilter : String
    }


type alias SearchResult =
    { id : Int
    , name : String
    , stars : Int
    }


initialModel : Model
initialModel =
    { query = "tutorial"
    , results = []
    , errorMessage = Nothing
    , options =
        { minStars = 0
        , minStarsError = Nothing
        , searchIn = "name"
        , userFilter = ""
        }
    }


init : ( Model, Cmd Msg )
init =
    ( initialModel, githubSearch (getQueryString initialModel) )


subscriptions : Model -> Sub Msg
subscriptions _ =
    githubResponse decodeResponse


viewMinStarsError : Maybe String -> Html msg
viewMinStarsError message =
    case message of
        Nothing ->
            text " "

        Just errorMessage ->
            div [ class "stars-error" ] [ text errorMessage ]


type Msg
    = Search
      -- TODO add a constructor for Options OptionsMsg
    | SetQuery String
    | DeleteById Int
    | HandleSearchResponse (List SearchResult)
    | HandleSearchError (Maybe String)
    | DoNothing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- TODO Add a branch for Options which updates model.options
        --
        -- HINT: calling updateOptions will save a lot of time here!
        Search ->
            ( model, githubSearch (getQueryString model) )

        SetQuery query ->
            ( { model | query = query }, Cmd.none )

        HandleSearchResponse results ->
            ( { model | results = results }, Cmd.none )

        HandleSearchError error ->
            ( { model | errorMessage = error }, Cmd.none )

        DeleteById idToHide ->
            let
                newResults =
                    model.results
                        |> List.filter (\{ id } -> id /= idToHide)

                newModel =
                    { model | results = newResults }
            in
                ( newModel, Cmd.none )

        DoNothing ->
            ( model, Cmd.none )


onBlurWithTargetValue : (String -> msg) -> Attribute msg
onBlurWithTargetValue toMsg =
    on "blur" (Json.Decode.map toMsg targetValue)


updateOptions : OptionsMsg -> SearchOptions -> SearchOptions
updateOptions optionsMsg options =
    case optionsMsg of
        SetMinStars minStarsStr ->
            case String.toInt minStarsStr of
                Ok minStars ->
                    { options | minStars = minStars, minStarsError = Nothing }

                Err _ ->
                    { options
                        | minStarsError =
                            Just "Must be an integer!"
                    }

        SetSearchIn searchIn ->
            { options | searchIn = searchIn }

        SetUserFilter userFilter ->
            { options | userFilter = userFilter }


view : Model -> Html Msg
view model =
    div [ class "content" ]
        [ header []
            [ h1 [] [ text "ElmHub" ]
            , span [ class "tagline" ] [ text "Like GitHub, but for Elm things." ]
            ]
        , div [ class "search" ]
            [ text "TODO call viewOptions here. Use Html.map to avoid a type mismatch!"
            , div [ class "search-input" ]
                [ input [ class "search-query", onInput SetQuery, defaultValue model.query ] []
                , button [ class "search-button", onClick Search ] [ text "Search" ]
                ]
            ]
        , viewErrorMessage model.errorMessage
        , ul [ class "results" ] (List.map viewSearchResult model.results)
        ]


viewErrorMessage : Maybe String -> Html msg
viewErrorMessage errorMessage =
    case errorMessage of
        Just message ->
            div [ class "error" ] [ text message ]

        Nothing ->
            text ""


viewSearchResult : SearchResult -> Html Msg
viewSearchResult result =
    li []
        [ span [ class "star-count" ] [ text (toString result.stars) ]
        , a [ href ("https://github.com/" ++ result.name), target "_blank" ]
            [ text result.name ]
        , button [ class "hide-result", onClick (DeleteById result.id) ]
            [ text "X" ]
        ]


type OptionsMsg
    = SetMinStars String
    | SetSearchIn String
    | SetUserFilter String


viewOptions : SearchOptions -> Html OptionsMsg
viewOptions opts =
    div [ class "search-options" ]
        [ div [ class "search-option" ]
            [ label [ class "top-label" ] [ text "Search in" ]
            , select [ onChange SetSearchIn, value opts.searchIn ]
                [ option [ value "name" ] [ text "Name" ]
                , option [ value "description" ] [ text "Description" ]
                , option [ value "name,description" ] [ text "Name and Description" ]
                ]
            ]
        , div [ class "search-option" ]
            [ label [ class "top-label" ] [ text "Owned by" ]
            , input
                [ type' "text"
                , placeholder "Enter a username"
                , defaultValue opts.userFilter
                , onInput SetUserFilter
                ]
                []
            ]
        , div [ class "search-option" ]
            [ label [ class "top-label" ] [ text "Minimum Stars" ]
            , input
                [ type' "text"
                , onBlurWithTargetValue SetMinStars
                , defaultValue (toString opts.minStars)
                ]
                []
            , viewMinStarsError opts.minStarsError
            ]
        ]


decodeGithubResponse : Json.Decode.Value -> Msg
decodeGithubResponse value =
    case Json.Decode.decodeValue responseDecoder value of
        Ok results ->
            HandleSearchResponse results

        Err err ->
            HandleSearchError (Just err)


onChange : (String -> msg) -> Attribute msg
onChange toMsg =
    on "change" (Json.Decode.map toMsg Html.Events.targetValue)


decodeResponse : Json.Decode.Value -> Msg
decodeResponse json =
    case Json.Decode.decodeValue responseDecoder json of
        Err err ->
            HandleSearchError (Just err)

        Ok results ->
            HandleSearchResponse results


port githubSearch : String -> Cmd msg


port githubResponse : (Json.Decode.Value -> msg) -> Sub msg


{-| NOTE: The following is not part of the exercise, but is food for thought if
you have extra time.

There are several opportunities to improve this getQueryString implementation.
A nice refactor of this would not change the type annotation! It would still be:

getQueryString : Model -> String

Try identifying patterns and writing helper functions which are responsible for
handling those patterns. Then have this function call them. Things to consider:

* There's pattern of adding "+foo:bar" - could we write a helper function for this?
* In one case, if the "bar" in "+foo:bar" is empty, we want to return "" instead
  of "+foo:" - is this always true? Should our helper function always do that?
* We also join query parameters together with "=" and "&" a lot. Can we give
  that pattern a similar treatment? Should we also take "?" into account?

If you have time, give this refactor a shot and see how it turns out!

Writing something out the long way like this, and then refactoring to something
nicer, is generally the preferred way to go about building things in Elm.
-}
getQueryString : Model -> String
getQueryString model =
    -- See https://developer.github.com/v3/search/#example for how to customize!
    "access_token="
        ++ Auth.token
        ++ "&q="
        ++ model.query
        ++ "+in:"
        ++ model.options.searchIn
        ++ "+stars:>="
        ++ (toString model.options.minStars)
        ++ "+language:elm"
        ++ (if String.isEmpty model.options.userFilter then
                ""
            else
                "+user:" ++ model.options.userFilter
           )
