DROP PROCEDURE IF EXISTS CARS_118_AMENDMENT_REQUESTS_REPORT;
DELIMITER $$
CREATE PROCEDURE CARS_118_AMENDMENT_REQUESTS_REPORT(IN period_id INTEGER,IN entity_id TEXT, IN excludeAcceptedFlag INT)


proc_label: BEGIN

DECLARE v_Status_Text TEXT DEFAULT NULL;
DECLARE v_sql TEXT DEFAULT NULL;




	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_AMENDMENT_REQUESTS_REPORT');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_AMENDMENT_REQUESTS_REPORT', 'Started', NOW());	

IF excludeAcceptedFlag = 1 THEN SET v_Status_Text = ' AND  A.STATUS <> ''Accepted'' ' ;
ELSE SET v_Status_Text = '  ' ;
END IF;


IF TRIM(entity_id)!='' THEN

SET v_sql = 
CONCAT('
SELECT 
	 H.ENTITY_NAME AS ''State_Territory'',
	 CASE WHEN C.HDR_AMEND_ID IS NULL THEN NULL
		  WHEN C.AMEND_SEQ_NUM>1 THEN CONCAT("Amendment #", C.AMEND_SEQ_NUM-1) 
     ELSE ''Initial Plan'' END AS ''Amendment_Number'',
	 A.STATUS AS ''Status'',
	 A.REQUESTED_BY AS ''Requested_By'',
	 A.REQUESTED_TS AS ''Requested_Time'',
	 A.DESCRIPTION AS ''Description'',
	 A.DECISION AS ''Decision'',
    A.DECISION_BY AS''Decision_By'',
    A.DECISION_TS AS ''Decision_Time'',
    A.ROGUIDANCE AS ''Regional_Office_Guidance''	
FROM CARS_118_AMENDMENT_REQUEST A
JOIN CARS_118_HDR_AMEND B ON A.ORIGINAL_HDR_AMEND_ID=B.HDR_AMEND_ID
LEFT OUTER JOIN CARS_118_HDR_AMEND C ON A.NEW_HDR_AMEND_ID = C.HDR_AMEND_ID
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=',period_id,'
JOIN CARS_ENTITY E
			ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = ''STATE-TER''
			WHERE H.ENTITY_ID IN (',entity_id,')', v_Status_Text, '  
            ORDER BY H.ENTITY_NAME'
			)
			;

EXECUTE IMMEDIATE v_sql;
	
	SELECT 'State/Territory' AS 'State/Territory','Amendment Number' AS 'Amendment_Number', 'Status' AS 'Status','Requested By' AS 'Requested By',
	'Requested Time' AS 'Requested Time','Description' AS 'Description','Decision' AS 'Decision','Decision By' AS 'Decision By','Decision Time' AS 'Decision Time',
	'Regional Office Guidance' AS 'Regional Office Guidance';
			
			
	ELSE
	
	SET v_sql = 
	CONCAT('
		SELECT 
	 H.ENTITY_NAME AS ''State_Territory'',
	 CASE WHEN C.HDR_AMEND_ID IS NULL THEN NULL
		  WHEN C.AMEND_SEQ_NUM>1 THEN CONCAT("Amendment #", C.AMEND_SEQ_NUM-1) 
     ELSE ''Initial Plan'' END AS ''Amendment_Number'',
	 A.STATUS AS ''Status'',
	 A.REQUESTED_BY AS ''Requested_By'',
	 A.REQUESTED_TS AS ''Requested_Time'',
	 A.DESCRIPTION AS ''Description'',
	 A.DECISION AS ''Decision'',
    A.DECISION_BY AS ''Decision_By'',
    A.DECISION_TS AS ''Decision_Time'',
    A.ROGUIDANCE AS ''Regional_Office_Guidance''
	FROM CARS_118_AMENDMENT_REQUEST A
	JOIN CARS_118_HDR_AMEND B ON A.ORIGINAL_HDR_AMEND_ID=B.HDR_AMEND_ID
	JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=',period_id,'
	LEFT OUTER JOIN CARS_118_HDR_AMEND C ON A.NEW_HDR_AMEND_ID = C.HDR_AMEND_ID
	JOIN CARS_ENTITY E
				ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = ''STATE-TER''
				WHERE 1 = 1 ', v_Status_Text, '  
				ORDER BY H.ENTITY_NAME'
				)
				;

EXECUTE IMMEDIATE v_sql;			
	
	SELECT 'State/Territory' AS 'State/Territory','Amendment Number' AS 'Amendment_Number','Status' AS 'Status','Requested By' AS 'Requested By',
	'Requested Time' AS 'Requested Time','Description' AS 'Description','Decision' AS 'Decision','Decision By' AS 'Decision By','Decision Time' AS 'Decision Time',
	'Regional Office Guidance' AS 'Regional Office Guidance';
END IF;

					  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_AMENDMENT_REQUESTS_REPORT');
		
END$$
DELIMITER ;