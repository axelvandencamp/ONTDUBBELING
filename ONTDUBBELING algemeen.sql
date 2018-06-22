--=================================================================
--OPMERKING:
-- procedure omvormen: altijd met eenzelfde formaat werken, met lege kolommen indien geen data beschikbaar
-- resultaat met scores moet naar temp tabel: vervolgens groepering op "bron_id" met een MAX op score en/of "sim_naam"/"sim_straat"
--WERKWIJZE:
-- eerst upload file klaarmaken met enkel de kolommen zoals in de [AV_temp_BpostMyMove] tabel
-- vervolgens conversie uitvoeren naar UTF-8 .txt
--=================================================================
--CREATE TEMP TABLE
/*
DROP TABLE IF EXISTS _AV_temp_algemeen;

CREATE TABLE _AV_temp_algemeen 
(bron_id NUMERIC,
 naam TEXT,
 voornaam TEXT,
 straat TEXT,
 nummer TEXT,
 postcode TEXT,
 gemeente TEXT,
 email TEXT
);

SELECT * FROM _AV_temp_algemeen WHERE lower(naam) = 'daniels'
*/
--DROP TABLE _AV_temp_algemeen;
--=================================================================
--IMPORT van .csv gelopen
--=================================================================


-- 'OUDE' manuele procedure in comment
--=================================================================
/*
DROP TABLE IF EXISTS myvar;
SELECT 
	'adres'::text AS vergelijk -- (email, email_work, naam, adres, lidnummer)
INTO TEMP TABLE myvar;
SELECT * FROM myvar;
*/
--=========================================================
--SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work + x.check_lidnummer) controle
/*
SELECT *
FROM	(
	SELECT y.*, 
	CASE 
	WHEN v.vergelijk = 'email' THEN ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_email DESC)
	WHEN v.vergelijk = 'email_work' THEN ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_emailwerk DESC)
	WHEN v.vergelijk = 'naam' THEN ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_straat DESC) 
	WHEN v.vergelijk = 'adres' THEN ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_naam DESC)
	END AS r
	FROM	myvar v, 
		(
		SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
		FROM (
			SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
				p.email, p.email_work, bron.email bron_email, 
				--NULL email_work,
				p.street, RTRIM(LTRIM(bron.straat)) bron_straat, 
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
				similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner,
				similarity(ccs.name,bron.straat) sim_straat,
				similarity(COALESCE(p.email,'_'),bron.email) sim_email,
				similarity(COALESCE(p.email_work,'_'),bron.email) sim_emailwerk,
				--
				CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
				--CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
				--CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
				0 check_email, 0 check_email_work,
				CASE WHEN RTRIM(LTRIM(LOWER(ccs.name))) = RTRIM(LTRIM(LOWER(bron.straat))) THEN 1 ELSE 0 END check_straat,
				CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
				--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
			FROM _AV_temp_algemeen bron, myvar v, res_partner p
				--JOIN res_partner p ON p.email = bb.email
				JOIN res_country c ON p.country_id = c.id
				JOIN res_country_city_street ccs ON p.street_id = ccs.id
				JOIN res_country_city cc ON p.zip_id = cc.id
				--gegevens van eventuele partner
				LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
				LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
				LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id	
			--email
			--WHERE RTRIM(LTRIM(LOWER(p.email))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
			--WHERE RTRIM(LTRIM(LOWER(p.email_work))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
			--volledige naam
			--WHERE RTRIM(LTRIM(LOWER(p.name))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) = '' THEN 'dummy bron' ELSE RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) END
			--adres
			--WHERE RTRIM(LTRIM(LOWER(ccs.name)))||cc.zip = CASE WHEN RTRIM(LTRIM(LOWER(bron.straat))) = '' THEN 'dummy bron' ELSE RTRIM(LTRIM(LOWER(bron.straat)))||bron.postcode END
			--lidnr
			--WHERE RTRIM(LTRIM(LOWER(p.membership_nbr::text))) = RTRIM(LTRIM(LOWER(bron.membership_number)))
			--
			) x
		) y
	--WHERE bron_id = 43
	ORDER BY bron_id--, controle, sim_naam DESC	
	) z
WHERE r = 1
*/	
------------------
--ccs.name = straatnaam zonder huisnummer	
--p.street = straatnaam met huisnummer
------------------
-------------------------------------------------
--aanmaken temptabel voor 'automatische' controle
-------------------------------------------------
DROP TABLE IF EXISTS _AV_temp_controletabel;

