DELIMITER $$
CREATE OR REPLACE PROCEDURE `CARS_118A_AMENDMENT_LOG_REPORT`(IN period_id INTEGER,IN entity_id TEXT, IN excludedApprovedAmendments INTEGER)
proc_label: BEGIN

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_AMENDMENT_LOG_REPORT');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118A_AMENDMENT_LOG_REPORT', 'Started', NOW());	



IF excludedApprovedAmendments=1 THEN
IF TRIM(entity_id)!='' THEN

SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			C.SUBQUES_NAME AS 'Question',
			'Yes' AS 'Is_Amendment',
			A.`EFFECTIVE_DATE` AS 'Effective_Date',
			A.REASON_FOR_CHANGE AS 'Reason_for_Change',
			A.`DESCRIPTION` AS 'Description'
            
FROM CARS_118A_SUBQUES_AMENDMENT A
JOIN CARS_118A_HDR_AMEND B ON A.HDR_AMEND_ID=B.HDR_AMEND_ID
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
			
			
			WHERE B.APPR_TS IS NULL AND H.ENTITY_ID IN ((select TRIM(j.name) AS ENTITY_ID
	from json_table(
	  replace(json_array(entity_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) AND A.`IS_AMENDED`=1
            ORDER BY H.ENTITY_NAME,C.SUBQUES_NAME;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Amendment Number' AS 'Amendment Number','Question' AS 'Question','Is Amendment' AS 'Is Amendment',
	'Effective Date' AS 'Effective Date','Reason for Change' AS 'Reason for Change',  'Description' AS 'Description';
			
			
	ELSE
		SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			C.SUBQUES_NAME AS 'Question',
			'Yes' AS 'Is_Amendment',
			A.`EFFECTIVE_DATE` AS 'Effective_Date',
			A.REASON_FOR_CHANGE AS 'Reason_for_Change',
			A.`DESCRIPTION` AS 'Description'
		FROM CARS_118A_SUBQUES_AMENDMENT A
		JOIN CARS_118A_HDR_AMEND B ON A.HDR_AMEND_ID=B.HDR_AMEND_ID
		JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
		JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
		JOIN CARS_TRIBE_INFO T
		ON H.PERIOD_ID = T.PERIOD_ID
		AND H.ENTITY_ID = T.TRIBE_ID
		JOIN CARS_ENTITY E
		ON H.ENTITY_ID = E.ENTITY_ID
		JOIN CARS_ENTITY R
		ON E.REGION_ID = R.ENTITY_ID
		AND R.ENTITY_TYPE_CD = 'REGION'
					
					
					WHERE B.APPR_TS IS NULL AND A.`IS_AMENDED`=1
            ORDER BY H.ENTITY_NAME,C.SUBQUES_NAME;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Amendment Number' AS 'Amendment Number','Question' AS 'Question','Is Amendment' AS 'Is Amendment',
	'Effective Date' AS 'Effective Date','Reason for Change' AS 'Reason for Change',  'Description' AS 'Description';
			
END IF;

ELSE

IF TRIM(entity_id)!='' THEN

SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			C.SUBQUES_NAME AS 'Question',
			'Yes' AS 'Is_Amendment',
			A.`EFFECTIVE_DATE` AS 'Effective_Date',
			A.REASON_FOR_CHANGE AS 'Reason_for_Change',
			A.`DESCRIPTION` AS 'Description'
FROM CARS_118A_SUBQUES_AMENDMENT A
JOIN CARS_118A_HDR_AMEND B ON A.HDR_AMEND_ID=B.HDR_AMEND_ID
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
			
			
			WHERE H.ENTITY_ID IN ((select TRIM(j.name) AS ENTITY_ID
	from json_table(
	  replace(json_array(entity_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) AND A.`IS_AMENDED`=1
            ORDER BY H.ENTITY_NAME,C.SUBQUES_NAME;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Amendment Number' AS 'Amendment Number','Question' AS 'Question','Is Amendment' AS 'Is Amendment',
	'Effective Date' AS 'Effective Date','Reason for Change' AS 'Reason for Change',  'Description' AS 'Description';
			
	ELSE
		SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			C.SUBQUES_NAME AS 'Question',
			'Yes' AS 'Is_Amendment',
			A.`EFFECTIVE_DATE` AS 'Effective_Date',
			A.REASON_FOR_CHANGE AS 'Reason_for_Change',
			A.`DESCRIPTION` AS 'Description'
		FROM CARS_118A_SUBQUES_AMENDMENT A
		JOIN CARS_118A_HDR_AMEND B ON A.HDR_AMEND_ID=B.HDR_AMEND_ID
		JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
		JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
		JOIN CARS_TRIBE_INFO T
		ON H.PERIOD_ID = T.PERIOD_ID
		AND H.ENTITY_ID = T.TRIBE_ID
		JOIN CARS_ENTITY E
		ON H.ENTITY_ID = E.ENTITY_ID
		JOIN CARS_ENTITY R
		ON E.REGION_ID = R.ENTITY_ID
		AND R.ENTITY_TYPE_CD = 'REGION'
					
					WHERE A.`IS_AMENDED`=1
            ORDER BY H.ENTITY_NAME,C.SUBQUES_NAME;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Amendment Number' AS 'Amendment Number','Question' AS 'Question','Is Amendment' AS 'Is Amendment',
	'Effective Date' AS 'Effective Date','Reason for Change' AS 'Reason for Change',  'Description' AS 'Description';
			
END IF;
END IF;
					  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118A_AMENDMENT_LOG_REPORT');
		
END$$
DELIMITER ;