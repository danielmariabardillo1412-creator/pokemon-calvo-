'use strict';
const run=require('./held_item_contract.cjs');
const refs=require('./held_item_reference_rows.cjs');
run({rows:refs.TRAINING,allRows:refs.ALL,rowCount:17,expectedMissing:19,
 output:'.godot/field_held_v17',reportKey:'reviewed_training',baseline:'32286f73',label:'FIELD_HELD_NATIVE_V17'});
