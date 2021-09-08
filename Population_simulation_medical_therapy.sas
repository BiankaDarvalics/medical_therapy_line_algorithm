/*************************************************************************************
**	DESCRIPTION:
**	Simulate a population with random number of medical therapy lines within
**	a specific follow-up interval. This population can be used to test
**	the macro %medical_therapy_line_algorithm(). The simulated population is 
**	generated in 2 major steps. 
**	First, it creates an "ideal" medical therapy dataset, where
**	every patient has a perfect set of records on medical therapy with only 
**	specified medical therapy drug groups and without drugs taken off 
**	treatment within the same line.
**	Second, it generates "noise" in the ideal dataset to make it more 
**	realistic and useful for testing the features of the medical therapy line
**	algorithm. 
**
**	In the simulated data (simulated_population_final) each line has an:
**	id:												patients' id
**	_medical_t_line:			    Sequential number of the medical therapy line.
**	medical_t_line_start:		  Start date of the line.
**	medical_t_line_end:			  End date of the line.
**	medical_t_date:				    Date of medical therapy.
**	_medical_t_record_number: Sequential number of the medical therapy within 
**														it's line.
**	medical_t_group_n:				Medical therapy group definition for the 
**														medical therapy record. Numeric value (1:10).
** 	medical_t_group_list:			List of medical therapy groups used in the line.
**	unspec_m_t_group_list:		List of medical therapy groups that could be behind
**														an unspecified drug code.
**	
**	As a last step, the simulated data is split into two datasets, which can be
**	used to test the macro %medical_therapy_line_algorithm():
**	simulated_population 
**	simulated_population_medical_t_drugs
**
**	Random variables:
**	-----------------
**	j:										Random number of medical therapy lines (generated   
**												for each patient id). The name of this variable in the
**												final dataset is _medical_t_line.
**	k:										Random number of medical therapy records in the  
**												medical therapy line (generated for each 
**												medical therapy line). The name of this variable  
**												in the final dataset is _medical_t_record_number.
**	
**************************************************************************************
** AUTHOR:			   Bianka Darvalics
** CREATION DATE:	 15.09.2020
**************************************************************************************
*************************************************************************************/



/*
Predefined macro variables:
---------------------------
Note, that these are arbitrary values, and can be changed, if some other 
characteristics seem more reasonable. 
*/
/*Number of patient id-s with both specified and unspecified anti-neoplastic 
drug records.*/
%let N = 100000;

/*Number of patient id-s with only unspecified medical therapy drug records.*/
%let M = 50000;

/*Seed for generated random values.*/
%let seed = 123;

/*Maximum number of medical therapy lines a patient can have in the dataset.*/
%let max_line_num = 7;

/*Maximum number of medical therapy drugs a patient can receive on the same date.*/
%let max_number_of_drugs = 5;

/*Overall number of distinct medical therapy drug codes used in the dataset.
The possible drug codes will be generated as a sequence:
0, 1, 2, 3, ..., &medical_t_drug_all_N.*/
%let medical_t_drug_all_N = 147;

/*Number of days allowed between 2 consecutive medical therapy records to 
consider them as records from the same line.*/
%let days = 45;

/*Start date of the interval for the first medical therapy record.*/
%let medical_t_interval_start = mdy(1,1,2005);

/*End date of the interval for the first medical therapy record.*/
%let medical_t_interval_end = mdy(1,1,2010);

/*Start date of follow-up.*/
%let follow_up_start_date = mdy(12,31,2004);

/*End date of follow-up. Patients shouldn't have medical therapy records 
after this date.*/
%let follow_up_end_date = mdy(12,31,2019);

/*List of all medical therapy groups in the correct order.*/
%let medical_t_group_list = PD-L1/PD-1+Chemo+TKI+AI+PARP+HER-2+IFN-alpha+BCG+Other+Unspec;

/*Number of specified medical therapy groups.*/
%let medical_t_group_num = 9;

