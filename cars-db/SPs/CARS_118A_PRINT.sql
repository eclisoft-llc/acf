DELIMITER $$
CREATE OR REPLACE PROCEDURE `CARS_118A_PRINT`(IN i_amend_id INT, OUT OutputString Longtext)
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
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_PRINT');
			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118A_PRINT', 'Started', NOW());	

	SET SESSION group_concat_max_len = 100000000;



DROP TABLE IF EXISTS tmp;
CREATE TABLE tmp 
					( 	
                    NumOrders Int, 
                  	SUBQUES_RESP_ID int,
     				PlanX text(225),
     				Tribe text(225),
                  	StringResponse longtext
                    );


CREATE OR REPLACE TEMPORARY TABLE amendtmp AS				
SELECT
	CONCAT('<amend', A.SUBQUES_ID,'>',IFNULL(CONCAT('Amended: Effective Date ',DATE_FORMAT(B.EFFECTIVE_DATE,'%m/%d/%Y'),CHAR(10)),''),'</amend', A.SUBQUES_ID,'>') AS AmendedString	
FROM
CARS_118A_SUBQUES AS A
LEFT JOIN
(SELECT DISTINCT SUBQUES_ID,EFFECTIVE_DATE FROM `CARS_118A_SUBQUES_AMENDMENT` WHERE HDR_AMEND_ID=i_amend_id) AS B
ON A.SUBQUES_ID=B.SUBQUES_ID
ORDER BY A.SUBQUES_ID;

INSERT INTO tmp( NumOrders, SUBQUES_RESP_ID, PlanX, Tribe ,StringResponse )

With
Info
AS
(
SELECT 	
	'plan118a' as Plan,
	H.ENTITY_NAME ,
	CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
	A.HDR_AMEND_ID,
	HA.SUBQUES_RESP_ID,
	Case When HA.ANS_BOOL IS NOT NULL Then HA.ANS_BOOL 
		When HA.ANS_INTEGER IS NOT NULL Then HA.ANS_INTEGER
			When HA.ANS_DEC IS NOT NULL Then HA.ANS_DEC
				When HA.ANS_TEXT IS NOT NULL Then CARS_CHAR_TO_HTML_MAP(HA.ANS_TEXT)
					When HA.ANS_DATE IS NOT NULL Then HA.ANS_DATE
						ELSE ' ' END AS Answer				
FROM
    CARS_118A_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118A_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118A_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID

WHERE
    A.HDR_AMEND_ID = i_amend_id
AND
    C.RESP_TYPE_CD NOT IN ('CHECKBOX', 'RADIO', 'DOCUMENT')

    UNION
    
SELECT
	'plan118a' as Plan,
	H.ENTITY_NAME ,
	CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
	A.HDR_AMEND_ID,
	HA.SUBQUES_RESP_ID,
	Case When HA.ANS_BOOL IS NOT NULL Then 'Document was provided by TLA'
		When HA.ANS_INTEGER IS NOT NULL Then 'Document was provided by TLA'
			When HA.ANS_DEC IS NOT NULL Then 'Document was provided by TLA'
				When HA.ANS_TEXT = '' Then 'Document was not provided by TLA'
					When HA.ANS_TEXT IS NOT NULL Then 'Document was provided by TLA'
						When HA.ANS_DATE IS NOT NULL Then 'Document was provided by TLA'
							ELSE 'Document was not provided by TLA' END AS Answer
FROM
    CARS_118A_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118A_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118A_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID
WHERE
    A.HDR_AMEND_ID = i_amend_id
AND
    C.RESP_TYPE_CD = 'DOCUMENT'
    
UNION
    
SELECT
	'plan118a' as Plan,
	H.ENTITY_NAME ,
	CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
	A.HDR_AMEND_ID,
	HA.SUBQUES_RESP_ID,
		Case When
			C.RESP_TYPE_CD = 'CHECKBOX' AND HA.ANS_TEXT IS NOT NULL AND TRIM(HA.ANS_TEXT) <> '' THEN '[x]' 
				When
    				C.RESP_TYPE_CD = 'RADIO' AND HA.ANS_TEXT IS NOT NULL AND TRIM(HA.ANS_TEXT) <> '' THEN '[x]'
						ELSE '[  ]' END AS Answer
FROM
    CARS_118A_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118A_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118A_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID

WHERE
    A.HDR_AMEND_ID = i_amend_id
AND
    C.RESP_TYPE_CD IN ('CHECKBOX', 'RADIO')
),