CREATE TABLE _AV_temp_controletabel
(bron_id NUMERIC,
 id NUMERIC,
 first_name TEXT,
 last_name TEXT,
 bron_naam TEXT,
 email TEXT,
 email_work TEXT,
 bron_email TEXT,
 street TEXT,
 bron_straat TEXT,
 gemeente TEXT,
 bron_gemeente TEXT,
 postcode TEXT,
 bron_postcode TEXT,
 lidnummer TEXT,
 inactieve_dubbel TEXT,
 actieve_partner_id NUMERIC,
 status_dubbel TEXT,
 active TEXT,
 deceased TEXT,
 status TEXT,
 partner TEXT,
 status_partner TEXT,
 mail_ontvangen TEXT,
 post_ontvangen TEXT,
 sim_naam NUMERIC,
 sim_partner NUMERIC,
 sim_straat NUMERIC,
 sim_email NUMERIC,
 sim_emailwerk NUMERIC,
 check_naam NUMERIC,
 check_email NUMERIC,
 check_email_work NUMERIC,
 check_straat NUMERIC,
 check_postcode NUMERIC,
 controle NUMERIC,
 r NUMERIC,
 type_controle TEXT,
 lid NUMERIC
);

SELECT * FROM _AV_temp_controletabel;
--------------------------------------------------
-- controle op basis van email
--------------------------------------------------
INSERT INTO _AV_temp_controletabel (
	SELECT *, 'email' AS type_controle, 1 AS lid
	FROM	(
		SELECT y.*, 
		ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_email DESC) AS r
		FROM	myvar v, 
			(
			SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
			FROM (
				SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
					p.email, p.email_work, bron.email bron_email, 
					--NULL email_work,
					p.street, RTRIM(LTRIM(bron.straat)) bron_straat, 
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
					similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner,
					similarity(p.street,bron.straat) sim_straat,
					similarity(COALESCE(p.email,'_'),bron.email) sim_email,
					similarity(COALESCE(p.email_work,'_'),bron.email) sim_emailwerk,
					--
					CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
					--0 check_email, 0 check_email_work,
					CASE WHEN RTRIM(LTRIM(LOWER(p.street))) = RTRIM(LTRIM(LOWER(bron.straat))) THEN 1 ELSE 0 END check_straat,
					CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
					--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
				FROM _AV_temp_algemeen bron, myvar v, res_partner p
					--JOIN res_partner p ON p.email = bb.email
					JOIN res_country c ON p.country_id = c.id
					JOIN res_country_city_street ccs ON p.street_id = ccs.id
					JOIN res_country_city cc ON p.zip_id = cc.id
					--gegevens van eventuele partner
					LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
					LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
					LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id	
				WHERE RTRIM(LTRIM(LOWER(p.email))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
				--*/
				) x
			) y
		ORDER BY bron_id--, controle, sim_naam DESC	
		) z
	WHERE r = 1);
