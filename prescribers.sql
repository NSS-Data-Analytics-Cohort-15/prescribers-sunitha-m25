--Q1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of
--claims.
SELECT npi, SUM(total_claim_count) AS total_number_of_claims
FROM prescription
GROUP BY npi
ORDER BY total_number_of_claims DESC limit 1;

--Q1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
--specialty_description, and the total number of claims.
SELECT
	nppes_provider_first_name AS provider_first_name
	,nppes_provider_last_org_name AS provider_last_org_name
	,specialty_description AS specialty
	, SUM(total_claim_count) AS total_number_of_claims
FROM prescription
INNER JOIN prescriber USING(npi)
GROUP BY provider_first_name,provider_last_org_name,specialty
ORDER BY total_number_of_claims DESC 
--LIMIT 1;

--Q2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT
	specialty_description
	, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN prescriber USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Q2b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description,SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription USING(npi)
WHERE drug_name IN(SELECT drug_name FROM drug WHERE opioid_drug_flag = 'Y' )
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;

--Q2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated 
--prescriptions in the prescription table?
SELECT DISTINCT specialty_description 
FROM prescriber
EXCEPT 
	SELECT DISTINCT specialty_description
	FROM prescriber
	JOIN prescription USING(npi)
	WHERE drug_name IS NOT NULL;

--alternative:
SELECT specialty_description
FROM prescriber AS p1
LEFT JOIN prescription AS p2 ON p1.npi = p2.npi
GROUP BY specialty_description
HAVING MIN(p2.npi) IS NULL
ORDER BY specialty_description;

--Q2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the 
--percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT 
    specialty_description, 
    (CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count ELSE 0 END) AS opioid_claims,
    (total_claim_count) AS total_specialty_claims
FROM prescription AS p1
INNER JOIN drug AS d USING (drug_name)  
INNER JOIN prescriber AS p2 ON p1.npi = p2.npi

--Q3a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name,MAX(total_drug_cost) AS drug_cost
FROM prescription
JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY 2 DESC;

--Q3 b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal 
--places. Google ROUND to see how this works.**

SELECT generic_name, MAX(round((total_drug_cost/total_day_supply),2)) AS cost_per_day
FROM prescription
JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY 2 DESC
LIMIT 1;

SELECT
	generic_name
	, ROUND((total_drug_cost / total_day_supply),2) AS total_cost_per_day
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE (total_drug_cost / total_day_supply) = (SELECT MAX(total_drug_cost / total_day_supply) FROM prescription);

--Q4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for
--drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says
--'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See
--https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT
	drug_name,
	 (CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
			WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' 
			ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name, drug_type;

--Q4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on 
--antibiotics. Hint: Format the total costs as MONEY for easier comparision.
WITH drugs AS (
		SELECT
			drug_name
			, (CASE WHEN MAX(opioid_drug_flag) = 'Y' THEN 'opioid'
					WHEN MAX(antibiotic_drug_flag) = 'Y' THEN 'antibiotic'
					ELSE 'neither' END)
				AS drug_type
		FROM drug
		GROUP BY drug_name
		)
--
SELECT
	SUM(CASE WHEN drug_type = 'opioid' THEN total_drug_cost END)::money AS total_spent_on_opioids
	, SUM(CASE WHEN drug_type = 'antibiotic' THEN total_drug_cost END)::money AS total_spent_on_antibiotics
FROM prescription
INNER JOIN drugs USING (drug_name);

--Q5 a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT DISTINCT cbsa, cbsaname FROM cbsa WHERE cbsaname LIKE '%TN%';

--Q5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT
	cbsaname
	, SUM(population) AS combined_population
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY combined_population DESC;

--Q5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and 
--population.
SELECT *
FROM population
INNER JOIN fips_county USING (fipscounty)
WHERE fipscounty IN (SELECT fipscounty FROM population EXCEPT SELECT DISTINCT fipscounty FROM cbsa)
ORDER BY population DESC;

SELECT *
FROM population
WHERE fipscounty IN (SELECT fipscounty FROM population EXCEPT SELECT DISTINCT fipscounty FROM cbsa)
ORDER BY population DESC;

--Q6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the 
--total_claim_count.
SELECT
	drug_name
	, COUNT(total_claim_count)
FROM prescription
WHERE total_claim_count >= 3000
GROUP BY drug_name
ORDER BY COUNT(total_claim_count) DESC;

--Q6 b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

WITH opioid_cte AS (--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.		
                   SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT
	drug_name
	, total_claim_count
	, opioid_flag
FROM prescription
INNER JOIN opioid_cte USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--Q6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with --each row.
WITH opioid_cte AS (		--cte to display drugs only once.  For ones that are opioids and listed as Y and N, it will be Y.
			    SELECT drug_name,
			        MAX(opioid_drug_flag) AS opioid_flag
			    FROM drug
				GROUP BY drug_name
)
SELECT
	drug_name
	, total_claim_count
	, opioid_flag
	, nppes_provider_last_org_name
	, nppes_provider_first_name
FROM prescription
INNER JOIN opioid_cte USING(drug_name)
INNER JOIN prescriber USING(npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC

--Q7The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--Q7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain 
--Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag =
--'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables 
--since you don't need the claims numbers yet.
SELECT npi,drug_name
FROM prescriber 
CROSS JOIN drug 
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y';


--Q7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the 
--prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT p1.npi, d.drug_name,p2.total_claim_count AS total_claim
FROM prescriber AS p1
CROSS JOIN drug d
LEFT JOIN prescription p2 ON p1.npi = p2.npi 
						  AND d.drug_name = p2.drug_name
WHERE p1.specialty_description = 'Pain Management'AND p1.nppes_provider_city = 'NASHVILLE'
     AND d.opioid_drug_flag = 'Y'
ORDER BY p1.npi, d.drug_name;

--Q7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the 
--COALESCE function.
SELECT p1.npi, d.drug_name,COALESCE(p2.total_claim_count,0) AS total_claim
FROM prescriber AS p1
CROSS JOIN drug d
LEFT JOIN prescription p2 ON p1.npi = p2.npi 
						  AND d.drug_name = p2.drug_name
WHERE p1.specialty_description = 'Pain Management'AND p1.nppes_provider_city = 'NASHVILLE'
     AND d.opioid_drug_flag = 'Y'
ORDER BY p1.npi, d.drug_name;





















































































































