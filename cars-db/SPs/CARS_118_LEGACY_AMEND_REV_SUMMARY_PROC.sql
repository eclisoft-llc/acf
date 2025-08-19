DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_118_LEGACY_AMEND_REV_SUMMARY_PROC(IN i_period_id INTEGER,IN i_entity_id TEXT)
BEGIN
DECLARE v_sql TEXT DEFAULT NULL ; 
DECLARE v_entities TEXT DEFAULT NULL;
DECLARE v_period_desc INTEGER DEFAULT NULL;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_LEGACY_AMEND_REV_SUMMARY_PROC');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_LEGACY_AMEND_REV_SUMMARY_PROC', 'Started', NOW());	

SELECT 
CAST(SUBSTR(PERIOD_DESC, 4,4) AS INTEGER) INTO v_period_desc
FROM CARS_PERIOD P
WHERE PERIOD_ID = i_period_id
;

IF i_entity_id IS NULL OR i_entity_id = '' 
THEN SET v_entities = ' ';
ELSE SET v_entities = CONCAT(' AND E.ENTITY_ID IN (', i_entity_id, ')');
END IF;

IF v_period_desc <> 2014 THEN

CREATE OR REPLACE TEMPORARY TABLE FQUERY
AS
SELECT
    state_name,
    stplan_state_code1,
    stplan_state_code2,
    stplan_resp_version,
    stplan_mod_summary,
    STPLAN_AMDMT_TEXT,
    STPLAN_AMDMT_TEXT2,
    STPLAN_AMDMT_TEXT3,
    STPLAN_AMDMT_TEXT4,
    stplan_year,
    amend_rev_ver1,
    amend_rev_ver2,
    stplan_type1,
    stplan_type2,
    stplan_status,
    STPLAN_RESP_VERSION_TYPE,
    stplan_cert_date,
    stplan_init_cert_date,
    stplan_aprvl_date,
    STPLAN_SEC_QUEST_NAME      
    
FROM      
(
SELECT DISTINCT
    ca.STPLAN_STATE_CODE,
    r.state_name,
    resp.stplan_state_code stplan_state_code1,
    ca.stplan_state_code stplan_state_code2,
    ca.stplan_resp_version,
    resp.stplan_mod_summary,
    substr(a.stplan_amdmt_text, 1, 4000) STPLAN_AMDMT_TEXT,
    substr(a.stplan_amdmt_text, 4001, 4000) STPLAN_AMDMT_TEXT2,
    substr(a.stplan_amdmt_text, 8002, 4000) STPLAN_AMDMT_TEXT3,
    substr(a.stplan_amdmt_text, 12003, 4000) STPLAN_AMDMT_TEXT4,
    ca.stplan_year,
    ca.amend_rev_ver amend_rev_ver1,
    ca.amend_rev_ver amend_rev_ver2,
    ca.stplan_type stplan_type1,
    ca.stplan_type stplan_type2,
    ca.stplan_type,
    ca.stplan_status,
    resp.STPLAN_RESP_VERSION_TYPE,
    ca.stplan_cert_date AS stplan_cert_date,
    ca.STPLAN_AMDMT_DATE AS stplan_init_cert_date,
    ca.stplan_aprvl_date AS stplan_aprvl_date,
	Q.STPLAN_SEC_QUEST_NAME
 
FROM
    CARS_LEGACY_118_STPLAN_CERT_APRVL_STATUS ca
	JOIN CARS_LEGACY_118_STPLAN_STATE_INFO_REF r
	ON ca.stplan_state_code = r.state_code
    JOIN CARS_LEGACY_118_STPLAN_SECT_RESP resp
	ON ca.stplan_resp_version = resp.stplan_resp_version
	AND ca.stplan_state_code = resp.stplan_state_code
	AND ca.stplan_year = resp.stplan_year 
	AND r.state_code = resp.stplan_state_code 
	AND resp.stplan_mod_summary IS NOT NULL
	JOIN (SELECT DISTINCT STPLAN_SECT_QUEST_ID, STPLAN_SEC_QUEST_NAME FROM CARS_LEGACY_118_STPLAN_SECT_QUEST) Q
	ON resp.stplan_sect_quest_id = Q.stplan_sect_quest_id
    LEFT OUTER JOIN CARS_LEGACY_118_STPLAN_AMDMT_SUMMARY a
	ON ca.stplan_info_id = a.stplan_info_id
    
WHERE 
ca.stplan_type <> 'O' 
AND ca.stplan_year = v_period_desc  
) A

