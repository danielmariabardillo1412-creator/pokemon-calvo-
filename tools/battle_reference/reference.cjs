// Development adapter over pinned Showdown internals, never a game dependency.
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const {performance} = require('node:perf_hooks');
const [input, output, runtime] = process.argv.slice(2);
if (!input || !output || !runtime) throw Error('Usage: reference.cjs input.json output.json runtime');
const simPath = path.resolve(runtime, 'node_modules/@pkmn/sim');
const version = JSON.parse(fs.readFileSync(path.join(simPath, 'package.json'), 'utf8')).version;
if (version !== '0.10.11') throw Error(`Unsupported reference version: ${version}`);
const {Battle, Dex} = require(simPath);
const keys = ['attack', 'defense', 'special_attack', 'special_defense', 'speed', 'accuracy', 'evasion'];
const psKeys = ['atk', 'def', 'spa', 'spd', 'spe', 'accuracy', 'evasion'];
const moves = new Set(['haze', 'topsy_turvy', 'heart_swap', 'power_swap', 'guard_swap', 'acupressure', 'clear_smog', 'spectral_thief']);
const fixedMoves = new Set(['dragon_rage','sonic_boom','seismic_toss','night_shade','super_fang','natures_madness','ruination']);
const variableMoves = new Set(['electro_ball','gyro_ball','flail','reversal','crush_grip','wring_out','hard_press','return','frustration','trump_card','punishment']);
const bindingMoves = new Set(['bind','wrap','fire_spin','whirlpool','clamp','sand_tomb','magma_storm','infestation','snap_trap','thunder_cage']);
const healingMoves = new Set(['aromatherapy','heal_bell','refresh','life_dew','jungle_healing','lunar_blessing','purify','rest']);
const manifest = JSON.parse(fs.readFileSync(input, 'utf8'));
if (manifest.schema_version !== 1 || !manifest.cases?.length) throw Error('Invalid manifest');
const started = performance.now();
const results = manifest.cases.map(run);
fs.writeFileSync(output, JSON.stringify({schema_version: 1, adapter: 'showdown', version, elapsed_ms: performance.now() - started, results}, null, 2));
console.log(JSON.stringify({adapter: 'showdown', cases: results.length, errors: results.filter(r => r.status !== 'ok').length}));

