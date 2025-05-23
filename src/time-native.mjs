var scheduled = [];

export function do_now() {
  return Date.now();
}

export function do_cancel() {
  for (const elem of scheduled) {
    clearTimeout(elem);
  }
  scheduled = [];
}

export function do_delay(effect, duration) {
  const thisTimeout = setTimeout(() => {
    const id = scheduled.indexOf(thisTimeout);
    if (id !== -1) {
      scheduled.splice(id);
    }
    effect();
  }, duration);
  scheduled.push(thisTimeout);
}

