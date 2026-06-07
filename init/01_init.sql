-- =============================================================================
-- Initialisation des données de démonstration
-- Schéma "raw" : simule des données brutes provenant d'une source externe
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS raw;

-- ─── Table customers ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS raw.customers (
    id            INTEGER,
    first_name    VARCHAR(50),
    last_name     VARCHAR(50),
    email         VARCHAR(100),
    country       VARCHAR(50),
    created_at    VARCHAR(30)   -- stocké en VARCHAR pour simuler des données brutes "sales"
);

INSERT INTO raw.customers (id, first_name, last_name, email, country, created_at) VALUES
    (1,  'Alice',   'Martin',    'alice.martin@email.com',    'France',    '2023-01-15'),
    (2,  'Bob',     'Dupont',    'bob.dupont@email.com',      'France',    '2023-02-20'),
    (3,  'Claire',  'Lemoine',   'claire.lemoine@email.com',  'Belgique',  '2023-03-05'),
    (4,  'David',   'Bernard',   'david.bernard@email.com',   'Suisse',    '2023-03-18'),
    (5,  'Emma',    'Petit',     'emma.petit@email.com',      'France',    '2023-04-02'),
    (6,  'François','Moreau',    'f.moreau@email.com',        'France',    '2023-04-25'),
    (7,  'Gaëlle',  'Simon',     'gaelle.simon@email.com',    'Belgique',  '2023-05-10'),
    (8,  'Hugo',    'Laurent',   'hugo.laurent@email.com',    'France',    '2023-06-01'),
    (9,  'Inès',    'Lefebvre',  'ines.lefebvre@email.com',   'Suisse',    '2023-07-14'),
    (10, 'Jules',   'Girard',    'jules.girard@email.com',    'France',    '2023-08-30'),
    (11, 'Karine',  'Dubois',    NULL,                        'France',    '2023-09-12'),  -- email manquant
    (12, 'Luc',     'Thomas',    'luc.thomas@email.com',      NULL,        '2023-10-05'); -- pays manquant

-- ─── Table products ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS raw.products (
    id            INTEGER,
    name          VARCHAR(100),
    category      VARCHAR(50),
    unit_price    VARCHAR(20),  -- VARCHAR pour simuler des données brutes
    is_active     VARCHAR(5)    -- 'true'/'false' en texte
);

INSERT INTO raw.products (id, name, category, unit_price, is_active) VALUES
    (1,  'Laptop Pro 15"',     'Informatique',  '1299.99',  'true'),
    (2,  'Souris sans fil',    'Informatique',  '29.99',    'true'),
    (3,  'Clavier mécanique',  'Informatique',  '89.99',    'true'),
    (4,  'Écran 27" 4K',       'Informatique',  '499.99',   'true'),
    (5,  'Casque audio',       'Audio',         '149.99',   'true'),
    (6,  'Webcam HD',          'Informatique',  '79.99',    'false'),
    (7,  'Disque SSD 1To',     'Stockage',      '109.99',   'true'),
    (8,  'Hub USB-C',          'Accessoires',   '49.99',    'true'),
    (9,  'Tapis de souris XL', 'Accessoires',   '19.99',    'true'),
    (10, 'Lampe de bureau LED','Bureautique',   '39.99',    'true');

-- ─── Table orders ─────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS raw.orders (
    id            INTEGER,
    customer_id   INTEGER,
    product_id    INTEGER,
    quantity      INTEGER,
    unit_price    VARCHAR(20),  -- prix au moment de la commande (peut différer du catalogue)
    status        VARCHAR(20),
    ordered_at    VARCHAR(30)
);

INSERT INTO raw.orders (id, customer_id, product_id, quantity, unit_price, status, ordered_at) VALUES
    (1,  1,  1,  1, '1299.99', 'completed', '2023-02-10'),
    (2,  1,  2,  2, '29.99',   'completed', '2023-02-10'),
    (3,  2,  3,  1, '89.99',   'completed', '2023-03-01'),
    (4,  3,  5,  1, '149.99',  'completed', '2023-03-20'),
    (5,  4,  4,  2, '499.99',  'completed', '2023-04-05'),
    (6,  5,  7,  3, '109.99',  'completed', '2023-04-15'),
    (7,  6,  8,  1, '49.99',   'completed', '2023-05-02'),
    (8,  7,  9,  2, '19.99',   'shipped',   '2023-05-20'),
    (9,  8,  1,  1, '1299.99', 'shipped',   '2023-06-10'),
    (10, 9,  2,  1, '29.99',   'completed', '2023-06-25'),
    (11, 10, 10, 2, '39.99',   'completed', '2023-07-01'),
    (12, 11, 3,  1, '89.99',   'pending',   '2023-07-15'),
    (13, 1,  4,  1, '499.99',  'completed', '2023-08-05'),
    (14, 2,  7,  2, '109.99',  'completed', '2023-08-20'),
    (15, 5,  5,  1, '149.99',  'cancelled', '2023-09-01'),
    (16, 3,  8,  3, '49.99',   'completed', '2023-09-10'),
    (17, 6,  2,  4, '29.99',   'completed', '2023-10-01'),
    (18, 7,  1,  1, '1199.99', 'shipped',   '2023-10-15'), -- prix différent (promo)
    (19, 8,  9,  1, '19.99',   'pending',   '2023-11-01'),
    (20, 10, 4,  1, '499.99',  'completed', '2023-11-20');
