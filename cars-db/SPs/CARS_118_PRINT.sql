DROP PROCEDURE IF EXISTS `CARS_118_PRINT`;
DELIMITER $$
CREATE PROCEDURE `CARS_118_PRINT`(IN i_amend_id INT, OUT OutputString Longtext)
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
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_PRINT');
			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_PRINT', 'Started', NOW());	
SET SESSION group_concat_max_len = 10000000;


DROP TABLE IF EXISTS tmp118;
CREATE TABLE tmp118 
					( 	
                    NumOrders Int, 
                  	SUBQUES_RESP_ID int,
     				PlanX text(225),
					State text(225),
					AmendNumber text(225),
                  	StringResponse longtext
                    );

CREATE OR REPLACE TEMPORARY TABLE amendtmp AS				
SELECT
	CONCAT('<amend', A.SUBQUES_ID,'>',IFNULL(CONCAT('Amended: Effective Date ',DATE_FORMAT(B.EFFECTIVE_DATE,'%m/%d/%Y'),CHAR(10)),''),'</amend', A.SUBQUES_ID,'>') AS AmendedString	
FROM
CARS_118_SUBQUES AS A
LEFT JOIN
(SELECT DISTINCT SUBQUES_ID,EFFECTIVE_DATE FROM `CARS_118_SUBQUES_AMENDMENT` WHERE HDR_AMEND_ID=i_amend_id) AS B
ON A.SUBQUES_ID=B.SUBQUES_ID
ORDER BY A.SUBQUES_ID;

INSERT INTO tmp118( NumOrders, SUBQUES_RESP_ID, PlanX, State, AmendNumber,StringResponse )


With
Info
as
(
SELECT
'plan118' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
A.AMEND_SEQ_NUM,
HA.SUBQUES_RESP_ID,
Case When HA.ANS_BOOL IS NOT NULL Then HA.ANS_BOOL
When HA.ANS_INTEGER IS NOT NULL Then HA.ANS_INTEGER
When HA.ANS_DEC IS NOT NULL Then HA.ANS_DEC
When HA.ANS_TEXT IS NOT NULL Then CARS_CHAR_TO_HTML_MAP( HA.ANS_TEXT)
When HA.ANS_DATE IS NOT NULL Then HA.ANS_DATE
ELSE ' ' END AS Answer
FROM
    CARS_118_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID
JOIN CARS_ENTITY I
        ON H.ENTITY_ID = I.ENTITY_ID 
        AND I.ENTITY_TYPE_CD='STATE-TER'
WHERE
    A.HDR_AMEND_ID = i_amend_id
AND
    C.RESP_TYPE_CD NOT IN ('CHECKBOX', 'RADIO', 'DOCUMENT')
UNION
SELECT
'plan118' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
A.AMEND_SEQ_NUM,
HA.SUBQUES_RESP_ID,
Case When HA.ANS_BOOL IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_INTEGER IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_DEC IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_TEXT IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_DATE IS NOT NULL Then 'Document was provided by TLA'
ELSE 'Document was not provided by TLA' END AS Answer
FROM
    CARS_118_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118_SUBQUES_RESP  C
		ON HA.SUBQUES_RESP_ID = C.SUBQUES_RESP_ID
JOIN CARS_ENTITY I
        ON H.ENTITY_ID = I.ENTITY_ID 
        AND I.ENTITY_TYPE_CD='STATE-TER'
WHERE
    A.HDR_AMEND_ID = i_amend_id
AND
    C.RESP_TYPE_CD = 'DOCUMENT'
UNION
SELECT
'plan118' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
A.AMEND_SEQ_NUM,
HA.SUBQUES_RESP_ID,
Case When
	C.RESP_TYPE_CD = 'CHECKBOX' AND ANS_TEXT IS NOT NULL AND TRIM(ANS_TEXT) <> '' THEN '[x]'
When
    C.RESP_TYPE_CD = 'RADIO' AND ANS_TEXT IS NOT NULL AND TRIM(ANS_TEXT) <> '' THEN '[x]'
ELSE '[  ]' END AS Answer
FROM
    CARS_118_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_118_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_118_SUBQUES_RESP  C
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
CONCAT("<", IFNULL(Plan,''), ">") as PlanX,
CONCAT("<entity>", IFNULL(ENTITY_NAME,''), "</entity>") AS State,
CASE WHEN AMEND_SEQ_NUM>1 THEN CONCAT("<amendnumber>Amendment ", AMEND_SEQ_NUM-1, "</amendnumber>") ELSE "<amendnumber>Initial Plan</amendnumber>" END AS amendnumber,
CONCAT("<", IFNULL(Response,''), ">", IFNULL(Answer,''), "</", IFNULL(Response,''), ">") as StringResponse
From Info
 ),
 
 OrderResponse 
 AS
 
 (
  Select 
     Row_Number() OVER (ORDER BY NumOrder ASC) AS NumOrders, 
     SUBQUES_RESP_ID,
     PlanX,
     State,
	 amendnumber,
     StringResponse
  From 
     Response 
  Order By 
     Row_Number() OVER (ORDER BY NumOrder ASC) ASC
     )
     Select NumOrders, SUBQUES_RESP_ID, PlanX, State ,amendnumber,StringResponse From OrderResponse Order By NumOrders;
 
 DROP TABLE IF EXISTS Output_tmp118;

