# Exercice dbt — Build Your First Parameterized dbt Pipeline

## Source

Ce document résume ce qui est demandé dans le fichier PDF fourni : **Build Your First Parameterized dbt Pipeline**.

## Contexte de l’exercice

Tu es data engineer dans une entreprise retail qui traite des transactions de ventes quotidiennes.

Aujourd’hui, l’équipe modifie manuellement des requêtes SQL chaque jour pour traiter les ventes de la veille. Cela implique de changer à la main :

- les filtres de date ;
- les paramètres régionaux ;
- les critères de statut.

Ce processus prend du temps, provoque des erreurs et empêche l’automatisation.

## Objectif principal

Créer un modèle **dbt paramétrable** capable de traiter automatiquement des données de ventes selon des paramètres d’exécution.

Le modèle doit pouvoir s’adapter à différentes combinaisons de :

- date ou plage de dates ;
- région ;
- statut de commande.

## Compétences à démontrer

À la fin de l’exercice, il faut être capable de :

- concevoir des requêtes SQL paramétrées ;
- utiliser la syntaxe des variables dbt avec `{{ var('nom_du_parametre') }}` ;
- créer une logique SQL réutilisable ;
- compiler et exécuter un modèle dbt avec différents paramètres ;
- vérifier que les résultats changent correctement selon les paramètres passés.

## Prérequis

Il faut disposer de :

- un environnement dbt CLI ou dbt Cloud ;
- un dataset retail de ventes ;
- une compréhension basique des requêtes SQL `SELECT` ;
- un éditeur de texte pour modifier les fichiers SQL.

## Structure de données attendue

L’exercice se base sur une table `orders`.

### Table `orders`

Colonnes attendues :

```text
order_id
customer_id
order_date
total_amount
status
region
product_category
```

## Requête SQL de départ

La requête statique à transformer est la suivante :

```sql
SELECT
    order_date,
    region,
    COUNT(*) as order_count,
    SUM(total_amount) as total_sales,
    AVG(total_amount) as avg_order_value
FROM orders
WHERE order_date = '2024-01-15'
  AND status = 'completed'
  AND region = 'North'
GROUP BY order_date, region
```

## Travail demandé

Transformer cette requête SQL statique en modèle dbt paramétrable.

Le modèle doit permettre de remplacer les valeurs fixes suivantes :

- `order_date = '2024-01-15'`
- `status = 'completed'`
- `region = 'North'`

par des variables dbt configurables.

## Étapes demandées

### Étape 1 — Créer la structure du modèle dbt

Créer un nouveau modèle dbt nommé :

```text
daily_sales_summary.sql
```

Dans un premier temps :

- écrire la requête SQL avec des valeurs fixes ;
- vérifier que le modèle fonctionne ;
- exécuter le modèle avec dbt.

### Étape 2 — Ajouter la configuration des variables

Modifier ou créer le fichier :

```text
dbt_project.yml
```

Ajouter les variables suivantes :

```yaml
vars:
  analysis_date: current date
  target_region: 'All'
  order_status: 'completed'
```

Les valeurs attendues sont :

- `analysis_date` : date d’analyse, par défaut la date courante ;
- `target_region` : région ciblée, par défaut `All` ;
- `order_status` : statut de commande, par défaut `completed`.

Ensuite, lancer :

```bash
dbt compile
```

pour vérifier que la syntaxe est correcte.

### Étape 3 — Implémenter la substitution de paramètres

Dans le modèle `daily_sales_summary.sql` :

Remplacer la date codée en dur par :

```jinja
{{ var('analysis_date') }}
```

Remplacer le statut codé en dur par :

```jinja
{{ var('order_status') }}
```

Ajouter une logique conditionnelle pour la région :

- si `target_region = 'All'`, ne pas filtrer sur une région précise ;
- sinon, filtrer sur la région fournie.

Ajouter aussi une validation des paramètres avec des blocs Jinja :

```jinja
{% if ... %}
{% endif %}
```

### Étape 4 — Tester plusieurs combinaisons de paramètres

Exécuter le modèle avec les paramètres par défaut.

Tester ensuite avec une région spécifique :

```bash
dbt run --vars '{"target_region": "South"}'
```

Tester avec un autre statut :

```bash
dbt run --vars '{"order_status": "pending"}'
```

Vérifier que les résultats changent correctement selon les paramètres utilisés.

### Étape 5 — Ajouter une logique métier supplémentaire

Améliorer le modèle avec :

- des agrégations conditionnelles ;
- des métriques spécifiques selon certaines régions ;
- une capacité à traiter plusieurs jours avec une plage de dates ;
- une documentation dans le fichier SQL expliquant les paramètres attendus.

## Critères de réussite

L’exercice est réussi si :

- le modèle dbt compile correctement ;
- le modèle dbt s’exécute correctement avec les paramètres par défaut ;
- les résultats changent lorsque les valeurs de paramètres changent ;
- le SQL utilise correctement `{{ var() }}` ;
- le modèle contient une logique conditionnelle adaptée ;
- les paramètres sont documentés dans le fichier du modèle.

## Pièges à éviter

### Mauvaise syntaxe de variable

dbt utilise :

```jinja
{{ var('param_name') }}
```

et non :

```bash
${param_name}
```

### Absence de valeurs par défaut

Toujours fournir des valeurs par défaut dans `dbt_project.yml` pour éviter les erreurs à l’exécution.

### Risque d’injection SQL

Éviter la concaténation directe de chaînes SQL dynamiques.

Préférer :

- les variables dbt ;
- la validation des paramètres ;
- les conditions Jinja contrôlées.



