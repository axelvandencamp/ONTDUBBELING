﻿--=================================================================
--WERKWIJZE:
-- eerst upload file klaarmaken met enkel de kolommen zoals in de [AV_temp_BpostMyMove] tabel
-- vervolgens conversie uitvoeren naar UTF-8 .txt
--=================================================================
--CREATE TEMP TABLE
/*
DROP TABLE IF EXISTS _AV_temp_algemeen;

CREATE TABLE _AV_temp_algemeen 
(bron_id NUMERIC,
 Voornaam TEXT,
 Naam TEXT,
 Straatnaam TEXT,
 Huisnummer TEXT,
 Bus TEXT,
 Postcode TEXT,
 Gemeente TEXT,
 Telefoonnummer TEXT,
 emailadres TEXT
);

SELECT * FROM _AV_temp_algemeen WHERE bron_id = 4778;
*/
--DROP TABLE _AV_temp_algemeen;
--=================================================================
--IMPORT van .csv gelopen
--=================================================================

--=================================================================

--=========================================================
--SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work + x.check_lidnummer) controle
SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
FROM (
	SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
		p.email, p.email_work, bron.email bron_email, 
		p.street, RTRIM(LTRIM(bron.straatnaam)) bron_straat, 
		cc.name gemeente, RTRIM(LTRIM(bron.gemeente)) bron_gemeente, cc.zip postcode, RTRIM(LTRIM(bron.postcode)) bron_postcode,
		p.membership_nbr,
		CASE
			WHEN p.inactive_id IN (1,8) THEN 'dubbel (via website)' ELSE ''
		END inactieve_dubbel,
		CASE
			WHEN p.inactive_id IN (1,8) THEN p.active_partner_id ELSE 0
		END actieve_partner_id,
		p3.membership_state,
		p.active, p.deceased, p.membership_state status, 
		p2.display_name, p2.membership_state,
		CASE WHEN COALESCE(p.opt_out,'f') = 'f' THEN 'JA' WHEN p.opt_out = 't' THEN 'NEEN' ELSE 'JA' END email_ontvangen,
		CASE WHEN COALESCE(p.opt_out_letter,'f') = 'f' THEN 'JA' WHEN p.opt_out_letter = 't' THEN 'NEEN' ELSE 'JA' END post_ontvangen,
		similarity(p.name,bron.Voornaam || ' ' || bron.naam) sim_naam,
		similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner
		similarity(ccs.name,bron.straatnaam) sim_straat,
		--
		CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
		CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
		CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
		CASE WHEN RTRIM(LTRIM(LOWER(ccs.name))) = RTRIM(LTRIM(LOWER(bron.straatnaam))) THEN 1 ELSE 0 END check_straat,
		CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
		--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
	FROM _AV_temp_algemeen bron, res_partner p
		--JOIN res_partner p ON p.email = bb.email
		JOIN res_country c ON p.country_id = c.id
		JOIN res_country_city_street ccs ON p.street_id = ccs.id
		JOIN res_country_city cc ON p.zip_id = cc.id
		--gegevens van eventuele partner
		LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
		LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
		LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id
	--email
	WHERE RTRIM(LTRIM(LOWER(p.email))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
	--WHERE RTRIM(LTRIM(LOWER(p.email_work))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
	--volledige naam
	--WHERE RTRIM(LTRIM(LOWER(p.name))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) = '' THEN 'dummy bron' ELSE RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) END
	--adres
	--WHERE RTRIM(LTRIM(LOWER(ccs.name))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.straatnaam))) = '' THEN 'dummy bron' ELSE RTRIM(LTRIM(LOWER(bron.straatnaam))) END
	--lidnr
	--WHERE RTRIM(LTRIM(LOWER(p.membership_nbr::text))) = RTRIM(LTRIM(LOWER(bron.membership_number)))
	) x


------------------
--ccs.name = straatnaam zonder huisnummer	
--p.street = straatnaam met huisnummer
------------------


	


