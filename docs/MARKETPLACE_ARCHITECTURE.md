# Architecture du marché entre joueurs

## État actuel

Le client Godot propose un **prototype local en jetons** : achat, mise en vente, séquestre et annulation. Il sert à valider l’interface et les règles économiques, mais ne constitue pas un marché multijoueur sécurisé.

L’argent réel est affiché comme **non activé**.

## Pourquoi un serveur est obligatoire

Le téléphone du joueur ne doit jamais décider :

- combien de cartes il possède ;
- si une carte a réellement été mise en séquestre ;
- si un paiement a réussi ;
- si une offre peut être achetée deux fois ;
- combien de jetons ou d’euros doivent être crédités.

Le serveur doit être la seule source de vérité. Le client envoie une intention et affiche la réponse signée par le serveur.

## Services nécessaires

1. **Authentification** : compte, appareils, renouvellement de session et récupération.
2. **Inventaire autoritaire** : quantités disponibles, réservées et verrouillées.
3. **Registre immuable** : chaque création, ouverture, fusion, vente et achat produit une écriture comptable.
4. **Marché** : offres, recherche, prix, expiration et annulation.
5. **Séquestre** : les cartes sont verrouillées avant publication.
6. **Portefeuille** : solde en monnaie du jeu et historique.
7. **Paiements** : intentions, reçus Apple/Google, webhooks, remboursements et litiges.
8. **Anti-fraude** : limites, vélocité, comptes liés, appareils compromis et chargebacks.
9. **Modération** : suspension, gel du portefeuille et traçabilité administrative.
10. **Observabilité** : journaux, alertes, sauvegardes et reprise après incident.

## Flux d’une vente en jetons

1. Le joueur demande la mise en vente de 3 cartes.
2. Le serveur ouvre une transaction SQL.
3. Il verrouille la ligne d’inventaire.
4. Il déplace 3 exemplaires de `available` vers `reserved`.
5. Il crée l’offre.
6. Lors de l’achat, il verrouille l’offre et les deux portefeuilles.
7. Il vérifie le solde, débite l’acheteur et crédite le vendeur moins la commission.
8. Il transfère les cartes et ferme l’offre.
9. Il écrit toutes les opérations dans le registre.
10. Il valide la transaction une seule fois grâce à une clé d’idempotence.

## Argent réel : point juridique et boutiques

Le concept combine un sacrifice financier possible, des caisses aléatoires et des objets revendables. En France, cette combinaison peut relever du cadre des **jeux à objets numériques monétisables (JONUM)**. Une analyse juridique spécialisée est nécessaire avant toute activation :

- ANJ — JONUM : https://anj.fr/jeux-objets-numeriques-monetisables-jonum
- Apple App Review Guidelines : https://developer.apple.com/app-store/review/guidelines/
- Google Play Payments : https://support.google.com/googleplay/android-developer/answer/9858738
- Google Play Real-Money Games : https://support.google.com/googleplay/android-developer/answer/9877032

Points à traiter avant production : vérification d’âge, territoires autorisés, KYC/AML si applicable, fiscalité, protection des mineurs, plafonds, auto-exclusion, probabilités visibles, remboursements, chargebacks et conditions générales.

## Recommandation de mise en production

### Phase A — actuelle

- Jetons gratuits de démonstration.
- Marché local.
- Aucun achat ni retrait en euros.

### Phase B

- Comptes serveur.
- Marché connecté uniquement en monnaie du jeu non convertible.
- Inventaire, fusion et ouverture calculés côté serveur.
- Tests de charge et anti-fraude.

### Phase C, après validation juridique et boutiques

- Paiements via les mécanismes autorisés.
- Vérification serveur des reçus.
- Argent réel éventuellement limité à l’achat direct d’objets à prix fixe.
- Ne pas autoriser de retrait ou de revente en euros sans cadre juridique explicite.

## API minimale proposée

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
POST   /v1/payments/intents
POST   /v1/payments/webhooks/{provider}
```

Toutes les requêtes qui modifient un solde doivent posséder une clé d’idempotence.
