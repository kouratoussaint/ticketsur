# ADR 0036 — Console pro : annonces programmées, réponses types, courbes sur 30 jours

- Statut : acceptée
- Date : 21 novembre 2026
- Décideur : Toussaint (lot 4-8 validé le 21/11, `claude/proposition-suite-sans-paiement.md`)

## Décisions

1. **Annonces programmées** (migration 4700) : `admin_publish_announcement(..., p_starts_at)` accepte un début entre maintenant et 90 jours (null = tout de suite) ; la version à 5 paramètres est remplacée, les anciennes APK l'appellent toujours sans ce paramètre. `admin_update_announcement` modifie une annonce **tant qu'elle n'a pas commencé** (`announcement_started` sinon). `admin_announcements` ajoute `scheduled`.
2. **Notification à l'heure** : `announcements.pushed_at` ; le déclencheur (désormais `before insert`) n'envoie que si l'annonce commence déjà ; `private.push_due_announcements(now)`, appelée par `push_tick` (toutes les 5 minutes), met en file les annonces importantes arrivées à leur début, une seule fois. Les annonces existantes sont marquées comme envoyées.
3. **Réponses types du support** : table `support_reply_templates` fermée à l'API (titre 2–60, texte 1–2000, 50 au plus) ; `admin_support_templates`, `admin_save_support_template`, `admin_delete_support_template`. Dans un fil de la console, le bouton « Réponses types » insère le texte dans la réponse, modifiable avant l'envoi.
4. **Courbes sur 30 jours** : `admin_daily_stats(jours 7–90)` → par jour UTC (= heure de Ouagadougou) : comptes créés, structures créées, événements publiés pour la première fois (journal `event.status_changed` vers `published`), tickets émis, entrées validées. Carte « 30 derniers jours » sur la vue d'ensemble, une mesure à la fois.
5. **Journal** : `admin.announcement_updated` (destinataires, importance), `admin.support_template_saved` (`created`), `admin.support_template_deleted` ; `admin.announcement_published` ajoute `scheduled: true` pour une annonce programmée. Jamais le texte d'une annonce ni d'un modèle.

## Conséquences

- Aucun coût. Une annonce programmée importante part à 5 minutes près.
- Les libellés du journal de `organization.settings_updated` et `event.defaults_applied` (lot 4-7b) sont ajoutés au passage.
