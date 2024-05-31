libname proj 'H:\WAWeight\Projection\';

%let nbedup=0.2128; 
%let nbedu_meanp=-0.00599; 
%let world_edu=9.3;
%let world_saf=0.664294573;

proc import datafile="H:\WAWeight\Projection\saf.csv"
        out=proj.saf
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;

proc import datafile="H:\WAWeight\Projection\PROJresult_AGE_SSP1_V12.csv"
        out=proj.SSP1
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;


proc import datafile="H:\WAWeight\Projection\PROJresult_AGE_SSP2_V12.csv"
        out=proj.SSP2
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;


proc import datafile="H:\WAWeight\Projection\PROJresult_AGE_SSP3_V12.csv"
        out=proj.SSP3
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;


proc import datafile="H:\WAWeight\Projection\PROJresult_AGE_SSP4_V12.csv"
        out=proj.SSP4
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;


proc import datafile="H:\WAWeight\Projection\PROJresult_AGE_SSP5_V12.csv"
        out=proj.SSP5
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;

proc import datafile="H:\WAWeight\Projection\estimates1950_2015.csv"
        out=proj.estimates
        dbms=csv
        replace;
        getnames=yes;
        guessingrows=200;
run;


data proj.projmacro;
set proj.SSP1-proj.SSP5;
run;

proc sort data=proj.saf; by region;run;
proc transpose data=proj.saf out=proj.saftransp(rename=(col1=saf));
by region;
run;

data proj.saftransp;
set proj.saftransp;
time2=compress(_NAME_, '', 'kd');
time=time2+0;
drop _NAME_ time2;
run;

proc sort data=proj.saftransp; by region time;run;
proc sort data=proj.projmacro; by region time;run;
data work.projection;
merge proj.projmacro (in=in1) proj.saftransp;
by region time;
if in1;

if edu in ('e1' 'e2') then nbedu=1;
if edu in ('e3') then nbedu=6;
if edu in ('e4') then nbedu=9;
if edu in ('e5') then nbedu=12;
if edu in ('e6') then nbedu=16;

if agest=-5 then delete;
pop=pop*1000;
keep region time agest sex nbedu edu pop saf scen;
run;

proc sort data=proj.saftransp; by region time;run;
proc sort data=proj.estimates; by region time;run;
data work.estimates;
merge proj.estimates (in=in1) proj.saftransp;
by region time;
if in1;

if edu in ('e1' 'e2') then nbedu=1;
if edu in ('e3') then nbedu=6;
if edu in ('e4') then nbedu=9;
if edu in ('e5') then nbedu=12;
if edu in ('e6') then nbedu=16;

scen="Estim";

pop=pop*1000;
keep region time agest sex nbedu edu pop saf scen;
run;

data work.completedata;
set work.estimates work.projection;
if time<1970 then delete;
run;


proc tabulate data=work.completedata out=work.nbeduaverage (keep=region time scen nbedu_mean);
var nbedu;
class region time scen;
table region*time*scen,nbedu*(mean);
freq pop;
run;


proc sort data=work.nbeduaverage; by region time scen;run;
proc sort data=work.completedata; by region time scen;run;
data proj.completedata2;
merge work.completedata (in=in1) work.nbeduaverage;
by region time scen;
if in1;

normalizedsaf=saf/&world_saf;

w=exp(&nbedup*nbedu+&nbedu_meanp*nbedu*nbedu_mean) /exp(&nbedup*&world_edu+&nbedu_meanp*&world_edu*nbedu_mean)*normalizedsaf;

pop_weight=pop*w;


run;

proc tabulate data=proj.completedata2 out=work.workingage (drop=_type_ _page_ _table_ rename=(pop_sum=wa_sum pop_weight_Sum=wa_weight));
var pop_weight pop;
class time region scen;
table scen*region,time*pop_weight*(sum) time*pop*(sum);
where 20<=agest<=64;
run;

proc tabulate data=proj.completedata2 out=work.poptot (drop=_type_ _page_ _table_);
var pop;
class time region scen;
table scen*region,time*pop*(sum);
run;

