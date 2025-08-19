DROP PROCEDURE IF EXISTS CARS_118A_GET_MULTIQUES_LOCK;

DELIMITER $$
CREATE PROCEDURE `CARS_118A_GET_MULTIQUES_LOCK`(IN `p_moduleHdrId` INT(11), IN `p_quespagecombo_Ids` TEXT, IN `p_lockBy` VARCHAR(255), OUT `p_lockSuccessful` TINYINT(1), OUT `p_lockedBy` VARCHAR(255), OUT `p_lockedTs` TIMESTAMP, OUT `p_lockedByRoleName` VARCHAR(255))
p_loop: 
BEGIN
	DECLARE v_quespagecombo_Ids TEXT ; 
	DECLARE v_comma INTEGER DEFAULT 0 ; 
	DECLARE v_pair VARCHAR(250) ; 	
	DECLARE v_remainder VARCHAR(250) ; 
	DECLARE v_quesId INTEGER DEFAULT 0 ;
	DECLARE v_pageNum INTEGER DEFAULT 0 ;
	DECLARE v_leave INTEGER DEFAULT 0 ; 
	DECLARE v_ts TIMESTAMP;
	DECLARE v_count INTEGER DEFAULT 0 ; 	
	DECLARE p_failed TINYINT(1) DEFAULT 0 ; 
	DECLARE v_roleName VARCHAR(250) ; 
	DECLARE v_USER_ID INT;
	
	-- process error handle
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		 
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_GET_MULTIQUES_LOCK');
		COMMIT; 
		
		SET p_lockSuccessful := FALSE;
	END;	
	
	SET p_failed := FALSE;
	SET p_lockSuccessful := FALSE;
	
	-- insert log record
	INSERT INTO CARS_SP_LOG (`SP_NAME`, `START_TS`, `END_TS`)
		VALUES( 'CARS_118A_GET_MULTIQUES_LOCK', NOW(), NOW());	
		
	-- check if there is question page pair exists
	SELECT INSTR(p_quespagecombo_Ids, ',') INTO v_comma FROM dual;
	
	IF v_comma = 0 THEN	
		ROLLBACK;		
		LEAVE p_loop;
	END IF;

	SET v_quespagecombo_Ids = p_quespagecombo_Ids;
	SET v_ts = NOW();
	
	START TRANSACTION;	

	-- Release lock
	-- loop through remainder string
	p_while:
	WHILE v_leave <> 1 DO	
		IF INSTR(v_quespagecombo_Ids, ';') > 0 THEN
			SELECT SUBSTRING(v_quespagecombo_Ids,1,INSTR(v_quespagecombo_Ids, ';') -1) INTO v_pair;
			SELECT SUBSTRING(v_quespagecombo_Ids,INSTR(v_quespagecombo_Ids, ';') +1) INTO v_remainder;	
			SELECT TO_NUMBER(TRIM(SUBSTRING(v_pair, 1, INSTR(v_pair, ',') -1))) INTO v_quesId;
			SELECT TO_NUMBER(TRIM(SUBSTRING(v_pair, INSTR(v_pair, ',') +1))) INTO v_pageNum;
		ELSE 
			SELECT TO_NUMBER(TRIM(SUBSTRING(v_quespagecombo_Ids, 1, INSTR(v_quespagecombo_Ids, ',') -1))) INTO v_quesId;
			SELECT TO_NUMBER(TRIM(SUBSTRING(v_quespagecombo_Ids, INSTR(v_quespagecombo_Ids, ',') +1))) INTO v_pageNum;		
			SET	v_remainder = NULL;		
		END IF;
	

	SELECT DISTINCT USER_ID  INTO v_USER_ID 
FROM VW_CARS_USER_ACCESS
		WHERE USERNAME = p_lockBy
		AND MODULE_ID IN (
			SELECT CMM.MODULE_ID FROM CARS_MODULE_META CMM 
			WHERE CMM.MODULE_META_ID IN (
					SELECT CMPH.MODULE_META_ID FROM CARS_MODULE_PERIOD_HDR CMPH
					where CMPH.MODULE_HDR_ID = p_moduleHdrId
				))

;

	
	SELECT ROLE_NAME INTO v_roleName FROM