--------------------------------------------------
-- controle op basis van EMAIL_WERK
--------------------------------------------------
INSERT INTO _AV_temp_controletabel (
	SELECT *, 'email_werk' AS type_controle, 1 AS lid
	FROM	(
		SELECT y.*, 
		ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_emailwerk DESC) AS r
		FROM	myvar v, 
			(
			SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
			FROM (
				SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
					p.email, p.email_work, bron.email bron_email, 
					--NULL email_work,
					p.street, RTRIM(LTRIM(bron.straat)) bron_straat, 
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
					similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner,
					similarity(p.street,bron.straat) sim_straat,
					similarity(COALESCE(p.email,'_'),bron.email) sim_email,
					similarity(COALESCE(p.email_work,'_'),bron.email) sim_emailwerk,
					--
					CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
					--0 check_email, 0 check_email_work,
					CASE WHEN RTRIM(LTRIM(LOWER(p.street))) = RTRIM(LTRIM(LOWER(bron.straat))) THEN 1 ELSE 0 END check_straat,
					CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
					--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
				FROM _AV_temp_algemeen bron, myvar v, res_partner p
					--JOIN res_partner p ON p.email = bb.email
					JOIN res_country c ON p.country_id = c.id
					JOIN res_country_city_street ccs ON p.street_id = ccs.id
					JOIN res_country_city cc ON p.zip_id = cc.id
					--gegevens van eventuele partner
					LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
					LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
					LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id	
				WHERE RTRIM(LTRIM(LOWER(p.email_work))) = CASE WHEN RTRIM(LTRIM(LOWER(bron.email))) = '' THEN 'bron@email.com' ELSE RTRIM(LTRIM(LOWER(bron.email))) END 
				--*/
				) x
			) y
		ORDER BY bron_id--, controle, sim_naam DESC	
		) z
	WHERE r = 1);
--------------------------------------------------
-- controle op basis van NAAM
--------------------------------------------------
INSERT INTO _AV_temp_controletabel (
	SELECT *, 'naam' AS type_controle, 0 AS lid
	FROM	(
		SELECT y.*, 
		ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_straat DESC) AS r
		FROM	myvar v, 
			(
			SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
			FROM (
				SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
					p.email, p.email_work, bron.email bron_email, 
					--NULL email_work,
					p.street, RTRIM(LTRIM(bron.straat)) bron_straat, 
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
					similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner,
					similarity(p.street,bron.straat) sim_straat,
					similarity(COALESCE(p.email,'_'),bron.email) sim_email,
					similarity(COALESCE(p.email_work,'_'),bron.email) sim_emailwerk,
					--
					CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
					--0 check_email, 0 check_email_work,
					CASE WHEN RTRIM(LTRIM(LOWER(p.street))) = RTRIM(LTRIM(LOWER(bron.straat))) THEN 1 ELSE 0 END check_straat,
					CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
					--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
				FROM _AV_temp_algemeen bron, myvar v, res_partner p
					--JOIN res_partner p ON p.email = bb.email
					JOIN res_country c ON p.country_id = c.id
					JOIN res_country_city_street ccs ON p.street_id = ccs.id
					JOIN res_country_city cc ON p.zip_id = cc.id
					--gegevens van eventuele partner
					LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
					LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
					LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id	
				WHERE RTRIM(LTRIM(LOWER(p.name))) = CASE 
									WHEN RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) = '' 
									THEN 'dummy bron' 
									ELSE RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) END
				--*/
				) x
			) y
		ORDER BY bron_id--, controle, sim_naam DESC	
		) z
	WHERE r = 1);	
