'use strict';
// Pre-implementation fixtures for ITEM_CLOSURE_V2/O100. This probe deliberately
// uses only the reviewed native engine boundary; it does not assume any future
// item helper, callback or checkpoint field. The generated file is immutable
// evidence and must be hashed before O110/O120 edits.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const { NativeEngine, ROOT, version } = require('../../modules/battle/backends/showdown/native_engine.cjs');

const DEST = path.join(ROOT, '.godot/opencode_items_v2/baseline_fixtures/native_baseline.json');
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const clean = value => JSON.parse(JSON.stringify(value, (key, item) => key === 'elapsed_ms' ? undefined : item));
const poke = (id, moves, held = '') => ({instance_id: id, species_id: 'mew', level: 50, moves, held_item_id: held});
const engine = new NativeEngine();

function start(id, teams, seed = [1, 2, 3, 4]) {
  engine.execute({op: 'start', id, seed, teams});
  return engine.sessions.get(id).battle;
}

function fixtureCheckpoint(id) {
  return clean(engine.execute({op: 'checkpoint', id}));
}

function ordinaryTurn() {
  start('ordinary_turn', {p1: [poke('ordinary_owner', ['tackle', 'reflect'])], p2: [poke('ordinary_enemy', ['splash', 'tackle'])]});
  const before = fixtureCheckpoint('ordinary_turn');
  const draft = clean(engine.execute({op: 'prepare', id: 'ordinary_turn', expected_hash: before.state_hash,
    choices: {p1: 'move 1', p2: 'move 1'}}));
  assert.equal(fixtureCheckpoint('ordinary_turn').state_hash, before.state_hash);
  const committed = clean(engine.execute({op: 'commit', id: 'ordinary_turn', draft_token: draft.draft_token}));
  assert.equal(committed.state_hash, draft.checkpoint.state_hash);
  const protocol = committed.snapshot.native.log.slice(before.snapshot.native.log.length);
  assert(protocol.some(line => line.startsWith('|move|p1a:') && line.includes('Tackle')));
  assert(protocol.some(line => line.startsWith('|move|p2a:') && line.includes('Splash')));
  return {before, draft, committed, protocol};
}

function medicineSpend() {
  const battle = start('medicine_spend', {p1: [poke('medicine_owner', ['tackle', 'reflect'])], p2: [poke('medicine_enemy', ['splash'])]});
  battle.p1.active[0].hp = 5;
  const before = fixtureCheckpoint('medicine_spend');
  const draft = clean(engine.execute({op: 'prepare', id: 'medicine_spend', expected_hash: before.state_hash,
    reaction: 'medicine', medicine: {item_id: 'potion', target_id: 'medicine_owner', move_slot: -1}, choices: {p2: 'move 1'}}));
  assert.equal(fixtureCheckpoint('medicine_spend').state_hash, before.state_hash);
  assert.equal(draft.checkpoint.roster[0].pokemon[0].hp, 25);
  const committed = clean(engine.execute({op: 'commit', id: 'medicine_spend', draft_token: draft.draft_token}));
  const protocol = committed.snapshot.native.log.slice(before.snapshot.native.log.length);
  assert(protocol.some(line => line.startsWith('|calvomedicine|') && line.endsWith('|potion')));
  assert(protocol.some(line => line.startsWith('|-heal|') && line.includes('[from] item: potion')));
  return {before, draft, committed, protocol};
}

function heldItemTransfer() {
  start('held_item_transfer', {
    p1: [poke('transfer_owner', ['trick', 'splash'], 'oran_berry')],
    p2: [poke('transfer_enemy', ['splash'], 'sitrus_berry')],
  });
  const before = fixtureCheckpoint('held_item_transfer');
  const draft = clean(engine.execute({op: 'prepare', id: 'held_item_transfer', expected_hash: before.state_hash,
    choices: {p1: 'move 1', p2: 'move 1'}}));
  const after = draft.checkpoint;
  assert.equal(after.roster[0].pokemon[0].item, 'sitrusberry');
  assert.equal(after.roster[1].pokemon[0].item, 'oranberry');
  const committed = clean(engine.execute({op: 'commit', id: 'held_item_transfer', draft_token: draft.draft_token}));
  const protocol = committed.snapshot.native.log.slice(before.snapshot.native.log.length);
  assert(protocol.some(line => line.startsWith('|-item|') && line.includes('Trick')));
  return {before, draft, committed, protocol};
}

function heldItemConsumed() {
  const battle = start('held_item_consumed', {
    p1: [poke('consume_owner', ['splash'], 'oran_berry')],
    p2: [poke('consume_enemy', ['tackle'])],
  });
  battle.p1.active[0].hp = 15;
  const before = fixtureCheckpoint('held_item_consumed');
  const draft = clean(engine.execute({op: 'prepare', id: 'held_item_consumed', expected_hash: before.state_hash,
    choices: {p1: 'move 1', p2: 'move 1'}}));
  const after = draft.checkpoint;
  assert.equal(after.roster[0].pokemon[0].item, '');
  const committed = clean(engine.execute({op: 'commit', id: 'held_item_consumed', draft_token: draft.draft_token}));
  const protocol = committed.snapshot.native.log.slice(before.snapshot.native.log.length);
  assert(protocol.some(line => line.startsWith('|-heal|') && line.includes('[from] item: Oran Berry')));
  assert(protocol.some(line => line.startsWith('|-enditem|') && line.includes('Oran Berry')));
  return {before, draft, committed, protocol};
}

const scenarios = {
  ordinary_turn: ordinaryTurn(),
  medicine_spend: medicineSpend(),
  held_item_transfer: heldItemTransfer(),
  held_item_consumed: heldItemConsumed(),
};
engine.close();

const fixture = {
  schema_version: 1,
  phase: 'OPENCODE_ITEM_CLOSURE_V2_O100_BASELINE',
  description: 'Pre-implementation native checkpoints. Never regenerate after O110/O120 changes.',
  engine: {
    version,
    source_sha256: {
      native_engine: sha(path.join(ROOT, 'modules/battle/backends/showdown/native_engine.cjs')),
      field_held_items: sha(path.join(ROOT, 'modules/battle/backends/showdown/field_held_items.cjs')),
    },
    seed: [1, 2, 3, 4],
  },
  scenarios,
};

if (process.argv.includes('--write')) {
  if (fs.existsSync(DEST)) throw Error('Baseline fixture already exists; never reseal it: ' + DEST);
  fs.mkdirSync(path.dirname(DEST), {recursive: true});
  fs.writeFileSync(DEST, JSON.stringify(fixture, null, 2) + '\n');
  console.log('OPENCODE_BASELINE_NATIVE PASS scenarios=' + Object.keys(scenarios).length + ' fixture=' + path.relative(ROOT, DEST));
} else {
  console.log('OPENCODE_BASELINE_NATIVE DRY_PASS scenarios=' + Object.keys(scenarios).length);
}
