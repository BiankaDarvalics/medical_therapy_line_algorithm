/*************************************************************************************
**	DESCRIPTION:
**	Macro, that defines medical therapy in an in-hospital treatment database  
**	and the specified and unspecified medical therapy drug groups according to 
**	treatment codes from the Danish National Patient Registry. Defining
**	these drug groups is necessary before using the medical therapy line
**	defining macro (%medical_therapy_line()).
**	The macro additionally defines medical therapy groups for each drug codes
**	(medical_t_group_l and medical_t_group_n).
**	The groups are the following: PD-L1/PD-1 immune checkpoint inhibitors, 
**	chemotherapy, TKI, Angiogenesis inhibitors, PARP inhibitors, HER-2 antibody, 
**	IFN-alpha/IL-2, BCG, other specified medical therapy, and unspecified medical 
**	therapy with abbreviations we chose for these groups names. For the medical 
**	therapy drugs which were given on the same date, all the drugs on the same
**	date will be assigned to a medical therapy group, and a list will be 
**	calculated in a new variable (medical_t_group_list) with the distinct medical
**	therapy groups used on this date. In the unspecified medical therapy
**	drug codes there could be more than one medical therapy groups
**	they belong to. The list of medical therapy groups for the unspecified drug
**	codes are included in a different variable (unspec_m_t_group_list).
**	The syntax also contains optional formats of the medical therapy drug
**	groups for those, who find them useful.
**	At the end of the syntax there is an example of code you could write to run 
**	the macro on your own data.
**	The macro defines the following new variables:
**
**	medical_t_date:					Date of the medical therapy.
**	medical_t_drug_code:		Treatment code for the medical therapy used in the
**													Danish National Patient Registry.
**	medical_t_drug_group:		Unique numeric value that identifies each medical
**													therapy drugs. Note that the number 0 is used to
**													identify unspecified medical therapy drugs.
**	medical_t_group_l:			Character label for the medical therapy group
**													the medical therapy drug is assigned to.
**	medical_t_group_n:			Unique numeric identifier for the medical therapy 
**													group the medical therapy drug is assigned to.
**	medical_t_group_list:		Character variable with the list of all the medical
**													therapy groups used on the same date for the patient.
**													Note: the macro uses '+' as  a separator between
**													the medical therapy groups in the list.
** 	unspec_m_t_group_list:	Character variable with the list of all the medical
**													therapy groups that could be behind an uspecified 
**													medical therapy code. Note: the macro uses '+' as
**													a separator between the medical therapy groups in 
**													the list.
**
**	PARAMETERS:
**	in_ds:			   	Name of the input dataset with the in-hospital treatment 
**					       	information.
**	out_ds:			   	Name of the output dataset with medical therapy and
**					       	medical therapy drug groups.
**	id_var:			   	Name of the personal ID variable in the input dataset.
**	date_var:		   	Name of the treatment date variable in the input dataset.
**	code_var:		   	Name of the treatment code variable in the input dataset, 
**									This variable is used for defining medical therapy and 
**									medical therapy drug groups.
**	add_code:		   	Specify if there's an additional treatment code (it could be 
**									'tillægskoder' in Danish) in the input dataset.
**					       	y = yes (default), n = no.
**	add_code_var:		Name of the additional treatment code variable in the input 
**					       	dataset. This variable can also be used for defining 
**									medical therapy 
**									and medical therapy drug groups, but only if add_code = y 
**									is set. It can be left blank, if additional treatment codes are
**									not needed.
**	del:			     	Specify if temporary datasets created by the macro should be
**					       	deleted. y = yes (default), n = no.
**************************************************************************************
** AUTHOR:			   Bianka Darvalics
** CREATION DATE:	 29.07.2020
**************************************************************************************
*************************************************************************************/

