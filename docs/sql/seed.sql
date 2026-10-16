-- =============================================================================
-- SEED MINIMAL — PRODUCTION BÉNIN
-- Ligue Panafricaine des Neurocitoyens
-- Version 1.0 — Octobre 2026
-- =============================================================================
-- Ce fichier insère :
--   - 12 départements du Bénin
--   - 77 communes du Bénin
--   - Barème de frais v1.0
--   - Catalogue pilote (9 produits)
--   - Configuration de la Ligue
--   - Assises 2027
-- =============================================================================
-- ⚠️ Les utilisateurs, coopératives et campagnes NAISSENT des Neurocitoyens.
--    Ce seed ne contient QUE les données administratives et paramétriques.
-- =============================================================================

-- =============================================================================
-- 1. DÉPARTEMENTS DU BÉNIN (12)
-- =============================================================================
INSERT INTO unites_territoriales (pays_code, niveau, nom, code) VALUES
  ('BJ', 4, 'Alibori', 'BJ-ALI'),
  ('BJ', 4, 'Atacora', 'BJ-ATA'),
  ('BJ', 4, 'Atlantique', 'BJ-ATL'),
  ('BJ', 4, 'Borgou', 'BJ-BOR'),
  ('BJ', 4, 'Collines', 'BJ-COL'),
  ('BJ', 4, 'Couffo', 'BJ-COU'),
  ('BJ', 4, 'Donga', 'BJ-DON'),
  ('BJ', 4, 'Littoral', 'BJ-LIT'),
  ('BJ', 4, 'Mono', 'BJ-MON'),
  ('BJ', 4, 'Ouémé', 'BJ-OUE'),
  ('BJ', 4, 'Plateau', 'BJ-PLA'),
  ('BJ', 4, 'Zou', 'BJ-ZOU')
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 2. COMMUNES DU BÉNIN (77)
-- =============================================================================
INSERT INTO unites_territoriales (pays_code, niveau, parent_id, nom, code)
SELECT 'BJ', 3, d.id, c.commune, c.code
FROM (VALUES
  -- ALIBORI (6)
  ('BJ-ALI', 'Banikoara', 'BJ-ALI-BAN'),
  ('BJ-ALI', 'Gogounou', 'BJ-ALI-GOG'),
  ('BJ-ALI', 'Kandi', 'BJ-ALI-KAN'),
  ('BJ-ALI', 'Karimama', 'BJ-ALI-KAR'),
  ('BJ-ALI', 'Malanville', 'BJ-ALI-MAL'),
  ('BJ-ALI', 'Ségbana', 'BJ-ALI-SEG'),
  -- ATACORA (9)
  ('BJ-ATA', 'Boukoumbé', 'BJ-ATA-BOU'),
  ('BJ-ATA', 'Cobly', 'BJ-ATA-COB'),
  ('BJ-ATA', 'Kérou', 'BJ-ATA-KER'),
  ('BJ-ATA', 'Kouandé', 'BJ-ATA-KOU'),
  ('BJ-ATA', 'Matéri', 'BJ-ATA-MAT'),
  ('BJ-ATA', 'Natitingou', 'BJ-ATA-NAT'),
  ('BJ-ATA', 'Péhunco', 'BJ-ATA-PEH'),
  ('BJ-ATA', 'Tanguiéta', 'BJ-ATA-TAN'),
  ('BJ-ATA', 'Toucountouna', 'BJ-ATA-TOU'),
  -- ATLANTIQUE (8)
  ('BJ-ATL', 'Abomey-Calavi', 'BJ-ATL-ABC'),
  ('BJ-ATL', 'Allada', 'BJ-ATL-ALL'),
  ('BJ-ATL', 'Kpomassè', 'BJ-ATL-KPO'),
  ('BJ-ATL', 'Ouidah', 'BJ-ATL-OUI'),
  ('BJ-ATL', 'Sô-Ava', 'BJ-ATL-SOA'),
  ('BJ-ATL', 'Toffo', 'BJ-ATL-TOF'),
  ('BJ-ATL', 'Tori-Bossito', 'BJ-ATL-TOR'),
  ('BJ-ATL', 'Zè', 'BJ-ATL-ZE'),
  -- BORGOU (8)
  ('BJ-BOR', 'Bembèrèkè', 'BJ-BOR-BEM'),
  ('BJ-BOR', 'Kalalé', 'BJ-BOR-KAL'),
  ('BJ-BOR', 'N''Dali', 'BJ-BOR-NDA'),
  ('BJ-BOR', 'Nikki', 'BJ-BOR-NIK'),
  ('BJ-BOR', 'Parakou', 'BJ-BOR-PAR'),
  ('BJ-BOR', 'Pèrèrè', 'BJ-BOR-PER'),
  ('BJ-BOR', 'Sinendé', 'BJ-BOR-SIN'),
  ('BJ-BOR', 'Tchaourou', 'BJ-BOR-TCH'),
  -- COLLINES (6)
  ('BJ-COL', 'Bantè', 'BJ-COL-BAN'),
  ('BJ-COL', 'Dassa-Zoumè', 'BJ-COL-DAS'),
  ('BJ-COL', 'Glazoué', 'BJ-COL-GLA'),
  ('BJ-COL', 'Ouèssè', 'BJ-COL-OUE'),
  ('BJ-COL', 'Savalou', 'BJ-COL-SAV'),
  ('BJ-COL', 'Savè', 'BJ-COL-SAX'),
  -- COUFFO (6)
  ('BJ-COU', 'Aplahoué', 'BJ-COU-APL'),
  ('BJ-COU', 'Djakotomey', 'BJ-COU-DJA'),
  ('BJ-COU', 'Dogbo', 'BJ-COU-DOG'),
  ('BJ-COU', 'Klouékanmè', 'BJ-COU-KLO'),
  ('BJ-COU', 'Lalo', 'BJ-COU-LAL'),
  ('BJ-COU', 'Toviklin', 'BJ-COU-TOV'),
  -- DONGA (4)
  ('BJ-DON', 'Bassila', 'BJ-DON-BAS'),
  ('BJ-DON', 'Copargo', 'BJ-DON-COP'),
  ('BJ-DON', 'Djougou', 'BJ-DON-DJO'),
  ('BJ-DON', 'Ouaké', 'BJ-DON-OUA'),
  -- LITTORAL (1)
  ('BJ-LIT', 'Cotonou', 'BJ-LIT-COT'),
  -- MONO (6)
  ('BJ-MON', 'Athiémé', 'BJ-MON-ATH'),
  ('BJ-MON', 'Bopa', 'BJ-MON-BOP'),
  ('BJ-MON', 'Comè', 'BJ-MON-COM'),
  ('BJ-MON', 'Grand-Popo', 'BJ-MON-GRA'),
  ('BJ-MON', 'Houéyogbé', 'BJ-MON-HOU'),
  ('BJ-MON', 'Lokossa', 'BJ-MON-LOK'),
  -- OUÉMÉ (9)
  ('BJ-OUE', 'Adjarra', 'BJ-OUE-ADJ'),
  ('BJ-OUE', 'Adjohoun', 'BJ-OUE-ADO'),
  ('BJ-OUE', 'Aguégués', 'BJ-OUE-AGU'),
  ('BJ-OUE', 'Akpro-Missérété', 'BJ-OUE-AKP'),
  ('BJ-OUE', 'Avrankou', 'BJ-OUE-AVR'),
  ('BJ-OUE', 'Bonou', 'BJ-OUE-BON'),
  ('BJ-OUE', 'Dangbo', 'BJ-OUE-DAN'),
  ('BJ-OUE', 'Porto-Novo', 'BJ-OUE-POR'),
  ('BJ-OUE', 'Sèmè-Kpodji', 'BJ-OUE-SEM'),
  -- PLATEAU (5)
  ('BJ-PLA', 'Adja-Ouèrè', 'BJ-PLA-ADJ'),
  ('BJ-PLA', 'Ifangni', 'BJ-PLA-IFA'),
  ('BJ-PLA', 'Kétou', 'BJ-PLA-KET'),
  ('BJ-PLA', 'Pobè', 'BJ-PLA-POB'),
  ('BJ-PLA', 'Sakété', 'BJ-PLA-SAK'),
  -- ZOU (9)
  ('BJ-ZOU', 'Abomey', 'BJ-ZOU-ABO'),
  ('BJ-ZOU', 'Agbangnizoun', 'BJ-ZOU-AGB'),
  ('BJ-ZOU', 'Bohicon', 'BJ-ZOU-BOH'),
  ('BJ-ZOU', 'Covè', 'BJ-ZOU-COV'),
  ('BJ-ZOU', 'Djidja', 'BJ-ZOU-DJI'),
  ('BJ-ZOU', 'Ouinhi', 'BJ-ZOU-OUI'),
  ('BJ-ZOU', 'Za-Kpota', 'BJ-ZOU-ZAK'),
  ('BJ-ZOU', 'Zagnanado', 'BJ-ZOU-ZAG'),
  ('BJ-ZOU', 'Zogbodomey', 'BJ-ZOU-ZOG')
) AS c(dept_code, commune, code)
JOIN unites_territoriales d ON d.code = c.dept_code AND d.pays_code = 'BJ'
ON CONFLICT DO NOTHING;

