**Instructions**
**Instructions de laboratoire**
**0 sur 6 terminées**

### Activité 2 : Génération de modèles SQL à partir de templates (7 minutes)

**Contexte :** À l’image de la manière dont dbt Labs automatise la génération de modèles, vous devez créer des modèles SQL dynamiques capables de s’adapter à différents besoins de transformation tout en conservant une structure cohérente et les bonnes pratiques.

#### Étapes :

### Construire un moteur de templates SQL dynamiques

* Créez un système de templates flexible pour les modèles de requêtes `SELECT`, `JOIN` et d’agrégation.
* Implémentez la substitution de paramètres pour les noms de tables, les colonnes et la logique de transformation.

**Pourquoi la génération basée sur des templates est-elle essentielle pour maintenir des normes de codage SQL cohérentes entre les équipes ?**

### Implémenter le mappage de la logique de transformation

* Convertissez les spécifications de configuration en transformations SQL exécutables.
* Ajoutez la prise en charge de modèles courants tels que les agrégations, les filtres et les correspondances de colonnes (*column mappings*).

**Comment les équipes d’entreprise s’assurent-elles que le SQL généré respecte les bonnes pratiques d’optimisation des performances ?**

💡 **Conseil :** Utilisez des templates paramétrés plutôt que la concaténation de chaînes de caractères. Cette approche est plus sûre et plus facile à maintenir pour la génération de SQL complexe.

🤖 **Exploration avec un outil d’IA :** Essayez ce commentaire :

```python id="9t5nwx"
# Créer un template SQL avancé avec optimisation des performances et gestion des erreurs
```

### ⚙️ Testez votre travail :

* Générez du SQL à partir de paramètres de configuration.

**Résultat attendu :** Un modèle de transformation SQL valide avec une syntaxe correcte.

---

## DÉFI PRATIQUE 2

**TÂCHE :** Implémentez la fonction de génération de modèle SQL qui prend des paramètres de configuration en entrée et produit un modèle complet de transformation SQL comprenant des instructions `SELECT`, une logique de `JOIN` et des clauses `WHERE` basées sur les spécifications de configuration.

**Indice :** Utilisez des templates de chaînes de caractères avec `.format()` ou des f-strings afin d’injecter les valeurs de configuration dans les modèles SQL.

**Résultat attendu :** Un fichier de modèle SQL généré qui respecte les exigences de transformation définies dans la configuration.
