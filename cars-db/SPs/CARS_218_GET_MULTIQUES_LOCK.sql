DROP PROCEDURE IF EXISTS CARS_218_GET_MULTIQUES_LOCK;

DELIMITER //

CREATE PROCEDURE CARS_218_GET_MULTIQUES_LOCK (
	IN p_moduleHdrId INT(11), 
	IN p_quespagecombo_Ids TEXT, 	
	IN p_lockBy VARCHAR(255), 
	OUT p_lockSuccessful TINYINT(1), 
    OUT p_lockedBy VARCHAR(255), 
	OUT p_lockedTs TIMESTAMP) 
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
	
	-- process error handle
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		 
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_218_GET_MULTIQUES_LOCK');
		COMMIT; 
		
		SET p_lockSuccessful := FALSE;
	END;	
	
	SET p_failed := FALSE;
	SET p_lockSuccessful := FALSE;
	
	-- insert log record
	INSERT INTO CARS_SP_LOG (`SP_NAME`, `START_TS`, `END_TS`)
		VALUES( 'CARS_218_GET_MULTIQUES_LOCK', NOW(), NOW());	
		
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
		
		-- check if it has been locked by others		
		SELECT LOCKED_BY, LOCKED_TS 
		  INTO p_lockedBy, p_lockedTs 
		  FROM CARS_218_HDR_QUES_PAGE_LOCK
		 WHERE MODULE_HDR_ID = p_moduleHdrId 
		   AND QUES_ID = v_quesId 
		   AND PAGE_NUM = v_pageNum; 
		
		IF NVL(p_lockedBy,p_lockBy) <> p_lockBy 
		THEN			
			-- failed to get lock and leave
			ROLLBACK;
			SET p_failed = TRUE;
			LEAVE p_while;		
		END IF;
					  
		INSERT INTO CARS_218_HDR_QUES_PAGE_LOCK (MODULE_HDR_ID, QUES_ID, PAGE_NUM, LOCKED_BY, LOCKED_TS) 
			SELECT 	p_moduleHdrId, v_quesId, v_pageNum, p_lockBy, v_ts 
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
	WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME='CARS_218_GET_MULTIQUES_LOCK');
	COMMIT;	

	-- Set locked to true
	SET p_lockSuccessful := TRUE;
	SET p_lockedBy = p_lockBy;	
	SET p_lockedTs = v_ts;

END //

DELIMITER ;