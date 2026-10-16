# Cahier des charges conceptuel de l'application

**Ligue Panafricaine des Neurocitoyens · Document de travail · 16 octobre 2026 · à valider par l'équipe**

L'application porte la fédération de coopératives de la Ligue de bout en bout : du parcours de formation du neurocitoyen jusqu'à l'achat groupé, avec le MASA comme seul acheteur, six niveaux fédéraux et AGORA comme plateforme locale d'inscription et d'achat. Ce document fixe le périmètre, les acteurs, les concepts, les modules, les règles de gestion et le modèle de données conceptuel. Il s'appuie sur le document « Fondations économiques et fédérales » ; le schéma SQL détaillé est dans `docs/sql/schema.sql`.

---

## 1. Objet et périmètre

**Objet.** Donner à chaque coopérative, à chaque union, à chaque Cité et au MASA les outils pour former leurs membres, gérer leurs décisions, leurs commandes, leurs prix, leurs stocks et leurs comptes, et rendre le réseau transparent. Donner à chaque client (citoyen, commerçant, artisan, école, mairie, entreprise) un espace pour s'inscrire, participer aux achats groupés et suivre ses commandes.

**Dans le périmètre :**

- une hiérarchie territoriale générique et six niveaux fédéraux ;
- le parcours de formation du neurocitoyen, la certification et l'accès aux fonctions de coopérative ;
- la vie des coopératives : création, membres, parts sociales, statut de comité ou d'entité opérationnelle ;
- l'inscription et l'espace personnel des clients sur AGORA ;
- la gouvernance : assemblées, ordres du jour, votes, résolutions, procès-verbaux ;
- le catalogue de référence, les accords-cadres, le barème de frais et la décomposition du prix ;
- les besoins, les campagnes d'achat groupé, les reçus et l'historique des commandes ;
- la centrale d'achat du MASA : commandes consolidées, achats, livraison au responsable de Cité, dispatching, stocks ;
- la finance coopérative : ristournes, contributions, fonds de garantie, parts sociales ;
- les indicateurs d'impact par territoire ;
- les Assises annuelles : inscription, programme, vote en ligne, dépôt des rapports, pitchs.

**Hors périmètre à ce stade :**

- l'épargne et le crédit aux membres, activité réglementée confiée à des institutions agréées ou à un partenaire ;
- l'opération de la monnaie mobile, assurée par un partenaire agréé ;
- l'instance civique (Forum de la Cité), distincte des assemblées coopératives.

---

## 2. Acteurs et rôles

| Acteur | Rôle dans l'application | Principales actions |
| --- | --- | --- |
| Citoyen | Client inscrit sur AGORA, membre ou non | Déposer un besoin, rejoindre un achat groupé, payer, suivre, obtenir son reçu |
| Commerçant, détaillant | Client professionnel | Commander en gros, accepter la charte, suivre ses commandes |
| École, mairie, entreprise | Structure cliente | Participer aux achats groupés depuis son espace, consulter son historique |
| Producteur ou artisan | Fournisseur local inscrit auprès de sa Cité | Proposer une offre, conclure un accord-cadre avec le MASA |
| Apprenant | Personne en parcours de formation | Suivre les modules, passer la certification |
| Neurocitoyen certifié | Personne certifiée | Fonder une coopérative, être élu, gérer, représenter |
| Formateur, animateur coopératif | Accompagnement et relais | Animer la formation, saisir les besoins des personnes sans smartphone |
| Membre | Propriétaire et usager de sa coopérative | Voter en assemblée, acheter, recevoir sa ristourne |
| Administrateur, comité de surveillance | Élus d'une coopérative | Suivre, contrôler, approuver |
| Gérant | Salarié d'un niveau opérationnel | Gérer commandes, stocks, livraisons |
| Délégué | Représentant d'une coopérative ou d'une Cité à un niveau supérieur | Voter en assemblée de niveau N2 à N6 |
| Responsable de Cité | Dirigeant de la fédération nationale (N5) | Recevoir les livraisons du MASA, dispatcher, suivre les engagements |
| Comité d'achats du MASA | Élus par les délégués des Cités | Décider des achats, publier le rapport |
| Auditeur externe | Contrôle indépendant | Consulter les comptes en lecture seule |
| Administrateur de la plateforme | Équipe technique | Paramétrer, déployer, supporter |

