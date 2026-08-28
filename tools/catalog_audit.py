#!/usr/bin/env python3
"""Contrôle l’avancement du catalogue vers la cible de 501 cartes."""
from collections import Counter
from pathlib import Path
import json, sys
ROOT=Path(__file__).resolve().parents[1]
cards=json.loads((ROOT/'data/card_catalog.json').read_text(encoding='utf-8'))
target=json.loads((ROOT/'data/catalog_target.json').read_text(encoding='utf-8'))
counts=Counter(c['rarity'] for c in cards)
ids=[c['id'] for c in cards]; numbers=[c['number'] for c in cards]
errors=[]
if len(ids)!=len(set(ids)): errors.append('identifiants dupliqués')
if len(numbers)!=len(set(numbers)): errors.append('numéros dupliqués')
print(f"Catalogue actuel : {len(cards)} / {target['target_total']} cartes")
print('-'*58)
for rarity,plan in target['rarities'].items():
 current=counts.get(rarity,0); missing=max(0,plan['target']-current)
 print(f"{rarity:12} {current:3} / {plan['target']:3}   manque {missing:3}")
 if current>plan['target']: errors.append(f'{rarity} dépasse la cible')
print('-'*58)
print(f"À produire : {sum(max(0,p['target']-counts.get(r,0)) for r,p in target['rarities'].items())}")
if errors:
 print('ERREURS : '+', '.join(errors),file=sys.stderr);sys.exit(1)
print('Structure du catalogue valide.')
