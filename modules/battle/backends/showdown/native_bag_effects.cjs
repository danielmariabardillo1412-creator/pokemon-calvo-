'use strict';
// O110 reviewed battle bag effects: the 11 authorized IDs (6 X items, Dire Hit,
// Guard Spec, blue/yellow/red flute). Applied on the native candidate with the
// pinned simulator's own APIs (battle.boost, addVolatile, addSideCondition and
// the Pokemon status/volatile state). No Dex callbacks, no parallel damage/RNG
// formulas and no player-selectable pass.
//
// Reference contract (pinned, credited):
// - Essentials 8c5911e4a4b07b07e832e4bb0d5d8859e88b4a9b:
//   013_Items/003_Item_BattleEffects.rb (CanUseInBattle + BattleUseOnBattler /
//   BattleUseOnPokemon), 014_Pokemon/001_Pokemon.rb#changeHappiness("battleitem"),
//   002_BattleSettings.rb (APPLY_HAPPINESS_SOFT_CAP = false).
// - RHH 8654616bd38d9b28cc7dd8f3d0b4cb030aa2d40c items.h: battleUsage
//   EFFECT_ITEM_INCREASE_STAT / EFFECT_ITEM_SET_FOCUS_ENERGY / EFFECT_ITEM_SET_MIST /
//   EFFECT_ITEM_CURE_STATUS; flutes notConsumed = TRUE.
//
// Consumption is owned by the application session: the 8 boosters spend one unit
// only after an accepted commit; the 3 flutes are reusable and spend nothing.

// X items raise two stages (declared modern profile) with the native +6 cap.
const X_STATS = Object.freeze({
  x_attack: 'atk',
  x_defense: 'def',
  x_sp_atk: 'spa',
  x_sp_def: 'spd',
  x_speed: 'spe',
  x_accuracy: 'accuracy',
});
const X_STAGES = 2;

// Flutes cure one volatile/status on the allowed target and never cure others.
const FLUTE_CURES = Object.freeze({blue_flute: 'slp', yellow_flute: 'confusion', red_flute: 'attract'});

// Essentials BattleUseOnBattler items require the active battler. Blue Flute uses
// BattleUseOnPokemon and can also cure a benched sleeping party member.
const ACTIVE_ONLY = new Set([
  'x_attack', 'x_defense', 'x_sp_atk', 'x_sp_def', 'x_speed', 'x_accuracy',
  'dire_hit', 'guard_spec', 'yellow_flute', 'red_flute',
]);

function reviewed(id) {
  return Object.hasOwn(X_STATS, id) || Object.hasOwn(FLUTE_CURES, id) ||
    id === 'dire_hit' || id === 'guard_spec';
}

function effectFor(id) {
  // The medicine channel labels its lines with the canonical bag ID; keep the same
  // convention so existing adapter rows keep one meaning.
  return {id: id.replace(/_/g, ''), name: id, effectType: 'Item'};
}

function resolveTarget(session, battle, itemId, targetId) {
  const name = Object.keys(session.identities).find(n => session.identities[n] === targetId);
  const p = name ? battle.p1.pokemon.find(p => p.name === name) : null;
  if (!p || p.hp <= 0 || p.fainted) throw Error('Invalid bag effect target');
  if (ACTIVE_ONLY.has(itemId) && (!p.isActive || battle.p1.active[0] !== p)) {
    throw Error('Bag effect requires the active battler');
  }
  return p;
}

function emitFor(battle, p) {
  // Never reveal an unrevealed reserve's exact state to p2 (same rule as medicine).
  const ident = `${p.side.id}: ${p.name}`;
  return (tag, ...fields) => {
    if (p.isActive) battle.add(tag, p, ...fields);
    else battle.addSplit('p1', [tag, ident, ...fields.map(f => typeof f === 'function' ? f.call(p).secret : f)], []);
  };
}

function grantBattleItemFriendship(p) {
  // Essentials changeHappiness("battleitem") gain = [1, 1, 0][happiness / 100]:
  // +1 below 200, no gain at 200+. The pinned settings keep
  // APPLY_HAPPINESS_SOFT_CAP = false, so the only clamp is 0..255. Soothe Bell's
  // (gain * 1.5).floor keeps a gain of 1 unchanged. Origin-map and Luxury Ball
  // bonuses need absent creature metadata and are not invented here.
  const current = Number.isInteger(p.happiness) ? p.happiness : 0;
  if (current < 200) p.happiness = Math.min(255, current + 1);
  else p.happiness = current;
  // The simulator serializes set.happiness, not the live field: keep both in sync
  // so a prepared candidate survives fork/restore and projects the real value.
  p.set.happiness = p.happiness;
}

function applyBagEffect(session, battle, command) {
  const itemId = command?.item_id;
  if (!reviewed(itemId)) throw Error('Unreviewed bag effect');
  const p = resolveTarget(session, battle, itemId, command?.target_id);
  if (p.volatiles.embargo) throw Error('Embargo prevents bag item use');
  const emit = emitFor(battle, p);

  if (Object.hasOwn(X_STATS, itemId)) {
    const stat = X_STATS[itemId];
    // The native ChangeBoost event handles Contrary/Simple before capping.
    // A raw +2 cap check here would incorrectly reject Contrary at +6.
    // Failure discards the prepared candidate without publishing state or spend.
    emit('calvomedicine', itemId);
    if (!battle.boost({[stat]: X_STAGES}, p, p, effectFor(itemId))) throw Error('Bag effect has no effect');
    grantBattleItemFriendship(p);
    return;
  }

  if (itemId === 'dire_hit') {
    if (p.volatiles.focusenergy) throw Error('Bag effect has no effect');
    emit('calvomedicine', itemId);
    if (!p.addVolatile('focusenergy', p, effectFor(itemId))) throw Error('Bag effect has no effect');
    grantBattleItemFriendship(p);
    return;
  }

  if (itemId === 'guard_spec') {
    if (battle.p1.sideConditions.mist) throw Error('Bag effect has no effect');
    emit('calvomedicine', itemId);
    if (!battle.p1.addSideCondition('mist', p, effectFor(itemId))) throw Error('Bag effect has no effect');
    grantBattleItemFriendship(p);
    return;
  }

  // Flutes: reusable, cure exactly one condition, never spend a unit.
  if (p.hasAbility('soundproof')) throw Error('Soundproof prevents the flute');
  if (itemId === 'blue_flute') {
    if (p.status !== FLUTE_CURES.blue_flute) throw Error('Bag effect has no effect');
    emit('calvomedicine', itemId);
    const old = p.status;
    p.setStatus('', p, effectFor(itemId));
    p.removeVolatile('nightmare');
    emit('-curestatus', old, '[from] item: ' + itemId);
    return;
  }
  if (itemId === 'yellow_flute') {
    if (!p.volatiles.confusion) throw Error('Bag effect has no effect');
    emit('calvomedicine', itemId);
    p.removeVolatile('confusion');
    emit('-end', 'confusion', '[from] item: ' + itemId);
    return;
  }
  if (itemId === 'red_flute') {
    if (!p.volatiles.attract) throw Error('Bag effect has no effect');
    emit('calvomedicine', itemId);
    p.removeVolatile('attract');
    emit('-end', 'attract', '[from] item: ' + itemId);
    return;
  }
  throw Error('Unreviewed bag effect');
}

module.exports = {applyBagEffect, X_STATS, FLUTE_CURES, reviewed};
