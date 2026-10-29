'use strict';
// Reviewed item metadata missing from the pinned simulator's competitive Dex.
// No callbacks: native Fling/Knock Off/Trick/item suppression remain authoritative.
// RHH items.h 8654616b: Soothe Bell has Fling power 10; field friendship belongs
// to FieldFriendship, not an invented battle event.
// V16: 24 reviewed recovery medicines have Fling power 30 and no held effect
// in the same pinned RHH table. Using one from the bag remains a separate action.
const medicine=(name,gen)=>Object.freeze({name,gen,fling:Object.freeze({basePower:30})});
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