;


CREATE OR REPLACE TEMPORARY TABLE SQUERY
AS
SELECT
    state_name,
    stplan_state_code1,
    stplan_state_code2,
    stplan_resp_version,
    stplan_mod_summary,
    STPLAN_AMDMT_TEXT,
    STPLAN_AMDMT_TEXT2,
    STPLAN_AMDMT_TEXT3,
    STPLAN_AMDMT_TEXT4,
    stplan_year,
    amend_rev_ver1,
    amend_rev_ver2,
    stplan_type1,
    stplan_type2,
    stplan_status,
    STPLAN_RESP_VERSION_TYPE,
    stplan_cert_date,
    stplan_init_cert_date,
    stplan_aprvl_date,
    STPLAN_SEC_QUEST_NAME      
    
FROM      
(
SELECT DISTINCT
    ca.STPLAN_STATE_CODE,
    r.state_name,
    resp.stplan_state_code stplan_state_code1,
    ca.stplan_state_code stplan_state_code2,
    ca.stplan_resp_version,
    resp.stplan_mod_summary,
    substr(a.stplan_amdmt_text, 1, 4000) STPLAN_AMDMT_TEXT,
    substr(a.stplan_amdmt_text, 4001, 4000) STPLAN_AMDMT_TEXT2,
    substr(a.stplan_amdmt_text, 8002, 4000) STPLAN_AMDMT_TEXT3,
    substr(a.stplan_amdmt_text, 12003, 4000) STPLAN_AMDMT_TEXT4,
    ca.stplan_year,
    ca.amend_rev_ver amend_rev_ver1,
    ca.amend_rev_ver amend_rev_ver2,
    ca.stplan_type stplan_type1,
    ca.stplan_type stplan_type2,
    ca.stplan_type,
    ca.stplan_status,
    resp.STPLAN_RESP_VERSION_TYPE,
    ca.stplan_cert_date AS stplan_cert_date,
    ca.STPLAN_AMDMT_DATE AS stplan_init_cert_date,
    ca.stplan_aprvl_date AS stplan_aprvl_date,
    NULL AS STPLAN_SEC_QUEST_NAME
FROM
    CARS_LEGACY_118_STPLAN_CERT_APRVL_STATUS ca
	JOIN CARS_LEGACY_118_STPLAN_STATE_INFO_REF r
	ON r.state_code = ca.stplan_state_code
    JOIN CARS_LEGACY_118_STPLAN_SECT_RESP resp
	ON ca.stplan_resp_version = resp.stplan_resp_version 
	AND ca.stplan_state_code = resp.stplan_state_code 
	AND ca.stplan_year = resp.stplan_year
	AND resp.stplan_state_code = r.state_code 
	AND resp.stplan_mod_summary IS NULL
    LEFT OUTER JOIN CARS_LEGACY_118_STPLAN_AMDMT_SUMMARY a
	ON ca.stplan_info_id = a.stplan_info_id
    
WHERE
ca.stplan_type <> 'O' 
AND ca.stplan_year = v_period_desc 
AND r.state_name NOT IN(
    SELECT DISTINCT
        r.state_name
    FROM
        CARS_LEGACY_118_STPLAN_CERT_APRVL_STATUS ca
		JOIN CARS_LEGACY_118_STPLAN_STATE_INFO_REF r
		ON r.state_code = ca.stplan_state_code
        JOIN CARS_LEGACY_118_STPLAN_SECT_RESP resp
		ON ca.stplan_year = resp.stplan_year
		AND ca.stplan_resp_version = resp.stplan_resp_version
		AND ca.stplan_state_code = resp.stplan_state_code
		AND resp.stplan_state_code = r.state_code
		AND resp.stplan_mod_summary IS NOT NULL
        LEFT OUTER JOIN CARS_LEGACY_118_STPLAN_AMDMT_SUMMARY a
        ON ca.stplan_info_id =  a.stplan_info_id       
    WHERE
        ca.stplan_type <> 'O' 
		AND ca.stplan_year = v_period_desc
	)
) A
;

