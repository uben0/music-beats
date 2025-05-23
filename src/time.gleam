import gleam/float
import gleam/int
import gleam/order.{type Order}
import lustre/effect.{type Effect}

pub type World

pub type Time(a) {
  Time(ms: Int)
}

pub fn now() -> Time(World) {
  Time(do_now())
}

pub type Duration {
  Duration(ms: Int)
}

pub opaque type Period(a) {
  Period(epoch: Time(World))
}

pub fn period(epoch: Time(World)) -> Period(a) {
  Period(epoch)
}

pub fn relative(period: Period(a), at: Time(World)) -> Time(a) {
  Time(at.ms - period.epoch.ms)
}

pub fn absolute(period: Period(a), at: Time(a)) -> Time(World) {
  Time(period.epoch.ms + at.ms)
}

pub fn elapsed(at: Time(a)) -> Duration {
  Duration(ms: at.ms)
}

pub fn diff(lhs: Time(a), rhs: Time(a)) -> Duration {
  Duration(ms: lhs.ms - rhs.ms)
}

pub fn advance(instant: Time(a), by duration: Duration) -> Time(a) {
  Time(ms: instant.ms + duration.ms)
}

pub fn rewind(instant: Time(a), by duration: Duration) -> Time(a) {
  Time(ms: instant.ms - duration.ms)
}

pub fn add(lhs: Duration, rhs: Duration) -> Duration {
  Duration(ms: lhs.ms + rhs.ms)
}

pub fn sub(lhs: Duration, rhs: Duration) -> Duration {
  Duration(ms: lhs.ms - rhs.ms)
}

pub fn scale(duration: Duration, by factor: Float) -> Duration {
  Duration(float.round(int.to_float(duration.ms) *. factor))
}

pub fn duration(seconds seconds: Float) -> Duration {
  Duration(ms: float.round(seconds *. 1000.0))
}

pub fn epoch() -> Time(a) {
  Time(ms: 0)
}

pub fn compare(lhs: Time(a), rhs: Time(a)) -> Order {
  int.compare(lhs.ms, rhs.ms)
}

pub fn seconds(duration: Duration) -> Float {
  int.to_float(duration.ms) /. 1000.0
}

pub fn delay(message: a, by duration: Duration) -> Effect(a) {
  use dispatch <- effect.from
  do_delay(fn() { dispatch(message) }, duration.ms)
}

pub fn schedule(message: a, at instant: Time(World)) -> Effect(a) {
  let ms = diff(instant, now()).ms
  use dispatch <- effect.from
  case ms <= 0 {
    True -> dispatch(message)
    False -> do_delay(fn() { dispatch(message) }, ms)
  }
}

pub fn cancel() -> Nil {
  do_cancel()
}

@external(javascript, "./time-native.mjs", "do_cancel")
fn do_cancel() -> Nil

@external(javascript, "./time-native.mjs", "do_now")
fn do_now() -> Int

@external(javascript, "./time-native.mjs", "do_delay")
fn do_delay(effect: fn() -> Nil, duration: Int) -> Nil
