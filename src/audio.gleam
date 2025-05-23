import gleam/list
import lustre/effect.{type Effect}
import time.{type Time}

pub type Audio

pub fn beat_track(
  audio_url: String,
  message: fn(List(Time(Audio))) -> a,
) -> Effect(a) {
  use dispatch <- effect.from
  use beats <- do_beat_track(audio_url)
  beats
  |> list.map(time.duration)
  |> list.map(time.advance(time.epoch(), by: _))
  |> message
  |> dispatch
}

@external(javascript, "./audio-native.mjs", "do_beat_track")
fn do_beat_track(url: String, dispatch: fn(List(Float)) -> Nil) -> Nil
