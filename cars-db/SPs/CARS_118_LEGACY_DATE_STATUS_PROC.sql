DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_118_LEGACY_DATE_STATUS_PROC(IN i_period_id INTEGER,IN i_entity_id TEXT)
BEGIN
DECLARE v_sql TEXT DEFAULT NULL ; 
DECLARE v_entities TEXT DEFAULT NULL;
DECLARE v_period_desc INTEGER DEFAULT NULL;
DECLARE v_ph_quest_id INTEGER DEFAULT NULL;
DECLARE v_pn_quest_id INTEGER DEFAULT NULL;
DECLARE v_ms_quest_id INTEGER DEFAULT NULL;


	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_LEGACY_DATE_STATUS_PROC');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_LEGACY_DATE_STATUS_PROC', 'Started', NOW());	
		
SELECT 
CAST(SUBSTR(PERIOD_DESC, 4,4) AS INTEGER) INTO v_period_desc
FROM CARS_PERIOD P
WHERE PERIOD_ID = i_period_id
;

IF i_entity_id IS NULL OR i_entity_id = '' 
THEN SET v_entities = ' ';
ELSE SET v_entities = CONCAT(' AND E.ENTITY_ID IN (', i_entity_id, ')');
END IF;

IF v_period_desc = 2014 THEN SET v_ph_quest_id = 10654; END IF;
IF v_period_desc = 2016 THEN SET v_ph_quest_id = 20980; END IF;
IF v_period_desc = 2019 THEN SET v_ph_quest_id = 41040; END IF;


IF v_period_desc = 2014 THEN SET v_pn_quest_id = 10651; END IF;
IF v_period_desc = 2016 THEN SET v_pn_quest_id = 20965; END IF;
IF v_period_desc = 2019 THEN SET v_pn_quest_id = 41070; END IF;


IF v_period_desc = 2014 THEN SET v_ms_quest_id = 13061; END IF;
IF v_period_desc = 2016 THEN SET v_ms_quest_id = 25140; END IF;
IF v_period_desc = 2019 THEN SET v_ms_quest_id = 49720; END IF;


CREATE OR REPLACE TEMPORARY TABLE PLAN_SUB
AS
SELECT  
A.STATE_NAME, 
B.STPLAN_CERT_DATE AS PLAN_SUB_DATE 
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF A
LEFT OUTER JOIN 
(
	SELECT STPLAN_STATE_CODE, STPLAN_CERT_DATE 
    FROM CARS_LEGACY_118_STPLAN_CERT_APRVL_STATUS  
    WHERE STPLAN_RESP_VERSION = '1'                  
    AND STPLAN_YEAR = v_period_desc
)B    
ON A.STATE_CODE = B.STPLAN_STATE_CODE
;


CREATE OR REPLACE TEMPORARY TABLE PUBLIC_HEARING 
AS
SELECT
A.STATE_NAME, 
trim(B.STPLAN_RESP_TEXT) AS PULIC_HEARING_DATE  
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF A
LEFT OUTER JOIN 
(
	SELECT STPLAN_STATE_CODE, STPLAN_RESP_TEXT
	FROM CARS_LEGACY_118_STPLAN_SECT_RESP 
	WHERE STPLAN_RESP_VERSION = '1'                  
	AND STPLAN_YEAR = v_period_desc
	AND STPLAN_SECT_QUEST_ID = v_ph_quest_id
)B    
ON A.STATE_CODE = B.STPLAN_STATE_CODE
;

CREATE OR REPLACE TEMPORARY TABLE PUBLIC_NOTICE
AS
SELECT 
A.STATE_NAME, 
trim(B.STPLAN_RESP_TEXT) AS PUBLIC_NOTICE_DATE 
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF A
LEFT OUTER JOIN 
(
	SELECT STPLAN_STATE_CODE, STPLAN_RESP_TEXT
    FROM CARS_LEGACY_118_STPLAN_SECT_RESP 
    WHERE STPLAN_RESP_VERSION = '1'                  
	AND STPLAN_YEAR = v_period_desc
    AND STPLAN_SECT_QUEST_ID = v_pn_quest_id
)B    
ON A.STATE_CODE = B.STPLAN_STATE_CODE
;

