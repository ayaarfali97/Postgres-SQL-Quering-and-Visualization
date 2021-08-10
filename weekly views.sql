create or replace view v_consultant_rank_weekly as
-- after reached date maybe set after the end of the phone call
-- make this in pivot pls
-- do a weekly one now as well please, name the views conslutant rank quarterly and weekly


select
    -- DATE_FORMAT(created_date , '%Y-%m-01') months,
       -- concat(year(created_date), '/', quarter(created_date)) quarter,
       concat(year(created_date), '/', lpad(week(created_date), 2, '0')) week,
       owned_by_consultant_id,
      case when controlling_channel<>'CRM' and number_of_unsuccessful_attempts = 0 and
        timestampdiff(minute,created_date,reached_date)<90 then 1 else 0 end fresh_lead,
       -- timestampdiff(minute,created_date,reached_date) , -- random value to debug
       -- max(DATE_FORMAT(date_add(created_date,interval 3 month), '%Y-%m-01') ) evaluation_month,
       /* concat(
           year(max(MAKEDATE(YEAR(created_date), 1) + INTERVAL QUARTER(created_date) quarter)),
           '/',
           quarter( max(MAKEDATE(YEAR(created_date), 1) + INTERVAL QUARTER(created_date) quarter) )
       ) evaluation_quarter, */

concat(
           year(max(MAKEDATE(YEAR(created_date), 1) + INTERVAL week(created_date) + 1 week)),
           '/',
           lpad(week( max(MAKEDATE(YEAR(created_date), 1) + INTERVAL week(created_date) + 1 week) ), 2, '0')
       ) evaluation_week,

              SUM(status='closed') closed ,
        SUM(status='qualified') qualified,
       SUM(status='qualified')/(SUM(status in ('qualified','closed'))) cr2cc,
              count(*) counts,
       -- ntile(4) over  (PARTITION BY  DATE_FORMAT(created_date, '%Y-%m-01') order by cr2cc) ranks
              ntile(4) over  (PARTITION BY  week, fresh_lead order by cr2cc) ranks -- this should be the same number because fresh lead is not in partion by
from dim_lead_us
where owner_team_role not like '%ookie%'
and owned_by_consultant_id not in ( '00G24000000JUFjEAO','00G24000000JVP6EAO','00G24000000JVP1EAO','00524000000OkxsAAC',
'00G24000000In7uEAC',
'00G24000000ixAuEAI'
)
and owned_by_consultant_id like '0051o00000Bb%'
-- and DATE_FORMAT(created_date
--    , '%Y-%m-01')='2020-01-01'
group by 1,2,3
having count(*)>30;

-- lets get datetime of first call to dim_lead_us

# -- if you get a bad lead and you autoclose them, they do not get assigned a consultant, so they assign 00524000000OkxsAAC
# -- so the ranking is by individual consultant, but then we calculate in 2nd query by group, how many qualifieds did the whole group
# truncate table consultant_january;
# insert consultant_january select * from vConsultantJanuary
#
# select * from consultant_january

-- always do left join otherwise cannot see what the new consultants do that started in february,
    -- instample january rank is blank for rookie they have never done it, all the non rookies. 1. rank, 2. next month evaluate
create or replace view v_consultant_performance_week as
select
         DATE_FORMAT(created_date, '%Y-%m-01') months,
        -- concat(year(created_date), '/', lpad(week(created_date), 2, '0')) week,
        r.ranks,
       owner_team_role rlike 'ookie' rookies,
         case when controlling_channel<>'CRM' and number_of_unsuccessful_attempts = 0 and
        timestampdiff(minute,created_date,reached_date)<90 then 1 else 0 end fresh_lead,
       SUM(status='closed') closed ,
       SUM(status='qualified') qualified,
       SUM(status='qualified')/(1+SUM(status in ('qualified','closed'))) cr2cc,
       count(*)
from
    dim_lead_us l
left join
    v_consultant_rank_weekly r on
        l.owned_by_consultant_id=r.owned_by_consultant_id
        -- and DATE_FORMAT(l.created_date, '%Y-%m-01')=r.evaluation_month
        and concat(year(l.created_date), '/', lpad(week(l.created_date), 2, '0')) = r.evaluation_week
and r.fresh_lead = 1 -- if this is not here the sum will be 2xbecause you match every lead twice
-- we only care about the score of the fresh leads because we are optimizing for facebook ads
group by 1,2,3,4;
-- first quarter is in sample, training dqta
-- how can we get the people who got fired
-- and where do we get them. if they fire everyone from 1 then the people who are left in 1 will be great
-- our model is everyone who sucked previous quarter, if they still work for us, they will be amazing
-- or its random every one has the same change of being in bottom 25 %. there is some latent variable called knowledge,
-- if that variable doesnt manifest in performance then you will not improve if you remove bottom 50%.
-- the solution is they cannot fire people every week, so we do weekly
