# Module 1 — Configuration File Parser

## Objectif du module

Ce module t'apprend à construire la première brique d'un pipeline de données automatisé : **lire et valider un fichier de configuration YAML** avant d'en faire quoi que ce soit.

En Data Engineering, la configuration externe (YAML, JSON, TOML) est le standard pour décrire ce qu'un pipeline doit faire sans modifier le code source. Comme en backend tu as peut-être vu des fichiers `application.yml` ou `.env`, ici c'est la même idée mais pour décrire des transformations SQL.

---

## Contexte métier

Le script `model_generator.py` est un **générateur de modèles SQL** : il lit un fichier YAML qui décrit une transformation de données, et produit automatiquement le fichier `.sql` correspondant.

Avant de pouvoir générer quoi que ce soit, il faut s'assurer que le fichier de config est valide. C'est exactement ce que fait le **Practice Challenge 1**.

---

## Tâches réalisées — étape par étape

### Étape 1 : Vérifier l'existence du fichier

```python
check_config_file_exists(config_path)
```

Cette fonction est fournie (PROVIDED CODE). Elle vérifie si le fichier existe sur le disque. Si non, elle lève une `ModelGeneratorError` avec un message explicatif. On l'appelle en premier car il est inutile d'aller plus loin si le fichier est absent.

**Analogie backend :** c'est comme vérifier qu'un endpoint existe avant de faire un appel HTTP.

---

### Étape 2 : Lire et parser le YAML

```python
with open(config_path, 'r') as f:
    config = yaml.safe_load(f)
```

- `open(config_path, 'r')` ouvre le fichier en lecture.
- `yaml.safe_load(f)` parse le contenu YAML et le convertit en dictionnaire Python.

**Pourquoi `safe_load` et pas `load` ?**
`yaml.load()` peut exécuter du code Python arbitraire embarqué dans le YAML (une faille de sécurité). `yaml.safe_load()` interdit cela. En production, on utilise **toujours** `safe_load`.

Le bloc `try/except yaml.YAMLError` capture les fichiers YAML malformés (indentation incorrecte, caractères invalides, etc.) et remonte une erreur claire.

---

### Étape 3 : Vérifier que le résultat est un dictionnaire

```python
if not isinstance(config, dict):
    raise ModelGeneratorError("Configuration file must contain a YAML mapping...")
```

Un fichier YAML peut contenir autre chose qu'une map : une liste, un scalaire, `null`... On s'assure que la structure racine est bien un dictionnaire clé-valeur, ce qu'on attend.

---

### Étape 4 : Valider les champs obligatoires

```python
required_fields = ['source_table', 'target_table', 'transformations']
missing_fields = [field for field in required_fields if field not in config]
if missing_fields:
    raise ModelGeneratorError(...)
```

On vérifie que les 3 champs **indispensables** sont présents :

| Champ | Rôle |
|---|---|
| `source_table` | Table source dans la base de données |
| `target_table` | Table de destination après transformation |
| `transformations` | Mapping des colonnes de sortie vers leur logique SQL |

Sans ces 3 champs, le générateur SQL ne peut pas fonctionner. Mieux vaut échouer tôt avec un message clair que de produire un SQL incorrect.

---

### Étape 5 : Valider le type du champ `transformations`

```python
if not isinstance(config['transformations'], dict):
    raise ModelGeneratorError("'transformations' must be a YAML mapping...")
```

`transformations` doit être un dictionnaire (mapping YAML) du type :

```yaml
transformations:
  customer_id: customer_id
  total_revenue: SUM(order_amount)
```

Si quelqu'un met une liste ou une chaîne à la place, on remonte une erreur explicite.

---

### Étape 6 : Retourner la config validée

```python
return config
```

La fonction retourne le dictionnaire Python complet. Les modules suivants (`generate_sql_model`, `save_model_and_generate_report`) consommeront ce dictionnaire pour générer le SQL.

---

## Ce qui change dans le code

La fonction `load_and_validate_config` avait un corps vide (`pass`). Voici ce qu'on a ajouté :

- Appel à `check_config_file_exists` (déjà dans le stub, mais sans logique ensuite)
- Ouverture et parsing YAML avec gestion d'erreur
- Validation du type racine
- Validation des champs requis
- Validation du type de `transformations`
- `return config`

---

## Impact de ces modifications

| Aspect | Sans la validation | Avec la validation |
|---|---|---|
| **Fiabilité** | Le script crashe au milieu de l'exécution avec une erreur cryptique | Erreur claire et précoce avant tout traitement |
| **Maintenance** | Difficile de diagnostiquer d'où vient le problème | Le message d'erreur pointe exactement le champ manquant |
| **Sécurité** | Risque d'injection via `yaml.load` | `yaml.safe_load` bloque l'exécution de code |
| **Pipeline** | Un fichier YAML invalide peut corrompre des données en aval | Le pipeline s'arrête proprement avant d'écrire quoi que ce soit |

---

## Points d'attention et erreurs courantes

**1. Ne jamais utiliser `yaml.load()` sans le paramètre `Loader`**
```python
# DANGEREUX
config = yaml.load(f)

# CORRECT
config = yaml.safe_load(f)
```

**2. Le fichier YAML doit être dans le même répertoire que le script**
Quand on lance `python model_generator.py`, le chemin `"sample_transform_config.yml"` est relatif au répertoire courant (là où tu exécutes la commande), pas à l'emplacement du script.

```bash
# Lancer depuis le bon dossier
cd labor_1
python model_generator.py
```

**3. L'indentation YAML est critique**
YAML utilise les espaces (pas des tabulations) pour définir la hiérarchie. Une mauvaise indentation génère une `yaml.YAMLError`.

```yaml
# CORRECT
transformations:
  customer_id: customer_id   # 2 espaces

# INCORRECT (tabulation)
transformations:
	customer_id: customer_id   # tabulation = erreur
```

**4. `pass` en Python ne retourne pas `None` explicitement mais c'est équivalent**
Avant la correction, la fonction retournait `None` implicitement. Le code appelant dans `process_single_config` utilisait ensuite cette valeur comme un dict, ce qui aurait causé une `TypeError`. Valider et retourner tôt évite ce genre de bug silencieux.

---

## Lien avec le métier de Data Engineer

En tant que Data Engineer, tu vas souvent :

- Écrire des **pipelines configurables** (Airflow DAGs, dbt models, Spark jobs) pilotés par des fichiers YAML ou JSON.
- Valider des configs en **entrée de pipeline** pour éviter des corruptions en aval.
- Utiliser des exceptions personnalisées (`ModelGeneratorError`) pour distinguer les erreurs métier des erreurs techniques.

Ce pattern — *lire, parser, valider, retourner* — est la base de tout système de pipeline robuste.
