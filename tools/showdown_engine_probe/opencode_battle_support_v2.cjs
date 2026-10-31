'use strict';
// O110 independent probe: the eleven reviewed bag effects exercised through the
// real transactional boundary (prepare/abort/commit) of the pinned native engine.
// Expected values are computed here from the pinned reference contract, not read
// back from the generated profile. Exit 0 requires real checks; a bare exit is
// never a PASS.
const path = require('node:path');
const ROOT = path.resolve(__dirname, '../..');
const {NativeEngine} = require(path.join(ROOT, 'modules/battle/backends/showdown/native_engine.cjs'));

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

function engineWith(teams, seed = [1, 2, 3, 4]) {
  const engine = new NativeEngine();
  engine.execute({op: 'start', id: 'b', seed, teams});
  return engine;
}
function checkpoint(engine) { return engine.execute({op: 'checkpoint', id: 'b'}); }
function row(engine, instanceId) {
  const cp = checkpoint(engine);
  for (const side of cp.roster) for (const p of side.pokemon) if (p.instance_id === instanceId) return p;
  throw new Error('row not found: ' + instanceId);
}
function use(engine, itemId, targetId, choice = 'move 1') {
  const before = checkpoint(engine);
  const draft = engine.execute({op: 'prepare', id: 'b', expected_hash: before.state_hash, reaction: 'medicine',
    medicine: {item_id: itemId, target_id: targetId, move_slot: -1}, choices: {p2: choice}});
  return {before, draft};
}
function attempt(engine, itemId, targetId, choice = 'move 1') {
  try { return {ok: true, ...use(engine, itemId, targetId, choice)}; }
  catch (error) { return {ok: false, error: error.message}; }
}
function commit(engine, draft) {
  return engine.execute({op: 'commit', id: 'b', draft_token: draft.draft_token});
}

const X_STATS = {x_attack: 'atk', x_defense: 'def', x_sp_atk: 'spa', x_sp_def: 'spd', x_speed: 'spe', x_accuracy: 'accuracy'};

// ---------------------------------------------------------------------------
// 1. X items: exact +2 with the native +6 cap, one enemy action, friendship.
for (const [itemId, stat] of Object.entries(X_STATS)) {
  check('x item ' + itemId + ' boosts ' + stat + ' by two and the enemy acts once', () => {
    const engine = engineWith({p1: [poke('own', ['tackle', 'growl'], {friendship: 100})], p2: [poke('enemy', ['splash', 'growl'])]});
    const {before, draft} = use(engine, itemId, 'own');
    const committed = commit(engine, draft);
    const after = checkpoint(engine);
    equal(after.roster[0].pokemon[0].boosts[stat], Math.min(6, before.roster[0].pokemon[0].boosts[stat] + 2), 'capped stage');
    equal(after.roster[0].pokemon[0].friendship, 101, 'battleitem happiness below 200');
    const lines = committed.snapshot.native.log.slice(before.snapshot.native.log.length);
    equal(lines.filter(l => l.startsWith('|move|p2a')).length, 1, 'enemy moves exactly once');
    assert(lines.some(l => l.startsWith('|-boost|') && l.includes('|' + stat + '|')), 'native boost protocol present');
    assert(lines.some(l => l.startsWith('|calvomedicine|')), 'bag channel protocol present');
    engine.close();
    return stat;
  });
}

// 2. Cap: +5 -> +6 (only one effective stage), then rejection without spend/state change.
check('x item caps at +6 and rejects with no effect at the cap', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  engine.sessions.get('b').battle.boost({atk: 5}, engine.sessions.get('b').battle.p1.active[0], engine.sessions.get('b').battle.p1.active[0], {id: 'x'});
  const first = attempt(engine, 'x_attack', 'own');
  assert(first.ok, 'one more stage is accepted');
  commit(engine, first.draft);
  const afterFirst = row(engine, 'own');
  equal(afterFirst.boosts.atk, 6, 'reaches the native +6 cap');
  const frozen = checkpoint(engine);
  const second = attempt(engine, 'x_attack', 'own');
  assert(!second.ok, 'a capped use is rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'rejected use leaves the state hash untouched');
  equal(JSON.stringify(checkpoint(engine).snapshot.native.prng), JSON.stringify(frozen.snapshot.native.prng), 'rejected use draws no RNG');
  engine.close();
});

