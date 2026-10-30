'use strict';
const run=require('./held_item_contract.cjs');
const refs=require('./held_item_reference_rows.cjs');
run({rows:refs.PROGRESSION,allRows:refs.ALL,rowCount:2,expectedMissing:7,
 output:'.godot/progression_items_v18',reportKey:'reviewed_progression',baseline:'28c550a4',label:'FIELD_HELD_NATIVE_V18'});
