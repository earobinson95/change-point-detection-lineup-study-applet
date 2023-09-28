/*Input dataset all_data_cleanas lineup*/

data lineup;
set lineup;
/*for sorting confidence level*/
conf_level_code=1*(conf_level="Strongly Disag") + 2*(conf_level="Disagree") + 
3*(conf_level="Neutral") + 4* (conf_level="Agree") + 5* (conf_level="Strongly Agree");
/*for sorting educational attainment*/
educ_code= 1*(academic_study="High School or Less") + 2*(academic_study="Some Undergraduate Courses") +
3*(academic_study="Undergraduate Degree") + 4*(academic_study="Some Graduate Courses") +
5*(academic_study="Graduate Degree");
run;

data lineup_c;
set lineup;
where correct=1;
run;

/*Correct and incorrect controlling for magnitude and variance*/

proc sort data=lineup;
by correct conf_level_code;
run;

proc freq data=lineup order=data;
title "Accuracy vs confidence";
tables correct*conf_level/cmh chisq measures nocol nopct cl;
run;

proc sort data=lineup;
by sigma theta_abs  conf_level_code;
run;
proc freq data=lineup order=data;
title "Accuracy vs confidence: controlling for magnitude and direction";
tables sigma*theta_abs*correct*conf_level/cmh chisq measures nocol nopct cl;
tables sigma*correct*conf_level/noprint cmh chisq measures cl;
tables theta_abs*correct*conf_level/noprint cmh chisq measures cl;
run;

/*magnitude/variance*/
proc sort data=lineup;
by theta_abs conf_level_code;
run;

proc freq data=lineup order=data;
title "Correct identification";
where correct=1;
tables sigma*theta_abs*conf_level/cmh chisq measures nocol nopct cl;
/*exact mhchi/maxtime=500;*/
run;



proc freq data=lineup order=data;
title "Incorrect identification";
where correct=0;
tables sigma*theta_abs*conf_level/cmh chisq measures nocol nopct cl ;
run;

/*STEM related*/

proc sort data=lineup;
by stem_related conf_level_code;

proc freq data=lineup order=data;
title "Work in Stem";
where stem_related IN ("Yes","No");
tables stem_related*conf_level/cmh chisq measures nocol nopct cl;
run;

proc sort data=lineup;
by stem_related correct conf_level_code;

proc freq data=lineup order=data;
title "Work in Stem";
where stem_related IN ("Yes","No");
tables stem_related*correct*conf_level/cmh chisq measures nocol nopct cl;
run;

/*Healthcare Related*/
proc sort data=lineup;
by health_related conf_level_code;

proc freq data=lineup order=data;
title "Work in Healthcare";
where health_related IN ("Yes","No");
tables health_related*conf_level/cmh chisq measures nocol nopct cl;
run;

proc sort data=lineup;
by health_related correct conf_level_code;

proc freq data=lineup order=data;
title "Work in Healthcare";
where health_related IN ("Yes","No");
tables health_related*correct*conf_level/cmh chisq measures nocol nopct cl;
run;

/*Educational Attainment*/

proc sort data=lineup;
by educ_code conf_level_code;

proc freq data=lineup order=data;
title "Educational Attainment";
where educ_code IN (1,2,3,4,5);
tables academic_study*conf_level/cmh chisq measures nocol nopct cl scores=modridit;
run;

proc sort data=lineup;
by educ_code correct conf_level_code;

proc freq data=lineup order=data;
title "Educational Attainment";
where educ_code IN (1,2,3,4,5);
tables academic_study*correct*conf_level/cmh chisq measures nocol nopct cl scores=modridit;
run;