function run(c) {
  let b;
  try {
    if (!({stat_stages:moves,fixed_damage:fixedMoves,variable_power:variableMoves,binding:bindingMoves,healing:healingMoves}[c.family]?.has(c.move_id))) return unavailable(c, 'Unsupported fixture family/move');
    const move = Dex.moves.get(c.move_id.replaceAll('_', ''));
    const contract = {power: move.basePower, type_id: move.type.toLowerCase(), damage_class: move.category.toLowerCase(),
      accuracy: move.accuracy === true ? -1 : move.accuracy, priority: move.priority, pp: move.pp};
    for (const [key, value] of Object.entries(contract)) {
      // Explicit normalization of the already documented frozen-data defect.
      // The Godot adapter separately requires canonical power=1. Both engines
      // must use the official current-HP effect, not a normal power-1 strike.
      if (c.family === 'fixed_damage' && c.move_id === 'ruination' && key === 'power' && c.contract.power === 1 && value === 0) continue;
      if (!move.exists || c.contract[key] !== value) return unavailable(c, `Move contract differs: ${key}: canonical=${c.contract[key]}, reference=${value}`);
    }
    if (c.move_id === 'acupressure' && Object.values(c.actor.stages).filter(v => v < 6).length > 1) return unavailable(c, 'Independent random stat selections');
    if (c.move_id === 'spectral_thief' && c.actor.stages.accuracy < c.target.stages.evasion) return unavailable(c, 'Independent accuracy rolls');
    for (const p of [c.actor, c.target]) {
      if (!Dex.species.get(p.species_id.replaceAll('_', '-')).exists || !Dex.abilities.get(p.ability_id.replaceAll('_', '-') || 'No Ability').exists) {
        return unavailable(c, 'Unknown species/ability');
      }
    }
    const set = (p, moveId) => ({name: 'Fixture', species: p.species_id.replaceAll('_', '-'), ability: p.ability_id.replaceAll('_', '-') || 'No Ability',
      moves: [moveId], item:(p.item_id ?? '').replaceAll('_',''), level: p.level ?? 50, nature: 'Hardy', ivs: {hp:31, atk:31, def:31, spa:31, spd:31, spe:31}, evs: {hp:0, atk:0, def:0, spa:0, spd:0, spe:0}});
    const bench = () => set({species_id:'mew', ability_id:''}, 'Splash');
    const actorTeam = [set(c.actor, move.id), bench()], targetTeam = [set(c.target, 'Splash'), bench()];
    if (c.lifecycle_turns === 8) actorTeam[0].moves.push('Haze');
    const sideA = c.actor_side === 'side_a';
    b = new Battle({formatid:'gen9customgame', seed:[c.seed & 65535, (c.seed >>> 16) & 65535, 17, 29],
      p1:{name:'lab-a', team:sideA ? actorTeam : targetTeam}, p2:{name:'lab-b', team:sideA ? targetTeam : actorTeam}});
    if (b.requestState === 'teampreview') b.makeChoices('team 1, 2', 'team 1, 2');
    const own = sideA ? b.p1 : b.p2, other = sideA ? b.p2 : b.p1;
    const a = own.active[0], t = other.active[0];
    for (const [p, spec, speed] of [[a,c.actor,200], [t,c.target,100]]) {
      if (!p?.storedStats || !p.baseStoredStats || !p.boosts || !p.moveSlots?.length) throw Error('Reference internal API changed');
      p.hp = p.maxhp = p.baseMaxhp = spec.max_hp ?? 20000;
      p.hp = spec.hp ?? spec.max_hp ?? 20000;
      p.happiness = spec.friendship ?? 127;
      if (spec.status_id === 'paralysis') {p.status = 'par'; p.statusState = {id:'par', target:p};}
      for (const key of ['atk','def','spa','spd','spe']) { p.storedStats[key] = key === 'spe' ? spec.speed ?? speed : 100; p.baseStoredStats[key] = p.storedStats[key]; }
      psKeys.forEach((k,i) => {p.boosts[k] = spec.stages[keys[i]];});
      if (spec.substitute_hp) {p.addVolatile('substitute'); p.volatiles.substitute.hp = spec.substitute_hp;}
    }
    psKeys.forEach((k,i) => {own.pokemon[1].boosts[k] = c.bench_stages.actor[keys[i]]; other.pokemon[1].boosts[k] = c.bench_stages.target[keys[i]];});
    if (c.family === 'healing') {
      // Set synthetic input status, never emulate a cure/heal outcome.
      for (const [p,spec] of [[a,c.actor],[t,c.target],
        [own.pokemon[1],{max_hp:101,...c.healing_bench.actor}], [other.pokemon[1],{max_hp:101,...c.healing_bench.target}]]) {
        p.hp = spec.hp; p.maxhp = p.baseMaxhp = spec.max_hp;
        p.ability = Dex.abilities.get(spec.ability_id.replaceAll('_','-') || 'No Ability').id;
        p.status = ({burn:'brn',poison:'psn',badly_poisoned:'tox',sleep:'slp',freeze:'frz',paralysis:'par'})[spec.status_id] ?? '';
        p.statusState = {id:p.status,target:p,time:3,startTime:3,stage:0};
      }
    }
    a.moveSlots[0].maxpp = c.contract.pp;
    a.moveSlots[0].pp = c.actor.pp ?? c.contract.pp;
    const before = a.moveSlots[0].pp;
    const powers = [];
    let residualDamage = 0;
    if (c.family === 'binding') {
      // Condition damage does not emit the move's AfterDamage event. Observe
      // the native damage boundary, preserving receiver, arguments and result.
      const originalDamage = b.damage;
      b.damage = function(...args) {
        const target = args[1] ?? this.event?.target;
        const effect = args[3] ?? this.effect;
        const beforeHP = target?.hp;
        const result = originalDamage.apply(this, args);
        if (target === t && effect?.id === 'partiallytrapped') residualDamage += beforeHP - target.hp;
        return result;
      };
    }
    if (c.family === 'variable_power') b.onEvent('BasePower', b.format, function (power, source, target, activeMove) {
      if (source === a && target === t && activeMove.id === move.id) powers.push(power);
      return power; // observation only; do not change reference mechanics/RNG
    });
    // Opponent Splash is an inert lab action, not admitted into the game's pool.
    b.makeChoices('move 1', 'move 1');
    if (b.log.some(line => line.startsWith('|error|'))) throw Error(b.log.filter(line => line.startsWith('|error|')).join('; '));
    const stages = p => Object.fromEntries(keys.map((k,i) => [k,p.boosts[psKeys[i]]]));
    const status = p => ({brn:'burn',psn:'poison',tox:'badly_poisoned',slp:'sleep',frz:'freeze',par:'paralysis'})[p.status] ?? '';
    const observed = p => ({stages:stages(p), substitute_present:!!p.volatiles.substitute, status_id:status(p),
      hp:p.hp, substitute_hp:p.volatiles.substitute?.hp ?? 0, knocked_out:p.hp === 0});
    const used = b.log.some(line => line.startsWith(`|move|${sideA ? 'p1a' : 'p2a'}: Fixture|${move.name}|`));
    if (powers.length > 1) throw Error('Unexpected repeated power observations');
    const bound = t.volatiles.partiallytrapped;
    const binding = {present:!!bound, blocked:t.trapped === true, residual_damage:residualDamage,
      move_id:bound ? c.move_id : '', clock_valid:!bound || (c.actor.item_id === 'grip_claw' ? bound.duration === 7 : [4,5].includes(bound.duration))};
    const lifecycle = [];
    if (c.family === 'binding' && c.lifecycle_turns === 8) {
      const snapshot = () => ({present:!!t.volatiles.partiallytrapped, blocked:t.trapped === true,
        duration:t.volatiles.partiallytrapped?.duration ?? 0, residual_damage:residualDamage});
      lifecycle.push(snapshot());
      for (let turn=2;turn<=8;turn++) {
        residualDamage=0;
        b.makeChoices(sideA ? 'move 2':'move 1', sideA ? 'move 1':'move 2');
        lifecycle.push(snapshot());
      }
    }
    return {id:c.id, status:'ok', actor:{...observed(a), pp_spent:before-a.moveSlots[0].pp, move_used:used}, target:observed(t),
      binding, lifecycle,
      healing_benches:{actor:{hp:own.pokemon[1].hp,status_id:status(own.pokemon[1])},target:{hp:other.pokemon[1].hp,status_id:status(other.pokemon[1])}},
      power:powers[0] ?? 0, contact:powers.length > 0 && !!move.flags.contact, hit_received:powers.length > 0,
      benches:{actor:stages(own.pokemon[1]), target:stages(other.pokemon[1])},
      normalizations:c.move_id === 'ruination' ? ['Frozen canonical power 1; official current-HP effect (basePower 0)'] : [],
      protocol:b.log.filter(line => /^\|(move|-(damage|boost|unboost|fail|swapboost|clearboost|clearallboost|invertboost|clearpositiveboost|activate|start|end|immune|miss))\|/.test(line)).slice(0,100)};
  } catch (error) { return {id:c.id, status:'error', reason:String(error.stack || error)}; }
  finally {b?.destroy();}
}
function unavailable(c, reason) {return {id:c.id, status:'unsupported', reason};}
