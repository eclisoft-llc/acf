
DROP PROCEDURE IF EXISTS CARS_118_REVIEW_PROGRESS_REPORT;

DELIMITER $$
CREATE PROCEDURE CARS_118_REVIEW_PROGRESS_REPORT(IN i_amend_where_cond TEXT, IN excludedApprovedAmendments INTEGER)
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
DECLARE v_amendmentsql TEXT DEFAULT '';
DECLARE v_module_meta_id INT DEFAULT 0;
DECLARE v_subques_amendment_join1 TEXT DEFAULT '';
DECLARE v_subques_amendment_join2 TEXT DEFAULT '';


	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_REVIEW_PROGRESS_REPORT');		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_REVIEW_PROGRESS_REPORT', 'Started', NOW());	

###########
SELECT SUBSTR(CAST(RAND() * 100000000 AS VARCHAR(50)), 1, 7) INTO v_rand FROM DUAL;


DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_LIST;

SET v_module_meta_id= 
	(SELECT DISTINCT MODULE_META_ID FROM CARS_MODULE_PERIOD_HDR H
	JOIN CARS_118_HDR_AMEND A ON A.MODULE_HDR_ID=H.MODULE_HDR_ID
	WHERE A.HDR_AMEND_ID IN (i_amend_where_cond) 
	);
	
IF v_module_meta_id =12 THEN 		
	SET v_subques_amendment_join1= 'JOIN CARS_118_SUBQUES_AMENDMENT SA ON SA.HDR_AMEND_ID=A.HDR_AMEND_ID AND SA.IS_AMENDED=1';
	SET v_subques_amendment_join2= 'JOIN CARS_118_SUBQUES_AMENDMENT SA ON SA.HDR_AMEND_ID=R.HDR_AMEND_ID AND SA.SUBQUES_ID=R.SUBQUES_ID AND SA.IS_AMENDED=1';
END IF;

SET v_sql = '';
SET v_sql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SECT_LIST   
AS 
SELECT
RANK() OVER(ORDER BY SECT_ID) AS LIST_ORDER, SECT_ID, SECT_NAV_TEXT
FROM CARS_118_SECT S
WHERE S.SECT_ID NOT IN (1,10,20,31) AND S.MODULE_META_ID = ',v_module_meta_id,' ;'
)
;

IF excludedApprovedAmendments=1 THEN SET v_amendmentsql=' AND A.APPR_TS IS NULL';
END IF;

EXECUTE IMMEDIATE(v_sql);


SELECT COUNT(DISTINCT LIST_ORDER) INTO v_iter FROM CARS_TEMP_SECT_LIST;


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_STATUS_COLS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);



SET v_whilecnt = 1;
SET v_createtable = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SECT_STATUS_COLS', v_rand, '  
( ENTITY_NAME TEXT NULL, REGION_NAME TEXT NULL, REGION_ID INT NULL,AMENDMENT_NUMBER TEXT NULL, ');

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
		
		IF v_infinite = 60 THEN
			LEAVE a_while;
		END IF;
		
	END WHILE a_while;

SET v_collist = CONCAT(v_collist, ');');



EXECUTE IMMEDIATE(v_collist);


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_STATUS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_crsql = '';
SET v_crsql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SECT_STATUS', v_rand, ' AS SELECT * FROM CARS_TEMP_SECT_STATUS_COLS', v_rand);

EXECUTE IMMEDIATE (v_crsql);

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_HEADER_COLS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);

