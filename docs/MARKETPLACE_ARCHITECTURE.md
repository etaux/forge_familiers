# Architecture du marché entre joueurs

Le marché n’échange que des **jetons de jeu**, obtenus en jouant. Aucune monnaie réelle n’entre dans le produit.

## État actuel

Le client Godot propose un prototype local en jetons : achat, mise en vente, séquestre et annulation.

Un serveur (`backend/server.py`) existe : comptes, inventaire `available/reserved`, caisses, fusion, marché en jetons, expéditions, idempotence. Le client Godot ne l’appelle pas encore (`ServerApi.SERVER_ENABLED = false`).

## Pourquoi un serveur est obligatoire

Le téléphone du joueur ne doit jamais décider :

- combien de cartes il possède ;
- si une carte a réellement été mise en séquestre ;
- si une offre peut être achetée deux fois ;
- combien de jetons doivent être crédités.

Le serveur est la seule source de vérité. Le client envoie une intention et affiche la réponse.

## Services

1. **Authentification** : compte, appareils, session.
2. **Inventaire autoritaire** : quantités disponibles, réservées et verrouillées.
3. **Registre immuable** : chaque ouverture, fusion, vente et achat produit une écriture.
4. **Marché** : offres, recherche, prix, expiration et annulation, **uniquement en jetons**.
5. **Séquestre** : les cartes sont verrouillées avant publication.
6. **Portefeuille** : essence, jetons, poussières.
7. **Anti-triche** : limites, vélocité, comptes liés.
8. **Modération** : suspension et traçabilité.
9. **Observabilité** : journaux, sauvegardes.

## Flux d’une vente

1. Le joueur demande la mise en vente de 3 cartes.
2. Le serveur ouvre une transaction SQL.
3. Il verrouille la ligne d’inventaire.
4. Il déplace 3 exemplaires de `available` vers `reserved`.
5. Il crée l’offre en jetons.
6. Lors de l’achat, il verrouille l’offre et les deux portefeuilles.
7. Il vérifie le solde, débite l’acheteur et crédite le vendeur.
8. Il transfère les cartes et ferme l’offre.
9. Il écrit toutes les opérations dans le registre.
10. Il valide la transaction une seule fois grâce à une clé d’idempotence.

## API

```text
POST   /v1/auth/session
GET    /v1/inventory
POST   /v1/crates/{crate_id}/open
POST   /v1/fusions
GET    /v1/market/listings
POST   /v1/market/listings
DELETE /v1/market/listings/{id}
POST   /v1/market/orders
GET    /v1/wallet
```

Toute requête qui modifie un solde porte une clé d’idempotence.