CREATE TABLE Output_tmp118
					(
                  	OutputString_C longtext 
               );
 
 INSERT INTO Output_tmp118( OutputString_C )
 
 WITH  PlanStatus
    AS(
Select Distinct  
Case When N.APPR_TS IS NOT NULL THEN 'Approved' WHEN P.STATUS_TEXT = 'In Review' Then 'Certified' Else P.STATUS_TEXT END as PlanStatus,	   
CASE WHEN D.PERIOD_DESC='FY 2022-2024' THEN 

	Case WHEN N.AMEND_SEQ_NUM=1 THEN NULL 
	When N.APPR_TS IS NOT NULL AND N.AMEND_SEQ_NUM >1 THEN CONCAT('as of ',N.APPR_TS,' GMT')  When P.STATUS_TEXT = 'In Review' AND N.AMEND_SEQ_NUM >1 
	Then CONCAT('as of ',N.SUBMIT_TS,' GMT') Else CONCAT('as of ',P.LAST_UPD_TS,' GMT') END
ELSE
    Case When N.APPR_TS IS NOT NULL THEN CONCAT('as of ',N.APPR_TS,' GMT')  When P.STATUS_TEXT = 'In Review' Then CONCAT('as of ',N.SUBMIT_TS,' GMT') 
	Else CONCAT('as of ',P.LAST_UPD_TS,' GMT') END 
END as PlanDate,
1 AS Priority
From 
CARS_MODULE_PERIOD_HDR as P
Left Join 
CARS_118_HDR_AMEND as N 
On 
P.MODULE_HDR_ID = N.MODULE_HDR_ID
JOIN CARS_PERIOD AS D ON D.PERIOD_ID=P.PERIOD_ID AND D.118_FLAG=1
Where 
N.HDR_AMEND_ID = i_amend_id
        )
		
 Select
 Planx as Output
 From
 tmp118
 Union
 Select
 State as Output
 From
 tmp118
 Union
 Select
 amendnumber as Output
 From
 tmp118
 Union
 Select
 StringResponse as Output
 From
 tmp118
 	 Union 
    
 Select
 	AmendedString as Output
 From
 	amendtmp

	    Union 
    
    Select 
    CONCAT('<planstatus>', IFNULL(PlanStatus,'') ,'</planstatus>') as Output
    From 
    PlanStatus
    Where Priority = 1
    
    Union 
    
    Select 
	CONCAT('<planstatusdate>', IFNULL(PlanDate,'') ,'</planstatusdate>') as Output
    From 
    PlanStatus
    Where Priority = 1
	
   Union  
 Select
'</plan118>' as Output;

SET SESSION group_concat_max_len = 1000000;

Select
    	Group_Concat( OutputString_C
                   SEPARATOR '
                    ') as 'Output' INTO OutputString 
    			From
    			Output_tmp118
;


 UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_PRINT');
		
END$$
DELIMITER ;