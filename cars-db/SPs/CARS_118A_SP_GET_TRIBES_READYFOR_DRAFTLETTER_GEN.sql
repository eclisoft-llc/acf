DELIMITER $$
CREATE OR REPLACE PROCEDURE CARS_118A_SP_GET_TRIBES_READYFOR_DRAFTLETTER_GEN(IN period_id INTEGER)
proc_label: BEGIN

	DECLARE EXIT HANDLER FOR SQLEXCEPTION
	BEGIN
		GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
		SET @full_error = CONCAT("ERROR ", @errno, " (", @sqlstate, "): ", @text);
		
		UPDATE CARS_SP_LOG
			SET SP_STATUS_TEXT='Error',SP_LOG_MESSAGE_TEXT=@full_error,END_TS=NOW()
		WHERE SP_LOG_ID=(SELECT MAX(SP_LOG_ID)FROM CARS_SP_LOG WHERE SP_NAME='CARS_118A_SP_GET_TRIBES_READYFOR_DRAFTLETTER_GEN');
			
		
	END;
	
		INSERT INTO CARS_SP_LOG (SP_NAME, SP_STATUS_TEXT, START_TS)
		VALUES('CARS_118A_SP_GET_TRIBES_READYFOR_DRAFTLETTER_GEN', 'Started', NOW());	



SELECT 
			DISTINCT H.ENTITY_ID,
			B.HDR_AMEND_ID
			
			
FROM CARS_118A_HDR_AMEND B

JOIN CARS_MODULE_PERIOD_HDR H 
ON H.MODULE_HDR_ID = B.MODULE_HDR_ID AND H.PERIOD_ID=period_id

JOIN CARS_ENTITY E
ON H.ENTITY_ID = E.ENTITY_ID
	
	LEFT JOIN (SELECT ha.HDR_AMEND_ID, 
case
WHEN ha.APPR_TS IS NOT NULL THEN "Approved" ELSE CASE
when hdr.STATUS_TEXT = "Approved" then ""
when hdr.STATUS_TEXT = "Work in Progress" then "Work in Progress"
when hdr.STATUS_TEXT = "Certified" then "Certified"
when hdr.STATUS_TEXT = "Not Started" then "Not Started"
when hdr.STATUS_TEXT IN('Review', 'Updates in Progress', 'Returned for Updates') then hdr.STATUS_TEXT
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
FROM CARS_118A_HDR_AMEND ha  
left join CARS_118A_HDR_SUBQUES_REVIEW sr on ha.HDR_AMEND_ID = sr.HDR_AMEND_ID and sr.`REVIEW_STATUS_TEXT` = "Recommendation Review" and ifnull(sr.`REVIEW_DECISION_TEXT`, "") <> "N/A"
join CARS_MODULE_PERIOD_HDR hdr on hdr.MODULE_HDR_ID = ha.MODULE_HDR_ID
left join CARS_118A_HDR_SUBQUES_REVIEW vr on vr.HDR_AMEND_ID = sr.HDR_AMEND_ID and vr.SUBQUES_ID = sr.SUBQUES_ID and vr.`REVIEW_STATUS_TEXT` = "Validation Review"
left join CARS_118A_SUBQUES sq on sq.SUBQUES_ID = sr.SUBQUES_ID
GROUP BY ha.HDR_AMEND_ID) AS AQ ON AQ.HDR_AMEND_ID=B.HDR_AMEND_ID
	LEFT JOIN CARS_118A_HDR_APPROVAL_LETTER AS P ON P.HDR_AMEND_ID=B.HDR_AMEND_ID


WHERE COALESCE(P.DRAFT_LETTER_TS,'') = ''
AND AQ.Review_Status = 'All Questions Agree'
ORDER BY 1,2;			
		  
UPDATE CARS_SP_LOG
SET SP_STATUS_TEXT= 'Success', END_TS=NOW()
WHERE  SP_LOG_ID=( SELECT MAX(SP_LOG_ID) FROM CARS_SP_LOG WHERE SP_NAME = 'CARS_118A_SP_GET_TRIBES_READYFOR_DRAFTLETTER_GEN');
		
END$$
DELIMITER ;