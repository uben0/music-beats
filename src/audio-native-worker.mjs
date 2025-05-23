import Essentia from '../../essentia/essentia.js-core.es.js';
import { EssentiaWASM } from '../../essentia/essentia-wasm.es.js';

const essentia = new Essentia(EssentiaWASM);

self.onmessage = function(event) {
  const sampleRate = event.data.sampleRate;
  const channelData = event.data.channelData;
  const scaleFactor = 44100.0 / sampleRate;
  const channelVector = essentia.arrayToVector(channelData);
  const beatVector = essentia.BeatTrackerMultiFeature(channelVector);
  const beatArray = essentia.vectorToArray(beatVector.ticks);
  const scaledBeatArray = beatArray.map(x => x * scaleFactor);
  self.postMessage({id: event.data.id, beats: scaledBeatArray});
}

