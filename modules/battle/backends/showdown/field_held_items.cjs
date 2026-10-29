'use strict';
// Reviewed item metadata missing from the pinned simulator's competitive Dex.
// No callbacks: native Fling/Knock Off/Trick/item suppression remain authoritative.
// RHH items.h 8654616b: Soothe Bell has Fling power 10; field friendship belongs
// to FieldFriendship, not an invented battle event.
const DEFINITIONS=Object.freeze({
 soothebell:Object.freeze({name:'Soothe Bell',gen:3,fling:Object.freeze({basePower:10})}),
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
