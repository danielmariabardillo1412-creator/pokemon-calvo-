"""Install reviewed existing PNGs as presentation-only beta assets. No dataset rewrites."""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil
import textwrap
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/'assets/local_item_catalog'


def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--prepared',type=Path,required=True);args=parser.parse_args()
    raw=json.loads(args.prepared.read_text(encoding='utf-8'))
    assert raw['status']=='READY' and len(raw['rows'])==364
    if (ASSETS/'manifest.json').exists():
        existing=json.loads((ASSETS/'manifest.json').read_text(encoding='utf-8'))['items']
        assert set(existing)<={r['id'] for r in raw['rows']}, 'This phase-one installer cannot downgrade a later art batch; use append_art_batch.py.'
    scope=json.loads((ROOT/'docs/current/ITEM_ART_SCOPE.json').read_text(encoding='utf-8'))['rows']
    rejected={r['id'] for r in scope if r['scope']!='RETAIN_FOR_FUNCTIONAL_REVIEW'}
    assert not {r['id'] for r in raw['rows']} & rejected
    icons=ASSETS/'icons';icons.mkdir(parents=True,exist_ok=True)
    items={}
    for row in raw['rows']:
        id=row['id'];source=Path(row['file']);assert sha(source)==row['sha256']
        with Image.open(source) as im:
            im.load();assert im.size==(row['width'],row['height']) and im.convert('RGBA').getchannel('A').getbbox()
        dest=icons/(id+'.png')
        if dest.exists():assert sha(dest)==row['sha256'],f'Existing asset differs: {id}'
        else:shutil.copyfile(source,dest)
        items[id]={k:row[k] for k in ['display_name','family','source','url','page','width','height','sha256','bytes','small_fallback']}
        items[id]['historical_review']=row['historical_review'] or row['family']=='CAPTURE_BALL'
        if id=='hopo_berry':items[id]['display_name']='Baya Hopo'
        items[id]['texture']='res://assets/local_item_catalog/icons/'+id+'.png'
    assert len(items)==364 and [id for id,r in items.items() if r['small_fallback']]==['pewter_crunchies']
    manifest={'schema_version':1,'status':'BETA_ART_ACCEPTED_AS_IS_NOT_FINAL_STYLE','date':'2026-10-28',
              'scope':'359 entries in five reviewed functional families plus the five additional art pilot items. Art inclusion is not mechanics support.',
              'ambient_setting':'Roman and Viking setting; user requests keeping these existing designs for beta and discussing redesigns later.',
              'items':items,'credits':['The Pokemon Company / Nintendo / Game Freak: original art','Serebii / Joe Merrick and contributors: item art archive','PokeAPI/sprites: Dream World samples and TM01 image; per-image URLs recorded']}
    (ASSETS/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (ASSETS/'CREDITS.md').write_text('# Arte de objetos — beta\n\nArte original: The Pokémon Company / Nintendo / Game Freak.\n'
        'Recopilación: Serebii / Joe Merrick y colaboradores; PokéAPI/sprites.\n'
        'Cada entrada de manifest.json conserva URL, procedencia, dimensiones y SHA-256.\n'
        'Se conserva el arte sin redibujar. Ambientación romana/vikinga pendiente de revisión artística.\n'
        'Rokikos usa un icono pequeño provisional. La inclusión visual no habilita un objeto en combate.\n',encoding='utf-8')
    OUT=ROOT/'.godot/item_art_beta_v1';OUT.mkdir(exist_ok=True)
    ids=list(items)
    font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',12)
    heading=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',23)
    for page in range((len(ids)+95)//96):
        sheet=Image.new('RGBA',(1440,1090),'#edf1f6');d=ImageDraw.Draw(sheet)
        d.text((16,12),f'Arte beta de objetos · lote {page+1} · imágenes originales',font=heading,fill='#172238')
        for n,id in enumerate(ids[page*96:page*96+96]):
            r=items[id];x=(n%12)*120;y=55+(n//12)*125
            d.rounded_rectangle((x+3,y,x+117,y+120),radius=6,fill='#fff2df' if r['small_fallback'] else 'white')
            im=Image.open(icons/(id+'.png')).convert('RGBA');im=ImageOps.contain(im,(76,76),Image.Resampling.LANCZOS)
            sheet.alpha_composite(im,(x+60-im.width//2,y+4+(76-im.height)//2))
            for k,line in enumerate(textwrap.wrap(r['display_name'],17)[:2]):d.text((x+6,y+82+14*k),line,font=font,fill='#172238')
        sheet.convert('RGB').save(OUT/f'contact_{page+1}.png')
    report={'status':'INSTALLED_PENDING_GODOT_CHECKS','items':len(items),'sources':dict(Counter(r['source'] for r in items.values())),
            'small_fallbacks':['pewter_crunchies'],'asset_bytes':sum(r['bytes'] for r in items.values()),
            'manifest_sha256':sha(ASSETS/'manifest.json'),'raw_art_generated':0,'data_changed':False}
    (OUT/'install.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report))


if __name__=='__main__':main()
