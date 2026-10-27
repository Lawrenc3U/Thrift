#!/usr/bin/env python3
"""Create deterministic original music loops and game feedback sounds. No samples."""
from pathlib import Path
import json
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'audio'
RATE = 22050

def frequency(midi):
    return 440 * 2 ** ((midi - 69) / 12)

def add_note(track, start, midi, duration=0.7, volume=0.2, instrument='bell'):
    f = frequency(midi)
    for i in range(int(duration * RATE)):
        pos = int(start * RATE) + i
        if pos >= len(track):
            break
        t = i / RATE
        attack = min(1, t / 0.008)
        if instrument == 'pad':
            envelope = math.sin(math.pi * min(1, t / duration)) ** 0.6
            value = (math.sin(2 * math.pi * f * t) + 0.15 * math.sin(4 * math.pi * f * t)) / 1.15
        elif instrument == 'bass':
            envelope = math.exp(-5 * t / duration)
            value = math.sin(2 * math.pi * f * t) + 0.18 * math.sin(4 * math.pi * f * t)
        else:
            envelope = math.exp(-6 * t / duration)
            value = math.sin(2 * math.pi * f * t) + 0.28 * math.sin(2 * math.pi * f * 2 * t) * math.exp(-9 * t)
        track[pos] += volume * attack * envelope * value

def save(name, track):
    peak = max(1.0, max(abs(v) for v in track) * 1.08)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, value / peak)) * 32767)) for value in track))
    return {'file': f'{name}.wav', 'duration': round(len(track) / RATE, 3), 'sampleRate': RATE, 'channels': 1}

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    manifest = {}
    effects = {
        'click': ([79], .11), 'reveal': ([60, 64, 67, 72, 79], .72),
        'restore': ([67, 72, 76], .55), 'sale': ([76, 79, 84, 88], .75),
        'reward': ([60, 64, 67, 72, 76, 84], 1.1), 'place': ([67, 72], .28),
        'auction': ([48, 60, 67, 72], .6), 'error': ([55, 52], .25),
        'scrub': ([84, 86, 88], .18), 'polish': ([84, 88, 91], .38),
    }
    for name, (notes, seconds) in effects.items():
        track = [0.0] * int((seconds + .3) * RATE)
        for i, note in enumerate(notes):
            add_note(track, i * seconds / max(1, len(notes)), note, max(.15, seconds), .20)
        manifest[name] = save(name, track)
    for name, bpm, key in [('shop', 84, 60), ('town', 96, 62), ('auction_music', 112, 57)]:
        beat = 60 / bpm
        duration = 32 * beat
        track = [0.0] * int(duration * RATE)
        chords = [(0, 4, 7, 11), (9, 12, 16, 19), (5, 9, 12, 16), (7, 11, 14, 17)]
        for bar in range(8):
            chord = chords[bar % 4]
            at = bar * 4 * beat
            for tone in chord[:3]:
                add_note(track, at, key + tone - 12, 3.8 * beat, .045, 'pad')
            add_note(track, at, key + chord[0] - 24, 1.7 * beat, .17, 'bass')
            add_note(track, at + 2 * beat, key + chord[2] - 24, 1.6 * beat, .12, 'bass')
            melody = [chord[0], chord[2], chord[1], chord[3], chord[2], chord[1]]
            for i, tone in enumerate(melody):
                add_note(track, at + [0, .75, 1.5, 2, 2.75, 3.5][i] * beat, key + tone + 12, .65 * beat, .09)
        # Seam is a musical bar boundary; tiny fade prevents DC/click discontinuity.
        for i in range(int(.025 * RATE)):
            track[i] *= i / (.025 * RATE)
            track[-i - 1] *= i / (.025 * RATE)
        manifest[name] = save(name, track)
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    print(f'Generated {len(manifest)} original audio files in {OUT}')

if __name__ == '__main__':
    main()
