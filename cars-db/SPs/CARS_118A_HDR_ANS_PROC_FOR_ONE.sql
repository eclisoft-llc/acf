DROP PROCEDURE IF EXISTS CARS_118A_HDR_ANS_PROC_FOR_ONE;

DELIMITER //

CREATE PROCEDURE CARS_118A_HDR_ANS_PROC_FOR_ONE(
	IN i_hdr_amend_id INT
)
p_loop: 
BEGIN

	DECLARE v_exist INTEGER DEFAULT 0 ;
	DECLARE v_total_rows_deleted INTEGER DEFAULT 0 ;
	DECLARE v_total_rows_inserted INTEGER DEFAULT 0 ;
	
	-- process error handle
	DECLARE exit handler for SQLEXCEPTION
	BEGIN
		 GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		 
		 SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		  
		 UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		  WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_HDR_ANS_PROC_FOR_ONE');
		 COMMIT; 
	END;
	
	-- insert log record
	INSERT INTO CARS_SP_LOG (`SP_NAME`, `START_TS`, `END_TS`)
		VALUES( 'CARS_118A_HDR_ANS_PROC_FOR_ONE', NOW(), NOW());	
		

	-- check if input value is NULL
    IF NVL(i_hdr_amend_id,-1) = -1 THEN		
		LEAVE p_loop;
	END IF;
		
	-- check if head amend ID exists
	SELECT COUNT(*)
		INTO v_exist
	FROM
		CARS_118A_HDR_AMEND A
	JOIN CARS_MODULE_PERIOD_HDR H ON
		A.MODULE_HDR_ID = H.MODULE_HDR_ID
	JOIN CARS_TRIBE_INFO I ON
		H.ENTITY_ID = I.TRIBE_ID 
		AND I.PERIOD_ID = 1 
		AND I.ALLOCATION_SIZE IN('Large', 'Medium', 'Small') 
		AND A.HDR_AMEND_ID = i_hdr_amend_id
		;
		
	IF NVL(v_exist,0) = 0 THEN	
		LEAVE p_loop;
	ELSE
		-- 1) delete all records in CARS_118A_HDR_ANS table for given HDR_AMEND_ID
		DELETE FROM CARS_118A_HDR_ANS WHERE HDR_AMEND_ID = i_hdr_amend_id;
		SET v_total_rows_deleted = ROW_COUNT() ;
	END IF;
    
	-- 2) insert records in CARS_118A_HDR_ANS table for given HDR_AMEND_ID
    INSERT INTO CARS_118A_HDR_ANS (
        HDR_AMEND_ID,
        SUBQUES_RESP_ID,
        ANS_STATUS_TEXT
    )
	SELECT
		A.HDR_AMEND_ID,
		R.SUBQUES_RESP_ID,
		(CASE WHEN I.ALLOCATION_SIZE IN('Large', 'Medium') THEN R.LGMED_ANS_STATUS_TEXT WHEN I.ALLOCATION_SIZE IN('Small') THEN R.SMALL_ANS_STATUS_TEXT END) ANS_STATUS_TEXT
	FROM
		CARS_118A_SUBQUES_RESP R
	JOIN CARS_118A_HDR_AMEND A ON
		1 = 1
	JOIN CARS_MODULE_PERIOD_HDR H ON
		A.MODULE_HDR_ID = H.MODULE_HDR_ID
	JOIN CARS_TRIBE_INFO I ON
		H.ENTITY_ID = I.TRIBE_ID 
			AND I.PERIOD_ID = 1 
			AND I.ALLOCATION_SIZE IN('Large', 'Medium', 'Small') 
			AND R.RESP_TYPE_CD <> 'INFO' 
			AND A.HDR_AMEND_ID = i_hdr_amend_id;
		
    -- get count for award tables	
	SET v_total_rows_inserted = ROW_COUNT() ;	
	
	 /*Log success of the SP*/
	UPDATE CARS_SP_LOG
		SET SP_STATUS_TEXT= CONCAT('Success. Rows inserted: ',v_total_rows_inserted,'; Rows deleted before process: ', v_total_rows_deleted), END_TS=NOW()
	WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_HDR_ANS_PROC_FOR_ONE');
	COMMIT;
END //
    
DELIMITER  ;
	
