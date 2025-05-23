import gleam/dynamic.{type Dynamic}
import gleam/list
import lustre/attribute.{type Attribute}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn drop_file(url: String) -> Nil {
  do_drop_file(url)
}

pub fn file_picker(
  mimes: List(String),
  handler: fn(String) -> msg,
  div_attrs: List(Attribute(msg)),
  button_attrs: List(Attribute(msg)),
  children: List(Element(msg)),
) -> Element(msg) {
  html.div(div_attrs, [
    html.button(
      list.prepend(button_attrs, {
        use dyn <- event.on("click")
        do_click_input(dyn)
        Error([])
      }),
      children,
    ),
    html.input([
      attribute.style([#("display", "none")]),
      attribute.type_("file"),
      attribute.accept(mimes),
      {
        use dyn <- event.on("change")
        Ok(handler(do_decode_file_url(dyn)))
      },
    ]),
  ])
}

@external(javascript, "./htmle-native.mjs", "do_decode_input_file")
fn do_decode_file_url(dynamic: Dynamic) -> String

@external(javascript, "./htmle-native.mjs", "do_drop_file")
fn do_drop_file(url: String) -> Nil

@external(javascript, "./htmle-native.mjs", "do_click_input")
fn do_click_input(dynamic: Dynamic) -> Nil
