# Module 2 — SQL Model Template Generation

## Objectif du module

Ce module t'apprend à **générer dynamiquement du SQL** à partir d'une configuration, en appliquant le même pattern que les outils comme dbt : une source de vérité (le YAML) pilote la création de modèles SQL cohérents et reproductibles, sans copier-coller.

En tant que Data Engineer, tu vas souvent générer des dizaines de modèles SQL similaires. Faire cela à la main est lent et source d'erreurs. Un moteur de template résout le problème à la racine.

---

## Contexte : la structure du template SQL

La fonction `get_sql_template()` (fournie) retourne ce squelette :

```sql
WITH source_data AS (
    SELECT {source_columns}
    FROM {source_table}
    {where_clause}
),
transformed_data AS (
    SELECT
        {transformation_logic}
    FROM source_data
    {join_clause}
    {group_by_clause}
)
SELECT * FROM transformed_data
{order_by_clause};
```

Les `{accolades}` sont des **placeholders** que Python remplace via `.format()`. Notre rôle dans ce challenge est de construire les valeurs à injecter à chaque placeholder.

---

## Tâches réalisées — étape par étape

### Étape 1 : Extraire les champs obligatoires

```python
source_table = config['source_table']
target_table  = config['target_table']
transformations = config['transformations']
```

Ces 3 champs ont été validés en Challenge 1, donc on peut les lire directement. Pas besoin de vérifier à nouveau.

---

### Étape 2 : Construire `source_columns`

```python
cols = config.get('source_columns')
source_columns = ', '.join(cols) if cols else '*'
```

Le YAML peut lister des colonnes explicites :

```yaml
source_columns:
  - customer_id
  - customer_name
  - order_amount
```

On les joint en chaîne `customer_id, customer_name, order_amount`. Si le champ est absent, on utilise `*` (toutes les colonnes). C'est le comportement attendu en SQL quand aucune sélection n'est précisée.

**Point d'attention :** En production, `SELECT *` est déconseillé car il peut inclure des colonnes sensibles ou casser si le schéma change. Toujours préférer une liste explicite.

---

### Étape 3 : Construire `where_clause`

```python
where_conditions = config.get('where_conditions', [])
if where_conditions:
    where_clause = 'WHERE ' + '\n    AND '.join(where_conditions)
else:
    where_clause = ''
```

Le YAML liste des conditions :

```yaml
where_conditions:
  - order_status = 'completed'
  - order_date >= '2024-01-01'
```

Résultat généré :

```sql
WHERE order_status = 'completed'
    AND order_date >= '2024-01-01'
```

Si aucune condition n'est définie, on retourne une chaîne vide — le placeholder `{where_clause}` sera simplement vide dans le template, ce qui est du SQL valide.

---

### Étape 4 : Construire `transformation_logic`

```python
transformation_lines = [
    f'{expr} AS {alias}'
    for alias, expr in transformations.items()
]
transformation_logic = ',\n        '.join(transformation_lines)
```

Le YAML mappe les noms de colonnes de sortie vers leur expression SQL :

```yaml
transformations:
  customer_id: customer_id
  customer_name: UPPER(customer_name)
  total_revenue: SUM(order_amount)
```

La **list comprehension** itère sur les paires `(alias, expression)` du dictionnaire et produit :

```
customer_id AS customer_id,
UPPER(customer_name) AS customer_name,
SUM(order_amount) AS total_revenue
```

**Pourquoi `alias, expr` et pas `expr, alias` ?**
Dans le YAML, la clé est l'alias (nom de la colonne en sortie) et la valeur est l'expression source. En Python, `.items()` retourne `(clé, valeur)` donc `(alias, expression)`.

---

### Étape 5 : Construire `join_clause`

```python
joins = config.get('joins', [])
if joins:
    join_parts = [
        f"{j['type']} JOIN {j['table']} ON {j['condition']}"
        for j in joins
    ]
    join_clause = '\n    '.join(join_parts)
else:
    join_clause = ''
```

Le YAML décrit chaque JOIN avec 3 attributs :

```yaml
joins:
  - type: LEFT
    table: customer_segments
    condition: raw_sales_data.customer_id = customer_segments.customer_id
```

Résultat généré :

