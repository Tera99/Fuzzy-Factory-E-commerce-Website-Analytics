use mavenfuzzyfactory;
/*
Scenario
Maven Fuzzy Factory is an e-commerce startup that has been live for about 8 months.
Below is a series of questions from the CEO regarding information she would like to have to help prepare for a 
presentation on the growth of the company since it's launch. The task is to use SQL to extract and analyze data 
pertaining to the company's growth and provide data and analysis in response to the stakeholder's questions. 

The CEO's questions are in block quotes. 
Comments, SQL code, and a brief analysis follow each prompt.  
*/

-- date: analyze records up to 2012-11-27

/*
1.	Gsearch seems to be the biggest driver of our business. Could you pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 

-- STEPS
-- SELECT * FROM website_sessions;
-- SELECT * FROM orders;
-- left join on website_sesson_id
-- filter for gsearch
-- summarize by month
-- get number of sessions, number of orders, for each month

SELECT 
	MONTH(ws.created_at) AS month,
    MIN(DATE(ws.created_at)) AS month_start_date,
    COUNT(ws.website_session_id) AS sessions,
    COUNT(o.order_id) AS orders,
    COUNT(o.order_id) / COUNT(ws.website_session_id) AS conversion_rate,
    SUM(o.items_purchased * o.price_usd) AS total_revenue,
    SUM(o.items_purchased * o.price_usd) / COUNT(ws.website_session_id) AS usd_per_session
FROM website_sessions ws
	LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE utm_source = 'gsearch'
	AND ws.created_at < '2012-11-27'
GROUP BY
	YEAR(ws.created_at), MONTH(ws.created_at)
;

-- ANALYSIS
-- Gsearch orders and sessions are growing rapidly and driving 
-- increases in revenue.
-- As sessions increase we are also seeing increases in 
-- conversion rates and dollars per session.

/*
2.	Next, it would be great to see a similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately. I am wondering if brand is picking up at all. If so, this is a good story to tell. 
*/ 

SELECT 
	MONTH(ws.created_at) AS month,
    MIN(DATE(ws.created_at)) AS month_start_date,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END) AS nonbrand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) AS nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END) AS brand_sessions,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_orders
FROM website_sessions ws
	LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE utm_source = 'gsearch'
	AND ws.created_at < '2012-11-27'
GROUP BY
	YEAR(ws.created_at), MONTH(ws.created_at)
;

-- ANALYSIS
-- Brand sessions and orders are a small fraction compared to non_brand;
-- however, brand is increasing steadily over time.

/*
3.	While we’re on Gsearch, could you dive into nonbrand, and pull monthly sessions and orders split by device type? 
I want to flex our analytical muscles a little and show the board we really know our traffic sources. 
*/ 

SELECT 
	MONTH(ws.created_at) AS month,
    MIN(DATE(ws.created_at)) AS month_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN ws.website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN o.order_id ELSE NULL END) AS desktop_orders,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN ws.website_session_id ELSE NULL END) AS mobile_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN o.order_id ELSE NULL END) AS mobile_orders
FROM website_sessions ws
	LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand' 
	AND ws.created_at < '2012-11-27'
GROUP BY
	YEAR(ws.created_at), MONTH(ws.created_at)
;

-- ANALYSIS
-- Mobile orders significantly trail behind desktop orders.

/*
4.	I’m worried that one of our more pessimistic board members may be concerned about the large % of traffic from Gsearch. 
Can you pull monthly trends for Gsearch, alongside monthly trends for each of our other channels?
*/ 

-- STEPS
-- include paid gsearch, bsearch, organic search sessions, direct type in sessions
-- all 3 nulls is direct type in traffic
-- null source & campaign is organic search engine traffic

SELECT DISTINCT 
	utm_source,
    utm_campaign,
    http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';

SELECT 
	MONTH(ws.created_at) AS month,
    MIN(DATE(ws.created_at)) AS month_start_date,
    COUNT(DISTINCT website_session_id) AS total_sessions,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE 0 END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE 0 END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE 0 END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN http_referer IS NULL THEN website_session_id ELSE 0 END) AS direct_type_in_sessions
FROM website_sessions ws
WHERE created_at < '2012-11-27'
GROUP BY
	YEAR(ws.created_at), MONTH(ws.created_at)
;

-- ANALYSIS
-- Gsearch paid sessions account for the bulk of sessions;
-- however, organic searches and direct type in sessions
-- have also been growing rapidly over the last 8 months.

/*
5.	I’d like to tell the story of our website performance improvements over the course of the first 8 months. 
Could you pull session to order conversion rates, by month? 

*/ 

SELECT 
	MONTH(ws.created_at) AS month,
    MIN(DATE(ws.created_at)) AS month_start_date,
    COUNT(ws.website_session_id) AS sessions,
    COUNT(o.order_id) AS orders,
    COUNT(o.order_id) / COUNT(ws.website_session_id) AS session_to_order_conv_rt
FROM website_sessions ws
	LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE ws.created_at < '2012-11-27'
GROUP BY
	YEAR(ws.created_at), MONTH(ws.created_at)
