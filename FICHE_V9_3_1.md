V9.3 AUTH GUARD + PROFIL CRUD COMPLET

- Pages publiques : /, /carte, /inscription, /charte, /modele-eco, /ia-guide
- Pages protegees : /dashboard, /modules, /module/:id, /universite, /forum, /banque, /coop, /profil, /admin -> si non connecte (pas code_parrain), redirect /inscription?pays=BJ&redirect=...
- Profil : avatar URL modifiable avec camera icon (pravatar), prenom/nom/email/phone modifiables, pays (dropdown 55 cites), commune/deme, quartier/agora modifiables si demenagement, poles (3 max), interets elargis, bouton sauvegarder CRUD SharedPreferences + snackbar, changer mot de passe, deconnexion clear
- Admin : liste utilisateurs (moi + filleuls + Mansa/Ola), recherche, stats total/cites/actifs, boutons Ajouter membre equipe CRUD, Creer Forum Continental, Voir Tresorerie BCN, popup Modifier grade/role, Suspendre, Supprimer
- Dashboard reste complet avec bienvenue, QR, arbre
