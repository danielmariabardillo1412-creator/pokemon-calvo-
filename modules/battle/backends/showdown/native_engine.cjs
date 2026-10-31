'use strict';
// Pinned native engine behind the map/lab worker's transactional boundary.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {performance} = require('node:perf_hooks');
const ROOT = path.resolve(__dirname, '../../../..');
const runtime = path.join(ROOT, '.godot/battle_reference/runtime/node_modules/@pkmn/sim');
const version = JSON.parse(fs.readFileSync(path.join(runtime, 'package.json'), 'utf8')).version;
if (version !== '0.10.11') throw Error('The probe requires pinned @pkmn/sim 0.10.11');
const {Battle, Dex} = require(runtime);
require('./field_held_items.cjs').install(Dex);
const Unified = require('./unified_profile.cjs');
const clone = x => JSON.parse(JSON.stringify(x));
const hash = x => crypto.createHash('sha256').update(JSON.stringify(x)).digest('hex');
const toID = x => String(x).toLowerCase().replace(/[^a-z0-9]/g, '');
const statusToPS = {burn:'brn',poison:'psn',badly_poisoned:'tox',paralysis:'par',sleep:'slp',freeze:'frz'};
const statusFromPS = Object.fromEntries(Object.entries(statusToPS).map(([a,b]) => [b,a]));
const STAT = {hp:'hp',attack:'atk',defense:'def',special_attack:'spa',special_defense:'spd',speed:'spe'};
const medicineProfile = JSON.parse(fs.readFileSync(path.join(ROOT,'modules/inventory/battle_medicine_profile.json'),'utf8'));

function applyMedicine(session, battle, command) {
  // O110: the only adapter change is routing the reviewed bag-effect IDs to the
  // helper; the medicine branch below stays authoritative for its own IDs.
  if (require('./native_bag_effects.cjs').reviewed(command?.item_id)) {
    require('./native_bag_effects.cjs').applyBagEffect(session, battle, command);
    return;
  }
  const spec = medicineProfile.items[command?.item_id];
  const name = Object.keys(session.identities).find(n => session.identities[n] === command?.target_id);
  const p = battle.p1.pokemon.find(p => p.name === name);
  if (!spec || !p || p.hp <= 0 || p.fainted) throw Error('Invalid medicine or living own target');
  if (p.volatiles.embargo) throw Error('Embargo prevents medicine use');
  let slots = [];
  if (spec.pp) {
    if (spec.scope === 'one') {
      if (!Number.isInteger(command.move_slot) || command.move_slot < 0 || command.move_slot >= p.moveSlots.length) throw Error('Invalid medicine move slot');
      slots = [p.moveSlots[command.move_slot]];
    } else slots = p.moveSlots;
  } else if (command.move_slot !== undefined && command.move_slot !== -1) throw Error('Unexpected medicine move slot');
  const cure = !!p.status && (spec.cure === 'all' || Array.isArray(spec.cure) && spec.cure.includes(p.status));
  const confusion = !!spec.confusion && !!p.volatiles.confusion;
  const heal = !!spec.heal && p.hp < p.maxhp;
  if (!heal && !cure && !confusion && !slots.some(m => m.pp < m.maxpp)) throw Error('Medicine has no effect');
  const ident = `${p.side.id}: ${p.name}`;
  const emit = (tag, ...fields) => {
    // Never reveal an unrevealed reserve's exact HP/status/identity to p2.
    if (p.isActive) battle.add(tag,p,...fields);
    else battle.addSplit('p1',[tag,ident,...fields.map(f => typeof f === 'function' ? f.call(p).secret : f)],[]);
  };
  emit('calvomedicine',command.item_id);
  if (heal) {
    p.heal(spec.heal === 'full' ? p.maxhp : spec.heal);
    emit('-heal',p.getHealth,'[from] item: ' + command.item_id);
  }
  if (cure) {
    const old = p.status;
    p.setStatus('');
    p.removeVolatile('nightmare');
    emit('-curestatus',old,'[from] item: ' + command.item_id);
  }
  if (confusion) p.removeVolatile('confusion');
  for (const slot of slots) {
    slot.pp = Math.min(slot.maxpp,slot.pp + (spec.pp === 'full' ? slot.maxpp : spec.pp));
    const base = p.baseMoveSlots.find(m => m.id === slot.id);
    if (base && !slot.virtual) base.pp = slot.pp;
  }
}