```sql
LEFT JOIN customer_segments ON raw_sales_data.customer_id = customer_segments.customer_id
```

Si plusieurs JOINs sont listés, chacun devient une ligne. Si aucun JOIN n'est défini, le placeholder est vide.

---

### Étape 6 : Construire `group_by_clause`

```python
group_by = config.get('group_by', [])
group_by_clause = f"GROUP BY {', '.join(group_by)}" if group_by else ''
```

```yaml
group_by:
  - customer_id
  - customer_name
```

Résultat : `GROUP BY customer_id, customer_name`

**Règle SQL à retenir :** Dans une requête avec des fonctions d'agrégation (`SUM`, `COUNT`, `AVG`), toutes les colonnes non agrégées doivent être dans le `GROUP BY`. Le YAML le rend explicite.

---

### Étape 7 : Construire `order_by_clause`

```python
order_by = config.get('order_by', [])
order_by_clause = f"ORDER BY {', '.join(order_by)}" if order_by else ''
```

```yaml
order_by:
  - total_revenue DESC
  - customer_name ASC
```

Résultat : `ORDER BY total_revenue DESC, customer_name ASC`

Note : le sens (`DESC`/`ASC`) est déjà inclus dans la valeur YAML, donc il est passé tel quel dans le SQL.

---

### Étape 8 : Injecter dans le template via `.format()`

```python
return template.format(
    source_table=source_table,
    target_table=target_table,
    timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    config_file=config_file,
    source_columns=source_columns,
    where_clause=where_clause,
    transformation_logic=transformation_logic,
    join_clause=join_clause,
    group_by_clause=group_by_clause,
    order_by_clause=order_by_clause,
)
```

`.format(**kwargs)` remplace chaque `{placeholder}` dans la chaîne template par la valeur correspondante. C'est l'équivalent d'un moteur de rendu de template (Jinja2, Mustache) mais avec les outils de base de Python.

---

## SQL généré à partir du fichier de config de ce lab

```sql
-- Generated SQL Transformation Model
-- Source: raw_sales_data
-- Target: transformed_sales_summary
-- Generated: 2026-06-23 22:08:12
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

---

## Impact de cette implémentation

| Aspect | Approche manuelle | Approche template |
|---|---|---|
| **Cohérence** | Chaque développeur écrit son propre style SQL | Tous les modèles suivent la même structure |
| **Scalabilité** | 50 tables = 50 fichiers SQL à écrire | 50 configs YAML = 50 SQL générés automatiquement |
| **Maintenance** | Modifier le pattern = modifier chaque fichier | Modifier le template = tous les modèles se mettent à jour |
| **Traçabilité** | Difficile de savoir d'où vient un modèle | Le commentaire en tête de fichier pointe vers la config source |

---

## Erreurs courantes à éviter

**1. Confondre alias et expression dans `.items()`**
```python
# CORRECT : (alias, expression) = (clé YAML, valeur YAML)
for alias, expr in transformations.items():
    f'{expr} AS {alias}'

# INCORRECT : produit "alias AS expression" → SQL invalide
for expr, alias in transformations.items():
    f'{expr} AS {alias}'
```

**2. Oublier la valeur par défaut dans `.get()`**
```python
# CORRECT : retourne [] si la clé est absente
config.get('joins', [])

# INCORRECT : lève une KeyError si 'joins' n'est pas dans le YAML
config['joins']
```

**3. Utiliser des f-strings dans le template principal**
Le template contient des `{accolades}` qui ressemblent à des f-strings mais ne le sont pas. Si tu utilisais un f-string pour le template, Python essaierait de résoudre `{source_table}` immédiatement — avant même d'avoir les valeurs. On utilise `.format()` qui diffère la substitution.

---

## Lien avec le métier de Data Engineer

Ce pattern — **config → template → artefact** — est le cœur de dbt, Great Expectations, et des générateurs de pipelines Airflow. En comprenant comment il fonctionne au niveau bas (string templating), tu seras capable de :

- Débugger n'importe quel outil de génération de code quand il produit du SQL inattendu.
- Construire tes propres générateurs pour des cas non couverts par les outils standard.
- Comprendre pourquoi les outils enterprise imposent des configs structurées plutôt que du SQL libre.