%macro medical_therapy_drug_groups(
	in_ds = ,
	out_ds = ,
	id_var = ,
	date_var = ,
	code_var = ,
	add_code = y,
	add_code_var = ,
	del = y
	);

	option minoperator;
	%put;
	%put Macro &sysmacroname is executing;
	%put;


	/**********************************************************************************
	CODES 
	**********************************************************************************/
	/*
	Define medical therapy drug groups according to treatment codes from the 
	Danish National Patient Registry (DNPR). 
	Note 1: you might need to add some codes, if new codes have been implemented 
	since the creation of this syntax, or if some treatment codes have been redefined.
	Note 2: the value 0 for the medical therapy drug group variable 
	(medical_t_drug_group) is used for the unspecified medical therapy drugs. This should 
	not be changed, so the medical therapy line defining macro 
	(%medical_therapy_line()) could work properly.
	*/
	%local i j medical_t_drug_all_N medical_t_all_codes;
	%let medical_t_drug_all_N = 147;
	%do i=0 %to &medical_t_drug_all_N.;
		%local medical_t_drug_&i._codes;
	%end;

	/*** All medical therapy codes ********/
	/*Those including sublevels*/
	%let medical_t_all_codes=				"BJHE12" "BWHA" "BWHB1" "BWHB2" "BOHJ10" "BOHJ11"
																	"BOHJ12" "BOHJ13" "BOHJ14" "BOHJ15" "BOHJ16" "BOHJ17"
																	"BOHJ18B" "BOHJ18C" "BOHJ19" "BOHJ28" "BOHJ3";

	/*Those without sublevels*/
	%let medical_t_all_s_codes=			"BWHB" "BWHB3" "BWHB8" "BWHB81" "BWHB82" "BWHB83"
																	"BWHB84" "BWHB86" "BOHJ" "BOHJ1" "BOHJ18" "BOHJ18A"
																	"BOHJ18A1" "BOHJ18A3" "BOHJ18A4" "BOHJ18A5" "BOHJ2"
																	"BOHJ24" "BOHJ25" "BOHJ26";


	/*** All specific medical therapy drug codes ********/
	/*5-fluorouracil*/
	%let medical_t_drug_1_codes=  	"BWHA110" "BWHA117" "BWHA118" "BWHA132" "BWHA146" 
																	"BWHA231" "BWHA232" "BWHA233" "BWHA234" "BWHA251";
	/*abemaciclib*/
	%let medical_t_drug_2_codes=		"BWHA444";
	/*actinomycin-D*/
	%let medical_t_drug_3_codes=		"BWHA121" "BWHA122" "BWHA241";
	/*afatinib*/
	%let medical_t_drug_4_codes=		"BWHA417";
	/*alectinib*/
	%let medical_t_drug_5_codes=		"BWHA440";
	/*alisertib*/
	%let medical_t_drug_6_codes=		"BWHA421";
	/*alpelisib*/
	%let medical_t_drug_7_codes=		"BWHA441";
	/*anagrelid*/
	%let medical_t_drug_8_codes=		"BWHA415";
	/*anthracyline*/
	%let medical_t_drug_9_codes=		"BWHA102" "BWHA103" "BWHA118" "BWHA119" "BWHA131" 
																	"BWHA138" "BWHA139" "BWHA144" "BWHA146" "BWHA165" 
																	"BWHA167" "BWHA170" "BWHA183" "BWHA184" "BWHA185" 
																	"BWHA204" "BWHA210" "BWHA216" "BWHA223" "BWHA232" 
																	"BWHA237" "BWHA258" "BWHA259" "BWHA260" "BWHA143" 
																	"BWHA221" "BWHA250" "BWHA307";
	/*arsentrioxid*/
	%let medical_t_drug_10_codes=		"BWHA443";
	/*asparaginase*/
	%let medical_t_drug_11_codes=		"BWHA188";
	/*axitinib*/
	%let medical_t_drug_12_codes=		"BWHA426";
	/*azacitidin*/
	%let medical_t_drug_13_codes=		"BWHA256";
	/*BCNU*/
	%let medical_t_drug_14_codes=		"BWHA310" "BWHA133";
	/*bendamustin*/
	%let medical_t_drug_15_codes=		"BWHA177";
	/*bleomycin*/
	%let medical_t_drug_16_codes=		"BWHA138" "BWHA150" "BWHA157" "BWHA167" "BWHA201" 
																	"BWHA207" "BWHA224";
	/*bortezomib*/
	%let medical_t_drug_17_codes=		"BWHA402" "BWHA42";
	/*bosutinib*/
	%let medical_t_drug_18_codes=		"BWHA425";
	/*busulfan*/
	%let medical_t_drug_19_codes=		"BWHA182" "BWHA312";
	/*cabazitaxel*/
	%let medical_t_drug_20_codes=		"BWHA263";
	/*cabozantinib*/
	%let medical_t_drug_21_codes=		"BWHA424";
	/*capecitabin*/
	%let medical_t_drug_22_codes=		"BWHA123" "BWHA205" "BWHA222" "BWHA223" "BWHA236" 
																	"BWHA253" "BWHA254";
	/*carfilzomib*/
	%let medical_t_drug_23_codes=		"BWHA432";
	/*ceretinib*/
	%let medical_t_drug_24_codes=		"BWHA431";
	/*cladribin*/
	%let medical_t_drug_25_codes=		"BWHA178";
	/*crizotinib*/
	%let medical_t_drug_26_codes=		"BWHA413";
	/*cyclophosphamid*/
	%let medical_t_drug_27_codes=		"BWHA105" "BWHA117" "BWHA118" "BWHA119" "BWHA134" 
																	"BWHA241" "BWHA247" "BWHA258" "BWHA138" "BWHA139" 
																	"BWHA144" "BWHA156" "BWHA160" "BWHA164" "BWHA165" 
																	"BWHA166" "BWHA174" "BWHA175" "BWHA176" "BWHA218" 
																	"BWHA221" "BWHA307" "BWHA311" "BWHA312" "BWHA143";
	/*cytarabin*/
	%let medical_t_drug_28_codes=		"BWHA158" "BWHA161" "BWHA162" "BWHA163" "BWHA301" 
																	"BWHA302" "BWHA303" "BWHA304" "BWHA307" "BWHA308" 
																	"BWHA310";
	/*dabrafenib*/
	%let medical_t_drug_29_codes=		"BWHA419";
	/*dacarbazin*/
	%let medical_t_drug_30_codes=		"BWHA145" "BWHA167";
	/*dasatinib*/
	%let medical_t_drug_31_codes=		"BWHA411";
	/*daunorubicin*/
	%let medical_t_drug_32_codes=		"BWHA303";
	/*eribulin*/
	%let medical_t_drug_33_codes=		"BWHA262";
	/*erlotinib*/
	%let medical_t_drug_34_codes=		"BWHA404" "BWHA44";
	/*etoposid*/
	%let medical_t_drug_35_codes=		"BWHA111" "BWHA112" "BWHA120" "BWHA127" "BWHA133" 
																	"BWHA138" "BWHA140" "BWHA157" "BWHA164" "BWHA165" 
																	"BWHA183" "BWHA201" "BWHA207" "BWHA214" "BWHA254" 
																	"BWHA305" "BWHA306" "BWHA308" "BWHA310";
	/*fludarabin*/
	%let medical_t_drug_36_codes=		"BWHA172" "BWHA173" "BWHA174" "BWHA175" "BWHA176" 
																	"BWHA217" "BWHA304" "BWHA116";
	/*ftorafur*/
	%let medical_t_drug_37_codes=		"BWHA124";
	/*gemcitabin*/
	%let medical_t_drug_38_codes=		"BWHA114" "BWHA128" "BWHA129" "BWHA170" "BWHA206" 
																	"BWHA211" "BWHA235" "BWHA236" "BWHA238" "BWHA253" 
																	"BWHA259";
	/*hexalen*/
	%let medical_t_drug_39_codes=		"BWHA125";
	/*hydroxurea*/
	%let medical_t_drug_40_codes=		"BWHA181";
	/*ibrutinib*/
	%let medical_t_drug_41_codes=		"BWHA427";
	/*idarubicin*/
	%let medical_t_drug_42_codes=		"BWHA304";
	/*idelalisib*/
	%let medical_t_drug_43_codes=		"BWHA428";
	/*ifosfamid*/
	%let medical_t_drug_44_codes=		"BWHA106" "BWHA120" "BWHA183" "BWHA251" "BWHA308";
	/*imatinib*/
	%let medical_t_drug_45_codes=		"BWHA401" "BWHA41";
	/*irinotecan*/
	%let medical_t_drug_46_codes=		"BWHA212" "BWHA225" "BWHA233" "BWHA234";
	/*ixazomib*/
	%let medical_t_drug_47_codes=		"BWHA439";
	/*klorambucil*/
	%let medical_t_drug_48_codes=		"BWHA168" "BWHA171";
	/*lapatinib*/
	%let medical_t_drug_49_codes=		"BWHA405" "BWHA45";
	/*lomustin*/
	%let medical_t_drug_50_codes=		"BWHA155" "BWHA261";
	/*M2*/
	%let medical_t_drug_51_codes=		"BWHA136";
	/*mAMSA*/
	%let medical_t_drug_52_codes=		"BWHA305";
	/*melphalan*/
	%let medical_t_drug_53_codes=		"BWHA154" "BWHA159" "BWHA309" "BWHA310";
	/*merestinib*/
	%let medical_t_drug_54_codes=		"BWHA435";
	/*methotrexat*/
	%let medical_t_drug_55_codes=		"BWHA115" "BWHA117" "BWHA120" "BWHA122" "BWHA130" 
																	"BWHA161" "BWHA184" "BWHA185" "BWHA219" "BWHA307";
	/*methyl-GAG*/
	%let medical_t_drug_56_codes=		"BWHA120";
	/*mitomycin*/
	%let medical_t_drug_57_codes=		"BJHE12A" "BWHA142" "BWHA151";
	/*mitoxantron*/
	%let medical_t_drug_58_codes=		"BWHA104" "BWHA137" "BWHA166" "BWHA176" "BWHA302";
	/*nelarabin*/
	%let medical_t_drug_59_codes=		"BWHA187";
	/*neratinib*/
	%let medical_t_drug_60_codes=		"BWHA414";
	/*nilotinib*/
	%let medical_t_drug_61_codes=		"BWHA409" "BWHA49";
	/*osimertinib*/
	%let medical_t_drug_62_codes=		"BWHA434";
	/*palbociclib*/
	%let medical_t_drug_63_codes=		"BWHA442";
	/*panobinostat*/
	%let medical_t_drug_64_codes=		"BWHA445";
	/*pazopanib*/
	%let medical_t_drug_65_codes=		"BWHA410";
	/*pemetrexed*/
	%let medical_t_drug_66_codes=		"BWHA239" "BWHA240";
	/*pixantron*/
	%let medical_t_drug_67_codes=		"BWHA189";
	/*platin*/
	%let medical_t_drug_68_codes=		"BWHA107" "BWHA109" "BWHA112" "BWHA126" "BWHA127" 
																	"BWHA128" "BWHA129" "BWHA130" "BWHA132" "BWHA133" 
																	"BWHA140" "BWHA157" "BWHA184" "BWHA185" "BWHA201" 
																	"BWHA203" "BWHA206" "BWHA207" "BWHA209" "BWHA214" 
																	"BWHA224" "BWHA225" "BWHA226" "BWHA238" "BWHA240"
																	"BWHA242" "BWHA251" "BWHA252" "BWHA261";
	/*ponatinib*/
	%let medical_t_drug_69_codes=		"BWHA429";
	/*procarbazin*/
	%let medical_t_drug_70_codes=		"BWHA138"  "BWHA152" "BWHA156" "BWHA168";
	/*pxd101*/
	%let medical_t_drug_71_codes=		"BWHA260";
	/*regorafenib*/
	%let medical_t_drug_72_codes=		"BWHA422";
	/*ribociclib*/
	%let medical_t_drug_73_codes=		"BWHA430";
	/*ridaforolimus*/
	%let medical_t_drug_74_codes=		"BWHA423";
	/*ruxolitinib*/
	%let medical_t_drug_75_codes=		"BWHA418";
	/*sorafenib*/
	%let medical_t_drug_76_codes=		"BWHA407" "BWHA47";
	/*sunitinib*/
	%let medical_t_drug_77_codes=		"BWHA406" "BWHA46";
	/*paclitaxel*/
	%let medical_t_drug_78_codes=		"BWHA202" "BWHA202A" "BWHA203" "BWHA204" "BWHA205" 
																	"BWHA206" "BWHA207"  "BWHA235" "BWHA238";
	/*tegafur_uracil*/
	%let medical_t_drug_79_codes=		"BWHA141" "BWHA142";
	/*temozolomid*/
	%let medical_t_drug_80_codes=		"BWHA215";
	/*temsirolimus*/
	%let medical_t_drug_81_codes=		"BWHA408" "BWHA48";
	/*tioguanin*/
	%let medical_t_drug_82_codes=		"BWHA186";
	/*tipifarnib*/
	%let medical_t_drug_83_codes=		"BWHA403" "BWHA43";
	/*tivozanib*/
	%let medical_t_drug_84_codes=		"BWHA436";
	/*topotecan*/
	%let medical_t_drug_85_codes=		"BWHA213" "BWHA214" "BWHA226";
	/*trabectedin*/
	%let medical_t_drug_86_codes=		"BWHA255";
	/*trametinib*/
	%let medical_t_drug_87_codes=		"BWHA420";
	/*treosulfan*/
	%let medical_t_drug_88_codes=		"BWHA101";
	/*tretionin*/
	%let medical_t_drug_89_codes=		"BWHA179";
	/*trofosfamid*/
	%let medical_t_drug_90_codes=		"BWHA190";
	/*vemurafenib*/
	%let medical_t_drug_91_codes=		"BWHA416";
	/*venetoclax*/
	%let medical_t_drug_92_codes=		"BWHA438";
	/*vinblastin*/
	%let medical_t_drug_93_codes=		"BWHA169" "BWHA130" "BWHA131" "BWHA167" "BWHA168" 
																	"BWHA170" "BWHA185";
	/*vinflunin*/
	%let medical_t_drug_94_codes=		"BWHA257";
	/*vinkristin*/
	%let medical_t_drug_95_codes=		"BWHA119" "BWHA127" "BWHA134" "BWHA135" "BWHA137" 
																	"BWHA138" "BWHA144" "BWHA153" "BWHA156" "BWHA164" 
																	"BWHA165" "BWHA166" "BWHA183" "BWHA216" "BWHA241" 
																	"BWHA258" "BWHA261" "BWHA307" "BWHA143" "BWHA221";
	/*vinorelbin*/
	%let medical_t_drug_96_codes=		"BWHA113" "BWHA126" "BWHA242" "BWHA259";
	/*vorinostat*/
	%let medical_t_drug_97_codes=		"BWHA412";
	/*oxaliplatin*/
	%let medical_t_drug_98_codes= 	"BWHA108" "BWHA222" "BWHA223" "BWHA231" "BWHA234" 
																	"BWHA253" "BWHA254";
	/*docetaxel*/
	%let medical_t_drug_99_codes= 	"BWHA208" "BWHA209" "BWHA210" "BWHA211" "BWHA247" 
																	"BWHA252";
	/*PARP*/
	%let medical_t_drug_100_codes=	"BWHA437" "BWHA433";
	/*HER-2*/
	%let medical_t_drug_101_codes=	"BOHJ13" "BOHJ13A";
	/*bevacizumab*/
	%let medical_t_drug_102_codes=	"BOHJ19B1";
	/*ramucirumab*/
	%let medical_t_drug_103_codes=	"BOHJ19B2";
	/*everolimus*/
	%let medical_t_drug_104_codes=	"BOHJ24";
	/*thalidomid*/
	%let medical_t_drug_105_codes=	"BWHB81";
	/*lenalidomid*/
	%let medical_t_drug_106_codes=	"BWHB82";
	/*alfa-int-leukin-2*/
	%let medical_t_drug_107_codes=	"BWHB10" "BWHB10A" "BWHB10B" "BWHB20";
	/*PD-L1*/
	%let medical_t_drug_108_codes=	"BOHJ19J" "BOHJ19J1" "BOHJ19J2" "BOHJ19J3" "BOHJ19J4"
																	"BOHJ19H7" "BOHJ19H2";
	/*BCG*/
	%let medical_t_drug_109_codes=	"BOHJ25";
	/*encorafenib*/
	%let medical_t_drug_110_codes=	"BWHA446";
	/*binimetinib*/
	%let medical_t_drug_111_codes=	"BWHA447";
	/*lorlatinib*/
	%let medical_t_drug_112_codes=	"BWHA448";
	/*tofacitinib*/
	%let medical_t_drug_113_codes=	"BOHJ28D";
	/*beta-interferon*/
	%let medical_t_drug_114_codes=	"BWHB11";
	/*azathioprin*/
	%let medical_t_drug_115_codes=	"BWHB83";
	/*eculizumab*/
	%let medical_t_drug_116_codes=	"BWHB84";
	/*pomalidomid*/
	%let medical_t_drug_117_codes=	"BWHB86";
	/*CD20-anti*/
	%let medical_t_drug_118_codes=	"BOHJ11" "BOHJ11B" "BOHJ11C";
	/*anti-thymocytglobulin*/
	%let medical_t_drug_119_codes=	"BOHJ12";
	/*gemtuzumab*/
	%let medical_t_drug_120_codes=	"BOHJ14";
	/*CD52-anti*/
	%let medical_t_drug_121_codes=	"BOHJ16" "BOHJ16A";
	/*cetuximab*/
	%let medical_t_drug_122_codes=	"BOHJ17";
	/*TNF-alfa-anti*/
	%let medical_t_drug_123_codes=	"BOHJ18A" "BOHJ18A1" "BOHJ18A3" "BOHJ18A4" "BOHJ18A5";
	/*interleukininhibitor*/
	%let medical_t_drug_124_codes=	"BOHJ18B" "BOHJ18B1" "BOHJ18B2" "BOHJ18B3" "BOHJ18B4"
																	"BOHJ18B5" "BOHJ18B6" "BOHJ18B7" "BOHJ18B8" "BOHJ18B9";
	/*costimulatorinhibitor*/
	%let medical_t_drug_125_codes=	"BOHJ18C" "BOHJ18C1";
	/*anti-IgE*/
	%let medical_t_drug_126_codes=	"BOHJ19A" "BOHJ19A1";
	/*anti-EGFR*/
	%let medical_t_drug_127_codes=	"BOHJ19C" "BOHJ19C1" "BOHJ19C2";
	/*anti-CTLA4*/
	%let medical_t_drug_128_codes=	"BOHJ19D" "BOHJ19D1" "BOHJ19D2";
	/*anti-CD30*/
	%let medical_t_drug_129_codes=	"BOHJ19E" "BOHJ19E1";
	/*mogamulizumab*/
	%let medical_t_drug_130_codes=	"BOHJ19F";
	/*anti-IGF-1*/
	%let medical_t_drug_131_codes=	"BOHJ19G" "BOHJ19G1";
	/*rilotumumab*/
	%let medical_t_drug_132_codes=	"BOHJ19H1";
	/*pertuzumab*/
	%let medical_t_drug_133_codes=	"BOHJ19H3";
	/*vedolizumab*/
	%let medical_t_drug_134_codes=	"BOHJ19H4";
	/*obinutuzumab*/
	%let medical_t_drug_135_codes=	"BOHJ19H5";
	/*belimumab*/
	%let medical_t_drug_136_codes=	"BOHJ19H6";
	/*daratumumab*/
	%let medical_t_drug_137_codes=	"BOHJ19H8";
	/*elotuzumab*/
	%let medical_t_drug_138_codes=	"BOHJ19H9";
	/*anti-IL5*/
	%let medical_t_drug_139_codes=	"BOHJ19I" "BOHJ19I1" "BOHJ19I2" "BOHJ19I3";
	/*anti-T-bi*/
	%let medical_t_drug_140_codes=	"BOHJ19K" "BOHJ19K1";
	/*anti-PDGFR*/
	%let medical_t_drug_141_codes=	"BOHJ19L" "BOHJ19L1";
	/*anti-CGRPR*/
	%let medical_t_drug_142_codes=	"BOHJ19M" "BOHJ19M1" "BOHJ19M2";
	/*anti-IL23*/
	%let medical_t_drug_143_codes=	"BOHJ19N" "BOHJ19N1";
	/*natalizumab*/
	%let medical_t_drug_144_codes=	"BOHJ26";
	/*teriflunomid*/
	%let medical_t_drug_145_codes=	"BOHJ28A";
	/*dimethylfumarat*/
	%let medical_t_drug_146_codes=	"BOHJ28B";
	/*glatirameracetat*/
	%let medical_t_drug_147_codes=	"BOHJ28C";


	/*All specifeied medical therapy codes*/
	%local medical_t_drug_all_codes;
	%let medical_t_drug_all_codes=;
	%do i=1 %to &medical_t_drug_all_N.;
		%let medical_t_drug_all_codes= &medical_t_drug_all_codes. &&medical_t_drug_&i._codes;
	%end;


	/**********************************************************************************
	Extract medical therapy and define medical therapy drug groups from &in_ds
	**********************************************************************************/
	data _medical_t_01;
		set &in_ds;
		if &code_var in: (&medical_t_all_codes) 
			or &code_var in (&medical_t_all_s_codes) 
				%if &add_code = y %then %do;
					or &add_code_var in: (&medical_t_all_codes)
					or &add_code_var in (&medical_t_all_s_codes)
				%end;
		;
	run;

	/*Specified medical therapy drug groups*/
	data _medical_t_02;
		set _medical_t_01;
		format medical_t_date date9. medical_t_drug_code $10.;

		if &code_var in (&medical_t_drug_all_codes.)
			%if &add_code = y %then %do;
				or &add_code_var in (&medical_t_drug_all_codes.) 
			%end;
		then do;
			%do i = 1 %to &medical_t_drug_all_N.;
				if &code_var in (&&medical_t_drug_&i._codes) 
					%if &add_code = y %then %do;
						or &add_code_var in (&&medical_t_drug_&i._codes) 
					%end;	
				then do;
						medical_t_drug_group = &i.;
						medical_t_date = &date_var;
						if &code_var in (&&medical_t_drug_&i._codes)
							then medical_t_drug_code = &code_var;
						%if &add_code = y %then %do;
							else if &add_code_var in (&&medical_t_drug_&i._codes)
								then medical_t_drug_code = &add_code_var;
						%end;
						output;
				end;
			%end;
		end;
		else do;
			medical_t_drug_group = 0;
			medical_t_date = &date_var;
			if (&code_var in: (&medical_t_all_codes) 
						or &code_var in (&medical_t_all_s_codes)) 
				then medical_t_drug_code = &code_var;
			%if &add_code = y %then %do;
				else if (&add_code_var in: (&medical_t_all_codes)
									or &add_code_var in (&medical_t_all_s_codes))
					then medical_t_drug_code = &add_code_var;
			%end;
			output;
		end;
	run;

	proc sort data = _medical_t_02 nodupkey out = _medical_t_03;
		by &id_var medical_t_date medical_t_drug_group;
	run;


	/**********************************************************************************
	Define medical therapy groups for the specified medical therapy drug codes
	**********************************************************************************/
 
	%local PD_L1_drugs chemo_drugs TKI_drugs AI_drugs PARP_drugs IFN_alpha_drugs
					HER_2_drugs BCG_drugs other_drugs unspec_drugs;

	/*PD-L1/PD-1 immune checkpoint inhibitors (PD-L1/PD-1)*/
	%let PD_L1_drugs			= 108;

	/*Chemotherapy (Chemo)*/
	%let chemo_drugs 			= 1 3 9 11 13 14 15 16 19 20 22 25 27 28 30 32 
													33 35 36 37 38 39 40 42 44 46 48 50 51 52 53 
													55 56 57 58 59 66 67 68 70 71 78 79 80 82 85 
													86 88 89 90 93 94 95 96 98 99 115;
	/*TKI (TKI)*/
	%let TKI_drugs 				= 2 4 5 6 7 12 17 18 21 23 24 26 29 31 34 41 43
													45 47 49 54 60 61 62 63 65 69 72 73 75 76 77
													83 84 87 91 110 111 112 113;

	/*Angiogenesis inhibitors (AI)*/
	%let AI_drugs					= 81 102 103 104 105 106;

	/*PARP inhibitors (PARP)*/
	%let PARP_drugs				= 100;

	/*HER-2 antibody (HER-2)*/
	%let HER_2_drugs			= 101;

	/*IFN-alpha/IL-2 (IFN-alpha)*/
	%let IFN_alpha_drugs	= 107;
		
	/*BCG*/
	%let BCG_drugs				= 109;

	/*Other specified medical therapy (Other)*/
	%let other_drugs			= 8 10 64 74 92 97 114 116 117 118 119 120 121
													122 123 124 125 126 127 128 129 130 131 132
													133 134 135 136 137 138 139 140 141 142 143
													144 145 146 147;

	/*Unspecified medical therapy (Unspec)*/
	%let unspec_drugs			= 0;


	data _medical_t_04;
		set _medical_t_03;
		format medical_t_group_l $20. medical_t_group_n 2.;

		if medical_t_drug_group in (&PD_L1_drugs) then do;
			medical_t_group_l = "PD-L1/PD-1";
			medical_t_group_n = 1;
			output;
		end;
		else if medical_t_drug_group in (&chemo_drugs) then do;
			medical_t_group_l = "Chemo";
			medical_t_group_n = 2;
			output;
		end;
		else if medical_t_drug_group in (&TKI_drugs) then do;
			medical_t_group_l = "TKI";
			medical_t_group_n = 3;
			output;
		end;
		else if medical_t_drug_group in (&AI_drugs) then do;
			medical_t_group_l = "AI";
			medical_t_group_n = 4;
			output;
		end;
		else if medical_t_drug_group in (&PARP_drugs) then do;				
			medical_t_group_l = "PARP";
			medical_t_group_n = 5;
			output;
		end;
		else if medical_t_drug_group in (&HER_2_drugs) then do;
			medical_t_group_l = "HER-2";
			medical_t_group_n = 6;
			output;
		end;
		else if medical_t_drug_group in (&IFN_alpha_drugs) then do;
			medical_t_group_l = "IFN-alpha";
			medical_t_group_n = 7;
			output;
		end;
		else if medical_t_drug_group in (&BCG_drugs) then do;
			medical_t_group_l = "BCG";
			medical_t_group_n = 8;
			output;
		end;
		else if medical_t_drug_group in (&other_drugs) then do;
			medical_t_group_l = "Other";
			medical_t_group_n = 9;
			output;
		end;
		else if medical_t_drug_group in (&unspec_drugs) then do;
			medical_t_group_l = "Unspec";
			medical_t_group_n = 10;
			output;
		end;
	run;

	proc sql;
			create table _medical_t_05 as
			select *, count(medical_t_date) as number_of_drugs
			from _medical_t_04 as a 
			group by a.&id_var, a.medical_t_date
			order by a.&id_var, a.medical_t_date, a.medical_t_group_n, a.medical_t_drug_group;
	quit;

	/*Delete those records whit unspecified medical therapy drug registered in 
	the same date as a specified anti_n drug.*/
	data _medical_t_06;
		set _medical_t_05;
		if number_of_drugs > 1 and medical_t_drug_group = 0 then delete;
			drop number_of_drugs;
	run;

	proc transpose data = _medical_t_06 
	      					out = _medical_t_group_l(drop = _NAME_)
	      					prefix = _medical_t_group_l;
		var medical_t_group_l;
		by &id_var medical_t_date;
	run;

	data _medical_t_07;
		merge _medical_t_06(in=q1)
					_medical_t_group_l(in=q2);
		by &id_var medical_t_date;
		if q1 and q2;
	run;

	data _medical_t_08;
		set _medical_t_07;
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

	proc sort data = _medical_t_08;
		by &id_var medical_t_date medical_t_drug_group medical_t_group_n;
	run;

	/**********************************************************************************
	Define medical therapy groups for the unspecified medical therapy drug codes
	**********************************************************************************/
	/*Note: the unspecified drug codes can be assigned to a specific medical
	therapy groups. In some cases one unspecified medical therapy drug code
	is assigned to only one medical therapy group, in other cases it is assigned
	to multiple medical therapy groups.*/

	%local unspec_drug_all_N i;
	%let unspec_drug_all_N = 9;
	%do i=0 %to &unspec_drug_all_N.;
		%local unspec_drug_&i._codes;
	%end;

	/*Unspecified PD-L1/PD-1 immune checkpoint inhibitors (PD-L1/PD-1)*/
	%let  unspec_drug_1_codes = 	"BOHJ" "BOHJ1" "BOHJ19" "BOHJ19H";

	/*Unspecified chemotherapy (Chemo)*/
	%let  unspec_drug_2_codes = 	"BWHA" "BWHA1" "BWHA2" "BWHA3" "BWHA30" "BWHA31"
																"BWHA32" "BJHE12" "BWHB" "BWHB8";
	/*Unspecified TKI (TKI)*/
	%let  unspec_drug_3_codes = 	"BWHA" "BWHA4" "BOHJ" "BOHJ2" "BOHJ28";

	/*Unspecified Angiogenesis inhibitors (AI)*/
	%let  unspec_drug_4_codes = 	"BWHA" "BWHA4" "BWHB" "BWHB8" "BOHJ" "BOHJ1" 
																"BOHJ19" "BOHJ19B" "BOHJ2";

	/*Unspecified PARP inhibitors (PARP)*/
	%let  unspec_drug_5_codes = 	"BWHA" "BWHA4";

	/*Unspecified HER-2 antibodies (HER-2)*/
	%let  unspec_drug_6_codes = 	"BOHJ" "BOHJ1";

	/*Unspecified IFN-alpha/IL-2 (IFN-alpha)*/
	%let  unspec_drug_7_codes = 	"BWHB" "BWHB1" "BWHB2";

	/*Unspecified BCG (BCG)*/
	%let  unspec_drug_8_codes = 	"BOHJ" "BOHJ2";

	/*Unspecified other medical therapy (Other)*/
	%let  unspec_drug_9_codes = 	"BWHA" "BWHA4" "BWHB" "BWHB1" "BWHB2" "BWHB3"
																"BWHB8" "BOHJ" "BOHJ1" "BOHJ10" "BOHJ10A"
																"BOHJ10B" "BOHJ18" "BOHJ19" "BOHJ19H" "BOHJ2"
																"BOHJ28" "BOHJ3";

	%let unspec_m_t_group_list = PD-L1$Chemo$TKI$AI$PARP$HER-2$IFN-alpha$BCG$Other$;

	data _medical_t_09;
		set _medical_t_08;
		format unspec_drug_group_l $20.;
		if medical_t_group_n = 10 then do;
			%do i = 1 %to &unspec_drug_all_N;
					%let unspec_drug_group_l = %scan(&unspec_m_t_group_list.,&i.,"$");
					if medical_t_drug_code in (&&unspec_drug_&i._codes) 
	/*						or c_tilopr in (&&unspec_drug_&i._codes) */
					then do;
							unspec_drug_group_n = &i.;
							unspec_drug_group_l = "&unspec_drug_group_l.";
							output;
					end;
			%end;
		end;
		else do;
			output;
		end;
	run;

	proc sort data = _medical_t_09;
		by &id_var medical_t_date medical_t_drug_group medical_t_group_n unspec_drug_group_n; 
	run;

	proc transpose data = _medical_t_09 
	      					out = _unspec_drug_group_n(drop = _NAME_)
	      					prefix = _unspec_drug_group_n;
		var unspec_drug_group_n;
		by &id_var medical_t_date medical_t_drug_group;
	proc transpose data = _medical_t_09 
	      					out = _unspec_drug_group_l(drop = _NAME_)
	      					prefix = _unspec_drug_group_l;
		var unspec_drug_group_l;
		by &id_var medical_t_date medical_t_drug_group;
	run;

	data _medical_t_10;
		merge _medical_t_08(in=q1)
					_unspec_drug_group_n(in=q2)
					_unspec_drug_group_l(in=q3);
		by &id_var medical_t_date medical_t_drug_group;
		if q1 and q2 and q3;
	run;

	data &out_ds;
		set _medical_t_10;
		array udg _unspec_drug_group_l:;
		format unspec_m_t_group_list $50.;

		do i=1 to dim(udg) until(udg(i)="");
			if i = 1 and udg(1) ^="" then unspec_m_t_group_list = udg(1);
				else if udg(i) ^="" then 
					unspec_m_t_group_list = catt(unspec_m_t_group_list,"+",udg(i));
		end;
		drop i _unspec_drug_group_l: _unspec_drug_group_n:;
	run; 


	/*Delete temporary datasets, if the macro variable &del = y.*/
	%if &del = y %then %do;
		proc datasets nodetails nolist;
			delete _medical_t_: _unspec_drug_group_:;
		run;
		quit;
	%end;

	%put;
	%put Macro &sysmacroname has ended;
	%put;

