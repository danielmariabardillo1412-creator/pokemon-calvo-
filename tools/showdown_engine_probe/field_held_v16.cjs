'use strict';
const run=require('./held_item_contract.cjs');
const refs=require('./held_item_reference_rows.cjs');
run({rows:refs.MEDICINES,allRows:refs.ALL,rowCount:24,expectedMissing:7,
 output:'.godot/field_held_v16',reportKey:'reviewed_medicines',baseline:'d0b1d8b',label:'FIELD_HELD_NATIVE_V16'});