--------------------------------------------------
-- controle op basis van ADRES
--------------------------------------------------
INSERT INTO _AV_temp_controletabel (
	SELECT *, 'adres' AS type_controle, 0 AS lid
	FROM	(
		SELECT y.*, 
		ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_naam DESC) AS r
		FROM	myvar v, 
			(
			SELECT x.*, (x.check_naam + x.check_straat + x.check_postcode + x.check_email + x.check_email_work) controle
			FROM (
				SELECT bron.bron_id bron_id, p.id, p.first_name, p.last_name, RTRIM(LTRIM(bron.Voornaam)) || ' ' || RTRIM(LTRIM(bron.naam)) bron_naam, 
					p.email, p.email_work, bron.email bron_email, 
					--NULL email_work,
					p.street, RTRIM(LTRIM(bron.straat)) bron_straat, 
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
					similarity(p2.name,bron.Voornaam || ' ' || bron.naam) sim_partner,
					similarity(p.street,bron.straat) sim_straat,
					similarity(COALESCE(p.email,'_'),bron.email) sim_email,
					similarity(COALESCE(p.email_work,'_'),bron.email) sim_emailwerk,
					--
					CASE WHEN RTRIM(LTRIM(LOWER(p.name))) = RTRIM(LTRIM(LOWER(bron.Voornaam || ' ' || bron.naam))) THEN 1 ELSE 0 END check_naam,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email,
					CASE WHEN RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email))) THEN 1 ELSE 0 END check_email_work,
					--0 check_email, 0 check_email_work,
					CASE WHEN RTRIM(LTRIM(LOWER(p.street))) = RTRIM(LTRIM(LOWER(bron.straat))) THEN 1 ELSE 0 END check_straat,
					CASE WHEN RTRIM(LTRIM(cc.zip)) = RTRIM(LTRIM(bron.postcode)) THEN 1 ELSE 0 END check_postcode--,
					--CASE WHEN RTRIM(LTRIM(p.membership_nbr::text)) = RTRIM(LTRIM(bron.membership_number)) THEN 1 ELSE 0 END check_lidnummer
				FROM _AV_temp_algemeen bron, myvar v, res_partner p
					--JOIN res_partner p ON p.email = bb.email
					JOIN res_country c ON p.country_id = c.id
					JOIN res_country_city_street ccs ON p.street_id = ccs.id
					JOIN res_country_city cc ON p.zip_id = cc.id
					--gegevens van eventuele partner
					LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
					LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
					LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id	
				WHERE RTRIM(LTRIM(LOWER(p.street)))||cc.zip = CASE 
										WHEN RTRIM(LTRIM(LOWER(bron.straat))) = '' 
										THEN 'dummy bron' 
										ELSE RTRIM(LTRIM(LOWER(bron.straat)))||bron.postcode END
				--*/
				) x
			) y
		ORDER BY bron_id--, controle, sim_naam DESC	
		) z
	WHERE r = 1);
---------------------------------------------------
/*
SELECT * FROM _AV_temp_controletabel WHERE lid = 1 --THEN 1
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle > 3 --THEN 1 
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_naam = 1 AND check_postcode = 1 AND check_straat = 1 --THEN 1
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_naam = 1 AND check_postcode = 1 AND sim_straat >= 0.4 --THEN 1
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND check_naam = 1 --THEN 1
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_naam >= 0.4 --THEN 1
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_naam BETWEEN 0.2 AND 0.4 --THEN 2
SELECT * FROM _AV_temp_controletabel WHERE lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_partner >= 0.4 --THEN 1
*/
---------------------------------------------------
-- SELECT * FROM _AV_temp_controletabel
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 1 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle > 3 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_naam = 1 AND check_postcode = 1 AND check_straat = 1 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_naam = 1 AND check_postcode = 1 AND sim_straat >= 0.4 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND check_naam = 1 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_naam >= 0.4 THEN 1 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_naam BETWEEN 0.2 AND 0.4 THEN 2 ELSE lid END;
UPDATE _AV_temp_controletabel
SET lid = CASE WHEN lid = 0 AND controle <= 3 AND check_straat = 1 AND check_postcode = 1 AND sim_partner >= 0.4 THEN 1 ELSE lid END;

--volledige selectie ter controle logica procedure
SELECT * FROM
	(SELECT *, ROW_NUMBER() OVER (PARTITION BY bron_id ORDER BY controle DESC, sim_naam DESC) r2
	FROM _AV_temp_controletabel 
	WHERE lid > 0) SQ1
WHERE SQ1.r2 = 1
--AND id = 17156
--WHERE bron_id = 188 --17156
--DISTINCT selectie voor gebruik ontdubbeling bron document
