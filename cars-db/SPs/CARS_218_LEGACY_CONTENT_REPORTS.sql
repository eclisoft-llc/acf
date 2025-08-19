
DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_218_LEGACY_CONTENT_REPORTS(IN i_subques_list TEXT, IN i_year TEXT, IN i_entity_list TEXT)
proc_label: BEGIN

DECLARE v_iter INTEGER DEFAULT 0;
DECLARE v_createtable TEXT DEFAULT '';
DECLARE v_droptable TEXT DEFAULT '';
DECLARE v_whilecnt INTEGER DEFAULT 1;
DECLARE v_collist TEXT DEFAULT '';
DECLARE v_collist1 TEXT DEFAULT '';
DECLARE v_infinite INTEGER DEFAULT 0;
DECLARE v_comma CHAR(1) DEFAULT ',';
DECLARE v_sql TEXT DEFAULT '';
DECLARE v_union TEXT DEFAULT ' ';
DECLARE v_sqlhdr TEXT DEFAULT '';
DECLARE v_sqlans TEXT DEFAULT '';
DECLARE v_rand CHAR(7) DEFAULT '';
DECLARE v_dropsql TEXT DEFAULT '';
DECLARE v_crsql TEXT DEFAULT '';



	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_218_LEGACY_CONTENT_REPORTS');

			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_218_LEGACY_CONTENT_REPORTS', 'Started', NOW());	

SELECT SUBSTR(CAST(RAND() * 100000000 AS VARCHAR(50)), 1, 7) INTO v_rand FROM DUAL;

/*
SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SUBQUES_RESP_LIST', v_rand);
EXECUTE IMMEDIATE (v_dropsql);
*/


DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SUBQUES_RESP_LIST;


SET v_sql = '';
SET v_sql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SUBQUES_RESP_LIST   
AS 
SELECT 
DENSE_RANK() OVER(ORDER BY Q.QPR_SECT_QUEST_ID , Q.QPR_SEQ) AS LIST_ORDER
,Q.QPR_SECT_QUEST_ID AS QUEST_ID
,Q.QPR_SEC_QUEST_NAME AS QUESTION
,Q.QPR_FORM_TEXT AS  RESPONSE
,Q.QPR_QUES_CODE AS RESP_TYPE_CD
,Q.QPR_FORM_TEXT AS  COL_HEADER
,Q.QPR_SECT_QUEST_ID  AS GROUP_COL
FROM  CARS_LEGACY_218_QPR_SECT_QUEST Q
JOIN CARS_PERIOD P ON  RIGHT(P.PERIOD_DESC,4)=Q.QPR_YEAR 
WHERE
 #Q.QPR_QUES_CODE NOT IN (''QB'',''LB'',''PB'')AND 
 Q.QPR_SEC_QUEST_NAME IN (', i_subques_list, ') 
AND P.PERIOD_ID= ', i_year ,'   
')
;


EXECUTE IMMEDIATE(v_sql);


SELECT COUNT(DISTINCT LIST_ORDER) INTO v_iter FROM CARS_TEMP_SUBQUES_RESP_LIST;

IF v_iter > 100 THEN
	SELECT 'TOO MANY' FROM DUAL;
	SELECT 'TOO MANY' FROM DUAL;
	LEAVE proc_label;
END IF;


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_ANS_COLS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);