Response
AS

(
Select
	Row_Number() OVER (ORDER BY SUBQUES_RESP_ID ASC) AS NumOrder,
	SUBQUES_RESP_ID,
    CONCAT("<", Plan, ">") as PlanX,
	CONCAT("<entity>", CARS_CHAR_TO_HTML_MAP(ENTITY_NAME), "</entity>") as Tribe,
	CONCAT("<", Response, ">", Answer, "</", Response, ">") as StringResponse
From Info
 ),
 
 OrderResponse 
 AS
 
 (
  Select 
     Row_Number() OVER (ORDER BY NumOrder ASC) AS NumOrders, 
     SUBQUES_RESP_ID,
     PlanX,
     Tribe,
     StringResponse
  From 
     Response 
  Order By 
     Row_Number() OVER (ORDER BY NumOrder ASC) ASC
     )
     Select NumOrders, SUBQUES_RESP_ID, PlanX, Tribe ,StringResponse From OrderResponse Order By NumOrders;

DROP TABLE IF EXISTS Output_tmp;

CREATE TABLE Output_tmp
					(
                  	OutputString_C longtext 
                    );

INSERT INTO Output_tmp( OutputString_C )
     With
     Sponsor
 as
 
 (
SELECT
	N.HDR_AMEND_ID, H.ENTITY_NAME, I.TRIBE_TYPE_CD, I.PROGRAM_477_FLAG,
		CASE WHEN A.SUBQUES_RESP_ID= 1809 THEN '<resp1809nc></resp1809nc>'
     		WHEN A.SUBQUES_RESP_ID= 1811 THEN
     			CONCAT('<resp1811nc></resp1811nc>',
            		'<resp1811c>', COALESCE(ANS_TEXT,''), '</resp1811c>')
						ELSE NULL END as Constring
FROM 
     	CARS_118A_HDR_ANS A
JOIN 
     	CARS_118A_HDR_AMEND N
ON 
     	A.HDR_AMEND_ID = N.HDR_AMEND_ID
JOIN 
     	CARS_MODULE_PERIOD_HDR H
ON 
     	N.MODULE_HDR_ID = H.MODULE_HDR_ID
JOIN 
     	CARS_TRIBE_INFO I
ON 
     	H.ENTITY_ID = I.TRIBE_ID
AND 
     	H.PERIOD_ID = I.PERIOD_ID
WHERE 
     	A.SUBQUES_RESP_ID IN (1809, 1811)
AND 
     	COALESCE(I.PROGRAM_477_FLAG, 0) = 0
AND 
     	I.TRIBE_TYPE_CD = 'CON'
AND 
     	N.HDR_AMEND_ID = i_amend_id
     
UNION ALL
     
SELECT
		N.HDR_AMEND_ID, H.ENTITY_NAME, I.TRIBE_TYPE_CD, I.PROGRAM_477_FLAG,
			CASE WHEN A.SUBQUES_RESP_ID= 1809 THEN CONCAT('<resp1809nc>',COALESCE(C.DISCR_CHILD_COUNT,''),'</resp1809nc>')
    			 WHEN A.SUBQUES_RESP_ID= 1811 THEN
      				CONCAT('<resp1811nc>', COALESCE(ANS_TEXT,''), '</resp1811nc>', '<resp1811c></resp1811c>')
						ELSE NULL END as Constring
FROM 
     	CARS_118A_HDR_ANS A
JOIN 
     	CARS_118A_HDR_AMEND N
ON 
     	A.HDR_AMEND_ID = N.HDR_AMEND_ID
JOIN 
     	CARS_MODULE_PERIOD_HDR H
ON 
     	N.MODULE_HDR_ID = H.MODULE_HDR_ID
JOIN 
     	CARS_TRIBE_INFO I
ON 
     	H.ENTITY_ID = I.TRIBE_ID
AND 
     	H.PERIOD_ID = I.PERIOD_ID
LEFT OUTER JOIN 
     	CARS_118A_CHILD_COUNT C
ON 
     	N.HDR_AMEND_ID = C.HDR_AMEND_ID
AND 
     	H.ENTITY_ID = C.ENTITY_ID
WHERE 
     	A.SUBQUES_RESP_ID IN (1809, 1811)
AND 
     	COALESCE(I.PROGRAM_477_FLAG, 0) = 0
AND 
     	I.TRIBE_TYPE_CD <> 'CON'
AND 
     	N.HDR_AMEND_ID = i_amend_id
     
UNION ALL
     
SELECT
	N.HDR_AMEND_ID, H.ENTITY_NAME, I.TRIBE_TYPE_CD, I.PROGRAM_477_FLAG,
	CASE WHEN A.SUBQUES_RESP_ID= 1817 THEN '<resp1817nc></resp1817nc>'
     	WHEN A.SUBQUES_RESP_ID= 1819 THEN
     		CONCAT('<resp1819nc></resp1819nc>',
            	'<resp1819c>', COALESCE(ANS_TEXT,''), '</resp1819c>')
					ELSE NULL END as Constring
FROM 
     	CARS_118A_HDR_ANS A
JOIN 
     	CARS_118A_HDR_AMEND N
ON 
     	A.HDR_AMEND_ID = N.HDR_AMEND_ID
JOIN 
     	CARS_MODULE_PERIOD_HDR H
ON 
     	N.MODULE_HDR_ID = H.MODULE_HDR_ID
JOIN 
     	CARS_TRIBE_INFO I
ON 
     	H.ENTITY_ID = I.TRIBE_ID
AND 
     	H.PERIOD_ID = I.PERIOD_ID
WHERE 
     	A.SUBQUES_RESP_ID IN (1817, 1819)
AND 
     	COALESCE(I.PROGRAM_477_FLAG, 0) = 1
AND 
     	I.TRIBE_TYPE_CD = 'CON'
AND 
     	N.HDR_AMEND_ID = i_amend_id
     
UNION ALL		
     
SELECT
	N.HDR_AMEND_ID, H.ENTITY_NAME, I.TRIBE_TYPE_CD, I.PROGRAM_477_FLAG,
		CASE WHEN A.SUBQUES_RESP_ID = 1817 THEN CONCAT('<resp1817nc>',COALESCE(C.DISCR_CHILD_COUNT,''),'</resp1817nc>')
    		 WHEN A.SUBQUES_RESP_ID = 1819 THEN
     			CONCAT('<resp1819nc>', COALESCE(ANS_TEXT,''), '</resp1819nc>',
            		'<resp1819c></resp1819c>')
						ELSE NULL END as Constring
FROM 
     	CARS_118A_HDR_ANS A
JOIN 
     	CARS_118A_HDR_AMEND N
ON 
     	A.HDR_AMEND_ID = N.HDR_AMEND_ID
JOIN 
     	CARS_MODULE_PERIOD_HDR H
ON 
     	N.MODULE_HDR_ID = H.MODULE_HDR_ID
JOIN 
     	CARS_TRIBE_INFO I
ON 
     	H.ENTITY_ID = I.TRIBE_ID
AND 
     	H.PERIOD_ID = I.PERIOD_ID
LEFT OUTER JOIN 
     	CARS_118A_CHILD_COUNT C
ON 
     	N.HDR_AMEND_ID = C.HDR_AMEND_ID
AND 
     	H.ENTITY_ID = C.ENTITY_ID
WHERE 
     	A.SUBQUES_RESP_ID IN (1817, 1819)
AND 
     	COALESCE(I.PROGRAM_477_FLAG, 0) = 1
AND 
     	I.TRIBE_TYPE_CD <> 'CON'
AND 
     	N.HDR_AMEND_ID = i_amend_id
     ),
 
 Child