// The native ability event must run before the stat is capped. Contrary can
// lower a stat already at +6, and Simple doubles the native boost.
check('x item respects Contrary at the upper and lower caps', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {ability_id: 'contrary'})], p2: [poke('enemy', ['splash'])]});
  try {
    engine.sessions.get('b').battle.p1.active[0].boostBy({atk: 6});
    const upper = attempt(engine, 'x_attack', 'own');
    assert(upper.ok, 'Contrary lowers from +6 instead of rejecting');
    commit(engine, upper.draft);
    equal(row(engine, 'own').boosts.atk, 4, 'Contrary reverses the native boost');
    engine.sessions.get('b').battle.p1.active[0].boostBy({atk: -10});
    const before = checkpoint(engine);
    assert(!attempt(engine, 'x_attack', 'own').ok, 'Contrary at -6 has no effect');
    equal(checkpoint(engine).state_hash, before.state_hash, 'lower-cap rejection does not mutate');
  } finally { engine.close(); }
});
check('x item uses the native Simple multiplier', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {ability_id: 'simple'})], p2: [poke('enemy', ['splash'])]});
  try {
    const result = attempt(engine, 'x_attack', 'own');
    assert(result.ok, 'Simple use accepted');
    commit(engine, result.draft);
    equal(row(engine, 'own').boosts.atk, 4, 'Simple doubles two stages to four');
  } finally { engine.close(); }
});

// 3. Dire Hit: Focus Energy once, rejected while active, cleared by switching out.
check('dire hit applies Focus Energy once and rejects while active', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const first = attempt(engine, 'dire_hit', 'own');
  assert(first.ok, 'first dire hit accepted');
  commit(engine, first.draft);
  assert(row(engine, 'own').volatiles.includes('focusenergy'), 'focus energy volatile present');
  const frozen = checkpoint(engine);
  const second = attempt(engine, 'dire_hit', 'own');
  assert(!second.ok, 'second dire hit rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'rejection leaves the hash untouched');
  engine.close();
});

// 4. Guard Spec: Mist side condition, native duration, no reapply.
check('guard spec applies Mist with the native duration and rejects a reapply', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const first = attempt(engine, 'guard_spec', 'own');
  assert(first.ok, 'first guard spec accepted');
  const draftMist = first.draft.checkpoint.snapshot.native.sides[0].sideConditions.mist;
  // The candidate already executed the full turn, so the real native timer shows
  // four remaining turns: "five turns" is not a raw counter after the action.
  equal(draftMist.duration, 4, 'the candidate carries the native ticking timer');
  commit(engine, first.draft);
  const mist = checkpoint(engine).snapshot.native.sides[0].sideConditions.mist;
  assert(!!mist, 'mist side condition present after the full turn');
  equal(mist.duration, 4, 'the committed checkpoint keeps the same native timer');
  const next = engine.execute({op: 'prepare', id: 'b', expected_hash: checkpoint(engine).state_hash, choices: {p1: 'move 1', p2: 'move 1'}});
  const ticked = engine.execute({op: 'commit', id: 'b', draft_token: next.draft_token});
  equal(ticked.snapshot.native.sides[0].sideConditions.mist.duration, 3, 'a following real turn ticks the native timer');
  const frozen = checkpoint(engine);
  const second = attempt(engine, 'guard_spec', 'own');
  assert(!second.ok, 'reapply rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'rejection leaves the hash untouched');
  engine.close();
});