CREATE OR REPLACE TEMPORARY TABLE UNION_RESULTS
AS
SELECT
    ROW_NUMBER() OVER(
    ORDER BY
        state_name,
        stplan_resp_version,
        STPLAN_SEC_QUEST_NAME
) AS RN,
state_name,
stplan_state_code1,
stplan_state_code2,
stplan_resp_version,
stplan_mod_summary,
STPLAN_AMDMT_TEXT,
STPLAN_AMDMT_TEXT2,
STPLAN_AMDMT_TEXT3,
STPLAN_AMDMT_TEXT4,
stplan_year,
amend_rev_ver1,
amend_rev_ver2,
stplan_type1,
stplan_type2,
stplan_status,
STPLAN_RESP_VERSION_TYPE,
stplan_cert_date,
stplan_init_cert_date,
stplan_aprvl_date,
STPLAN_SEC_QUEST_NAME
FROM
    (
		SELECT * FROM FQUERY
		UNION ALL 
		SELECT * FROM SQUERY
	) A
;

CREATE OR REPLACE TABLE FINAL_QUERY
AS
SELECT 
a.state_name,
/*
CASE WHEN
    a.stplan_state_code1 = b.stplan_state_code2 THEN ' ' ELSE a.state_name
END stplan_state_code1,
*/
a.state_name AS stplan_state_code1,
/*
CASE WHEN(
    (
        a.amend_rev_ver1 = b.amend_rev_ver2
    ) AND(
        a.stplan_type1 = b.stplan_type2
    ) AND(
        a.stplan_state_code1 = b.stplan_state_code2
    )
) THEN ' ' ELSE CASE WHEN a.stplan_type1 = 'a' THEN CONCAT('a #' , a.amend_rev_ver1)
 WHEN a.stplan_type1 = 'r' THEN CONCAT('r #', a.amend_rev_ver1)
 WHEN a.stplan_type1 = 'b' THEN CONCAT('a/r #', a.amend_rev_ver1)
END
END amend_rev_num,
*/
CASE WHEN a.stplan_type1 = 'a' THEN CONCAT('a #' , a.amend_rev_ver1)
 WHEN a.stplan_type1 = 'r' THEN CONCAT('r #', a.amend_rev_ver1)
 WHEN a.stplan_type1 = 'b' THEN CONCAT('a/r #', a.amend_rev_ver1)
END AS amend_rev_num,
/*
CASE WHEN(
    (
        a.amend_rev_ver1 = b.amend_rev_ver2
    ) AND(
        a.stplan_type1 = b.stplan_type2
    ) AND(
        a.stplan_state_code1 = b.stplan_state_code2
    )
) THEN ' ' ELSE a.STPLAN_AMDMT_TEXT
END STPLAN_AMDMT_TEXT,
*/
a.STPLAN_AMDMT_TEXT AS STPLAN_AMDMT_TEXT,

/*
CASE WHEN(
    (
        a.amend_rev_ver1 = b.amend_rev_ver2
    ) AND(
        a.stplan_type1 = b.stplan_type2
    ) AND(
        a.stplan_state_code1 = b.stplan_state_code2
    )
) THEN ' ' ELSE a.STPLAN_AMDMT_TEXT2
END STPLAN_AMDMT_TEXT2,
CASE WHEN(
    (
        a.amend_rev_ver1 = b.amend_rev_ver2
    ) AND(
        a.stplan_type1 = b.stplan_type2
    ) AND(
        a.stplan_state_code1 = b.stplan_state_code2
    )
) THEN ' ' ELSE a.STPLAN_AMDMT_TEXT3
END STPLAN_AMDMT_TEXT3,
CASE WHEN(
    (
        a.amend_rev_ver1 = b.amend_rev_ver2
    ) AND(
        a.stplan_type1 = b.stplan_type2
    ) AND(
        a.stplan_state_code1 = b.stplan_state_code2
    )
) THEN ' ' ELSE a.STPLAN_AMDMT_TEXT4
END STPLAN_AMDMT_TEXT4,
*/
a.STPLAN_SEC_QUEST_NAME,
a.STPLAN_RESP_VERSION_TYPE,
a.stplan_mod_summary,
a.stplan_init_cert_date,
a.stplan_cert_date,
a.stplan_aprvl_date
/*
a.stplan_type1 stplan_type,

a.stplan_resp_version,

a.stplan_year,
a.amend_rev_ver1 amend_rev_ver,

a.stplan_status
*/
FROM UNION_RESULTS a 
LEFT OUTER JOIN UNION_RESULTS b ON
    a.rn = b.rn + 1