CREATE OR REPLACE TEMPORARY TABLE MARKET_SURVEY
AS
SELECT 
A.STATE_NAME, 
trim(B.STPLAN_RESP_TEXT) AS MARKET_SURVEY_DATE  
FROM CARS_LEGACY_118_STPLAN_STATE_INFO_REF A
LEFT OUTER JOIN 
(
	SELECT STPLAN_STATE_CODE, STPLAN_RESP_TEXT
    FROM CARS_LEGACY_118_STPLAN_SECT_RESP 
    WHERE STPLAN_RESP_VERSION = '1'                  
    AND STPLAN_YEAR = v_period_desc
    AND STPLAN_SECT_QUEST_ID = v_ms_quest_id
)B    
ON A.STATE_CODE = B.STPLAN_STATE_CODE
;

SET v_sql = 
'
SELECT
E.ENTITY_NAME AS ''State_Territory'',
R.ENTITY_NAME AS ''Region'',
R.ENTITY_ID AS ''REGION_ID'',
PS.PLAN_SUB_DATE AS ''Plan_Submission_Date'',
PH.PULIC_HEARING_DATE AS ''Date_of_Public_Hearing'',
PN.PUBLIC_NOTICE_DATE AS ''Date_of_Public_Notice_of_Public_Hearing'',
MS.MARKET_SURVEY_DATE AS ''Date_Market_Rate_Survey_Completed''

FROM CARS_MODULE_PERIOD_HDR H
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
AND E.ENTITY_TYPE_CD = ''STATE-TER''
entity_list
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = ''REGION''

LEFT OUTER JOIN PLAN_SUB PS
ON E.ENTITY_NAME = PS.STATE_NAME

LEFT OUTER JOIN PUBLIC_HEARING PH
ON E.ENTITY_NAME = PH.STATE_NAME

LEFT OUTER JOIN PUBLIC_NOTICE PN
ON E.ENTITY_NAME = PN.STATE_NAME

LEFT OUTER JOIN MARKET_SURVEY MS
ON E.ENTITY_NAME = MS.STATE_NAME


WHERE H.PERIOD_ID = replace_period
ORDER BY E.ENTITY_NAME
'
;

EXECUTE IMMEDIATE REPLACE(REPLACE(v_sql, 'entity_list', v_entities), 'replace_period', i_period_id);

IF v_period_desc = 2014 THEN

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region', 'Region_ID' AS 'Region_ID', 'Plan Submission Date' AS 'Plan_Submission_Date',
	   'Date of Public Hearing (no earlier than 1/1/2013)' AS 'Date_of_Public_Hearing',
	   'Date of Public Notice of Public Hearing (at least 20 days prior to public hearing)' AS 'Date_of_Public_Notice_of_Public_Hearing',
	   'Date Market Rate Survey Completed (no earlier than 10/2011)' AS 'Date_Market_Rate_Survey_Completed'
;
END IF;

IF v_period_desc = 2016 THEN

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region', 'Region_ID' AS 'Region_ID', 'Plan Submission Date' AS 'Plan_Submission_Date',
	   'Date of Public Hearing (no earlier than 9/1/2015)' AS 'Date_of_Public_Hearing',
	   'Date of Public Notice of Public Hearing (at least 20 days prior to public hearing)' AS 'Date_of_Public_Notice_of_Public_Hearing',
	   'Date Market Rate Survey Completed (no earlier than 7/1/2013 and no later than 3/1/2016)' AS 'Date_Market_Rate_Survey_Completed'
;

END IF;

IF v_period_desc = 2019 THEN

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region', 'Region_ID' AS 'Region_ID', 'Plan Submission Date' AS 'Plan_Submission_Date',
	   'Date of Public Hearing (no earlier than 1/1/2018)' AS 'Date_of_Public_Hearing',
	   'Date of Public Notice of Public Hearing (at least 20 days prior to public hearing)' AS 'Date_of_Public_Notice_of_Public_Hearing',
	   'Date Market Rate Survey Completed (no earlier than 7/1/2016 and no later than 7/1/2018)' AS 'Date_Market_Rate_Survey_Completed'
;
END IF;

UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_LEGACY_DATE_STATUS_PROC');
		
END$$
DELIMITER ;