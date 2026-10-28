import unittest
from move_layer_timing import bake_layers


class LayerTimingTests(unittest.TestCase):
    def test_mod_then_set_same_frame_does_not_erase_fade(self):
        timings = [{"@frame": 0, "@timingType": 2, "@duration": 10, "@opacity": 200},
                   {"@frame": 0, "@timingType": 1, "@name": "sun.png", "@opacity": 0},
                   {"@frame": 11, "@timingType": 2, "@duration": 8, "@opacity": 0}]
        frames = bake_layers(timings, 20)
        self.assertEqual([frames[n]["back"]["opacity"] for n in (0, 1, 10, 11, 12, 19)], [0, 20, 200, 200, 175, 0])
        self.assertTrue(all(f["back"]["name"] == "sun.png" for f in frames))

    def test_set_during_active_fade_and_independent_foreground(self):
        timings = [{"@frame": 0, "@timingType": 2, "@duration": 4, "@opacity": 200},
                   {"@frame": 2, "@timingType": 1, "@name": "new.png", "@opacity": 7},
                   {"@frame": 0, "@timingType": 3, "@name": "front.png", "@opacity": 0},
                   {"@frame": 0, "@timingType": 4, "@duration": 4, "@opacity": 100}]
        frames = bake_layers(timings, 5)
        self.assertEqual([f["back"]["opacity"] for f in frames], [0, 50, 7, 150, 200])
        self.assertEqual([f["front"]["opacity"] for f in frames], [0, 25, 50, 75, 100])

    def test_concurrent_scroll_fade_zero_and_snapshot_isolation(self):
        frames = bake_layers([{"@frame": 0, "@timingType": 1, "@name": "a.png", "@opacity": 100},
                              {"@frame": 0, "@timingType": 2, "@duration": 2, "@bgX": 20},
                              {"@frame": 1, "@timingType": 2, "@duration": 1, "@opacity": 0}], 3)
        self.assertEqual(frames[2]["back"]["opacity"], 0)
        self.assertEqual(frames[2]["back"]["bgX"], 20)
        frames[0]["back"]["name"] = "mutated"
        self.assertEqual(frames[2]["back"]["name"], "a.png")


if __name__ == "__main__":
    unittest.main()
