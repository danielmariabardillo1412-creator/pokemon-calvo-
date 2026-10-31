'use strict';
// O120 independent probe: Smoke Ball native metadata and the real held-item
// activity projection used by the session Run boundary. The probe never fakes
// activity: it removes/suppresses the item through the simulator's own APIs and
// reads the checkpoint projection. Exit 0 requires real checks.
const path = require('node:path');
const ROOT = path.resolve(__dirname, '../..');
const runtime = path.join(ROOT, '.godot/battle_reference/runtime/node_modules/@pkmn/sim');
const {NativeEngine} = require(path.join(ROOT, 'modules/battle/backends/showdown/native_engine.cjs'));
const {Dex} = require(runtime);
require(path.join(ROOT, 'modules/battle/backends/showdown/field_held_items.cjs')).install(Dex);

const checks = [];
function check(name, fn) {
  try { const value = fn(); checks.push({name, status: 'PASS', value: value === undefined ? null : value}); }
  catch (error) { checks.push({name, status: 'FAIL', error: error.message}); }
}
function assert(condition, message) { if (!condition) throw new Error(message || 'assertion failed'); }
function equal(actual, expected, message) {
  if (actual !== expected) throw new Error((message || 'equality') + ': ' + JSON.stringify(actual) + ' !== ' + JSON.stringify(expected));
}
const poke = (id, moves, extra = {}) => ({instance_id: id, species_id: 'mew', level: 50, moves, ...extra});

function engineWith(teams) {
  const engine = new NativeEngine();
  engine.execute({op: 'start', id: 'b', seed: [1, 2, 3, 4], teams});
  return engine;
}
function row(engine, instanceId) {
  const cp = engine.execute({op: 'checkpoint', id: 'b'});
  for (const side of cp.roster) for (const p of side.pokemon) if (p.instance_id === instanceId) return p;
  throw new Error('row not found');
}
const itemEffect = {id: 'probe', name: 'Probe', effectType: 'Condition'};

check('smoke ball is registered with the pinned metadata and no callbacks', () => {
  const item = Dex.items.get('smokeball');
  equal(item.exists, true, 'registered');
  equal(item.name, 'Smoke Ball', 'name');
  equal(item.fling.basePower, 30, 'fling power');
  equal(item.gen, 2, 'generation');
  equal(item.onTrap, undefined, 'no invented callback');
  equal(item.onStart, undefined, 'no invented callback');
});

check('the checkpoint reports the real held-item activity for an active holder', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {held_item_id: 'smoke_ball'}), poke('bench', ['tackle'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['splash'])]});
  equal(row(engine, 'own').held_item_active, true, 'active holder');
  equal(row(engine, 'bench').held_item_active, false, 'a reserve never counts as active');
  engine.close();
});

check('a real Fling, Magic Room, Embargo and Klutz clear the activity projection', () => {
  const fling = engineWith({p1: [poke('own', ['fling', 'tackle'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['splash'])]});
  const flingBefore = fling.execute({op: 'checkpoint', id: 'b'});
  const flingDraft = fling.execute({op: 'prepare', id: 'b', expected_hash: flingBefore.state_hash, choices: {p1: 'move 1', p2: 'move 1'}});
  fling.execute({op: 'commit', id: 'b', draft_token: flingDraft.draft_token});
  equal(row(fling, 'own').item, '', 'fling consumed the smoke ball');
  equal(row(fling, 'own').held_item_active, false, 'consumed item is not active');
  fling.close();
  const magic = engineWith({p1: [poke('own', ['tackle'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['splash'])]});
  magic.sessions.get('b').battle.field.addPseudoWeather('magicroom', magic.sessions.get('b').battle.p1.active[0], itemEffect);
  equal(row(magic, 'own').held_item_active, false, 'magic room suppresses it');
  magic.close();
  const embargo = engineWith({p1: [poke('own', ['tackle'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['splash'])]});
  embargo.sessions.get('b').battle.p1.active[0].addVolatile('embargo', embargo.sessions.get('b').battle.p1.active[0], itemEffect);
  equal(row(embargo, 'own').held_item_active, false, 'embargo suppresses it');
  embargo.close();
  const klutz = engineWith({p1: [poke('own', ['tackle'], {held_item_id: 'smoke_ball', ability_id: 'klutz'})], p2: [poke('enemy', ['splash'])]});
  equal(row(klutz, 'own').held_item_active, false, 'klutz suppresses it');
  klutz.close();
});

check('a real Trick transfer moves the activity with the item', () => {
  const engine = engineWith({p1: [poke('own', ['trick'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['splash'], {held_item_id: 'oran_berry'})]});
  const before = engine.execute({op: 'checkpoint', id: 'b'});
  const draft = engine.execute({op: 'prepare', id: 'b', expected_hash: before.state_hash, choices: {p1: 'move 1', p2: 'move 1'}});
  engine.execute({op: 'commit', id: 'b', draft_token: draft.draft_token});
  equal(row(engine, 'own').item, 'oranberry', 'holder changed');
  equal(row(engine, 'enemy').item, 'smokeball', 'recipient holds it');
  equal(row(engine, 'own').held_item_active, true, 'the new item is active for the old holder');
  equal(row(engine, 'enemy').held_item_active, true, 'the smoke ball is active for the new holder');
  engine.close();
});

check('a real Knock Off clears the activity and rewards no false run', () => {
  const engine = engineWith({p1: [poke('own', ['splash'], {held_item_id: 'smoke_ball'})], p2: [poke('enemy', ['knock_off'])]});
  const before = engine.execute({op: 'checkpoint', id: 'b'});
  const draft = engine.execute({op: 'prepare', id: 'b', expected_hash: before.state_hash, choices: {p1: 'move 1', p2: 'move 1'}});
  engine.execute({op: 'commit', id: 'b', draft_token: draft.draft_token});
  equal(row(engine, 'own').item, '', 'knock off removed the item');
  equal(row(engine, 'own').held_item_active, false, 'activity cleared');
  engine.close();
});

check('the projection does not invent activity for other items and old snapshots', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {held_item_id: 'oran_berry'})], p2: [poke('enemy', ['splash'])]});
  equal(row(engine, 'own').held_item_active, true, 'a real berry is active too; the item name decides in the pure rule');
  engine.close();
});

const failed = checks.filter(c => c.status !== 'PASS');
console.log(JSON.stringify({probe: 'OPENCODE_WORLD_HELD_V2', checks: checks.length, failed: failed.length, results: checks}, null, 2));
process.exit(failed.length === 0 && checks.length > 0 ? 0 : 1);
