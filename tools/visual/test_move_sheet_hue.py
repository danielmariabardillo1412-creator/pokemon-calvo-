import unittest
from PIL import Image
from move_sheet_hue import normalize_hue, rotate_sheet


class HueTests(unittest.TestCase):
    def test_primary_secondary_colors_and_direction(self):
        image = Image.new("RGBA", (6, 1))
        image.putdata([(255, 0, 0, 255), (255, 255, 0, 128), (0, 255, 0, 1),
                       (0, 255, 255, 0), (0, 0, 255, 254), (255, 0, 255, 70)])
        result = rotate_sheet(image, 120)
        self.assertEqual([result.getpixel((x, 0)) for x in range(6)], [(0, 255, 0, 255), (0, 255, 255, 128),
            (0, 0, 255, 1), (255, 0, 255, 0), (255, 0, 0, 254), (255, 255, 0, 70)])
        self.assertEqual(result.getchannel("A").tobytes(), image.getchannel("A").tobytes())

    def test_every_alpha_and_achromatic_pixels_stay_exact(self):
        image = Image.new("RGBA", (256, 3))
        image.putdata([(gray, gray, gray, a) for gray in (0, 93, 255) for a in range(256)])
        original = image.tobytes()
        for degrees in (1, 33, 120, 341, -19, 720):
            self.assertEqual(rotate_sheet(image, degrees).tobytes(), original)
        self.assertEqual(image.tobytes(), original)

    def test_integer_wrap_and_zero_identity(self):
        image = Image.new("RGBA", (1, 1), (31, 129, 208, 23))
        self.assertEqual(normalize_hue(-1), 359)
        self.assertEqual(rotate_sheet(image, -19).tobytes(), rotate_sheet(image, 341).tobytes())
        self.assertEqual(rotate_sheet(image, 720).tobytes(), image.tobytes())


if __name__ == "__main__":
    unittest.main()
