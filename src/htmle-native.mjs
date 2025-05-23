export function do_decode_input_file(event) {
  const file = event.target.files[0];
  return URL.createObjectURL(file);
}

export function do_drop_file(url) {
  URL.revokeObjectURL(url)
}

export function do_click_input(event) {
  event.target.parentElement.getElementsByTagName("input")[0].click();
}