/*Maximum number of medical therapy groups included in the list of 
specified medical therapy for the unspecified records.*/
%let max_num_of_m_t_gr = 4;

/***** Medical therapy group drug codes *******/
/*PD-L1/PD-1 immune checkpoint inhibitors*/
%let PD_L1_drugs			= 108;
												
/*Chemotherapy*/
%let chemo_drugs 			= 1 3 9 11 13 14 15 16 19 20 22 25 27 28 30 32 
												33 35 36 37 38 39 40 42 44 46 48 50 51 52 53 
												55 56 57 58 59 66 67 68 70 71 78 79 80 82 85 
												86 88 89 90 93 94 95 96 98 99 115;

/*Tyrosine kinase inhibitors*/
%let TKI_drugs 				= 2 4 5 6 7 12 17 18 21 23 24 26 29 31 34 41 43
												45 47 49 54 60 61 62 63 65 69 72 73 75 76 77
												83 84 87 91 110 111 112 113;

/*Angionesis inhibitors*/
%let AI_drugs					= 81 102 103 104 105 106;

/*Poly ADP ribose polymorase inhibitors*/
%let PARP_drugs				= 100;

/*Human epidermal growth factor receptor 2 antibody*/
%let HER_2_drugs			= 101;

/*Alfa-interferon and interleukin-2*/
%let IFN_alpha_drugs	= 107;

/*Bacille calmette Guerin*/
%let BCG_drugs				= 109;

/*other specified medical therapy*/
%let other_drugs			= 8 10 64 74 92 97 114 116 117 118 119 120 121
												122 123 124 125 126 127 128 129 130 131 132
												133 134 135 136 137 138 139 140 141 142 143
												144 145 146 147;

%let unspec_drugs			= 0;
/**********************************************/



/***** Create an ideal medical therapy dataset ************************/
data _simulated_population_00(rename=(i=id j=_medical_t_line k=_medical_t_record_number));
	call streaminit(&seed);
	format medical_t_line_start medical_t_line_end medical_t_date date9.;
	do i = 1 to &N;
		retain prev_medical_t_line_end medical_t_date;
		a = &medical_t_interval_start;
		b = &medical_t_interval_end;
		prev_medical_t_line_end = a + floor((b-a) * rand('Uniform'));

		do j = 1 to min(round(1 + rand('Poisson',1)),&max_line_num)
					until (prev_medical_t_line_end >= &follow_up_end_date - &days);
			
			medical_t_line_start = prev_medical_t_line_end + round(200 * (rand('Uniform')));

			do k = 1 to min(round(1 + abs(rand('Normal',10,5))),30);
				if k = 1 then medical_t_date = medical_t_line_start;
				else do;
					medical_t_date = 
						min(medical_t_date + max(abs(round(rand('Normal',30,20))),1),
								&follow_up_end_date - &days);
				end;
				medical_t_line_end = medical_t_date + &days;
				output;
			end;

			prev_medical_t_line_end = medical_t_line_end;
		end;
	end;
	drop prev_medical_t_line_end a b;
run;

/*Delete those records that were after the end of follow-up date - &days.*/
proc sort data = _simulated_population_00 nodupkey;
	by id medical_t_line_start medical_t_line_end medical_t_date;
run;

data _simulated_population_01;
	set _simulated_population_00;
	by id medical_t_line_start medical_t_line_end;
	if first.medical_t_line_end;
run;

data _simulated_population_02;
	set _simulated_population_01;
	by id medical_t_line_start medical_t_line_end;
	if last.medical_t_line_start;
run;

proc sort data = _simulated_population_02;
	by id descending _medical_t_line;
run;

data _simulated_population_03;
	set _simulated_population_02;
	by id descending _medical_t_line;
	retain prev_medical_t_line_start;

	if first.id then prev_medical_t_line_start = medical_t_line_start;
	 else if medical_t_line_end >= prev_medical_t_line_start then do;
	 	medical_t_line_end = prev_medical_t_line_start - 1;
		prev_medical_t_line_start = medical_t_line_start;
	 end; 
	 else prev_medical_t_line_start = medical_t_line_start;

	keep id medical_t_line_start medical_t_line_end _medical_t_line;
