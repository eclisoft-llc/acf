DELIMITER $$
CREATE OR REPLACE PROCEDURE `CARS_118A_REVIEW_LETTER_RECOMMENDATIONS_PROC`(IN period_id INTEGER,IN amend_id TEXT)
proc_label: BEGIN

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_REVIEW_LETTER_RECOMMENDATIONS_PROC');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118A_REVIEW_LETTER_RECOMMENDATIONS_PROC', 'Started', NOW());	




IF TRIM(amend_id)!='' THEN

SELECT * FROM (SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Plan_Version',
			C.SUBQUES_NAME AS 'Amended_Question',
			IFNULL(AQ.REVIEW_DECISION_TEXT,'') AS 'Recommendation_Review_Decision',
			IFNULL(AQ.LETTER_SELECTION_TEXT,'') AS 'Approval_Letter_Recommendation',
			IFNULL(AQ.LETTER_STANDARD_LANG,'') AS 'Language_in_Letter',
			IFNULL(AQ.NEW_EFFECTIVE_DATE,'') AS 'Late_Amendment_New_Effective_Date'
            
FROM CARS_118A_HDR_AMEND B 
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_118A_SUBQUES_AMENDMENT A ON A.HDR_AMEND_ID=B.HDR_AMEND_ID AND A.`IS_AMENDED`=1
JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
	
    LEFT JOIN CARS_118A_HDR_SUBQUES_REVIEW AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID AND C.SUBQUES_ID=AQ.SUBQUES_ID AND AQ.REVIEW_STATUS_TEXT='Recommendation Review' 
	
	
			WHERE B.HDR_AMEND_ID IN ((select TRIM(j.name) AS AMEND_ID
	from json_table(
	  replace(json_array(amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) 
	UNION ALL 
	SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			'Initial Plan' AS 'Amendment_Number',
			AQ.SUBQUES_NAME AS 'Amended_Question',
			IFNULL(AQ.REVIEW_DECISION_TEXT,'') AS 'Recommendation_Review_Decision',
			IFNULL(AQ.LETTER_SELECTION_TEXT,'') AS 'Approval_Letter_Recommendation',
			IFNULL(AQ.LETTER_STANDARD_LANG,'') AS 'Language_in_Letter',
			IFNULL(AQ.NEW_EFFECTIVE_DATE,'') AS 'Late_Amendment_New_Effective_Date'
			
FROM CARS_118A_HDR_AMEND B 
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'

    JOIN (SELECT A.HDR_AMEND_ID,B.SUBQUES_NAME,A.REVIEW_DECISION_TEXT,
               A.LETTER_SELECTION_TEXT,A.LETTER_STANDARD_LANG,A.NEW_EFFECTIVE_DATE
               FROM CARS_118A_HDR_SUBQUES_REVIEW AS A 
    JOIN CARS_118A_SUBQUES B ON B.SUBQUES_ID=A.SUBQUES_ID
	WHERE A.REVIEW_STATUS_TEXT='Recommendation Review') AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID 
		WHERE B.HDR_AMEND_ID IN ((select TRIM(j.name) AS AMEND_ID
	from json_table(
	  replace(json_array(amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j))  AND B.AMEND_SEQ_NUM=1) AS G
			
          ORDER BY Lead_Agency,Amended_Question;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Plan Version' AS 'Plan Version','Amended Question' AS 'Amended Question','Recommendation Review Decision' AS 'Recommendation Review Decision',
	'Approval Letter Recommendation' AS 'Approval Letter Recommendation','Language in Letter' AS 'Language in Letter',  'Late Amendment/New Effective Date' AS 'Late Amendment/New Effective Date';
		
			
	ELSE
		SELECT * FROM (SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Plan_Version',
			C.SUBQUES_NAME AS 'Amended_Question',
			IFNULL(AQ.REVIEW_DECISION_TEXT,'') AS 'Recommendation_Review_Decision',
			IFNULL(AQ.LETTER_SELECTION_TEXT,'') AS 'Approval_Letter_Recommendation',
			IFNULL(AQ.LETTER_STANDARD_LANG,'') AS 'Language_in_Letter',
			IFNULL(AQ.NEW_EFFECTIVE_DATE,'') AS 'Late_Amendment_New_Effective_Date'
            
FROM CARS_118A_HDR_AMEND B 
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_118A_SUBQUES_AMENDMENT A ON A.HDR_AMEND_ID=B.HDR_AMEND_ID AND A.`IS_AMENDED`=1
JOIN CARS_118A_SUBQUES C ON C.SUBQUES_ID=A.SUBQUES_ID
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'
	
    LEFT JOIN CARS_118A_HDR_SUBQUES_REVIEW AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID AND C.SUBQUES_ID=AQ.SUBQUES_ID AND AQ.REVIEW_STATUS_TEXT='Recommendation Review' 
	
			
	UNION ALL 
	SELECT 
			DISTINCT H.ENTITY_NAME AS 'Lead_Agency',
			E.OGM_TRIBAL_CD AS 'Tribal_Code',
			H.ENTITY_STATE_CD AS 'State',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			T.ALLOCATION_SIZE AS 'Allocation',
			'Initial Plan' AS 'Amendment_Number',
			AQ.SUBQUES_NAME AS 'Amended_Question',
			IFNULL(AQ.REVIEW_DECISION_TEXT,'') AS 'Recommendation_Review_Decision',
			IFNULL(AQ.LETTER_SELECTION_TEXT,'') AS 'Approval_Letter_Recommendation',
			IFNULL(AQ.LETTER_STANDARD_LANG,'') AS 'Language_in_Letter',
			IFNULL(AQ.NEW_EFFECTIVE_DATE,'') AS 'Late_Amendment_New_Effective_Date'
			
FROM CARS_118A_HDR_AMEND B 
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = 'REGION'

    JOIN (SELECT A.HDR_AMEND_ID,B.SUBQUES_NAME,A.REVIEW_DECISION_TEXT,
               A.LETTER_SELECTION_TEXT,A.LETTER_STANDARD_LANG,A.NEW_EFFECTIVE_DATE
               FROM CARS_118A_HDR_SUBQUES_REVIEW AS A 
    JOIN CARS_118A_SUBQUES B ON B.SUBQUES_ID=A.SUBQUES_ID
	WHERE A.REVIEW_STATUS_TEXT='Recommendation Review') AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID 
		WHERE B.AMEND_SEQ_NUM=1) AS G
			
          ORDER BY Lead_Agency,Amended_Question;
			
	
	SELECT 'Lead Agency' AS 'Lead Agency', 'Tribal Code' AS 'Tribal Code', 'State' AS 'State','Region' AS 'Region','Region_ID' AS 'Region_ID','Allocation' AS 'Allocation','Plan Version' AS 'Plan Version','Amended Question' AS 'Amended Question','Recommendation Review Decision' AS 'Recommendation Review Decision',
	'Approval Letter Recommendation' AS 'Approval Letter Recommendation','Language in Letter' AS 'Language in Letter',  'Late Amendment/New Effective Date' AS 'Late Amendment/New Effective Date';
	
			
END IF;

					  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118A_REVIEW_LETTER_RECOMMENDATIONS_PROC');
		
END$$
DELIMITER ;