DROP PROCEDURE IF EXISTS CARS_CMR_CERT_AND_APPROVAL_PROC;
DELIMITER $$
CREATE PROCEDURE `CARS_CMR_CERT_AND_APPROVAL_PROC`(IN period_id INTEGER,IN excludeAcceptedFlag INTEGER, IN i_hdramend_id TEXT)
proc_label: BEGIN

    DECLARE v_Status_Text TEXT DEFAULT NULL;
	DECLARE v_hdramendid_Text TEXT DEFAULT NULL;
    DECLARE v_sql TEXT DEFAULT NULL;
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_CMR_CERT_AND_APPROVAL_PROC');

			
		
	END;
	
	
	INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_CMR_CERT_AND_APPROVAL_PROC', 'Started', NOW());	

IF excludeAcceptedFlag = 1 THEN SET v_Status_Text = ' AND  A.STATUS_TEXT <> ''Accepted'' ' ;
ELSE SET v_Status_Text = '  ' ;
END IF;

IF TRIM(i_hdramend_id)!='' THEN SET v_hdramendid_Text = CONCAT(' AND  A.HDR_AMEND_ID IN ( ',i_hdramend_id,') ') ;
ELSE SET v_hdramendid_Text = '  ' ;
END IF;

SET v_sql = 
CONCAT('SELECT DISTINCT
E.ENTITY_NAME AS ''Lead Agency'',
E.OGM_TRIBAL_CD AS ''Tribal Code'',
ST.ENTITY_NAME AS ''State'',
R.ENTITY_NAME AS ''Region'',
I.ALLOCATION_SIZE AS ''Allocation'',
CONCAT("Request #",A.AMEND_SEQ_NUM) AS ''Request #'',
A.INITIAL_SUBMIT_TS AS ''Initial_Certified_Date'',
A.SUBMIT_TS AS ''Last_Certified_Date'',
RR.Review_Status,
A.READY_FOR_ACCEPTANCE_TS AS ''Ready for Acceptance Date'',
A.APPR_TS AS ''Accepted Date''
FROM CARS_MODULE_PERIOD_HDR H
JOIN CARS_CMR_HDR_AMEND A
ON H.MODULE_HDR_ID = A.MODULE_HDR_ID

JOIN CARS_ENTITY E ON (H.ENTITY_ID = E.ENTITY_ID and E.ENTITY_TYPE_CD = ''TRIBE'')
JOIN CARS_TRIBE_INFO I ON (H.ENTITY_ID = I.TRIBE_ID and H.PERIOD_ID = I.PERIOD_ID)
JOIN CARS_ENTITY R ON (E.REGION_ID = R.ENTITY_ID and R.ENTITY_TYPE_CD = ''REGION'')
JOIN CARS_ENTITY ST ON (E.ENTITY_STATE_CD = ST.ENTITY_STATE_CD and ST.ENTITY_TYPE_CD = ''STATE-TER'')

LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Accepted" ELSE CASE
when ha.STATUS_TEXT = "Accepted" then ""
when ha.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when ha.STATUS_TEXT = "Certified" then "Certified"
when ha.STATUS_TEXT = "Not Started" then "Not Started"
when ha.STATUS_TEXT IN(''Review'', ''Updates in Progress'', ''Returned for Updates'') then ha.STATUS_TEXT
when sum(ifnull(sr.RETURNED_GRANTEE_FLAG, 0)) > 0 then "At Least One Tribal Update"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Disagree" and ifnull(sr.READY_VALIDATION_FLAG, 0) <> 1 then 1 else 0 end) > 0 then "At Least One Disagree"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "" and ifnull(sr.READY_VALIDATION_FLAG, 0) = 1 and ifnull(sr.RETURNED_RO_LEAST_ONCE_FLAG, 0) = 1  then 1 else 0 end) > 0
and count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Disagree Resolved-Ready for Validation"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Agree" then 1 else 0 end) = 
sum(case when ifnull(sr.REVIEW_DECISION_TEXT, "") = "Recommend with Conditions" or ifnull(sq.PRIORITY_REVIEW_FLAG, 0) = 1 then 1 else 0 end) and 
count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Agree"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Ready for Validation"
else "Recommendation Review" END
end Review_Status
FROM CARS_CMR_HDR_AMEND ha  
left join CARS_CMR_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
left join CARS_CMR_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_CMR_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS RR ON RR.HDR_AMEND_ID=A.HDR_AMEND_ID
WHERE H.PERIOD_ID IN (',period_id,')', v_Status_Text,v_hdramendid_Text);

EXECUTE IMMEDIATE v_sql;

SELECT 'Lead Agency' AS 'Lead Agency','Tribal Code' AS 'Tribal Code','State' AS 'State','Region' AS 'Region','Allocation' AS 'Allocation',
'Request #' AS 'Request #','Initial Certified Date' AS 'Initial Certified Date','Last Certified Date' AS 'Last Certified Date',
'Review Status' AS 'Review Status','Ready for Acceptance Date' AS 'Ready for Acceptance Date','Accepted Date' AS 'Accepted Date';

UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_CMR_CERT_AND_APPROVAL_PROC');
		
	
END$$
DELIMITER ;