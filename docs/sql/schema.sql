-- =============================================================================
-- SCHÉMA COMPLET — FÉDÉRATION DE COOPÉRATIVES
-- Ligue Panafricaine des Neurocitoyens
-- Version 1.0 — Octobre 2026
-- =============================================================================
-- 32+ tables couvrant :
--   - Territoires et coopératives
--   - Clients et AGORA
--   - Besoins et campagnes d'achat groupé
--   - Commandes et MASA
--   - Stocks et livraisons
--   - Finance et ristournes
--   - Gouvernance
--   - Impact et Assises
-- =============================================================================

-- =============================================================================
-- DOMAINE 1 : TERRITOIRES
-- =============================================================================
CREATE TABLE IF NOT EXISTS unites_territoriales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pays_code text NOT NULL REFERENCES countries(id),
  niveau int NOT NULL,
  parent_id uuid REFERENCES unites_territoriales(id),
  nom text NOT NULL,
  code text,
  population int,
  actif boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_unites_pays ON unites_territoriales(pays_code);
CREATE INDEX IF NOT EXISTS idx_unites_niveau ON unites_territoriales(niveau);
CREATE INDEX IF NOT EXISTS idx_unites_parent ON unites_territoriales(parent_id);

-- =============================================================================
-- DOMAINE 2 : COOPÉRATIVES
-- =============================================================================
CREATE TABLE IF NOT EXISTS cooperatives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  nom text NOT NULL,
  niveau int NOT NULL,
  parent_id uuid REFERENCES cooperatives(id),
  unite_territoriale_id uuid REFERENCES unites_territoriales(id),
  pays_code text NOT NULL REFERENCES countries(id),
  statut text DEFAULT 'comite',
  date_creation date,
  date_operationnelle date,
  nombre_membres int DEFAULT 0,
  part_sociale_fcfa int DEFAULT 5000,
  fonds_roulement_fcfa bigint DEFAULT 0,
  actif boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_coop_niveau ON cooperatives(niveau);
CREATE INDEX IF NOT EXISTS idx_coop_parent ON cooperatives(parent_id);
CREATE INDEX IF NOT EXISTS idx_coop_pays ON cooperatives(pays_code);

