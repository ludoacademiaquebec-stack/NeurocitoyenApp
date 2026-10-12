# Mise en place (dans l'ordre)

1. Sauvegarde déjà faite (../ligue_v9_4_lib_backup).
2. Copier dans le projet, aux mêmes chemins :
   - lib/features/home/landing_screen.dart  (remplace la page d'accueil réelle)
   - lib/features/panafricain/carte_afrique_screen.dart  (remplace l'écran « Cités »)
   - lib/widgets/africa_map.dart  (nouveau)
   - lib/app.dart  (ajout de /poles + correction du contrôle d'accès)
   - assets/geo/africa_50m.json  (à la racine du projet : créer dossiers assets/geo)
3. pubspec.yaml : ajouter l'asset (voir pubspec_extrait.yaml), puis `flutter pub get`.
4. `bash nettoyage.sh` : supprime les doublons identiques, archive router.dart et home_screen.dart.
5. `flutter analyze` puis `flutter run`.
