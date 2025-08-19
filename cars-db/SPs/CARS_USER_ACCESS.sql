DROP  PROCEDURE IF EXISTS CARS_USER_ACCESS;

DELIMITER $$
CREATE PROCEDURE CARS_USER_ACCESS(
	IN i_user_id TEXT ,
    IN i_role_id TEXT ,
    IN i_module_id TEXT ,
    IN i_user_email_addr TEXT ,
    IN i_username TEXT ,
    IN i_user_status_cd TEXT ,
    IN i_status_cd TEXT ,
    IN i_user_type_cd TEXT 
)

BEGIN
	DECLARE v_user_id TEXT DEFAULT '';
    DECLARE v_role_id TEXT DEFAULT '';
    DECLARE v_module_id TEXT DEFAULT '';
    DECLARE v_user_email_addr TEXT DEFAULT '';
    DECLARE v_username TEXT DEFAULT '';
    DECLARE v_user_status_cd TEXT DEFAULT '';
    DECLARE v_status_cd TEXT DEFAULT '';
    DECLARE v_user_type_cd TEXT DEFAULT '';
	DECLARE v_where TEXT DEFAULT '';
    DECLARE v_sql TEXT DEFAULT '';
    
	-- process error handle
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		 
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_USER_ACCESS');
		COMMIT; 

	END;	
	
	-- insert log record
	INSERT INTO CARS_SP_LOG (SP_NAME, START_TS, END_TS)
		VALUES( 'CARS_USER_ACCESS', NOW(), NOW());

############### 

IF IFNULL(i_user_id,'')<>'' THEN SET v_user_id = CONCAT(' AND A.USER_ID IN (',i_user_id,')'); END IF ;
IF IFNULL(i_role_id,'')<>'' THEN SET v_role_id = CONCAT(' AND A.ROLE_ID IN (',i_role_id,')'); END IF ;
IF IFNULL(i_module_id,'')<>'' THEN SET v_module_id = CONCAT(' AND A.MODULE_ID IN (',i_module_id,')'); END IF;
IF IFNULL(i_user_email_addr,'')<>''THEN SET v_user_email_addr = CONCAT(' AND A.USER_EMAIL_ADDR LIKE  ("%',i_user_email_addr,'%")'); END IF;
IF IFNULL(i_username,'')<>''THEN SET v_username = CONCAT(' AND A.USERNAME <>',i_username,' ');END IF ;
IF IFNULL(i_user_status_cd,'')<>'' THEN SET v_user_status_cd = CONCAT(' AND A.USER_STATUS_CD IN (',i_user_status_cd,')');END IF ;
IF IFNULL(i_status_cd,'')<>'' THEN SET v_status_cd = CONCAT(' AND A.STATUS_CD IN (',i_status_cd,')'); END IF;
IF IFNULL(i_user_type_cd,'')<>'' THEN SET v_user_type_cd = CONCAT(' AND A.USER_TYPE_CD IN (',i_user_type_cd,')'); END IF;

SET    v_where= CONCAT(v_user_id, 
     v_role_id,
     v_module_id, 
     v_user_email_addr, 
     v_username,  
     v_user_status_cd, 
     v_status_cd,  
     v_user_type_cd 
	 ) ;
#SELECT v_where;
 
 SET v_sql = CONCAT('   
SELECT USER_ACCESS_ID, USER_ID, USERNAME, USER_EMAIL_ADDR, FIRST_NAME, LAST_NAME, USER_PHONE_NUM, USER_PHONE_EXT_NUM, ENTITY_ID
, ENTITY_NAME, ENTITY_TYPE_CD, ROLE_ID, MODULE_ID, MODULE_NAME, ROLE_NAME, LAST_UPD_TS,
 USER_STATUS_CD, STATUS_CD, COMMENT_TEXT, APPROVE_REGION_ID, USER_TYPE_CD, LAST_UPD_BY, PRIVILEGED_USER_FLAG, ACCOUNT_REVIEW_FLAG,
 LAST_REVIEWED_BY, LAST_REVIEWED_TS
FROM VW_CARS_USER_ACCESS A
WHERE 
A.ROLE_ID <> 11', v_where)
;
#SELECT v_sql;

EXECUTE IMMEDIATE(v_sql);
###################

	UPDATE CARS_SP_LOG
		SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
	WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME='CARS_USER_ACCESS');
	COMMIT;	
 	
END$$
DELIMITER ;