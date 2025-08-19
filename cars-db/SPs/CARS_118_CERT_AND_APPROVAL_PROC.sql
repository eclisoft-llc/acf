DELIMITER $$
CREATE OR REPLACE PROCEDURE `CARS_118_CERT_AND_APPROVAL_PROC`(IN period_id INTEGER,IN amend_id TEXT, IN excludedApprovedAmendments INTEGER)
proc_label: BEGIN

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118_CERT_AND_APPROVAL_PROC');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118_CERT_AND_APPROVAL_PROC', 'Started', NOW());	



IF excludedApprovedAmendments=1 THEN
IF TRIM(amend_id)!='' THEN


SELECT 
			DISTINCT H.ENTITY_NAME AS 'State_Territory',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			B.INITIAL_SUBMIT_TS AS 'Initial_Certified_Date',
			B.SUBMIT_TS AS 'Last_Certified_Date',
            AQ.Review_Status,
			CASE WHEN AD.CNT IS NULL OR AD.CNT=0 THEN '' ELSE 'Yes' END  AS 'Compliance_Change',
			P.DRAFT_LETTER_TS AS 'Draft_Letter_Generation_Date',
			P.FINAL_REVIEW_TS AS 'Ready_for_Final_Review_Date',
			P.READY_TO_SIGN_TS AS 'Ready_for_Signature_Date',
			B.APPR_TS AS 'Approval_Date'
            
FROM CARS_118_HDR_AMEND B 
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_ENTITY E
			ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = 'STATE-TER'
				JOIN CARS_ENTITY R
	ON E.REGION_ID = R.ENTITY_ID
	AND R.ENTITY_TYPE_CD = 'REGION'
	
	LEFT JOIN (SELECT HDR_AMEND_ID,COUNT(1) AS CNT FROM CARS_118_SUBQUES_AMENDMENT WHERE IS_AMENDED=1 
	AND REASON_FOR_CHANGE='Changes to indicate compliance with a monitoring or Plan noncompliance finding (may be a change in process or practice, like adding information on training)' GROUP BY HDR_AMEND_ID) AS AD ON AD.HDR_AMEND_ID=B.HDR_AMEND_ID
	
  	LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Approved" ELSE CASE
when hdr.STATUS_TEXT = "Approved" then ""
when hdr.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when hdr.STATUS_TEXT = "Certified" then "Certified"
when hdr.STATUS_TEXT IN('Review', 'Updates in Progress', 'Returned for Updates') then hdr.STATUS_TEXT

when sum(ifnull(sr.RETURNED_GRANTEE_FLAG, 0)) > 0 then "At Least One State Update"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Disagree" and ifnull(sr.READY_VALIDATION_FLAG, 0) <> 1 then 1 else 0 end) > 0 then "At Least One Disagree"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "" and ifnull(sr.READY_VALIDATION_FLAG, 0) = 1 and ifnull(sr.RETURNED_RO_LEAST_ONCE_FLAG, 0) = 1  then 1 else 0 end) > 0
and count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Disagree Resolved-Ready for Validation"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Agree"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Ready for Validation"

else "Recommendation Review" END
end Review_Status