function lookup(kind, id) {
  let key = id;
  // PokeAPI's held crystal maps to the battle item; its bag ID stays distinct.
  if (kind === 'items' && String(key).endsWith('_z_held') && Dex.items.get(key.slice(0,-5)).zMove) key=key.slice(0,-5);
  if (kind === 'species') key = ({minior:'Minior-Meteor',darmanitan_galar_standard:'Darmanitan-Galar',
    tauros_paldea_combat_breed:'Tauros-Paldea-Combat',tauros_paldea_blaze_breed:'Tauros-Paldea-Blaze',tauros_paldea_aqua_breed:'Tauros-Paldea-Aqua'})[key] ?? key;
  if (kind === 'moves' && /_(physical|special)$/.test(key)) {
    const base = key.replace(/_(physical|special)$/, '');
    if (Dex.moves.get(base).isZ) key = base;
  }
  return Dex[kind].get(key);
}

function serialize(battle) {
  const snapshot = clone(battle.toJSON());
  // Showdown inserts wall-clock protocol markers on choices. They are not game
  // state; canonical snapshots must replay identically after a real-world delay.
  snapshot.log = snapshot.log.map(line => line.startsWith('|t:|') ? '|t:|0' : line);
  // State.deserialize adds formatid as an own property. Its insertion order
  // differs at the initial checkpoint; pin order for the new versioned profile
  // without rewriting hashes of historical Gen8/Gen9 saves.
  if (Unified.isUnified(snapshot.formatid)) {
    const id=snapshot.formatid;delete snapshot.formatid;snapshot.formatid=id;
  }
  return snapshot;
}
function restore(snapshot) {
  const b = Battle.fromJSON(clone(snapshot));
  b.restart(() => {});
  return b;
}

function observeSubstitutes(b) {
  // Observation only: capture the HP the native condition actually computed,
  // including multiple hits and create+break within one turn. No damage rules.
  const add=b.add, single=b.singleEvent;
  const emit=(p,phase,hp)=>b.addSplit(p.side.id,['calvosub',`${p.side.id}: ${p.name}`,phase,hp],[]);
  Object.defineProperty(b,'add',{configurable:true,value:function(...parts){
    add.apply(this,parts);
    if(parts[0]==='-activate'&&String(parts[2]).includes('Substitute')&&parts.includes('[damage]'))emit(parts[1],'damage',parts[1].volatiles.substitute?.hp??0);
    if(parts[0]==='-end'&&parts[2]==='Substitute')emit(parts[1],'end',0);
  }});
  Object.defineProperty(b,'singleEvent',{configurable:true,value:function(...args){
    const result=single.apply(this,args);
    if(args[0]==='Start'&&args[1]?.id==='substitute'&&result!==false)emit(args[3],'start',args[3].volatiles.substitute?.hp??0);
    return result;
  }});
}

function protocolFor(log, perspective) {
  const output = [];
  for (let i=0;i<log.length;i++) {
    if (log[i].startsWith('|split|')) {
      output.push(log[i+1+(log[i] === '|split|' + perspective ? 0 : 1)]);
      i += 2;
    } else output.push(log[i]);
  }
  return output.filter(x => typeof x === 'string');
}

