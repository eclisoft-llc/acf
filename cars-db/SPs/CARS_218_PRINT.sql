DELIMITER $$
CREATE OR REPLACE PROCEDURE `CARS_218_PRINT`(IN i_amend_id INT, OUT OutputString Longtext)
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
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_218_PRINT');
			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_218_PRINT', 'Started', NOW());	
SET SESSION group_concat_max_len = 10000000;


DROP TABLE IF EXISTS tmp218;
CREATE TABLE tmp218 
					( 	
                    NumOrders Int, 
                  	SUBQUES_RESP_ID int,
     				PlanX text(225),
					State text(225),
                  	StringResponse longtext
                    );

INSERT INTO tmp218( NumOrders, SUBQUES_RESP_ID, PlanX, State, StringResponse )


With
Info
as
(
SELECT
'plan218' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
HA.SUBQUES_RESP_ID,
Case When HA.ANS_BOOL IS NOT NULL Then HA.ANS_BOOL
When HA.ANS_INTEGER IS NOT NULL Then HA.ANS_INTEGER
When HA.ANS_DEC IS NOT NULL Then HA.ANS_DEC
When HA.ANS_TEXT IS NOT NULL Then CARS_CHAR_TO_HTML_MAP( HA.ANS_TEXT)
When HA.ANS_DATE IS NOT NULL Then HA.ANS_DATE
ELSE ' ' END AS Answer
FROM
    CARS_218_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_218_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_218_SUBQUES_RESP  C
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
'plan218' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
HA.SUBQUES_RESP_ID,
Case When HA.ANS_BOOL IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_INTEGER IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_DEC IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_TEXT IS NOT NULL Then 'Document was provided by TLA'
When HA.ANS_DATE IS NOT NULL Then 'Document was provided by TLA'
ELSE 'Document was not provided by TLA' END AS Answer
FROM
    CARS_218_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_218_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_218_SUBQUES_RESP  C
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
'plan218' as Plan,
H.ENTITY_NAME ,
CONCAT('resp', HA.SUBQUES_RESP_ID) as Response,
A.HDR_AMEND_ID,
HA.SUBQUES_RESP_ID,
Case When
	C.RESP_TYPE_CD = 'CHECKBOX' AND ANS_TEXT IS NOT NULL AND TRIM(ANS_TEXT) <> '' THEN '[x]'
When
    C.RESP_TYPE_CD = 'RADIO' AND ANS_TEXT IS NOT NULL AND TRIM(ANS_TEXT) <> '' THEN '[x]'
ELSE '[  ]' END AS Answer
FROM
    CARS_218_HDR_AMEND A
JOIN
    CARS_MODULE_PERIOD_HDR H
    	ON H.MODULE_HDR_ID = A.MODULE_HDR_ID
JOIN
    CARS_218_HDR_ANS HA
    	ON HA.HDR_AMEND_ID = A.HDR_AMEND_ID
JOIN
    CARS_218_SUBQUES_RESP  C
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
CONCAT("<entity>", ENTITY_NAME, "</entity>") as State,
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
     State,
     StringResponse
  From 
     Response 
  Order By 
     Row_Number() OVER (ORDER BY NumOrder ASC) ASC
     )
     Select NumOrders, SUBQUES_RESP_ID, PlanX, State ,StringResponse From OrderResponse Order By NumOrders;
 
 DROP TABLE IF EXISTS Output_tmp218;

CREATE TABLE Output_tmp218
					(
                  	OutputString_C longtext 
               );
 
 INSERT INTO Output_tmp218( OutputString_C )
 
 WITH  PlanStatus
    AS(
       Select Distinct
Case When P.STATUS_TEXT = 'In Review' Then 'Certified' Else P.STATUS_TEXT END as PlanStatus,
Case When P.STATUS_TEXT = 'In Review' Then S.LAST_UPD_TS Else P.LAST_UPD_TS END as PlanDate,
Row_Number() OVER (PARTITION BY P.STATUS_TEXT ORDER BY P.LAST_UPD_TS, S.LAST_UPD_TS DESC) AS Priority
From 
CARS_MODULE_PERIOD_HDR as P
Left Join 
CARS_218_HDR_AMEND as N 
On 
P.MODULE_HDR_ID = N.MODULE_HDR_ID
Left Join 
CARS_218_HDR_STATUS as S
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
 tmp218
 Union
 Select
 State as Output
 From
 tmp218
 Union
 Select
 StringResponse as Output
 From
 tmp218

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
'</plan218>' as Output;

SET SESSION group_concat_max_len = 1000000;

Select
    	Group_Concat( OutputString_C
                   SEPARATOR '
                    ') as 'Output' INTO OutputString 
    			From
    			Output_tmp218
;


 UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_218_PRINT');
		
END$$
DELIMITER ;