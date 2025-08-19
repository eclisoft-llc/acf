DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_218_LEGACY_CERT_AND_ACCEPTANCE_SUMMARY_PROC(IN i_period_id INTEGER,IN i_entity_id TEXT)
BEGIN
DECLARE v_sql TEXT DEFAULT NULL ; 
DECLARE v_entities TEXT DEFAULT NULL;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_218_LEGACY_CERT_AND_ACCEPTANCE_SUMMARY_PROC');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_218_LEGACY_CERT_AND_ACCEPTANCE_SUMMARY_PROC', 'Started', NOW());	

IF TRIM(i_entity_id)!='' THEN

SELECT 
E.ENTITY_NAME AS 'State_Territory', 
R.ENTITY_NAME AS 'Region', 
R.ENTITY_ID AS 'REGION_ID',
A.QPR_AMDMT_DATE AS 'Initial_Certified_Date', 
NULL AS 'Initial_Recommend_for_Acceptance_Date',
NULL AS 'Final_Recommend_for_Acceptance_Date',
A.QPR_CERT_DATE AS 'Last_Certified_Date', 
A.QPR_APRVL_DATE AS 'Acceptance_Date'
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF S
JOIN CARS_ENTITY E
ON S.STATE_NAME = E.ENTITY_NAME
AND E.ENTITY_TYPE_CD = 'STATE-TER'
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
LEFT OUTER JOIN 
(
	SELECT A.QPR_STATE_CODE, A.QPR_AMDMT_DATE, A.QPR_CERT_DATE, A. QPR_APRVL_DATE, A.QPR_YEAR
	FROM CARS_LEGACY_218_QPR_CERT_APRVL_STATUS A
	JOIN CARS_PERIOD P
	ON A.QPR_YEAR = SUBSTR(P.PERIOD_DESC, 4, 4)
	AND P.PERIOD_ID = i_period_id
) A
ON S.STATE_CODE = A.QPR_STATE_CODE
WHERE E.ENTITY_ID IN ((select TRIM(j.name) AS ENTITY_ID
	from json_table(
	  replace(json_array(i_entity_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j))
ORDER BY E.ENTITY_NAME
;

	SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID', 'Initial Certified Date' AS 'Initial_Certified_Date',
	'Initial Recommend for Acceptance Date' AS 'Initial_Recommend_for_Acceptance_Date', 'Final Recommend for Acceptance Date' AS 'Final_Recommend_for_Acceptance_Date', 
	'Last Certified Date' AS 'Last_Certified_Date','Acceptance Date' AS 'Acceptance_Date';
	
ELSE

SELECT 
E.ENTITY_NAME AS 'State_Territory', 
R.ENTITY_NAME AS 'Region', 
R.ENTITY_ID AS 'REGION_ID',
A.QPR_AMDMT_DATE AS 'Initial_Certified_Date ', 
NULL AS 'Initial_Recommend_for_Acceptance_Date',
NULL AS 'Final_Recommend_for_Acceptance_Date',
A.QPR_CERT_DATE AS 'Last_Certified_Date ', 
A.QPR_APRVL_DATE AS 'Acceptance_Date'
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF S
JOIN CARS_ENTITY E
ON S.STATE_NAME = E.ENTITY_NAME
AND E.ENTITY_TYPE_CD = 'STATE-TER'
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
LEFT OUTER JOIN 
(
	SELECT A.QPR_STATE_CODE, A.QPR_AMDMT_DATE, A.QPR_CERT_DATE, A. QPR_APRVL_DATE, A.QPR_YEAR
	FROM CARS_LEGACY_218_QPR_CERT_APRVL_STATUS A
	JOIN CARS_PERIOD P
	ON A.QPR_YEAR = SUBSTR(P.PERIOD_DESC, 4, 4)
	AND P.PERIOD_ID = i_period_id
) A
ON S.STATE_CODE = A.QPR_STATE_CODE
ORDER BY E.ENTITY_NAME
;

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID', 'Initial Certified Date' AS 'Initial_Certified_Date',
	'Initial Recommend for Acceptance Date' AS 'Initial_Recommend_for_Acceptance_Date', 'Final Recommend for Acceptance Date' AS 'Final_Recommend_for_Acceptance_Date', 
	'Last Certified Date' AS 'Last_Certified_Date','Acceptance Date' AS 'Acceptance_Date';

END IF;


UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_218_LEGACY_CERT_AND_ACCEPTANCE_SUMMARY_PROC');
		
END$$
DELIMITER ;