import Essentia from '../../essentia/essentia.js-core.es.js';
import { EssentiaWASM } from '../../essentia/essentia-wasm.es.js';
import { toList } from '../prelude.mjs';

const essentia = new Essentia(EssentiaWASM);
var audioContext = null;
const worker = new Worker(new URL("./audio-native-worker.mjs", import.meta.url), {type: "module"});

var idGenerator = 0;
var callbacks = new Map();

worker.onmessage = function(event) {
  const beats = event.data.beats;
  const id = event.data.id;
  const callback = callbacks.get(id);
  callbacks.delete(id);
  callback(toList(beats));
}

export function do_beat_track(url, dispatch) {
  const id = idGenerator;
  idGenerator += 1;
  if (audioContext == null) {
    audioContext = new AudioContext();
  }
  callbacks.set(id, dispatch);
  essentia.getAudioBufferFromURL(url, audioContext).then(audio => {
    const signal = essentia.audioBufferToMonoSignal(audio);
    worker.postMessage({id: id, sampleRate: audio.sampleRate, channelData: signal});
  });
}