// 5. Flutes: exact cure, reusable twice, wrong condition rejected, target scopes.
check('blue flute cures a sleeping benched target and is reusable', () => {
  const engine = engineWith({p1: [poke('own', ['tackle']), poke('bench', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const benchAt = () => engine.sessions.get('b').battle.p1.pokemon.find(p => p.name === 'calvo_p1_1');
  benchAt().setStatus('slp', benchAt(), {id: 'probe', effectType: 'Condition'});
  const first = attempt(engine, 'blue_flute', 'bench');
  assert(first.ok, 'sleeping benched target accepted');
  commit(engine, first.draft);
  equal(row(engine, 'bench').status_id, '', 'sleep cured');
  benchAt().setStatus('slp', benchAt(), {id: 'probe', effectType: 'Condition'});
  const second = attempt(engine, 'blue_flute', 'bench');
  assert(second.ok, 'flute reusable for the second cure');
  commit(engine, second.draft);
  equal(row(engine, 'bench').status_id, '', 'second cure applied');
  const noSleep = attempt(engine, 'blue_flute', 'own');
  assert(!noSleep.ok, 'a healthy target is rejected');
  engine.close();
});
check('yellow and red flutes cure their volatile once and reject otherwise', () => {
  const engine = engineWith({p1: [poke('own', ['tackle']), poke('bench', ['tackle'])], p2: [poke('enemy', ['splash'], {gender: 'M'})]}, [3, 4, 5, 6]);
  const live = () => engine.sessions.get('b').battle;
  live().p1.active[0].gender = 'F';
  live().p2.active[0].gender = 'M';
  live().p1.active[0].addVolatile('confusion', live().p1.active[0], {id: 'probe', effectType: 'Condition'});
  const yellow = attempt(engine, 'yellow_flute', 'own');
  assert(yellow.ok, 'confused target accepted');
  commit(engine, yellow.draft);
  assert(!row(engine, 'own').volatiles.includes('confusion'), 'confusion cured');
  live().p1.active[0].addVolatile('attract', live().p2.active[0], {id: 'probe', effectType: 'Condition'});
  const red = attempt(engine, 'red_flute', 'own');
  assert(red.ok, 'attracted target accepted');
  commit(engine, red.draft);
  assert(!row(engine, 'own').volatiles.includes('attract'), 'attraction cured');
  const missing = attempt(engine, 'yellow_flute', 'own');
  assert(!missing.ok, 'no condition means rejection');
  const benchTarget = attempt(engine, 'yellow_flute', 'bench');
  assert(!benchTarget.ok, 'yellow flute requires the active battler');
  engine.close();
});
for (const status of ['brn', 'par', 'psn', 'tox', 'frz']) {
  check('blue flute rejects ' + status + ' without changing state or RNG', () => {
    const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
    try {
      const own = engine.sessions.get('b').battle.p1.active[0];
      assert(own.setStatus(status, own, {id: 'probe', effectType: 'Condition'}), 'status fixture applied');
      const before = checkpoint(engine);
      assert(!attempt(engine, 'blue_flute', 'own').ok, 'only sleep can be cured');
      const after = checkpoint(engine);
      equal(after.state_hash, before.state_hash, 'wrong-status rejection leaves the hash untouched');
      equal(JSON.stringify(after.snapshot.native.prng), JSON.stringify(before.snapshot.native.prng), 'no RNG drawn');
      equal(own.status, status, 'original status retained');
    } finally { engine.close(); }
  });
}
check('soundproof blocks the flutes without state change', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {ability_id: 'soundproof'})], p2: [poke('enemy', ['splash'])]});
  const own = engine.sessions.get('b').battle.p1.active[0];
  own.setStatus('slp', own, {id: 'probe', effectType: 'Condition'});
  const frozen = checkpoint(engine);
  const blocked = attempt(engine, 'blue_flute', 'own');
  assert(!blocked.ok, 'soundproof target rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'no mutation on immunity');
  equal(own.status, 'slp', 'sleep survives the rejected flute');
  engine.close();
});

