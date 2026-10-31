"""Offline BG/FG sampling. No artwork, audio or battle mechanics are generated."""
import copy

FIELDS = ("bgX", "bgY", "opacity", "colorRed", "colorGreen", "colorBlue", "colorAlpha")


def bake_layers(timings, count):
    states = {name: {"name": "", **{field: 0 for field in FIELDS}} for name in ("back", "front")}
    transitions = {}
    frames = []
    for frame in range(count):
        for (layer, field), (start, duration, before, after) in list(transitions.items()):
            fraction = min(1.0, (frame - start) / duration)
            states[layer][field] = before + (after - before) * fraction
            if fraction >= 1:
                del transitions[layer, field]
        for timing in timings:
            if timing.get("@frame", 0) != frame:
                continue
            kind = timing.get("@timingType", 0)
            if kind == 0:
                continue
            if kind not in (1, 2, 3, 4):
                raise ValueError("Unsupported timing kind")
            layer = "back" if kind in (1, 2) else "front"
            if kind in (1, 3):
                states[layer] = {"name": timing.get("@name", ""),
                                 **{field: timing.get("@" + field) or 0 for field in FIELDS}}
                # Source playback evaluates active transitions BEFORE exact-frame
                # events. A Set BG/FG does not delete already scheduled fades.
                # In particular, mod then set at frame zero must fade in at f1.
            else:
                duration = timing.get("@duration", 5)
                if duration is None:
                    duration = 5
                if duration <= 0:
                    raise ValueError("Invalid layer duration")
                for field in FIELDS:
                    value = timing.get("@" + field)
                    if value is not None:
                        transitions[layer, field] = (frame, duration, states[layer][field], value)
        frames.append(copy.deepcopy(states))
    return frames
