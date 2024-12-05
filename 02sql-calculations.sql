/* Base table and citation impact data for Figure 5 and 6

NOTE: The workflwo starts with the "importeddata" table which results from a match between Web of Science and the PubMed data.
It contains WoS Item ID's (FK_UT); PMID ID's; hierarchly unified document types from PubMed (mtypefinal. PRISMA-citation is an own document type, see related publication for explanation); and the official publication year

Creates "citations_data.csv"

*/

--Calculate cpin values in the base table "importeddata"
	CREATE TABLE gubi_newnew_cpin as
	WITH gubi_new_wb_dist as (
			SELECT 
			aa.FK_UT,
			aa.pmid,
			aa.mtypefinal,
			aa.pubyear	
			FROM importeddata aa
	), gubi_new_tens AS (
			SELECT aa.fk_ut,
			count(DISTINCT CASE WHEN bb.CITYEAR <= aa.pubyear + 3 THEN  bb.UT_CITING  ELSE NULL end) cit_cnt_3y,
			count(DISTINCT CASE WHEN bb.CITYEAR <= aa.pubyear + 5 THEN  bb.UT_CITING  ELSE NULL end) cit_cnt_5y,
			count(DISTINCT CASE WHEN bb.CITYEAR <= aa.pubyear + 10 THEN  bb.UT_CITING  ELSE NULL end) cit_cnt_10y
			FROM gubi_new_wb_dist aa
			LEFT JOIN wos_b_2019.KB_CITINGITEMS bb ON aa.fk_ut = bb.UT_CITED
			GROUP BY aa.fk_ut
	), gubi_new_wb_dist_2 AS (
			SELECT aa.*, bb.cit_cnt_10y
			FROM gubi_new_wb_dist aa LEFT JOIN gubi_new_tens bb ON aa.FK_UT =bb.fk_ut
	), gubi_newnew AS (
			SELECT aa.*, cc.FK_CLASSIFICATIONS 
			FROM gubi_new_wb_dist_2 aa
			LEFT JOIN WOS_B_2019.items bb ON aa.FK_UT =bb.UT_EID
			LEFT JOIN WOS_B_2019.ITEMS_CLASSIFICATIONS cc ON bb.PK_ITEMS =cc.FK_ITEMS
	), gubi_wosclass_3Y as (
			SELECT FK_CLASSIFICATIONS, pubyear, CIT_CNT_3Y, count(fk_UT) pub_per_cit_cnt_3Y
			FROM gubi_newnew
			GROUP BY FK_CLASSIFICATIONS, pubyear, CIT_CNT_3Y
			ORDER BY CIT_CNT_3Y
	), gubi_wosclass_5Y as (
			SELECT FK_CLASSIFICATIONS, pubyear, CIT_CNT_5Y, count(fk_UT) pub_per_cit_cnt_5Y
			FROM gubi_newnew
			GROUP BY FK_CLASSIFICATIONS, pubyear, CIT_CNT_5Y
			ORDER BY CIT_CNT_5Y
	), gubi_wosclass_10Y as (
			SELECT FK_CLASSIFICATIONS, pubyear, CIT_CNT_10Y, count(fk_UT) pub_per_cit_cnt_10Y
			FROM gubi_newnew
			GROUP BY FK_CLASSIFICATIONS, pubyear, CIT_CNT_10Y
			ORDER BY CIT_CNT_10Y
	), gubi_wosclass_3Y_final as (
		SELECT 
		fk_classifications, 
		pubyear, 
		cit_cnt_3Y, 
		pub_per_cit_cnt_3Y, 
		sum(pub_per_cit_cnt_3Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear) totoalcnt,
		sum(pub_per_cit_cnt_3Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear, cit_cnt_3Y) cumcnt
		FROM gubi_wosclass_3Y
	), 	gubi_wosclass_5Y_final as (
		SELECT 
		fk_classifications, 
		pubyear, 
		cit_cnt_5Y, 
		pub_per_cit_cnt_5Y, 
		sum(pub_per_cit_cnt_5Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear) totoalcnt,
		sum(pub_per_cit_cnt_5Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear, cit_cnt_5Y) cumcnt
		FROM gubi_wosclass_5Y
	), gubi_wosclass_10Y_final as (
		SELECT 
		fk_classifications, 
		pubyear, 
		cit_cnt_10Y, 
		pub_per_cit_cnt_10Y, 
		sum(pub_per_cit_cnt_10Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear) totoalcnt,
		sum(pub_per_cit_cnt_10Y) OVER(PARTITION BY fk_classifications, pubyear ORDER BY fk_classifications, pubyear, cit_cnt_10Y) cumcnt
		FROM gubi_wosclass_10Y
	)  SELECT aa.*, 
		round((100*(bb.cumcnt / bb.totoalcnt)),2) cpin_3Y,
		round((100*(cc.cumcnt / cc.totoalcnt)),2) cpin_5Y,
		round((100*(dd.cumcnt / dd.totoalcnt)),2) cpin_10Y
		FROM gubi_newnew aa
		LEFT JOIN gubi_wosclass_3Y_final bb ON aa.FK_CLASSIFICATIONS = bb.fk_classifications AND aa.PUBYEAR =bb.pubyear AND aa.CIT_CNT_3Y = bb.cit_cnt_3Y
		LEFT JOIN gubi_wosclass_5Y_final cc ON aa.FK_CLASSIFICATIONS = cc.fk_classifications AND aa.PUBYEAR =cc.pubyear AND aa.CIT_CNT_5Y = cc.cit_cnt_5Y
		LEFT JOIN gubi_wosclass_10Y_final dd ON aa.FK_CLASSIFICATIONS = dd.fk_classifications AND aa.PUBYEAR =dd.pubyear AND aa.CIT_CNT_10Y = dd.cit_cnt_10Y


