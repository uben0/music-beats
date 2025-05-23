import gleam/dynamic.{type Dynamic}
import lustre/attribute.{type Attribute}
import lustre/event
import time.{type Duration}

pub fn on_play(message: fn(Duration) -> a) -> Attribute(a) {
  use dyn <- event.on("play")
  Ok(message(time.duration(do_decode_current_time(dyn))))
}

pub fn on_pause(message: fn(Duration) -> a) -> Attribute(a) {
  use dyn <- event.on("pause")
  Ok(message(time.duration(do_decode_current_time(dyn))))
}

@external(javascript, "./evente-native.mjs", "do_decode_audio_time")
fn do_decode_current_time(dynamic: Dynamic) -> Float
