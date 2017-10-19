--=================================================================
--WERKWIJZE:
-- eerst upload file klaarmaken met enkel de kolommen zoals in de [AV_temp_BpostMyMove] tabel
-- vervolgens conversie uitvoeren naar UTF-8 .txt
--=================================================================
--CREATE TEMP TABLE
/*
DROP TABLE IF EXISTS _AV_temp_eMail;

CREATE TABLE _AV_temp_eMail 
--lijst "emaillijst tbv Natuurpunt per 13-10-2015.xls"
(
 bronid TEXT,
 voornaam TEXT,
 naam TEXT,
 Email TEXT,
 created_at TEXT
);

SELECT * FROM _AV_temp_eMail;
*/
--DROP TABLE _AV_temp_eMail_CeraWandelingen;
--=================================================================
--IMPORT van .csv gelopen
--=================================================================

--=================================================================

--=========================================================
SELECT DISTINCT bron.bronid bron_id, bron.email, 
	p.membership_start start_datum, p.id, p.membership_nbr lidnummer, p.name, p.email, p.email_work, p.membership_state, p.active,
	p2.display_name partner, p2.membership_state partner_status, 
	CASE
		WHEN p.inactive_id IN (1,8) THEN 'dubbel (via website)' ELSE ''
	END inactieve_dubbel,
	CASE
		WHEN p.inactive_id IN (1,8) THEN p.active_partner_id ELSE 0
	END actieve_partner_id,
	p3.membership_state
FROM _AV_temp_eMail bron
	JOIN res_partner p ON RTRIM(LTRIM(LOWER(p.email))) = RTRIM(LTRIM(LOWER(bron.email))) --OR RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email)))
	--JOIN res_partner p ON p.membership_nbr = bron.lidnummer
	--gegevens van eventuele partner
	LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
	LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
	LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id
UNION
SELECT DISTINCT bron.bronid bron_id, bron.email, 
	p.membership_start start_datum, p.id, p.membership_nbr lidnummer, p.name, p.email, p.email_work, p.membership_state, p.active,
	p2.display_name partner, p2.membership_state partner_status, 
	CASE
		WHEN p.inactive_id IN (1,8) THEN 'dubbel (via website)' ELSE ''
	END inactieve_dubbel,
	CASE
		WHEN p.inactive_id IN (1,8) THEN p.active_partner_id ELSE 0
	END actieve_partner_id,
	p3.membership_state
FROM _AV_temp_eMail bron
	JOIN res_partner p ON RTRIM(LTRIM(LOWER(p.email_work))) = RTRIM(LTRIM(LOWER(bron.email)))
	--gegevens van eventuele partner
	LEFT OUTER JOIN res_partner p2 ON p.relation_partner_id = p2.id
	LEFT OUTER JOIN partner_inactive pi ON p.inactive_id = pi.id
	LEFT OUTER JOIN res_partner p3 ON p.active_partner_id = p3.id

	



--SELECT * FROM res_partner LIMIT 100	
--SELECT * FROM res_country_city_street LIMIT 100
	
	