Les droits suivent le niveau : chaque acteur ne voit et ne modifie que ce qui relève de sa coopérative, de son niveau ou de ses sous-niveaux.

---

## 3. Concepts métier

| Concept | Définition |
| --- | --- |
| Unité territoriale | Nœud de la hiérarchie générique (quartier, arrondissement, commune, département, pays…), avec un parent |
| Niveau | Rang N1 à N6 d'une entité dans la fédération |
| Cité | Fédération nationale (N5), dirigée par un responsable de Cité |
| MASA | Autorité continentale (N6) et centrale d'achat groupé, seul acheteur du réseau |
| Coopérative | Entité de premier degré (N1) ou union (N2 à N5), rattachée à une unité territoriale et à un parent |
| Comité de coordination | Statut de départ d'un niveau : assemblée, sans stock ni trésorerie propre |
| Entité opérationnelle | Statut atteint avec cinq coopératives actives au niveau inférieur et douze mois d'activité (seuils à valider) |
| Parcours | Suite d'étapes de formation, de l'éveil à la coopérative opérationnelle |
| Certification de neurocitoyen | Reconnaissance obtenue à l'issue de la formation ; exigée pour fonder, diriger ou représenter une coopérative |
| Espace client | Espace personnel sur AGORA (citoyen, mairie, entreprise, école, commerçant) |
| Part sociale | Capital détenu par un membre, remboursable selon les statuts |
| Catalogue de référence | Liste commune des produits, classés en familles A, B et C |
| Accord-cadre | Entente du MASA avec un fournisseur, rattachée à un produit et à une source |
| Barème de frais | Pourcentages de service par niveau, dégressifs, versionnés, votés chaque année |
| Décomposition du prix | Ventilation du prix final : achat, frais de chaque niveau, transport |
| Besoin | Demande d'un client : produit, quantité, lieu de retrait, date limite |
| Campagne d'achat groupé | Regroupement de besoins avec volume minimum et date de clôture |
| Commande consolidée | Somme des besoins remontés d'une Cité, transmise au MASA |
| Livraison à la Cité | Livraison directe du MASA au responsable de Cité, qui dispatche ensuite |
| Ristourne | Part de l'excédent reversée aux membres au prorata de leur usage |
| Contribution fédérale | Part de l'excédent net remontée au niveau directement supérieur |
| Fonds de garantie solidaire | Réserve qui absorbe les pertes |

---

## 4. Modules fonctionnels

### 4.1 Territoires

- Stocker les territoires dans une hiérarchie générique à profondeur variable.
- Paramétrer, par pays, la correspondance entre unités administratives et niveaux N1 à N5, avec regroupement possible quand un pays a moins de niveaux.
- Rattacher chaque coopérative, chaque point de retrait, chaque client et chaque statistique à une unité territoriale.

### 4.2 Parcours de formation et certification

- Catalogue de modules et définition du parcours en sept étapes : éveil et inscription, formation à la neurocitoyenneté, formation au coopérativisme, mise en situation, création, préparation du marché, démarrage et suivi.
- Suivi de progression de chaque apprenant, évaluations, délivrance de la certification de neurocitoyen et des grades.
- Accès aux fonctions de coopérative (fondateur, administrateur, gérant, délégué) conditionné à la certification.
- Mentorat et suivi entre coopératives.

### 4.3 Coopératives et membres

