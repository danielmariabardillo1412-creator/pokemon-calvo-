"""Review sheets from actual GPU captures; never alters game assets."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parents[2] / '.godot/native_doubles_checks'
IDS = ['after_you', 'ally_switch', 'aromatic_mist', 'coaching', 'dragon_cheer',
       'follow_me', 'helping_hand', 'hold_hands', 'quash', 'rage_powder', 'spotlight']


def main():
    font = ImageFont.truetype('C:/Windows/Fonts/arial.ttf', 17)
    for side in range(2):
        for start in range(0, 11, 4):
            moves = IDS[start:start + 4]
            canvas = Image.new('RGB', (1320, len(moves) * 306), '#17342a')
            for row, move in enumerate(moves):
                for sample in range(3):
                    capture = Image.open(OUT / f'{move}_{side}_{sample}.png')
                    # Common arena rectangle across the varying control widths.
                    arena = capture.crop((12, 39, 760, 539)).resize((440, 280))
                    x, y = sample * 440, row * 306
                    canvas.paste(arena, (x, y + 24))
                    ImageDraw.Draw(canvas).text((x + 5, y + 3), f'{move} / lado {side+1} / {sample+1}', font=font, fill='white')
            canvas.save(OUT / f'review_{side}_{start}.png')
    print('DOUBLES_CONTACT_SHEETS 6 / 66 original captures')


if __name__ == '__main__':
    main()
