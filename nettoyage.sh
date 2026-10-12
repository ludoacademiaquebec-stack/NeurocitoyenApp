#!/bin/bash
# À lancer depuis la racine du projet :  bash nettoyage.sh
# Ne supprime que les doublons *_1.dart strictement identiques à leur original.
mkdir -p ../ligue_archive
for f in $(find lib -name "*_1.dart" | sort); do
  o="${f%_1.dart}.dart"
  if [ -f "$o" ] && diff -q "$f" "$o" >/dev/null; then
    rm "$f"
    echo "supprimé : $f"
  else
    echo "CONSERVÉ (différent) : $f"
  fi
done
if [ -f lib/core/router.dart ]; then
  mv lib/core/router.dart ../ligue_archive/router.dart.old
  echo "archivé : lib/core/router.dart (cassé et inutilisé)"
fi
if [ -f lib/features/home/home_screen.dart ]; then
  mv lib/features/home/home_screen.dart ../ligue_archive/home_screen.dart.old
  echo "archivé : lib/features/home/home_screen.dart (inutilisé)"
fi
echo "Terminé. Lancez : flutter analyze"