FROM CARS_118_HDR_AMEND ha  
left join CARS_118_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
join CARS_MODULE_PERIOD_HDR hdr on hdr.MODULE_HDR_ID = ha.MODULE_HDR_ID
left join CARS_118_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_118_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID
	
	LEFT JOIN CARS_118_HDR_PROVISIONAL_LETTER AS P ON P.HDR_AMEND_ID=B.HDR_AMEND_ID
	
			WHERE B.APPR_TS IS NULL AND B.HDR_AMEND_ID IN ((select TRIM(j.name) AS HDR_AMEND_ID
	from json_table(
	  replace(json_array(amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) 
            ORDER BY H.ENTITY_NAME,B.HDR_AMEND_ID;
			
	
	SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID','Amendment Number' AS 'Amendment Number','Initial Certified Date' AS 'Initial Certified Date',
	'Last Certified Date' AS 'Last Certified Date','Review Status' AS 'Review Status','Compliance Change' AS 'Compliance Change','Draft Letter Generation Date' AS 'Draft Letter Generation Date',
	'Ready for Final Review Date' AS 'Ready for Final Review Date','Ready for Signature Date' AS 'Ready for Signature Date', 'Approval Date' AS 'Approval Date';
			
			
	ELSE
		SELECT 
			DISTINCT H.ENTITY_NAME AS 'State_Territory',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			B.INITIAL_SUBMIT_TS AS 'Initial_Certified_Date',
			B.SUBMIT_TS AS 'Last_Certified_Date',
            AQ.Review_Status,
			CASE WHEN AD.CNT IS NULL OR AD.CNT=0 THEN '' ELSE 'Yes' END  AS 'Compliance_Change',
			P.DRAFT_LETTER_TS AS 'Draft_Letter_Generation_Date',
			P.FINAL_REVIEW_TS AS 'Ready_for_Final_Review_Date',
			P.READY_TO_SIGN_TS AS 'Ready_for_Signature_Date',
			B.APPR_TS AS 'Approval_Date'
			
		FROM CARS_118_HDR_AMEND B
		JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
		JOIN CARS_ENTITY E
					ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = 'STATE-TER'
						JOIN CARS_ENTITY R
	ON E.REGION_ID = R.ENTITY_ID
	AND R.ENTITY_TYPE_CD = 'REGION'
	
	
	LEFT JOIN (SELECT HDR_AMEND_ID,COUNT(1) AS CNT FROM CARS_118_SUBQUES_AMENDMENT WHERE IS_AMENDED=1 
	AND REASON_FOR_CHANGE='Changes to indicate compliance with a monitoring or Plan noncompliance finding (may be a change in process or practice, like adding information on training)' GROUP BY HDR_AMEND_ID) AS AD ON AD.HDR_AMEND_ID=B.HDR_AMEND_ID
	
  	LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Approved" ELSE CASE
when hdr.STATUS_TEXT = "Approved" then ""
when hdr.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when hdr.STATUS_TEXT = "Certified" then "Certified"
when hdr.STATUS_TEXT IN('Review', 'Updates in Progress', 'Returned for Updates') then hdr.STATUS_TEXT

when sum(ifnull(sr.RETURNED_GRANTEE_FLAG, 0)) > 0 then "At Least One State Update"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Disagree" and ifnull(sr.READY_VALIDATION_FLAG, 0) <> 1 then 1 else 0 end) > 0 then "At Least One Disagree"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "" and ifnull(sr.READY_VALIDATION_FLAG, 0) = 1 and ifnull(sr.RETURNED_RO_LEAST_ONCE_FLAG, 0) = 1  then 1 else 0 end) > 0
and count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Disagree Resolved-Ready for Validation"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Agree"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Ready for Validation"

else "Recommendation Review" END
end Review_Status
FROM CARS_118_HDR_AMEND ha  
left join CARS_118_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
join CARS_MODULE_PERIOD_HDR hdr on hdr.MODULE_HDR_ID = ha.MODULE_HDR_ID
left join CARS_118_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_118_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID
	LEFT JOIN CARS_118_HDR_PROVISIONAL_LETTER AS P ON P.HDR_AMEND_ID=B.HDR_AMEND_ID
	
					WHERE B.APPR_TS IS NULL
            ORDER BY H.ENTITY_NAME,B.HDR_AMEND_ID;
			
	
	SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID','Amendment Number' AS 'Amendment Number','Initial Certified Date' AS 'Initial Certified Date',
	'Last Certified Date' AS 'Last Certified Date','Review Status' AS 'Review Status','Compliance Change' AS 'Compliance Change','Draft Letter Generation Date' AS 'Draft Letter Generation Date',
	'Ready for Final Review Date' AS 'Ready for Final Review Date','Ready for Signature Date' AS 'Ready for Signature Date', 'Approval Date' AS 'Approval Date';
			
END IF;

ELSE

IF TRIM(amend_id)!='' THEN

SELECT		
            DISTINCT H.ENTITY_NAME AS 'State_Territory',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			B.INITIAL_SUBMIT_TS AS 'Initial_Certified_Date',
			B.SUBMIT_TS AS 'Last_Certified_Date',
            AQ.Review_Status,
			CASE WHEN AD.CNT IS NULL OR AD.CNT=0 THEN '' ELSE 'Yes' END  AS 'Compliance_Change',
			P.DRAFT_LETTER_TS AS 'Draft_Letter_Generation_Date',
			P.FINAL_REVIEW_TS AS 'Ready_for_Final_Review_Date',
			P.READY_TO_SIGN_TS AS 'Ready_for_Signature_Date',
			B.APPR_TS AS 'Approval_Date'
			
FROM CARS_118_HDR_AMEND B
JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
JOIN CARS_ENTITY E
			ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = 'STATE-TER'
				JOIN CARS_ENTITY R
	ON E.REGION_ID = R.ENTITY_ID
	AND R.ENTITY_TYPE_CD = 'REGION'
	
	LEFT JOIN (SELECT HDR_AMEND_ID,COUNT(1) AS CNT FROM CARS_118_SUBQUES_AMENDMENT WHERE IS_AMENDED=1 
	AND REASON_FOR_CHANGE='Changes to indicate compliance with a monitoring or Plan noncompliance finding (may be a change in process or practice, like adding information on training)' GROUP BY HDR_AMEND_ID) AS AD ON AD.HDR_AMEND_ID=B.HDR_AMEND_ID
	
  	LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Approved" ELSE CASE
when hdr.STATUS_TEXT = "Approved" then ""
when hdr.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when hdr.STATUS_TEXT = "Certified" then "Certified"
when hdr.STATUS_TEXT IN('Review', 'Updates in Progress', 'Returned for Updates') then hdr.STATUS_TEXT

when sum(ifnull(sr.RETURNED_GRANTEE_FLAG, 0)) > 0 then "At Least One State Update"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Disagree" and ifnull(sr.READY_VALIDATION_FLAG, 0) <> 1 then 1 else 0 end) > 0 then "At Least One Disagree"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "" and ifnull(sr.READY_VALIDATION_FLAG, 0) = 1 and ifnull(sr.RETURNED_RO_LEAST_ONCE_FLAG, 0) = 1  then 1 else 0 end) > 0
and count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Disagree Resolved-Ready for Validation"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Agree"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Ready for Validation"

else "Recommendation Review" END
end Review_Status
FROM CARS_118_HDR_AMEND ha  
left join CARS_118_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
join CARS_MODULE_PERIOD_HDR hdr on hdr.MODULE_HDR_ID = ha.MODULE_HDR_ID
left join CARS_118_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_118_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID
	LEFT JOIN CARS_118_HDR_PROVISIONAL_LETTER AS P ON P.HDR_AMEND_ID=B.HDR_AMEND_ID
			WHERE B.HDR_AMEND_ID IN ((select TRIM(j.name) AS HDR_AMEND_ID
	from json_table(
	  replace(json_array(amend_id), ',', '","'),
	  '$[*]' columns (name varchar(10) path '$')
	) j)) 
            ORDER BY H.ENTITY_NAME,B.HDR_AMEND_ID;
			
	
	SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID','Amendment Number' AS 'Amendment Number','Initial Certified Date' AS 'Initial Certified Date',
	'Last Certified Date' AS 'Last Certified Date','Review Status' AS 'Review Status','Compliance Change' AS 'Compliance Change','Draft Letter Generation Date' AS 'Draft Letter Generation Date',
	'Ready for Final Review Date' AS 'Ready for Final Review Date','Ready for Signature Date' AS 'Ready for Signature Date', 'Approval Date' AS 'Approval Date';
			
	ELSE
		SELECT 
            DISTINCT H.ENTITY_NAME AS 'State_Territory',
			R.ENTITY_NAME AS Region,
			R.REGION_ID AS 'REGION_ID',
			CASE WHEN B.AMEND_SEQ_NUM>1 THEN CONCAT('Amendment #',B.AMEND_SEQ_NUM-1) ELSE 'Initial Plan' END AS 'Amendment_Number',
			B.INITIAL_SUBMIT_TS AS 'Initial_Certified_Date',
			B.SUBMIT_TS AS 'Last_Certified_Date',
            AQ.Review_Status,
			CASE WHEN AD.CNT IS NULL OR AD.CNT=0 THEN '' ELSE 'Yes' END  AS 'Compliance_Change',
			P.DRAFT_LETTER_TS AS 'Draft_Letter_Generation_Date',
			P.FINAL_REVIEW_TS AS 'Ready_for_Final_Review_Date',
			P.READY_TO_SIGN_TS AS 'Ready_for_Signature_Date',
			B.APPR_TS AS 'Approval_Date'		FROM CARS_118_HDR_AMEND B
		JOIN CARS_MODULE_PERIOD_HDR H ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id
		JOIN CARS_ENTITY E
					ON H.ENTITY_ID = E.ENTITY_ID AND E.ENTITY_TYPE_CD = 'STATE-TER'
						JOIN CARS_ENTITY R
	ON E.REGION_ID = R.ENTITY_ID
	AND R.ENTITY_TYPE_CD = 'REGION'
	
	LEFT JOIN (SELECT HDR_AMEND_ID,COUNT(1) AS CNT FROM CARS_118_SUBQUES_AMENDMENT WHERE IS_AMENDED=1 
	AND REASON_FOR_CHANGE='Changes to indicate compliance with a monitoring or Plan noncompliance finding (may be a change in process or practice, like adding information on training)' GROUP BY HDR_AMEND_ID) AS AD ON AD.HDR_AMEND_ID=B.HDR_AMEND_ID
	
  	LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Approved" ELSE CASE
when hdr.STATUS_TEXT = "Approved" then ""
when hdr.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when hdr.STATUS_TEXT = "Certified" then "Certified"
when hdr.STATUS_TEXT IN('Review', 'Updates in Progress', 'Returned for Updates') then hdr.STATUS_TEXT

when sum(ifnull(sr.RETURNED_GRANTEE_FLAG, 0)) > 0 then "At Least One State Update"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "Disagree" and ifnull(sr.READY_VALIDATION_FLAG, 0) <> 1 then 1 else 0 end) > 0 then "At Least One Disagree"
when sum(case when ifnull(vr.REVIEW_DECISION_TEXT, "") = "" and ifnull(sr.READY_VALIDATION_FLAG, 0) = 1 and ifnull(sr.RETURNED_RO_LEAST_ONCE_FLAG, 0) = 1  then 1 else 0 end) > 0
and count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Disagree Resolved-Ready for Validation"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Agree"
when count(sr.REVIEW_DECISION_TEXT) = sum(ifnull(sr.READY_VALIDATION_FLAG, 0)) then "All Questions Ready for Validation"

else "Recommendation Review" END
end Review_Status
FROM CARS_118_HDR_AMEND ha  
left join CARS_118_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
join CARS_MODULE_PERIOD_HDR hdr on hdr.MODULE_HDR_ID = ha.MODULE_HDR_ID
left join CARS_118_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_118_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID
	LEFT JOIN CARS_118_HDR_PROVISIONAL_LETTER AS P ON P.HDR_AMEND_ID=B.HDR_AMEND_ID
            ORDER BY H.ENTITY_NAME,B.HDR_AMEND_ID;
			
	
	SELECT 'State/Territory' AS 'State/Territory','Region' AS 'Region','Region_ID' AS 'Region_ID','Amendment Number' AS 'Amendment Number','Initial Certified Date' AS 'Initial Certified Date',
	'Last Certified Date' AS 'Last Certified Date','Review Status' AS 'Review Status','Compliance Change' AS 'Compliance Change','Draft Letter Generation Date' AS 'Draft Letter Generation Date',
	'Ready for Final Review Date' AS 'Ready for Final Review Date','Ready for Signature Date' AS 'Ready for Signature Date', 'Approval Date' AS 'Approval Date';
			
END IF;
END IF;
					  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118_CERT_AND_APPROVAL_PROC');
		
END$$
DELIMITER ;