SET v_whilecnt = 1;
SET v_createtable = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_ANS_COLS', v_rand, '  
( ENTITY_NAME TEXT NULL, REGION_NAME TEXT NULL, REGION_ID INT NULL, ');

a_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
		
		IF v_iter = 0 THEN 
			SET v_collist = '';
			LEAVE a_while;
		END IF;
		
		IF v_whilecnt = 1 THEN 
			SET v_collist = v_createtable;
		END IF;
		
		IF v_whilecnt = v_iter THEN
			SET v_comma = '';
		END IF;
		
		SET v_collist = CONCAT(v_collist, 'COL', v_whilecnt, ' TEXT NULL', v_comma);
		
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 100 THEN
			LEAVE a_while;
		END IF;
		
	END WHILE a_while;

SET v_collist = CONCAT(v_collist, ');');

EXECUTE IMMEDIATE(v_collist);


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_ANSWERS', v_rand);

EXECUTE IMMEDIATE (v_dropsql);


SET v_crsql = '';
SET v_crsql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_ANSWERS', v_rand, ' AS SELECT * FROM CARS_TEMP_ANS_COLS', v_rand);

EXECUTE IMMEDIATE (v_crsql);

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_HEADER_COLS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_whilecnt = 1;
SET v_comma = ',';
SET v_collist = '';
SET v_infinite = 0;
SET v_createtable = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_HEADER_COLS', v_rand, '  
( ENTITY_NAME TEXT NULL, REGION_NAME TEXT NULL, REGION_ID TEXT NULL,  ');


a1_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
		
		IF v_iter = 0 THEN 
			SET v_collist = '';
			LEAVE a1_while;
		END IF;
		
		IF v_whilecnt = 1 THEN 
			SET v_collist = v_createtable;
		END IF;
		
		IF v_whilecnt = v_iter THEN
			SET v_comma = '';
		END IF;
		
		SET v_collist = CONCAT(v_collist, 'HEADER', v_whilecnt, ' TEXT NULL', v_comma);
		
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 100 THEN
			LEAVE a1_while;
		END IF;
		
	END WHILE a1_while;

SET v_collist = CONCAT(v_collist, ');');


EXECUTE IMMEDIATE(v_collist);

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_HEADERS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_crsql = '';
SET v_crsql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_HEADERS', v_rand, ' AS SELECT * FROM CARS_TEMP_HEADER_COLS', v_rand);

EXECUTE IMMEDIATE (v_crsql);


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_AMEND_LIST', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_sql = '';
SET v_sql = CONCAT('
CREATE TEMPORARY TABLE CARS_TEMP_AMEND_LIST', v_rand, ' 
AS 
SELECT 
DISTINCT
X.ENTITY_NAME
,0 AS HDR_AMEND_ID
,X.REGION_NAME
,X.REGION_ID
#,0 AS AMEND_SEQ_NUM
FROM 
 CARS_PERIOD P
CROSS JOIN 
	(SELECT  E.ENTITY_NAME,R.ENTITY_NAME AS REGION_NAME, E.REGION_ID AS REGION_ID, E.ENTITY_ID
	FROM
	CARS_ENTITY E
	JOIN CARS_ENTITY R
	ON E.REGION_ID = R.ENTITY_ID
	AND R.ENTITY_TYPE_CD = ''REGION'' AND E.ENTITY_TYPE_CD=''STATE-TER''
	)X
WHERE P.218_FLAG=1 AND ENTITY_ID IN (', i_entity_list, ')'
 )
;

		
EXECUTE IMMEDIATE(v_sql);


SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_sql = '';

b_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	

		SET v_sql = CONCAT(
		'INSERT INTO CARS_TEMP_ANS_COLS', v_rand, ' ( ENTITY_NAME, REGION_NAME, REGION_ID, COL', v_whilecnt, 
		') 
		SELECT
		ENTITY_NAME, REGION_NAME, REGION_ID 
		,MAX(
		CASE WHEN Q.QPR_QUES_CODE = ''CB'' AND R.QPR_RESP_CHECK=1 THEN ''X''
		 	 WHEN Q.QPR_QUES_CODE = ''NB'' THEN R.QPR_RESP_NUM
			 WHEN Q.QPR_QUES_CODE = ''DB'' THEN R.QPR_RESP_DESC
			 WHEN Q.QPR_QUES_CODE = ''TB'' THEN R.QPR_RESP_TEXT			 
			 WHEN SUBSTR(Q.QPR_QUES_CODE, 1,1) = (''Y'') AND QPR_RESP_YES_NO >=1 THEN ''X''
			 WHEN SUBSTR(Q.QPR_QUES_CODE, 1,1) = (''N'') AND QPR_RESP_YES_NO >=1 THEN ''X''
			END
		) AS ANSWER
		FROM CARS_TEMP_AMEND_LIST', v_rand, ' M
        JOIN CARS_LEGACY_118_STPLAN_STATE_INFO_REF S ON S.STATE_NAME=M.ENTITY_NAME
        JOIN CARS_LEGACY_218_QPR_SECT_RESP_FINAL R ON R.QPR_STATE_CODE=S.STATE_CODE 
        JOIN CARS_LEGACY_218_QPR_SECT_QUEST Q ON R.QPR_SECT_QUEST_ID=Q.QPR_SECT_QUEST_ID
        JOIN CARS_PERIOD P ON  RIGHT(P.PERIOD_DESC,4)=Q.QPR_YEAR AND P.218_FLAG=1  AND P.PERIOD_ID= ', i_year ,'
		JOIN CARS_TEMP_SUBQUES_RESP_LIST  C ON R.QPR_SECT_QUEST_ID = C.QUEST_ID
		WHERE C.LIST_ORDER = ', v_whilecnt, 
		' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID,  C.GROUP_COL'
		)
		;
		
		EXECUTE IMMEDIATE (v_sql);
		
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 100 THEN
			LEAVE b_while;
		END IF;

	END WHILE b_while;
	
	
SET v_sql = CONCAT(
		'INSERT INTO CARS_TEMP_ANS_COLS', v_rand, ' (ENTITY_NAME, REGION_NAME, REGION_ID)
		SELECT M.ENTITY_NAME, M.REGION_NAME, M.REGION_ID
		FROM CARS_TEMP_AMEND_LIST', v_rand, ' M
		LEFT OUTER JOIN CARS_TEMP_ANS_COLS', v_rand, ' A
		ON M.ENTITY_NAME = A.ENTITY_NAME
		WHERE A.ENTITY_NAME IS NULL'
		);
		
	EXECUTE IMMEDIATE (v_sql);


SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_sql = '';

b1_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	

		SET v_sql = CONCAT(
		'INSERT INTO CARS_TEMP_HEADER_COLS', v_rand, ' ( ENTITY_NAME, REGION_NAME, REGION_ID,  HEADER', v_whilecnt, 
		') 
		SELECT
		''HEADER ROW'', NULL, NULL,  
		COL_HEADER
		FROM CARS_TEMP_SUBQUES_RESP_LIST   
		WHERE LIST_ORDER = ', v_whilecnt
		)
		;
		
		EXECUTE IMMEDIATE (v_sql);
		
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 100 THEN
			LEAVE b1_while;
		END IF;

	END WHILE b1_while;



SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_comma = ',';


SET v_sqlhdr = CONCAT('INSERT INTO CARS_TEMP_HEADERS', v_rand, ' SELECT ''State/Territory'', ''Region'', ''REGION_ID'',  ');
SET v_sqlans = CONCAT('INSERT INTO CARS_TEMP_ANSWERS', v_rand,' SELECT ENTITY_NAME, REGION_NAME, REGION_ID, ');


c1_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	
		IF v_whilecnt = v_iter THEN
			SET v_comma = '';
		END IF;
	
		SET v_sqlhdr = CONCAT(v_sqlhdr, ' MAX(HEADER', v_whilecnt, ')', v_comma);
		SET v_sqlans = CONCAT(v_sqlans, ' MAX(COL', v_whilecnt, ')', v_comma);
		
		SET v_whilecnt = v_whilecnt + 1;

		IF v_infinite = 100 THEN
			LEAVE c1_while;
		END IF;
	
	END WHILE c1_while;

SET v_sqlhdr = CONCAT(v_sqlhdr, ' FROM CARS_TEMP_HEADER_COLS', v_rand, ' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID');
SET v_sqlans = CONCAT(v_sqlans, ' FROM CARS_TEMP_ANS_COLS', v_rand, ' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID');


EXECUTE IMMEDIATE(v_sqlhdr);

EXECUTE IMMEDIATE(v_sqlans);


SET v_sql = '';
SET v_sql = CONCAT('SELECT * FROM CARS_TEMP_HEADERS', v_rand);

EXECUTE IMMEDIATE(v_sql);

SET v_sql = '';
SET v_sql = CONCAT('SELECT * FROM CARS_TEMP_ANSWERS', v_rand);


EXECUTE IMMEDIATE(v_sql);


UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_218_LEGACY_CONTENT_REPORTS');
		
	
END$$
DELIMITER ;