-- Project [Credit Limit Increase Campaign]
-- It is a typical credit card limit campaign. The bank sends 5400 offers to its customers and 
-- provide the opportunity to increase their current credit limit. When a customer receives the 
-- offer, he/she will call the bank. The customer service person will check the customer’s 
-- status at the time of call, and decide whether to approve or decline the offer.
-- After dropping the campaign, the bank starts to monitor the campaign.
-- You have a few tables to complete the monitoring:
-- * Base table: includes the base population which the bank selects to provide this 
-- offer
-- * Call_record table: has the call records from these customers by day. The bank 
-- uses the call record to evaluate the response rate
-- * Decision table: has the final decision regarding each offer. AP=Approval; 
-- DL=Decline
-- * Change_record table: has the credit limit change record in the system
-- * Letter table: the bank needs to send approval letter or decline letter to customers 
-- accordingly. For example, if the customer speaks English, the bank must send 
-- letter in English. The correct letter code should be:
--      English approval letter = AE001
--      English Decline letter = RE001
--      French Approval letter = AE002
--      French Decline letter = RE002

select count(distinct acct_num) as num_people, call_date from call_record
group by call_date;

select 
sum(case when decision_status = 'AP' then 1 else 0 end) / count(acct_decision_id) as approval_rate,
sum(case when decision_status = 'DL' then 1 else 0 end) / count(acct_decision_id) as decline_rate
from decision; #This is how the case when can be used to get the number of approved and declined people


/*3.3 for approved accounts, check whether their credit limit has been changed correctly based on the offer_amount*/
SELECT A.* FROM
(select base.acct_num, 
base.credit_limit,base.offer_amount, 
d.decision_status,
c.credit_limit_after,
base.credit_limit+base.offer_amount-credit_limit_after as mismatch
from
base
left join
decision as d
on base.acct_num=d.acct_decision_id
left join
change_record as c
on
base.acct_num=c.account_number
where decision_status='AP') as A 
where A.MISMATCH <> 0;

/*3.4.1 letter monitoring for sending check*/
SELECT * FROM (
select base.acct_num,
d.decision_status, 
d.decision_date,
l.letter_code, l.Letter_trigger_date, 
datediff(decision_date,Letter_trigger_date) as letter_mis
from
base
left join
decision as d
on base.acct_num=d.acct_decision_id
left join
letter as l
on 
base.acct_num=l.account_number
where decision_status is not null) as A
where letter_mis > 0 or letter_trigger_date is NULL;

/*3.4.2 letter monitoring for code*/
SELECT * FROM
(select base.acct_num as acct_num, base.offer_amount, d.decision_status, d.decision_date,
l.language, l.letter_code,
case when decision_status='DL' and language='French' then 'RE002'
	 WHEN decision_status='AP' and language='French' then 'AE002'
     WHEN decision_status='DL' and language='English' then 'RE001'
     WHEN decision_status='AP' and language='English' then 'AE001'
     END AS letter_code2
from
base
left join
decision as d
on base.acct_num=d.acct_decision_id
left join
letter as l
on 
base.acct_num=l.account_number
where decision_status is not null) A
WHERE A.letter_code <> A.letter_code2;


/*3.5 final monitoring*/
select base.acct_num,
base.credit_limit,
base.offer_amount,
d.decision_status,
d.decision_date,
l.Letter_trigger_date, 
l.letter_code,
l.language,
c.credit_limit_after, 
case when decision_status='AP' and
base.credit_limit+base.offer_amount-credit_limit_after <> 0 then 1
else 0 end as mismatch_flag,
case when datediff(decision_date,Letter_trigger_date) > 0 then 1 else 0 end as missing_letter_flag,
case when decision_status='DL' and language='French' and l.letter_code <> 'RE002' then 1
	 WHEN decision_status='AP' and language='French' and l.letter_code <> 'AE002' then 1 
     WHEN decision_status='DL' and language='English' and l.letter_code <> 'RE001' then 1
     WHEN decision_status='AP' and language='English' and l.letter_code <> 'AE001' then 1
     ELSE 0
     END AS wrong_letter_flag 
from
base
left join
decision as d
on base.acct_num=d.acct_decision_id
left join
change_record as c
on
base.acct_num=c.account_number
left join
letter as l
on 
base.acct_num=l.account_number
where decision_status is not null;