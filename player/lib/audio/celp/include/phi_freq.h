/*====================================================================*/
/*         MPEG-4 Audio (ISO/IEC 14496-3) Copyright Header            */
/*====================================================================*/
/*
This software module was originally developed by Rakesh Taori and Andy
Gerrits (Philips Research Laboratories, Eindhoven, The Netherlands) in
the course of development of the MPEG-4 Audio (ISO/IEC 14496-3). This
software module is an implementation of a part of one or more MPEG-4
Audio (ISO/IEC 14496-3) tools as specified by the MPEG-4 Audio
(ISO/IEC 14496-3). ISO/IEC gives users of the MPEG-4 Audio (ISO/IEC
14496-3) free license to this software module or modifications thereof
for use in hardware or software products claiming conformance to the
MPEG-4 Audio (ISO/IEC 14496-3). Those intending to use this software
module in hardware or software products are advised that its use may
infringe existing patents. The original developer of this software
module and his/her company, the subsequent editors and their
companies, and ISO/IEC have no liability for use of this software
module or modifications thereof in an implementation. Copyright is not
released for non MPEG-4 Audio (ISO/IEC 14496-3) conforming products.
CN1 retains full right to use the code for his/her own purpose, assign
or donate the code to a third party and to inhibit third parties from
using the code for non MPEG-4 Audio (ISO/IEC 14496-3) conforming
products.  This copyright notice must be included in all copies or
derivative works. Copyright 1996.
*/

static int init_freq[227]=
{
	82,
	72,
	46,
	46,
	57,
	59,
	75,
	76,
	865,
	82,
	89,
	78,
	91,
	64,
	92,
	126,
	109,
	151,
	219,
	225,
	303,
	365,
	390,
	385,
	405,
	418,
	422,
	423,
	452,
	392,
	378,
	294,
	234,
	208,
	94,
	168,
	43,
	33,
	52,
	71,
	86,
	137,
	138,
	187,
	220,
	264,
	350,
	401,
	553,
	542,
	557,
	598,
	480,
	380,
	351,
	321,
	296,
	1219,
	391,
	173,
	73,
	50,
	32,
	29,
	58,
	192,
	229,
	361,
	488,
	1502,
	1066,
	1073,
	890,
	734,
	598,
	421,
	223,
	106,
	73,
	48,
	66,
	144,
	309,
	527,
	646,
	831,
	1118,
	1285,
	1830,
	598,
	330,
	175,
	106,
	34,
	77,
	199,
	552,
	850,
	2155,
	1692,
	1161,
	672,
	332,
	177,
	69,
	42,
	9,
	15,
	54,
	131,
	297,
	674,
	1128,
	1786,
	2349,
	955,
	416,
	150,
	48,
	54,
	160,
	301,
	579,
	953,
	2263,
	1792,
	1103,
	503,
	206,
	74,
	23,
	28,
	64,
	191,
	464,
	885,
	1420,
	1993,
	2210,
	551,
	152,
	52,
	65,
	180,
	646,
	2471,
	2235,
	1393,
	691,
	231,
	96,
	85,
	223,
	693,
	1577,
	2306,
	2462,
	521,
	140,
	42,
	281,
	841,
	2898,
	2320,
	1165,
	374,
	86,
	126,
	465,
	1261,
	2456,
	2775,
	695,
	228,
	78,
	575,
	2946,
	2542,
	1250,
	466,
	149,
	40,
	268,
	1089,
	2491,
	3051,
	832,
	198,
	38,
	110,
	659,
	3004,
	2496,
	1186,
	451,
	100,
	307,
	1149,
	2549,
	3038,
	794,
	168,
	101,
	763,
	3682,
	2512,
	782,
	165,
	4,
	108,
	980,
	2841,
	3407,
	631,
	35,
	38,
	706,
	3821,
	2821,
	589,
	30,
	57,
	849,
	3114,
	3480,
	500,
	5,
};