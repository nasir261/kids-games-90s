#!/usr/bin/env python3
"""Generate original, child-friendly 30-second music loops for the six apps."""

from __future__ import annotations

import math
import random
import struct
import wave
from array import array
from pathlib import Path


SAMPLE_RATE = 44_100
DURATION = 30.0
ROOT = Path(__file__).resolve().parents[1]


TRACKS = {
    "AppleMuncher/AppleMuncher/GameplayMusic.wav": {
        "bpm": 82,
        "roots": [60, 65, 57, 67],
        "melody": [0, 4, 7, 9, 7, 4, 2, 4, 0, 4, 7, 12, 9, 7, 4, 2],
        "lead": "triangle",
        "mood": "gentle",
    },
    "BeeBop/BeeBop/GameplayMusic.wav": {
        "bpm": 76,
        "roots": [67, 62, 64, 60],
        "melody": [7, 12, 16, 19, 16, 12, 9, 14, 7, 11, 14, 19, 17, 14, 11, 9],
        "lead": "sine",
        "mood": "gentle",
    },
    "BrickBlast/BrickBlast/GameplayMusic.wav": {
        "bpm": 80,
        "roots": [55, 60, 57, 62],
        "melody": [0, 4, 7, 9, 7, 4, 2, 0, 0, 2, 4, 7, 9, 7, 4, 2],
        "lead": "bell",
        "mood": "gentle",
    },
    "MemoryMatch/MemoryMatch/GameplayMusic.wav": {
        "bpm": 72,
        "roots": [60, 57, 65, 67],
        "melody": [0, 4, 7, 12, 9, 7, 4, 2, 0, 2, 4, 9, 7, 4, 2, 0],
        "lead": "bell",
        "mood": "gentle",
    },
    "MoleBash/MoleBash/GameplayMusic.wav": {
        "bpm": 86,
        "roots": [53, 58, 55, 60],
        "melody": [0, 4, 7, 4, 12, 7, 4, 2, 0, 5, 9, 5, 12, 9, 7, 4],
        "lead": "triangle",
        "mood": "gentle",
    },
    "PaddleBounce/PaddleBounce/GameplayMusic.wav": {
        "bpm": 78,
        "roots": [57, 60, 55, 52],
        "melody": [0, 7, 12, 7, 3, 10, 12, 10, 0, 7, 14, 12, 10, 7, 3, 7],
        "lead": "sine",
        "mood": "gentle",
    },
}


