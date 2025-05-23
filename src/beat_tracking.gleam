import audio.{type Audio}
import evente
import gleam/list
import gleam/order.{Eq, Gt, Lt}
import gleam/result
import gleam/string
import htmle
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element
import lustre/element/html
import lustre/event
import time.{type Duration, type Period, type Time, type World, Duration}

type PlayState {
  Playing(period: Period(Audio), is_blinking: Bool)
  Paused
}

pub type TrackState {
  Tracking
  TrackingDone(beats: List(Time(Audio)))
}

type Model {
  ModelInitial
  Model(audio_url: String, play_state: PlayState, track_state: TrackState)
}

fn init(_: Nil) -> #(Model, Effect(Msg)) {
  #(ModelInitial, effect.none())
}

fn double_beat(beats: List(Time(Audio))) -> List(Time(Audio)) {
  use #(l, r) <- list.flat_map(list.window_by_2(beats))
  let diff = time.diff(r, l) |> time.scale(by: 0.5)
  [l, l |> time.advance(by: diff)]
}

fn next_beat(
  beats: List(Time(Audio)),
  at: Time(Audio),
) -> Result(Time(Audio), Nil) {
  use beat <- list.find(beats)
  case time.compare(beat, at) {
    Gt -> True
    Eq -> False
    Lt -> False
  }
}

fn next_beat_time(
  beats: List(Time(Audio)),
  period: Period(Audio),
  now: Time(World),
) -> Result(Time(World), Nil) {
  beats
  |> next_beat(time.relative(period, now))
  |> result.map(time.absolute(period, _))
}

fn blink(model: Model) -> Effect(Msg) {
  case model {
    Model(_, Playing(period, is_blinking: False), TrackingDone(beats)) ->
      case next_beat_time(beats, period, time.now()) {
        Ok(beat) -> {
          time.schedule(BlinkStart, at: beat)
        }
        _ -> effect.none()
      }
    _ -> effect.none()
  }
}

pub type Msg {
  DoubleBeat
  Tracked(List(Time(Audio)))
  AudioSelected(url: String)
  BlinkStart
  BlinkEnd
  Play(Duration)
  Pause
}

fn update(model: Model, message: Msg) -> #(Model, Effect(Msg)) {
  case message, model {
    // user jsut selected a audio file from the file picker
    AudioSelected(url), _ -> {
      case model {
        ModelInitial -> Nil
        Model(audio_url: url, ..) -> htmle.drop_file(url)
      }
      time.cancel()
      #(
        Model(audio_url: url, track_state: Tracking, play_state: Paused),
        audio.beat_track(url, Tracked),
      )
    }
    // the beat tracking algorithm just terminated
    Tracked(beats), Model(_, _, _) -> {
      let model = Model(..model, track_state: TrackingDone(beats))
      #(model, blink(model))
    }
    // there is a pulsation now, we should turn the screen white
    BlinkStart, Model(_, Playing(period, is_blinking: False), _) -> {
      #(
        Model(..model, play_state: Playing(period, is_blinking: True)),
        time.delay(BlinkEnd, by: time.duration(0.1)),
      )
    }
    // the screen have remained white during a 0.1 seconds, let's turn it back to black
    BlinkEnd, Model(_, Playing(period, is_blinking: True), _) -> {
      let model =
        Model(..model, play_state: Playing(period, is_blinking: False))
      #(model, blink(model))
    }
    // the user want the beat to be double (interpolate new pulsations)
    DoubleBeat, Model(_, _, TrackingDone(beats)) -> {
      let model = Model(..model, track_state: TrackingDone(double_beat(beats)))
      #(model, blink(model))
    }
    // the audio is now playing with the cursor at a certain position
    Play(audio_time), Model(..) -> {
      let now = time.now()
      let period = time.period(time.rewind(now, by: audio_time))
      let play_state = Playing(period, False)
      let model = Model(..model, play_state: play_state)
      #(model, blink(model))
    }
    // the audio is not playing anymore, we should stop the blinking
    Pause, Model(..) -> {
      time.cancel()
      #(Model(..model, play_state: Paused), effect.none())
    }
    // if a combination of message and model state that we are not expecting, just ignore it
    _, _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> element.Element(Msg) {
  html.div([attribute.class("main")], [
    html.div(
      [
        attribute.class("centered-content"),
        attribute.class(case model {
          Model(_, Playing(_, is_blinking: True), _) -> "blink-on"
          _ -> "blink-off"
        }),
      ],
      [
        case model {
          Model(_, _, Tracking) -> html.div([attribute.class("loader")], [])
          _ -> element.none()
        },
      ],
    ),
    html.audio(
      [
        attribute.controls(True),
        evente.on_play(Play),
        evente.on_pause(fn(_) { Pause }),
        case model {
          ModelInitial -> attribute.none()
          Model(audio_url: url, ..) -> attribute.src(url)
        },
      ],
      [],
    ),
    htmle.file_picker(
      ["audio/*"],
      AudioSelected,
      [attribute.class("file-picker")],
      [
        attribute.disabled(case model {
          Model(_, _, Tracking) -> True
          _ -> False
        }),
      ],
      [element.text("select audio file")],
    ),
    html.button(
      [
        event.on_click(DoubleBeat),
        attribute.disabled(case model {
          Model(_, _, TrackingDone(_)) -> False
          _ -> True
        }),
      ],
      [element.text("double beat")],
    ),
    case model {
      Model(_, _, TrackingDone(beats)) ->
        html.pre([], [
          html.code([], [
            element.text(string.inspect(
              beats |> list.map(time.elapsed) |> list.map(time.seconds),
            )),
          ]),
        ])
      _ -> element.none()
    },
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, onto: "#app", with: Nil)
}