run;

proc sort data = _simulated_population_03;
	by id _medical_t_line;
run;
proc sql;
	create table _simulated_population_04 as
	select a.id, a.medical_t_line_start, b.medical_t_line_end, a.medical_t_date, 
			a._medical_t_line, a._medical_t_record_number
	from _simulated_population_01 as a
	left join _simulated_population_03 as b
	on a.id = b.id and a.medical_t_line_start = b.medical_t_line_start
	order by a.id, a._medical_t_line, a.medical_t_date;
quit;

/*
Generate medical therapy drugs for each line. For each medical therapy 
line a random number of medical therapy drugs 
(maximum number = &max_number_of_drugs) will be chosen without replacement 
from the possible medical therapy drug list (&list_of_medical_t_drugs) and they 
will be retained through out all medical therapy dates within the line. 
This way each patient id will have "perfect" records within the line.

Macro variables:
----------------
list_of_medical_t_drugs:	List of possible medical therapy drugs.
max_number_of_drugs:			Maximum number of medical therapy drugs is plausible to 
													have within one line.

Random variables:	
-----------------
num_of_drugs_in_line:			Random number of medical therapy drugs asigned to the line.
_medical_t_drug_group{i}:	Random medical therapy drug chosen without replacement.
index_random_drug:				Random index to point on a number in the decreasing list of 
													medical therapy drugs.

Other help varables:
--------------------
drug_list:								Overall medical therapy drug list.
drug_list_WOR:						Decreasing list of medical therapy drugs (due to without
													replacement technic).
length_drug_list:					Length of the decreasing list of medical therapy drugs.
*/

/*Create a macro variable with all the possible medical therapy drug groups
in one string separated by $ $, like: "$1$ $2$ $3$ $4$...$&medical_t_drug_all_N$".*/
data _dummy_medical_t_drug_(rename=(i=medical_t_drug_group));
	do i = 1 to &medical_t_drug_all_N;
		output;
	end;
run;
proc sql noprint;
	select medical_t_drug_group into :list_of_medical_t_drugs separated by '$ $'
		from _dummy_medical_t_drug_;
quit;
%let list_of_medical_t_drugs = $&list_of_medical_t_drugs$;
%put &list_of_medical_t_drugs;

data _simulated_population_05;
	set _simulated_population_04;
	by id _medical_t_line;
	array _medical_t_drug_group {&max_number_of_drugs};
	retain _medical_t_drug_group: num_of_drugs_in_line drug_list_WOR;

	call streaminit(&seed);

	drug_list = "&list_of_medical_t_drugs.";
	/*Intialize the entire drug list [1:&medical_t_drug_all_N].*/
	if first.id then drug_list_WOR = "&list_of_medical_t_drugs.";
	if first._medical_t_line then do;
		num_of_drugs_in_line = min(round(1 + abs(rand('Normal',0,1))),&max_number_of_drugs);
		do i = 1 to &max_number_of_drugs;
			if i <= num_of_drugs_in_line 
				then do;
					length_drug_list = countw(drug_list_WOR);
					index_random_drug = max(ceil(length_drug_list * rand('Uniform')),1);
					_medical_t_drug_group{i} = scan(drug_list_WOR,index_random_drug);
					word = "$"||trim(left(put(_medical_t_drug_group{i},3.)))||"$";
					drug_list_WOR = tranwrd(drug_list_WOR,trim(word),"");
				end;

			else _medical_t_drug_group{i} =.;
		end;
	end;
	drop i drug_list drug_list_WOR index_random_drug length_drug_list word;
run;