- Fiche coopérative : niveau, parent, statut (comité ou opérationnelle), territoire, étapes de création.
- Fiche membre : adhésion, parts sociales souscrites et remboursées, historique d'usage.
- Bascule d'un comité vers une entité opérationnelle quand les seuils sont atteints, sur validation de l'assemblée.
- Suivi des douze mois de préparation de chaque Cité : coopératives créées (objectif d'au moins cinq), clients inscrits par coopérative, état de préparation au démarrage.
- Adhésion par parts sociales uniquement, sans frais d'inscription non remboursables.

### 4.4 Inscription et espaces clients sur AGORA

- Inscription des citoyens, commerçants, artisans, écoles, mairies, entreprises et de toute structure du territoire, rattachés à la coopérative et à la commune.
- Espace personnel sur smartphone : dépôt de besoins, participation aux campagnes, suivi de chaque étape de commande, reçu, historique.
- Espaces dédiés : citoyen, mairie, entreprise, école, commerçant.
- Charte de qualité et de transparence signée par les détaillants ; mêmes conditions pour tous les détaillants du territoire ; prix de revente conseillés, jamais imposés.
- Saisie par un animateur pour les personnes sans smartphone ; langues du pays, pictogrammes, prix en monnaie locale.
- Outils de promotion pour les coopératives : suivi des inscriptions, invitations, objectifs d'inscrits.

### 4.5 Gouvernance

- Assemblées : convocation, ordre du jour, émargement, quorum.
- Votes : un membre une voix en N1 ; une voix par coopérative en N2 à N5, avec pondération plafonnée paramétrable ; une voix par Cité en N6. Réutiliser le mécanisme des propositions.
- Résolutions et procès-verbaux archivés et consultables.
- Séparation nette des instances : assemblées coopératives d'un côté, Forum de la Cité de l'autre.
- Comité d'achats du MASA : élection par les délégués des Cités, suivi des décisions.

### 4.6 Catalogue, accords-cadres et prix

- Produits de référence, familles A, B et C, identiques partout.
- Accords-cadres par produit et par source : producteurs de la Cité, autres Cités, extérieur.
- Barème de frais dégressif, versionné par niveau, avec date d'effet et vote associé.
- Calcul automatique de la décomposition du prix, affichée dans chaque canal de vente.
- Contrôle des garde-fous : frais amont cumulés, contribution par niveau, prix comparé au marché local relevé chaque trimestre.

### 4.7 Besoins et achats groupés

- Dépôt d'un besoin par le client ou par un animateur.
- Ouverture de campagnes par produit et par période, avec volume minimum et clôture.
- Paiement à l'avance par monnaie mobile via un partenaire agréé ; remboursement ou report si le minimum n'est pas atteint.
- Retrait groupé à date fixe ou livraison de proximité ; reçu et historique.
- Remontée des besoins agrégés, sans données personnelles, vers les unions, la Cité et le MASA.

### 4.8 Centrale d'achat du MASA, livraison et stocks

- Consolidation des besoins de niveau en niveau jusqu'à la Cité, puis transmission au MASA en commande consolidée.
- Planification des achats par le MASA, mise en concurrence d'au moins trois fournisseurs au-dessus du seuil fixé par les Assises, suivi de la part maximale par fournisseur.
- Achats chez les producteurs locaux de chaque Cité, dans les autres Cités et à l'extérieur ; contrôle qualité.
- Livraison directe au responsable de Cité ; dispatching vers les unions et coopératives ; bons de livraison et réception.
- Stocks par niveau et mouvements ; suivi de la règle des trois manutentions au plus entre le hub national et la boutique.
- Inscription des producteurs et artisans auprès de leur Cité, avec prix équitable publié.

### 4.9 Finance

- Parts sociales : souscription, remboursement.
- Flux : paiement comptant la première année, crédit interne plafonné après audit, acompte à la commande consolidée, règlement du MASA par la Cité, paiement des fournisseurs par le MASA.
- Répartition de l'excédent annuel dans l'ordre : pertes reportées, réserve indivisible, formation, contribution fédérale, intérêt des parts, ristourne.
- Fonds de garantie solidaire et fonds de roulement fédéral.
- Accès en lecture seule pour l'auditeur externe.

### 4.10 Impact

- Tableau de bord par territoire : neurocitoyens certifiés, coopératives actives, membres, clients inscrits, emplois, chiffre d'affaires, excédents, prix comparés au marché.
- Indicateurs : écart de prix, taux de rupture, délai de livraison, part de membres actifs, excédent par niveau, emplois créés, part des achats locaux.

### 4.11 Assises

- Éditions annuelles : inscription solidaire, programme sur trois jours, diffusion hybride, replays.
- Vote en ligne du barème, du catalogue de référence et des résolutions.
- Dépôt des rapports de Cités, motions, pitchs de nouvelles coopératives.
- Engagements chiffrés par Cité et suivi de leur réalisation l'année suivante.

---

## 5. Règles de gestion

| N° | Règle |
| --- | --- |
| RG1 | Seuls les neurocitoyens certifiés peuvent fonder une coopérative, être élus à son conseil ou à son comité de surveillance, être gérants ou délégués. |
| RG2 | Un client s'inscrit sur AGORA sans prérequis de formation. |
| RG3 | Une coopérative a un seul parent, au niveau immédiatement supérieur actif. |
| RG4 | Un niveau devient opérationnel avec cinq coopératives actives au niveau inférieur et douze mois d'activité (seuils paramétrables). |
| RG5 | N1 : un membre une voix. N2 à N5 : une voix par coopérative, pondération plafonnée. N6 : une voix par Cité. |
| RG6 | Seul le MASA achète pour le réseau ; toute commande d'achat émise par une Cité ou une coopérative est refusée. |
| RG7 | Le MASA livre directement au responsable de Cité, qui dispatche vers les unions et coopératives, que l'achat soit local ou extérieur. |
| RG8 | Les producteurs et artisans sont inscrits auprès de leur Cité ; le prix équitable est fixé et publié. |
| RG9 | Frais amont cumulés : au plus **20 %** du prix d'achat initial ; alerte ou blocage au-delà. |
| RG10 | Contribution sur excédent : au plus 5 % par niveau, calculée sur l'excédent propre, hors contributions reçues. |
| RG11 | Prix final en boutique au plus égal au prix moyen du marché local relevé chaque trimestre ; sinon alerte et révision du barème ou du fournisseur. |
| RG12 | Livraison directe : frais de coordination ramené à 0,5 % ; transport refacturé au coût réel. |
| RG13 | Au plus trois manutentions physiques entre le hub national et la boutique de base. |
| RG14 | Première année d'une coopérative : paiement comptant ; crédit interne seulement après audit, dans les plafonds du niveau supérieur. |
| RG15 | Campagne d'achat groupé : si le volume minimum n'est pas atteint à la clôture, remboursement intégral ou report. |
| RG16 | Tous les détaillants d'un territoire achètent aux mêmes conditions ; prix de revente conseillés, jamais imposés. |
| RG17 | Aucune rémunération n'est liée au recrutement ; les rémunérations paient un travail ou un service rendu. |
| RG18 | Les besoins remontés au-delà de la coopérative de base sont agrégés et sans donnée personnelle. |
| RG19 | Le barème est voté chaque année aux Assises, versionné, publié et audité ; une modification ne s'applique qu'à sa date d'effet. |
| RG20 | Mise en concurrence d'au moins trois fournisseurs au-dessus du seuil fixé par les Assises ; part maximale par fournisseur contrôlée. |
| RG21 | Aucun prix ne s'affiche sans sa décomposition. |
| RG22 | Chaque client dispose d'un reçu et d'un historique de commande. |

Les seuils chiffrés (cinq coopératives, douze mois, 20 %, 5 %, 0,5 %, trois manutentions) sont des paramètres, pas des constantes dans le code.

---

## 6. Modèle de données conceptuel

Le schéma SQL détaillé est dans `docs/sql/schema.sql` (32+ tables, 13 domaines). Le seed est dans `docs/sql/seed.sql`.

| Domaine | Tables principales |
| --- | --- |
| Territoires | `unites_territoriales` |
| Coopératives | `cooperatives`, `cooperative_membres`, `coop_etapes_creation`, `parts_sociales_mouvements` |
| Clients | `clients_inscrits`, `espaces_clients` |
| Besoins & campagnes | `besoins`, `campagnes_achat`, `campagnes_participations` |
| Catalogue | `catalogue_produits`, `accords_cadres` |
| Commandes | `commandes`, `commande_lignes` |
| MASA | `masa_achats`, `masa_livraisons`, `dispatch_internes` |
| Stocks | `mouvements_stock`, `stock_actuel` |
| Reçus | `recus` |
| Finance | `bareme_frais`, `repartitions_excedent`, `ristournes_membres`, `fonds`, `fonds_mouvements` |
| Gouvernance | `assemblees`, `resolutions`, `votes`, `mandats` |
| Impact & Assises | `indicateurs_impact`, `releves_prix_marche`, `assises_editions`, `assises_inscriptions`, `assises_engagements` |
| Audit | `audit_log` |

---

## 7. Parcours clés

### 7.1 Du neurocitoyen à la coopérative

1. La personne s'inscrit sur AGORA et suit la formation à la neurocitoyenneté.
2. Elle obtient la certification, puis suit la formation au coopérativisme et la mise en situation.
3. Les certifiés tiennent l'assemblée constitutive, souscrivent leurs parts sociales et élisent le conseil.
4. La coopérative démarre comme comité de coordination, puis inscrit ses clients sur AGORA.

### 7.2 Achat groupé d'un client

1. Le client dépose un besoin depuis son espace.
2. La plateforme l'intègre à une campagne avec volume minimum et clôture.
3. Le prix s'affiche avec sa décomposition ; le client paie à l'avance par monnaie mobile.
4. À la clôture, le besoin remonte avec les autres besoins de la Cité.
5. Le client suit sa commande étape par étape, retire sa marchandise et reçoit son reçu ; remboursement ou report si le minimum n'est pas atteint.

### 7.3 Approvisionnement par le MASA

1. Les besoins sont consolidés de niveau en niveau jusqu'à la Cité, puis transmis au MASA.
2. Le MASA croise les besoins avec l'offre (producteurs de la Cité d'abord), lance la mise en concurrence et achète.
3. Il contrôle la qualité et livre directement au responsable de Cité.
4. Le responsable de Cité dispatche vers les unions et coopératives, en trois manutentions au plus.
5. La Cité règle le MASA sur sa commande consolidée ; le MASA règle ses fournisseurs.