// 6. Target and suppression contracts.
check('active-only items reject a reserve and a foreign target', () => {
  const engine = engineWith({p1: [poke('own', ['tackle']), poke('bench', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  for (const itemId of ['x_attack', 'dire_hit', 'guard_spec', 'yellow_flute', 'red_flute']) {
    const reserve = attempt(engine, itemId, 'bench');
    assert(!reserve.ok, itemId + ' must reject a reserve');
  }
  const foreign = attempt(engine, 'x_attack', 'enemy');
  assert(!foreign.ok, 'foreign target rejected');
  const frozen = checkpoint(engine);
  assert(!attempt(engine, 'x_attack', 'bench').ok, 'still rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'target rejections leave the hash untouched');
  engine.close();
});
check('embargo blocks bag effects on the target', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const own = engine.sessions.get('b').battle.p1.active[0];
  own.addVolatile('embargo', own, {id: 'probe', effectType: 'Condition'});
  const frozen = checkpoint(engine);
  const blocked = attempt(engine, 'x_attack', 'own');
  assert(!blocked.ok, 'embargo target rejected');
  equal(checkpoint(engine).state_hash, frozen.state_hash, 'embargo rejection leaves the hash untouched');
  engine.close();
});

// 7. Transaction: abort keeps the state hash and RNG identical; commit is exact.
check('prepare/abort leaves the exact state and RNG untouched', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const before = checkpoint(engine);
  const {draft} = use(engine, 'x_attack', 'own');
  assert(draft.checkpoint.state_hash !== before.state_hash, 'the candidate has the effect');
  equal(checkpoint(engine).state_hash, before.state_hash, 'prepare alone leaves the live state untouched');
  engine.execute({op: 'abort', id: 'b', draft_token: draft.draft_token});
  const after = checkpoint(engine);
  equal(after.state_hash, before.state_hash, 'abort restores the hash');
  equal(JSON.stringify(after.snapshot.native.prng), JSON.stringify(before.snapshot.native.prng), 'abort restores the RNG');
  equal(after.roster[0].pokemon[0].boosts.atk, before.roster[0].pokemon[0].boosts.atk, 'abort restores the stage');
  engine.close();
});

// 8. KO continuation: an item use can end in the existing faint/replacement flow.
check('item use rides the existing KO and replacement pipeline', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'], {current_hp: 1}), poke('bench', ['tackle'])], p2: [poke('enemy', ['tackle'])]});
  const {draft} = use(engine, 'x_attack', 'own');
  commit(engine, draft);
  const cp = checkpoint(engine);
  const own = cp.roster[0].pokemon.find(p => p.instance_id === 'own');
  equal(own.hp, 0, 'the enemy action KOs through the normal pipeline');
  assert(cp.views.p1.request.forceSwitch[0] === true, 'replacement is requested by the native request');
  engine.close();
});

// 9. Rejection never draws RNG: the frozen RNG matches after a no-effect attempt.
check('no-effect rejection draws no RNG and changes no state', () => {
  const engine = engineWith({p1: [poke('own', ['tackle'])], p2: [poke('enemy', ['splash'])]});
  const own = engine.sessions.get('b').battle.p1.active[0];
  own.boostBy({atk: 6});
  const frozen = checkpoint(engine);
  const rejected = attempt(engine, 'x_attack', 'own');
  assert(!rejected.ok, 'capped stat rejected');
  const after = checkpoint(engine);
  equal(after.state_hash, frozen.state_hash, 'state unchanged');
  equal(JSON.stringify(after.snapshot.native.prng), JSON.stringify(frozen.snapshot.native.prng), 'RNG unchanged');
  engine.close();
});

// 10. The medicine branch is untouched by the routing.
check('medicine behavior is unchanged next to the reviewed routing', () => {
  const engine = engineWith({p1: [poke('own', ['tackle', 'reflect'], {current_hp: 5})], p2: [poke('enemy', ['splash'])]});
  const {draft} = use(engine, 'potion', 'own');
  equal(draft.checkpoint.roster[0].pokemon[0].hp, 25, 'potion heals exactly its profile amount');
  engine.close();
});

const failed = checks.filter(c => c.status !== 'PASS');
const report = {probe: 'OPENCODE_BATTLE_SUPPORT_V2', checks: checks.length, failed: failed.length, results: checks};
console.log(JSON.stringify(report, null, 2));
process.exit(failed.length === 0 && checks.length > 0 ? 0 : 1);