--Calculate mncs value and match to cpin table
	CREATE TABLE GUBI_NEWNEW_CP_MNCS as
	WITH gubi_mncs_field AS (
		SELECT bb.field, bb.pubyear, round((bb.ccnt / bb.pcnt),4) mean_exp_cit
		FROM (
		SELECT aa.field field, aa.pubyear pubyear, sum(aa.pubcnt) pcnt, sum(aa.citcnt) ccnt
		FROM wos_b_2019.D_expected_citations_field aa
		WHERE aa."WINDOW" = 3 AND PUBTYPE ='Journal'
		GROUP BY aa.field, aa.pubyear) bb
	),  gubi_mncs_field_2 AS (
		SELECT aa.*, bb.PK_CLASSIFICATIONS FROM gubi_mncs_field aa 
		LEFT JOIN wos_b_2019.CLASSIFICATIONS bb ON aa.field=bb.CLASSIFICATION
	) SELECT aa.*, 
		round((aa.CIT_CNT_3Y / bb.mean_exp_cit),4) MNCS_3Y
		FROM GUBI_NEWNEW_CPIN aa
		LEFT JOIN gubi_mncs_field_2 bb ON aa.pubyear=bb.pubyear AND aa.FK_CLASSIFICATIONS =bb.pk_classifications



/* Field-based data for Figure 1 and 2
Based on gubi_newnew_cpin (see above)

Creates
"fields_WoS_extended_peryear.csv"
"fields_top_fields_rates.csv"
*/

--Creates annual item numbers for each WoS field and document type (wide format)	
	SELECT cc.CLASSIFICATION , pubyear,
	count(fk_ut) total_cnt,
	count(CASE WHEN MTYPEFINAL = 'med_News' THEN fk_ut ELSE NULL end) med_News,
	count(CASE WHEN MTYPEFINAL = 'med_Editorial' THEN fk_ut ELSE NULL end) med_Editorial,
	count(CASE WHEN MTYPEFINAL = 'med_Letter' THEN fk_ut ELSE NULL end) med_Letter,
	count(CASE WHEN MTYPEFINAL = 'med_review' THEN fk_ut ELSE NULL end) med_review,
	count(CASE WHEN MTYPEFINAL = 'med_Article' THEN fk_ut ELSE NULL end) med_Article,
	count(CASE WHEN MTYPEFINAL = 'med_SReview' THEN fk_ut ELSE NULL end) med_SReview,	
	count(CASE WHEN MTYPEFINAL = 'med_SReview_Titled' THEN fk_ut ELSE NULL end) med_SReview_Titled
	FROM GUBI_NEWNEW_CPIN aa
	LEFT JOIN wos_b_2019.CLASSIFICATIONS cc ON aa.FK_CLASSIFICATIONS =cc.PK_CLASSIFICATIONS
	WHERE CLASSIFICATION_TYPE = 'sc_extended'
	GROUP BY cc.CLASSIFICATION, pubyear