;

-- ANALYSIS
-- Session to order conversion rate has been steadily increasing over the last 8 months
-- from ~2.8% in April/May to over 4% by the end of the study period. 

/*
6.	For the gsearch lander test, please estimate the revenue that test earned us 
(Hint: Look at the increase in CVR from the test (Jun 19 – Jul 28), and use 
nonbrand sessions and revenue since then to calculate incremental value)
*/ 

-- STEPS
-- find when /lander-1 started in use
-- filter relevant sessions and get min pageview ids
-- get urls (limit to home and lander-1) for min pageviews
-- join with orders to get order ids
-- summarize by grouping by url, count sessions, count orders, calc conv rate 

-- find when /lander-1 started in use
SELECT * 
FROM website_pageviews
WHERE pageview_url = '/lander-1'
ORDER BY website_pageview_id
;
-- 23504 first pageview

-- filter relevant sessions and get min pageview ids
DROP TEMPORARY TABLE sessions_minpv;
CREATE TEMPORARY TABLE sessions_minpv
SELECT 
	ws.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
    ON ws.website_session_id = wp.website_session_id
WHERE 
	wp.website_pageview_id >= 23504
    AND wp.created_at < '2012-07-28'
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY 
	ws.website_session_id
;

-- get urls (limit to home and lander-1) for min pageviews
DROP TEMPORARY TABLE session_pageview_url;
CREATE TEMPORARY TABLE session_pageview_url
SELECT 
	sm.website_session_id,
    sm.min_pageview,
    wp.pageview_url 
FROM sessions_minpv sm
	LEFT JOIN website_pageviews wp
    ON sm.min_pageview = wp.website_pageview_id
    AND wp.pageview_url IN ('/home', '/lander-1')
;

-- join with orders to get order ids
CREATE TEMPORARY TABLE session_to_order
SELECT 
	spu.website_session_id,
    spu.min_pageview,
    spu.pageview_url,
    o.order_id
FROM session_pageview_url spu
	LEFT JOIN orders o 
    ON spu.website_Session_id = o.website_session_id
;

-- get conversion rate broken down by landing page
SELECT 
	pageview_url,
	COUNT(website_session_id) AS sessions,
    COUNT(order_id) AS orders,
    COUNT(order_id) / COUNT(website_session_id) AS conversion_rt
FROM session_to_order
GROUP BY
	pageview_url
ORDER BY
    pageview_url
;

-- Lander-1 increased conversion rate from 3.18% to 4.06% for gsearch nonbrand traffic during the period of the test.
-- This is an additional 0.0088 orders per session increase. 

-- Next, to find the lift generated by the test:
-- Find the number of orders since the test and multiply by the increase

-- Find the last pageview where traffic was sent to home
SELECT 
	MAX(ws.website_session_id) AS most_recent_gsearch_nonbrand_home_pageview
FROM website_sessions ws
LEFT JOIN website_pageviews wp
	ON wp.website_session_id = ws.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
	AND pageview_url = '/home'
    AND ws.created_at < '2012-11-27' -- specified in prompt
;
-- session_id = 17145
-- use this id to filter next query
-- since this pageview, traffic has been routed else where

-- Find number of sessions since the test
SELECT 
	COUNT(website_session_id) AS sessions_since_test
FROM 
	website_sessions
WHERE created_at < '2012-11-27'
	AND website_session_id > 17145
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
;

-- 22,972 sessions since the test
-- 0.0088 * 22972 = 202 additional orders generated by the new page
-- or about 50 extra orders a month


/*
7.	For the landing page test you analyzed previously, it would be great to show a full conversion funnel 
from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 – Jul 28).
*/ 

-- STEPS
-- show full conversion funnel for /home AND /lander-1 between Jun 19 – Jul 28
-- filter relevant sessions and get min pageviews
-- join to website pageviews to get urls
-- create flags for each step in funnel
-- summarize and group by landing page, count flags
-- calculate clickthrough rates

-- get sessions and min pageviews and landing url with filtering
DROP TEMPORARY TABLE sessions_w_landing_pageview_id;
CREATE TEMPORARY TABLE sessions_w_landing_pageview_id
SELECT 
	ws.website_session_id,
    MIN(wp.website_pageview_id) as landing_pageview_id
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
    ON ws.website_session_id = wp.website_session_id
WHERE ws.utm_source = 'gsearch' 
    AND ws.utm_campaign = 'nonbrand' 
    AND ws.created_at > '2012-06-19' 
	AND wp.created_at < '2012-07-28'
GROUP BY
	ws.website_session_id
;

DROP TEMPORARY TABLE sessions_w_landing_page;
CREATE TEMPORARY TABLE sessions_w_landing_page
SELECT 
	slpi.website_session_id,
    slpi.landing_pageview_id,
    wp.pageview_url
FROM sessions_w_landing_pageview_id slpi
	LEFT JOIN website_pageviews wp
    ON slpi.landing_pageview_id = wp.website_pageview_id
;


