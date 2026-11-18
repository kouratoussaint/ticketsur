## Objet

<!-- Ce que change la PR et pourquoi. Lien vers l'issue : Closes #… -->

## Exigences couvertes

<!-- ex. SCN-02, AT-04 -->

## Comment tester

```bash
bash scripts/db-test.sh
```

## Vérifications

- [ ] Tests ajoutés ou mis à jour, verts en local
- [ ] Tests de concurrence verts si `validate_scan`, `tickets` ou `scan_*` sont touchés
- [ ] RLS / permissions testées pour toute table ou fonction nouvelle
- [ ] Aucun secret, jeton QR ou donnée personnelle dans le code, les logs ou les captures
- [ ] Nouvelle migration (aucune migration fusionnée modifiée) ; retour arrière décrit si irréversible
- [ ] Documentation et CHANGELOG à jour
- [ ] Flux critique démontré sur appareil Android (à partir de la Phase 5)
