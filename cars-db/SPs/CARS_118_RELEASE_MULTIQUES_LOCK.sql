DROP PROCEDURE IF EXISTS CARS_118_RELEASE_MULTIQUES_LOCK;

DELIMITER //

CREATE PROCEDURE CARS_118_RELEASE_MULTIQUES_LOCK (
	IN p_moduleHdrId INT(11), 
	IN p_quespagecombo_Ids TEXT, 	
	IN p_lockedBy VARCHAR(255), 
	IN p_lockedTs TIMESTAMP, 
	OUT p_releaseSuccessful TINYINT(1))
p_loop: 
BEGIN
	DECLARE v_quespagecombo_Ids TEXT ; 
	DECLARE v_comma INTEGER DEFAULT 0 ; 
	DECLARE v_pair VARCHAR(250) ; 	
	DECLARE v_remainder VARCHAR(250) ; 
	DECLARE v_quesId INTEGER DEFAULT 0 ;
	DECLARE v_pageNum INTEGER DEFAULT 0 ;
	DECLARE v_leave INTEGER DEFAULT 0 ; 
	
	DECLARE v_count INTEGER DEFAULT 0 ; 
	
	-- process error handle
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		 
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_RELEASE_MULTIQUES_LOCK');
		COMMIT; 
		
		SET p_releaseSuccessful := FALSE;
	END;	
	
	-- insert log record
	INSERT INTO CARS_SP_LOG (`SP_NAME`, `START_TS`, `END_TS`)
		VALUES( 'CARS_118_RELEASE_MULTIQUES_LOCK', NOW(), NOW());	
		
	-- check if there is question page pair exists
	SELECT INSTR(p_quespagecombo_Ids, ',') INTO v_comma FROM dual;
	
	IF v_comma = 0 THEN	
		ROLLBACK;
		SET p_releaseSuccessful := FALSE;
		LEAVE p_loop;
	END IF;

	SET v_quespagecombo_Ids = p_quespagecombo_Ids;
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
			   		
		DELETE FROM CARS_118_HDR_QUES_PAGE_LOCK
		WHERE
			MODULE_HDR_ID = p_moduleHdrId 
			AND QUES_ID = v_quesId
			AND PAGE_NUM = v_pageNum
			AND LOCKED_BY = p_lockedBy
			AND LOCKED_TS = TIMESTAMP(p_lockedTs)
			;
			
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
	
	 /*Log success of the SP*/
	UPDATE CARS_SP_LOG
		SET SP_STATUS_TEXT= CONCAT('Success. Locks released: ',v_count), END_TS=NOW()
	WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_RELEASE_MULTIQUES_LOCK');
	COMMIT;	
	
	SET p_releaseSuccessful := TRUE;

END //

DELIMITER ;