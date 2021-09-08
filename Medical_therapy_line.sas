/**************************************************************************************
**	DESCRIPTION:
**	Macro, that defines medical therapy lines using specified and unspecified 
**	medical therapy drug codes. It also defines the medical therapy groups present in
**	each line. The groups should be previously assigned to each medical therapy drugs
**	(using the macro %medical_therapy_drug_groups()) used in the line. This macro will
**	create a complete list of all the medical therapy groups that were used in each
**	medical therapy line. The following medical therapy groups are defined:
**	PD-L1/PD-1 immune checkpoint inhibitors, chemotherapy, TKI, 
**	Angiogenesis inhibitors, PARP inhibitors, HER-2 antibody, IFN-alpha/IL-2, BCG, 
**	other specified medical therapy, and unspecified medical therapy with abbreviations
**	we chose for these groups names. The list also has a priority order, that fit
**	best our research purpose.
**	This algorithm can be used on the output dataset of the macro that defines medical 
**	therapy and the medical therapy drug groups in an in-hopital treatment dataset
**	(%medical_therapy_drug_groups()), or on an arbitrary dataset where there is
**	a separate record for each date of medical therapy contact, and for
**	each medical therapy drugs used during that contact. It means,
**	if a patient received multiple medical therapy drugs on the same date, he/she
**	will have multiple records in the dataset, one for each medical therapy drugs.
**	The medical therapy drugs should be defined as a numeric group variable on
**	an arbirtrary scale (eg.: 0-147), but using medical_t_drug_group = 0 to identify
**	unspecified medical therapy drugs. The patient ID variable should have the same
**	name as in the population_ds.
**	At the end of the syntax there is an example of code you could write to run the 
**	macro on a simulated data.
**	The macro defines the following new variables:
**	medical_t_line: 						Sequential number of the medical therapy line.
**	medical_t_line_start:				Start date of the line.	
**	medical_t_line_end:					End date of the line.	
**	medical_t_line_duration:		Duration of the line (in days).
**	medical_t_drug_group::			Array for the medical therapy drug groups that defined 
**															the line.
**	medical_t_line_group_list:	Character variable with the list of medical therapy 
**															groups used in the line. Note: the macro uses '+' as
**															a separator between the medical therapy groups in 
**															the list.
**	
**	PARAMETERS:
**	population_ds:      Name of the input dataset with the study population. This
**											dataset ensures, that medical therapy lines are only defined
**											for patients included in the study population, and it is
**											calculated in the follow-up period of interest. In the
**											dataset there needs to be a variable for 
**											patient ID (id_var),
**											index date (index_date) and  
**											end of follow-up date (follow_up_end_date).
**	medical_t_drug_ds:	Name of the input dataset with the medical therapy records 
**  					          and the defined medical therapy drug groups variable.
**											The macro %medical_therapy_drug_groups() creates such a 
**											dataset, but it can be created without the macro as well.
**											In the dataset there needs to be a variable for:
**											patient ID (id_var),
**											date of medical therapy (medical_t_date) and
**											medical therapy drug group (medical_t_drug_group).
**	out_ds:				      Name of the output dataset with the defined new variables.
**											This dataset has a separate line for each medical therapy
**											line the patient had.
**	id_var:				      Name of the personal ID variable in the study population 
**						          dataset and in the dataset with the medical therapy records. 
**						          Note, that they have to have the same name in those
**											2 datasets.
**	index_date:			    Name of the index date variable in the study population 
**                      dataset.
**	follow_up_end_date:	Name of the end of follow-up date variable in the study 
**						          population dataset.
**  days:				        Number of days used in the algorithm. According to our
**						          validation study the optimal number of days is 45 days, 
**											therefore it is set to default.
**	long_format:		    Specifiy if a long formatted data with all the medical therapy
**						          records should be included as well. The long formatted data
**											will have the same format as the dataset medical_t_drug_ds, eg. 
**											it has a separate line for each date of medical therapy contact
**											and medical therapy drug used in that contact, and it
**											will include the new variables the macro defines. 
**											y = yes (default), n = no.
**	del:				        Specify if temporary datasets created by the macro should be
**						          deleted. y = yes (default), n = no.
**************************************************************************************
** AUTHOR:			         Bianka Darvalics
** CREATION DATE:	       29.07.2020
**************************************************************************************
*************************************************************************************/
%macro medical_therapy_line(
	population_ds = ,
	medical_t_drug_ds = ,
	out_ds = ,
	id_var = ,
 	index_date = ,
	follow_up_end_date = ,
	days = 45,
	long_format = y,
	del = y
	);


	option minoperator;
	%put;
	%put Macro &sysmacroname is executing;
	%put;

	%local i j k all_medical_t_drugs max_number_of_drugs medical_t_drug_all_N
					medical_t_group_list num_of_m_t_gr;
	/*Number of possible medical therapy drug groups in the &medical_t_drug_ds
	dataset.
	Note: you might need to change this macro variable, if you use different 
	groupings than the groupings made by the %medical_therapy_drug_groups() macro, 
	or new codes have been implemented since the creation of this syntax, 
	or if some treatment codes have been redefined.*/
	%let medical_t_drug_all_N = 147;

	/*List of all medical therapy groups in the correct order.*/
	%let medical_t_group_list = PD-L1/PD-1+Chemo+TKI+AI+PARP+HER-2+IFN-alpha+BCG+Other+Unspec;

	/*Number of medical therapy groups.*/
	%let num_of_m_t_gr = 10;

	/*Merge the population data (&population_ds) to the medical therapy dataset with the
	predefined medical therapy drug groups.*/
	proc sql;
			create table _medical_t_drug_00 as
			select a.&id_var, a.&index_date, a.&follow_up_end_date, b.medical_t_date, 
							b.medical_t_drug_group,	b.medical_t_group_list,
							b.unspec_m_t_group_list
			from &population_ds as a 
			left join &medical_t_drug_ds as b
			on a.&id_var = b.&id_var and
				  a.&index_date <= b.medical_t_date <= a.&follow_up_end_date
			order by a.&id_var, b.medical_t_date, b.medical_t_drug_group;
	quit;


	/*Calculate the number of medical therapy drugs on the same
	date by patient for each date (number_of_drugs variable).*/
	proc sql;
			create table _medical_t_drug_01 as
			select *, count(medical_t_date) as number_of_drugs
			from _medical_t_drug_00 as a 
			group by a.&id_var, a.medical_t_date
			order by a.&id_var, a.medical_t_date, a.medical_t_drug_group;
	quit;

	/*One-way frequency tables on:
	1) Number of medical therapy drugs used on the same date
	2) Medical therapy drugs used in the population
	to check the feasability of the data.*/
	proc freq data = _medical_t_drug_01;
		tables number_of_drugs medical_t_drug_group;
	run;

	/*Delete those records whit unspecified medical therapy drug registered in 
	the same date as a specified medical therapy drug.*/
	data _medical_t_drug_02;
		set _medical_t_drug_01;
		if number_of_drugs > 1 and medical_t_drug_group = 0 then delete;
			drop number_of_drugs;
	run;

	/*Recalculate the number of medical therapy drugs on the same
	date by patient for each date (number_of_drugs variable).*/
	proc sql;
			create table _medical_t_drug_03 as
			select *, count(medical_t_date) as number_of_drugs
			from _medical_t_drug_02 as a 
			group by a.&id_var, a.medical_t_date
			order by a.&id_var, a.medical_t_date, a.medical_t_drug_group;
	quit;

	/*Make a macro variable to save the type of drugs used in the &population_ds 
  dataset.*/
	proc freq data = _medical_t_drug_03  ;
		tables medical_t_drug_group / out = _freq_medical_t_drug_group_00;
	run;
	data _freq_medical_t_drug_group_01;
		set _freq_medical_t_drug_group_00;
		if medical_t_drug_group ^=.;
	run;
	proc sql noprint;
		select medical_t_drug_group into :all_medical_t_drugs separated by ' '
		from _freq_medical_t_drug_group_01;
	quit;

	%put The type of drugs used in the &population_ds dataset are:
			&all_medical_t_drugs;

	/*Make a macro variable to save the maximum number of drugs one person
	recieved on the same date in the &population_ds dataset.*/
	proc freq data = _medical_t_drug_03;
		tables number_of_drugs / out = _freq_number_of_drugs_00;
	run;
	data _freq_number_of_drugs_01;
		set _freq_number_of_drugs_00;
		by number_of_drugs;

		if last.number_of_drugs 
			then call symput("max_number_of_drugs",left(put(number_of_drugs,2.)));
	run;
	%put The maximum number of drugs one person recieved on the same date in the
			&population_ds dataset is: &max_number_of_drugs;





	/******************************************************************************/
	/*********** Define medical therapy lines for the specified drugs *************/
	/******************************************************************************/
	/*Keep only the records with specied medical therapy drugs.*/
	data _medical_t_drug_specified_00;
		set _medical_t_drug_03;
		if medical_t_drug_group ^= 0;
	run;

	/*Transpose the drug groups by date. The number of the columns represent how 
	many was the maximum number of drugs one person recieved on the same date.
	The number of columns will be equal to the value in the macro variable: 
	&max_number_of_drugs*/
	proc transpose data = _medical_t_drug_specified_00 
        					out =_medical_t_drug_TA_00(drop = _NAME_)
        					prefix = _medical_t_drug_group;
		var medical_t_drug_group;
		by &id_var medical_t_date medical_t_group_list;
	run;

	/*Transpose the dataset by date for all possible values for the drug groups
	in &population_ds dataset. This will create indicator functions (0,1) for
	each drug.*/
	data _medical_t_drug_specified_01;
		set _medical_t_drug_specified_00;
		/*Dummy indicator is necessary to have the value 1 in the medical therapy
		drug's indicator variable after the transpose procedure, if the patient 
		received that drug on the specific date.*/
		dummy_indicator = 1;
	run;
	proc transpose data = _medical_t_drug_specified_01 
        					out =_medical_t_drug_TB_00(drop = _NAME_) 
        					prefix = _medical_t_drug;
		id medical_t_drug_group;
		var dummy_indicator;
		by &id_var medical_t_date medical_t_group_list;
	run;

	/*Set the indicators to 0 if it is missing in the new transposed dataset.
	Do it only for those included in the macro variable &all_medical_t_drugs, so it won't 
	make unnecessary indicators in the new transposed dataset.*/
	data _medical_t_drug_TB_01;
		set _medical_t_drug_TB_00;
		%do i = 0 %to &medical_t_drug_all_N;
			%if &i in (&all_medical_t_drugs) %then %do;
				if _medical_t_drug&i. =. then _medical_t_drug&i. = 0;
			%end;
		%end;
	run;

	/*Merge the 2 transposed data to get a better overview of the medical therapy
	drug use the patients in &population_ds dataset.*/
	data _medical_t_drug_T_00;
		merge _medical_t_drug_TA_00 (in=q1) _medical_t_drug_TB_01 (in=q2);
		by &id_var medical_t_date;
		if q1 and q2;
	run;

	/*Define the medical therapy lines for the specified records.*/
	data _medical_t_drug_T_01;
		set _medical_t_drug_T_00;
		by &id_var medical_t_date;
		%do j = 0 %to &medical_t_drug_all_N;
			%if &j in (&all_medical_t_drugs) %then %do;
				retain _prev_medical_t_drug&j.;
				if first.&id_var then do;
					_prev_medical_t_drug&j. = _medical_t_drug&j.;
					specified_line = 1;
				end;
				 else if _prev_medical_t_drug&j. < _medical_t_drug&j. then do;
				 	%do k = 0 %to &medical_t_drug_all_N;
						%if &k in (&all_medical_t_drugs) %then %do;
						 	_prev_medical_t_drug&k. = _medical_t_drug&k.;
						%end;
					%end;
					specified_line + 1;
				 end;
			%end;
		%end;

		if medical_t_date = . then specified_line = 0;
	run;

	data _medical_t_drug_T_02;
		set _medical_t_drug_T_01;
		keep &id_var medical_t_date medical_t_group_list specified_line
				  _medical_t_drug_group1-_medical_t_drug_group&max_number_of_drugs;
	run;

	data _medical_t_drug_T_03;
		set _medical_t_drug_T_02;
		by &id_var specified_line medical_t_date;
		retain specified_line_group_list;
		format specified_line_group_list $50.;

		if first.specified_line then do;
			if specified_line_group_list ^= "$Unspec$" then specified_line_group_list = medical_t_group_list;
			else specified_line_group_list = "";
		end;

		drop medical_t_group_list;
	run;





	/******************************************************************************/
	/******************** Define medical therapy lines for both  ******************/
	/********************* the unspecified and specified drugs ********************/
	/******************************************************************************/
  /*Add the unspecified records back to dataset with the specified records
  and the defined specified medical therapy lines.*/
	proc sql;
			create table _medical_t_drug_04 as
			select a.*, b.specified_line, b.specified_line_group_list
			from _medical_t_drug_03(drop=medical_t_group_list) as a 
			left join _medical_t_drug_T_03 as b
			on a.&id_var = b.&id_var and
				  a.medical_t_date = b.medical_t_date
			order by a.&id_var, a.medical_t_date;
	quit;

	/*
	Fill in the "gaps" for the medical therapy line, due to added unspecified 
	records

	Retained help varables (by &id_var):
	-----------------------------------
	prev_medical_t_date:			Previous medical therapy date.
	prev_specified_line:		  Sequential number of the latest specified line in  
								            the previous records.
	prev_line:		            Value of the previous specified_line variable. 
            								Therefore it is missing, if the previous records 
            								was an unspecified record.
	prev_new_specified_line:	The new sequential number of the latest specified 
            								line. It helps to keep track on changes made in the 
            								data step.

	Aimed variable:
	---------------
	medical_t_line:	Final sequential number of the medical therapy line. It is 
		  						defined in 2 data steps:
		  						Step 1: 
		  						Calculate the correct line variable for each record, except
		  						when the unspecified records are in between 2 specified 
		  						records in the same line. For those records, line will be
		  						greater by 1, than the line for the 2 specified records.
		  						Step 2:
		  						Correct the line for these records to the same line as for
		  						the 2 specified records.
	*/
	data _medical_t_drug_05;
		set _medical_t_drug_04;
		by &id_var medical_t_date;
		format prev_medical_t_date date9.;
		retain prev_medical_t_date prev_specified_line medical_t_line prev_line 
						prev_new_specified_line;
		
		if first.&id_var then do;
				medical_t_line = 1;
				prev_medical_t_date = medical_t_date;
				prev_line = specified_line;
				prev_specified_line = specified_line;
				prev_new_specified_line = specified_line;
		end;
		else if prev_medical_t_date + &days < medical_t_date or 
						(prev_specified_line ^= specified_line and specified_line ^=.)
		then do;
			if prev_specified_line = specified_line and specified_line ^= . 
				then do;
					if medical_t_line ^= prev_specified_line and prev_line =. 
						then medical_t_line = prev_new_specified_line;
					prev_medical_t_date = medical_t_date;
					prev_line = specified_line;
					prev_specified_line = specified_line;
					if specified_line ^=.  then prev_new_specified_line = medical_t_line;
			end;
			else do;
				if prev_line = . and prev_medical_t_date + &days >= medical_t_date and
						specified_line ^=. and medical_t_line ^= prev_specified_line
					then do;
						if prev_specified_line ^= specified_line and
								prev_new_specified_line = medical_t_line then medical_t_line + 1;
						prev_medical_t_date = medical_t_date;
						prev_line = specified_line;
						prev_specified_line = specified_line;
						if specified_line ^=.  then prev_new_specified_line = medical_t_line;
				end;
				else do;
					medical_t_line + 1;
					prev_line = specified_line;
					prev_medical_t_date = medical_t_date;
					if specified_line ^=. then do;
						prev_specified_line = specified_line;
						prev_new_specified_line = medical_t_line;
					end;
				end;
			end;
		 end;
		 else do;
		 	if prev_specified_line = specified_line and specified_line ^=. and
					prev_line = . then do;
						medical_t_line = prev_new_specified_line;
			end;
			prev_line = specified_line;
			prev_medical_t_date = medical_t_date;
			if specified_line ^=. then do;
				prev_specified_line = specified_line;
				prev_new_specified_line = medical_t_line;
			end;
		end;

		drop prev_medical_t_date prev_specified_line prev_line prev_new_specified_line;
	run;

	proc sort data = _medical_t_drug_05;
		by &id_var descending medical_t_date;
	run;

	data _medical_t_drug_06;
		set _medical_t_drug_05;
		by &id_var descending medical_t_date;
		retain prev_line;

		if first.&id_var then prev_line = medical_t_line;
		else if prev_line < medical_t_line then medical_t_line = prev_line;
		else prev_line = medical_t_line;

		if specified_line = 0 then medical_t_line = 0;

		drop prev_line;
	run;

	/*Define the unspecified lines by medical therapy groups
		(PD-L1, Chemo, TKI, AI, PARP, HER-2, IFN-alpha, BCG, Other)*/
	proc sort data = _medical_t_drug_06;
		by &id_var medical_t_line medical_t_date;
	run;

	data _medical_t_drug_07;
		set _medical_t_drug_06;
		by &id_var medical_t_line medical_t_date;
		retain medical_t_line_group_list;
		format medical_t_line_group_list $50.;

		if first.medical_t_line then do;
			if specified_line_group_list = "" then medical_t_line_group_list = unspec_m_t_group_list;
			else medical_t_line_group_list = specified_line_group_list;
		end;
	run;

	data _medical_t_drug_08;
		set _medical_t_drug_07;
		by &id_var medical_t_line medical_t_date;
		retain _medical_t_line_group_list;
		if first.medical_t_line then do;
			_medical_t_line_group_list = medical_t_line_group_list;
		end;
		else do;
			if specified_line_group_list ^= "" then do;
				found = 0;
				do i = 1 to countw(specified_line_group_list,"+") until(found=1);
					word = scan(specified_line_group_list,i,"+");
					if findw(medical_t_line_group_list,trim(left(word))) ^= 0 then do;
						found = 1;
						_medical_t_line_group_list = medical_t_line_group_list;
					end;
				end;
				if found = 0 then do;
					_medical_t_line_group_list = specified_line_group_list;
				end;
			end;
			else if unspec_m_t_group_list ^= "" then do;
				found = 0;
				do j = 1 to countw(unspec_m_t_group_list,"+") until(found=1);
					word = scan(unspec_m_t_group_list,j,"+");
					if findw(medical_t_line_group_list,trim(left(word))) ^= 0 then do;
						found = 1;
						_medical_t_line_group_list = medical_t_line_group_list;
					end;
				end;
				if found = 0 then do;
					_medical_t_line_group_list = unspec_m_t_group_list;
				end;
			end;
		end;
		drop i j;
	run;

	data _medical_t_drug_09;
		set _medical_t_drug_08;
		by &id_var medical_t_line medical_t_date;
		retain new_medical_t_line prev_medical_t_line prev_medical_t_line_group_list;

		if first.&id_var then new_medical_t_line = medical_t_line;
			if first.medical_t_line then do; 
				prev_medical_t_line_group_list = _medical_t_line_group_list;
				prev_medical_t_line = medical_t_line;
				if first.&id_var = 0 then new_medical_t_line + 1;
			end;
			else do;
				found_prev = 0;
				do i = 1 to countw(_medical_t_line_group_list,"+") until(found_prev=1);
					word = scan(_medical_t_line_group_list,i,"+");
					if findw(prev_medical_t_line_group_list,trim(left(word))) ^= 0 then do;
						found_prev = 1;
					end;
				end;

				if found_prev = 0 and prev_medical_t_line = medical_t_line
					then do;
						new_medical_t_line + 1;
						prev_medical_t_line_group_list = _medical_t_line_group_list;
				end;
				else if prev_medical_t_line ^= medical_t_line
					then new_medical_t_line + 1;
			end;

			rename new_medical_t_line = medical_t_line
							medical_t_line = medical_t_line_old;
			drop found found_prev prev_medical_t_line_group_list
						medical_t_line_group_list prev_medical_t_line i word;
	run;

	/*Correctly define medical therapy group list for the line
		(medical_t_line_group_list).*/
	data _medical_t_drug_10;
		set _medical_t_drug_09;
		unspec_in_line = 0;
		spec_in_line = 0;
		if unspec_m_t_group_list ^= "" then unspec_in_line = 1;
		else if specified_line_group_list ^= "" then spec_in_line = 1;
	run;

	/*Calculate how many unspecified and specified records are within
	the line.*/
	proc sql;
		create table _medical_t_drug_11 as
			select *, sum(unspec_in_line) as sum_unspec_in_line,
							sum(spec_in_line) as sum_spec_in_line,
							count(medical_t_line) as No_records_in_line
			from _medical_t_drug_10
			group by &id_var, medical_t_line
			order by &id_var, medical_t_line, medical_t_date;
	run;
	quit;

	/*The unspecified lines (= defined only by unspecified records)
	that belongs to only one medical therapy group should be named 
	as the medical therapy group, not just unspecified (Unspec).*/
	data _medical_t_drug_12;
		set _medical_t_drug_11;
		if sum_unspec_in_line = No_records_in_line then do;
			if countw(unspec_m_t_group_list,"+") > 1 then true_unspec = 1;
			else true_unspec = 0;
		end;
	run;

	proc sql;
		create table _medical_t_drug_13 as
			select *, sum(true_unspec) as sum_true_unspec_in_line
			from _medical_t_drug_12
			group by &id_var, medical_t_line
			order by &id_var, medical_t_line, medical_t_date;
	run;
	quit;

	data _medical_t_drug_14;
		set _medical_t_drug_13;
		by &id_var medical_t_line medical_t_date;
		format new_unspec_m_t_group_list $50.; 
		retain new_unspec_m_t_group_list;
		array _m_t_group_list{&num_of_m_t_gr} $50.;

		if sum_unspec_in_line = No_records_in_line then do;
			if first.medical_t_line then do;
				if true_unspec = 0 then new_unspec_m_t_group_list = unspec_m_t_group_list;
				else if true_unspec = 1 then new_unspec_m_t_group_list = "Unspec";
			end;
			else do;
				if true_unspec = 0 and  
								findw(new_unspec_m_t_group_list,trim(unspec_m_t_group_list)) = 0
					then do;
						place_m_t_group_new = findw("&medical_t_group_list.", trim(unspec_m_t_group_list));
						stop = 0; 
						do i = 1 to countw(new_unspec_m_t_group_list,'+') until(stop=1);
							_m_t_group_list{i} = scan(new_unspec_m_t_group_list,i,'+');
							place_m_t_group = findw("&medical_t_group_list.", trim(_m_t_group_list{i}));
							if place_m_t_group_new < place_m_t_group then do;
								stop = 1;
								new_unspec_m_t_group_list = tranwrd(new_unspec_m_t_group_list,
																							trim(_m_t_group_list{i}),
																							catt(trim(unspec_m_t_group_list),'+',trim(_m_t_group_list{i})));
							end;
						end;
					end;
				else if true_unspec = 1 and findw(new_unspec_m_t_group_list,"Unspec") = 0 
					then new_unspec_m_t_group_list = catt(new_unspec_m_t_group_list,"+","Unspec");
			end;
		end;
		else new_unspec_m_t_group_list =.;

		if last.medical_t_line;

		drop _m_t_group_list: place_m_t_group_new place_m_t_group stop i;
	run;

	proc sql;
		create table _medical_t_drug_15 as
			select a.*, b.new_unspec_m_t_group_list
			from _medical_t_drug_13 as a
			inner join _medical_t_drug_14 as b
			on a.&id_var = b.&id_var and
					a.medical_t_line = b.medical_t_line
			order by &id_var, medical_t_line, medical_t_date;
	run;
	quit;

	/*Fix the drug group list in a way that the category "Other" and
	"Unspec" is placed to the end of the list.*/
	data _medical_t_drug_16;
		set _medical_t_drug_15;
		format other_groups $10.;
		other_groups = "";
		if find(new_unspec_m_t_group_list,"Other+Unspec+") ^= 0 then do;
			new_unspec_m_t_group_list = transtrn(new_unspec_m_t_group_list,"Other+Unspec+",trimn(""));
			other_groups = "+Other+Unspec";
		end;
		else if find(new_unspec_m_t_group_list,"Other+") ^= 0 then do;
			new_unspec_m_t_group_list = transtrn(new_unspec_m_t_group_list,"Other+",trimn(""));
			other_groups = "+Other";
		end;
		else if find(new_unspec_m_t_group_list,"Unspec+") ^= 0 then do;
			new_unspec_m_t_group_list = transtrn(new_unspec_m_t_group_list,"Unspec+",trimn(""));
			other_groups = "+Unspec";
		end;

		new_unspec_m_t_group_list = catt(new_unspec_m_t_group_list,trim(other_groups));
		drop other_groups;
	run;

	/*Final definition of the medical therapy group list for the line
	(medical_t_line_group_list) for those lines, where 
		-there has been both specified and unspecified records,  
		-there has been only unspecified records.*/
	data _medical_t_drug_17;
		set _medical_t_drug_16;
		by &id_var medical_t_line medical_t_date;
		retain new_group_list;
		format new_group_list $50.;

		if first.medical_t_line then do;
			if sum_unspec_in_line = No_records_in_line 
				then new_group_list = new_unspec_m_t_group_list;
			else if sum_spec_in_line ^= No_records_in_line 
				then do;
					if spec_in_line = 1 
						then new_group_list = specified_line_group_list;
					if spec_in_line = 0 
						then new_group_list = "";
				end;
			else if sum_spec_in_line = No_records_in_line
				then new_group_list ="";
			else if unspec_in_line = 1 
				then new_group_list ="";
		end;
		else do;
			if sum_unspec_in_line ^= No_records_in_line 
					and sum_spec_in_line ^= No_records_in_line
					and spec_in_line = 1
				then new_group_list = specified_line_group_list;
		end;
	run;

	proc sort data = _medical_t_drug_17;
		by &id_var descending medical_t_line descending medical_t_date;
	run;

	data _medical_t_drug_18;
		set _medical_t_drug_17;
		by &id_var descending medical_t_line descending medical_t_date;
		retain medical_t_line_group_list;
		if first.medical_t_line then do;
			if new_group_list = "" 
				then medical_t_line_group_list = _medical_t_line_group_list;
			else if new_group_list ^= "" 
				then medical_t_line_group_list = new_group_list;
		end;

		drop _medical_t_line_group_list new_group_list specified_line_group_list
					spec_in_line unspec_in_line sum_spec_in_line sum_unspec_in_line 
					No_records_in_line sum_true_unspec_in_line 
					new_unspec_m_t_group_list;
	run;

	proc sort data = _medical_t_drug_18;
		by &id_var medical_t_line medical_t_date;
	run;

	/*Define the start date and end date of the medical therapy line*/
	data _medical_t_drug_19;
		set _medical_t_drug_18;
		by &id_var medical_t_line medical_t_date;

		format medical_t_line_start date9. medical_t_line_end date9.;
		retain medical_t_line_start;

		if medical_t_date ^=. then do;
			medical_t_line_end = min(medical_t_date + &days,&follow_up_end_date);
		end;

		if first.medical_t_line then do;
			medical_t_line_start = medical_t_date;
		end;
	run;

	data _medical_t_drug_20;
		set _medical_t_drug_19;
		by &id_var medical_t_line_start;
		if last.medical_t_line_start;

		drop medical_t_drug_group number_of_drugs specified_line medical_t_date;
	run;

	proc sort data = _medical_t_drug_20;
		by &id_var descending medical_t_line;
	run;

	data _medical_t_drug_21;
		set _medical_t_drug_20;
		by &id_var descending medical_t_line;
		format prev_medical_t_line_start date9.;
		retain prev_medical_t_line_start;

		if first.&id_var then prev_medical_t_line_start = medical_t_line_start;
		else if medical_t_line_end >= prev_medical_t_line_start then do;
		 	medical_t_line_end = prev_medical_t_line_start - 1;
			prev_medical_t_line_start = medical_t_line_start;
		end; 
		else prev_medical_t_line_start = medical_t_line_start;

		medical_t_line_duration = medical_t_line_end - medical_t_line_start;

		keep &id_var medical_t_line_start medical_t_line_end medical_t_line medical_t_line_duration
					medical_t_line_group_list unspec_m_t_group_list medical_t_line_old;
	run;

	proc sort data = _medical_t_drug_21;
		by &id_var medical_t_line;
	run;

	/*Retreive information on the medical therapy drugs, the medical therapy
	line was based on.*/
	proc transpose data = _medical_t_drug_03 
          				out = _medical_t_drug_TC_00(drop = _NAME_) 
          				prefix = _medical_t_drug_group;
		var medical_t_drug_group;
		by &id_var medical_t_date;
	run;

	proc sql;
		create table _medical_t_drug_22 as
		select a.medical_t_line, a.medical_t_line_group_list, a.unspec_m_t_group_list,
						b.* 
		from _medical_t_drug_19 as a
		left join _medical_t_drug_TC_00 as b
		on a.&id_var = b.&id_var and
			  a.medical_t_date = b.medical_t_date
		order by b.&id_var, a.medical_t_line, b.medical_t_date;
	quit;

	data _medical_t_drug_23;
		set _medical_t_drug_22;
		by &id_var medical_t_line;
		array cd _medical_t_drug_group:;
		array medical_t_drug_group {&max_number_of_drugs};

		retain medical_t_drug_group: Specified;
		if first.medical_t_line then do;
			Specified = 0;
			if cd(1) ^= 0 then do;
				Specified = 1;
				do i = 1 to &max_number_of_drugs;
					medical_t_drug_group{i} = cd(i);
				end;
			end;
			else do;
				do i = 1 to &max_number_of_drugs;
					medical_t_drug_group{i} = cd(i);
				end;
			end;
		end;
		else if Specified = 0 then do;
			if cd(1) ^= 0 then do;
				Specified = 1;
				do i = 1 to &max_number_of_drugs;
					medical_t_drug_group{i} = cd(i);
				end;
			end;
		end;
	run;

	data _medical_t_drug_24;
		set _medical_t_drug_23;
		by &id_var medical_t_line;
		if last.medical_t_line;

		keep &id_var medical_t_line medical_t_drug_group: medical_t_line_group_list;
	run;

	/*Create the final table.*/
	proc sql;
		create table &out_ds. as
		select *
		from _medical_t_drug_21(drop = medical_t_line_group_list 
																		unspec_m_t_group_list) as a
		left join _medical_t_drug_24 as b
		on a.&id_var = b.&id_var and 
			  a.medical_t_line = b.medical_t_line;
	quit;



	/*Create long formatted dataset, if the macro variable &long_format = y.*/
	%if &long_format = y %then %do;
		data _medical_t_line_L_00;	
			set _medical_t_drug_18;
			by &id_var medical_t_date;
			if first.medical_t_date;

			drop medical_t_drug_group specified_line true_unspec;
		run;

		proc sql;
			create table _medical_t_line_L_01 as
			select a.*, b.medical_t_line_start, b.medical_t_line_end, b.medical_t_line_duration
			from _medical_t_line_L_00 as a
			left join _medical_t_drug_21 as b
			on a.&id_var = b.&id_var and 
				  a.medical_t_line = b.medical_t_line;
		quit;

		proc sql;
			create table &out_ds._L as
			select a.*, b.* 
			from _medical_t_line_L_01 as a
			left join _medical_t_drug_TC_00 as b
			on a.&id_var = b.&id_var and
				  a.medical_t_date = b.medical_t_date;
		quit;
	%end;



	/*Delete temporary datasets, if the macro variable &del = y.*/
	%if &del = y %then %do;
		proc datasets nodetails nolist;
			delete _medical_t_drug_: _freq_medical_t_drug_group_: _freq_number_of_drugs_: 
							_medical_t_drug_T: _medical_t_line_L_:;
		run;
		quit;
	%end;

	%put;
	%put Macro &sysmacroname has ended;
	%put;

%mend medical_therapy_line;

/*********************************************************************************/
/*
Example:
This is an example of using the macro on a simulated population. The simulated
population syntax should be run before the macro. This syntax creates the 2 datasets,
which can be used as parameters population_ds (simulated_population) and
medical_t_drug_ds (simulated_population_medical_t_drugs) for the 
%medical_therapy_line() macro. But you can skip this simulation
step, if you'd like to use your own data to test the algorithm.

Simulate a population for testing:
----------------------------------
*/
/*
%let &Syntax_path = 'the path to the folder with the population simulation syntax';
%include "&Syntax_path\Population_simulation_medical_therapy.sas";
*/

/*
Run the medical therapy line macro with the simulated population:
--------------------------------------------------------------
*/
/*
%medical_therapy_line(
	population_ds = simulated_population,
	medical_t_drug_ds = simulated_population_m_t_drugs,
	out_ds = medical_t_line_ds,
	id_var = id,
	index_date = index_date,
	follow_up_end_date = follow_up_end_date,
	days = 45,
	long_format = y,
	del = y
	);
*/
/**********************************************************************************/