AS

(
SELECT Distinct
    I.TRIBE_TYPE_CD,
'childcounts' as Plan,
CONCAT('member=', "'", CARS_CHAR_TO_HTML_MAP(CE.ENTITY_NAME), "'") as ENTITY_NAME ,
Case When
    CC.MAND_CHILD_COUNT IS NULL Then "' '" Else CONCAT("'", CC.MAND_CHILD_COUNT, "'") END as Mand_ChildCount,
Case When
    CC.DISCR_CHILD_COUNT IS NULL Then "' '" Else CONCAT("'", CC.DISCR_CHILD_COUNT, "'") END as Discr_ChildCount,
Case When
    CC.DECLR_DOC_ID IS NULL Then "'Document was not provided by TLA'" Else "'Document was provided by TLA'" END as Declr_ChildCount,
Case When
    CC.DEMO_DOC_ID IS NULL Then "'Document was not provided by TLA'" Else "'Document was provided by TLA'" END as Demo_ChildCount
FROM
    CARS_118A_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118A_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118A_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID
Left Outer Join
    CARS_118A_CHILD_COUNT as CC
    	on A.HDR_AMEND_ID = CC.HDR_AMEND_ID
Left Outer Join
	CARS_ENTITY as CE
    	ON
        CC.ENTITY_ID = CE.ENTITY_ID
JOIN 
    	CARS_TRIBE_INFO I
ON 
    	H.ENTITY_ID = I.TRIBE_ID
AND 
    	H.PERIOD_ID = I.PERIOD_ID
WHERE
    I.TRIBE_TYPE_CD = 'CON'
    AND
    A.HDR_AMEND_ID = i_amend_id
    ),
    
 ChildCount
 AS
 
 (
  Select
     Case When TRIBE_TYPE_CD = 'CON' Then CONCAT("<", Plan, ' ', ENTITY_NAME, ' ',  'mandatory= ' ,Mand_ChildCount, ' ', 'discretionary= ' ,Discr_ChildCount,' ', 'declaration= ', Declr_ChildCount,' ', 'demonstration= ', Demo_ChildCount,"/>") ELSE "<childcounts member=' ' mandatory= ' ' discretionary= ' ' declaration= ' ' demonstration= ' '/>" END AS CStringResponse
     From Child
    ),
    
    PlanStatus
    AS
    
    (
Select Distinct
	Case When P.STATUS_TEXT = 'In Review' Then 'Certified' Else P.STATUS_TEXT END as PlanStatus,
		Case When P.STATUS_TEXT = 'In Review' Then S.LAST_UPD_TS Else P.LAST_UPD_TS END as PlanDate,
			Row_Number() OVER (PARTITION BY P.STATUS_TEXT ORDER BY P.LAST_UPD_TS, S.LAST_UPD_TS DESC) AS Priority
From 
	CARS_MODULE_PERIOD_HDR as P
Left Join 
	CARS_118A_HDR_AMEND as N 
On 
	P.MODULE_HDR_ID = N.MODULE_HDR_ID
Left Join 
	CARS_118A_HDR_STATUS as S
On 
	P.MODULE_HDR_ID = S.MODULE_HDR_ID
Where 
	N.HDR_AMEND_ID = i_amend_id
Group By 
	S.STATUS_TEXT
        )
 Select
 	Planx as Output
 From
 	tmp
    
 Union 
    
 Select
 	Tribe as Output
 From
 	tmp
    
 Union 
    
 Select
 	StringResponse as Output
 From
 	tmp
	 Union 
    
 Select
 	AmendedString as Output
 From
 	amendtmp
    
 Union 
    
 Select
	Case When
    CStringResponse IS NUll THEN  "<childcounts member=' ' mandatory= ' ' discretionary= ' ' declaration= ' ' demonstration= ' '/>"
    Else CStringResponse End as Output
 From
 ChildCount
    
 Union 
    
    Select
    Constring as Output
    From
    Sponsor
    
    Union 
    
    Select 
    CONCAT('<planstatus>', PlanStatus ,'</planstatus>') as Output
    From 
    PlanStatus
    Where Priority = 1
    
    Union 
    
    Select 
	CONCAT('<planstatusdate>', PlanDate ,'</planstatusdate>') as Output
    From 
    PlanStatus
    Where Priority = 1

   Union 
 		Select
		'</plan118a>' as Output
;
     

SET SESSION group_concat_max_len = 1000000;

Select
    	Group_Concat( OutputString_C
                   SEPARATOR '
                    ') as 'Output' INTO OutputString 
    			From
    			Output_tmp
;

UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118A_PRINT')
;

END$$
DELIMITER ;