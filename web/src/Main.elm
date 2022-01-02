port module Main exposing (..)

import Browser
import Browser.Events as BrowserEvent
import FormatNumber as F
import FormatNumber.Locales as F
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events as Event
import Json.Decode as Decode
import Json.Decode.Pipeline as Decode
import Json.Encode as Encode



-- PORTS


port initFlux : Encode.Value -> Cmd msg


port setSettings : Encode.Value -> Cmd msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { isOpen : Bool
    , settings : Settings
    }


type alias Settings =
    { viscosity : Float
    , velocityDissipation : Float
    , fluidWidth : Int
    , fluidHeight : Int
    , diffusionIterations : Int
    , pressureIterations : Int
    , colorScheme : ColorScheme
    , lineLength : Float
    , lineWidth : Float
    , lineBeginOffset : Float
    , adjustAdvection : Float
    , noiseChannel1 : Noise
    , noiseChannel2 : Noise
    }


type ColorScheme
    = Plasma
    | Poolside
    | Pollen


type alias Noise =
    { scale : Float
    , multiplier : Float
    , offset1 : Float
    , offset2 : Float
    , offsetIncrement : Float
    , blendDuration : Float
    }


defaultSettings : Settings
defaultSettings =
    { viscosity = 0.4
    , velocityDissipation = 0.0
    , fluidWidth = 128
    , fluidHeight = 128
    , diffusionIterations = 5
    , pressureIterations = 30
    , colorScheme = Plasma
    , lineLength = 200.0
    , lineWidth = 8.0
    , lineBeginOffset = 0.4
    , adjustAdvection = 5.0
    , noiseChannel1 =
        { scale = 1.2
        , multiplier = 1.8
        , offset1 = 1.0
        , offset2 = 10.0
        , offsetIncrement = 10.0
        , blendDuration = 10.0
        }
    , noiseChannel2 =
        { scale = 20.0
        , multiplier = 0.4
        , offset1 = 1.0
        , offset2 = 1.0
        , offsetIncrement = 0.1
        , blendDuration = 0.6
        }
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        model =
            { isOpen = False
            , settings = defaultSettings
            }
    in
    ( model
    , initFlux (encodeSettings model.settings)
    )



-- UPDATE


type Msg
    = ToggleControls
    | SaveSetting SettingMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleControls ->
            ( { model | isOpen = not model.isOpen }, Cmd.none )

        SaveSetting settingToUpdate ->
            let
                newSettings =
                    updateSettings settingToUpdate model.settings
            in
            ( { model | settings = newSettings }
            , setSettings (encodeSettings newSettings)
            )


type SettingMsg
    = SetViscosity Float
    | SetVelocityDissipation Float
    | SetDiffusionIterations Int
    | SetPressureIterations Int
    | SetColorScheme ColorScheme
    | SetLineLength Float
    | SetLineWidth Float
    | SetLineBeginOffset Float
    | SetAdjustAdvection Float
    | SetNoiseChannel1 NoiseMsg
    | SetNoiseChannel2 NoiseMsg


type NoiseMsg
    = SetNoiseScale Float
    | SetNoiseMultiplier Float
    | SetNoiseOffset1 Float
    | SetNoiseOffset2 Float
    | SetNoiseOffsetIncrement Float
    | SetNoiseBlendDuration Float


updateSettings : SettingMsg -> Settings -> Settings
updateSettings msg settings =
    case msg of
        SetViscosity newViscosity ->
            { settings | viscosity = newViscosity }

        SetVelocityDissipation newVelocityDissipation ->
            { settings | velocityDissipation = newVelocityDissipation }

        SetDiffusionIterations newDiffusionIterations ->
            { settings | diffusionIterations = newDiffusionIterations }

        SetPressureIterations newPressureIterations ->
            { settings | pressureIterations = newPressureIterations }

        SetColorScheme newColorScheme ->
            { settings | colorScheme = newColorScheme }

        SetLineLength newLineLength ->
            { settings | lineLength = newLineLength }

        SetLineWidth newLineWidth ->
            { settings | lineWidth = newLineWidth }

        SetLineBeginOffset newLineBeginOffset ->
            { settings | lineBeginOffset = newLineBeginOffset }

        SetAdjustAdvection newAdjustAdvection ->
            { settings | adjustAdvection = newAdjustAdvection }

        SetNoiseChannel1 noiseMsg ->
            { settings | noiseChannel1 = updateNoise noiseMsg settings.noiseChannel1 }

        SetNoiseChannel2 noiseMsg ->
            { settings | noiseChannel2 = updateNoise noiseMsg settings.noiseChannel2 }


updateNoise : NoiseMsg -> Noise -> Noise
updateNoise msg noise =
    case msg of
        SetNoiseScale newScale ->
            { noise | scale = newScale }

        SetNoiseMultiplier newMultiplier ->
            { noise | multiplier = newMultiplier }

        SetNoiseOffset1 newOffset ->
            { noise | offset1 = newOffset }

        SetNoiseOffset2 newOffset ->
            { noise | offset2 = newOffset }

        SetNoiseOffsetIncrement newOffsetIncrement ->
            { noise | offsetIncrement = newOffsetIncrement }

        SetNoiseBlendDuration newBlendDuration ->
            { noise | blendDuration = newBlendDuration }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.isOpen then
        BrowserEvent.onKeyDown toggleControlsOnEscape

    else
        Sub.none


toggleControlsOnEscape : Decode.Decoder Msg
toggleControlsOnEscape =
    Decode.field "key" Decode.string
        |> Decode.andThen
            (\string ->
                if string == "Escape" then
                    Decode.succeed ToggleControls

                else
                    Decode.fail ""
            )



-- VIEW


type alias Control value =
    { title : String
    , description : String
    , input : Input value
    }


type Input number
    = Slider
        { min : number
        , max : number
        , step : number
        , value : number
        , onInput : String -> Msg
        , toString : number -> String
        }


view : Model -> Html Msg
view model =
    Html.div []
        [ Html.div
            [ HA.class "control-panel"
            , HA.class <|
                if model.isOpen then
                    "visible"

                else
                    ""
            ]
            [ Html.div
                [ HA.class "control-container" ]
                [ viewSettings model.settings ]
            ]
        , Html.footer []
            [ Html.ul [ HA.class "nav" ]
                [ Html.li []
                    [ Html.button
                        [ Event.onClick ToggleControls
                        , HA.class <|
                            if model.isOpen then
                                "active"

                            else
                                ""
                        ]
                        [ Html.text "Controls" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ HA.href "https://github.com/sandydoo/" ]
                        [ Html.text "© 2021 Sander Melnikov" ]
                    ]
                , Html.li []
                    [ Html.a
                        [ HA.href "https://github.com/sandydoo/flux/blob/main/LICENSE" ]
                        [ Html.text "Licensed under MIT" ]
                    ]
                ]
            ]
        ]


viewSettings : Settings -> Html Msg
viewSettings settings =
    Html.ul
        [ HA.class "control-list" ]
        [ Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.button
                [ Event.onClick ToggleControls, HA.class "text-secondary" ]
                [ Html.text "← Back" ]
            , Html.h2 [] [ Html.text "Colors" ]
            ]
        , viewButtonGroup (SetColorScheme >> SaveSetting)
            settings.colorScheme
            [ ( "Plasma", Plasma )
            , ( "Poolside", Poolside )
            , ( "Pollen", Pollen )
            ]
        , Html.h2 [ HA.class "col-span-2-md" ] [ Html.text "Fluid simulation" ]
        , viewControl <|
            Control
                "Viscosity"
                """
                A viscous fluid resists any change to its velocity.
                It spreads out and diffuses any force applied to it.
                """
                (Slider
                    { min = 0.1
                    , max = 4.0
                    , step = 0.1
                    , value = settings.viscosity
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetViscosity
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Velocity dissipation"
                """
                Velocity should decrease, or dissipate, as it travels through a fluid.
                """
                (Slider
                    { min = 0.0
                    , max = 2.0
                    , step = 0.1
                    , value = settings.velocityDissipation
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetVelocityDissipation
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Diffusion iterations"
                """
                Viscous fluids dissipate velocity through a process called “diffusion”.
                Each iteration enchances this effect and the diffusion strength is controlled by the fluid’s viscosity.
                """
                (Slider
                    { min = 0
                    , max = 30
                    , step = 1
                    , value = settings.diffusionIterations
                    , onInput =
                        \value ->
                            String.toInt value
                                |> Maybe.withDefault 0
                                |> SetDiffusionIterations
                                |> SaveSetting
                    , toString = String.fromInt
                    }
                )
        , viewControl <|
            Control
                "Pressure iterations"
                """
                Applying a force to fluid creates pressure as the fluid pushes back.
                Calculating pressure is expensive, but the fluid will look unrealistic with fewer than 20 iterations.
                """
                (Slider
                    { min = 0
                    , max = 60
                    , step = 1
                    , value = settings.pressureIterations
                    , onInput =
                        \value ->
                            String.toInt value
                                |> Maybe.withDefault 0
                                |> SetPressureIterations
                                |> SaveSetting
                    , toString = String.fromInt
                    }
                )
        , Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.h2 [] [ Html.text "Look" ] ]
        , viewControl <|
            Control
                "Line length"
                """
                The maximum length of a line.
                """
                (Slider
                    { min = 1.0
                    , max = 500.0
                    , step = 1.0
                    , value = settings.lineLength
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineLength
                                |> SaveSetting
                    , toString = formatFloat 0
                    }
                )
        , viewControl <|
            Control
                "Line width"
                """
                The maximum width of a line.
                """
                (Slider
                    { min = 1.0
                    , max = 20.0
                    , step = 0.1
                    , value = settings.lineWidth
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineWidth
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Line fade offset"
                """
                The point along a line when it begins to fade out.
                """
                (Slider
                    { min = 0.0
                    , max = 1.0
                    , step = 0.01
                    , value = settings.lineBeginOffset
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetLineBeginOffset
                                |> SaveSetting
                    , toString = formatFloat 2
                    }
                )
        , viewControl <|
            Control
                "Adjust advection"
                """
                Adjust how quickly the lines respond to changes in the fluid.
                """
                (Slider
                    { min = 0.1
                    , max = 20.0
                    , step = 0.1
                    , value = settings.adjustAdvection
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetAdjustAdvection
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , Html.div
            [ HA.class "col-span-2-md" ]
            [ Html.h2 [] [ Html.text "Noise" ] ]
        , viewNoiseChannel "Channel 1" SetNoiseChannel1 settings.noiseChannel1
        , viewNoiseChannel "Channel 2" SetNoiseChannel2 settings.noiseChannel2
        ]


viewButtonGroup : (value -> msg) -> value -> List ( String, value ) -> Html msg
viewButtonGroup onClick active options =
    let
        isActive : value -> String
        isActive value =
            if value == active then
                "active"

            else
                ""
    in
    Html.div [ HA.class "button-group col-span-2-md" ] <|
        List.map
            (\( name, value ) ->
                Html.button
                    [ HA.type_ "button"
                    , HA.class "button"
                    , HA.class (isActive value)
                    , Event.onClick (onClick value)
                    ]
                    [ Html.text name ]
            )
            options


viewNoiseChannel title setNoiseChannel noiseChannel =
    Html.div
        [ HA.class "control-list-single" ]
        [ Html.div []
            [ Html.h4 [] [ Html.text title ]
            , Html.p [ HA.class "control-description" ] [ Html.text "Simplex noise" ]
            ]
        , viewControl <|
            Control
                "Scale"
                ""
                (Slider
                    { min = 0.1
                    , max = 30.0
                    , step = 0.1
                    , value = noiseChannel.scale
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseScale
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Strength"
                ""
                (Slider
                    { min = 0.0
                    , max = 3.0
                    , step = 0.1
                    , value = noiseChannel.multiplier
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseMultiplier
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset 1"
                ""
                (Slider
                    { min = 0.0
                    , max = 100.0
                    , step = 1.0
                    , value = noiseChannel.offset1
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffset1
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset 2"
                ""
                (Slider
                    { min = 0.0
                    , max = 100.0
                    , step = 1.0
                    , value = noiseChannel.offset2
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffset2
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Offset increment"
                ""
                (Slider
                    { min = 0.0
                    , max = 1000.0
                    , step = 0.1
                    , value = noiseChannel.offsetIncrement
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseOffsetIncrement
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        , viewControl <|
            Control
                "Blend duration"
                ""
                (Slider
                    { min = 0.1
                    , max = 10.0
                    , step = 0.1
                    , value = noiseChannel.blendDuration
                    , onInput =
                        \value ->
                            String.toFloat value
                                |> Maybe.withDefault 0.0
                                |> SetNoiseBlendDuration
                                |> setNoiseChannel
                                |> SaveSetting
                    , toString = formatFloat 1
                    }
                )
        ]


viewControl : Control number -> Html Msg
viewControl { title, description, input } =
    let
        id =
            toKebabcase title
    in
    Html.li [ HA.class "control" ]
        [ Html.label
            [ HA.for id ]
            [ Html.h3
                [ HA.class "control-title" ]
                [ Html.text title ]
            , Html.p
                [ HA.class "control-description" ]
                [ Html.text description ]
            , Html.div [ HA.class "control-slider" ] <|
                case input of
                    Slider slider ->
                        [ Html.input
                            [ HA.id id
                            , HA.type_ "range"
                            , HA.min <| slider.toString slider.min
                            , HA.max <| slider.toString slider.max
                            , HA.step <| slider.toString slider.step
                            , HA.value <| slider.toString slider.value
                            , Event.onInput slider.onInput
                            ]
                            []
                        , Html.span
                            [ HA.class "control-value" ]
                            [ Html.text <| slider.toString slider.value ]
                        ]
            ]
        ]


formatFloat : Int -> Float -> String
formatFloat decimals value =
    F.format
        { decimals = F.Exact decimals
        , system = F.Western
        , thousandSeparator = ","
        , decimalSeparator = "."
        , negativePrefix = "−"
        , negativeSuffix = ""
        , positivePrefix = ""
        , positiveSuffix = ""
        , zeroPrefix = ""
        , zeroSuffix = ""
        }
        value


toKebabcase : String -> String
toKebabcase =
    let
        -- This only converts titles separated by spaces
        kebabify char =
            if char == ' ' then
                '-'

            else
                Char.toLower char
    in
    String.map kebabify



-- JSON


encodeSettings : Settings -> Encode.Value
encodeSettings settings =
    Encode.object
        [ ( "viscosity", Encode.float settings.viscosity )
        , ( "velocityDissipation", Encode.float settings.velocityDissipation )
        , ( "fluidWidth", Encode.int settings.fluidWidth )
        , ( "fluidHeight", Encode.int settings.fluidHeight )
        , ( "diffusionIterations", Encode.int settings.diffusionIterations )
        , ( "pressureIterations", Encode.int settings.pressureIterations )
        , ( "colorScheme", encodeColorScheme settings.colorScheme )
        , ( "lineLength", Encode.float settings.lineLength )
        , ( "lineWidth", Encode.float settings.lineWidth )
        , ( "lineBeginOffset", Encode.float settings.lineBeginOffset )
        , ( "adjustAdvection", Encode.float settings.adjustAdvection )
        , ( "noiseChannel1", encodeNoise settings.noiseChannel1 )
        , ( "noiseChannel2", encodeNoise settings.noiseChannel2 )
        ]


settingsDecoder =
    Decode.succeed Settings
        |> Decode.required "viscosity" Decode.float
        |> Decode.required "velocityDissipation" Decode.float
        |> Decode.required "fluidWidth" Decode.int
        |> Decode.required "fluidHeight" Decode.int
        |> Decode.required "diffusionIterations" Decode.int
        |> Decode.required "pressureIterations" Decode.int
        |> Decode.required "colorScheme" colorSchemeDecoder
        |> Decode.required "lineLength" Decode.float
        |> Decode.required "lineWidth" Decode.float
        |> Decode.required "lineBeginOffset" Decode.float
        |> Decode.required "adjustAdvection" Decode.float
        |> Decode.required "noiseChannel1" noiseDecoder
        |> Decode.required "noiseChannel2" noiseDecoder


encodeColorScheme : ColorScheme -> Encode.Value
encodeColorScheme =
    colorSchemeToString >> Encode.string


colorSchemeToString colorscheme =
    case colorscheme of
        Plasma ->
            "Plasma"

        Poolside ->
            "Poolside"

        Pollen ->
            "Pollen"


colorSchemeFromString : String -> Maybe ColorScheme
colorSchemeFromString string =
    case string of
        "Plasma" ->
            Just Plasma

        "Poolside" ->
            Just Poolside

        "Pollen" ->
            Just Pollen

        _ ->
            Nothing


colorSchemeDecoder : Decode.Decoder ColorScheme
colorSchemeDecoder =
    Decode.string
        |> Decode.andThen
            (\value ->
                case colorSchemeFromString value of
                    Just colorscheme ->
                        Decode.succeed colorscheme

                    Nothing ->
                        Decode.fail "Not a supported colorscheme"
            )


encodeNoise : Noise -> Encode.Value
encodeNoise noise =
    Encode.object
        [ ( "scale", Encode.float noise.scale )
        , ( "multiplier", Encode.float noise.multiplier )
        , ( "offset1", Encode.float noise.offset1 )
        , ( "offset2", Encode.float noise.offset2 )
        , ( "offsetIncrement", Encode.float noise.offsetIncrement )
        , ( "blendDuration", Encode.float noise.blendDuration )
        ]


noiseDecoder : Decode.Decoder Noise
noiseDecoder =
    Decode.succeed Noise
        |> Decode.required "scale" Decode.float
        |> Decode.required "multiplier" Decode.float
        |> Decode.required "offset1" Decode.float
        |> Decode.required "offset2" Decode.float
        |> Decode.required "offsetIncrement" Decode.float
        |> Decode.required "blendDuration" Decode.float