function nativeSet(spec, side, index) {
  const species = lookup('species', spec.species_id);
  if (!species.exists) throw Error('Unknown species: ' + spec.species_id);
  const moves = spec.moves ?? spec.moveset?.map(x => x.move_id);
  if (!Array.isArray(moves) || moves.length < 1 || moves.length > 4) throw Error('Expected 1..4 explicit moves');
  for (const id of moves) if (!lookup('moves', id).exists) throw Error('Unknown move: ' + id);
  const out = {name:`calvo_${side}_${index}`,species:species.name,level:spec.level ?? 50,
    ability:spec.ability_id ? lookup('abilities',spec.ability_id).name : 'No Ability',
    item:spec.held_item_consumed ? '' : spec.held_item_id ? lookup('items',spec.held_item_id).name : '',
    moves:moves.map(x => lookup('moves',x).name), nature:spec.nature_id ?? 'Hardy',
    happiness:spec.friendship ?? 0, shiny:!!spec.is_shiny, ivs:{},evs:{}};
  if (spec.ability_id && !lookup('abilities',spec.ability_id).exists) throw Error('Unknown ability');
  if (spec.held_item_id && !lookup('items',spec.held_item_id).exists) throw Error('Unknown held item');
  for (const [key,short] of Object.entries(STAT)) {
    out.ivs[short] = spec.ivs?.[key] ?? 31;
    out.evs[short] = spec.evs?.[key] ?? 0;
  }
  return out;
}

function importPersistent(battle, specs) {
  // Initial conditions only, installed before switch-in effects via onBegin.
  // No move/item/ability mechanics are duplicated in this adapter.
  for (const side of battle.sides) for (let i=0;i<side.pokemon.length;i++) {
    const p = side.pokemon[i], spec = specs[side.id][i];
    if (spec.stats) {
      const actual = {max_hp:p.maxhp,attack:p.storedStats.atk,defense:p.storedStats.def,
        special_attack:p.storedStats.spa,special_defense:p.storedStats.spd,speed:p.storedStats.spe};
      for (const [k,v] of Object.entries(actual)) if (spec.stats[k] !== v) throw Error(`Stat import mismatch ${spec.instance_id}/${k}: game=${spec.stats[k]} native=${v}`);
    }
    if (spec.current_hp !== undefined) {
      if (!Number.isInteger(spec.current_hp) || spec.current_hp < 0 || spec.current_hp > p.maxhp) throw Error('Invalid persistent HP');
      p.hp = spec.current_hp;
      p.fainted = !p.hp;
    }
    const status = spec.status_state?.persistent_id ?? '';
    if (status && !(status in statusToPS)) throw Error('Unsupported persistent status');
    if (status === 'sleep') {
      const clock=spec.native_sleep;
      if (!clock || clock.version!==version || !Number.isInteger(clock.start_time) || clock.start_time<2 || clock.start_time>4 ||
          !Number.isInteger(clock.time) || clock.time<0 || clock.time>clock.start_time) throw Error('Sleep import requires an observed native clock');
      // Restore the observed condition; do not reroll sleep or trigger a new status application.
      p.status='slp';p.statusState={id:'slp',target:p,startTime:clock.start_time,time:clock.time};
    } else if (status) p.setStatus(statusToPS[status],p,{id:'probe_import',effectType:'Condition'});
    if (spec.moveset) for (let j=0;j<p.moveSlots.length;j++) {
      const slot = spec.moveset[j];
      if (!slot || toID(lookup('moves',slot.move_id).id) !== p.moveSlots[j].id) throw Error('Move slot order mismatch');
      if (!Number.isInteger(slot.max_pp) || slot.max_pp < 1 || !Number.isInteger(slot.current_pp) || slot.current_pp < 0 || slot.current_pp > slot.max_pp) throw Error('Invalid persistent PP');
      p.moveSlots[j].maxpp = slot.max_pp;
      p.moveSlots[j].pp = slot.current_pp;
    }
  }
}