/*
Define medical therapy groups for the choosen medical therapy drugs using
the Danish therapeutic code specifications.
*/
data _simulated_population_06;
	set _simulated_population_05;
	format medical_t_group_l $20. medical_t_group_n 2.;
	array mt _medical_t_drug_group:;

	do i = 1 to &max_number_of_drugs;
		if mt(i) in (&PD_L1_drugs) then do;
			medical_t_group_l = "PD-L1/PD-1";
			medical_t_group_n = 1;
			output;
		end;
		else if mt(i) in (&chemo_drugs) then do;
			medical_t_group_l = "Chemo";
			medical_t_group_n = 2;
			output;
		end;
		else if mt(i) in (&TKI_drugs) then do;
			medical_t_group_l = "TKI";
			medical_t_group_n = 3;
			output;
		end;
		else if mt(i) in (&AI_drugs) then do;
			medical_t_group_l = "AI";
			medical_t_group_n = 4;
			output;
		end;
		else if mt(i) in (&PARP_drugs) then do;				
			medical_t_group_l = "PARP";
			medical_t_group_n = 5;
			output;
		end;
		else if mt(i) in (&HER_2_drugs) then do;
			medical_t_group_l = "HER-2";
			medical_t_group_n = 6;
			output;
		end;
		else if mt(i) in (&IFN_alpha_drugs) then do;
			medical_t_group_l = "IFN-alpha";
			medical_t_group_n = 7;
			output;
		end;
		else if mt(i) in (&BCG_drugs) then do;
			medical_t_group_l = "BCG";
			medical_t_group_n = 8;
			output;
		end;
		else if mt(i) in (&other_drugs) then do;
			medical_t_group_l = "Other";
			medical_t_group_n = 9;
			output;
		end;
		else if mt(i) in (&unspec_drugs) then do;
			medical_t_group_l = "Unspec";
			medical_t_group_n = 10;
			output;
		end;
	end;

	drop i;
run;

proc sort data = _simulated_population_06;
	by id medical_t_line_start medical_t_date medical_t_group_n;
run;

proc transpose data = _simulated_population_06 
      					out = _medical_t_group_l(drop = _NAME_)
      					prefix = _medical_t_group_l;
	var medical_t_group_l;
	by id medical_t_date;
run;

data _simulated_population_07;
	merge _simulated_population_06(in=q1 drop = medical_t_group_n medical_t_group_l)
				_medical_t_group_l(in=q2);
	by id medical_t_date;
	if q1 and q2;
run;

data _simulated_population_08;
	set _simulated_population_07;
	by id medical_t_date;
	if first.medical_t_date;
run;

data _simulated_population_09;
	set _simulated_population_08;
	array mtg _medical_t_group_l:;
	format medical_t_group_list $50.;

	do i=1 to dim(mtg) until(mtg(i)="");
		if i = 1 and mtg(1) ^="" then medical_t_group_list = mtg(1);
			else if mtg(i) ^="" then do; 
				if findw(medical_t_group_list, trim(left(mtg(i)))) = 0 then
					medical_t_group_list = catt(medical_t_group_list,"+",mtg(i));
			end;
	end;
	drop i _medical_t_group_l:;
run;


/***** Generate some noise in the ideal dataset ***************************/
/*
Step 1:
-------
Randomly remove some medical therapy drugs from random records (except for
the first record in the line) within the medical therapy line. This 
way the algorithm will be testable on those cases where the patients have 
some drugs removed (and possibly added back later on) from their therapy 
due to eg. side effects.

Step 2:
-------
Define a random interval [interval_start, interval_end] within records 
could be randomly set to unspecified medical therapy drugs. This way the
algorithm will be testable on those cases, where the patient has an
unspecified record between (at least) 2 specified records for the same
medical therapy line.

Step 3:
-------
Define the previous medical therapy date (prev_medical_t_date) and the 
next medical therapy date (next_medical_t_date) for each medical 
therapy record within the line. Randomly set some specified medical 
therapy records to unspecified, if the record fulfills the &days-criteria, 
eg. there's no more than &days has ellapsed since previous or next specified 
medical therapy record. This way the algorithm will be testable 
on those cases, where the patient has an unspecified record "close" enough 
(within prespecified &days days) to a specified record, which suggest it 
belongs to the same medical therapy line.

Step 4:
-------
Define some noise for the list of specified medical therapy groups the 
unspecified record could belong to (unspec_m_t_group_list), by randomly
adding additional medical therapy groups to the list, or removing some 
(without creating an empty list).

Step 5:
-------
Simulate data with only unspecified drugs, and add it to the other 
simulated dataset.
*/