CREATE TABLE IF NOT EXISTS cooperative_membres (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text DEFAULT 'membre',
  parts_sociales_souscrites int DEFAULT 1,
  parts_sociales_payees int DEFAULT 0,
  parts_sociales_remboursees int DEFAULT 0,
  date_adhesion date DEFAULT CURRENT_DATE,
  statut text DEFAULT 'actif',
  created_at timestamptz DEFAULT now(),
  UNIQUE(cooperative_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_membres_coop ON cooperative_membres(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_membres_user ON cooperative_membres(user_id);

CREATE TABLE IF NOT EXISTS coop_etapes_creation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  etape int NOT NULL,
  nom text NOT NULL,
  statut text DEFAULT 'non_commence',
  date_debut date,
  date_fin date,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS parts_sociales_mouvements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type text NOT NULL,
  nombre_parts int NOT NULL,
  montant_fcfa int NOT NULL,
  date_mouvement timestamptz DEFAULT now(),
  statut text DEFAULT 'valide',
  notes text
);

-- =============================================================================
-- DOMAINE 3 : CLIENTS ET AGORA
-- =============================================================================
CREATE TABLE IF NOT EXISTS clients_inscrits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  cooperative_id uuid REFERENCES cooperatives(id) ON DELETE SET NULL,
  unite_territoriale_id uuid REFERENCES unites_territoriales(id),
  pays_code text NOT NULL REFERENCES countries(id),
  type_client text NOT NULL,
  nom_affichage text,
  email text,
  telephone text,
  adresse text,
  charte_signee boolean DEFAULT false,
  actif boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clients_coop ON clients_inscrits(cooperative_id);
CREATE INDEX IF NOT EXISTS idx_clients_user ON clients_inscrits(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_type ON clients_inscrits(type_client);
CREATE INDEX IF NOT EXISTS idx_clients_pays ON clients_inscrits(pays_code);

CREATE TABLE IF NOT EXISTS espaces_clients (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid UNIQUE NOT NULL REFERENCES clients_inscrits(id) ON DELETE CASCADE,
  langue text DEFAULT 'fr',
  notifications_email boolean DEFAULT true,
  notifications_sms boolean DEFAULT true,
  points_retrait_preferes jsonb,
  preferences jsonb,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 4 : BESOINS ET CAMPAGNES
-- =============================================================================
CREATE TABLE IF NOT EXISTS besoins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id uuid NOT NULL REFERENCES clients_inscrits(id) ON DELETE CASCADE,
  cooperative_id uuid REFERENCES cooperatives(id) ON DELETE SET NULL,
  produit_id uuid,
  produit_libre text,
  quantite numeric NOT NULL,
  unite text DEFAULT 'unite',
  prix_souhaite_fcfa int,
  lieu_retrait text,
  date_limite date,
  statut text DEFAULT 'ouvert',
  notes text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS campagnes_achat (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  produit_id uuid,
  produit_libre text,
  unite text DEFAULT 'unite',
  quantite_minimum numeric NOT NULL,
  quantite_actuelle numeric DEFAULT 0,
  prix_unitaire_estime_fcfa int,
  date_ouverture timestamptz DEFAULT now(),
  date_cloture timestamptz NOT NULL,
  statut text DEFAULT 'ouverte',
  source_achat text,
  commande_consolidee_id uuid,
  notes text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS campagnes_participations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campagne_id uuid NOT NULL REFERENCES campagnes_achat(id) ON DELETE CASCADE,
  client_id uuid NOT NULL REFERENCES clients_inscrits(id) ON DELETE CASCADE,
  besoin_id uuid REFERENCES besoins(id) ON DELETE SET NULL,
  quantite numeric NOT NULL,
  prix_unitaire_fcfa int,
  prix_total_fcfa int,
  statut text DEFAULT 'confirme',
  date_participation timestamptz DEFAULT now(),
  date_paiement timestamptz,
  date_livraison timestamptz,
  mode_paiement text,
  reference_paiement text,
  notes text
);

-- =============================================================================
-- DOMAINE 5 : CATALOGUE
-- =============================================================================
CREATE TABLE IF NOT EXISTS catalogue_produits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  nom text NOT NULL,
  description text,
  famille text NOT NULL,
  unite text DEFAULT 'unite',
  poids_kg numeric,
  image_url text,
  actif boolean DEFAULT true,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS accords_cadres (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  fournisseur_nom text NOT NULL,
  fournisseur_pays text,
  source text NOT NULL,
  prix_unitaire_fcfa int,
  quantite_minimum numeric,
  unite text DEFAULT 'unite',
  devise text DEFAULT 'FCFA',
  conditions text,
  date_debut date,
  date_fin date,
  statut text DEFAULT 'actif',
  document_url text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 6 : COMMANDES
-- =============================================================================
CREATE TABLE IF NOT EXISTS commandes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  type_commande text NOT NULL,
  cooperative_id uuid REFERENCES cooperatives(id),
  niveau int,
  pays_code text REFERENCES countries(id),
  parent_id uuid REFERENCES commandes(id),
  statut text DEFAULT 'brouillon',
  montant_total_fcfa bigint DEFAULT 0,
  montant_paye_fcfa bigint DEFAULT 0,
  date_commande timestamptz DEFAULT now(),
  date_validation timestamptz,
  date_livraison_prevue date,
  date_livraison_reelle date,
  notes text,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS commande_lignes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  commande_id uuid NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  quantite numeric NOT NULL,
  unite text DEFAULT 'unite',
  prix_unitaire_achat_fcfa int,
  prix_unitaire_vente_fcfa int,
  marge_fcfa int,
  source text,
  fournisseur text,
  decomposition_prix jsonb,
  statut text DEFAULT 'en_attente',
  created_at timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 7 : MASA
-- =============================================================================
CREATE TABLE IF NOT EXISTS masa_achats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  quantite numeric NOT NULL,
  unite text DEFAULT 'unite',
  fournisseur_nom text,
  fournisseur_pays text,
  prix_unitaire_achat_fcfa int NOT NULL,
  prix_total_achat_fcfa bigint NOT NULL,
  devise_origine text DEFAULT 'FCFA',
  taux_change numeric DEFAULT 1,
  mise_en_concurrence jsonb,
  source text,
  pays_source text,
  statut text DEFAULT 'planifie',
  date_commande date,
  date_reception_prevue date,
  date_reception_reelle date,
  document_url text,
  notes text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS masa_livraisons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  achat_id uuid NOT NULL REFERENCES masa_achats(id) ON DELETE CASCADE,
  pays_destination text NOT NULL REFERENCES countries(id),
  responsable_cite_id uuid REFERENCES users(id),
  quantite_livree numeric NOT NULL,
  unite text DEFAULT 'unite',
  statut text DEFAULT 'preparee',
  date_expedition date,
  date_reception_prevue date,
  date_reception_reelle date,
  bon_livraison_url text,
  notes text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS dispatch_internes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  livraison_id uuid REFERENCES masa_livraisons(id) ON DELETE CASCADE,
  commande_id uuid REFERENCES commandes(id),
  cooperative_source_id uuid REFERENCES cooperatives(id),
  cooperative_destination_id uuid REFERENCES cooperatives(id),
  quantite numeric NOT NULL,
  unite text DEFAULT 'unite',
  statut text DEFAULT 'prepare',
  date_expedition date,
  date_reception date,
  manutentions int DEFAULT 0,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 8 : STOCKS
-- =============================================================================
CREATE TABLE IF NOT EXISTS mouvements_stock (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  type_mouvement text NOT NULL,
  quantite numeric NOT NULL,
  unite text DEFAULT 'unite',
  stock_avant numeric,
  stock_apres numeric,
  reference text,
  motif text,
  date_mouvement timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stock_actuel (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  quantite_disponible numeric DEFAULT 0,
  unite text DEFAULT 'unite',
  seuil_alerte numeric,
  derniere_entree timestamptz,
  derniere_sortie timestamptz,
  modifie_le timestamptz DEFAULT now(),
  UNIQUE(cooperative_id, produit_id)
);

-- =============================================================================
-- DOMAINE 9 : REÇUS
-- =============================================================================
CREATE TABLE IF NOT EXISTS recus (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  client_id uuid NOT NULL REFERENCES clients_inscrits(id) ON DELETE CASCADE,
  participation_id uuid REFERENCES campagnes_participations(id),
  commande_id uuid REFERENCES commandes(id),
  montant_fcfa bigint NOT NULL,
  mode_paiement text,
  contenu jsonb,
  url_pdf text,
  qr_code text,
  created_at timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 10 : BARÈME ET FINANCE
-- =============================================================================
CREATE TABLE IF NOT EXISTS bareme_frais (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version text NOT NULL,
  niveau int NOT NULL,
  type_frais text NOT NULL,
  taux numeric NOT NULL,
  plafond numeric,
  date_effet date NOT NULL,
  date_fin date,
  statut text DEFAULT 'actif',
  vote_assemblee_id uuid,
  description text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(version, niveau, type_frais)
);

CREATE TABLE IF NOT EXISTS repartitions_excedent (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  annee int NOT NULL,
  excedent_brut_fcfa bigint NOT NULL,
  pertes_reportees_fcfa bigint DEFAULT 0,
  reserve_indivisible_fcfa bigint DEFAULT 0,
  fonds_formation_fcfa bigint DEFAULT 0,
  contribution_federale_fcfa bigint DEFAULT 0,
  interet_parts_fcfa bigint DEFAULT 0,
  ristourne_membres_fcfa bigint DEFAULT 0,
  excedent_net_fcfa bigint NOT NULL,
  statut text DEFAULT 'calcule',
  date_calcul timestamptz DEFAULT now(),
  date_versement timestamptz,
  notes text,
  UNIQUE(cooperative_id, annee)
);

CREATE TABLE IF NOT EXISTS ristournes_membres (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  annee int NOT NULL,
  usage_total_fcfa bigint DEFAULT 0,
  ristourne_fcfa bigint DEFAULT 0,
  statut text DEFAULT 'calcule',
  date_versement timestamptz,
  created_at timestamptz DEFAULT now(),
  UNIQUE(cooperative_id, user_id, annee)
);

CREATE TABLE IF NOT EXISTS fonds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text UNIQUE NOT NULL,
  nom text NOT NULL,
  type_fonds text NOT NULL,
  niveau int,
  cooperative_id uuid REFERENCES cooperatives(id),
  pays_code text REFERENCES countries(id),
  solde_fcfa bigint DEFAULT 0,
  objectif_fcfa bigint,
  statut text DEFAULT 'actif',
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fonds_mouvements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  fonds_id uuid NOT NULL REFERENCES fonds(id) ON DELETE CASCADE,
  type_mouvement text NOT NULL,
  montant_fcfa bigint NOT NULL,
  motif text,
  reference text,
  date_mouvement timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 11 : GOUVERNANCE
-- =============================================================================
CREATE TABLE IF NOT EXISTS assemblees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid REFERENCES cooperatives(id) ON DELETE CASCADE,
  niveau int,
  type_assemblee text NOT NULL,
  titre text NOT NULL,
  ordre_du_jour jsonb,
  date_convocation timestamptz DEFAULT now(),
  date_seance timestamptz NOT NULL,
  lieu text,
  lien_visio text,
  quorum_requis int,
  quorum_atteint int DEFAULT 0,
  statut text DEFAULT 'planifiee',
  proces_verbal_url text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS resolutions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  assemblee_id uuid REFERENCES assemblees(id) ON DELETE CASCADE,
  cooperative_id uuid REFERENCES cooperatives(id) ON DELETE CASCADE,
  titre text NOT NULL,
  texte text NOT NULL,
  type text DEFAULT 'ordinaire',
  statut text DEFAULT 'deposee',
  votes_pour int DEFAULT 0,
  votes_contre int DEFAULT 0,
  votes_abstention int DEFAULT 0,
  date_depot timestamptz DEFAULT now(),
  date_vote timestamptz,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resolution_id uuid NOT NULL REFERENCES resolutions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  cooperative_id uuid REFERENCES cooperatives(id),
  vote text NOT NULL,
  poids int DEFAULT 1,
  date_vote timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(resolution_id, user_id)
);

CREATE TABLE IF NOT EXISTS mandats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid NOT NULL REFERENCES cooperatives(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL,
  date_debut date NOT NULL,
  date_fin date,
  statut text DEFAULT 'en_cours',
  assemblee_election_id uuid REFERENCES assemblees(id),
  notes text,
  created_at timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 12 : IMPACT ET ASSISES
-- =============================================================================
CREATE TABLE IF NOT EXISTS indicateurs_impact (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooperative_id uuid REFERENCES cooperatives(id) ON DELETE CASCADE,
  unite_territoriale_id uuid REFERENCES unites_territoriales(id),
  pays_code text REFERENCES countries(id),
  periode text NOT NULL,
  neurocitoyens_certifies int DEFAULT 0,
  cooperatives_actives int DEFAULT 0,
  membres_total int DEFAULT 0,
  clients_inscrits int DEFAULT 0,
  emplois_crees int DEFAULT 0,
  chiffre_affaires_fcfa bigint DEFAULT 0,
  excedents_fcfa bigint DEFAULT 0,
  part_achats_locaux numeric DEFAULT 0,
  metadata jsonb,
  created_at timestamptz DEFAULT now(),
  UNIQUE(cooperative_id, periode)
);

CREATE TABLE IF NOT EXISTS releves_prix_marche (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pays_code text NOT NULL REFERENCES countries(id),
  unite_territoriale_id uuid REFERENCES unites_territoriales(id),
  produit_id uuid REFERENCES catalogue_produits(id),
  produit_libre text,
  prix_moyen_fcfa int NOT NULL,
  prix_min_fcfa int,
  prix_max_fcfa int,
  date_releve date NOT NULL,
  source text,
  notes text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assises_editions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  annee int NOT NULL UNIQUE,
  titre text NOT NULL,
  theme text,
  pays_hote text REFERENCES countries(id),
  ville text,
  date_debut date,
  date_fin date,
  format text DEFAULT 'hybride',
  lien_visio text,
  programme jsonb,
  statut text DEFAULT 'planifiee',
  rapport_url text,
  declaration_url text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS assises_inscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  edition_id uuid NOT NULL REFERENCES assises_editions(id) ON DELETE CASCADE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  cooperative_id uuid REFERENCES cooperatives(id),
  pays_code text REFERENCES countries(id),
  type_participation text DEFAULT 'membre',
  presentiel boolean DEFAULT true,
  montant_inscription_fcfa int DEFAULT 0,
  statut text DEFAULT 'inscrit',
  created_at timestamptz DEFAULT now(),
  UNIQUE(edition_id, user_id)
);

CREATE TABLE IF NOT EXISTS assises_engagements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  edition_id uuid NOT NULL REFERENCES assises_editions(id) ON DELETE CASCADE,
  pays_code text NOT NULL REFERENCES countries(id),
  cooperative_id uuid REFERENCES cooperatives(id),
  type_engagement text NOT NULL,
  objectif int NOT NULL,
  realise int DEFAULT 0,
  periode text,
  statut text DEFAULT 'en_cours',
  notes text,
  created_at timestamptz DEFAULT now(),
  modifie_le timestamptz DEFAULT now()
);

-- =============================================================================
-- DOMAINE 13 : AUDIT
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  row_id uuid,
  user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  action text NOT NULL,
  old_data jsonb,
  new_data jsonb,
  user_email text,
  ip_address text,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_table ON audit_log(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_date ON audit_log(created_at DESC);

-- =============================================================================
-- FIN DU SCHÉMA
-- =============================================================================