function observe(session, from=0, perspective='p1') {
  const b = session.battle;
  const request = clone(b[perspective]?.activeRequest ?? null);
  return {turn:b.turn,ended:b.ended,winner:b.winner ?? '',request_state:b.requestState,
    // Only the owner's request and public opponent information cross this view.
    request,protocol:protocolFor(b.log.slice(from),perspective),
    own:b[perspective].pokemon.map(p => ({instance_id:session.identities[p.name],species_id:p.species.id,
      hp:p.hp,max_hp:p.maxhp,status_id:statusFromPS[p.status] ?? '',active:p.isActive,fainted:p.fainted,
      held_item_id:p.item,moves:p.moveSlots.map(m => ({id:m.id,pp:m.pp,max_pp:m.maxpp}))})),
    opponent:b[perspective === 'p1' ? 'p2':'p1'].active.filter(Boolean).map(p => ({instance_id:session.identities[p.name],
      details:p.getFullDetails().shared.split('|')[0],health:p.getHealth().shared,status_id:statusFromPS[p.status] ?? '',fainted:p.fainted})),
  };
}

function visualShiny(b,p) {
  if(!p.transformed)return !!p.set.shiny;
  const line=[...b.log].reverse().find(l=>l.startsWith('|-transform|')&&l.split('|')[2].endsWith(': '+p.name));
  const name=line?.split('|')[3]?.split(': ')[1];
  return !!b.sides.flatMap(s=>s.pokemon).find(q=>q.name===name)?.set.shiny;
}

function checkpoint(session) {
  const b=session.battle;
  return {snapshot:{version,native:serialize(b),identities:clone(session.identities)},
    state_hash:hash(serialize(b)),views:{p1:observe(session,0,'p1'),p2:observe(session,0,'p2')},
    roster:b.sides.map(side=>({id:side.id,active_id:session.identities[side.active[0]?.name] ?? '',
      active_ids:side.active.map(p=>session.identities[p?.name]??''),
      pokemon:side.pokemon.map(p=>({instance_id:session.identities[p.name],species_id:p.species.id,
        hp:p.hp,max_hp:p.maxhp,status_id:statusFromPS[p.status] ?? '',status_time:p.statusState.time ?? 0,
        persistent_hp:p.getUndynamaxedHP(),base_max_hp:p.baseMaxhp,
        // Additive projections only (not part of the canonical state hash): the real
        // battle-item happiness and the real held-item activity computed with the
        // simulator's own ignoringItem() suppression (Magic Room/Embargo/Klutz/consumed).
        friendship:Number.isInteger(p.happiness)?p.happiness:(Number.isInteger(p.set?.happiness)?p.set.happiness:0),
        held_item_active:!!p.item&&!p.ignoringItem(),
        toxic_stage:p.statusState.stage ?? 0,boosts:clone(p.boosts),item:p.item,ability:p.ability,
        transformed:p.transformed,trapped:!!p.trapped,volatiles:Object.keys(p.volatiles),substitute_hp:p.volatiles.substitute?.hp ?? 0,
        stats:{max_hp:p.maxhp,attack:p.storedStats.atk,defense:p.storedStats.def,special_attack:p.storedStats.spa,special_defense:p.storedStats.spd,speed:p.storedStats.spe},
        base_moves:p.baseMoveSlots.map(m=>({id:m.id,pp:m.pp,max_pp:m.maxpp})),
        shiny:visualShiny(b,p),last_move_category:(p.lastMove?.category??'').toLowerCase(),
        sleep_clock:p.status==='slp'?{version,start_time:p.statusState.startTime,time:p.statusState.time}:null,
        moves:p.moveSlots.map(m=>({id:m.id,pp:m.pp,max_pp:m.maxpp}))}))}))};
}

