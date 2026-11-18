-- Données de démonstration — boutique FICTIVE, prix et frais inventés pour la démo.
truncate lignes_commande, commandes, promos, zones, produits restart identity cascade;

insert into produits (slug, categorie, nom, prix_dh, stock) values
-- soins
('huile-argan-100',      'soins',    '{"fr":"Huile d''argan pure 100 ml","ar":"زيت الأركان الخالص 100 مل","en":"Pure argan oil 100 ml"}', 120, 40),
('huile-argan-50',       'soins',    '{"fr":"Huile d''argan pure 50 ml","ar":"زيت الأركان الخالص 50 مل","en":"Pure argan oil 50 ml"}', 70, 60),
('savon-noir-eucalyptus','soins',    '{"fr":"Savon noir à l''eucalyptus","ar":"الصابون البلدي بالكاليبتوس","en":"Eucalyptus black soap"}', 45, 80),
('ghassoul-250',         'soins',    '{"fr":"Ghassoul de l''Atlas 250 g","ar":"غاسول الأطلس 250 غ","en":"Atlas ghassoul clay 250 g"}', 35, 70),
('eau-de-rose',          'soins',    '{"fr":"Eau de rose de Kelâa M''Gouna","ar":"ماء الورد من قلعة مكونة","en":"Kelaa M''Gouna rose water"}', 50, 50),
('gant-kessa',           'soins',    '{"fr":"Gant kessa de hammam","ar":"كيس الحمام","en":"Hammam kessa glove"}', 25, 120),
-- thé
('the-vert-menthe',      'the',      '{"fr":"Thé vert gunpowder 250 g","ar":"شاي أخضر 250 غ","en":"Gunpowder green tea 250 g"}', 40, 90),
('theiere-argentee',     'the',      '{"fr":"Théière argentée gravée","ar":"براد فضي منقوش","en":"Engraved silver teapot"}', 260, 15),
('verres-beldi-6',       'the',      '{"fr":"6 verres à thé beldi","ar":"6 كؤوس شاي بلدية","en":"6 beldi tea glasses"}', 150, 25),
('plateau-cuivre',       'the',      '{"fr":"Plateau en cuivre martelé","ar":"صينية نحاسية مطروقة","en":"Hammered copper tray"}', 320, 10),
('melange-epices-the',   'the',      '{"fr":"Mélange d''herbes pour thé","ar":"خليط أعشاب الشاي","en":"Herbal tea blend"}', 30, 100),
-- poterie
('bol-safi-bleu',        'poterie',  '{"fr":"Bol de Safi bleu","ar":"زلافة آسفي زرقاء","en":"Blue Safi bowl"}', 90, 30),
('tajine-decoratif',     'poterie',  '{"fr":"Tajine décoratif peint main","ar":"طاجين مزخرف مرسوم باليد","en":"Hand-painted decorative tajine"}', 180, 12),
('assiette-fes',         'poterie',  '{"fr":"Assiette de Fès motif zellige","ar":"صحن فاسي بنقش الزليج","en":"Fez plate, zellige pattern"}', 140, 20),
('photophore-cuivre',    'poterie',  '{"fr":"Photophore ajouré en cuivre","ar":"فانوس نحاسي مخرم","en":"Pierced copper lantern"}', 210, 8),
-- textile
('babouches-cuir-jaune', 'textile',  '{"fr":"Babouches en cuir jaune","ar":"بلغة جلدية صفراء","en":"Yellow leather babouches"}', 160, 35),
('babouches-brodees',    'textile',  '{"fr":"Babouches brodées","ar":"بلغة مطرزة","en":"Embroidered babouches"}', 190, 25),
('fouta-hammam',         'textile',  '{"fr":"Fouta de hammam tissée","ar":"فوطة الحمام المنسوجة","en":"Woven hammam fouta"}', 85, 45),
('coussin-berbere',      'textile',  '{"fr":"Housse de coussin berbère","ar":"غطاء وسادة أمازيغي","en":"Berber cushion cover"}', 130, 18),
('sac-panier-osier',     'textile',  '{"fr":"Panier en osier et cuir","ar":"قفة من الدوم والجلد","en":"Wicker and leather basket"}', 110, 22),
-- coffrets
('coffret-hammam',       'coffrets', '{"fr":"Coffret hammam","ar":"علبة هدايا الحمام","en":"Hammam gift box"}', 220, 15),
('coffret-the',          'coffrets', '{"fr":"Coffret thé à la menthe","ar":"علبة هدايا الشاي بالنعناع","en":"Mint tea gift box"}', 290, 12),
('coffret-mariage',      'coffrets', '{"fr":"Coffret mariage","ar":"علبة هدايا العرس","en":"Wedding gift box"}', 450, 6),
('coffret-aid',          'coffrets', '{"fr":"Coffret de l''Aïd","ar":"علبة هدايا العيد","en":"Eid gift box"}', 350, 1);

insert into zones (ville, nom, frais_dh, delai, livraison_offerte_des) values
('casablanca', '{"fr":"Casablanca","ar":"الدار البيضاء","en":"Casablanca"}', 20, '24 h', 400),
('rabat',      '{"fr":"Rabat","ar":"الرباط","en":"Rabat"}',                  30, '24 à 48 h', 500),
('marrakech',  '{"fr":"Marrakech","ar":"مراكش","en":"Marrakech"}',           35, '48 h', 500),
('tanger',     '{"fr":"Tanger","ar":"طنجة","en":"Tangier"}',                  35, '48 h', 500),
('fes',        '{"fr":"Fès","ar":"فاس","en":"Fez"}',                           35, '48 h', 500),
('agadir',     '{"fr":"Agadir","ar":"أكادير","en":"Agadir"}',                 40, '2 à 3 jours', 600),
('autres',     '{"fr":"Autres villes","ar":"مدن أخرى","en":"Other cities"}',  45, '3 à 5 jours', null);

insert into promos (code, type, valeur, minimum_dh, fin) values
('BIENVENUE10', 'pourcent', 10, 0,   null),
('AID50',       'montant',  50, 300, null),
('ETE2026',     'pourcent', 15, 0,   '2026-09-01T00:00:00Z');   -- expiré : sert à montrer le refus