(	
		SELECT  CASE WHEN ROLE_ID IN (1, 2) THEN 'State' WHEN ROLE_ID IN (3, 7) THEN 'Region' WHEN ROLE_ID = 4 THEN 'Validator' ELSE 'Default' END  ROLE_NAME
		FROM VW_CARS_USER_ACCESS
		WHERE USERNAME = p_lockBy
		AND USER_STATUS_CD='Active'
        AND STATUS_CD='Active'
		AND (
		(ENTITY_ID = ( SELECT E.ENTITY_ID FROM CARS_MODULE_PERIOD_HDR H JOIN CARS_ENTITY E ON H.ENTITY_ID=E.ENTITY_ID WHERE H.MODULE_HDR_ID=p_moduleHdrId))
		OR (ENTITY_ID = ( SELECT E.REGION_ID FROM CARS_MODULE_PERIOD_HDR H JOIN CARS_ENTITY E ON H.ENTITY_ID=E.ENTITY_ID WHERE H.MODULE_HDR_ID=p_moduleHdrId))
			)
			AND MODULE_ID IN (
			SELECT CMM.MODULE_ID FROM CARS_MODULE_META CMM 
			WHERE CMM.MODULE_META_ID IN (
					SELECT CMPH.MODULE_META_ID FROM CARS_MODULE_PERIOD_HDR CMPH
					where CMPH.MODULE_HDR_ID = p_moduleHdrId
				))

UNION
		
		SELECT  CASE WHEN DELEGATED_ROLE_ID IN (1, 2) THEN 'State' WHEN DELEGATED_ROLE_ID IN (3, 7) THEN 'Region' WHEN DELEGATED_ROLE_ID = 4 THEN 'Validator' ELSE 'Default' END   ROLE_NAME
		FROM VW_CARS_DELEGATION_LOG_REPORT
		WHERE USER_ID = v_USER_ID
		AND DELEGATED_REGION_IDS LIKE ( SELECT E.REGION_ID FROM CARS_MODULE_PERIOD_HDR H JOIN CARS_ENTITY E ON H.ENTITY_ID=E.ENTITY_ID WHERE H.MODULE_HDR_ID=p_moduleHdrId)
		AND DELEGATION_STATUS='Active'
		AND DELEGATED_ROLE_ID IN (1,2,3,4,7)
		AND MODULE_NAME IN (
			SELECT M.MODULE_NAME FROM CARS_MODULE_META CMM 
			JOIN CARS_MODULE M ON CMM.MODULE_ID=M.MODULE_ID
			WHERE CMM.MODULE_META_ID IN (
					SELECT CMPH.MODULE_META_ID FROM CARS_MODULE_PERIOD_HDR CMPH
					where CMPH.MODULE_HDR_ID = p_moduleHdrId
				)
		)
)AA		
;	
	
		-- check if it has been locked by others		
		SELECT LOCKED_BY, LOCKED_TS 
		  INTO p_lockedBy, p_lockedTs 
		  FROM CARS_118A_HDR_QUES_PAGE_LOCK
		 WHERE MODULE_HDR_ID = p_moduleHdrId 
		   AND QUES_ID = v_quesId 
		   AND PAGE_NUM = v_pageNum
		   AND (ROLE_NAME = v_roleName OR ROLE_NAME = 'Default'); 
		
		IF NVL(p_lockedBy,p_lockBy) <> p_lockBy 
		THEN			
			-- failed to get lock and leave
			ROLLBACK;
			SET p_failed = TRUE;
			LEAVE p_while;		
		END IF;
					  
		INSERT INTO CARS_118A_HDR_QUES_PAGE_LOCK (MODULE_HDR_ID, QUES_ID, PAGE_NUM, ROLE_NAME, LOCKED_BY, LOCKED_TS) 
			SELECT 	p_moduleHdrId, v_quesId, v_pageNum, v_roleName, p_lockBy, v_ts 
				ON DUPLICATE KEY UPDATE 
					LOCKED_TS = v_ts;	
			
		SELECT INSTR(v_remainder, ',') INTO v_comma FROM dual;	
		IF NVL(v_comma,0) = 0 THEN 
			SET v_leave = 1;
		ELSE
			SET v_quespagecombo_Ids = v_remainder;
		END IF;		

		-- prevent any infinite loop
		SET v_count = v_count + 1;			
		IF v_count > 500 THEN 
			LEAVE p_while;
		END IF;
		
	END WHILE ;
	
	IF p_failed = TRUE 
	THEN
		LEAVE p_loop;
	END IF;
		
	 /*Log success of the SP*/
	UPDATE CARS_SP_LOG
		SET SP_STATUS_TEXT= CONCAT('Success. Locks created or updated: ',v_count), END_TS=NOW()
	WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_GET_MULTIQUES_LOCK');
	COMMIT;	

	-- Set locked to true
	SET p_lockSuccessful := TRUE;
	SET p_lockedBy = p_lockBy;		
	SET p_lockedTs = v_ts;
	SET p_lockedByRoleName = v_roleName;

END$$
DELIMITER ;