ORDER BY
    a.rn,
    a.stplan_resp_version
;

SET v_sql = '
SELECT
stplan_state_code1 AS ''State_Territory'',
R.ENTITY_NAME AS ''Region'',
R.ENTITY_ID AS ''REGION_ID'',
amend_rev_num AS ''Amendment_Number'',
STPLAN_AMDMT_TEXT AS ''Summary_of_Plan_Amendment'',
CAST(F.STPLAN_SEC_QUEST_NAME AS VARCHAR(50)) AS ''Question_Amendend'',
STPLAN_RESP_VERSION_TYPE AS ''Mod_Type_*'',
stplan_mod_summary AS ''Summary_of_Question_Modification'',
stplan_init_cert_date AS ''Initial_Date_submitted_to_ACF'',
stplan_cert_date AS ''Final_Date_Submitted_to_ACF'',
stplan_aprvl_date AS ''Date_Approved_by_ACF''
FROM FINAL_QUERY F
JOIN CARS_ENTITY E
ON F.state_name = E.ENTITY_NAME
AND E.ENTITY_TYPE_CD = ''STATE-TER''
entity_list
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = ''REGION''
'
;

EXECUTE IMMEDIATE REPLACE(v_sql, 'entity_list', v_entities);

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region', 'Region_ID' AS 'Region_ID', 'Amendment Number' AS 'Amendment_Number', 'Summary of Plan Amendment' AS 'Summary_of_Plan_Amendment', 'Question Amended' AS 'Question_Amended', 'Mod Type *' AS 'Mod_Type_*', 'Summary of Question Modification' AS 'Summary_of_Question_Modification', 
'Initial Date submitted to ACF' AS 'Initial_Date_submitted_to_ACF', 'Final Date Submitted to ACF' AS 'Final_Date_Submitted_to_ACF', 'Date Approved by ACF' AS 'Date_Approved_by_ACF';

ELSE

SET v_sql = '
SELECT  
r.state_name AS ''State_Territory'', 
R.ENTITY_NAME AS ''Region'',
R.ENTITY_ID AS ''REGION_ID'',
c.stplan_type AS ''Type *'',
cast(c.stplan_resp_version - 1 AS INTEGER) AS ''Amendment_Revision_Number'',  
a.stplan_amdmt_text AS ''Summary_of_Amendment'', 
c.STPLAN_AMDMT_DATE as ''Initial_Date_Submitted_to_ACF'',
c.stplan_cert_date as ''Final_Date_Submitted_to_ACF'',      
c.stplan_aprvl_date as ''Date_Approved_by_ACF''

##a.stplan_amdmt_date as stplan_amdmt_date,     
                            
FROM CARS_ENTITY E
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = ''REGION''
JOIN CARS_LEGACY_118_STPLAN_STATE_INFO_REF r
ON E.ENTITY_NAME = r.state_name
LEFT OUTER JOIN CARS_LEGACY_118_STPLAN_CERT_APRVL_STATUS c
ON r.state_code = c.stplan_state_code
LEFT OUTER JOIN CARS_LEGACY_118_STPLAN_AMDMT_SUMMARY a    
ON c.stplan_info_id = a.stplan_info_id
WHERE E.ENTITY_TYPE_CD = ''STATE-TER''
AND c.STPLAN_TYPE <> ''O'' 
AND c.STPLAN_YEAR = replace_period
entity_list

ORDER BY r.state_name,c.stplan_resp_version
'
;

EXECUTE IMMEDIATE REPLACE(REPLACE(v_sql, 'entity_list', v_entities), 'replace_period', v_period_desc);

SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region', 'Region_ID' AS 'Region_ID','Type *' AS 'Type_*', 'Amendment/Revision Number' AS 'Amendment_Revision_Number', 'Summary of Amendment' AS 'Summary_of_Amendment', 'Initial Date Submitted to ACF' AS 'Initial_Date_Submitted_to_ACF', 'Final Date Submitted to ACF' AS 'Final_Date_Submitted_to_ACF', 'Date Approved by ACF' AS 'Date_Approved_by_ACF';

END IF;


UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_LEGACY_AMEND_REV_SUMMARY_PROC');
		
END$$
DELIMITER ;