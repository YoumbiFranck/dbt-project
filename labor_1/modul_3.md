# Module 3 — Automated File Output and Validation

## Objectif du module

Ce module finalise le pipeline automatisé : après avoir lu la config (M1) et généré le SQL (M2), il faut **écrire le résultat sur le disque**, **valider sa syntaxe** et **retourner un rapport structuré** pour que l'appelant sache ce qui s'est passé.

En Data Engineering, un pipeline qui génère du code sans le valider avant d'écrire est dangereux — un fichier SQL corrompu peut casser tous les jobs Airflow ou les modèles dbt qui en dépendent.

---

## Contexte : ce que fait la fonction

`save_model_and_generate_report` est le **dernier maillon** de la chaîne. Elle est appelée par `process_single_config` (code fourni) après que le SQL a été généré :

```
load_and_validate_config  →  generate_sql_model  →  save_model_and_generate_report
       (Module 1)                 (Module 2)                  (Module 3)
```

Elle reçoit :
- `sql_content` : le SQL généré en Module 2
- `config` : le dictionnaire de configuration validé en Module 1
- `output_dir` : le répertoire créé par `setup_output_directory`
- `config_file` : le chemin du fichier YAML source

Elle doit retourner un dictionnaire de résultats que `main()` utilise pour afficher le rapport final.

---

## Tâches réalisées — étape par étape

### Étape 1 : Construire le nom du fichier

```python
target_table = config['target_table']
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
filename = f"{target_table}_{timestamp}.sql"
file_path = os.path.join(output_dir, filename)
```

Le nom du fichier combine :
- le nom de la table cible (`transformed_sales_summary`)
- l'horodatage (`20260623_234426`)

Résultat : `transformed_sales_summary_20260623_234426.sql`

**Pourquoi inclure le timestamp ?**
Si on relance le pipeline plusieurs fois sur la même config, chaque run produit un fichier distinct. Sans timestamp, chaque exécution écraserait le précédent et on perdrait l'historique de génération.

`os.path.join(output_dir, filename)` construit le chemin complet de façon portable (fonctionne sur Linux, Mac et Windows), contrairement à la concaténation de chaînes avec `/`.

---

### Étape 2 : Valider la syntaxe SQL avant d'écrire

```python
sql_valid = validate_sql_syntax(sql_content)
```

`validate_sql_syntax` est la fonction fournie (PROVIDED CODE). Elle vérifie que le SQL contient au minimum les mots-clés `SELECT` et `FROM`.

**Pourquoi valider AVANT d'écrire ?**
On applique le principe **"fail fast"** (échouer tôt) : si le SQL est invalide, autant le détecter maintenant plutôt qu'après l'avoir écrit sur le disque et potentiellement déclenché des jobs en aval.

Note : cette validation est basique (présence de mots-clés). En production, on utiliserait un vrai parseur SQL (ex: `sqlfluff`, `sqlparse`) pour détecter les erreurs de syntaxe réelles.

---

### Étape 3 : Écrire le fichier SQL sur le disque

```python
try:
    with open(file_path, 'w') as f:
        f.write(sql_content)
except OSError as e:
    raise ModelGeneratorError(f"Failed to write SQL model to {file_path}: {e}")
```

- `open(file_path, 'w')` ouvre le fichier en écriture (le crée s'il n'existe pas, l'écrase s'il existe).
- `with` garantit que le fichier est **toujours fermé** après l'écriture, même en cas d'exception — c'est le pattern standard en Python pour la gestion des ressources.
- Le `try/except OSError` capture les erreurs disque : permissions insuffisantes, disque plein, chemin inexistant.

**Analogie backend :** c'est l'équivalent d'une transaction de base de données — on s'assure que l'opération se termine proprement ou qu'on sait exactement pourquoi elle a échoué.

---

### Étape 4 : Retourner le rapport structuré

```python
return {
    'status': 'success',
    'filename': filename,
    'file_path': file_path,
    'source_table': config['source_table'],
    'target_table': target_table,
    'sql_valid': sql_valid,
    'config_file': config_file,
    'generated_at': timestamp,
}
```

Ce dictionnaire est le **rapport de génération**. Il contient tout ce qu'un système appelant a besoin de savoir :

| Clé | Contenu | Utilisé par |
|---|---|---|
| `status` | `'success'` ou `'error'` | `main()` pour choisir l'affichage |
| `filename` | Nom du fichier créé | `process_single_config` pour le log |
| `file_path` | Chemin complet | Intégration avec des outils tiers |
| `source_table` | Table source | `main()` pour le résumé |
| `target_table` | Table cible | `main()` pour le résumé |
| `sql_valid` | `True` / `False` | `main()` pour le statut de validation |
| `config_file` | Fichier YAML utilisé | Traçabilité / audit |
| `generated_at` | Timestamp | Historique de génération |