proc sort data=work.workingage; by region time scen;run;
proc sort data=work.poptot; by region time scen;run;
data work.output;
merge work.workingage work.poptot;
by region time scen;
PWWAP=wa_weight;
POP=pop_sum;
WAP=wa_sum;
if PWWAP=. then delete;
drop wa_sum pop_sum wa_weight; 
run;


data work.output;
set work.output;
length region2 $ 25;
length Continent $ 13;
length CountryName $ 75;
if region='reg4' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Afghanistan'; end;
if region='reg248' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Åland Islands'; end;
if region='reg8' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Albania'; end;
if region='reg12' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Algeria'; end;
if region='reg16' then do; region2='Polynesia'; Continent='Oceania'; CountryName='American Samoa'; end;
if region='reg20' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Andorra'; end;
if region='reg24' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Angola'; end;
if region='reg660' then do; region2='Caribbean'; Continent='North America'; CountryName='Anguilla'; end;
if region='reg10' then do; region2='Antarctica'; Continent='Antarctica'; CountryName='Antarctica'; end;
if region='reg28' then do; region2='Caribbean'; Continent='North America'; CountryName='Antigua and Barbuda'; end;
if region='reg32' then do; region2='South America'; Continent='South America'; CountryName='Argentina'; end;
if region='reg51' then do; region2='Western Asia'; Continent='Asia'; CountryName='Armenia'; end;
if region='reg533' then do; region2='Caribbean'; Continent='North America'; CountryName='Aruba'; end;
if region='reg36' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='Australia'; end;
if region='reg40' then do; region2='Western Europe'; Continent='Europe'; CountryName='Austria'; end;
if region='reg31' then do; region2='Western Asia'; Continent='Asia'; CountryName='Azerbaijan'; end;
if region='reg44' then do; region2='Caribbean'; Continent='North America'; CountryName='Bahamas'; end;
if region='reg48' then do; region2='Western Asia'; Continent='Asia'; CountryName='Bahrain'; end;
if region='reg50' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Bangladesh'; end;
if region='reg52' then do; region2='Caribbean'; Continent='North America'; CountryName='Barbados'; end;
if region='reg112' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Belarus'; end;
if region='reg56' then do; region2='Western Europe'; Continent='Europe'; CountryName='Belgium'; end;
if region='reg84' then do; region2='Central America'; Continent='North America'; CountryName='Belize'; end;
if region='reg204' then do; region2='Western Africa'; Continent='Africa'; CountryName='Benin'; end;
if region='reg60' then do; region2='Northern America'; Continent='North America'; CountryName='Bermuda'; end;
if region='reg64' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Bhutan'; end;
if region='reg68' then do; region2='South America'; Continent='South America'; CountryName='Bolivia (Plurinational State of)'; end;
if region='reg535' then do; region2='Caribbean'; Continent='North America'; CountryName='Bonaire, Sint Eustatius and Saba'; end;
if region='reg70' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Bosnia and Herzegovina'; end;
if region='reg72' then do; region2='Southern Africa'; Continent='Africa'; CountryName='Botswana'; end;
if region='reg74' then do; region2='South America'; Continent='South America'; CountryName='Bouvet Island'; end;
if region='reg76' then do; region2='South America'; Continent='South America'; CountryName='Brazil'; end;
if region='reg86' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='British Indian Ocean Territory'; end;
if region='reg92' then do; region2='Caribbean'; Continent='North America'; CountryName='British Virgin Islands'; end;
if region='reg96' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Brunei Darussalam'; end;
if region='reg100' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Bulgaria'; end;
if region='reg854' then do; region2='Western Africa'; Continent='Africa'; CountryName='Burkina Faso'; end;
if region='reg108' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Burundi'; end;
if region='reg132' then do; region2='Western Africa'; Continent='Africa'; CountryName='Cabo Verde'; end;
if region='reg116' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Cambodia'; end;
if region='reg120' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Cameroon'; end;
if region='reg124' then do; region2='Northern America'; Continent='North America'; CountryName='Canada'; end;
if region='reg136' then do; region2='Caribbean'; Continent='North America'; CountryName='Cayman Islands'; end;
if region='reg140' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Central African Republic'; end;
if region='reg148' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Chad'; end;
if region='reg152' then do; region2='South America'; Continent='South America'; CountryName='Chile'; end;
if region='reg156' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='China'; end;
if region='reg344' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='China, Hong Kong Special Administrative Region'; end;
if region='reg446' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='China, Macao Special Administrative Region'; end;
if region='reg162' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='Christmas Island'; end;
if region='reg166' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='Cocos (Keeling) Islands'; end;
if region='reg170' then do; region2='South America'; Continent='South America'; CountryName='Colombia'; end;
if region='reg174' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Comoros'; end;
if region='reg178' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Congo'; end;
if region='reg184' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Cook Islands'; end;
if region='reg188' then do; region2='Central America'; Continent='North America'; CountryName='Costa Rica'; end;
if region='reg384' then do; region2='Western Africa'; Continent='Africa'; CountryName='Côte d’Ivoire'; end;
if region='reg191' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Croatia'; end;
if region='reg192' then do; region2='Caribbean'; Continent='North America'; CountryName='Cuba'; end;
if region='reg531' then do; region2='Caribbean'; Continent='North America'; CountryName='Curaçao'; end;
if region='reg196' then do; region2='Western Asia'; Continent='Asia'; CountryName='Cyprus'; end;
if region='reg203' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Czechia'; end;
if region='reg408' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='Democratic People s Republic of Korea'; end;
if region='reg180' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Democratic Republic of the Congo'; end;
if region='reg208' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Denmark'; end;
if region='reg262' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Djibouti'; end;
if region='reg212' then do; region2='Caribbean'; Continent='North America'; CountryName='Dominica'; end;
if region='reg214' then do; region2='Caribbean'; Continent='North America'; CountryName='Dominican Republic'; end;
if region='reg218' then do; region2='South America'; Continent='South America'; CountryName='Ecuador'; end;
if region='reg818' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Egypt'; end;
if region='reg222' then do; region2='Central America'; Continent='North America'; CountryName='El Salvador'; end;
if region='reg226' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Equatorial Guinea'; end;
if region='reg232' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Eritrea'; end;
if region='reg233' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Estonia'; end;
if region='reg748' then do; region2='Southern Africa'; Continent='Africa'; CountryName='Eswatini'; end;
if region='reg231' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Ethiopia'; end;
if region='reg238' then do; region2='South America'; Continent='South America'; CountryName='Falkland Islands (Malvinas)'; end;
if region='reg234' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Faroe Islands'; end;
if region='reg242' then do; region2='Melanesia'; Continent='Oceania'; CountryName='Fiji'; end;
if region='reg246' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Finland'; end;
if region='reg250' then do; region2='Western Europe'; Continent='Europe'; CountryName='France'; end;
if region='reg254' then do; region2='South America'; Continent='South America'; CountryName='French Guiana'; end;
if region='reg258' then do; region2='Polynesia'; Continent='Oceania'; CountryName='French Polynesia'; end;
if region='reg260' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='French Southern Territories'; end;
if region='reg266' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Gabon'; end;
if region='reg270' then do; region2='Western Africa'; Continent='Africa'; CountryName='Gambia'; end;
if region='reg268' then do; region2='Western Asia'; Continent='Asia'; CountryName='Georgia'; end;
if region='reg276' then do; region2='Western Europe'; Continent='Europe'; CountryName='Germany'; end;
if region='reg288' then do; region2='Western Africa'; Continent='Africa'; CountryName='Ghana'; end;
if region='reg292' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Gibraltar'; end;
if region='reg300' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Greece'; end;
if region='reg304' then do; region2='Northern America'; Continent='North America'; CountryName='Greenland'; end;
if region='reg308' then do; region2='Caribbean'; Continent='North America'; CountryName='Grenada'; end;
if region='reg312' then do; region2='Caribbean'; Continent='North America'; CountryName='Guadeloupe'; end;
if region='reg316' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Guam'; end;
if region='reg320' then do; region2='Central America'; Continent='North America'; CountryName='Guatemala'; end;
if region='reg831' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Guernsey'; end;
if region='reg324' then do; region2='Western Africa'; Continent='Africa'; CountryName='Guinea'; end;
if region='reg624' then do; region2='Western Africa'; Continent='Africa'; CountryName='Guinea-Bissau'; end;
if region='reg328' then do; region2='South America'; Continent='South America'; CountryName='Guyana'; end;
if region='reg332' then do; region2='Caribbean'; Continent='North America'; CountryName='Haiti'; end;
if region='reg334' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='Heard Island and McDonald Islands'; end;
if region='reg336' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Holy See'; end;
if region='reg340' then do; region2='Central America'; Continent='North America'; CountryName='Honduras'; end;
if region='reg348' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Hungary'; end;
if region='reg352' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Iceland'; end;
if region='reg356' then do; region2='Southern Asia'; Continent='Asia'; CountryName='India'; end;
if region='reg360' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Indonesia'; end;
if region='reg364' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Iran (Islamic Republic of)'; end;
if region='reg368' then do; region2='Western Asia'; Continent='Asia'; CountryName='Iraq'; end;
if region='reg372' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Ireland'; end;
if region='reg833' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Isle of Man'; end;
if region='reg376' then do; region2='Western Asia'; Continent='Asia'; CountryName='Israel'; end;
if region='reg380' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Italy'; end;
if region='reg388' then do; region2='Caribbean'; Continent='North America'; CountryName='Jamaica'; end;
if region='reg392' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='Japan'; end;
if region='reg832' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Jersey'; end;
if region='reg400' then do; region2='Western Asia'; Continent='Asia'; CountryName='Jordan'; end;
if region='reg398' then do; region2='Central Asia'; Continent='Asia'; CountryName='Kazakhstan'; end;
if region='reg404' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Kenya'; end;
if region='reg296' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Kiribati'; end;
if region='reg414' then do; region2='Western Asia'; Continent='Asia'; CountryName='Kuwait'; end;
if region='reg417' then do; region2='Central Asia'; Continent='Asia'; CountryName='Kyrgyzstan'; end;
if region='reg418' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Lao People s Democratic Republic'; end;
if region='reg428' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Latvia'; end;
if region='reg422' then do; region2='Western Asia'; Continent='Asia'; CountryName='Lebanon'; end;
if region='reg426' then do; region2='Southern Africa'; Continent='Africa'; CountryName='Lesotho'; end;
if region='reg430' then do; region2='Western Africa'; Continent='Africa'; CountryName='Liberia'; end;
if region='reg434' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Libya'; end;
if region='reg438' then do; region2='Western Europe'; Continent='Europe'; CountryName='Liechtenstein'; end;
if region='reg440' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Lithuania'; end;
if region='reg442' then do; region2='Western Europe'; Continent='Europe'; CountryName='Luxembourg'; end;
if region='reg450' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Madagascar'; end;
if region='reg454' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Malawi'; end;
if region='reg458' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Malaysia'; end;
if region='reg462' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Maldives'; end;
if region='reg466' then do; region2='Western Africa'; Continent='Africa'; CountryName='Mali'; end;
if region='reg470' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Malta'; end;
if region='reg584' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Marshall Islands'; end;
if region='reg474' then do; region2='Caribbean'; Continent='North America'; CountryName='Martinique'; end;
if region='reg478' then do; region2='Western Africa'; Continent='Africa'; CountryName='Mauritania'; end;
if region='reg480' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Mauritius'; end;
if region='reg175' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Mayotte'; end;
if region='reg484' then do; region2='Central America'; Continent='North America'; CountryName='Mexico'; end;
if region='reg583' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Micronesia (Federated States of)'; end;
if region='reg492' then do; region2='Western Europe'; Continent='Europe'; CountryName='Monaco'; end;
if region='reg496' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='Mongolia'; end;
if region='reg499' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Montenegro'; end;
if region='reg500' then do; region2='Caribbean'; Continent='North America'; CountryName='Montserrat'; end;
if region='reg504' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Morocco'; end;
if region='reg508' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Mozambique'; end;
if region='reg104' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Myanmar'; end;
if region='reg516' then do; region2='Southern Africa'; Continent='Africa'; CountryName='Namibia'; end;
if region='reg520' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Nauru'; end;
if region='reg524' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Nepal'; end;
if region='reg528' then do; region2='Western Europe'; Continent='Europe'; CountryName='Netherlands'; end;
if region='reg540' then do; region2='Melanesia'; Continent='Oceania'; CountryName='New Caledonia'; end;
if region='reg554' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='New Zealand'; end;
if region='reg558' then do; region2='Central America'; Continent='North America'; CountryName='Nicaragua'; end;
if region='reg562' then do; region2='Western Africa'; Continent='Africa'; CountryName='Niger'; end;
if region='reg566' then do; region2='Western Africa'; Continent='Africa'; CountryName='Nigeria'; end;
if region='reg570' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Niue'; end;
if region='reg574' then do; region2='Australia and New Zealand'; Continent='Oceania'; CountryName='Norfolk Island'; end;
if region='reg807' then do; region2='Southern Europe'; Continent='Europe'; CountryName='North Macedonia'; end;
if region='reg580' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Northern Mariana Islands'; end;
if region='reg578' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Norway'; end;
if region='reg512' then do; region2='Western Asia'; Continent='Asia'; CountryName='Oman'; end;
if region='reg586' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Pakistan'; end;
if region='reg585' then do; region2='Micronesia'; Continent='Oceania'; CountryName='Palau'; end;
if region='reg591' then do; region2='Central America'; Continent='North America'; CountryName='Panama'; end;
if region='reg598' then do; region2='Melanesia'; Continent='Oceania'; CountryName='Papua New Guinea'; end;
if region='reg600' then do; region2='South America'; Continent='South America'; CountryName='Paraguay'; end;
if region='reg604' then do; region2='South America'; Continent='South America'; CountryName='Peru'; end;
if region='reg608' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Philippines'; end;
if region='reg612' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Pitcairn'; end;
if region='reg616' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Poland'; end;
if region='reg620' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Portugal'; end;
if region='reg630' then do; region2='Caribbean'; Continent='North America'; CountryName='Puerto Rico'; end;
if region='reg634' then do; region2='Western Asia'; Continent='Asia'; CountryName='Qatar'; end;
if region='reg410' then do; region2='Eastern Asia'; Continent='Asia'; CountryName='Republic of Korea'; end;
if region='reg498' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Republic of Moldova'; end;
if region='reg638' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Réunion'; end;
if region='reg642' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Romania'; end;
if region='reg643' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Russian Federation'; end;
if region='reg646' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Rwanda'; end;
if region='reg652' then do; region2='Caribbean'; Continent='North America'; CountryName='Saint Barthélemy'; end;
if region='reg654' then do; region2='Western Africa'; Continent='Africa'; CountryName='Saint Helena'; end;
if region='reg659' then do; region2='Caribbean'; Continent='North America'; CountryName='Saint Kitts and Nevis'; end;
if region='reg662' then do; region2='Caribbean'; Continent='North America'; CountryName='Saint Lucia'; end;
if region='reg663' then do; region2='Caribbean'; Continent='North America'; CountryName='Saint Martin (French Part)'; end;
if region='reg666' then do; region2='Northern America'; Continent='North America'; CountryName='Saint Pierre and Miquelon'; end;
if region='reg670' then do; region2='Caribbean'; Continent='North America'; CountryName='Saint Vincent and the Grenadines'; end;
if region='reg882' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Samoa'; end;
if region='reg674' then do; region2='Southern Europe'; Continent='Europe'; CountryName='San Marino'; end;
if region='reg678' then do; region2='Middle Africa'; Continent='Africa'; CountryName='Sao Tome and Principe'; end;
if region='reg680' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Sark'; end;
if region='reg682' then do; region2='Western Asia'; Continent='Asia'; CountryName='Saudi Arabia'; end;
if region='reg686' then do; region2='Western Africa'; Continent='Africa'; CountryName='Senegal'; end;
if region='reg688' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Serbia'; end;
if region='reg690' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Seychelles'; end;
if region='reg694' then do; region2='Western Africa'; Continent='Africa'; CountryName='Sierra Leone'; end;
if region='reg702' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Singapore'; end;
if region='reg534' then do; region2='Caribbean'; Continent='North America'; CountryName='Sint Maarten (Dutch part)'; end;
if region='reg703' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Slovakia'; end;
if region='reg705' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Slovenia'; end;
if region='reg90' then do; region2='Melanesia'; Continent='Oceania'; CountryName='Solomon Islands'; end;
if region='reg706' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Somalia'; end;
if region='reg710' then do; region2='Southern Africa'; Continent='Africa'; CountryName='South Africa'; end;
if region='reg239' then do; region2='South America'; Continent='South America'; CountryName='South Georgia and the South Sandwich Islands'; end;
if region='reg728' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='South Sudan'; end;
if region='reg724' then do; region2='Southern Europe'; Continent='Europe'; CountryName='Spain'; end;
if region='reg144' then do; region2='Southern Asia'; Continent='Asia'; CountryName='Sri Lanka'; end;
if region='reg275' then do; region2='Western Asia'; Continent='Asia'; CountryName='State of Palestine'; end;
if region='reg729' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Sudan'; end;
if region='reg740' then do; region2='South America'; Continent='South America'; CountryName='Suriname'; end;
if region='reg744' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Svalbard and Jan Mayen Islands'; end;
if region='reg752' then do; region2='Northern Europe'; Continent='Europe'; CountryName='Sweden'; end;
if region='reg756' then do; region2='Western Europe'; Continent='Europe'; CountryName='Switzerland'; end;
if region='reg760' then do; region2='Western Asia'; Continent='Asia'; CountryName='Syrian Arab Republic'; end;
if region='reg762' then do; region2='Central Asia'; Continent='Asia'; CountryName='Tajikistan'; end;
if region='reg764' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Thailand'; end;
if region='reg626' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Timor-Leste'; end;
if region='reg768' then do; region2='Western Africa'; Continent='Africa'; CountryName='Togo'; end;
if region='reg772' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Tokelau'; end;
if region='reg776' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Tonga'; end;
if region='reg780' then do; region2='Caribbean'; Continent='North America'; CountryName='Trinidad and Tobago'; end;
if region='reg788' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Tunisia'; end;
if region='reg792' then do; region2='Western Asia'; Continent='Asia'; CountryName='Turkey'; end;
if region='reg795' then do; region2='Central Asia'; Continent='Asia'; CountryName='Turkmenistan'; end;
if region='reg796' then do; region2='Caribbean'; Continent='North America'; CountryName='Turks and Caicos Islands'; end;
if region='reg798' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Tuvalu'; end;
if region='reg800' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Uganda'; end;
if region='reg804' then do; region2='Eastern Europe'; Continent='Europe'; CountryName='Ukraine'; end;
if region='reg784' then do; region2='Western Asia'; Continent='Asia'; CountryName='United Arab Emirates'; end;
if region='reg826' then do; region2='Northern Europe'; Continent='Europe'; CountryName='United Kingdom of Great Britain and Northern Ireland'; end;
if region='reg834' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='United Republic of Tanzania'; end;
if region='reg581' then do; region2='Micronesia'; Continent='Oceania'; CountryName='United States Minor Outlying Islands'; end;
if region='reg840' then do; region2='Northern America'; Continent='North America'; CountryName='United States of America'; end;
if region='reg850' then do; region2='Caribbean'; Continent='North America'; CountryName='United States Virgin Islands'; end;
if region='reg858' then do; region2='South America'; Continent='South America'; CountryName='Uruguay'; end;
if region='reg860' then do; region2='Central Asia'; Continent='Asia'; CountryName='Uzbekistan'; end;
if region='reg548' then do; region2='Melanesia'; Continent='Oceania'; CountryName='Vanuatu'; end;
if region='reg862' then do; region2='South America'; Continent='South America'; CountryName='Venezuela (Bolivarian Republic of)'; end;
if region='reg704' then do; region2='South-eastern Asia'; Continent='Asia'; CountryName='Viet Nam'; end;
if region='reg876' then do; region2='Polynesia'; Continent='Oceania'; CountryName='Wallis and Futuna Islands'; end;
if region='reg732' then do; region2='Northern Africa'; Continent='Africa'; CountryName='Western Sahara'; end;
if region='reg887' then do; region2='Western Asia'; Continent='Asia'; CountryName='Yemen'; end;
if region='reg894' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Zambia'; end;
if region='reg716' then do; region2='Eastern Africa'; Continent='Africa'; CountryName='Zimbabwe'; end;


Year=Time;
CountryCode=region;
Scenario=scen;
drop Time Region scen;
run;



proc export data=work.output
    outfile="H:\WAWeight\Projection\output_PWWAP.csv"
    dbms=csv
	replace; 
run;