def midi_frequency(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def oscillator(kind: str, phase: float) -> float:
    sine = math.sin(phase)
    if kind == "sine":
        return sine
    if kind == "square":
        return 0.72 * (1.0 if sine >= 0 else -1.0) + 0.28 * math.sin(phase * 2)
    if kind == "triangle":
        return (2.0 / math.pi) * math.asin(sine)
    if kind == "saw":
        return 0.58 * ((phase / math.pi) % 2.0 - 1.0) + 0.42 * sine
    if kind == "bell":
        return 0.72 * sine + 0.2 * math.sin(phase * 2.01) + 0.08 * math.sin(phase * 3.97)
    if kind == "pluck":
        return 0.58 * sine + 0.3 * math.sin(phase * 2) + 0.12 * math.sin(phase * 3)
    raise ValueError(kind)


def add_note(
    left: array,
    right: array,
    start: float,
    duration: float,
    note: int,
    volume: float,
    kind: str,
    pan: float = 0.0,
) -> None:
    start_sample = max(0, int(start * SAMPLE_RATE))
    sample_count = min(int(duration * SAMPLE_RATE), len(left) - start_sample)
    if sample_count <= 0:
        return
    frequency = midi_frequency(note)
    attack = min(0.025, duration * 0.15)
    release = min(0.14, duration * 0.35)
    left_gain = math.sqrt((1.0 - pan) / 2.0)
    right_gain = math.sqrt((1.0 + pan) / 2.0)
    for offset in range(sample_count):
        t = offset / SAMPLE_RATE
        if t < attack:
            envelope = t / max(attack, 1e-6)
        elif t > duration - release:
            envelope = max(0.0, (duration - t) / max(release, 1e-6))
        else:
            envelope = 1.0
        if kind in {"bell", "pluck"}:
            envelope *= math.exp(-2.7 * t / max(duration, 0.01))
        sample = oscillator(kind, 2.0 * math.pi * frequency * t) * volume * envelope
        left[start_sample + offset] += sample * left_gain
        right[start_sample + offset] += sample * right_gain


def add_kick(left: array, right: array, start: float, volume: float) -> None:
    count = min(int(0.18 * SAMPLE_RATE), len(left) - int(start * SAMPLE_RATE))
    base = int(start * SAMPLE_RATE)
    for offset in range(max(0, count)):
        t = offset / SAMPLE_RATE
        phase = 2.0 * math.pi * (82.0 * t - 55.0 * t * t)
        sample = math.sin(phase) * math.exp(-24.0 * t) * volume
        left[base + offset] += sample * 0.707
        right[base + offset] += sample * 0.707


def add_hat(left: array, right: array, start: float, volume: float, rng: random.Random) -> None:
    count = min(int(0.055 * SAMPLE_RATE), len(left) - int(start * SAMPLE_RATE))
    base = int(start * SAMPLE_RATE)
    previous = 0.0
    for offset in range(max(0, count)):
        t = offset / SAMPLE_RATE
        noise = rng.uniform(-1.0, 1.0)
        high = noise - previous * 0.82
        previous = noise
        sample = high * math.exp(-65.0 * t) * volume
        left[base + offset] += sample * 0.58
        right[base + offset] += sample * 0.81


def compose(config: dict[str, object]) -> tuple[array, array]:
    frame_count = int(SAMPLE_RATE * DURATION)
    left = array("f", [0.0]) * frame_count
    right = array("f", [0.0]) * frame_count
    bpm = int(config["bpm"])
    beat = 60.0 / bpm
    bar = beat * 4.0
    bar_count = round(DURATION / bar)
    roots = config["roots"]
    melody = config["melody"]
    lead = str(config["lead"])
    mood = str(config["mood"])
    rng = random.Random(f"cozy-{mood}")

    for bar_index in range(bar_count):
        start = bar_index * bar
        root = roots[bar_index % len(roots)]
        is_minor = mood in {"drive", "pingpong"}
        third = 3 if is_minor else 4

        for chord_note, pan in zip((root, root + third, root + 7), (-0.45, 0.0, 0.45)):
            add_note(left, right, start, bar * 0.96, chord_note, 0.038, "sine", pan)

        for beat_index in range(4):
            beat_start = start + beat_index * beat
            bass_note = root - 12 + (7 if beat_index == 2 else 0)
            add_note(left, right, beat_start, beat * 0.72, bass_note, 0.09, "triangle", -0.12)
            if mood not in {"gentle", "flutter"} and beat_index in {0, 2}:
                add_kick(left, right, beat_start, 0.12 if mood != "drive" else 0.16)

        steps = 8 if mood == "gentle" else 16
        step_duration = bar / steps
        for step in range(steps):
            phrase_index = (bar_index * steps + step) % len(melody)
            interval = melody[phrase_index]
            note = root + 12 + interval
            note_start = start + step * step_duration
            if mood == "pingpong":
                pan = -0.72 if step % 2 == 0 else 0.72
            elif mood == "flutter":
                pan = math.sin(step * math.pi / 4.0) * 0.55
            else:
                pan = ((step % 4) - 1.5) * 0.16
            length = step_duration * (0.52 if mood in {"bounce", "playful", "drive"} else 0.82)
            volume = 0.095 if mood != "drive" else 0.08
            add_note(left, right, note_start, length, note, volume, lead, pan)
            if mood in {"drive", "playful", "bounce", "pingpong"} and step % 2 == 1:
                add_hat(left, right, note_start, 0.025 if mood != "drive" else 0.04, rng)

    delay = int(SAMPLE_RATE * (0.18 if mood != "gentle" else 0.28))
    for index in range(delay, frame_count):
        left[index] += right[index - delay] * 0.075
        right[index] += left[index - delay] * 0.065
    return left, right


def write_wave(path: Path, left: array, right: array) -> None:
    peak = max(max(abs(v) for v in left), max(abs(v) for v in right), 1e-6)
    scale = 0.62 / peak
    with wave.open(str(path), "wb") as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(SAMPLE_RATE)
        chunk = bytearray()
        for l_sample, r_sample in zip(left, right):
            l_value = int(max(-1.0, min(1.0, l_sample * scale)) * 32767)
            r_value = int(max(-1.0, min(1.0, r_sample * scale)) * 32767)
            chunk.extend(struct.pack("<hh", l_value, r_value))
            if len(chunk) >= 262_144:
                output.writeframesraw(chunk)
                chunk.clear()
        if chunk:
            output.writeframesraw(chunk)


def main() -> None:
    for relative_path, config in TRACKS.items():
        destination = ROOT / relative_path
        print(f"Generating {destination.relative_to(ROOT)}")
        left, right = compose(config)
        write_wave(destination, left, right)


if __name__ == "__main__":
    main()