/****** Step 1 ***********/
/* 
Calculated variable:
--------------------
num_of_records_in_line:	Number of medical therapy records in the line.
num_of_drugs_deleted:		Number of medical therapy drugs that could be 
												potentially removed.
*/
proc sql;
	create table _simulated_population_10 as
	select *, count(_medical_t_line) as num_of_records_in_line
	from _simulated_population_09
	group by id, _medical_t_line
	order by id, _medical_t_line, medical_t_date;
quit;

data _simulated_population_11;
	set _simulated_population_10;
	by id _medical_t_line;
	retain num_of_drugs_deleted;
	if first._medical_t_line then 
		num_of_drugs_deleted = 1 + floor((num_of_drugs_in_line - 1) * rand('Uniform'));
run;

data _simulated_population_12;
	set _simulated_population_11;
	array cd _medical_t_drug_group: ;

	call streaminit(&seed);

	if num_of_drugs_in_line > 1 and _medical_t_record_number > 1 then do;
		do i = 1 to num_of_drugs_deleted;
			j = max(ceil(num_of_drugs_in_line * rand('Uniform')),1);
			LessDrug = rand('Binomial',.30,1);
			if LessDrug = 1 then cd(j) =.;
		end;
	end;
	drop i j;
run;


/****** Step 2 ***********/
data _simulated_population_13;
	set _simulated_population_12;
	by id _medical_t_line medical_t_date;
	array cd _medical_t_drug_group: ;
	retain modify_yn interval_start interval_end;

	call streaminit(&seed);

	if first._medical_t_line then do;
		modify_yn = rand('Binomial',.50,1);
		interval_start = 1 + floor((num_of_records_in_line-1) * rand('Uniform'));
		interval_end = interval_start + 
						floor((num_of_records_in_line-interval_start) * rand('Uniform'));
	end;
run;

data _simulated_population_14;
	set _simulated_population_13;
	format unspec_m_t_group_list $50.;
	array cd _medical_t_drug_group: ;
	if interval_start < _medical_t_record_number < interval_end and modify_yn = 1 then do;
		do i = 1 to num_of_drugs_in_line;
			if i = 1 then cd(i) = 0;
			else cd(i) = .;
		end;
		unspec_m_t_group_list = medical_t_group_list;
		medical_t_group_list = 'Unspec';
	end;
	drop modify_yn;
run;


/****** Step 3 ***********/
data _simulated_population_15;
	set _simulated_population_14;
	by id _medical_t_line medical_t_date;
	retain _medical_t_date;
	format prev_medical_t_date date9.;
	if first._medical_t_line then _medical_t_date = medical_t_date;
	else do;
		prev_medical_t_date = _medical_t_date;
		_medical_t_date = medical_t_date;
	end;
	drop _medical_t_date;
run;

proc sort data = _simulated_population_15;
	by id descending _medical_t_line descending medical_t_date;
run;

data _simulated_population_16;
	set _simulated_population_15;
	by id descending _medical_t_line descending medical_t_date;
	retain _medical_t_date;
	format next_medical_t_date date9.;
	if first._medical_t_line then _medical_t_date = medical_t_date;
	else do;
		next_medical_t_date = _medical_t_date;
		_medical_t_date = medical_t_date;
	end;
	drop _medical_t_date;
run;

proc sort data = _simulated_population_16;
	by id _medical_t_line medical_t_date;
run;