-- =============================================================================
-- 3. BARÈME DE FRAIS v1.0
-- =============================================================================
-- Barème : N1 = 8 %, N2-N6 = 4 % chacun, total 28 %
-- Contribution sur excédent : 5 % par niveau
-- Plafond frais amont (N6 à N2) : 20 %
-- =============================================================================
INSERT INTO bareme_frais (version, niveau, type_frais, taux, date_effet, statut, description) VALUES
  -- N1 — Coopérative de Quartier
  ('1.0', 1, 'service', 8.0, '2026-01-01', 'actif', 'Frais de service de la coopérative de quartier'),
  ('1.0', 1, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net de la CQ'),
  -- N2 — Coopérative d'Arrondissement
  ('1.0', 2, 'service', 4.0, '2026-01-01', 'actif', 'Frais de service de la coopérative d''arrondissement'),
  ('1.0', 2, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net de la CA'),
  -- N3 — Coopérative de Commune
  ('1.0', 3, 'service', 4.0, '2026-01-01', 'actif', 'Frais de service de la coopérative de commune'),
  ('1.0', 3, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net de la CC'),
  -- N4 — Coopérative de Département
  ('1.0', 4, 'service', 4.0, '2026-01-01', 'actif', 'Frais de service de la coopérative de département'),
  ('1.0', 4, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net de la CD'),
  -- N5 — Coopérative Nationale
  ('1.0', 5, 'service', 4.0, '2026-01-01', 'actif', 'Frais de service de la coopérative nationale'),
  ('1.0', 5, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net de la CN'),
  -- N6 — MASA
  ('1.0', 6, 'service', 4.0, '2026-01-01', 'actif', 'Frais de service du MASA'),
  ('1.0', 6, 'contribution_excedent', 5.0, '2026-01-01', 'actif', 'Contribution sur excédent net du MASA')
ON CONFLICT (version, niveau, type_frais) DO NOTHING;

-- =============================================================================
-- 4. CATALOGUE PILOTE (9 produits)
-- =============================================================================
INSERT INTO catalogue_produits (code, nom, description, famille, unite, poids_kg, actif) VALUES
  -- Famille A — Vivres
  ('A-HUILE-1L', 'Huile végétale 1 L', 'Huile de cuisine en bouteille de 1 litre', 'A', 'bouteille', 1.0, true),
  ('A-RIZ-50KG', 'Riz 50 kg', 'Riz blanc parfumé en sac de 50 kg', 'A', 'sac', 50.0, true),
  ('A-MAIS-50KG', 'Maïs 50 kg', 'Maïs grain sec en sac de 50 kg', 'A', 'sac', 50.0, true),
  ('A-HARICOT-25KG', 'Haricot 25 kg', 'Haricot sec en sac de 25 kg', 'A', 'sac', 25.0, true),
  ('A-PATES-500G', 'Pâtes alimentaires 500 g', 'Pâtes alimentaires en paquet de 500 g', 'A', 'paquet', 0.5, true),
  ('A-SUCRE-50KG', 'Sucre 50 kg', 'Sucre blanc cristallisé en sac de 50 kg', 'A', 'sac', 50.0, true),
  -- Famille B — Fournitures scolaires
  ('B-CAHIER-100P', 'Cahier 100 pages', 'Cahier scolaire 100 pages format A4', 'B', 'unite', 0.15, true),
  ('B-STYLO-BIC', 'Stylo à bille (bleu, noir, rouge)', 'Stylo à bille en 3 couleurs', 'B', 'unite', 0.01, true),
  ('B-BOITE-GEO', 'Boîte de géométrie complète', 'Boîte contenant compas, équerre, rapporteur, règle', 'B', 'boite', 0.2, true)
ON CONFLICT (code) DO NOTHING;

-- =============================================================================
-- 5. CONFIGURATION LIGUE (29 clés)
-- =============================================================================
INSERT INTO config_ligue (cle, valeur, type, public, description) VALUES
  -- Prix (PUBLICS)
  ('part_sociale', '5000', 'prix_fcfa', true, 'Part sociale remboursable à l''adhésion'),
  ('carte_membre_premiere_tranche', '500', 'prix_fcfa', true, 'Première tranche pour recevoir la carte membre'),
  ('formation_certifiante_prix', '5000', 'prix_fcfa', true, 'Prix d''une formation certifiante'),
  ('isln_prix', '50000', 'prix_fcfa', true, 'Prix du cursus ISLN complet'),
  ('eec_prix', '30000', 'prix_fcfa', true, 'Prix du cursus EEC complet'),
  
  -- Parcours (PUBLICS)
  ('etape1_gratuit', 'true', 'booleen', true, 'Étape 1 (Mur Invisible) gratuite'),
  ('paiement_graduel_max_tranches', '3', 'nombre', true, 'Nombre max de tranches pour paiement graduel'),
  ('message_verrouillage', 'Valide l''étape 1 pour débloquer cette section', 'texte', true, 'Message affiché quand une section est verrouillée'),
  
  -- Général (PUBLIC)
  ('devise', 'FCFA', 'texte', true, 'Devise principale'),
  ('devise_zone_cfa', 'FCFA', 'texte', true, 'Devise pour les pays de la zone CFA'),
  ('devise_hors_cfa', 'À définir par pays', 'texte', true, 'Devise pour les pays hors zone CFA'),
  
  -- Barème (PUBLICS)
  ('bareme_version_active', '1.0', 'texte', true, 'Version du barème en vigueur'),
  ('plafond_frais_amont', '20', 'nombre', true, 'Plafond des frais amont (N6 à N2) en pourcentage'),
  ('plafond_contribution_excedent', '5', 'nombre', true, 'Plafond contribution sur excédent par niveau'),
  
  -- Fédéralisme (PUBLICS)
  ('seuil_cinq_cooperatives', '5', 'nombre', true, 'Nombre minimum de coopératives actives pour activer un niveau'),
  ('duree_activation_mois', '12', 'nombre', true, 'Durée minimum (mois) avant activation'),
  ('max_manutentions', '3', 'nombre', true, 'Nombre maximum de manutentions'),
  ('frais_coordination_livraison_directe', '0.5', 'nombre', true, 'Frais de coordination livraison directe (%)'),
  
  -- Objectifs Bénin (PUBLICS)
  ('objectif_cooperatives_benin', '5', 'nombre', true, 'Objectif public : coopératives à créer au Bénin'),
  ('objectif_membres_benin', '500', 'nombre', true, 'Objectif public : membres au Bénin'),
  ('objectif_clients_inscrits', '2000', 'nombre', true, 'Objectif public : clients inscrits sur AGORA'),
  ('objectif_emplois_crees', '50', 'nombre', true, 'Objectif public : emplois à créer au Bénin'),
  
  -- Objectifs INTERNES
  ('objectif_neurocitoyens', '1000000', 'nombre', false, 'Objectif total de Neurocitoyens (interne)'),
  
  -- IA Guide (PRIVÉ — sécurité)
  ('IA_GUIDE_PROMPT', 'Tu es l''IA Guide de la République des Neurocitoyens. Tu accueilles, orientes et rassures.', 'texte', false, 'Prompt système de l''IA Guide (privé)')
ON CONFLICT (cle) DO UPDATE SET
  valeur = EXCLUDED.valeur,
  public = EXCLUDED.public,
  description = EXCLUDED.description,
  modifie_le = now();

-- =============================================================================
-- 6. ASSISES 2027 (Bénin, juillet)
-- =============================================================================
INSERT INTO assises_editions (
  annee, titre, theme, pays_hote, ville,
  date_debut, date_fin, format, statut, programme
) VALUES (
  2027,
  'Assises 2027 — Forum Africain de l''économie sociale et circulaire',
  'Fédérer les coopératives africaines pour une économie sociale et circulaire',
  'BJ',
  'Cotonou',
  '2027-07-01',
  '2027-07-03',
  'hybride',
  'planifiee',
  '{
    "jour_1": {
      "titre": "Congrès",
      "contenu": [
        "Rapport du Mansa sur l''état de la Ligue",
        "Reddition de comptes : Ligue, régions, Cités, flux fédéraux",
        "Vote des résolutions et du barème",
        "Remise des certifications et des grades"
      ]
    },
    "jour_2": {
      "titre": "Forum et formation",
      "contenu": [
        "Plénières et ateliers par secteur",
        "Masterclasses et bonnes pratiques",
        "Marché des coopératives",
        "Trophées des bonnes pratiques"
      ]
    },
    "jour_3": {
      "titre": "Passage à l''action",
      "contenu": [
        "Pitchs de nouvelles coopératives",
        "Mise en relation avec accompagnement et financements",
        "Signature d''engagements chiffrés par Cité",
        "Déclaration des Assises"
      ]
    }
  }'::jsonb
)
ON CONFLICT (annee) DO UPDATE SET
  titre = EXCLUDED.titre,
  theme = EXCLUDED.theme,
  programme = EXCLUDED.programme,
  modifie_le = now();

-- =============================================================================
-- VÉRIFICATION FINALE
-- =============================================================================
SELECT 'départements' AS t, count(*) FROM unites_territoriales WHERE pays_code = 'BJ' AND niveau = 4
UNION ALL SELECT 'communes', count(*) FROM unites_territoriales WHERE pays_code = 'BJ' AND niveau = 3
UNION ALL SELECT 'barème', count(*) FROM bareme_frais WHERE version = '1.0'
UNION ALL SELECT 'catalogue', count(*) FROM catalogue_produits
UNION ALL SELECT 'config', count(*) FROM config_ligue
UNION ALL SELECT 'assises', count(*) FROM assises_editions;

-- =============================================================================
-- FIN DU SEED
-- =============================================================================