SET v_whilecnt = 1;
SET v_comma = ',';
SET v_collist = '';
SET v_infinite = 0;
SET v_createtable = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SECT_HEADER_COLS', v_rand, '  
( ENTITY_NAME TEXT NULL, REGION_NAME TEXT NULL, REGION_ID TEXT NULL,AMENDMENT_NUMBER TEXT NULL, ');


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
		
		IF v_infinite = 50 THEN
			LEAVE a1_while;
		END IF;
		
	END WHILE a1_while;

SET v_collist = CONCAT(v_collist, ');');


EXECUTE IMMEDIATE(v_collist);

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_HEADERS', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_crsql = '';
SET v_crsql = CONCAT('CREATE TEMPORARY TABLE CARS_TEMP_SECT_HEADERS', v_rand, ' AS SELECT * FROM CARS_TEMP_SECT_HEADER_COLS', v_rand);

EXECUTE IMMEDIATE (v_crsql);


SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SECT_AMEND_LIST', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_sql = '';
SET v_sql = CONCAT('
CREATE TEMPORARY TABLE CARS_TEMP_SECT_AMEND_LIST', v_rand, ' 
AS 
SELECT
DISTINCT H.ENTITY_NAME, A.HDR_AMEND_ID, CASE WHEN A.AMEND_SEQ_NUM>1 THEN CONCAT(''Amendment #'',A.AMEND_SEQ_NUM-1) ELSE ''Initial Submission'' END AS AMENDMENT_NUMBER, R.ENTITY_NAME AS REGION_NAME, E.REGION_ID AS REGION_ID
FROM CARS_MODULE_PERIOD_HDR H
JOIN CARS_118_HDR_AMEND A
ON H.MODULE_HDR_ID = A.MODULE_HDR_ID ',
v_subques_amendment_join1,
' LEFT OUTER JOIN CARS_TRIBE_INFO T
ON H.PERIOD_ID = T.PERIOD_ID
AND H.ENTITY_ID = T.TRIBE_ID
JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
JOIN CARS_ENTITY R
ON E.REGION_ID = R.ENTITY_ID
AND R.ENTITY_TYPE_CD = ''REGION''
WHERE A.HDR_AMEND_ID IN (', i_amend_where_cond, ')',v_amendmentsql)
;

EXECUTE IMMEDIATE(v_sql);	
		

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_SUBQUES_REVIEW_STATUS_PCT', v_rand);
EXECUTE IMMEDIATE (v_dropsql);

SET v_sql = '';
SET v_sql = CONCAT('
CREATE TEMPORARY TABLE CARS_TEMP_SUBQUES_REVIEW_STATUS_PCT', v_rand, ' 
AS 
SELECT
H.ENTITY_ID, H.ENTITY_NAME,
A.HDR_AMEND_ID,
CASE WHEN A.AMEND_SEQ_NUM>1 THEN CONCAT(''Amendment #'',A.AMEND_SEQ_NUM-1) ELSE ''Initial Submission'' END AS AMENDMENT_NUMBER,
S.SECT_ID, 
SUM(CASE WHEN R.Recommendation_RST = ''Recommendation Review'' AND Recommendation_DST <> ''N/A'' THEN 1 ELSE 0 END) AS REVIEWABLE,
SUM(
CASE WHEN (R.Validation_RST = ''Validation Review'' AND R.Validation_DST = ''Agree'' AND H.MODULE_META_ID=12 ) THEN 1
	 WHEN (R.Recommendation_RST = ''Recommendation Review'' 
			AND R.COMPLIANCE_STATUS_TEXT IN( ''Was compliant, changing to NON-compliant'', ''Was NON-compliant, is still NON-compliant'') 
			AND R.Validation_RST ="Validation Review" 
			AND R.Validation_DST =''Agree'' 
			AND H.MODULE_META_ID=25 ) THEN 1
		 
	 WHEN (R.VALIDATION_CD = ''PANEL'' 
			AND R.VALIDATED_BY_PANEL_FLAG =1 
			AND R.Validation_RST= ''Validation Review''
			AND R.RECOMMENDATION_FINAL_FLAG=1
			AND R.Recommendation_RST=''Recommendation Review''
			AND H.MODULE_META_ID=25 ) THEN 1
		 
	 WHEN ( R.COMPLIANCE_STATUS_TEXT NOT IN(''Was compliant, changing to NON-compliant'',''Was NON-compliant, is still NON-compliant'') 
			AND R.Recommendation_DST<>''N/A''
			AND R.Recommendation_RST=''Recommendation Review''
			AND R.RECOMMENDATION_FINAL_FLAG=1
			AND H.MODULE_META_ID=25 ) THEN 1
		 ELSE 0 	END			
	) AS COMPLETE,

ROUND(SUM(CASE WHEN (R.Validation_RST = ''Validation Review'' AND R.Validation_DST = ''Agree'' AND H.MODULE_META_ID=12 ) THEN 1
	 WHEN (R.Recommendation_RST = ''Recommendation Review'' 
			AND R.COMPLIANCE_STATUS_TEXT IN( ''Was compliant, changing to NON-compliant'', ''Was NON-compliant, is still NON-compliant'') 
			AND R.Validation_RST ="Validation Review" 
			AND R.Validation_DST =''Agree'' 
			AND H.MODULE_META_ID=25 ) THEN 1
		  
	 WHEN (R.VALIDATION_CD = ''PANEL'' 
			AND R.VALIDATED_BY_PANEL_FLAG =1 
			AND R.Validation_RST= ''Validation Review''
			AND R.RECOMMENDATION_FINAL_FLAG=1
			AND R.Recommendation_RST=''Recommendation Review''
			AND H.MODULE_META_ID=25 ) THEN 1
		  
	 WHEN ( R.COMPLIANCE_STATUS_TEXT NOT IN(''Was compliant, changing to NON-compliant'',''Was NON-compliant, is still NON-compliant'') 
			AND R.Recommendation_DST<>''N/A''
			AND R.Recommendation_RST=''Recommendation Review''
			AND R.RECOMMENDATION_FINAL_FLAG=1
			AND H.MODULE_META_ID=25 ) THEN 1
		 ELSE 0 	END) / 
(SUM(CASE WHEN R.Recommendation_RST = ''Recommendation Review'' AND R.Recommendation_DST <> ''N/A'' THEN 1 ELSE 0 END)) * 100, 2) AS SECT_PCT

FROM CARS_MODULE_PERIOD_HDR H
JOIN CARS_118_HDR_AMEND A
ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN 
	(
	SELECT 
	SR1.HDR_AMEND_ID,
	SR1.SUBQUES_ID,
	SR1.REVIEW_STATUS_TEXT AS Validation_RST,
	SR.REVIEW_STATUS_TEXT AS Recommendation_RST,
	SR1.REVIEW_DECISION_TEXT Validation_DST,
	SR.REVIEW_DECISION_TEXT Recommendation_DST,
	SQ.VALIDATION_CD ,
	SR.VALIDATED_BY_PANEL_FLAG,
	SR.RECOMMENDATION_FINAL_FLAG ,
	SR.COMPLIANCE_STATUS_TEXT 
	FROM CARS_118_HDR_SUBQUES_REVIEW SR
	JOIN CARS_118_HDR_SUBQUES_REVIEW SR1 ON SR.HDR_AMEND_ID=SR1.HDR_AMEND_ID AND SR.SUBQUES_ID=SR1.SUBQUES_ID AND SR1.REVIEW_STATUS_TEXT=''Validation Review''
	JOIN CARS_118_SUBQUES SQ ON SR.SUBQUES_ID=SQ.SUBQUES_ID 
	WHERE 
	SR.REVIEW_STATUS_TEXT=''Recommendation Review''
	) R
ON A.HDR_AMEND_ID = R.HDR_AMEND_ID
JOIN CARS_118_SUBQUES SQ ON R.SUBQUES_ID = SQ.SUBQUES_ID ',
v_subques_amendment_join2,
' JOIN CARS_118_QUES Q ON SQ.QUES_ID = Q.QUES_ID
JOIN CARS_118_SUBSECT S ON Q.SUBSECT_ID = S.SUBSECT_ID
WHERE A.HDR_AMEND_ID IN (', i_amend_where_cond, ')',v_amendmentsql,' 
 GROUP BY 1,2,3,4,5'
)
;

EXECUTE IMMEDIATE(v_sql);

SET v_dropsql = '';
SET v_dropsql = CONCAT('DROP TEMPORARY TABLE IF EXISTS CARS_TEMP_ALL_STATUSES', v_rand);
EXECUTE IMMEDIATE (v_dropsql);


SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_sql = '';

b_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	

		SET v_sql = CONCAT(
		'INSERT INTO CARS_TEMP_SECT_STATUS_COLS', v_rand, ' ( ENTITY_NAME, REGION_NAME, REGION_ID,AMENDMENT_NUMBER, COL', v_whilecnt, 
		') 
		SELECT
		M.ENTITY_NAME, REGION_NAME, REGION_ID, M.AMENDMENT_NUMBER,
		CASE WHEN S.REVIEWABLE = 0 THEN ''NOT REQUIRED'' 
		     WHEN S.REVIEWABLE = S.COMPLETE THEN ''COMPLETE'' ELSE S.SECT_PCT END
		FROM CARS_TEMP_SECT_AMEND_LIST', v_rand, ' M
		JOIN CARS_TEMP_SECT_LIST C
		ON 1 = 1
		LEFT OUTER JOIN CARS_TEMP_SUBQUES_REVIEW_STATUS_PCT', v_rand, '  S
		ON M.HDR_AMEND_ID = S.HDR_AMEND_ID
		AND C.SECT_ID = S.SECT_ID
		WHERE C.LIST_ORDER = ', v_whilecnt, 
		' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID'
		)
		;
		
		EXECUTE IMMEDIATE (v_sql);
				
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 60 THEN
			LEAVE b_while;
		END IF;

	END WHILE b_while;
	

SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_sql = '';

b1_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	

		SET v_sql = CONCAT(
		'INSERT INTO CARS_TEMP_SECT_HEADER_COLS', v_rand, ' ( ENTITY_NAME, REGION_NAME, REGION_ID,AMENDMENT_NUMBER, HEADER', v_whilecnt, 
		') 
		SELECT
		''HEADER ROW'', NULL, NULL, NULL, 
		SECT_NAV_TEXT
		FROM CARS_TEMP_SECT_LIST   
		WHERE LIST_ORDER = ', v_whilecnt
		)
		;
		
		EXECUTE IMMEDIATE (v_sql);
		
		SET v_whilecnt = v_whilecnt + 1;
		
		IF v_infinite = 50 THEN
			LEAVE b1_while;
		END IF;

	END WHILE b1_while;



SET v_infinite = 0;
SET v_whilecnt = 1;
SET v_comma = ',';


SET v_sqlhdr = CONCAT('INSERT INTO CARS_TEMP_SECT_HEADERS', v_rand, ' SELECT ''State/Territory'', ''Region'', ''REGION_ID'',''Amendment Number'',  ');
SET v_sqlans = CONCAT('INSERT INTO CARS_TEMP_SECT_STATUS', v_rand,' SELECT ENTITY_NAME, REGION_NAME, REGION_ID,AMENDMENT_NUMBER, ');


c1_while:
	WHILE v_whilecnt <= v_iter DO
		SET v_infinite = v_infinite + 1;
	
		IF v_whilecnt = v_iter THEN
			SET v_comma = '';
		END IF;
	
		SET v_sqlhdr = CONCAT(v_sqlhdr, ' MAX(HEADER', v_whilecnt, ')', v_comma);
		SET v_sqlans = CONCAT(v_sqlans, ' MAX(COL', v_whilecnt, ')', v_comma);
		
		SET v_whilecnt = v_whilecnt + 1;

		IF v_infinite = 50 THEN
			LEAVE c1_while;
		END IF;
	
	END WHILE c1_while;

SET v_sqlhdr = CONCAT(v_sqlhdr, ' FROM CARS_TEMP_SECT_HEADER_COLS', v_rand, ' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID, AMENDMENT_NUMBER');
SET v_sqlans = CONCAT(v_sqlans, ' FROM CARS_TEMP_SECT_STATUS_COLS', v_rand, ' GROUP BY ENTITY_NAME, REGION_NAME, REGION_ID, AMENDMENT_NUMBER');


EXECUTE IMMEDIATE(v_sqlhdr);

EXECUTE IMMEDIATE(v_sqlans);


SET v_sql = '';
SET v_sql = CONCAT('SELECT * FROM CARS_TEMP_SECT_HEADERS', v_rand);

EXECUTE IMMEDIATE(v_sql);

SET v_sql = '';
SET v_sql = CONCAT('SELECT * FROM CARS_TEMP_SECT_STATUS', v_rand);

EXECUTE IMMEDIATE(v_sql);

#################
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_REVIEW_PROGRESS_REPORT');
		
	
END$$
DELIMITER ;