data _simulated_population_17;
	set _simulated_population_16;
	format unspec_m_t_group_list $50.;
	array cd _medical_t_drug_group: ;

	call streaminit(&seed);

	modify_bef = rand('Binomial',.50,1);
	modify_aft = rand('Binomial',.50,1);
	if _medical_t_record_number < interval_start and modify_bef = 1 and LessDrug = 0 and
		next_medical_t_date <= medical_t_date + &days then do;
			do i = 1 to num_of_drugs_in_line;
				if i = 1 then cd(i) = 0;
				else cd(i) = .;
			end;
			unspec_m_t_group_list = medical_t_group_list;
			medical_t_group_list = 'Unspec';
	end;
	else if _medical_t_record_number > interval_end and modify_aft = 1 and LessDrug = 0 and
		medical_t_date <= prev_medical_t_date + &days  then do;
			do i = 1 to num_of_drugs_in_line;
				if i = 1 then cd(i) = 0;
				else cd(i) = .;
			end;
			unspec_m_t_group_list = medical_t_group_list;
			medical_t_group_list = 'Unspec';
	end;
	keep id medical_t_line_start medical_t_line_end _medical_t_line medical_t_date 
				_medical_t_drug_group: num_of_drugs_in_line medical_t_group_list 
				unspec_m_t_group_list;
run;


/****** Step 4 ***********/
/*
Calculated variable:
--------------------
unspec_m_t_group_list:		list of specified medical therapy groups the 
													unspecified record belongs to.
*/
data _simulated_population_18;
	set _simulated_population_17;

	call streaminit(&seed);

	modify_yn = rand('Binomial',.70,1);

	length = countw(unspec_m_t_group_list,'+');

	if length > 1 and modify_yn = 1 then do;
		index = max(ceil(length * rand('Uniform')),1);
		m_t_group = scan(unspec_m_t_group_list,index,'+');
		if 1 <= index < length then word = catt(m_t_group,'+');
		else if index = length then word = catt('+',m_t_group);
		unspec_m_t_group_list = transtrn(unspec_m_t_group_list,trim(word),trimn(""));
	end;

	if length = 1 and modify_yn = 1 and unspec_m_t_group_list^ = '' then do;
		index = max(ceil(&medical_t_group_num * rand('Uniform')),1);
		m_t_group = scan("&medical_t_group_list.",index,'+');

		place_m_t_group = findw("&medical_t_group_list.", trim(unspec_m_t_group_list));
		place_m_t_group_new = findw("&medical_t_group_list.", trim(m_t_group));
		if m_t_group ^= unspec_m_t_group_list then do;
			if place_m_t_group < place_m_t_group_new 
				then unspec_m_t_group_list = catt(unspec_m_t_group_list,'+',m_t_group);
			else if place_m_t_group > place_m_t_group_new 
				then unspec_m_t_group_list = catt(m_t_group,'+',unspec_m_t_group_list);
		end;
	end;

	drop modify_yn m_t_group word length index place_m_t_group place_m_t_group_new;
run;


/*Create long formated data from the final version of the simulated data
with the noise*/
data _simulated_population_19;
	set _simulated_population_18;
	array cd _medical_t_drug_group: ;
	do i = 1 to num_of_drugs_in_line;
		if cd(i) ^=. then do;
			medical_t_drug_group = cd(i);
			output;
		end;		
	end;
	drop i num_of_drugs_in_line _medical_t_drug_group:;
run;


/****** Step 5 ***********/

/*
Generate some random specified medical therapy list to choose from
It is now relative to the number of medical therapy groups in the list
eg. the lists with less medical therapy groups are more common.
Macro variable:
---------------
list_of_medical_t_group_list:		List of the all possible medical therapy
																group lists.
length_of_m_t_gr_list:					Length of the list above.
*/
%macro loop(index,index_var);
	add_to_list = scan("&medical_t_group_list.",&index_var,"+");
	_medical_t_drug_group_list{&index + 1} = catt(_medical_t_drug_group_list{&index},"+",add_to_list);
	do m = &index + 2 to &max_num_of_m_t_gr;
		_medical_t_drug_group_list{m} = '';
	end;
	output;