%mend medical_therapy_drug_groups;

/********* Formats for the grouping variable on the medical therapy drugs *******/
/*
proc format;
	value medical_t_drug_group
		0  ='unspecified medical therapy drug'
		1  ='5-fluorouracil'
		2  ='abemaciclib'	
		3  ='actinomycin-D'	
		4  ='afatinib'	
		5  ='alectinib'	
		6  ='alisertib'
		7  ='alpelisib'	
		8  ='anagrelid'	
		9  ='anthracyline'	
		10 ='arsentrioxid'
		11 ='asparaginase '
		12 ='axitinib'	
		13 ='azacitidin'	
		14 ='BCNU'	
		15 ='bendamustin'	
		16 ='bleomycin'	
		17 ='bortezomib'	
		18 ='bosutinib'	
		19 ='busulfan'	
		20 ='cabazitaxel'	
		21 ='cabozantinib'	
		22 ='capecitabin'	
		23 ='carfilzomib'	
		24 ='ceretinib'	
		25 ='cladribin'	
		26 ='crizotinib'	
		27 ='cyclophosphamid'	
		28 ='cytarabin'	
		29 ='dabrafenib'	
		30 ='dacarbazin'	
		31 ='dasatinib'	
		32 ='daunorubicin'	
		33 ='eribulin'	
		34 ='erlotinib'	
		35 ='etoposid'	
		36 ='fludarabin'	
		37 ='ftorafur'	
		38 ='gemcitabin'	
		39 ='hexalen'	
		40 ='hydroxurea'	
		41 ='ibrutinib'	
		42 ='idarubicin'	
		43 ='idelalisib'	
		44 ='ifosfamid'	
		45 ='imatinib'	
		46 ='irinotecan'	
		47 ='ixazomib'	
		48 ='klorambucil'	
		49 ='lapatinib'	
		50 ='lomustin'
		51 ='M2'
		52 ='mAMSA'	
		53 ='melphalan'
		54 ='merestinib'	
		55 ='methotrexat'	
		56 ='methyl-GAG'	
		57 ='mitomycin'	
		58 ='mitoxantron'
		59 ='nelarabin'	
		60 ='neratinib'	
		61 ='nilotinib'	
		62 ='osimertinib'	
		63 ='palbociclib'
		64 ='panobinostat'
		65 ='pazopanib'	
		66 ='pemetrexed'	
		67 ='pixantron'	
		68 ='platin'
		69 ='ponatinib'
		70 ='procarbazin'
		71 ='pxd101'	
		72 ='regorafenib'	
		73 ='ribociclib'	
		74 ='ridaforolimus'	
		75 ='ruxolitinib'	
		76 ='sorafenib'	
		77 ='sunitinib'	
		78 ='taxane'	
		79 ='tegafur_uracil  '	
		80 ='temozolomid'	
		81 ='temsirolimus'	
		82 ='tioguanin'	
		83 ='tipifarnib'
		84 ='tivozanib'
		85 ='topotecan'	
		86 ='trabectedin'	
		87 ='trametinib'	
		88 ='treosulfan'	
		89 ='tretionin'	
		90 ='trofosfamid'
		91 ='vemurafenib'
		92 ='venetoclax'
		93 ='vinblastin'
		94 ='vinflunin'
		95 ='vinkristin'
		96 ='vinorelbin'
		97 ='vorinostat'
		98 ='oxaliplatin'
		99 ='docetaxel'
		100='PARP'
		101='HER-2
		102='bevacizumab'
		103='ramucirumab'
		104='everolimus'
		105='thalidomid'
		106='lenalidomid'
		107='alfa-int-leukin-2'
		108='PD-L1'
		109='BCG'
		110='encorafenib'
		111='binimetinib'
		112='lorlatinib'
		113='tofacitinib'
		114='beta-interferon'
		115='azathioprin'
		116='eculizumab'
		117='pomalidomid'
		118='CD20-anti'
		119='anti-thymocytglobulin'
		120='gemtuzumab'
		121='CD52-anti'
		122='cetuximab'
		123='TNF-alfa-anti'
		124='interleukininhibitor'
		125='costimulatorinhibitor'
		126='anti-IgE'
		127='anti-EGFR'
		128='anti-CTLA4'
		129='anti-CD30'
		130='mogamulizumab'
		131='anti-IGF-1'
		132='rilotumumab'
		133='pertuzumab'
		134='vedolizumab'
		135='obinutuzumab'
		136='belimumab'
		137='daratumumab'
		138='elotuzumab'
		139='anti-IL5'
		140='anti-T-bi'
		141='anti-PDGFR'
		142='anti-CGRPR'
		143='anti-IL23'
		144='natalizumab'
		145='teriflunomid'
		146='dimethylfumarat'
		147='glatirameracetat';
	run;
*/

/*********************************************************************************/
/*Example:*/
/*
%medical_therapy_drug_groups(
	in_ds = 'name of your input dataset',
	out_ds = 'name of your output dataset',
	id_var = 'name of ID variable',
	date_var = 'name of medical therapy date variable',
	code_var = 'name of variable holding main treatment code for 
							medical therapy therapy',
	add_code = y [y indicates that additional treatment codes should be used]
	add_code_var = 'name of variable holding additional treatment codes for 
									medical therapy',
	del = y [y indicates that you want temporaty datasets deleted]
	);
*/
/*********************************************************************************/
