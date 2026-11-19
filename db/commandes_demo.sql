-- Commandes de DÉMONSTRATION pour l'espace du gérant : 10 commandes, noms fictifs, sur les 7 derniers jours.
-- Passées par passer_commande() (prix, frais et stock calculés par la base), puis datées et avancées
-- dans le circuit pour montrer chaque statut (et une rupture : le coffret de l'Aïd). Aucune n'est une vraie vente.
do $$
declare
  c record;
  v_num text;
begin
  for c in select * from (values
    -- jours en arrière, heure, panier, zone, code, nom, téléphone, adresse, statut final
    (6, 10, '[{"produit_id":8,"quantite":1},{"produit_id":9,"quantite":1}]', 3, null, 'Hind Lahlou', '0661203040', '22 derb Sidi Bouloukat, Médina, Marrakech', 'livree'),
    (5, 16, '[{"produit_id":1,"quantite":2}]', 2, 'BIENVENUE10', 'Omar Benjelloun', '0677889900', '7 rue Patrice Lumumba, Rabat', 'livree'),
    (4, 11, '[{"produit_id":17,"quantite":1},{"produit_id":18,"quantite":2}]', 1, null, 'Leïla Chraibi', '0612998877', '45 boulevard d''Anfa, Casablanca', 'livree'),
    (3, 19, '[{"produit_id":13,"quantite":1}]', 5, null, 'Rachid Alaoui', '0655443322', '3 talaa Kebira, Fès', 'annulee'),
    (2, 9,  '[{"produit_id":21,"quantite":1},{"produit_id":5,"quantite":2}]', 4, 'AID50', 'Samira Idrissi', '0699001122', '18 rue de la Liberté, Tanger', 'expediee'),
    (1, 14, '[{"produit_id":3,"quantite":3},{"produit_id":4,"quantite":1}]', 1, null, 'Mehdi Tazi', '0623456789', '9 rue Ibnou Mounir, Maârif, Casablanca', 'expediee'),
    (1, 20, '[{"produit_id":15,"quantite":1}]', 6, null, 'Zineb Ouazzani', '0645678901', '12 avenue Hassan Ier, Agadir', 'confirmee'),
    -- la dernière pièce du coffret de l'Aïd part : la réserve montre une rupture
    (1, 17, '[{"produit_id":24,"quantite":1}]', 1, null, 'Ilham Sebti', '0688776655', '14 rue Jean Jaurès, Gauthier, Casablanca', 'confirmee'),
    (0, 8,  '[{"produit_id":10,"quantite":1},{"produit_id":6,"quantite":2}]', 1, null, 'Karim Bennis', '0634567812', '5 rue Moulay Youssef, Casablanca', 'recue'),
    (0, 11, '[{"produit_id":19,"quantite":1},{"produit_id":11,"quantite":3}]', 7, null, 'Nawal Berrada', '0678123456', '27 hay Al Qods, Béni Mellal', 'recue')
  ) v(jours, heure, panier, zone, code, nom, tel, adresse, statut)
  loop
    v_num := passer_commande(c.panier::jsonb, c.zone, c.code, c.nom, c.tel, c.adresse)->>'numero';
    update commandes set
      cree_le = (date_trunc('day', now() at time zone 'Africa/Casablanca') - make_interval(days => c.jours)
                 + make_interval(hours => c.heure)) at time zone 'Africa/Casablanca',
      statut = c.statut
    where numero = v_num;
    -- le numéro porte la date de la commande, comme s'il avait été attribué ce jour-là
    update commandes set numero = 'DH-' || to_char(cree_le at time zone 'Africa/Casablanca', 'YYMMDD') || substr(numero, 10)
    where numero = v_num returning numero into v_num;
    if c.statut = 'annulee' then   -- la marchandise revient en rayon
      update produits p set stock = p.stock + l.quantite
      from lignes_commande l join commandes k on k.id = l.commande_id
      where k.numero = v_num and p.id = l.produit_id;
    end if;
  end loop;
end $$;