%mend;

data All_medical_t_gr_combination_00;
	array _medical_t_drug_group_list {&max_num_of_m_t_gr} $50.;

	do i = 1 to &medical_t_group_num;
		
		main_medical_t_group_n = i;
		main_medical_t_group = scan("&medical_t_group_list.",i,"+");
		
		_medical_t_drug_group_list{1} = main_medical_t_group;
		do m = 2 to &max_num_of_m_t_gr;;
			_medical_t_drug_group_list{m} = '';
		end;
		output;
		
		do j = i + 1 to &medical_t_group_num;
 			%loop(1,j);
			do k = j + 1 to &medical_t_group_num;
				%loop(2,k);
				do l = k + 1 to &medical_t_group_num;
					%loop(3,l);
				end;
			end;
		end;
	end;
	drop i j k l m add_to_list;
run;

data All_medical_t_gr_combination_01;
	set All_medical_t_gr_combination_00;
	format medical_t_group_list $50.;
	array mt _medical_t_drug_group_list:;
	do i = 1 to &max_num_of_m_t_gr;
		if mt(i) ^= '' then do;
			medical_t_group_list = mt(i);
			output;
		end;
	end;
	keep main_medical_t_group_n main_medical_t_group medical_t_group_list;
run;

proc sort data = All_medical_t_gr_combination_01 
						out = All_medical_t_gr_combination(keep=medical_t_group_list);
	by main_medical_t_group_n medical_t_group_list;
run;

proc sql noprint;
	select medical_t_group_list into :list_of_medical_t_group_list separated by '$'
		from All_medical_t_gr_combination;
quit;
%let length_of_m_t_gr_list = %sysfunc(countw(&list_of_medical_t_group_list,"$"));

data _simulated_population_20(rename=(i=id j=_medical_t_line k=_medical_t_record_number));
	call streaminit(&seed);
	format medical_t_line_start medical_t_line_end medical_t_date date9. 
					medical_t_group_list $50. unspec_m_t_group_list $50.;
	do i = &N + 1 to &N + &M;
		retain prev_medical_t_line_end medical_t_date;
		a = &medical_t_interval_start;
		b = &medical_t_interval_end;

		prev_medical_t_line_end = a + floor((b-a) * rand('Uniform'));

		do j = 1 to min(round(1 + rand('Poisson',1)),&max_line_num)
				until (prev_medical_t_line_end >= &follow_up_end_date - &days);;
			
			medical_t_line_start = prev_medical_t_line_end + max(round(200 * (rand('Uniform'))),&days+1);
			index = max(ceil(&length_of_m_t_gr_list * rand('Uniform')),1);
			unspec_m_t_group_list = scan("&list_of_medical_t_group_list.",index,"$");

			do k = 1 to min(round(1 + abs(rand('Normal',10,5))),30);
				if k = 1 then medical_t_date = medical_t_line_start;
				else do;
					medical_t_date = 
						min(medical_t_date + min(max(abs(round(rand('Normal',30,20))),1),&days),
								&follow_up_end_date - &days);
				end;
				medical_t_line_end = medical_t_date + &days;
				medical_t_drug_group = 0;
				medical_t_group_list = 'Unspec';
				output;
			end;

			prev_medical_t_line_end = medical_t_date;
			output;
		end;
	end;
	drop prev_medical_t_line_end a b index;
run;


/*Delete those records that were after the end of follow-up date - &days.*/
proc sort data = _simulated_population_20 nodupkey;
	by id medical_t_line_start medical_t_line_end medical_t_date;
run;

data _simulated_population_21;
	set _simulated_population_20;
	by id medical_t_line_start medical_t_line_end;
	if first.medical_t_line_end;
run;

data _simulated_population_22;
	set _simulated_population_21;
	by id medical_t_line_start medical_t_line_end;
	if last.medical_t_line_start;
run;

