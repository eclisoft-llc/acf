DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_118A_REVIEW_DECISION_HISTORY(IN i_entity_ids TEXT,IN i_subques_ids TEXT,IN i_query_by TEXT,IN i_amend_id TEXT)
proc_label: BEGIN


	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_REVIEW_DECISION_HISTORY');

			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118A_REVIEW_DECISION_HISTORY', 'Started', NOW());


IF TRIM(i_query_by)='returnedGranteeLeastOnceFlag' THEN
SELECT 
ROW_NUMBER() OVER() as ROW_SEQ_NUM
,ti.LEAD_AGENCY_NAME
,e.OGM_TRIBAL_CD
,e.ENTITY_STATE_CD
,e.ENTITY_ID
,e.ENTITY_NAME
,e.REGION_ID
,r.ENTITY_NAME AS REGION_NAME
,ti.ALLOCATION_SIZE
,CASE WHEN ha.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',ha.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Plan_Version'
,sq.SUBQUES_ID
,sq.SUBQUES_NAME
,sr.RETURNED_GRANTEE_LEAST_ONCE_FLAG
,sr.RETURNED_RO_LEAST_ONCE_FLAG
FROM `CARS_118A_HDR_SUBQUES_REVIEW` sr
join CARS_118A_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
join CARS_118A_HDR_AMEND ha on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID
join VW_CARS_118A_HDR_TRIBE_INFO ti on ti.MODULE_HDR_ID = ha.MODULE_HDR_ID
join CARS_ENTITY e on e.ENTITY_ID = ti.ENTITY_ID
join CARS_ENTITY r on r.ENTITY_ID = e.REGION_ID
WHERE e.ENTITY_ID IN ((select TRIM(j.name) AS ENTITY_ID
		from json_table(
		  replace(json_array(i_entity_ids), ',', '","'),
		  '$[*]' columns (name varchar(10) path '$')
		) j)) AND sq.SUBQUES_ID IN ((select TRIM(j.name) AS SUBQUES_ID
		from json_table(
		  replace(json_array(i_subques_ids), ',', '","'),
		  '$[*]' columns (name varchar(10) path '$')
		) j)) AND sr.`RETURNED_GRANTEE_LEAST_ONCE_FLAG` = 1 AND sr.`REVIEW_STATUS_TEXT` = "Recommendation Review"
			AND ha.HDR_AMEND_ID IN ((select TRIM(j.name) AS HDR_AMEND_ID
	from json_table(
	  replace(json_array(i_amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j));
	
ELSE
SELECT 
ROW_NUMBER() OVER() as ROW_SEQ_NUM
,ti.LEAD_AGENCY_NAME
,e.OGM_TRIBAL_CD
,e.ENTITY_STATE_CD
,e.ENTITY_ID
,e.ENTITY_NAME
,e.REGION_ID
,r.ENTITY_NAME AS REGION_NAME
,ti.ALLOCATION_SIZE
,CASE WHEN ha.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',ha.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Plan_Version'
,sq.SUBQUES_ID
,sq.SUBQUES_NAME
,sr.RETURNED_GRANTEE_LEAST_ONCE_FLAG
,sr.RETURNED_RO_LEAST_ONCE_FLAG
FROM `CARS_118A_HDR_SUBQUES_REVIEW` sr
join CARS_118A_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
join CARS_118A_HDR_AMEND ha on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID
join VW_CARS_118A_HDR_TRIBE_INFO ti on ti.MODULE_HDR_ID = ha.MODULE_HDR_ID
join CARS_ENTITY e on e.ENTITY_ID = ti.ENTITY_ID
join CARS_ENTITY r on r.ENTITY_ID = e.REGION_ID
WHERE e.ENTITY_ID IN ((select TRIM(j.name) AS ENTITY_ID
		from json_table(
		  replace(json_array(i_entity_ids), ',', '","'),
		  '$[*]' columns (name varchar(10) path '$')
		) j)) AND sq.SUBQUES_ID IN ((select TRIM(j.name) AS SUBQUES_ID
		from json_table(
		  replace(json_array(i_subques_ids), ',', '","'),
		  '$[*]' columns (name varchar(10) path '$')
		) j)) AND sr.`RETURNED_RO_LEAST_ONCE_FLAG` = 1 AND sr.`REVIEW_STATUS_TEXT` = "Recommendation Review"
		AND ha.HDR_AMEND_ID IN ((select TRIM(j.name) AS HDR_AMEND_ID
	from json_table(
	  replace(json_array(i_amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) ;
		
		
END IF;

					  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118A_REVIEW_DECISION_HISTORY');
		
END$$
DELIMITER ;