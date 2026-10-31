'use strict';
// Reviewed item metadata missing from the pinned simulator's competitive Dex.
// No callbacks: native Fling/Knock Off/Trick/item suppression remain authoritative.
// RHH items.h 8654616b: Soothe Bell has Fling power 10; field friendship belongs
// to FieldFriendship, not an invented battle event.
// V16: 24 reviewed recovery medicines have Fling power 30 and no held effect
// in the same pinned RHH table. Using one from the bag remains a separate action.
// V17: nine training consumables and eight battle-boost consumables reviewed
// against that source: power 30, no passive held effect. Bag-use support is separate.
const medicine=(name,gen)=>Object.freeze({name,gen,fling:Object.freeze({basePower:30})});
// V20 imports only twelve reviewed IDs without passive held effects. Their bag,
// encounter and contest uses are separate contexts, not fabricated callbacks.
const misc=require('./field_misc_items_v20.json');
const miscDefinitions=Object.fromEntries(Object.entries(misc.items).map(([id,row])=>
 [id,Object.freeze({name:row.name,gen:row.gen,fling:Object.freeze({basePower:row.fling.basePower})})]));
// V2 (O120): Smoke Ball metadata only. Native Fling/Knock Off/Trick/suppression
// stay authoritative; the guaranteed Run rule lives at the session boundary and
// Cleanse Tag/Pure Incense keep their separate encounter-rate context.
const world=require('./field_world_items_v2.json');
const worldDefinitions=Object.fromEntries(Object.entries(world.items).map(([id,row])=>
 [id,Object.freeze({name:row.name,gen:row.gen,fling:Object.freeze({basePower:row.fling.basePower})})]));
// V23: the existing overworld rate items must also survive native handoff.
// Only identity/Fling metadata; their rate rule remains in the overworld helper.
const encounter=require('./field_encounter_items_v23.json');
const encounterDefinitions=Object.fromEntries(Object.entries(encounter.items).map(([id,row])=>
 [id,Object.freeze({name:row.name,gen:row.gen,fling:Object.freeze({basePower:row.fling.basePower})})]));
// V24: only native identity/Fling; explicit bag evolution is owned by inventory.
const cord=require('../../../inventory/linking_cord_profile_v24.json');
const cordDefinitions=Object.fromEntries(Object.entries(cord.items).map(([id,row])=>
 [id,Object.freeze({name:row.name,gen:row.gen,fling:Object.freeze({basePower:row.fling.basePower})})]));
const DEFINITIONS=Object.freeze({
 soothebell:Object.freeze({name:'Soothe Bell',gen:3,fling:Object.freeze({basePower:10})}),
 antidote:medicine('Antidote',1),
 awakening:medicine('Awakening',1),
 burnheal:medicine('Burn Heal',1),
 elixir:medicine('Elixir',1),
 energypowder:medicine('Energy Powder',2),
 energyroot:medicine('Energy Root',2),
 ether:medicine('Ether',1),
 freshwater:medicine('Fresh Water',1),
 fullheal:medicine('Full Heal',1),
 fullrestore:medicine('Full Restore',1),
 healpowder:medicine('Heal Powder',2),
 hyperpotion:medicine('Hyper Potion',1),
 iceheal:medicine('Ice Heal',1),
 lavacookie:medicine('Lava Cookie',3),
 lemonade:medicine('Lemonade',1),
 maxelixir:medicine('Max Elixir',1),
 maxether:medicine('Max Ether',1),
 maxpotion:medicine('Max Potion',1),
 moomoomilk:medicine('Moomoo Milk',2),
 oldgateau:medicine('Old Gateau',4),
 paralyzeheal:medicine('Paralyze Heal',1),
 potion:medicine('Potion',1),
 sodapop:medicine('Soda Pop',1),
 superpotion:medicine('Super Potion',1),
 calcium:medicine('Calcium',1),
 carbos:medicine('Carbos',1),
 hpup:medicine('HP Up',1),
 iron:medicine('Iron',1),
 ppmax:medicine('PP Max',3),
 ppup:medicine('PP Up',1),
 protein:medicine('Protein',1),
 rarecandy:medicine('Rare Candy',1),
 zinc:medicine('Zinc',3),
 direhit:medicine('Dire Hit',1),
 guardspec:medicine('Guard Spec.',1),
 xaccuracy:medicine('X Accuracy',1),
 xattack:medicine('X Attack',1),
 xdefense:medicine('X Defense',1),
 xspatk:medicine('X Sp. Atk',1),
 xspdef:medicine('X Sp. Def',4),
 xspeed:medicine('X Speed',1),
 // V18: real post-battle XP / level-evolution effects belong to progression.
 luckyegg:medicine('Lucky Egg',2),
 everstone:medicine('Everstone',2),
 ...miscDefinitions,
 ...worldDefinitions,
 ...encounterDefinitions,
 ...cordDefinitions,
});

function install(Dex) {
 // Register before constructing any battle or restoring a serialized one.
 // Include already-loaded generation Dexes so an earlier read cannot leave a
 // missing entry cached. Never replace an existing native descriptor.
 const base=Dex.mod('base');
 for(const [id,definition] of Object.entries(DEFINITIONS)) {
  if(Object.hasOwn(base.data.Items,id) && base.data.Items[id]!==definition)
   throw Error('Native field item definition conflict: '+id);
  base.data.Items[id]=definition;
 }
 for(const dex of Object.values(Dex.dexes)) {
  if(!dex.dataCache)continue;
  for(const [id,definition] of Object.entries(DEFINITIONS)) {
   if(Object.hasOwn(dex.data.Items,id) && dex.data.Items[id]!==definition)
    throw Error('Native field item definition conflict: '+id);
   dex.data.Items[id]=definition;
   dex.items.itemCache.delete(id);
  }
  dex.items.allCache=null;
 }
}
module.exports={DEFINITIONS,install};