proc sort data = _simulated_population_22;
	by id descending _medical_t_line;
run;

data _simulated_population_23;
	set _simulated_population_22;
	by id descending _medical_t_line;
	retain prev_medical_t_line_start;

	if first.id then prev_medical_t_line_start = medical_t_line_start;
	 else if medical_t_line_end >= prev_medical_t_line_start then do;
	 	medical_t_line_end = prev_medical_t_line_start - 1;
		prev_medical_t_line_start = medical_t_line_start;
	 end; 
	 else prev_medical_t_line_start = medical_t_line_start;

	keep id medical_t_line_start medical_t_line_end _medical_t_line;
run;

proc sort data = _simulated_population_23;
	by id _medical_t_line;
run;
proc sql;
	create table _simulated_population_24 as
	select a.id, a.medical_t_line_start, b.medical_t_line_end, a.medical_t_date, 
			a._medical_t_line, a._medical_t_record_number, a.medical_t_group_list,
			a.unspec_m_t_group_list, a.medical_t_drug_group
	from _simulated_population_21 as a
	left join _simulated_population_23 as b
	on a.id = b.id and a.medical_t_line_start = b.medical_t_line_start
	order by a.id, a._medical_t_line, a.medical_t_date;
quit;

data _simulated_population_25;
	set _simulated_population_24;
	by id _medical_t_line medical_t_date;

	call streaminit(&seed);

	modify_yn = rand('Binomial',.70,1);

	length = countw(unspec_m_t_group_list,'+');

	if first._medical_t_line = 0 and length > 1 and modify_yn = 1 then do;
		index = max(ceil(length * rand('Uniform')),1);
		m_t_group = scan(unspec_m_t_group_list,index,'+');
		if 1 <= index < length then word = catt(m_t_group,'+');
		else if index = length then word = catt('+',m_t_group);
		unspec_m_t_group_list = transtrn(unspec_m_t_group_list,trim(word),trimn(""));
	end;

	if length = 1 and modify_yn = 1 and unspec_m_t_group_list^ = '' then do;
		index = max(ceil(&medical_t_group_num * rand('Uniform')),1);
		m_t_group = scan("&medical_t_group_list.",index,'+');

		place_m_t_group = findw("&medical_t_group_list.", trim(unspec_m_t_group_list));
		place_m_t_group_new = findw("&medical_t_group_list.", trim(m_t_group));
		if m_t_group ^= unspec_m_t_group_list then do;
			if place_m_t_group < place_m_t_group_new 
				then unspec_m_t_group_list = catt(unspec_m_t_group_list,'+',m_t_group);
			else if place_m_t_group > place_m_t_group_new 
				then unspec_m_t_group_list = catt(m_t_group,'+',unspec_m_t_group_list);
		end;
	end;
	drop modify_yn index m_t_group place_m_t_group place_m_t_group_new 
				length word _medical_t_record_number;
run;



/***** Create the final dataset of the population ***************************/
data simulated_population_final;
	set _simulated_population_19
			_simulated_population_25;
run;

proc sort data = simulated_population_final;
	by id medical_t_line_start medical_t_line_end;
run;


/*Create the 2 datasets for testing the medical therapy line defining 
macro %medical_therapy_line_algorithm()*/
data simulated_population_m_t_drugs;
	set simulated_population_final;
	by id medical_t_line_start medical_t_line_end;
	drop _medical_t_line medical_t_line_start medical_t_line_end;
run;

data simulated_population;
	set simulated_population_final;
	by id medical_t_line_start medical_t_line_end;
	format index_date follow_up_end_date date9.;
	if first.id;
	index_date = &follow_up_start_date;
	follow_up_end_date = &follow_up_end_date;

	keep id index_date follow_up_end_date;
run;


/*Delete help datasets*/
proc datasets nodetails nolist;
	delete _simulated_population_: _dummy_medical_t_drug_
					All_medical_t_gr_combination: _medical_t_group_l;
run;
quit;
