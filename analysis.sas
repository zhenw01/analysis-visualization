libname heartlib "/home/u63984249/sasuser.v94/Example";

filename heart "/home/u63984249/sasuser.v94/Example/heart_attack_predictions.csv";

proc import datafile=heart
out=heartlib.heart_data
dbms=csv;

RUN;

/* Data at a glance */

proc sql;
	create table heartlib.summary as
	select 
		count(*)	as total_rows,
		mean(Age)	as avg_age,
		mean(cholesterol_level) as avg_chol,
		mean(blood_pressure) as avg_bp
	From work.heart_data;
quit;

/* Observing for smoking based on outcomes */

proc sql;
	select
		smoking_history,
		heart_attack_outcome,
		count(*)	as total_count,
		mean(cholesterol_level) as avg_chol,
		mean(blood_pressure) as avg_bp
	from heartlib.heart_data
	group by smoking_history, heart_attack_outcome;
quit;

proc sql;
	select
		heart_attack_outcome,
		count(*) as outcome_count,
		(count(*) * 100.0 /(select count(*) from heartlib.heart_data)) as pct_outcome
	from heartlib.heart_data
	group by Heart_attack_outcome;
quit;


/* observing cholesteral ratio */
/* filtering zeroes which are physiologically impossible */
PROC SQL;
	Create table work.filtered_chol_data AS
	SELECT Cholesterol_Level, hdl_cholesterol, ldl_cholesterol, heart_attack_outcome
	FROM work.heart_data
	WHERE HDL_Cholesterol <> 0
		AND LDL_Cholesterol <> 0;
QUIT;

/* Observing the relationship between cholesterol ratio and heart attack outcome */

DATA heartlib.filtered_chol_ratio_data;
	SET work.filtered_chol_data;
	chol_ratio = HDL_Cholesterol / LDL_Cholesterol;
RUN;

proc logistic data=heartlib.filtered_chol_ratio_data;
	model Heart_Attack_Outcome(event="Died") = chol_ratio;
run;

/* The logistic model shows p-value of 0.3789 and an odds ratio of 0.993, indicating that cholesterol ratio is not a good predictor for survival once a heart attack has occured */



/* Pivoting the table to observe outcome based on age */

proc sql;
	create table work.age_data as
	select
		age,
		sum(case when Heart_Attack_Outcome='Survived' then 1 else 0 end) as Survived_Count,
        sum(case when Heart_Attack_Outcome='Died' then 1 else 0 end)     as Died_Count
    from heartlib.heart_data
    group by age;
    select
    	*,
        (Survived_count/(Survived_count+died_count) * 100.0) As survival_rate
    from work.age_data
    group by age;
quit;