-- get flags for funnel
DROP TEMPORARY TABLE sessions_landing_flags;
CREATE TEMPORARY TABLE sessions_landing_flags
SELECT 
	slp.website_session_id,
    slp.pageview_url as landing_page,
    wp.website_pageview_id,
    -- create flags
    CASE WHEN wp.pageview_url = '/home' THEN 1 ELSE 0 END AS home,
    CASE WHEN wp.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1,
    CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products,
    CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy,
    CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart,
    CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping,
    CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing,
    CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou
FROM sessions_w_landing_page slp
	LEFT JOIN website_pageviews wp
    ON slp.website_session_id = wp.website_session_id
ORDER BY
	slp.website_session_id,
    wp.website_pageview_id
;

-- SELECT * FROM sessions_landing_flags;

-- get sessions to each page
DROP TEMPORARY TABLE clicked_to_page;
CREATE TEMPORARY TABLE clicked_to_page
SELECT 
	landing_page,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN products = 1 THEN website_pageview_id ELSE NULL END) as to_products,
    COUNT(DISTINCT CASE WHEN mrfuzzy = 1 THEN website_pageview_id ELSE NULL END) as to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN cart = 1 THEN website_pageview_id ELSE NULL END) as to_cart,
    COUNT(DISTINCT CASE WHEN shipping = 1 THEN website_pageview_id ELSE NULL END) as to_shipping,
    COUNT(DISTINCT CASE WHEN billing = 1 THEN website_pageview_id ELSE NULL END) as to_billing,
    COUNT(DISTINCT CASE WHEN thankyou = 1 THEN website_pageview_id ELSE NULL END) as to_thankyou
FROM sessions_landing_flags
GROUP BY
	landing_page
;

SELECT * FROM clicked_to_page;

-- get click_through_rates
SELECT 
	landing_page,
	sessions AS total_sessions,
    to_products / sessions AS lander_click_thru,
    to_mrfuzzy / to_products AS products_click_thru,
    to_cart / to_mrfuzzy AS mrfuzzy_click_thru,
    to_shipping / to_cart AS cart_click_thru,
    to_billing / to_shipping AS shipping_click_thru,
    to_thankyou / to_billing AS billing_click_thru
    
FROM 
	clicked_to_page
;

-- ANALYSIS
-- The custom lander shows a 5% improvement over the original home page.
-- The lander, mr fuzzy, and billing click through rates are all 
-- somewhat low (click through rate < 50%) so these pages are areas for future improvements. 

/*
8.	I’d love for you to quantify the impact of our billing test, as well. Please analyze the lift generated 
from the test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 

-- STEPS
-- compare /billing and /billing-2
-- revenue per billing page session
-- join orders on website_session_id to get revenue
-- count sessions

-- step 1 - filter sessions on dates and billing pages
CREATE TEMPORARY TABLE billing_sessions
SELECT 
	wp.pageview_url AS billing_page,
	ws.website_session_id AS session_id,
    wp.website_pageview_id AS pageview_id
FROM website_sessions ws
	LEFT JOIN website_pageviews wp
    ON ws.website_session_id = wp.website_session_id
WHERE wp.created_at BETWEEN '2012-09-10' AND '2012-11-10'
AND pageview_url IN ('/billing', '/billing-2')
;

-- Step 2 
-- revenue per billing page session
-- join orders on website_session_id to get revenue
-- SELECT * FROM billing_sessions;
-- SELECT * FROM orders;

SELECT 
	billing_page,
    COUNT(DISTINCT session_id) AS sessions,
    -- SUM(o.items_purchased * o.price_usd) AS total_revenue,
    SUM(o.items_purchased * o.price_usd) / COUNT(DISTINCT session_id) AS revenue_per_session
FROM
	billing_sessions bs
    LEFT JOIN orders o
    ON bs.session_id = o.website_session_id
GROUP BY
	billing_page
;    
-- billing page sessions in the past month (2012-10-27 to 2012-11-27)
SELECT 
	COUNT(website_session_id) AS past_month_billing_sessions
 FROM 
	website_pageviews
WHERE 
	pageview_url IN ('/billing-2')
    AND created_at BETWEEN '2012-10-27' AND '2012-11-27'
-- 583 sessions for billing-2 in the past month
-- 583 * $8.51 = $4961.33 increase due to billing-2 in the past month

-- ANALYSIS
-- Revenue per session for billing-2 is $31.34 versus $22.83 for the original billing page. 
-- This is an increase of $8.51 per billing page view.
-- Billing-2 looks like a significant improvement over the original billing page with each
-- session resulting in substantially more revenue per session. 
-- In the final month of the study period, /billing-2 brought in $4961.33 in additional revenue 
-- over the original billing page. 

-- PROJECT SUMMARY
-- KEY TAKE AWAYS
-- Revenue, sessions, orders, and conversion rates all show strong growth during the last 8 months.
-- The majority of traffic is generated by paid searches; 
-- however, organic search and direct type in sessions are increasing.
-- The recent improvements to the billing page dramatically improved revenue.
-- One significant area to improve is the mobile user experience. 
-- Additionally, the lander and mr fuzzy page are weak spots 
-- in the conversion funnel that could be improved. 




