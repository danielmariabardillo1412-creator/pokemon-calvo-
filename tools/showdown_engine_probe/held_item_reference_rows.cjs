'use strict';
// Independent reviewed expectations: RHH items.h 8654616b and pret generation sources.
const MEDICINES=[['antidote','Antidote',1],['awakening','Awakening',1],['burn_heal','Burn Heal',1],
 ['elixir','Elixir',1],['energy_powder','Energy Powder',2],['energy_root','Energy Root',2],
 ['ether','Ether',1],['fresh_water','Fresh Water',1],['full_heal','Full Heal',1],
 ['full_restore','Full Restore',1],['heal_powder','Heal Powder',2],['hyper_potion','Hyper Potion',1],
 ['ice_heal','Ice Heal',1],['lava_cookie','Lava Cookie',3],['lemonade','Lemonade',1],
 ['max_elixir','Max Elixir',1],['max_ether','Max Ether',1],['max_potion','Max Potion',1],
 ['moomoo_milk','Moomoo Milk',2],['old_gateau','Old Gateau',4],['paralyze_heal','Paralyze Heal',1],
 ['potion','Potion',1],['soda_pop','Soda Pop',1],['super_potion','Super Potion',1]];
const TRAINING=[['calcium','Calcium',1],['carbos','Carbos',1],['hp_up','HP Up',1],['iron','Iron',1],
 ['pp_max','PP Max',3],['pp_up','PP Up',1],['protein','Protein',1],['rare_candy','Rare Candy',1],['zinc','Zinc',3],
 ['dire_hit','Dire Hit',1],['guard_spec','Guard Spec.',1],['x_accuracy','X Accuracy',1],['x_attack','X Attack',1],
 ['x_defense','X Defense',1],['x_sp_atk','X Sp. Atk',1],['x_sp_def','X Sp. Def',4],['x_speed','X Speed',1]];
const PROGRESSION=[['lucky_egg','Lucky Egg',2],['everstone','Everstone',2]];
module.exports={MEDICINES,TRAINING,PROGRESSION,ALL:[...MEDICINES,...TRAINING,...PROGRESSION]};