---

## SQL généré et sauvegardé

Voici le contenu réel du fichier produit par le pipeline complet :

```sql
-- Generated SQL Transformation Model
-- Source: raw_sales_data
-- Target: transformed_sales_summary
-- Generated: 2026-06-23 23:44:26
-- Configuration: sample_transform_config.yml

WITH source_data AS (
    SELECT customer_id, customer_name, order_amount, order_date
    FROM raw_sales_data
    WHERE order_status = 'completed'
    AND order_date >= '2024-01-01'
),
transformed_data AS (
    SELECT
        customer_id AS customer_id,
        UPPER(customer_name) AS customer_name,
        SUM(order_amount) AS total_revenue,
        AVG(order_amount) AS avg_order_value,
        COUNT(*) AS order_count
    FROM source_data
    LEFT JOIN customer_segments ON raw_sales_data.customer_id = customer_segments.customer_id
    GROUP BY customer_id, customer_name
)
SELECT * FROM transformed_data
ORDER BY total_revenue DESC, customer_name ASC;
```

Localisé dans : `generated_models/models_YYYYMMDD_HHMMSS/transformed_sales_summary_YYYYMMDD_HHMMSS.sql`

---

## Sortie complète du pipeline (les 3 modules enchaînés)

```
🚀 Data Transformation Model Generator
==================================================
✅ Created output directory: generated_models/models_20260623_234426
✅ Configuration file found: sample_transform_config.yml

🔄 Processing configuration: sample_transform_config.yml
✅ Configuration loaded and validated        ← Module 1
✅ SQL model generated                       ← Module 2
✅ Model saved: transformed_sales_summary_20260623_234426.sql  ← Module 3

📊 Generation Summary
==============================
✅ Successfully generated: transformed_sales_summary_20260623_234426.sql
📋 Source table: raw_sales_data
🎯 Target table: transformed_sales_summary
✓ SQL validation: Passed
```

---

## Impact de cette implémentation

| Aspect | Sans ce module | Avec ce module |
|---|---|---|
| **Persistance** | Le SQL existe en mémoire et est perdu à la fin du script | Le SQL est sauvegardé sur disque, intégrable dans dbt/Airflow |
| **Traçabilité** | Aucune trace de ce qui a été généré | Fichiers horodatés + rapport structuré |
| **Intégration** | Impossible à utiliser dans un pipeline automatisé | Le dict retourné permet à l'orchestrateur de savoir si continuer |
| **Sécurité** | Un SQL corrompu pourrait être exécuté silencieusement | Validation avant écriture bloque les artefacts invalides |

---

## Erreurs courantes à éviter

**1. Écrire avant de valider**
```python
# INCORRECT : on écrit d'abord, on valide après (trop tard)
with open(file_path, 'w') as f:
    f.write(sql_content)
sql_valid = validate_sql_syntax(sql_content)

# CORRECT : valider en premier
sql_valid = validate_sql_syntax(sql_content)
with open(file_path, 'w') as f:
    f.write(sql_content)
```

**2. Construire les chemins avec la concaténation de chaînes**
```python
# INCORRECT : casse sur Windows (séparateur différent)
file_path = output_dir + "/" + filename

# CORRECT : portable sur tous les OS
file_path = os.path.join(output_dir, filename)
```

**3. Ne pas capturer `OSError`**
Si le répertoire `output_dir` n'existe pas ou si les permissions sont insuffisantes, `open()` lève une `OSError`. Sans `try/except`, le script crashe avec un message cryptique au lieu d'une erreur explicite.

**4. Oublier `status` dans le retour**
`main()` teste `result['status'] == 'success'`. Si la clé est absente, Python lève une `KeyError`. La gestion d'erreur dans `process_single_config` (PROVIDED CODE) retourne déjà `{'status': 'error', ...}` en cas d'exception — notre fonction doit retourner `{'status': 'success', ...}` en cas de succès.

---

## Lien avec le métier de Data Engineer

Ce module illustre trois principes fondamentaux du Data Engineering :

**1. Idempotence et horodatage**
Chaque exécution produit un fichier distinct grâce au timestamp. On peut rejouer le pipeline sans risque d'écraser un artefact précédent — principe d'idempotence essentiel dans les pipelines Airflow.

**2. Rapport structuré (observabilité)**
Retourner un dict plutôt qu'imprimer des messages permet à l'orchestrateur (Airflow, Prefect, dbt) de récupérer les métadonnées de chaque run. C'est la base de l'observabilité des pipelines.

**3. Séparation génération / persistence**
`generate_sql_model` produit le SQL en mémoire. `save_model_and_generate_report` écrit sur le disque. Cette séparation permet de tester la génération SQL sans toucher au disque, et de brancher d'autres destinations (S3, GCS, base de données) sans modifier la logique de génération.