class NativeEngine {
  constructor() { this.sessions = new Map();this.drafts=new Map(); }
  execute(c) {
    const started = performance.now();
    const result = this.dispatch(c);
    return {...result,elapsed_ms:performance.now()-started};
  }
  dispatch(c) {
    if (c.op === 'hello') return {version,node:process.version,transport:'local stdio JSONL',pid:process.pid};
    if (c.op === 'shutdown') {this.close();return {closed:true};}
    if (c.op === 'start') {
      if (!['gen9customgame','gen8customgame','gen9doublescustomgame',Unified.SINGLE,Unified.DOUBLE].includes(c.format ?? 'gen9customgame')) throw Error('Unreviewed format');
      if (this.sessions.has(c.id) || this.sessions.size >= 12) throw Error('Duplicate/too many sessions');
      const specs = c.teams;
      if (!specs || !['p1','p2'].every(s => Array.isArray(specs[s]) && specs[s].length >= 1 && specs[s].length <= 6)) throw Error('Expected two teams of 1..6');
      if(['gen9doublescustomgame',Unified.DOUBLE].includes(c.format)&&['p1','p2'].some(s=>specs[s].length<2))throw Error('Doubles requires at least two initial participants per side');
      if (!Array.isArray(c.seed) || c.seed.length !== 4 || c.seed.some(x => !Number.isInteger(x) || x<0 || x>65535)) throw Error('Explicit native four-word seed required');
      const identities = {};
      for (const s of ['p1','p2']) for (let i=0;i<specs[s].length;i++) {
        const id = specs[s][i].instance_id;
        if (typeof id !== 'string' || !id || Object.values(identities).includes(id)) throw Error('Unique instance IDs required');
        identities[`calvo_${s}_${i}`] = id;
      }
      const parentFormat = Dex.formats.get(c.format ?? 'gen9customgame');
      const format = {...parentFormat,onBegin() {parentFormat.onBegin?.call(this);this.reportExactHP=false;importPersistent(this,specs);}};
      let b;
      try {
        b = new Battle({format,seed:c.seed,p1:{name:'Player',team:specs.p1.map((p,i) => nativeSet(p,'p1',i))},
          p2:{name:'Opponent',team:specs.p2.map((p,i) => nativeSet(p,'p2',i))}});
        if (b.requestState === 'teampreview') {
          if(b.gameType==='doubles')b.makeChoices(...['p1','p2'].map(s=>'team '+specs[s].map((_,i)=>i+1).join(',')));
          else b.makeChoices('team 1','team 1');
        }
        const session = {battle:b,identities};
        const result = observe(session,0,c.perspective);
        this.sessions.set(c.id,session);
        return result;
      } catch(e) {b?.destroy();throw e;}
    }
    if (c.op === 'restore') {
      if (c.snapshot?.version !== version || this.sessions.has(c.id) || this.sessions.size >= 12) throw Error('Snapshot version/session mismatch');
      const session = {battle:restore(c.snapshot.native),identities:clone(c.snapshot.identities)};
      this.sessions.set(c.id,session);
      return observe(session,session.battle.log.length,c.perspective);
    }
    const session = this.sessions.get(c.id);
    if (!session) throw Error('Unknown session');
    if (c.op === 'drop') {
      for(const [token,draft] of this.drafts)if(draft.id===c.id){draft.session.battle.destroy();this.drafts.delete(token);}
      session.battle.destroy();this.sessions.delete(c.id);return {dropped:true};
    }
    if (c.op === 'snapshot') return {snapshot:{version,native:serialize(session.battle),identities:clone(session.identities)}};
    if (c.op === 'view') return observe(session,session.battle.log.length,c.perspective);
    if (c.op === 'checkpoint') return checkpoint(session);
    if (c.op === 'prepare') {
      const current=hash(serialize(session.battle));
      if(c.expected_hash !== current) throw Error('Stale native revision');
      for(const [token,draft] of this.drafts) if(draft.id===c.id) {draft.session.battle.destroy();this.drafts.delete(token);}
      const fork=new NativeEngine();
      try {
        fork.execute({op:'restore',id:'draft',snapshot:{version,native:serialize(session.battle),identities:clone(session.identities)}});
        fork.execute({op:'choose',id:'draft',choices:c.choices,perspective:c.perspective,reaction:c.reaction,medicine:c.medicine});
        const candidate=fork.sessions.get('draft');
        const token=crypto.randomUUID();
        const result={draft_token:token,before_hash:current,checkpoint:checkpoint(candidate)};
        this.drafts.set(token,{id:c.id,before_hash:current,session:candidate});fork.sessions.delete('draft');
        return result;
      } finally {fork.close();}
    }
    if(c.op==='abort') {
      const draft=this.drafts.get(c.draft_token);
      if(!draft || draft.id!==c.id) throw Error('Unknown draft');
      draft.session.battle.destroy();this.drafts.delete(c.draft_token);return {aborted:true};
    }
    if(c.op==='commit') {
      const draft=this.drafts.get(c.draft_token);
      if(!draft || draft.id!==c.id || hash(serialize(session.battle))!==draft.before_hash) throw Error('Stale or missing prepared turn');
      const result=checkpoint(draft.session);
      session.battle.destroy();this.sessions.set(c.id,draft.session);this.drafts.delete(c.draft_token);
      return result;
    }
    if (c.op === 'choose') {
      // Commit only a completely valid pair/continuation, not a half-entered turn.
      if (Unified.isUnified(session.battle.format.id) && Object.values(c.choices ?? {}).some(choice => /\b(mega|megax|megay|ultra|terastallize)\b/.test(choice))) throw Error('Unreviewed special mechanic in unified attack profile');
      const candidate = restore(serialize(session.battle));
      observeSubstitutes(candidate);
      const start = candidate.log.length;
      try {
        if (c.reaction !== undefined) {
          // Trusted adventure boundary, NOT a player-selectable battle pass.
          // The ball/escape action has already been staged by the game. Only
          // the opponent acts; native turnLoop still owns residuals and RNG.
          if (!['capture_failed','escape_failed','escape_blocked','medicine'].includes(c.reaction) ||
              candidate.gameType !== 'singles' || candidate.requestState !== 'move' ||
              candidate.ended || candidate.queue.list.length ||
              candidate.sides.some(s => s.requestState !== 'move' || !s.active[0]?.hp || s.isChoiceDone()) ||
              Object.keys(c.choices ?? {}).some(s => s !== 'p2')) throw Error('Invalid adventure reaction boundary');
          if (c.reaction === 'medicine') applyMedicine(session,candidate,c.medicine);
          else if (c.medicine !== undefined) throw Error('Unexpected medicine payload');
          candidate.p1.clearChoice();
          candidate.p1.choice.actions.push({choice:'pass'});
        } else if (c.medicine !== undefined) throw Error('Medicine requires an adventure action');
        const required = ['p1','p2'].filter(side => !candidate[side].isChoiceDone());
        for (const side of required) {
          if (typeof c.choices?.[side] !== 'string' || !candidate.choose(side,c.choices[side])) throw Error('Invalid choice for ' + side);
        }
        if (candidate.log.slice(start).some(x => x.startsWith('|error|'))) throw Error('Native engine rejected choices');
        const result = observe({...session,battle:candidate},start,c.perspective);
        session.battle.destroy();session.battle = candidate;
        return result;
      } catch(e) {candidate.destroy();throw e;}
    }
    if (c.op === 'branches') {
      if (!Array.isArray(c.candidates) || c.candidates.length > 256) throw Error('Bounded candidate batch required');
      const snapshot = {version,native:serialize(session.battle),identities:clone(session.identities)};
      const results = [];
      for (let i=0;i<c.candidates.length;i++) {
        const fork = new NativeEngine();
        try {
          fork.execute({op:'restore',id:'fork',snapshot});
          results.push({ok:true,result:fork.execute({op:'choose',id:'fork',choices:c.candidates[i],perspective:c.perspective})});
        } catch(e) {results.push({ok:false,error:e.message});}
        finally {fork.close();}
      }
      return {results,source_unchanged:hash(serialize(session.battle)) === hash(snapshot.native)};
    }
    throw Error('Unsupported probe command');
  }
  close() {for(const d of this.drafts.values())d.session.battle.destroy();this.drafts.clear();for (const s of this.sessions.values()) s.battle.destroy();this.sessions.clear();}
}


module.exports={NativeEngine,lookup,version,ROOT,serialize,restore,protocolFor,hash};
