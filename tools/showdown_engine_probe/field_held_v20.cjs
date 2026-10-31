'use strict';
const run=require('./held_item_contract.cjs');
const refs=require('./held_item_reference_rows.cjs');
run({rows:refs.MISC,allRows:refs.ALL,rowCount:12,expectedMissing:7,
 output:'.godot/field_held_v20',reportKey:'reviewed_misc',baseline:'aeb2c8b1',label:'FIELD_HELD_NATIVE_V20'});