### 7.4 Vote d'une résolution

1. Le conseil dépose la résolution et convoque l'assemblée.
2. Les membres ou délégués votent, en séance ou en ligne.
3. Le résultat et le procès-verbal sont archivés et publiés.

### 7.5 Clôture annuelle d'une coopérative

1. Calcul de l'excédent net.
2. Répartition dans l'ordre fixé : pertes, réserve, formation, contribution, intérêt, ristourne.
3. Versement de la contribution au niveau supérieur et de la ristourne aux membres ; publication des comptes.

---

## 8. Exigences non fonctionnelles

- **Accessibilité** : application, site web et saisie par animateur ; langues du pays ; pictogrammes ; prix en monnaie locale.
- **Faible connexion** : fonctionnement dégradé sur réseau lent et saisie différée pour les animateurs.
- **Smartphone d'abord** : espaces clients utilisables sur téléphone.
- **Données personnelles** : remontée des besoins sans données personnelles ; droits d'accès par niveau.
- **Traçabilité et audit** : journal des opérations financières, des votes et des livraisons ; accès en lecture seule pour l'auditeur.
- **Paramétrage** : seuils, taux, paliers, pondérations et étapes du parcours modifiables sans développement.
- **Multi-pays** : règles juridiques et fiscales paramétrables par pays.
- **Paiements** : intégration d'un partenaire de monnaie mobile agréé, sans conservation de fonds par la Ligue.
- **Publication** : barème, décomposition des prix et rapports annuels consultables par le public.

