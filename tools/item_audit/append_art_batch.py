"""Append a planned presentation-only art batch, preserving all previous asset identities."""
import argparse
from collections import Counter
import hashlib, json, shutil, textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT=Path(__file__).resolve().parents[2]
ASSETS=ROOT/'assets/local_item_catalog'
OUT=ROOT/'.godot/item_art_expansion_v2'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--prepared',type=Path,required=True)
    parser.add_argument('--plan',type=Path,default=ROOT/'docs/current/ITEM_ART_EXPANSION_V2_PLAN.json')
    parser.add_argument('--evidence',type=Path,default=OUT);args=parser.parse_args()
    out=args.evidence;raw=read(args.prepared);plan=read(args.plan)
    before=read(out/'before_manifest.json');manifest=read(ASSETS/'manifest.json')
    assert raw['status']=='READY' and len(raw['rows'])==plan['expected_new_entries']
    assert plan['phase'] in ['ITEM_ART_EXPANSION_V2','ITEM_ART_UTILITY_V3'] and len(before['items'])==plan['prior_items']
    assert {r['id'] for r in raw['rows']}==set(plan['target_ids'])
    deferred=set(plan.get('deferred_art_ids',{}))|set(plan.get('deferred_content_ids',{}))|set(plan.get('deferred_style_ids',{}))
    assert not set(plan['target_ids']) & (set(plan['excluded_art_ids'])|deferred|set(before['items']))
    for id,r in before['items'].items():
        assert manifest['items'][id]==r and sha(ROOT/r['texture'].removeprefix('res://'))==r['sha256']
    for r in raw['rows']:
        src=Path(r['file']);assert sha(src)==r['sha256']
        with Image.open(src) as im:
            im.load();assert im.size==(r['width'],r['height']) and im.convert('RGBA').getchannel('A').getbbox()
        dest=ASSETS/'icons'/(r['id']+'.png')
        if dest.exists():assert sha(dest)==r['sha256']
        else:shutil.copyfile(src,dest)
        row={k:r[k] for k in ['display_name','family','source','url','page','width','height','sha256','bytes','small_fallback','historical_review']}
        row['texture']='res://assets/local_item_catalog/icons/'+r['id']+'.png'
        for k in ['visual_shared_base','thumbnail_url','thumbnail_sha256','thumbnail_mean_rgb_error','url_derivation','archive_entry','archive_sha256','additional_credit']:
            if k in r:row[k]=r[k]
        if r['family']=='MEGA_STONE':row['mechanic_note']='Arte preparado; la megaevolución sigue pendiente en el perfil de combate actual.'
        elif r['family']=='TERA_MATERIAL':row['mechanic_note']='Arte preparado; la teracristalización sigue pendiente en el perfil de combate actual.'
        elif r['family']=='Z_BAG_TOKEN':row['mechanic_note']='Cristal Z: presentación de bolsa. Solo se permiten movimientos Z de daño.'
        elif r['family']=='Z_CRYSTAL':row['mechanic_note']='Cristal Z: presentación de objeto equipado. Solo se permiten movimientos Z de daño.'
        manifest['items'][r['id']]=row
    assert len(manifest['items'])==plan['expected_total_entries']
    manifest['scope']=f"{len(manifest['items'])} beta art entries in reviewed functional families; visual registration never enables item mechanics."
    batches=manifest.get('art_batches',[{'phase':'ITEM_ART_BETA_V1','entries':364}])
    manifest['art_batches']=[b for b in batches if b['phase']!=plan['phase']]+[{'phase':plan['phase'],'entries':len(raw['rows']),'excluded_art_ids':plan['excluded_art_ids'],'deferred_art_ids':plan.get('deferred_art_ids',{}),'deferred_content_ids':plan.get('deferred_content_ids',{}),'deferred_style_ids':plan.get('deferred_style_ids',{})}]
    credit='TechSkylander1518: Dream World Items compilation; Bulbagarden Staff / Joe Merrick: sources credited by the pack'
    if credit not in manifest['credits']:manifest['credits'].append(credit)
    (ASSETS/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    cp=ASSETS/'CREDITS.md';ct=cp.read_text(encoding='utf-8')
    if 'TechSkylander1518' not in ct:cp.write_text(ct+'\nTechSkylander1518: recopilación Dream World Items (https://eeveeexpo.com/resources/689/).\nCréditos de sus fuentes: Bulbagarden Staff / Joe Merrick. Se usan sus copias de Nictostal Z y Electrostal Z.\n',encoding='utf-8')
    font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',12);heading=ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf',23)
    pages=(len(raw['rows'])+95)//96
    for page in range(pages):
        sheet=Image.new('RGBA',(1440,1090),'#edf1f6');d=ImageDraw.Draw(sheet);d.text((16,12),f'Ampliación de arte beta · lote {page+1} de {pages}',font=heading,fill='#172238')
        for n,r in enumerate(raw['rows'][page*96:page*96+96]):
            x=(n%12)*120;y=55+(n//12)*125;d.rounded_rectangle((x+3,y,x+117,y+120),radius=6,fill='white')
            im=Image.open(r['file']).convert('RGBA');im=ImageOps.contain(im,(76,76),Image.Resampling.LANCZOS);sheet.alpha_composite(im,(x+60-im.width//2,y+4+(76-im.height)//2))
            name=r['display_name']+(' · bolsa' if r['family']=='Z_BAG_TOKEN' else ' · equipado' if r['family']=='Z_CRYSTAL' else '')
            for k,line in enumerate(textwrap.wrap(name,17)[:2]):d.text((x+6,y+82+14*k),line,font=font,fill='#172238')
        sheet.convert('RGB').save(out/f'contact_{page+1}.png')
    report={'status':'INSTALLED_PENDING_VISUAL_AND_GODOT_CHECKS','phase':plan['phase'],'new_entries':len(raw['rows']),'total_entries':len(manifest['items']),
            'new_families':dict(Counter(r['family'] for r in raw['rows'])),'new_sources':dict(Counter(r['source'] for r in raw['rows'])),
            'new_bytes':sum(r['bytes'] for r in raw['rows']),'previous_entries_preserved':len(before['items']),'manifest_sha256':sha(ASSETS/'manifest.json')}
    (out/'install.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report))


if __name__=='__main__':main()