--Creates document type rates for different fields
	WITH overallcounts as (
			SELECT cc.CLASSIFICATION,
			count(fk_ut) total_cnt,
			count(CASE WHEN MTYPEFINAL = 'med_News' THEN fk_ut ELSE NULL end) med_News,
			count(CASE WHEN MTYPEFINAL = 'med_Editorial' THEN fk_ut ELSE NULL end) med_Editorial,
			count(CASE WHEN MTYPEFINAL = 'med_Letter' THEN fk_ut ELSE NULL end) med_Letter,
			count(CASE WHEN MTYPEFINAL = 'med_review' THEN fk_ut ELSE NULL end) med_review,
			count(CASE WHEN MTYPEFINAL = 'med_Article' THEN fk_ut ELSE NULL end) med_Article,
			count(CASE WHEN MTYPEFINAL = 'med_SReview' THEN fk_ut ELSE NULL end) med_SReview,	
			count(CASE WHEN MTYPEFINAL = 'med_SReview_Titled' THEN fk_ut ELSE NULL end) med_SReview_Titled
			FROM GUBI_NEWNEW_CPIN aa
			LEFT JOIN wos_b_2019.CLASSIFICATIONS cc ON aa.FK_CLASSIFICATIONS =cc.PK_CLASSIFICATIONS
			WHERE CLASSIFICATION IN ('Physical Sciences','Arts & Humanities','Technology','Social Sciences','Life Sciences & Biomedicine')
			GROUP BY cc.CLASSIFICATION ORDER BY total_cnt desc
	)	SELECT aa.classification,
			round((100*(aa.med_News / aa.total_cnt)),2) news_rate,
			round((100*(aa.med_Editorial / aa.total_cnt)),2) edit_rate,
			round((100*(aa.med_Letter / aa.total_cnt)),2) letter_rate,
			round((100*(aa.med_review / aa.total_cnt)),2) review_rate,
			round((100*(aa.med_Article / aa.total_cnt)),2) article_rate,
			round((100*(aa.med_SReview / aa.total_cnt)),2) srev_rate,
			round((100*(aa.med_SReview_Titled / aa.total_cnt)),2) prisma_rate
		from overallcounts


--Additional data to get the field classification of all PRISMA documents
	SELECT DISTINCT dd.PK_CLASSIFICATIONS, dd.CLASSIFICATION 
	FROM PUBMED_GUIDES aa
	LEFT JOIN wos_b_2019.items bb ON aa.UT_EID =bb.UT_EID 
	LEFT JOIN wos_b_2019.ITEMS_CLASSIFICATIONS cc ON bb.PK_ITEMS =cc.FK_ITEMS 
	LEFT JOIN wos_b_2019.CLASSIFICATIONS dd ON cc.FK_CLASSIFICATIONS =dd.PK_CLASSIFICATIONS 
	WHERE aa.TYPE IN ('PRISMA-G','PRISMA-E&E') AND dd.CLASSIFICATION_TYPE = 'sc_extended'



/* Country-based data for Figure 3 and 4
based on gubi_newnew_cpin (see above)

Creates:
"country_totals.csv"
"country_SSR_annaul.csv"

*/