---

## 9. Lots de réalisation

| Lot | Contenu | Pourquoi dans cet ordre |
| --- | --- | --- |
| 1 | Territoires, parcours de formation, certification | Les premiers neurocitoyens se forment dès le mois 1 |
| 2 | Coopératives, membres, parts sociales | Création d'au moins cinq coopératives (mois 4 à 9) |
| 3 | Inscription et espaces clients sur AGORA | Les coopératives inscrivent leurs clients dès leur création |
| 4 | Catalogue, accords-cadres, barème, décomposition du prix | Prérequis de toute vente |
| 5 | Besoins, campagnes d'achat groupé, reçus | Cœur du démarrage (après 12 mois) |
| 6 | Centrale du MASA, commandes consolidées, livraison à la Cité, stocks | Ferme la chaîne d'approvisionnement |
| 7 | Gouvernance : assemblées, votes, résolutions | Nécessaire dès l'activation des niveaux |
| 8 | Finance, impact et Assises | Utiles après une première année d'activité et pour l'édition 1 (juillet 2027) |

---

## 10. Questions ouvertes

- [ ] MASA : statut juridique du niveau continental.
- [ ] Parcours : contenus, durées et critères de la certification de neurocitoyen.
- [ ] Cinq coopératives : par Cité ou par commune.
- [ ] Seuils d'activation des niveaux : cinq coopératives et douze mois.
- [ ] Barème de départ, paliers de dégressivité et pondération des voix aux niveaux supérieurs.
- [ ] Catalogue du pilote : valider les 9 produits actuels.
- [ ] Objectif d'inscrits par coopérative à l'ouverture.
- [ ] Pays et département du pilote.
- [ ] Partenaire de monnaie mobile et cadre réglementaire de l'épargne.

---

**FIN DU DOCUMENT**