-- Base data gubi_cntry: Calculation of fractional author counts
	CREATE TABLE gubi_cntry as
	WITH gubi_cntry_bomb AS (
		SELECT aa.fk_ut, dd.COUNTRYCODE, cc.role, aa.pubyear, aa.MTYPEFINAL 
		FROM (SELECT DISTINCT fk_UT, pubyear, mtypefinal FROM gubi_newnew_cpin) aa
		LEFT JOIN wos_b_2019.items bb ON aa.FK_UT =bb.UT_EID
		LEFT JOIN wos_b_2019.ITEMS_AUTHORS_INSTITUTIONS cc ON bb.PK_ITEMS =cc.FK_ITEMS
		LEFT JOIN wos_b_2019.INSTITUTIONS dd ON cc.FK_INSTITUTIONS = dd.PK_INSTITUTIONS
		WHERE dd.COUNTRYCODE IS NOT NULL
	), gubi_cntry_bombfra AS (
		SELECT aa.fk_ut, aa.COUNTRYCODE, aa.ROLE, aa.pubyear, aa.mtypefinal, bb.anzahl 
		FROM gubi_cntry_bomb aa 
		LEFT JOIN (SELECT fk_ut, 1 / count(fk_ut) anzahl FROM gubi_cntry_bomb GROUP BY fk_ut) bb ON aa.fk_ut =bb.fk_ut
	), gubi_cntry_grouped as (
		SELECT aa.fk_ut,  aa.ROLE, aa.pubyear, aa.mtypefinal, aa.COUNTRYCODE, sum(aa.anzahl) fraction
		FROM gubi_cntry_bombfra aa 
		GROUP BY aa.fk_ut,  aa.ROLE, aa.pubyear, aa.mtypefinal, aa.COUNTRYCODE
	), gubi_cntry_filtered as (
		SELECT COUNTRYCODE, 
		MTYPEFINAL, pubyear,
		sum(fraction) cnts
		FROM gubi_cntry_grouped
		WHERE MTYPEFINAL IN ('med_review','med_SReview','med_SReview_Titled')
		GROUP BY mtypefinal, COUNTRYCODE, pubyear
	) SELECT aa.COUNTRYCODE,aa.mtypefinal,aa.pubyear, aa.cnts,
		sum(aa.cnts) over(PARTITION BY aa.COUNTRYCODE, aa.mtypefinal ORDER BY aa.pubyear) cum_cnt,
		sum(aa.cnts) over(PARTITION BY aa.COUNTRYCODE ORDER BY aa.pubyear) tot_cnt_per_year
		FROM gubi_cntry_filtered
		ORDER BY COUNTRYCODE, mtypefinal, pubyear) aa;

-- Dataset for Figure 3 (Bubbleplot)
	CREATE TABLE gubi_cntry_bomb_bubble AS
	WITH widedata as (
		SELECT COUNTRYCODE, 
		max(aa.TOT_CNT_PER_YEAR) total,
		round((CASE WHEN mtypefinal = 'med_SReview' THEN (max(cum_cnt) / max(aa.TOT_CNT_PER_YEAR)*100) ELSE NULL END), 2) rate_sr, 
		round((CASE WHEN mtypefinal = 'med_SReview_Titled' THEN (max(cum_cnt) / max(aa.TOT_CNT_PER_YEAR)*100) ELSE NULL END), 2) rate_ssr
		FROM gubi_cntry aa
		GROUP BY COUNTRYCODE, mtypefinal
	) SELECT bb.countrycode, max(bb.total) total, max(bb.rate_sr) rate_sr, max(bb.rate_ssr) rate_ssr 
		FROM widedata bb
		GROUP BY bb.COUNTRYCODE;
		
		--remove NULL values
		UPDATE gubi_cntry_bomb_bubble SET rate_sR = 0 WHERE rate_sR IS NULL;
		UPDATE gubi_cntry_bomb_bubble SET rate_SsR = 0 WHERE rate_SsR IS NULL;

	--> This table (gubi_cntry_bomb_bubble) is exported as "country_totals.csv"

-- Dataset for Figure 4, filtered for the 17th greates publishing countries of reviews
	CREATE TABLE gubi_cntry_annual AS
		SELECT aa.countrycode, mtypefinal, pubyear, round(cnts,2) cnts, round(cum_cnt,2) cum_cnt, round(TOT_CNT_PER_YEAR, 2) TOT_CNT_PER_YEAR, 
		round(((cum_cnt / tot_cnt_per_year)*100),2) ANNUAL_GROWTH_Rate
		FROM gubi_cntry aa
		WHERE countrycode IN ('USA','GBR','DEU','ITA','FRA','CAN','CHN','AUS','JPN','ESP','NLD','IND','CHE','BRA','BEL','POL','DNK')
		ORDER BY aa.COUNTRYCODE, aa.mtypefinal, aa.pubyear;
		--> This table is exported as "country_SSR_annaul.csv"
