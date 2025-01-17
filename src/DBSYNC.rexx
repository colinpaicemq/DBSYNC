/* DBSYNC: REXX exec to find differences between two RACF databases   */
/* and create commands to synchronize them.                           */
/*                                                                    */
/*%Copyright Copyright IBM Corporation, 1993, 2006                    */
/*                                                                    */
/* Author: Walt Farrell  Walter Farrell/Poughkeepsie/IBM@IBMUS        */
/*                    or wfarrell@us.ibm.com                          */
/*                                                                    */
/*                                                                    */
/*  DBSYNC currently recognizes the following database unload         */
/*  record types:                                                     */
/*       0100   GROUP basic                                           */
/*       0101   GROUP subgroup                                        */
/*       0102   GROUP members                                         */
/*       0103   GROUP instdata                                        */
/*       0110   GROUP DFP                                             */
/*       0120   GROUP OMVS                                            */
/*       0130   GROUP OVM                                             */
/*       0141   GROUP TME Role                                    @LIA*/
/*       0151   GROUP CSDATA (new)                                @M7A*/
/*       0200   USER basic                                            */
/*       0201   USER category                                         */
/*       0202   USER classauth                                        */
/*       0203   USER-group connection (ignored; 0205 used instead)    */
/*       0204   USER instdata                                         */
/*       0205   USER connect                                          */
/*       0206   USER associations                                     */
/*       0207   USER certificate data                             @LLA*/
/*       0210   USER DFP                                              */
/*       0220   USER TSO                                              */
/*       0230   USER CICS                                             */
/*       0231   USER CICS opdata                                      */
/*       0232   USER CICS RSL key info                            @M5A*/
/*       0233   USER CICS TSL key info                            @M5A*/
/*       0240   USER LANGUAGE                                         */
/*       0250   USER OPERPARM                                         */
/*       0251   USER OPERPARM SCOPE                                   */
/*       0260   USER WORKDATA                                         */
/*       0270   USER OMVS                                             */
/*       0280   USER NETVIEW                                          */
/*       0281   USER NETVIEW operator classes                         */
/*       0282   USER NETVIEW domains                                  */
/*       0290   USER DCE                                              */
/*       02A0   USER OVM                                              */
/*       02B0   USER LNOTES                                           */
/*       02C0   USER NDS                                          @LKA*/
/*       02D0   USER KERB                                         @LRA*/
/*       02E0   USER PROXY data                                   @LTA*/
/*       02F0   USER EIM data                                     @LZA*/
/*       02G1   USER CSDATA (new)                                 @M7A*/
/*       0400   DATASET basic                                         */
/*       0401   DATASET DATASET categories                            */
/*       0402   DATASET conditional access list                       */
/*       0403   DATASET volumes                                       */
/*       0404   DATASET access list                                   */
/*       0405   DATASET instdata                                      */
/*       0410   DATASET DFP                                           */
/*       0421   DATASET TME roles                                 @LIA*/
/*       0500   general basic                                         */
/*       0501   general TVTOC                                         */
/*       0502   general categories                                    */
/*       0503   general members                                       */
/*       0504   general volume                                        */
/*       0505   general access list                                   */
/*       0506   general instdata                                      */
/*       0507   general conditional access list                       */
/*       0510   general SESSION                                       */
/*       0511   general SESSION (ignored; obsolete)                   */
/*       0520   general DLF                                           */
/*       0521   general DLF jobs                                      */
/*       0540   general STDATA                                        */
/*       0550   general System View                                   */
/*       0570   general TME                                       @LIA*/
/*       0571   general TME child                                 @LIA*/
/*       0572   general TME resource                              @LIA*/
/*       0573   general TME group                                 @LIA*/
/*       0574   general TME role                                  @LIA*/
/*       0580   general KERB data                                 @LRA*/
/*       0590   general PROXY data                                @LTA*/
/*       05A0   general EIM data                                  @LZA*/
/*       05B0   general ALIAS data (ignored)                      @M0A*/
/*       05C0   general CDTINFO                                   @M7C*/
/*       05D0   general ICTX (new)                                @M7A*/
/*       05E0   general CFDEF (new)                               @M7A*/
/*                                                                    */
/* DBSYNC currently recognizes but cannot process the following       */
/* record types, and will issue a warning message about them:         */
/*       0208   USER associated mappings                          @LUA*/
/*       0508   general filter data                               @LUA*/
/*       0560   general certificate data                          @LLA*/
/*       0561   general certificate references record             @LLA*/
/*       0562   general keyring                                   @LLA*/
/*       0232   USER CICS RSL mapping                             @M5A*/
/*       0233   USER CICS TSL mapping                             @M5A*/
/*                                                                    */
/* DBSYNC currently does NOT recognize the following record types     */
/* and will issue a warning message and skip them:                    */
/*       None                                                         */
/*                                                                    */
/*                                                                    */
/*                                                                    */
/* Change Activity:                                                   */
/*                                                                    */
/* $L0=DBSYNC HRF2102 950316 PDWBF1: First general release        @L0A*/
/* $LA=DBUSYNCH HRF2220 940804 PDWBF1: Handle RRSF Data (0206)        */
/* $LB=DBUSYNCH HRF2220 940829 PDWBF1: Handle NETVIEW data (0280-0282)*/
/* $P1=DBSYNC HRF2102 950318 PDWBF1: Fix typo in routecode code   @P1A*/
/* $P2=DBSYNC HRF2102 950318 PDWBF1: Fix typo in genc0501 parse   @P2A*/
/* $P3=DBSYNC HRF2102 950318 PDWBF1: 0501 create date comparison  @P3A*/
/* $M1=DBSYNC HRF2102 950322 PDWBF1: Handle full output files     @M1A*/
/* $P4=DBSYNC HRF2102 950322 PDWBF1: Missing label sel0251        @P4A*/
/* $P5=DBSYNC HRF2102 950322 PDWBF1: Correct DDnames in end msgs  @P5A*/
/* $P6=DBSYNC HRF2102 950727 PDWBF1: Shift some lines             @P6A*/
/* $P7=DBSYNC HRF2102 950731 PDWBF1: Interval, SETX               @P7A*/
/* $LC=DBSYNC OS390R1 960216 PDWBF1: DCE Support                  @LCA*/
/* $LD=DBSYNC OS390R1 960216 PDWBF1: SystemView for MVS Support   @LDA*/
/* $P8=DBSYNC OS390R1 960318 PDWBF1: Removing user from dummygrp  @P8A*/
/* $P9=DBSYNC OS390R1 960327 PDWBF1: Reset access lists           @P9A*/
/* $LE=DBSYNC OS390R1 960715 PDWBF1: Netview Updates              @LEA*/
/* $PA=DBSYNC OS390R2 970218 PDWBF1: Fix error in @P9A code       @PAA*/
/* $PB=DBSYNC OS390R8 000405 PDWBF1: Fix PW NOINTERVAL problem    @PBA*/
/* $LF=DBSYNC OS390R8 000405 PDWBF1: Detect Invalid Upload        @LFA*/
/* $LG=DBSYNC OS390R8 000407 PDWBF1: OVM segment support          @LGA*/
/* $LH=DBSYNC OS390R8 000407 PDWBF1: OMVS user limits             @LHA*/
/* $LI=DBSYNC OS390R8 000407 PDWBF1: TME support                  @LIA*/
/* $LJ=DBSYNC OS390R8 000411 PDWBF1: User LNOTES support          @LJA*/
/* $LK=DBSYNC OS390R8 000411 PDWBF1: User NDS support             @LKA*/
/* $LL=DBSYNC OS390R8 000411 PDWBF1: User certificate support     @LLA*/
/* $LM=DBSYNC OS390R8 000414 PDWBF1: dummygrp enhancements        @LMA*/
/* $LN=DBSYNC OS390R8 000424 PDWBF1: user vs group name conflicts @LNA*/
/* $PC=DBSYNC OS390R8 000424 PDWBF1: DELDSD problem on OUTALTn    @PCA*/
/* $PD=DBSYNC OS390R8 000424 PDWBF1: REVOKE/RESUME date problem   @PDA*/
/* $PE=DBSYNC OS390R8 000424 PDWBF1: SUPGROUP(dummgroup) problem  @PEA*/
/* $PF=DBSYNC OS390R8 020716 PDWBF1: Fix revdate NOVALUE error    @PFA*/
/* $LO=DBSYNC OS390R10 020716 PDWBF1: Restricted User Support     @LOA*/
/* $LP=DBSYNC OS390R8 020716 PDWBF1: Protected User Support       @LPA*/
/* $LQ=DBSYNC OS390R10 020716 PDWBF1: Certificate Mapping Support @LQA*/
/* $LR=DBSYNC OS390R10 020716 PDWBF1: Kerberos Support            @LRA*/
/* $LS=DBSYNC zOSR2   020716 PDWBF1: UNIVERSAL Groups             @LSA*/
/* $LT=DBSYNC zOSR3   020716 PDWBF1: PDAS Support                 @LTA*/
/* $LU=DBSYNC zOSR3   020716 PDWBF1: More PKI Support             @LUA*/
/* $PG=DBSYNC zOSR3   020722 PDWFB1: Move seclevels/seclabels     @PGA*/
/* $PH=DBSYNC zOSR3   020722 PDWBF1: Skip irrcerta & friends      @PHA*/
/* $PI=DBSYNC zOSR3   020723 PDWBF1: Another REVOKE/RESUME(date)  @PIA*/
/* $PJ=DBSYNC zOSR3   020723 PDWBF1: NOSET for DATASET discrete   @PJA*/
/* $PK=DBSYNC zOSR3   020723 PDWBF1: Better UNIT() for ADD/DELDSD @PKA*/
/* $LV=DBSYNC zOSR3   020726 PDWBF1: USOPER_AUTO                  @LVA*/
/* $LW=DBSYNC zOSR3   020726 PDWBF1: Network Name Support         @LWA*/
/* $PL=DBSYNC zOSR3   020726 PDWBF1: RALTER for canned seclabels  @PLA*/
/* $PM=DBSYNC zOSR3   020726 PDWBF1: ALU/ALG for canned IDs       @PMA*/
/* $PN=DBSYNC zOSR3   020729 PDWBF1: OUTSCDn files for secdata    @PNA*/
/* $PO=DBSYNC zOSR3   020731 PDWBF1: skip hsmback categories      @POA*/
/* $PP=DBSYNC zOSR3   020806 PDWBF1: Recognize Protected Users    @PPA*/
/* $PQ=DBSYNC zOSR3   020806 PDWBF1: RESTRICTED user problem      @PQA*/
/* $PR=DBSYNC zOSR3   020925 PDWBF1: Novalue for grscacc_net_id   @PRA*/
/* $PS=DBSYNC zOSR3   021009 PDWBF1: Novalue: USOMVS_ASSIZEEMAX   @PSA*/
/* $LX=DBSYNC zOSR2   030731 PDWBF1: OS/390 V2R10 Toleration      @LXA*/
/* $PT=DBSYNC zOSR2   031111 PDWBF1: Novalue for some kerb fields @PTA*/
/* $PU=DBSYNC OS390R8 040109 PDWBF1: Fix SET DUMMYGMAXU           @PUA*/
/* $PV=DBSYNC zOSR4   040112 PDWBF1: Improve error messages       @PVA*/
/* $PY=DBSYNC zOSR2   050611 PDWBF1: Fix several problems         @PYA*/
/* $LY=DBSYNC zOSR2   040112 PDWBF1: UNIVERSAL DummyGroup Support @LYA*/
/* $PW=DBSYNC zOSR2   050119 PDWBF1: PYJ0028 Compatibility        @PWA*/
/* $LZ=DBSYNC zOSR4   050119 PDWBF1: EIM Support                  @LZA*/
/* $PX=DBSYNC OS390R3 050119 PDWBF1: TCOMMAND Support Missing     @PXA*/
/* $M0=DBSYNC zOSR5   050119 PDWBF1: Ignore MLS 05B0 records      @M0A*/
/* $M2=DBSYNC zOSR6   050119 PDWBF1: 64-bit support for OMVS      @M2A*/
/* $M3=DBSYNC zOSR3   050119 PDWBF1: LDAP Password Envelope       @M3A*/
/* $PZ=DBSYNC zOSR6   050611 PDWBF1: .ofile problems              @PZA*/
/* $Q1=DBSYNC zOSR5   050621 PDWBF1: Use RALTER for SYSMULTI      @Q1A*/
/* $M4=DBSYNC zOSR6   050122 PDWBF1: Dynamic CDT                  @M4A*/
/* $M5=DBSYNC zOSR7   051214 PDWBF1: z/OS R7 Support              @M5A*/
/* $M6=DBSYNC zOSR7   060118 PDWBF1: z/OS R4 Toleration           @M6A*/
/* $Q2=DBSYNC zOSR5   060118 PDWBF1: fix error in @M2 support     @Q2A*/
/* $Q3=DBSYNC zOSR4   060314 PDWBF1: SECLABEL AUDIT Qual Prob     @Q3A*/
/* $Q4=DBSYNC zOSR7   060707 PDWBF1: Misc problems                @Q4A*/
/* $Q5=DBSYNC zOSR10  081231 PDWBF1: Misc problems                @Q5A*/
/* $M7=DBSYNC zOSR10  081231 PDWBF1: z/OS R8, R9, R10 Support     @M7A*/
/* $Q6=DBSYNC zOSR10  091117 PDWBF1: seclevel/category problem    @Q6A*/
/* $Q7=DBSYNC zOSR10  091230 PDWBF1: continuation of @Q6          @Q7A*/
/*                                                                    */
/* Change Description:                                                */
/*                                                                    */
/* A000000-999999  First general release                              */
/* A - Add processing for user ID associations (record 0206) for      */
/*     RACF 2.2.                                                      */
/* A - Added processing for NETVIEW segment records 0280,0281,0282.   */
/* C - Fixed typo in spelling of usopr_routecode field            @P1A*/
/* C - Fixed typo (missing comma) in genc0501's parse stmt.       @P2A*/
/* A - Don't compare create dates in record type 0501 (TVTOC)     @P3A*/
/* C - In Massage code for 0102, add "if selecting then"          @P3A*/
/* A - Detect execio failures on output data sets and quit        @M1A*/
/* A - Add missing label sel0251:                                 @P4A*/
/* C - Correct the DDnames in the stats messages at normal end.   @P5A*/
/* C - Shift some lines so they don't extend past column 72.      @P6A*/
/* C - (1) Use PASSWORD not ALTUSER to set interval.              @P7A*/
/*     (2) Fix unbalanced quotes in SETX OPTIONS processing       @P7A*/
/* A - Support for record type 0290 (DCE).  (2.2.0.006)           @LCA*/
/* A - Support for record type 0550 (SystemView for MVS, SVFMR)   @LDA*/
/* C - Fix removal of user from dummygroup so we can delete it.   @P8A*/
/*     (2.2.0.007)                                                @P8A*/
/* C - Reset the access list after creating a profile so the      @P9A*/
/*     creator doesn't end up in the list by default (2.2.0.008)  @P9A*/
/* A - Support for NetView NGMFVSPN field in user profile.        @LEA*/
/* C - Fix order of NetView fields in 0280 per revised Macros &   @LEA*/
/*     Interfaces for OS/390 Sec Server R2  (2.2.0.009)           @LEA*/
/* C - Fix bad field name in @P9A code (2.2.0.008) so we use the  @PAA*/
/*     proper class name when issuing PERMIT ... RESET for        @PAA*/
/*     a general resource class (2.2.0.010)                       @PAA*/
/* C - Fix generation of PASSWORD INTERVAL(nnn) command for the   @PBA*/
/*     case where the interval is 0 to use NOINTERVAL instead.    @PBA*/
/*     (2.2.0.011)                                                @PBA*/
/* A - Add some processing to try to detect some common cases of  @LFA*/
/*     errors caused by improper uploading procedures             @LFA*/
/* A - Add support for user/group OVM segment                     @LGA*/
/* A - Add support for user OMVS limits                           @LHA*/
/* A - Add support for TME role info                              @LIA*/
/* A - Add support for USER LNOTES info                           @LJA*/
/* A - Add support for USER certificate info                      @LLA*/
/*     (Note: differences detected, but not corrected)            @LLA*/
/* C - Enhance dummygrp processing to handle the case of more     @LMA*/
/*     than 5957 users connected to  a dummy group or more        @LMA*/
/*     than 8191 subgroups of a dummy supgroup                    @LMA*/
/* A - Detect conflicts where one database has a group named X    @LNA*/
/*     the other has a user named X                               @LNA*/
/* C - Generate DELDSD commands to OUTREMn rather than OUTALTn    @PCA*/
/*     to ensure a DELUSER or DELGROUP on OUTDELn will work       @PCA*/
/* C - Correct revoke/resume dates to format mm/dd/yy rather than @PDA*/
/*     yy/mm/dd                                                   @PDA*/
/* C - Correct ALTGROUP groupname SUPGROUP(dummy) to also have    @PEA*/
/*     OWNER(dummy) to handle the case where the group is owned   @PEA*/
/*     by a group, where owner and supgroup must be the same      @PEA*/
/* C - Fix revocation date problem with unitialized variable.     @PFA*/
/*     One occurrence of the word revdate changed to rev_revdate  @PFA*/
/* A - Add code for Restricted user IDs                           @LOA*/
/* A - Add code to handle PROTECTED user IDs                      @LPA*/
/* A - Add code for certificate naming                            @LQA*/
/* A - Add code for Kerberos                                      @LRA*/
/* A - Add code for UNIVERSAL groups                              @LSA*/
/* A - Add code for PROXY.                                        @LTA*/
/*     (any non-zero numeric value will enable the trace)         @LTA*/
/* A - More PKI Support                                           @LUA*/
/* C - Move seclevel/seclabel info for users to OUTALT file       @PGA*/
/* C - Skip irrcerta, irrsitec, irrmulti user basic (0200) data   @PHA*/
/* C - Correct handling of revoke/resume date on connections      @PIA*/
/*   - Also finish @PD, reformatting "today" to mm/dd/yy          @PIA*/
/* C - Default to SET for an ADDSD/DELDSD of a discrete profile   @PJA*/
/*     but allow option for NOSET as unit/volser may not be       @PJA*/
/*     available in some cases                                    @PJA*/
/* C - Use better UNIT for discrete tape/dasd DATASET profiles.   @PKA*/
/*     Values set below or via OPTIONS file                       @PKA*/
/* A - Support for OPERPARM ( AUTO(YES/NO) )                      @LVA*/
/* A - Support network name for WHEN(APPCPORT(...))               @LWA*/
/* C - Use RALTER instead of RDEFINE for SYSHIGH et al            @PLA*/
/* C - Use ALTUSER for IBMUSER instead of ADDUSER, and ALTGROUP   @PMA*/
/*     for SYS1, VSAMDSET, and SYSCTLG instead of ADDGROUP        @PMA*/
/* C - Define SECDATA on new output file, OUTSCDn, so it's avail  @PNA*/
/*     before the commands in OUTADDn are run                     @PNA*/
/* A - Add "hsmback" check to processing of 0401 records as we    @POA*/
/*     have in other 04xx records.                                @POA*/
/* C - Remove old code that prevented recognition of Protected    @PPA*/
/*     users                                                      @PPA*/
/* C - RESTRICTED users broken for 1 alter file and defines       @PQA*/
/* C - Typo in processing field grcacc_net_id caused NOVALUE      @PRA*/
/* C - Typo in processing field USOMVS_ASSIZEMAX caused NOVALUE   @PSA*/
/* A - Tolerate comparison of OS/390 V2R10 files with z/OS R2     @LXA*/
/*     files that don't have UNIVERSAL group info in them         @LXA*/
/*   - Also tolerate different numbers of trailing blanks in      @LXA*/
/*     the input records for robustness                           @LXA*/
/* C - Fix NOVALUE errors for user and general resource KERB      @PTA*/
/*     data, and remove an extra set of kerbname processing in    @PTA*/
/*     user processsing.                                          @PTA*/
/* C - Fix SET DUMMYGMAXU processing to reset dummyucnt properly  @PUA*/
/* C - Fix small problem in handling UNIVERSAL groups when a      @PYA*/
/*     pre-z/OSR2 system is involved, and a label problem in      @PYA*/
/*     genc0207 for certificates, and the location of the         @PYA*/
/*     creation date when parsing in genc0100.                    @PYA*/
/* A - Add additional error messages showing DBSYNC version and   @PVA*/
/*     asking user to report problem via RACF-L                   @PVA*/
/* C - Make the DummyGroups UNIVERSAL so they can hold more users @LYA*/
/* C - Allow HIGHTRST per PYJ0028                                 @PWA*/
/* A - Support EIM records 02F0 (user) and 05A0 (general)         @LZA*/
/* A - Add support for COMMAND field in TSO segment (user)        @PXA*/
/* A - Ignore IPLOOK alias records (05B0) created by MLS support  @M0A*/
/* A - Support new 64-bit memory limits for OMVS segment (0270)   @M2A*/
/* A - Ignore  LDAP Password Envelope field in User (0200)        @M3A*/
/* A - Support Dynamic CDT segment in general profile (05C0)      @M4A*/
/* C - Correct problems with usage of .ofile variables            @PZA*/
/* C - Add SYSMULTI to the list of special SECLABELs              @Q1A*/
/* A - Support for z/OS R7:                                       @M5A*/
/*       Mixed Case Passwords (ignore password "asis" field)      @M5A*/
/*       CICS extensions (RSLKEY record 0232,                     @M5A*/
/*                        TSLKEY record 0233)                     @M5A*/
/* A - Allow suppression of z/OS R6 keywords on z/OS R4 system    @M6A*/
/* C - Fix specification of NOMEMLIMIT in @M2 support             @Q2A*/
/* C - RACF creates canned SECLABELs with uninitialized           @Q3A*/
/*     audit qualifiers, which DBU dumps as X<FF>.  Account for   @Q3A*/
/*     them to avoid building incorrect commands.                 @Q3A*/
/* C - Missing comment closing delimiter for password asis flag,  @Q4A*/
/*     and problem with seclevels for ALTUSER                     @Q4A*/
/* C - Miscellaneous problems                                     @Q5A*/
/*         fix format of RRSF associations record (0206)          @Q5A*/
/*         fix length of NETVIEW domains record (0282)            @Q5A*/
/*         fix length of USER OVM record (02A0)                   @Q5A*/
/*         fix length of USER EIM record (02F0)                   @Q5A*/
/*         fix length of General EIM record (05A0)                @Q5A*/
/*         fix problem handling TME roles (0141)                  @Q5A*/
/*         Fix NQN in DS and GR cond acl (0402, 0507)             @Q5A*/
/*         Fix missing ALTUSER RESUME (0200)                      @Q5A*/
/* A - Support for z/OS R8, R9, R10:                              @M7A*/
/*       Password Phrases (ignore existence, enveloping in 0200)  @M7A*/
/*       Custom Fields (records 05E0, 02G1, 0151                  @M7A*/
/*       Dynamic CDT "generic" keyword (05C0)                     @M7A*/
/*       Certificate sequence number in 0200 (ignore)             @M7A*/
/*       ICTX Segment in general profiles (05D0)                  @M7A*/
/*       KEYFROM in KERB Segment (02D0, ignore)                   @M7A*/
/*       AES support for KERB (02D0, 0580)                        @M7A*/
/*       Additional OPERPARM segment fields  (0250)               @M7A*/
/*       WHEN(SERVAUTH) in conditional access list (0402, 0507)   @M7A*/
/*       WHEN(CRITERIA) in conditional access list (0507)         @M7A*/
/*       Assume z/OS R10 (FMID HRF7750) for DD1FMID, DD2FMID      @M7A*/
/*       If we made changes to CDT class, make sure class is      @M7A*/
/*           active, and SETR RACLISTed or REFRESHed before we    @M7A*/
/*           refer to that class.                                 @M7A*/
/* C - Fix handling of seclevel/category information to           @Q6A*/
/*     tolerate longer input records related to phrases, etc.     @Q6A*/
/* C - Continue @Q6 fix.                                          @Q7A*/
 
/**********************************************************************/
/**********************************************************************/
/*                                                                    */
/* The following statements may be changed to tailor this exec to     */
/* work at your installation.  Or, these defaults may be overridden   */
/* by use of an OPTIONS file.                                         */
/*                                                                    */
/**********************************************************************/
 
 
hsmback    = 'HSM.BACK.'        /* change this if your HSM backup
                                   files start with a different
                                   prefix. Set hsmback = '' to include
                                   your HSM backup files              */
dummygroup = 'DUMMY'            /* change this to use a different
                                   dummy group name                   */
                                /* Note: DBSYNC will truncate this name
                                   to 7 characters if longer, and will
                                   append a character (1,2,3,...) @LMA*/
 
norstd = 'NORESTRICTED'         /* if you need to run the commands that
                                   DBSYNC generates on a system older
                                   than OS/390 V2R10 then change this
                                   variable to '' or ALTUSER commands
                                   will get syntax errors         @LOA*/
 
set_noset = 'SET'               /* if you have discrete DATASET
                                   profiles but the units or volsers
                                   are not available, change to noset
                                   to build ADDSD/DELDSD with
                                   noset option instead           @PJA*/
 
dasd_unit = 'SYSALLDA'          /* Value for UNIT operand on discrete
                                   DASD DATASET profiles if RACF DB
                                   didn't specify anything        @PKA*/
 
tape_unit = 'TAPE'              /* Value for UNIT operand on discrete
                                   TAPE dataset profiles if RACF DB
                                   didn't specify anything        @PKA*/
 
 
/**********************************************************************/
/*                                                                    */
/* The following statements should not be changed by the user of      */
/* this exec                                                          */
/*                                                                    */
/**********************************************************************/
 
signal on novalue
signal on syntax
/* trace 'o' */
address tso
 
call ValidateUpload              /* See if we uploaded OK to host @LFA*/
 
call InitVars                    /* Initialize some variables         */
 
howrun = 'Interpreted'           /* Assume running interpreted        */
parse upper version rexxv .      /* get compiler or interpreter
                                    version                           */
if rexxv = 'REXXC370' then       /* if version indicates compiler,    */
  howrun = 'Compiled'            /* then indicate running compiled    */
say howrun DBsyncName 'beginning on 'date()' at 'time() /* issue msg
                                    to show which exec running, date,
                                    time, and whether compiled        */
 
call ReadOptions                 /* process the OPTIONS file, if any  */
 
hsmback = translate(hsmback)     /* make sure hsm prefix is upper-
                                    case so code will work            */
hsmblen = length(hsmback)        /* get length of hsm prefix          */
 
/****************************/
/* determine input dsnames  */
/****************************/
dmy1 = listdsi("INDD1 FILE")     /* get data set info for INDD1       */
if dmy1 = 0 then
  inname1 = SYSDSNAME            /* copy dsname if LISTDSI successful */
else
  inname1 = "????????"           /* else use ????????                 */
dmy1  = listdsi("INDD2 FILE")    /* get data set info for INDD2       */
if dmy1 = 0 then
  inname2 = SYSDSNAME            /* copy dsname if LISTDSI successful */
else
  inname2 = "????????"           /* else use ????????                 */
 
/*********************************/
/* write headers to output files */
/*********************************/
cmd.1 = '/*REXX exec */'
cmd.2 = '/*Created on' date() 'at' time() '*/'
cmd.3 = '/*Input file 1: 'inname1' */'
cmd.4 = '/*Input file 2: 'inname2' */'
cmd.5 = '/*Output file: OUTADD1 */'
"execio * diskw outadd1 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTADD1'
cmd.5 = '/*Output file: OUTADD2 */'
"execio * diskw outadd2 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTADD2'
cmd.5 = '/*Output file: OUTALT1 */'
"execio * diskw outalt1 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTALT1'
cmd.5 = '/*Output file: OUTALT2 */'
"execio * diskw outalt2 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTALT2'
cmd.5 = '/*Output file: OUTREM1 */'
"execio * diskw outrem1 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTREM1'
cmd.5 = '/*Output file: OUTREM2 */'
"execio * diskw outrem2 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTREM2'
cmd.5 = '/*Output file: OUTDEL1 */'
"execio * diskw outdel1 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTDEL1'
cmd.5 = '/*Output file: OUTDEL2 */'
"execio * diskw outdel2 (stem cmd."
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTDEL2'
cmd.5 = '/*Output file: OUTCLN1 */'
"execio * diskw outcln1 (stem cmd." /*                            @LMA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @LMA*/
  'OUTCLN1'
cmd.5 = '/*Output file: OUTCLN2 */'
"execio * diskw outcln2 (stem cmd." /*                            @LMA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @LMA*/
  'OUTCLN2'
cmd.5 = '/*Output file: OUTSCD1 */' /*                            @PNA*/
"execio * diskw outscd1 (stem cmd." /*                            @PNA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @PNA*/
  'OUTSCD1'
cmd.5 = '/*Output file: OUTSCD2 */' /*                            @PNA*/
"execio * diskw outscd2 (stem cmd." /*                            @PNA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @PNA*/
  'OUTSCD2'
 
 
drop cmd.
 
 
/*********************************/
/* process the input files       */
/*********************************/
do loop = 1 by 1 while done1 = 0 | done2 = 0  /* loop while indd1 or
                                                 indd2 has unprocessed
                                                 data                 */
  skip = 0                                 /* assume we're not skipping
                                              this record             */
  /********************************************************************/
  /* get a record from indd1 if needed, and prepare it for analysis   */
  /********************************************************************/
  if read1 = 1 then do                     /* need new indd1 record?  */
    read1 = 0                              /* y:show we read it       */
    if i1 < d1.0 then i1 = i1+1            /*   use next in-storage
                                                record,               */
    else if dd1rc = 0 then do              /*   else if not eof       */
      "execio" ExecioInCount "diskr indd1 (stem d1." /* read more
                                                  records             */
      dd1rc = rc                           /*     save return code    */
      if d1.0 > 0 then i1 = 1              /*     if ok use 1st record*/
      else done1 = 1                       /*     else set eof        */
      end /* dd1rc = 0 */
    else done1 = 1                         /*   else set eof on indd1 */
 
    if done1 = 0 then do                   /*   if indd1 not at eof   */
      count1 = count1+1                    /*     bump record count   */
      if (count1//RecMsgCount = 0) then    /*   Check number of records
                                                read and issue message
                                                if needed             */
        say 'Processing INDD1 record #'count1
      data1 = massage(d1.i1)               /*     massage data        */
      dd1type = substr(data1,1,4)          /*  set dd1type field      */
      if skip = 1 then do                  /*  if skip flag set,      */
        read1 = 1                          /*    set "read ampther"   */
        iterate loop                       /*    loop for next record */
        end /* skip = 1 */
      end /* done1 = 0 */
    end /* read1 = 1 */
 
  /********************************************************************/
  /* get a record from indd2 if needed, and prepare it for analysis   */
  /********************************************************************/
  if read2 = 1 then do                     /* need new indd2 record?  */
    read2 = 0                              /* y:show we read it       */
    if i2 < d2.0 then i2 = i2+1            /*   use next in-storage
                                                record,               */
    else if dd2rc = 0 then do              /*   else if not eof       */
      "execio" ExecioInCount "diskr indd2 (stem d2." /* read more
                                                  records             */
      dd2rc = rc                           /*     save return code    */
      if d2.0 > 0 then i2 = 1              /*     if ok use 1st record*/
      else done2 = 1                       /*     else set eof        */
      end /* dd2rc = 0 */
    else done2 = 1                         /*   else set eof on indd2 */
 
    if done2 = 0 then do                   /*   if indd2 not at eof   */
      count2 = count2+1                    /*     bump record count   */
      if (count2//RecMsgCount = 0) then    /*   Check number of records
                                                read and issue message
                                                if needed             */
        say 'Processing INDD2 record #'count2
      data2 = massage(d2.i2)               /*     massage data        */
      dd2type = substr(data2,1,4)          /*  set dd2type field      */
      if skip = 1 then do                  /*  if skip flag set,      */
        read2 = 1                          /*    set "read another"   */
        iterate loop                       /*    loop for next record */
        end /* skip = 1 */
      end /* done2 = 0 */
    end /* read2 = 1 */
 
/**********************************************/
/* Records have been massaged.  See if they   */
/* match.                                     */
/**********************************************/
if done1 = 0 & done2 = 0 then do           /* If two records, compare
                                              them:                   */
  if data1 = data2 then do                /* if data equal, except
                                             possibly for trailing
                                             blanks               @LXC*/
    if dd1type = '0200' then               /*  if user basic data     */
      call chkdfltgrp                      /*  see if we need to reset
                                                 user's dfltgrp       */
    read1 = 1                              /*   need new indd1 record */
    read2 = 1                              /*   need new indd2 record */
    iterate loop                           /*   loop for next record  */
    end /* data1 = data2 @LXC*/
 
/*****************************************/
/* data not equal, figure out what to do */
/*****************************************/
 
  else if dd1type < dd2type then do        /* if record type
                                              of record on indd1 is <
                                              record type of record on
                                              indd2, then data missing
                                              from indd2              */
    say 'INDD1 Record #'count1 'missing from INDD2: ',
      substr(data1,1,50)
    cmdcount = cmdcount + 1                /* bump command count      */
    call create2                           /* create data for indd2   */
    call delete1                           /* delete data from indd1  */
    read1 = 1                              /* need another indd1 rec  */
    iterate loop                           /* loop for next record    */
    end /* dd1type < dd2type */
 
  else if dd2type < dd1type then do        /* if record
                                              type of record on indd2 is
                                              < record type of record on
                                              indd1, then data missing
                                              from indd1              */
    say 'INDD2 Record #'count2 'missing from INDD1: ',
      substr(data2,1,50)
    cmdcount = cmdcount + 1                /* bump command count      */
    call create1                           /* create data for indd1   */
    call delete2                           /* delete data from indd2  */
    read2 = 1                              /* need another indd2 rec  */
    iterate loop                           /* loop for next record    */
    end /* dd2type < dd1type */
 
  else do                                  /* else record types match */
    call makekeys                          /* generate record keys    */
    if skip = 1 then                       /* if error in makekeys,   */
      iterate loop                         /* loop for next records   */
 
  /**********************************************************/
  /* Compare the generated keys to see whether one file has */
  /* a missing record, or whether we have comparable        */
  /* records with different data in them                    */
  /**********************************************************/
    if key1 < key2 then do              /* if record missing on indd2 */
      say 'INDD1 Record #'count1 'missing from INDD2: '||,
        substr(data1,1,50)
      cmdcount = cmdcount + 1           /* bump command count         */
      call create2                      /* create data for indd2      */
      call delete1                      /* delete data from indd1     */
      read1 = 1                         /* need new indd1 record      */
      iterate loop                      /* loop for next record       */
      end /* key1 < key2 */
    else if key2 < key1 then do         /* if record missing on indd2 */
      say 'INDD2 Record #'count2 'missing from INDD1: '||,
        substr(data2,1,50)
      cmdcount = cmdcount + 1           /* bump command count         */
      call create1                      /* create data for indd1      */
      call delete2                      /* delete data from indd2     */
      read2 = 1                         /* need new indd2 record      */
      iterate loop                      /* loop for next record       */
      end /* key2 < key1 */
    else do /* key1 = key2 */           /* data mismatch              */
      say 'Records different.  INDD1 record #'count1||,
        ', INDD2 record #'count2':' substr(data1,1,50)
      cmdcount = cmdcount + 1           /* bump command count         */
      call alter1                       /* modify data for indd1      */
      read1 = 1                         /* need new indd1 record      */
      call alter2                       /* modify data for indd2      */
      read2 = 1                         /* need new indd2 record      */
      iterate loop                      /* loop for next records      */
      end /* key1 = key2 */
  end /* record types match */
end /* compare two records */
 
else if done1 = 1 & done2 = 0 then do      /* if eof on indd1 but
                                              record exists on indd2  */
  if eofmsg1 then                       /* if EOF msg for INDD1 issued*/
    nop                                 /* don't issue message        */
  else do                               /* Else note INDD1 EOF        */
    say 'EOF has been reached on INDD1' /* Issue msg about it         */
    eofmsg1 = 1                         /* set flag for EOF msg issued*/
    end                                 /* end "else note INDD1 EOF"  */
  cmdcount = cmdcount + 1                  /* bump command count      */
  call create1                             /* create data for indd1   */
  call delete2                             /* delete data from indd2  */
  read2 = 1                                /* need another indd2 rec  */
  iterate loop                             /* loop for next record    */
  end /* done1=1 and done2 = 0 */
 
else if done2 = 1 & done1 = 0 then do      /* else if eof on indd2 but
                                              record exists on indd1  */
  if eofmsg2 then                       /* if EOF msg for INDD2 issued*/
    nop                                 /* don't issue message        */
  else do                               /* Else note INDD2 EOF        */
    say 'EOF has been reached on INDD2' /* issue msg about it         */
    eofmsg2 = 1                         /* set flag for EOF msg issued*/
    end                                 /* end "else note INDD2 EOF"  */
  cmdcount = cmdcount + 1                  /* bump command count      */
  call create2                             /* create data for indd2   */
  call delete1                             /* delete data from indd1  */
  read1 = 1                                /* need another indd1 rec  */
  iterate loop                             /* loop for next record    */
  end /* done2=1 and done1 = 0 */
 
else if done1 = 1 & done2 = 1 then do      /* else if eof on both     */
  iterate loop                             /* iterate to end loop     */
  end /* done1=1 and done2 = 1 */
 
end loop /* loop while data to process */
 
do di = 1 to dummygtot           /* gen cmds to del dummy groups  @LMA*/
  dummygroup = dummygbase || ,   /* set the group name            @LMA*/
               substr(dummygsuf,di,1)
  cmd = 'DELGROUP' dummygroup '/* DELETE TEMPORARY DUMMY GROUP */' /*
                                     build the command            @LMA*/
  ofile = 1                      /* write command to outcln1      @LMA*/
  call writecln                  /*                               @LMA*/
  ofile = 2                      /* write command to outcln2      @LMA*/
  call writecln                  /*                               @LMA*/
  end                                                    /*       @LMA*/
 
/**********************************************************************/
/* Refresh CDT if needed                                              */
/*     Entire section:                                            @M7A*/
/**********************************************************************/
 
do ofile = 1 to 2                 /* process ofile 1 and 2            */
  if CDT.ofile = 1 then do        /* if CDT defines done for ofile    */
    cmd = 'setr classact(cdt)'
    call writeadd
    cmd = 'setr raclist(cdt)'
    call writeadd
    cmd = 'setr raclist(cdt) refresh'
    call writeadd
    say ">>>"
    say ">>>>>> Note: Commands added to OUTADD"ofile" to activate "||,
        "and RACLIST or RACLIST REFRESH the CDT class <<<<<<"
    say ">>>"
    end                           /* if ...                           */
  end                             /* do ofile...                      */
 
/**********************************************************************/
/* Refresh CFIELD if needed                                           */
/*     Entire section:                                            @M7A*/
/**********************************************************************/
 
do ofile = 1 to 2                 /* process ofile 1 and 2            */
  if CFDEF.ofile = 1 then do      /* if CFDEF defines done for ofile  */
    cmd = 'setr classact(cfdef)'
    call writeadd
    cmd = "alloc file(sysut1) dsname('sys1.samplib(irrdpsds)')",
          " shr reuse"
    call writeadd
    cmd = 'irrdpi00 update'
    call writeadd
    cmd = 'free file(sysut1)'
    call writeadd
    say ">>>"
    say ">>>>>> Note: Commands added to OUTADD"ofile" to activate "||,
        "and refresh (IRRDPI00) the CFDEF class <<<<<<"
    say ">>>"
    end                           /* if ...                           */
  end                             /* do ofile...                      */
 
/**********************************************************************/
/* Refresh SECLABEL if needed                                         */
/*     Entire section:                                            @M7A*/
/**********************************************************************/
 
do ofile = 1 to 2                 /* process ofile 1 and 2            */
  if SECLABEL.ofile = 1 then do   /* if SECLABEL added for ofile      */
    cmd = 'setr classact(SECLABEL)'
    call writeadd
    cmd = 'setr raclist(SECLABEL)'
    call writeadd
    cmd = 'setr raclist(SECLABEL) refresh'
    call writeadd
    say ">>>"
    say ">>>>>> Note: Commands added to OUTADD"ofile" to activate "||,
        "and RACLIST or RACLIST REFRESH the SECLABEL class <<<<<<"
    say ">>>"
    end                           /* if ...                           */
  end                             /* do ofile...                      */
 
/************************/
/* Issue stats messages */
/************************/
say 'Successful termination: '
say '  'count1 'records processed from INDD1'
say '  'count2 'records processed from INDD2'
say '  'cmdcount 'command groups created'
say '  'out1trem 'commands written to file OUTREM1'
say '  'out2trem 'commands written to file OUTREM2'
say '  'out1tdel 'commands written to file OUTDEL1'
say '  'out2tdel 'commands written to file OUTDEL2'
say '  'out1tscd 'commands written to file OUTSCD1'        /*     @PNA*/
say '  'out2tscd 'commands written to file OUTSCD2'        /*     @PNA*/
say '  'out1tadd 'commands written to file OUTADD1'        /*     @P5C*/
say '  'out2tadd 'commands written to file OUTADD2'        /*     @P5C*/
say '  'out1talt 'commands written to file OUTALT1'        /*     @P5C*/
say '  'out2talt 'commands written to file OUTALT2'        /*     @P5C*/
say '  'out1tcln 'commands written to file OUTCLN1'        /*     @LMA*/
say '  'out2tcln 'commands written to file OUTCLN2'        /*     @LMA*/
 
 
/*******************/
/* Close the files */
/*******************/
"execio 0 diskr indd1 (finis"
"execio 0 diskr indd2 (finis"
 
tempcount = out1add                 /* get temporary count        @M1A*/
out1add = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outadd1 (stem outaddcmd1. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTADD1'
drop outaddcmd1.                    /*                            @LMA*/
 
tempcount = out2add                 /* get temporary count        @M1A*/
out2add = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outadd2 (stem outaddcmd2. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTADD2'
drop outaddcmd2.                    /*                            @LMA*/
 
tempcount = out1alt                 /* get temporary count        @M1A*/
out1alt = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outalt1 (stem outaltcmd1. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTALT1'
drop outaltcmd1.                    /*                            @LMA*/
 
tempcount = out2alt                 /* get temporary count        @M1A*/
out2alt = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outalt2 (stem outaltcmd2. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTALT2'
drop outaltcmd2.                    /*                            @LMA*/
 
tempcount = out1rem                 /* get temporary count        @M1A*/
out1rem = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outrem1 (stem outremcmd1. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTREM1'
drop outremcmd1.                    /*                            @LMA*/
 
tempcount = out2rem                 /* get temporary count        @M1A*/
out2rem = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outrem2 (stem outremcmd2. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTREM2'
drop outremcmd2.                    /*                            @LMA*/
 
tempcount = out1del                 /* get temporary count        @M1A*/
out1del = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outdel1 (stem outdelcmd1. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTDEL1'
drop outdelcmd1.                    /*                            @LMA*/
 
tempcount = out2del                 /* get temporary count        @M1A*/
out2del = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @M1A*/
"execio" tempcount "diskw outdel2 (stem outdelcmd2. finis"  /*    @M1C*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @M1A*/
  'OUTDEL2'
drop outdelcmd2.                    /*                            @LMA*/
 
 
tempcount = out1cln                 /* get temporary count        @LMA*/
out1cln = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @LMA*/
"execio" tempcount "diskw outcln1 (stem outclncmd1. finis"  /*    @LMA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @LMA*/
  'OUTCLN1'
 
tempcount = out2cln                 /* get temporary count        @LMA*/
out2cln = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @LMA*/
"execio" tempcount "diskw outcln2 (stem outclncmd2. finis"  /*    @LMA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @LMA*/
  'OUTCLN2'
 
tempcount = out1scd                 /* get temporary count        @PNA*/
out1scd = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @PNA*/
"execio" tempcount "diskw outscd1 (stem outscdcmd1. finis"  /*    @PNA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @PNA*/
  'OUTSCD1'
 
tempcount = out2scd                 /* get temporary count        @PNA*/
out2scd = 0                         /* set real count to 0 to avoid
                                       multiple x37 abends if possible
                                                                  @PNA*/
"execio" tempcount "diskw outscd2 (stem outscdcmd2. finis"  /*    @PNA*/
if rc <> 0 then call execio_err1,   /* terminate if execio error  @PNA*/
  'OUTSCD2'
 
 
/*******************/
/* Done.  Exit.    */
/*******************/
if cmdcount > 0 then    /* if any inconsistencies were found          */
  exit 4+(bumprc*4)     /* exit with RC = 4 or 8                      */
else
  exit 0                /* else exit with RC = 0 to show ok           */
 
/****************************************************************/
/* ReadOptions: Reads the OPTIONS file, if present, and sets the*/
/* appropriate variables to control later processing, such as   */
/* record types to include.                                     */
/****************************************************************/
ReadOptions:
 
  include. = ''                    /* initialize include/exclude info */
  exclude. = ''
  include.0 = 0
  exclude.0 = 0
  optionerror = 0                  /* show no errors so far           */
  "execio * diskr options (stem opt. finis"/* read contents of file   */
  if opt.0 > 0 then do             /* process the options lines       */
    say '>>>Processing OPTIONS file:'
    do j = 1 to opt.0              /* process each line of the file   */
      say '>>>  'opt.j
      parse upper var opt.j verb class mask . /* get data from a line */
      if substr(verb,1,1) = '*',
        |substr(verb,1,2) = '/' || '*',
        then iterate               /* skip the line if it's a comment */
      else call ProcessOption      /* else go process the line        */
      end                          /* end "process each line"         */
    including = (0 <> include.0)   /* set flag if any
                                      include-type options present    */
    excluding = (0 <> exclude.0)   /* set flag if any
                                      exclude-type options present    */
    say '>>>Done processing OPTIONS file.'
    drop opt.
    end                            /* end "process the options lines" */
else                               /* else no file or no data, so
                                      issue message                   */
  say "OPTIONS data not supplied. Defaults assumed."
 
if optionerror then do
  say '>>>Terminating due to error in OPTIONS file'
  exit 12
  end
else return;                       /* return to mainline              */
 
/****************************************************************/
/* ProcessOption: Processes a parsed line from the OPTIONS file */
/* and sets the appropriate variables.                          */
/* Input fields: verb, class, mask                              */
/****************************************************************/
ProcessOption:
 
select                                      /* select the option:     */
  when verb = 'SET' then do                 /* SET:                   */
    if class = 'HSMBACK' then do            /*   SET HSMBACK ?        */
      if mask = '*NONE' then                /*   Y: Set null value?   */
        hsmback = ''                        /*     Yes                */
      else
        hsmback = mask                      /*     No - set real value*/
      end                                   /*     End Set null value */
    else if class = 'DUMMYGROUP' then do    /*   N: SET DUMMYGROUP?   */
      if mask = '*NONE' then                /*    Yes: Set null value?*/
        dummygbase = ''                     /*                        */
      else
        dummygbase = strip(substr(mask,1,7))/*    No - real value @LMA*/
      end                                   /*      End Set null value*/
    else if class = 'DUMMYGMAXU' then do    /*   N: Set dummygmaxu?   */
      if datatype(mask,'N') then            /*   validate numeric @LMA*/
        dummygmaxu = mask                   /*   set value if OK  @LMA*/
      else do                               /*   else complain    @LMA*/
        say '>>> Non-numeric SET DUMMYGMAXU value specified:', /* @LMA*/
            ' 'mask                                            /* @LMA*/
        optionerror = 1                     /*   and kill the run @LMA*/
        end                                 /*                    @LMA*/
      dummyucnt = dummygmaxu                /* init count         @PUC*/
      if dummyucnt > 5957 then              /* If customer wants
                                               large dummy groups @LYA*/
         dummyguniv = 'UNIVERSAL'          /* make them universal @LYA*/
      end                                   /*                    @LMA*/
    else if class = 'DUMMYGMAXS' then do    /* N: Set dummygmaxs? @LMA*/
      if datatype(mask,'N') then            /*   validate numeric @LMA*/
        dummygmaxs = mask                   /*   set value if OK  @LMA*/
      else do                               /*   else complain    @LMA*/
        say '>>> Non-numeric SET DUMMYGMAXS value specified:', /* @LMA*/
            ' 'mask                                            /* @LMA*/
        optionerror = 1                     /*   and kill the run @LMA*/
        end                                 /*                    @LMA*/
      dummygcnt = dummygmaxs                /* init count         @LMA*/
      end                                   /*                    @LMA*/
    else if class = 'SET_NOSET' then        /* N: set set_noset?  @PJA*/
      set_noset = mask                      /* use user's value   @PJA*/
    else if class = 'DASD_UNIT' then        /* N: dasd_unit?      @PKA*/
      dasd_unit = mask                      /* use user's value   @PKA*/
    else if class = 'TAPE_UNIT' then        /* N: tape_unit?      @PKA*/
      tape_unit = mask                      /* use user's value   @PKA*/
    else if class = 'DD1FMID' then          /* FMID for DD1?      @M6A*/
      FMID.1 = mask                         /*                    @M7C*/
    else if class = 'DD2FMID' then          /* FMID for DD2?      @M6A*/
      FMID.2 = mask                         /*                    @M7C*/
    else do                                 /*    No: Oops, user error*/
      say '>>> Unknown option for SET, 'class   /* issue msg          */
      optionerror = 1                       /* kill the run           */
      end                                   /* End Oops               */
  end                                       /* End SET                */
 
  when verb = 'INCLUDE' then do             /* INCLUDE:               */
    if class <> '',                         /*   If class present     */
     & length(class) <= 8 then do           /*   and short enough     */
      i = include.0 + 1                     /*     bump include count */
      include.0 = i
      include.0class.i = class              /*     save class name    */
      selecting = 1                         /*   show include/exclude
                                                 processing needed    */
      end                                   /*   End If class present */
    else if class = '',                     /*   Else if class not    */
          | length(class) > 8 then do       /*   valid                */
      say '>>> Incorrect class specified, 'class /* issue msg and     */
      optionerror = 1                       /*   kill the run         */
      end                                   /*   End class not valid  */
  end                                       /* End INCLUDE            */
 
  when verb = 'EXCLUDE' then do             /* EXCLUDE:               */
    if class <> '',                         /*   If class present     */
     & length(class) <= 8 then do           /*   and short enough     */
      i = exclude.0 + 1                     /*     bump exclude count */
      exclude.0 = i
      exclude.0class.i = class              /*     save class name    */
      selecting = 1                         /*   show include/exclude
                                                 processing needed    */
      end                                   /*   End If class present */
    else if class = '',                     /*   Else if class not    */
          | length(class) > 8 then do       /*   valid                */
      say '>>> Incorrect class specified, 'class /* issue msg and     */
      optionerror = 1                       /*   kill the run         */
      end                                   /*   End class not valid  */
  end                                       /* End EXCLUDE            */
 
  when verb = 'SETX' then do                /* SETX (internal options)*/
    if class = 'RECMSGCOUNT' then           /*   SETX RECMSGCOUNT?    */
      RecMsgCount = mask                    /*   Y: set it            */
    else if class = 'EXECIOINCOUNT' then    /*  N: EXECIOINCOUNT? @P7C*/
      ExecioInCount = mask                  /*    Y: set it           */
    else if class = 'EXECIOOUTCOUNT' then   /*  N:EXECIOOUTCOUNT? @P7C*/
      ExecioOutCount = mask                 /*     Y: set it          */
    else if class = 'MAXLEN' then           /*     N: SET MAXLEN?     */
      maxlen = mask                         /*      Y: set it         */
    else do                                 /*      N: Oops.          */
      say '>>> Unknown option for SETX, 'class  /* issue msg          */
      optionerror = 1                       /* kill the run           */
      end                                   /* End Oops               */
  end                                       /* End SET                */
 
  otherwise do
    say '>>>Unknown option: 'verb
    optionerror = 1
    end
  end
 
return;                            /* return to ReadOptions           */
 
/**********************************************************************/
/* Massage:                                                           */
/*   (1) For fields that we can't handle                              */
/*       (dates, times, etc.) set the                                 */
/*       field value to a constant value                              */
/*       so comparisons will work.                                    */
/*   (2) For records that we can't                                    */
/*       handle or that we don't need,                                */
/*       set the "skip" flag so                                       */
/*       the record will be skipped and                               */
/*       a new record will be obtained.                               */
/*   (3) Invoke the selection routine to determine whether the        */
/*       record should be skipped or not.                             */
/*   Note: Ordering of WHEN clauses is based on expected number       */
/*         of records, to improve performance.                        */
/**********************************************************************/
massage:
    parse arg drec
    ddtype = substr(drec,1,4)             /* isolate record type      */
    select
 
      when ddtype = '0400' then do         /* when dataset basic data:*/
        parse var drec,                    /*   parse the data:       */
              1 p1,
             63 .,                         /*     skip create date    */
             74 p2,
             83 .,                         /*     skip last ref/change*/
            129 p3,
            138 .,                         /*     skip group-ds flag  */
            143 p4,
            152 .,                         /*     skip creation group */
            161 p5,
            489 .,                         /*     skip seclevel number*/
            493 p6
        drec  = p1'1234567890 '||,
                p2'123456789012345678911234567892123456789312345 '||,
                p3'1234 'p4'12345678 'p5'123 'p6     /*  rebuild data */
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0400     /* handle include/exclude  */
        end /* ddtype = 0400 */
 
      when ddtype = '0403' then do         /* when ds volumes data    */
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0403     /* handle include/exclude  */
        end /* ddtype = 0403 */
 
      when ddtype = '0404' then do         /* when ds access          */
        parse var drec,                    /*   parse the data:       */
              1 p1,
             76 .                          /*     skip access count   */
        drec  = p1'12345'                  /*   rebuild the data      */
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0404     /* handle include/exclude  */
        end /* ddtype = 0404 */
 
      when ddtype = '0500' then do         /* when general basic data */
        parse var drec,                    /*   parse the data:       */
              1 p1,
            267 .,                         /* skip class #/create date*/
            282 p2,
            291 .,                         /*    skip last ref/change */
            337 p3,
            670 .,                         /*    skip autotapevol flag*/
            675 p4,
            750 .,                         /*    skip seclevel number */
            754 p5
        drec  = p1'12345678901234 'p2||,
          '123456789012345678911234567892123456789312345 '||,
            p3'1234 'p4'123 'p5      /*   rebuild the data            */
        if selecting then call sel0500     /* handle include/exclude  */
        end /* ddtype = 0500 */
 
      when ddtype = '0505' then do         /* when general access data*/
        parse var drec,                    /*   parse the data:       */
              1 p1,
            280 .                          /*     skip access count   */
        drec  = p1'12345'                  /*   rebuild the data      */
        if selecting then call sel0505     /* handle include/exclude  */
        end /* ddtype = 0505 */
 
      when ddtype = '0200' then do         /* when user basic data    */
        drec = substr(drec,1,631)          /* ensure record long enough
                                              for full record     @Q7C*/
        parse var drec,                    /*   parse the data:       */
              1 p1,
             15 .,                         /*     skip create date    */
             26 p2,
             64 .,                         /*     skip password date  */
             75 p3,
            105 .,                         /*     skip last access    */
            125 p4,                        /*                     @PPA*/
            396 .,                         /*     skip oidcard        */
            401 .,                         /*     skip pwdgen         */
            405 .,                         /*     skip revoke count   */
            409 p5,
            454 .,                         /*     skip seclevel number*/
            458 p6,                        /*                     @M3C*/
            551 .,                    /* Skip envelope exists?    @M3A*/
            556 .,                         /* password asis?      @M5A*/
            561 .,                         /* phrase date         @M7A*/
            572 .,                         /* phrase generation # @M7A*/
            576 .,                         /* cert sequence #     @M7A*/
            587 .,                         /* phrase env exists?  @M7A*/
            591 p8                         /*                     @M7C*/
 
        drec  = p1'1234567890 'p2'1234567890 'p3||,
          '1234567890123456789 'p4' 678901234567 'p5'123 'p6||,/* @M3C*/
          '1234 1234 1234567890 123 1234567890 1234'||,        /* @M7C*/
          p8                               /* rebuild data        @M5C*/
        if selecting then call sel0200     /* handle include/exclude  */
        if substr(drec,6,3) = 'irr' then
          skip = 1                         /* skip irr.... IDs    @PHA*/
        end /* ddtype = 0200 */
 
 
      when ddtype = '0203' then skip     = 1 /* skip user-group
                                             connection record - don't
                                              need, will use the 0205
                                              record                  */
 
      when ddtype = '0205' then do         /* when user connect data: */
        parse var drec,                    /*   parse the data:       */
              1 p1,
             24 .,                         /*     skip connect date   */
             35 p2,
             44 .,                         /*     skip last access    */
             64 p3,
             73 .,                         /*     skip access count   */
             79 p4
        drec  = p1'1234567890 'p2||,
          '1234567890123456789 'p3'12345 'p4 /* rebuild data          */
        if selecting then call sel0205     /* handle include/exclude  */
        end /* ddtype = 0205 */
 
      when ddtype = '0102' then            /* when group members data */
        if selecting then call sel0102     /* handle include/exclude
                                                                  @P3C*/
 
      when ddtype = '0100' then do         /* when group basic data   */
        drec = substr(drec,1,362)          /* ensure record long
                                              enough for UNIV.    @PYA*/
        parse var drec,                    /*   parse the data:       */
                        1 p1,
                       24 .,               /*     skip create date    */
                       35 p2,              /*                     @LXC*/
                      359 p3,              /*  handle universal   @LXC*/
                      363 p4               /*                     @PYC*/
 
        if p3 = "" then                    /* If no universal     @LXC*/
          p3 = "NO  "                      /* value assume NO     @PYC*/
        drec  = p1'1234567890 'p2||p3||p4  /*   rebuild data      @LXC*/
        if selecting then call sel0100     /* handle include/exclude  */
        end /* ddtype = 0100 */
 
      when ddtype = '0206' then do         /* when user associations: */
        parse var drec,                    /*   parse the data:       */
              1 p1,
             33 .,                         /*     skip version        */
             37 p2,
             52 .,                         /*     skip pendings       */
             62 p3,
             67 .,                         /*     skip error & stamps */
            126 p4                         /*                     @Q5C*/
        drec  = p1'123 'p2||,
          '123456789 'p3||,
          '12345678901234567890123456789012345678901234567890'||,
          '12345678 'p4                    /*rebuild data         @Q5C*/
        if selecting then call sel0206     /* handle include/exclude  */
        end /* ddtype = 0206 */                               /*      */
 
 
      when ddtype = '0220' then do         /* when user TSO data:     */
          parse var drec,                  /*   parse the data:       */
              1 p1,                        /*                    2@PXD*/
            183 .,                         /*     skip perf group     */
            194 p3
        drec  = p1||,                      /*                     @PXC*/
          '1234567890 'p3                  /* rebuild data            */
        if selecting then call sel0220     /* handle include/exclude  */
        end /* ddtype = 0220 */
 
      when ddtype = '0402' then do         /* when ds cond. access    */
        drec = substr(drec,1,353)          /* pad if necessary    @M7C*/
        parse var drec,                    /*   parse the data:       */
              1 p1,
             94 . ,                        /*   skip access count     */
            100 p2
        drec =p1'12345 'p2                 /*   rebuild the data  @M7C*/
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip    = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0402     /* handle include/exclude  */
        end /* ddtype = 0402 */
 
      when ddtype = '0405' then do         /* when ds instdata data   */
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0405     /* handle include/exclude  */
        end /* ddtype = 0405 */
 
      when ddtype = '0410' then do         /* when ds DFP data        */
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets       */
        if skip = 0 &,
           selecting then call sel0410     /* handle include/exclude  */
        end /* ddtype = 0410 */
 
      when ddtype = '0421' then do         /* when ds TME data    @LIA*/
        if hsmblen > 0 &,
           substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets   @LIA*/
        if skip = 0 &,
           selecting then call sel0421     /* handle include/excl @LIA*/
        end /* ddtype = 0421                                      @LIA*/
 
 
      when ddtype = '0501' then do         /* when general tvtoc  @P3M*/
        parse var drec,                    /*   parse the data:   @P3A*/
              1 p1,                                        /*     @P3A*/
            268 .,                         /*    skip create date @P3A*/
            279 p2                                         /*     @P3A*/
        drec  = p1'1234567890 'p2          /*   rebuild the data  @P3A*/
        if selecting then call sel0501     /* handle include/exclude
                                                                  @P3C*/
        end /* ddtype = 0501 @P3M*/
 
      when ddtype = '0507' then do         /* when general cond.access*/
        drec = substr(drec,1,557)          /* pad if needed       @M7A*/
        parse var drec,                    /*   parse the data:       */
              1 p1,
            298 . ,                        /*     skip access count   */
            304 p2                         /*                     @M7A*/
        drec  = p1'12345 'p2               /*   rebuild the data  @M7C*/
        if selecting then call sel0507     /* handle include/exclude  */
        end /* ddtype = 0507 */
 
      when ddtype = '0510' then do         /* when gen. SESSION       */
        parse var drec,                    /*   parse the data:       */
              1 p1,                        /*                         */
            276 .,                         /*     skip key date       */
            287 p2                         /*                         */
        drec  = p1'1234567890 'p2          /*   rebuild the data      */
        if selecting then call sel0510     /* handle include/exclude  */
        end /* ddtype = 0510 */            /*                         */
 
      when ddtype = '0511' then skip   = 1 /* skip gen. session, not
                                              really used by RACF     */
 
      when ddtype = '02D0' then do         /* when user kerb      @LRA*/
       drec = substr(drec,1,359)           /* pad length if nec   @M7C*/
       parse var drec,                     /*   parse the data:       */
              1 p1,                        /*                         */
            267 .,                         /*     skip key version    */
            271 p2,                        /*                     @M7C*/
            351 .                          /*   skip keyfrom      @M7C*/
        drec  = p1'123 'p2'12345678 '      /*   rebuild the data  @M7C*/
        if selecting then call sel02d0
        end /* ddtype = 02D0 */
 
     when ddtype = '0580' then do          /* when general kerb   @LRA*/
       drec = substr(drec,1,564)           /* pad if necessary    @M7A*/
       parse var drec,                     /*   parse the data:       */
              1 p1,                        /*                         */
            536 .,                         /*     skip key version    */
            540 p2                         /*                         */
       drec  = p1'123 'p2                  /*   rebuild the data      */
       if selecting then call sel0580
       end /* ddtype = 0580 */
 
     when ddtype = '0401' then do          /* when DATASET cat.   @POA*/
       if hsmblen > 0 &,
          substr(drec,6,hsmblen) = hsmback then skip  = 1 /* skip
                                            HSM.BACK. data sets   @POA*/
        if skip = 0 &,
           selecting then call sel0401     /* handle incl/excl    @POA*/
 
        end                                /*                     @POA*/
 
      when ddtype = '05B0' then skip     = 1 /* skip IPLOOK alias
                                             records for SERVAUTH class
                                             created for MLS      @M0A*/
 
 
      otherwise                            /* other records:          */
        if selecting then                  /* use as-is unless we're  */
          select                           /* applying selection      */
          when ddtype = '0101' then        /* when group subgroup data*/
            call sel0101                   /* handle include/exclude  */
 
          when ddtype = '0103' then        /* when group inst. data   */
            call sel0103                   /* handle include/exclude  */
 
          when ddtype = '0110' then        /* when group dfp data     */
            call sel0110                   /* handle include/exclude  */
 
          when ddtype = '0120' then        /* when group omvs data    */
            call sel0120                   /* handle include/exclude  */
 
          when ddtype = '0130' then        /* when group ovm data @LGA*/
            call sel0130                   /* handle include/excl @LGA*/
 
          when ddtype = '0141' then        /* when group tme data @LIA*/
            call sel0141                   /* handle include/excl @LIA*/
 
          when ddtype = '0151' then        /* when group CSDATA   @M7A*/
            call sel0151                   /* handle include/excl @M7A*/
 
 
          when ddtype = '0201' then        /* when user category data */
            call sel0201                   /* handle include/exclude  */
 
          when ddtype = '0202' then        /* when user classes data  */
            call sel0202                   /* handle include/exclude  */
 
          when ddtype = '0204' then        /* when user inst. data    */
            call sel0204                   /* handle include/exclude  */
 
          when ddtype = '0207' then        /* when user cert info @LLA*/
            call sel0207                   /* handle incl/excl    @LLA*/
 
          when ddtype = '0208' then        /* when user certassoc @LUA*/
            call sel0208                   /* handle incl/excl    @LUA*/
 
          when ddtype = '0210' then        /* when user DFP data      */
            call sel0210                   /* handle include/exclude  */
 
          when ddtype = '0230' then        /* when user CICS data     */
            call sel0230                   /* handle include/exclude  */
 
          when ddtype = '0231' then        /* when user CICS op. data */
            call sel0231                   /* handle include/exclude  */
 
          when ddtype = '0232' then        /* Handle inc/exc for  @M5A*/
            call sel0232                   /* user CICS RSL key   @M5A*/
 
          when ddtype = '0233' then        /* Handle inc/exc for  @M5A*/
            call sel0233                   /* user CICS TSL key   @M5A*/
 
          when ddtype = '0240' then        /* when user LANGUAGE data */
            call sel0240                   /* handle include/exclude  */
 
          when ddtype = '0250' then do     /* when user OPERPARM  @M7C*/
            drec = substr(drec,1,850)      /* pad if necessary    @M7C*/
            call sel0250                   /* handle include/exclude  */
            end                            /*                     @M7A*/
 
          when ddtype = '0251' then        /* when user OPERPARM scope*/
            call sel0251                   /* handle include/exclude  */
 
          when ddtype = '0260' then        /* when user WORKDATA data */
            call sel0260                   /* handle include/exclude  */
 
          when ddtype = '0270' then        /* when user OMVS data     */
            call sel0270                   /* handle include/exclude  */
 
          when ddtype = '0290' then        /* when user DCE data  @LCA*/
            call sel0290                   /* handle incl/exclude @LCA*/
 
          when ddtype = '02A0' then        /* when user OVM data  @LGA*/
            call sel02A0                   /* handle incl/exclude @LGA*/
 
          when ddtype = '02B0' then        /* when user LNOTES    @LJA*/
            call sel02B0                   /* handle incl/excl    @LJA*/
 
          when ddtype = '02C0' then        /* when user NDS       @LKA*/
            call sel02C0                   /* handle incl/excl    @LKA*/
 
          when ddtype = '02E0' then        /* when user PROXY     @LTA*/
            call sel02E0                   /* handle incl/excl    @LTA*/
 
          when ddtype = '02F0' then        /* when user EIM       @LZA*/
            call sel02F0                   /* handle incl/excl    @LZA*/
 
          when ddtype = '02G1' then        /* when user CSDATA    @M7A*/
            call sel02G1
 
          when ddtype = '0280' then        /* when user NETVIEW data  */
            call sel0280                   /* handle include/exclude  */
 
          when ddtype = '0281' then        /* when user NETVIEW
                                              operator classes        */
            call sel0281                   /* handle include/exclude  */
 
          when ddtype = '0282' then        /* when user NETVIEW
                                              domains                 */
            call sel0282                   /* handle include/exclude  */
 
          when ddtype = '0502' then        /* when general categories */
            call sel0502                   /* handle include/exclude  */
 
          when ddtype = '0503' then        /* when general member data*/
            call sel0503                   /* handle include/exclude  */
 
          when ddtype = '0504' then        /* when general volume data*/
            call sel0504                   /* handle include/exclude  */
 
          when ddtype = '0506' then        /* when general inst. data */
            call sel0506                   /* handle include/exclude  */
 
          when ddtype = '0508' then        /* when general filter @LUA*/
            call sel0508                   /* handle include/exclude  */
 
          when ddtype = '0520' then        /* when general DLF data   */
            call sel0520                   /* handle include/exclude  */
 
          when ddtype = '0521' then        /* when general DLFjob data*/
            call sel0521                   /* handle include/exclude  */
 
          when ddtype = '0540' then        /* when general STDATA data*/
            call sel0540                   /* handle include/exclude  */
 
          when ddtype = '0550' then        /* when gen. svfmr     @LDA*/
            call sel0550                   /* handle incl/excl    @LDA*/
 
          when ddtype = '0560' then        /* when gen cert data  @LLA*/
            call sel0560                   /* handle incl/excl    @LLA*/
 
          when ddtype = '0561' then        /* when gen cert data  @LLA*/
            call sel0561                   /* handle incl/excl    @LLA*/
 
          when ddtype = '0562' then        /* when gen cert data  @LLA*/
            call sel0562                   /* handle incl/excl    @LLA*/
 
          when ddtype = '0570' then        /* when gen tme        @LIA*/
            call sel0570                   /* handle incl/excl    @LIA*/
 
          when ddtype = '0571' then        /* when gen tme child  @LIA*/
            call sel0571                   /* handle incl/excl    @LIA*/
 
          when ddtype = '0572' then        /* when gen tme res.   @LIA*/
            call sel0572                   /* handle incl/excl    @LIA*/
 
          when ddtype = '0573' then        /* when gen tme group  @LIA*/
            call sel0573
 
          when ddtype = '0574' then        /* when gen tme roles  @LIA*/
            call sel0574
 
          when ddtype = '0590' then        /* when gen proxy      @LTA*/
            call sel0590
 
          when ddtype = '05A0' then        /* when gen EIM        @LZA*/
            call sel05A0
 
          when ddtype = '05C0' then        /* when gen CDTINFO    @M4A*/
            call sel05C0
 
          when ddtype = '05D0' then        /* when gen ICTX       @M7A*/
            call sel05D0
 
          when ddtype = '05E0' then        /* when gen CFDEF      @M7A*/
            call sel05E0
 
 
    /***************************************************/
    /* Unexpected record type found if we get here.    */
    /* Issue a message and skip it.                    */
    /***************************************************/
          otherwise do
            say '>>>Unexpected record skipped, type 'ddtype,
              'Count1 = 'count1'; Count2 = 'count2
            skip = 1                    /* skip the record            */
            bumprc = 1                  /* indicate rc to be bumped   */
            end
          end                              /* End Select "applying..."*/
      end /* select */
    return drec
 
/****************************************************************/
/* MAKEKEYS: Generate keys for two records which have the same  */
/* record type so we can see if they are really for the same    */
/* profile.                                                     */
/* Note: WHEN clauses are ordered based roughly on expected     */
/*       numbers of records in order to improve performance.    */
/****************************************************************/
makekeys:
  select                                   /* generate "keys" to see if
                                              records are for same
                                              profile data            */
    /***************************************************/
    /* For dataset basic data or dataset DFP data      */
    /* use dsname and vol as the key                   */
    /***************************************************/
    when 0 <> pos(dd1type,'0400 0410') then do
      key1 = substr(data1,6,51)
      key2 = substr(data2,6,51)
      end /* 0400, 0410 */
 
    /***************************************************/
    /* For dataset volumes data                        */
    /* use dsname, vol, and additional vol as the key. */
    /***************************************************/
    when dd1type = '0403' then do
      key1 = substr(data1,6,58)
      key2 = substr(data2,6,58)
      end /* 0403 */
 
    /***************************************************/
    /* For dataset access data or dataset installation */
    /* data data,                                      */
    /* use dsname, vol, and id/field_name as the key.  */
    /***************************************************/
    when 0 <> pos(dd1type,'0404 0405') then do
      key1 = substr(data1,6,60)
      key2 = substr(data2,6,60)
      end /* 0404, 0405 */
 
    /***************************************************/
    /* For dataset TME info                        @LIA*/
    /*                                             @LIA*/
    /* use everything as the key.                  @LIA*/
    /***************************************************/
    when 0 <> pos(dd1type,'0421') then do       /* @LIA*/
      key1 = substr(data1,6)                    /* @LIA*/
      key2 = substr(data2,6)                    /* @LIA*/
      end /* 0421                                  @LIA*/
 
 
    /***************************************************/
    /* For general resource basic data, or g.r.        */
    /* dlf data or g.r. KERB data or g.r. PROXY        */
    /* or g.r. STDATA data                             */
    /* or g.r. session data or g.r. svfmr data         */
    /* or g.r. EIM data                            @LZA*/
    /* or g.r  CDTINFO, ICTX, or CFDEF data        @M7A*/
    /* use name, class as the key.                     */
    /***************************************************/
    when 0 <> pos(dd1type,,
           '0500 0510 0520 0540 0550 ' ||,
           '0580 0590 05A0 05C0 05D0 05E0 ') then do /*
                                                    @M7C*/
      key1 = substr(data1,6,255)
      key2 = substr(data2,6,255)
      end /* 0500, 0510, 0520, 0540, 0550 0580-05E0 @M7C*/
 
    /***************************************************/
    /* For general resource access data, g.r.          */
    /* installation data data, g.r. DLF jobnames data  */
    /* use name, class, id/field_name/job_name as key. */
    /***************************************************/
    when 0 <> pos(dd1type,'0505 0506 0521') then do
      key1 = substr(data1,6,264)
      key2 = substr(data2,6,264)
      end /* 0505, 0506,0521 */
 
    /***************************************************/
    /* For general resource TME data,              @LIA*/
    /* use everything as key.                      @LIA*/
    /***************************************************/
    when 0 <> pos(dd1type,,
      '0570 0571 0572 0573 0574') then do     /*   @LIA*/
      key1 = substr(data1,6)                  /*   @LIA*/
      key2 = substr(data2,6)                  /*   @LIA*/
      end /* 0570, 0571, 0572, 0573, 0574          @LIA*/
 
 
    /***************************************************/
    /* For user basic data, user DFP data, user TSO    */
    /* data, user CICS data, user LANGUAGE data, user  */
    /* OPERPARM data, or user WORKATTR data, or        */
    /* user NETVIEW data, or                           */
    /* user OMVS data or user DCE data                 */
    /* or user LNOTES or user NDS data                 */
    /* or user KERB or user PROXY or user EIM      @LZC*/
    /* use the user id as the key.                     */
    /***************************************************/
    when 0 <> pos(dd1type,,
   '0200 0210 0220 0230 0240 0250 0260 ' || ,
   '0270 0280 0290 02A0 02B0 02C0 02D0 02E0 ' || ,
   '02F0 02G1 ') then do                        /* @M7C*/
        key1 = substr(data1,6,8)
        key2 = substr(data2,6,8)
      end /* 0200, 0210, 0220, ..., 2G1            @M7C*/
 
    /***************************************************/
    /* For user clauth data, user installation data,   */
    /* user connect data, or user operparm scope data, */
    /* use user id and class_name/field_name/group_id/ */
    /* system_name as the key.                         */
    /***************************************************/
    when 0 <> pos(dd1type,'0202 0204 0205 0251') then do
      key1 = substr(data1,6,17)
      key2 = substr(data2,6,17)
      end /* 0202, ..., 0251 */
 
    /***************************************************/
    /* For group subgroup data, group member data, or  */
    /* group installation data use the group name and  */
    /* subgroup/user/field_name as the key.            */
    /***************************************************/
    when 0 <> pos(dd1type,'0101 0102 0103') then do
      key1 = substr(data1,6,17)
      key2 = substr(data2,6,17)
      end /* 0101, 0102 or 0103 */
 
    /***************************************************/
    /* For group basic data or group DFP data or       */
    /* group OMVS data or group OVM data or group TME  */
    /* or group CSDATA                             @M7A*/
    /* use the group id as the key.                    */
    /***************************************************/
    when 0 <> pos(dd1type,,
      '0100 0110 0120 0130 0141 0151 ') then do /* @M7C*/
      key1 = substr(data1,6,8)
      key2 = substr(data2,6,8)
      end /* 0100 or 0110 or 0120 ... or 0151      @M7C*/
 
    /***************************************************/
    /* For user CICS operator class data,              */
    /* use user id and operator class as the key.      */
    /***************************************************/
    when dd1type = '0231' then do
      key1 = substr(data1,6,12)
      key2 = substr(data2,6,12)
      end /* 0231 */
 
    /***************************************************/      /* @M5A*/
    /* For user CICS RSL key or TSL key data           */      /* @M5A*/
    /* use user id and operator class as the key.      */      /* @M5A*/
    /***************************************************/      /* @M5A*/
    when 0 <> pos(dd1type,'0232 0233') then do                 /* @M5A*/
      key1 = substr(data1,6,14)                                /* @M5A*/
      key2 = substr(data2,6,14)                                /* @M5A*/
      end /* 0232, 0233 */                                     /* @M5A*/
 
    /***************************************************/
    /* For user association data,                      */
    /* use user id, target node, and target user id as */
    /* the key.                                        */
    /***************************************************/
    when dd1type = '0206' then do
      key1 = substr(data1,6,26)
      key2 = substr(data2,6,26)
      end /* 0206 */
 
    /***************************************************/
    /* For user certificat data,                   @LLA*/
    /* use user id, and certificate name           @LLA*/
    /* the key.                                    @LLA*/
    /***************************************************/
    when dd1type = '0207' then do             /*   @LLA*/
      key1 = substr(data1,6,254)              /*   @LLA*/
      key2 = substr(data2,6,254)              /*   @LLA*/
      end /* 0207                                  @LLA*/
 
    /***************************************************/
    /* For user certificate assoc,                 @LUA*/
    /* use user id, and certificate label, and         */
    /* map name as key                                 */
    /***************************************************/
    when dd1type = '0208' then do
      key1 = substr(data1,6,288)
      key2 = substr(data2,6,288)
      end /* 0208                                  @LUA*/
 
 
    /***************************************************/
    /* For user NETVIEW operator class and domain data */
    /* use user id and data value as the key.          */
    /***************************************************/
    when 0 <> pos(dd1type,'0281 0282') then do
      key1 = substr(data1,6,14)
      key2 = substr(data2,6,14)
      end /* 0281, 0282 */
 
    /***************************************************/
    /* For dataset conditional access data             */
    /* use dsname, vol, type of conditional, class,    */
    /* and id as the key.                              */
    /***************************************************/
    when dd1type = '0402' then do
      key1 = substr(data1,6,78)||,
             substr(data1,100,253)              /* @M7C*/
      key2 = substr(data2,6,78)||,
             substr(data2,100,253)              /* @M7C*/
      end /* 0402 */
 
    /***************************************************/
    /* For general resource tvtoc data use profile     */
    /* name, class name (TAPEVOL) and file sequence    */
    /* as the key. (TAPEVOL not needed, but used for   */
    /* convenience/performance.)                       */
    /***************************************************/
    when dd1type = '0501' then do
      key1 = substr(data1,6,261)
      key2 = substr(data2,6,261)
      end /* 0501 */
 
    /***************************************************/
    /* For general resource member data                */
    /* use name, class, member name as the key.        */
    /***************************************************/
    when dd1type = '0503' then do
      key1 = substr(data1,6,511)
      key2 = substr(data2,6,511)
      end /* 0503 */
 
    /***************************************************/
    /* For general resource volumes data use           */
    /* use name, class, additional volume name as key. */
    /***************************************************/
    when dd1type = '0504' then do
      key1 = substr(data1,6,261)
      key2 = substr(data2,6,261)
      end /* 0504 */
 
    /***************************************************/
    /* For general resource conditional access data    */
    /* use name, class, condition type, condition name,*/
    /* id as the key.                                  */
    /***************************************************/
    when dd1type = '0507' then do
      key1 = substr(data1,6,282)||,
             substr(data1,304,253)             /*  @M7C*/
      key2 = substr(data2,6,282)||,
             substr(data2,304,253)             /*  @M7C*/
      end /* 0507 */
 
    /***************************************************/
    /* For general resource filter data            @LUA*/
    /* use name, class, condition type, condition name,*/
    /* id as the key.                                  */
    /***************************************************/
    when dd1type = '0508' then do
      key1 = substr(data1,6,245)
      key2 = substr(data2,6,245)
      end /* 0508 */
 
 
    /***************************************************/
    /* For general resource certificate data       @LLA*/
    /* use name, class, condition type, condition name,*/
    /* id as the key.                                  */
    /***************************************************/
    when 0 <> pos(dd1type,,
              '0560 0561 0562') then do         /* @LLA*/
      key1 = substr(data1,6,254)                /* @LLA*/
      key2 = substr(data2,6,254)                /* @LLA*/
      end /* 0560, 0561, 0562                      @LLA*/
 
    otherwise do           /* shouldn't be hit as
                              we detected and skipped
                              unknown records during
                              massage                  */
      say '>>>Unexpected record reached makekeys: Count1 = ',
        count1'; Count2 = 'count2'; type = 'substr(data1,1,4)
      bumprc = 1           /* indicate rc to be bumped by 4           */
      end
    end  /* select */
  return                                /* return to caller           */
 
/****************************************************************/
/* Subroutines to control record selection                      */
/* If any include/p specifications exist, then we will skip the */
/* record unless it matches an include/p.                       */
/* If any exclude/p specifications exist, we will skip the      */
/* record if it matches an exclude/p.                           */
/* Note: Groups of SELxxxx entries are ordered roughly in the   */
/*       expected number of records to improve performance.     */
/****************************************************************/
/****************************************************************/
/*  Selection control for DATASET-related records               */
/****************************************************************/
sel0400:                                /* select DATASET basic       */
sel0401:                                /* select DATASET categories  */
sel0402:                                /* select DATASET cond. access*/
sel0403:                                /* select DATASET volumes     */
sel0404:                                /* select DATASET access      */
sel0405:                                /* select DATASET inst. data  */
sel0410:                                /* select DATASET dfp         */
sel0421:                                /* select DATASET tme     @LIA*/
 
  cname = 'DATASET'                     /* set class name to DATASET  */
  call selstuff                         /* apply selection criteria   */
  return                                /* return to caller           */
 
/****************************************************************/
/*  Selection control for general resource related records      */
/****************************************************************/
sel0500:                                /* select general basic       */
sel0501:                                /* select general tvtoc       */
sel0502:                                /* select general categories  */
sel0503:                                /* select general member      */
sel0504:                                /* select general volume      */
sel0505:                                /* select general access      */
sel0506:                                /* select general inst. data  */
sel0507:                                /* select general cond. access*/
sel0508:                                /* select general filter  @LUA*/
sel0510:                                /* select general session     */
sel0520:                                /* select general dlf         */
sel0521:                                /* select general dlf jobnames*/
sel0540:                                /* select general stdata      */
sel0550:                                /* select general svfmr   @LDA*/
sel0560:                                /* select general cert    @LLA*/
sel0561:                                /* select general cert    @LLA*/
sel0562:                                /* select general cert    @LLA*/
sel0570:                                /* select general tme     @LIA*/
sel0571:                                /* select general tmechld @LIA*/
sel0572:                                /* select general tmeres  @LIA*/
sel0573:                                /* select general tme grp @LIA*/
sel0574:                                /* select general tme rol @LIA*/
sel0580:                                /* select general kerb    @LRA*/
sel0590:                                /* select general proxy   @LTA*/
sel05A0:                                /* select general EIM     @LZA*/
sel05C0:                                /* select general CDTINFO @M4A*/
sel05D0:                                /* select general ICTX    @M7A*/
sel05E0:                                /* select general CFDEF   @M7A*/
 
  cname = substr(drec,253,8)            /* set class name             */
  call selstuff                         /* apply selection criteria   */
  return                                /* return to caller           */
 
/****************************************************************/
/*  Selection control for user-related records                  */
/****************************************************************/
sel0102:                                /* select group member        */
                                        /* Note:
                                           this is treated as a user
                                           record for consistency with
                                           RRSF AUTODIRECT processing */
sel0200:                                /* select user basic          */
sel0201:                                /* select user categories     */
sel0202:                                /* select user classes        */
sel0204:                                /* select user inst. data     */
sel0205:                                /* select user connects       */
sel0206:                                /* select user associations   */
sel0207:                                /* select user cert       @LLA*/
sel0208:                                /* select user cert assoc @LUA*/
sel0210:                                /* select user dfp            */
sel0220:                                /* select user tso            */
sel0230:                                /* select user cics           */
sel0231:                                /* select user cics oper      */
sel0232:                                /* select user cics RSL   @M5A*/
sel0233:                                /* select user cics TSL   @M5A*/
sel0240:                                /* select user language       */
sel0250:                                /* select user operparm       */
sel0251:                                /* select user operparm scope
                                                                  @P4A*/
sel0260:                                /* select user workattr       */
sel0270:                                /* select user omvs           */
sel0280:                                /* select user netview        */
sel0281:                                /* select user netview
                                           operator classes           */
sel0282:                                /* select user netview
                                           domains                    */
sel0290:                                /* select user DCE        @LCA*/
sel02A0:                                /* select user OVM        @LGA*/
sel02B0:                                /* select user LNOTES     @LJA*/
sel02C0:                                /* select user NDS        @LKA*/
sel02D0:                                /* select user KERB       @LRA*/
sel02E0:                                /* select user PROXY      @LTA*/
sel02F0:                                /* select user EIM        @LZA*/
sel02G1:                                /* select user CSDATA     @M7C*/
 
  cname = 'USER'                        /* set class name to USER     */
  call selstuff                         /* apply selection criteria   */
  return                                /* return to caller           */
 
/****************************************************************/
/*  Selection control for group-related records                 */
/****************************************************************/
sel0100:                                /* select group basic         */
sel0101:                                /* select group subgroup      */
sel0103:                                /* select group inst. data    */
sel0110:                                /* select group dfp           */
sel0120:                                /* select group omvs          */
sel0130:                                /* select group ovm       @LGA*/
sel0141:                                /* select group tme       @LIA*/
sel0151:                                /* select group csdata    @M7A*/
 
  cname = 'GROUP'                       /* set class name to GROUP    */
  call selstuff                         /* apply selection criteria   */
  return                                /* return to caller           */
 
/****************************************************************/
/*  Basic selection code:    input: cname                       */
/****************************************************************/
selstuff:                               /* select a record            */
 
  if including then do                  /* process include options    */
    skip = 1                            /* assume record is skipped   */
    do k = 1 to include.0 until skip=0  /* try to include it...       */
      if include.0class.k = cname then  /* include this class?        */
        skip = 0                        /* if match, don't skip       */
      end                               /* end "try to include it"    */
    end                                 /* end "process include"      */
  if excluding & skip = 0 then do       /* process exclude options if
                                           record is being included   */
    do k = 1 to exclude.0 until skip=1  /* try to exclude it...       */
      if exclude.0class.k = cname then  /* exclude this class?        */
        skip = 1                        /* if match, then skip        */
      end                               /* end "try to exclude it"    */
    end                                 /* end "process exclude"      */
  return                                /* return to caller           */
 
/****************************************************************/
/* Subroutines to control data generation/deletion/modification */
/****************************************************************/
/*************************/
/* Create data for indd1 */
/*************************/
create1: datarec = data2                /* use data from indd1        */
  ofile = 1                             /* use indd1's output files   */
  type = 'define'                       /* indicate define needed     */
  call gencmd                           /* go create the commands     */
  return
 
/*************************/
/* Create data for indd2 */
/*************************/
create2: datarec = data1                /* use data from indd2        */
  ofile = 2                             /* use indd1's output files   */
  type = 'define'                       /* indicate define needed     */
  call gencmd                           /* go create the commands     */
  return
 
/**************************/
/* Delete data from indd1 */
/**************************/
delete1: datarec = data1                /* use data from indd1        */
  ofile = 1                             /* use indd1's output files   */
  type = 'delete'                       /* indicate delete needed     */
  call gencmd                           /* go create the commands     */
  return
 
/**************************/
/* Delete data from indd2 */
/**************************/
delete2: datarec = data2                /* use data from indd2        */
  ofile = 2                             /* use indd2's output files   */
  type = 'delete'                       /* indicate delete needed     */
  call gencmd                           /* go create the commands     */
  return
 
/**************************/
/* Alter data on indd1    */
/**************************/
alter1: datarec = data2                 /* use data from indd2        */
  ofile = 1                             /* use indd1's output files   */
  type = 'alter'                        /* indicate alter needed      */
  call gencmd                           /* go create the commands     */
  return
 
/**************************/
/* Alter data on indd2    */
/**************************/
alter2: datarec = data1                 /* use data from indd1        */
  ofile = 2                             /* use indd2's output files   */
  type = 'alter'                        /* indicate alter needed      */
  call gencmd                           /* go create the commands     */
  return
 
/*****************************************************/
/* Check to see if user's dfltgrp needs to be reset  */
/* to the correct value. This is only done explicitly*/
/* when the two 0200 records are equal, as other     */
/* cases will be fixed automatically for unequal or  */
/* missing records.                                  */
/*****************************************************/
chkdfltgrp:
  usbd_name = strip(substr(data1,6,8))  /* get the user id            */
  usbd_defgrp_id = strip(substr(data1,96,8))/* get dfltgrp            */
  if wordpos(usbd_name,resetdflt.1) > 0 /* if user in file 1 list     */
    then do                             /* then reset dfltgrp         */
      cmd = 'altuser' usbd_name         /* build altuser + userid     */
      cmd = cmd 'dfltgrp('usbd_defgrp_id')' /* add to cmd             */
      ofile = 1                         /* set output file id         */
      call writealt                     /* write cmd to OUTALTn       */
                                                         /*      5@LMD*/
      end                               /* end user in list 1         */
  if wordpos(usbd_name,resetdflt.2) > 0 /* if user in file 2 list     */
    then do                             /* then reset dfltgrp         */
      cmd = 'altuser' usbd_name         /* build altuser + userid     */
      cmd = cmd 'dfltgrp('usbd_defgrp_id')' /* add to cmd             */
      ofile = 2                         /* set output file id         */
      call writealt                     /* write cmd to OUTALTn       */
                                                         /*      5@LMD*/
      end                               /* end user in list 2         */
  return                                /* return to main loop        */
 
/*****************************************************/
/* Route control to right place to build the command */
/* Note: WHEN clauses are ordered roughly based on   */
/*       the number of expected records to improve   */
/*       performance.                                */
/*****************************************************/
gencmd:  rtype = substr(datarec,1,4)    /* isolate the record type    */
select                                  /* select correct routine     */
  when rtype='0400' then call genc0400
  when rtype='0403' then call genc0403
  when rtype='0404' then call genc0404
  when rtype='0500' then call genc0500
  when rtype='0504' then call genc0504
  when rtype='0505' then call genc0505
  when rtype='0506' then call genc0506
  when rtype='0200' then call genc0200
  when rtype='0205' then call genc0205
  when rtype='0102' then call genc0102
  when rtype='0100' then call genc0100
  when rtype='0101' then call genc0101
  when rtype='0103' then call genc0103
  when rtype='0110' then call genc0110
  when rtype='0120' then call genc0120
  when rtype='0130' then call genc0130                   /*    @LGA*/
  when rtype='0141' then call genc0141                   /*    @LIA*/
  when rtype='0151' then call genc0151                   /*    @M7A*/
  when rtype='0201' then call genc0201
  when rtype='0202' then call genc0202
  when rtype='0204' then call genc0204
  when rtype='0206' then call genc0206
  when rtype='0207' then call genc0207                   /*    @LLA*/
  when rtype='0208' then call genc0208                   /*    @LUA*/
  when rtype='0210' then call genc0210
  when rtype='0220' then call genc0220
  when rtype='0230' then call genc0230
  when rtype='0231' then call genc0231
  when rtype='0232' then call genc0232                        /* @M5A*/
  when rtype='0233' then call genc0233                        /* @M5A*/
  when rtype='0240' then call genc0240
  when rtype='0250' then call genc0250
  when rtype='0251' then call genc0251
  when rtype='0260' then call genc0260
  when rtype='0270' then call genc0270
  when rtype='0280' then call genc0280
  when rtype='0281' then call genc0281
  when rtype='0282' then call genc0282
  when rtype='0290' then call genc0290                     /*     @LCA*/
  when rtype='02A0' then call genc02A0                     /*     @LGA*/
  when rtype='02B0' then call genc02B0                     /*     @LJA*/
  when rtype='02C0' then call genc02C0                     /*     @LKA*/
  when rtype='02D0' then call genc02D0                     /*     @LRA*/
  when rtype='02E0' then call genc02E0                     /*     @LTA*/
  when rtype='02F0' then call genc02F0                     /*     @LZA*/
  when rtype='02G1' then call genc02G1                     /*     @M7A*/
  when rtype='0401' then call genc0401
  when rtype='0402' then call genc0402
  when rtype='0405' then call genc0405
  when rtype='0410' then call genc0410
  when rtype='0421' then call genc0421                     /*     @LIA*/
  when rtype='0501' then call genc0501
  when rtype='0502' then call genc0502
  when rtype='0503' then call genc0503
  when rtype='0507' then call genc0507
  when rtype='0508' then call genc0508                     /*     @LUA*/
  when rtype='0510' then call genc0510
  when rtype='0520' then call genc0520
  when rtype='0521' then call genc0521
  when rtype='0540' then call genc0540
  when rtype='0550' then call genc0550                     /*     @LDA*/
  when rtype='0560' then call genc0560                     /*     @LLA*/
  when rtype='0561' then call genc0561                     /*     @LLA*/
  when rtype='0562' then call genc0562                     /*     @LLA*/
  when rtype='0570' then call genc0570                     /*     @LIA*/
  when rtype='0571' then call genc0571                     /*     @LIA*/
  when rtype='0572' then call genc0572                     /*     @LIA*/
  when rtype='0573' then call genc0573                     /*     @LIA*/
  when rtype='0574' then call genc0574                     /*     @LIA*/
  when rtype='0580' then call genc0580                     /*     @LRA*/
  when rtype='0590' then call genc0590                     /*     @LTA*/
  when rtype='05A0' then call genc05A0                     /*     @LZA*/
  when rtype='05C0' then call genc05C0                     /*     @M4A*/
  when rtype='05D0' then call genc05D0                     /*     @M7A*/
  when rtype='05E0' then call genc05E0                     /*     @M7A*/
  otherwise do
    say '>>>Unexpected record reached gencmd: Count1 = ',
      count1'; Count2 = 'count2'; 'datarec
    bumprc = 1              /* indicate rc to be bumped by 4          */
    end
  end
 
return
 
/**********************************************************************/
/* Build commands for group basic data (0100):                        */
/*   For a define operation:                                          */
/*      (1) Build an ADDGROUP command to file OUTADDn, but specify a  */
/*          dummy owner and supgroup in case the real owner and       */
/*          supgroup haven't been defined yet.                        */
/*      (2) Build an ALTGROUP command to file OUTALTn to specify the  */
/*          real owner and supgroup.  File OUTALTn will be executed   */
/*          after file OUTALTn, so we know the real owner and supgroup*/
/*          will exist by the time that outalt1 is executed.          */
/*                                                                    */
/*   For an alter operation:                                          */
/*      (1) Build an ALTGROUP command to file OUTALTn.                */
/*                                                                    */
/*   For a delete operation:                                          */
/*      (1) Remember this group is deleted (use variable              */
/*          d.0.ofile.group_id)                                       */
/*          so that we won't build commands later that affect this    */
/*          group.                                                    */
/*      (2) Build a DELGROUP command to file OUTDELn.                 */
/*                                                                    */
/**********************************************************************/
genc0100:
parse var datarec 6 gpbd_name,             /* parse the data          */
   15 gpbd_supgrp_id,
   24 gpbd_create_date,                    /*                     @PYC*/
   35 gpbd_owner_id,
   44 gpbd_uacc,
   53 gpbd_notermuacc,
   58 gpbd_install_data,
  314 gpbd_model,
  359 gpbd_universal,
  363
 pull
 
gpbd_name = strip(gpbd_name)               /* remove blanks from name */
 
if type = 'define' then                    /* if operation is define  */
  if 0 = wordpos(gpbd_name,special_groups) then /* if not canned  @PMA*/
    cmd = 'addgroup'                       /* group build AG      @PMC*/
  else do                                  /* else treat as alter @PMA*/
    cmd = 'altgroup'                       /*   build ALG         @PMA*/
    type = 'alter'                         /*   force alter path  @PMA*/
    temp_univ = 'NO'                       /*   assume non-univ.  @PMA*/
    end
 
else if type = 'alter' then                /* if operation is alter   */
  cmd = 'altgroup'                         /*   build altgroup command*/
else do                                    /* if operation is delete  */
  cmd = 'delgroup'                         /*   build delgroup and    */
  d.0.ofile.gpbd_name = 1                       /* remember
                                                deleted group         */
  end
cmd = cmd gpbd_name                        /* add groupname to command*/
if type <> 'delete' then do
  if dummygbase <> '' &,                   /* if dummygroup avail @LMC*/
    type = 'define' then do                /* for define,             */
    dummygroup = setdumg(gpbd_name)        /* get proper dummy
                                              supgroup            @LMA*/
                                           /* then set supgrp and
                                              owner as dummy for  @LMC*/
    cmd = cmd 'supgroup('dummygroup')'     /* for now,  in case   @LMC*/
    cmd = cmd 'owner('dummygroup')'        /* real owner/grp      @LMC*/
    end                                    /* not defined yet         */
 
  else do                                  /* (alter or no dummygroup)*/
    if gpbd_name <> 'SYS1' then            /* no supgrp for SYS1  @PMA*/
      cmd = cmd 'supgroup('gpbd_supgrp_id')' /* add real supgrp and   */
    cmd = cmd 'owner('gpbd_owner_id')'     /* owner to the command    */
    end
  if gpbd_notermuacc = 'YES' then          /* for define or alter, add*/
    cmd = cmd 'notermuacc'                 /* notermuacc if needed    */
  else if type = 'alter' then              /* for alter, add termuacc */
    cmd = cmd '  termuacc'                 /* when needed.            */
  if gpbd_install_data <> ' ' then do      /* add installation data:  */
    cmd = cmd "data("dquote(strip(gpbd_install_data,'T'))")" /*
                                              quotes doubled,
                                              quoted and stripped of
                                              trailing blanks         */
    end
  else if type = 'alter' then              /* If alter, set nodata if */
    cmd = cmd 'nodata'                     /* needed                  */
  if gpbd_model <> ' ' then                /* if model exists,        */
    cmd = cmd 'model('strip(gpbd_model)')' /* add it, without quotes,
                                              and stripped of blanks  */
  else if type = 'alter' then              /* If alter, set nomodel if*/
    cmd = cmd 'nomodel'                    /* needed                  */
 
  if type = 'define' then do               /* if a define         @LSA*/
    if gpbd_universal = 'YES' then         /* if group is universal   */
      cmd = cmd 'universal'                /* say so              @LSA*/
    end                                    /*                     @LSA*/
  else if type = 'alter' then do           /* else for alter      @LSA*/
    if ofile = 1 then                      /* if first outfile    @LSA*/
      temp_univ = gpbd_universal           /* save universal flag @LSA*/
    else if ofile = 2 then do              /* else if 2nd outfile @LSA*/
      if gpbd_universal <> temp_univ then do /* ensure they match @LSA*/
        say '>>> Group 'gpbd_name' is UNIVERSAL',
            ' on one database but not on the other' /* warn user  @LSA*/
        bumprc = 1                         /* upgrade return code @LSA*/
        end                                /*                     @LSA*/
      end                                  /*                     @LSA*/
    end                                    /*                     @LSA*/
 
  end /* type not delete */
 
if type = 'define' then do                 /* For a define,           */
  call writeadd                            /*   write cmd to OUTADDn  */
  if dummygbase <> '' then do              /* Then, if dummygroup @LMA*/
    cmd = 'altgroup'                       /*   used, create altgrp   */
    cmd = cmd gpbd_name                    /*   command to set the    */
    cmd = cmd 'supgroup('gpbd_supgrp_id')' /*   right owner/supgrp    */
    cmd = cmd 'owner('gpbd_owner_id')'     /*   and write it to       */
    call writealt                          /*   OUTALTn               */
    end
  end
else if type = 'delete' then               /* For a delete,           */
  call writedel                            /*   write cmd to OUTDELn  */
else                                       /* For an alter,           */
  call writealt                            /*   write cmd to OUTALTn  */
 
if (ofile = 1) & (type <> 'alter') then    /* Missing group on one file
                                              or the other (only need
                                              to examine one for this
                                              case)?              @LNA*/
  g.gpbd_name = 'y'                        /* If so, record it    @LNA*/
 
return
 
/**********************************************************************/
/* Build commands for group subgroup data (0101):                     */
/*                                                                    */
/* If a subgroup's supgroup (parent) is being deleted, make           */
/* sure the parent doesn't have any subgroups so the delete           */
/* will succeed.                                                      */
/*                                                                    */
/* Build an altgroup command to specify a dummy                       */
/* supgroup for this subgroup.  Write the altgroup to the             */
/* OUTREMn file, so it will be processed before the                   */
/* deletion of parent group.  Also, if the subgroup does              */
/* still exist on the system, but with a different supgrp,            */
/* the commands in OUTALTn will fix the supgroup later.               */
/*                                                                    */
/* For other cases, nothing to do here.                               */
/*                                                                    */
/**********************************************************************/
genc0101:
parse var datarec 6 gpsgrp_name,
   15 gpsgrp_subgrp_id,
   23
 
gpsgrp_name = strip(gpsgrp_name) /* remove blanks from name           */
 
if type = 'delete',              /* if the group is being deleted     */
 & d.0.ofile.gpsgrp_name = 1 then do
  cmd = 'altgroup'               /* then alter its subgroup to have a */
  cmd = cmd gpsgrp_subgrp_id     /* dummy superior group              */
  dummygroup = setdumg(gpsgrp_name) /* generate proper dmy group  @LMA*/
  cmd = cmd 'supgroup('dummygroup')'                         /*   @LMC*/
  cmd = cmd 'owner('dummygroup')'/* and set owner to dmy grp, too @PEA*/
  call writerem                  /* put command on OUTREMn so it is   */
  end                            /* before the DELGROUP from OUTDELn  */
return
 
/**********************************************************************/
/* Build commands for group members data(0102):                       */
/*                                                                    */
/* If a user is being deleted from the group, build a REMOVE command. */
/* Otherwise, for adds and alters, build a CONNECT command.           */
/*                                                                    */
/* REMOVEs will be written to OUTREMn so they are done before the     */
/* group itself is (possibly) deleted by a DELGROUP in OUTDELn.       */
/* For a REMOVE, we will assign the group as the owner of any group-  */
/* dataset profiles.                                                  */
/* Also, for a REMOVE we will first CONNECT the user to the dummy     */
/* group and then use ALTUSER to make the dummy group the user's      */
/* dfltgrp, so the REMOVE is guaranteed to work. We also remember     */
/* we have done this so we only do it once, and so we can reset the   */
/* correct dfltgrp later (if possible).  All these commands go to     */
/* OUTREMn.                                                           */
/*                                                                    */
/* Note: We cannot build the CONNECT to the dummy group           @LMA*/
/*       if DBSYNC has been told not to                           @LMA*/
/*       perform dummy group processing.  In that case, the       @LMA*/
/*       REMOVE might fail, but so be it.                         @LMA*/
/*                                                                    */
/* Normal CONNECTs will be written to OUTALTn so we know              */
/* that the group will be defined by the time the CONNECT is done.    */
/*                                                                    */
/**********************************************************************/
genc0102:
parse var datarec 6 gpmem_name,
   15 gpmem_member_id,
   24 gpmem_auth,
   32
gpmem_member_id = strip(gpmem_member_id) /* remove blanks             */
if type = 'delete' then do       /* If deleting this entry:           */
  /********************************************************************
   * if we've already reset the user's default group, don't reset it  *
   * again                                                            *
   ********************************************************************/
  if (wordpos(gpmem_member_id,resetdflt.ofile) = 0),
   & dummygbase <> ''            /* if not reset yet and dummy group
                                    processing available          @LMA*/
   then do                       /* If not reset yet,                 */
    cmd = 'connect'              /* build connect cmd for user        */
    cmd = cmd gpmem_member_id    /* to connect to the                 */
    dummygroup = setdumu(gpmem_member_id) /* determine proper dummy
                                               group name         @LMA*/
    cmd = cmd 'group('dummygroup')' /* dummy group                    */
    call writerem                /* write it to OUTREMn               */
    cmd = 'altuser'              /* build altuser command:            */
    cmd = cmd gpmem_member_id    /*   add the userid                  */
    cmd = cmd 'dfltgrp('dummygroup')' /* add the dummy group          */
    call writerem                /* write it to OUTREMn               */
    resetdflt.ofile = resetdflt.ofile" "gpmem_member_id /*
                                    remember we reset this user       */
    cmd = 'remove'               /* Build command to remove user from
                                    dummy group                   @LMA*/
    cmd = cmd gpmem_member_id    /* add the user ID               @LMA*/
    cmd = cmd 'group('dummygroup')' /* and dummy group name       @LMA*/
    call writecln                /* write to OUTCLNn              @LMA*/
    end                          /* end "If not reset yet"            */
 
  cmd = 'remove'                 /* now build real remove cmd         */
  end                            /* end "If deleting this entry       */
else
  cmd = 'connect'
cmd = cmd gpmem_member_id
cmd = cmd 'group('gpmem_name')'
if type = 'delete' then
  cmd = cmd 'owner('gpmem_name')'
else
  cmd = cmd 'authority('gpmem_auth')'
if type = 'delete' then
  call writerem
else
  call writealt
return
 
/**********************************************************************/
/* Process group installation data data(0103) (USRxxx repeat fields)  */
/*                                                                    */
/* All that we can do here is warn the user running the exec that we  */
/* have encountered some data.  Since the RACF command processors do  */
/* not support administration of the USRxxx fields in the GROUP       */
/* profile we cannot build any commands.                              */
/*                                                                    */
/**********************************************************************/
genc0103:
/* parse group installation data data */
parse var datarec 6 gpinstd_name,
   15 gpinstd_usr_name,
   24 gpinstd_usr_data,
  280 gpinstd_usr_flag,
  288
 
gpinstd_usr_name = strip(gpinstd_usr_name) /* remove blanks from name
                                                                      */
if type = 'delete',              /* if the group is being deleted     */
 & d.0.ofile.gpinstd_name = 1 then nop      /* do nothing         @PZC*/
else do                          /* else issue msg                    */
  say '****' type 'Group' gpinstd_name 'contains user-data: Name= ',
    gpinstd_usr_name 'Flag=' gpinstd_usr_flag 'Data= ',
    strip(gpinstd_usr_data)
  bumprc = 1                     /* indicate return code to be bumped */
  end                            /* end "else issue msg"              */
return
 
/**********************************************************************/
/* Process group DFP data (0110):                                     */
/*                                                                    */
/* Build commands for handling the DFP segment in a group profile.    */
/* If the entire group is being deleted we won't generate anything.   */
/* Otherwise, we will build an ALTGROUP command on OUTALTn to add,    */
/* delete, or modify the DFP segment information for the group.       */
/*                                                                    */
/**********************************************************************/
genc0110:
parse var datarec 6 gpdfp_name,
   15 gpdfp_dataappl,
   24 gpdfp_dataclas,
   33 gpdfp_mgmtclas,
   42 gpdfp_storclas,
   50
 
gpdfp_name = strip(gpdfp_name) /* remove blanks from name         */
 
cmd = 'altgroup'
cmd = cmd gpdfp_name
if type = 'delete' then do  /* if a delete is needed,             */
  if d.0.ofile.gpdfp_name = 1 then return       /* if
                               group being deleted, do nothing    */
  else
    cmd = cmd 'nodfp'       /* else just delete DFP segment       */
  end                       /* end "if type = delete"             */
else do                     /* else not a delete (add or alter    */
  cmd = cmd '  dfp'         /* insert DFP keyword                 */
  if type = 'alter',        /* if doing an alter, or if data is   */
   | substr(datarec,15) <> ' ' then do /* present, need to use it */
    cmd = cmd'('            /* so add a ( after the DFP keyword   */
    if gpdfp_dataappl <> ' ' then            /* If dataappl data  */
      cmd = cmd 'dataappl('gpdfp_dataappl')' /* add it to command */
    else if type = 'alter' then    /* else if alter               */
      cmd = cmd 'nodataappl'       /* add nodataappl to command   */
    if gpdfp_dataclas <> ' ' then            /* If dataclas data  */
      cmd = cmd 'dataclas('gpdfp_dataclas')' /* add it to command */
    else if type = 'alter' then    /* else if alter               */
      cmd = cmd 'nodataclas'       /* add nodataclas to command   */
    if gpdfp_mgmtclas <> ' ' then            /* If mgmtclas data  */
      cmd = cmd 'mgmtclas('gpdfp_mgmtclas')' /* add it to command */
    else if type = 'alter' then    /* else if alter               */
      cmd = cmd 'nomgmtclas'       /* add nomgmtclas to command   */
    if gpdfp_storclas <> ' ' then            /* If storclas data  */
      cmd = cmd 'storclas('gpdfp_storclas')' /* add it to command */
    else if type = 'alter' then    /* else if alter               */
      cmd = cmd 'nostorclas'       /* add nostorclas to command   */
    cmd = cmd')'            /* add ending ) after DFP data        */
    end /* dfp data present */
  end /* end not a delete */
call writealt               /* write command to OUTALTn           */
return
 
/**********************************************************************/
/* Process group OMVS data (0120):                                    */
/*                                                                    */
/* Build commands for handling the OMVS segment in a group profile.   */
/* If the entire group is being deleted we won't generate anything.   */
/* Otherwise, we will build an ALTGROUP command on OUTALTn to add,    */
/* delete, or modify the OMVS segment information for the group.      */
/*                                                                    */
/**********************************************************************/
genc0120:
 
omvsovm = 'omvs'
call gomvsovm
return
 
/**********************************************************************/
/* Process group OVM data (0130):                                     */
/*                                                                    */
/* Build commands for handling the OVM  segment in a group profile.   */
/* If the entire group is being deleted we won't generate anything.   */
/* Otherwise, we will build an ALTGROUP command on OUTALTn to add,    */
/* delete, or modify the OMVS segment information for the group.      */
/*                                                                    */
/**********************************************************************/
genc0130:
 
omvsovm = 'ovm'
call gomvsovm
return
 
/**********************************************************************/
/* Build data for 0120/0130 (group OMVS/OVM)                          */
/*                                                                    */
/* Build commands for handling the OMVS/OVM segment in group profile. */
/* If the entire group is being deleted we won't generate anything.   */
/* Otherwise, we will build an ALTGROUP command on OUTALTn to add,    */
/* delete, or modify the OMVS segment information for the group.      */
/*                                                                    */
/**********************************************************************/
gomvsovm:
parse var datarec 6 gpomvs_name,
   15 gpomvs_gid,
   25
 
gpomvs_name = strip(gpomvs_name) /* remove blanks from name         */
 
cmd = 'altgroup'
cmd = cmd gpomvs_name
if type = 'delete' then do  /* if a delete is needed,               */
  if d.0.ofile.gpomvs_name = 1 then return      /* if
                               group being deleted, do nothing      */
  else
    cmd = cmd 'no'omvsovm   /* else just delete segment             */
  end
else do                     /* else not a delete (add or alter      */
  cmd = cmd '  'omvsovm     /* insert segment keyword               */
  if type = 'alter',        /* if doing an alter, or if data is     */
   | substr(datarec,15) <> ' ' then do /* present, need to use it   */
    cmd = cmd'('            /* so add a ( after the segmentkeyword  */
    if gpomvs_gid <> ' ' then                /* If gid present    */
      cmd = cmd 'gid('gpomvs_gid')'/* add it to command           */
    else if type = 'alter' then    /* else if alter               */
      cmd = cmd 'nogid'            /* add nogid to command        */
    cmd = cmd')'            /* add ending ) after OMVS data       */
    end /* omvs data present */
  end /* end not a delete */
call writealt               /* write command to OUTALTn           */
return
 
/**********************************************************************/
/* Build commands for group TME role data (0141):                     */
/*                                                                    */
/* If the group is being deleted do nothing.                          */
/*                                                                    */
/* Otherwise, build an ALTGROUP command to specify ADDROLE or         */
/* DELROLE for the TME role associated with this record and write     */
/* it to file OUTALTn.                                                */
/*                                                                    */
/* Generate the command as a comment since roles should be            */
/* administered via TME, not via RACF commands                        */
/*                                                                    */
/**********************************************************************/
genc0141:
parse var datarec 6 gptme_name,            /* parse the data          */
   15 gptme_role,
   261
 
gptme_name = strip(gptme_name)             /* remove blanks from name */
gptme_role = strip(gptme_role)             /* and from role name      */
 
cmd = 'altgroup'                           /* start altgroup command  */
cmd = cmd gptme_name                       /* add group name          */
if type = 'delete' then do                 /* if delete               */
  if d.0.ofile.gptme_name = 1 then         /* if group being          */
      return                               /*   deleted do nothing    */
  cmd = cmd 'tme(delroles('gptme_role'))'  /* else use DELROLES   @Q5C*/
  end                                      /* End if delete           */
else                                       /* Else add/alter          */
  cmd = cmd 'tme(addroles('gptme_role'))'  /* use ADDROLES        @Q5C*/
 
cmd = '/' || '*' cmd '*' || '/'            /* make it a comment       */
 
call writealt                              /* write to OUTALTn        */
return
 
/**********************************************************************/
/* Process group CSDATA data (0151):                                  */
/*                                                                    */
/* Build commands for handling the CSDATA segment in a group profile. */
/* If the entire group is being deleted we won't generate anything.   */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add or   */
/* modify the CSDATA segment information for the user.                */
/*                                                                    */
/* note: can't delete entire csdata segment, as IRRDBU00 does not     */
/*       produce a type 0150 record, and thus we don't have a way to  */
/*       tell that one group has a csdata segment and another doesn't. */
/*       We can only tell about individual fields in csdata.           */
 
/*                                                                    */
/*                                         Entire routine added   @M7A*/
/**********************************************************************/
genc0151:
parse var datarec 6 gpcsd_name,             /* parse the data          */
   15 gpcsd_type,
   20 gpcsd_key,
   53 gpcsd_value,
 1153
 
gpcsd_name = strip(gpcsd_name)             /* remove blanks from name */
gpcsd_key = strip(gpcsd_key)               /* and key and trailing    */
gpcsd_value = strip(gpcsd_value,'T')       /* blanks from value       */
/* Question: can we tell if the value should have trailing blanks?    */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd gpcsd_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.gpcsd_name = 1 then
    return                                 /* leave if user deleted   */
  end                                      /* end if delete           */
 
cmd = cmd 'csdata( '                       /* add/alter csdata        */
 
if gpcsd_value <> ' ' then do              /* append the key and value*/
  cmd = cmd gpcsd_key"("
 
  if gpcsd_type = "NUM " then              /* for numeric values,     */
     gpcsd_value = strip(substr(gpcsd_value,1,9),'L','0') /* strip
                                              leading zeroes but leave
                                              at least one (total
                                              field is 10 digits)     */
 
  else if gpcsd_type = "CHAR" then         /* for char data, double   */
     gpcsd_value = dquote(gpcsd_value) /* any quote and quote it*/
 
  cmd = cmd gpcsd_value
 
  cmd = cmd")"
  end
 
else do
  cmd = cmd "no"gpcsd_key                  /* or negate the key       */
  end
 
cmd = cmd ")"                              /* add ) to end data       */
 
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Build commands for user basic data (0200):                         */
/*   For a define operation:                                          */
/*      (1) Build an ADDUSER command to file OUTADDn, but specify a   */
/*          dummy owner and dfltgrp in case the real owner and        */
/*          dfltgrp haven't been defined yet.                         */
/*      (2) Build an ALTUSER command to file OUTALTn to specify the   */
/*          real owner and dfltgrp. Also REVOKE, UAUDIT, and revoke/  */
/*          resume dates.  File OUTALTn will be executed              */
/*          after file OUTADDn, so we know the real owner and dfltgrp */
/*          will exist by the time that outalt1 is executed.          */
/*                                                                    */
/*   For an alter operation:                                          */
/*      (1) Build an ALTUSER command to file OUTALTn.                 */
/*                                                                    */
/*   For a delete operation:                                          */
/*      (1) Remember this user is deleted (use variable               */
/*          d.1.ofile.user_id)                                        */
/*          so that we won't build commands later that affect this    */
/*          group.                                                    */
/*      (2) Build a DELUSER command to file OUTDELn.                  */
/*                                                                    */
/**********************************************************************/
genc0200:
parse var datarec 6 usbd_name,             /* Parse the data          */
  15 usbd_create_date,
  26 usbd_owner_id,
  35 usbd_adsp,
  40 usbd_special,
  45 usbd_oper,
  50 usbd_revoke,
  55 usbd_grpacc,
  60 usbd_pwd_interval,
  64 usbd_pwd_date,
  75 usbd_programmer,
  96 usbd_defgrp_id,
 105 usbd_lastjob_time,
 114 usbd_lastjob_date,
 125 usbd_install_data,
 380
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 381 usbd_uaudit,
 386 usbd_auditor,
 391 usbd_nopwd,
 396 usbd_oidcard,
 401 usbd_pwd_gen,
 405 usbd_revoke_cnt,
 409 usbd_model,
 454 usbd_seclevel,
 458 usbd_revoke_date,
 469 usbd_resume_date,
 480 usbd_access_sun,
 485 usbd_access_mon,
 490 usbd_access_tue,
 495 usbd_access_wed,
 499
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 500 usbd_access_thu,
 505 usbd_access_fri,
 510 usbd_access_sat,
 515 usbd_start_time,
 524 usbd_end_time,
 533 usbd_seclabel,
 542 usbd_attribs,
 551 usbd_pwdenv_exists,                   /*                     @Q4A*/
 556 usbd_pwd_asis,                        /*                     @Q4A*/
 561 usbd_phr_date,                        /*                     @Q6A*/
 572 usbd_phr_gen,                         /*                     @Q6A*/
 576 usbd_cert_seqn,                       /*                     @Q6A*/
 587 usbd_pphenv_exists,                   /*                     @Q6A*/
 592 external_seclevel,                    /*                     @Q7C*/
 631
 
usbd_name = strip(usbd_name)               /* remove blanks from name */
 
if (ofile = 1) & (type <> 'alter') then do /* possible group vs user
                                              mismatch?           @LNA*/
  if g.usbd_name = 'y' then do             /* if name is group on one
                                              but user on other   @LNA*/
    say '>>>Cannot synchronize: 'usbd_name,/* issue warning msg   @LNA*/
        ' is a user on one database but a group on the other.' /* @LNA*/
    bumprc = 1                             /* upgrade return code @LNA*/
    end
  end                                      /*                     @LNA*/
 
 
 
if type = 'define' then                    /* If operation is define  */
  if usbd_name <> 'IBMUSER' then           /* if not IBMUSER      @PMA*/
    cmd = 'adduser'                        /*   build adduser command */
  else do                                  /* else treat as alter @PMA*/
    cmd = 'altuser'                        /*   build altuser     @PMA*/
    type = 'alter'                         /*   force alter path  @PMA*/
    end                                    /*                     @PMA*/
else if type = 'alter' then                /* If operation is alter   */
  cmd = 'altuser'                          /*   build altuser command */
else do                                    /* If operation is delete  */
  cmd = 'deluser'                          /*   build deluser command */
  d.1.ofile.usbd_name = 1
  end
cmd = cmd usbd_name                        /* add userid to command   */
if type <> 'delete' then do
  if type = 'define' then do               /* for define:             */
 
    if dummygbase <> '' then               /* if dummygroup avail @LMC*/
      cmd = cmd 'owner('dummygbase'0)'     /* Set dummy owner and @LMC*/
                                           /*                    4@LMD*/
    else                                   /* else no dummygroup, @LMC*/
      cmd = cmd 'owner('usbd_owner_id')'   /* add real owner      @LMC*/
                                           /*                    2@LMD*/
    end                                    /* end "for define"        */
 
  else                                     /* else for alter      @LMC*/
    cmd = cmd 'owner('usbd_owner_id')'     /*   add real owner    @LMC*/
 
  if usbd_nopwd='PRO' then                 /* if protected user   @LPA*/
      cmd = cmd 'nopassword'               /* say so              @LPA*/
  else if type = 'define' then             /* else for a define   @LPA*/
    cmd = cmd '/*password(????????)*/'     /* can't provide password,
                                              so put in a placeholder
                                              to simplify manual
                                              editing of commands @LPM*/
  if usbd_nopwd='PHR' then                 /* note existence of   @M7A*/
    cmd = cmd '/*phrase(??????????????)*/' /* phrase if present   @M7A*/
 
  cmd = cmd 'dfltgrp('usbd_defgrp_id')'    /* add real dfltgrp as it
                                              must exist by now since
                                              we've processed all
                                              01xx records        @LMC*/
 
  if usbd_adsp = 'YES' then                /* for define or alter, add*/
    cmd = cmd '  adsp'                     /* adsp if needed          */
  else if type = 'alter' then              /* for alter, add noadsp   */
    cmd = cmd 'noadsp'                     /* when needed.            */
 
  if usbd_special = 'YES' then             /* for define or alter, add*/
    cmd = cmd '  special'                  /* special if needed       */
  else if type = 'alter' then              /* for alter, add nospecial*/
    cmd = cmd 'nospecial'                  /* when needed.            */
 
  if usbd_oper = 'YES' then                /* for define or alter, add*/
    cmd = cmd '  operations'               /* operations if needed    */
  else if type = 'alter' then              /* for alter, add nooper...*/
    cmd = cmd 'nooperations'               /* when needed.            */
 
  if usbd_grpacc = 'YES' then              /* for define or alter, add*/
    cmd = cmd '  grpacc'                   /* grpacc if needed        */
  else if type = 'alter' then              /* for alter, add nogrpacc */
    cmd = cmd 'nogrpacc'                   /* when needed.            */
 
  /* Process interval in a separate PASSWORD command later        @P7C*/
 
                                           /* Add programmer name:    */
  cmd = cmd "name("dquote(strip(usbd_programmer,'T'))")" /* add the
                                              name, quotes doubled, in
                                              quotes and stripped of
                                              trailing blanks         */
 
  if usbd_install_data <> ' ' then do      /* add installation data:  */
    cmd = cmd "data("dquote(strip(usbd_install_data,'T'))")" /*
                                              add data, quotes doubled,
                                              quoted and stripped of
                                              trailing blanks         */
    end
  else if type = 'alter' then              /* If alter set nodata if  */
    cmd = cmd 'nodata'                     /* needed                  */
 
                                           /* For define we must do   */
                                           /* UAUDIT later.           */
  if type = 'alter' then do                /* for alter, add uaudit   */
    if usbd_uaudit = 'YES' then            /* or nouaudit as needed   */
      cmd = cmd 'uaudit'
    else
      cmd = cmd 'nouaudit'
    end
 
  if usbd_auditor = 'YES' then             /* for define or alter, add*/
    cmd = cmd '  auditor'                  /* auditor if needed       */
  else if type = 'alter' then              /* for alter, add noauditor*/
    cmd = cmd 'noauditor'                  /* when needed.            */
 
  if usbd_model <> ' ' then                /* for define or alter, add*/
    cmd = cmd 'model('strip(usbd_model)')' /* model, no quotes/blanks */
  else if type = 'alter' then              /* for alter, add nomodel  */
    cmd = cmd 'nomodel'                    /* when needed.            */
 
 
  if strip(usbd_attribs) = 'RSTD' then     /* if restricted then  @PQC*/
      cmd = cmd 'restricted'               /* say so              @LOA*/
    else if type = 'alter' then            /* else if alter       @PQC*/
      cmd = cmd norstd                     /*   say not           @PQC*/
 
 
  if type = 'alter',                       /* for alter delete    @PGC*/
    & external_seclevel = '*none' then     /* seclevel when needed    */
    cmd = cmd 'noseclevel'
 
                                           /* For define we must do   */
                                           /* revoke and resume dates */
                                           /* later                   */
                                           /* But for an alter,   @Q5A*/
  if type = 'alter' then do                /* handle them now     @Q5C*/
 
      rev_cmd = 'altuser' usbd_name        /* setup a basic altuser   */
      rev_revoke = usbd_revoke             /* get revoke flag         */
      if usbd_revoke_date <> ' ' then      /* get revoke date if any  */
        rev_revdate = ,
          substr(usbd_revoke_date,1,4)||,                     /*  @PIC*/
          substr(usbd_revoke_date,6,2)||,                     /*  @PIC*/
          substr(usbd_revoke_date,9,2)                        /*  @PIC*/
      else rev_revdate = ' '               /* else set it to blank    */
      if usbd_resume_date <> ' ' then      /* get resume date if any  */
        rev_resdate = ,
          substr(usbd_resume_date,1,4)||,                     /*  @PIC*/
          substr(usbd_resume_date,6,2)||,                     /*  @PIC*/
          substr(usbd_resume_date,9,2)                        /*  @PIC*/
      else rev_resdate = ' '               /* else set it to blank    */
      call gen_revoke                      /* and call gen_revoke to  */
      end                                  /* generate needed info    */
 
  if pos('NO',substr(datarec,480,34)) > 0, /* if day or time          */
   | substr(datarec,515,17) <> ' ' then do /* restrictions exist      */
   cmd = cmd 'when('                       /* Add WHEN to the command */
     if pos('NO',substr(datarec,480,34)) > 0 then do /* if days are   */
       cmd = cmd'days('                    /* restricted add each day
                                              that is allowed         */
       if usbd_access_sun = 'YES' then cmd = cmd 'sunday'
       if usbd_access_mon = 'YES' then cmd = cmd 'monday'
       if usbd_access_tue = 'YES' then cmd = cmd 'tuesday'
       if usbd_access_wed = 'YES' then cmd = cmd 'wednesday'
       if usbd_access_thu = 'YES' then cmd = cmd 'thursday'
       if usbd_access_fri = 'YES' then cmd = cmd 'friday'
       if usbd_access_sat = 'YES' then cmd = cmd 'saturday'
       cmd = cmd') '                       /* add trailing ) to days  */
       end                                 /* end "if days restricted"*/
     else if type = 'alter' then           /* for alter, set anyday if*/
       cmd = cmd 'days(anyday)'            /* no days are restricted  */
     if substr(datarec,515,17) <> ' ' then do /* if times restricted  */
       cmd = cmd'time('                    /* add time and values     */
       cmd = cmd||substr(usbd_start_time,1,2)||,
             substr(usbd_start_time,4,2)":"||,
             substr(usbd_end_time,1,2)||,
             substr(usbd_end_time,4,2)
       cmd = cmd')'                        /* add trailing ) to time  */
       end                                 /* end "if times restricted*/
     else if type = 'alter' then           /* for alter, set anytime  */
       cmd = cmd 'time(anytime)'           /* if no time restriction  */
     cmd = cmd')'
     end                                   /* end if day/time rest... */
  else if type = 'alter' then              /* for alter, if no day or
                                              time restrictions, set
                                              anyday/anytime          */
    cmd = cmd 'when(days(anyday) time(anytime))'
 
  if type = 'alter',
   & usbd_seclabel = ' ' then              /* for alter add noseclabel*/
    cmd = cmd 'noseclabel'                 /* when needed.            */
 
  end                                      /* end "type not delete"   */
 
if type = 'define' then                    /* For define, write cmd to*/
  call writeadd                            /* the add file            */
else if type = 'delete' then do            /* For delete, write cmd to*/
  call writedel                            /* the delete file.        */
  /* removed code to add user to dummygroup, as we don't need     @P8D*/
  /* to do that when deleting the user                            @P8D*/
  end                            /* end "type = delete"               */
else
  call writealt                            /* else write to alter file*/
 
/**********************************************************************/
/* When defining a user, use ALTUSER for UAUDIT, REVOKE, revoke dates,*/
/* resume dates, and OWNER                                        @LMC*/
/* Also for adding a seclevel or seclabel                         @PGA*/
/* This special processing is needed because:                         */
/*   (a) ADDUSER can't specify UAUDIT or REVOKE;                      */
/*   (b) OWNER must be setup as DUMMY in the add file to          @LMC*/
/*       ensure that the OWNER will have been defined             @LMC*/
/*       before they are referenced.                                  */
/*   (c) seclevel and seclabel names have not been defined yet    @PGA*/
/**********************************************************************/
if type = 'define',                        /* If define and altuser   */
  &(dummygbase <> '',                      /* is needed...        @LMA*/
    | usbd_uaudit = 'YES',
    | usbd_revoke = 'YES',
    | usbd_revoke_date <> ' ',
    | (external_seclevel <> '',            /*                     @PGA*/
       & external_seclevel <> '*none'),                        /* @PGA*/
    | usbd_seclabel <> ' ',                /*                     @PGA*/
    | usbd_resume_date <> ' ') then do
  cmd = 'altuser'                          /*  setup ALTUSER with     */
  cmd = cmd usbd_name                      /*  userid                 */
  if dummygbase <> '' then                 /* if dummygroup avail @LMc*/
    cmd = cmd 'owner('usbd_owner_id')'     /*  real owner             */
                                           /*                    1@LMD*/
  if usbd_uaudit = 'YES' then              /*  UAUDIT if needed       */
    cmd = cmd 'uaudit'
 
  if external_seclevel <> '',              /*  Seclevel?          @PGA*/
   & external_seclevel <> '*none' then
     cmd = cmd 'seclevel('strip(external_seclevel)')'
 
   say "line2921" usbd_seclabel
   if usbd_seclabel <> ' ' then            /* if seclabel info    @PGA*/
    cmd = cmd 'seclabel('usbd_seclabel')'  /* then add it         @PGA*/
 
  if usbd_revoke = 'YES',                  /* If revoke or one of the */
    |usbd_revoke_date <> ' ',              /* revoke/resume dates is  */
    |usbd_resume_date <> ' ' then do       /* set then:               */
 
      rev_cmd = 'altuser' usbd_name        /* setup a basic altuser   */
      rev_revoke = usbd_revoke             /* get revoke flag         */
      if usbd_revoke_date <> ' ' then      /* get revoke date if any  */
        rev_revdate = ,
          substr(usbd_revoke_date,1,4)||,              /*         @PIC*/
          substr(usbd_revoke_date,6,2)||,              /*         @PIC*/
          substr(usbd_revoke_date,9,2)                 /*         @PIC*/
      else rev_revdate = ' '               /* else set it to blank    */
      if usbd_resume_date <> ' ' then      /* get resume date if any  */
        rev_resdate = ,
          substr(usbd_resume_date,1,4)||,              /*         @PIC*/
          substr(usbd_resume_date,6,2)||,              /*         @PIC*/
          substr(usbd_resume_date,9,2)                 /*         @PIC*/
      else rev_resdate = ' '               /* else set it to blank    */
      call gen_revoke                      /* and call gen_revoke to  */
      end                                  /* end "if revoke or one"  */
 
  call writealt                            /* write to alter file     */
                                           /*                    7@LMD*/
  end                                      /* End "If define and alt" */
 
 
/**********************************************************************/
/* When defining or altering a user, use PASSWORD for the         @P7C*/
/* password interval.                                             @P7C*/
/**********************************************************************/
if type = 'define' | type = 'alter'        /* If define or alter      */
  then do
  cmd = 'password'                         /*  setup PASSWORD cmd @P7C*/
  cmd = cmd 'user('usbd_name')'            /*  userid             @P7C*/
  if usbd_pwd_interval > 0 then            /* nonzero interval?   @PBA*/
    cmd = cmd 'interval('usbd_pwd_interval')'/*  add the interval     */
  else                                     /* no: use NOINTERVAL  @PBA*/
    cmd = cmd 'nointerval'                 /*                     @PBA*/
  if type = 'define' then                  /*  if a define,           */
    call writeadd                          /*  write to add file      */
  else                                     /*  else for an alter      */
    call writealt                          /*  use the alter file     */
  end                                      /* End "If define or alter
                                                                      */
return
 
/**********************************************************************/
/* Build commands for user category data (0201):                      */
/*                                                                    */
/* If the user is being deleted do nothing.                           */
/*                                                                    */
/* Otherwise, build an ALTUSER command to specify ADDCATEGORY or      */
/* DELCATEGORY for the category associated with this record and write */
/* it to file OUTALTn.                                                */
/*                                                                    */
/**********************************************************************/
genc0201:
parse var datarec 6 uscat_name,            /* parse the data          */
   15 external_category,
   54
 
uscat_name = strip(uscat_name)             /* remove blanks from name */
external_category = strip(external_category) /* and from category     */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uscat_name                       /* add userid              */
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uscat_name = 1 then              /* if user being      */
      return                               /*   deleted do nothing    */
  cmd = cmd 'delcategory('external_category')' /* else use DELCAT     */
  end                                      /* End if delete           */
else                                       /* Else add/alter          */
  cmd = cmd 'addcategory('external_category')' /* use ADDCAT          */
call writealt                              /* write to OUTALTn        */
return
 
/**********************************************************************/
/* Build commands for user classes data (0202):                       */
/*                                                                    */
/* If the user is being deleted do nothing.                           */
/*                                                                    */
/* Otherwise, build an ALTUSER command to specify CLAUTH or NOCLAUTH  */
/* for the class associated with this record. Write the command to    */
/* file OUTALTn.                                                      */
/*                                                                    */
/**********************************************************************/
genc0202:
parse var datarec 6 uscla_name,            /* parse the data          */
   15 uscla_class,
   23
 
uscla_name = strip(uscla_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uscla_name                       /* add userid              */
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uscla_name = 1 then              /* if user being      */
      return                               /*   deleted do nothing    */
  cmd = cmd 'noclauth('uscla_class')'      /*   else use NOCLAUTH     */
  end                                      /* End if delete           */
else                                       /* Else add/alter          */
  cmd = cmd 'clauth('uscla_class')'        /* so use CLAUTH           */
call writealt                              /* write to OUTALTn        */
return
 
/**********************************************************************/
/* Build commands for user installation-data data (0204):             */
/*                                                                    */
/* We cannot handle this one, so just write a message                 */
/*                                                                    */
/**********************************************************************/
genc0204:
parse var datarec 6 usinstd_name,          /* parse the data          */
   15 usinstd_usr_name,
   24 usinstd_usr_data,
  280 usinstd_usr_flag,
  288
 
usinstd_usr_name = strip(usinstd_usr_name) /* remove blanks from name
                                                                      */
if type = 'delete',              /* if the user is being deleted      */
 & d.1.ofile.usinstd_name = 1 then nop      /* do nothing         @PZC*/
else do                          /* else issue msg                    */
  say '****' type 'User' usinstd_name 'contains user-data: Name= ',
    usinstd_usr_name 'Flag=' usinstd_usr_flag 'Data= ',
    strip(usinstd_usr_data)
  bumprc = 1                     /* indicate return code to be bumped */
  end                            /* end "else issue msg"              */
return
 
/**********************************************************************/
/* Build commands for user connect data (0205):                       */
/*                                                                    */
/* For a delete do nothing.  We will already have processed this      */
/* connection when processing group member data above.                */
/*                                                                    */
/* Otherwise, build a  CONNECT command to specify specify the rest of */
/* the user's connect-related information. Write the command to       */
/* file OUTALTn.                                                      */
/*                                                                    */
/* Since OUTADDn is processed before OUTALTN any necessary groups and */
/* users for OWNER, connect-group, etc.will already be defined.       */
/**********************************************************************/
genc0205:
parse var datarec 6 uscon_name,            /* parse the data          */
   15 uscon_grp_id,
   24 uscon_connect_date,
   35 uscon_owner_id,
   44 uscon_lastcon_time,
   53 uscon_lastcon_date,
   64 uscon_uacc,
   73 uscon_init_cnt,
   79 uscon_grp_adsp,
   84 uscon_grp_special,
   89 uscon_grp_oper,
   94 uscon_revoke,
   99 uscon_grp_acc,
  104 uscon_notermuacc,
  109 uscon_grp_audit,
  114 uscon_revoke_date,
  125 uscon_resume_date,
  135
if type <> 'delete' then do                /* if not a delete         */
  cmd = 'connect'                          /* start CONNECT command   */
  cmd = cmd uscon_name                     /* add userid              */
  cmd = cmd 'group('uscon_grp_id')'        /*   groupid               */
  cmd = cmd 'owner('uscon_owner_id')'      /*   owner                 */
  cmd = cmd 'uacc('uscon_uacc')'           /*   uacc                  */
 
  if uscon_grp_adsp = 'YES' then           /*   ADSP if needed        */
    cmd = cmd 'adsp'
  else if type = 'alter' then              /*   NOADSP if needed and  */
    cmd = cmd 'noadsp'                     /*   this is an alter      */
 
  if uscon_grp_special = 'YES' then        /*   SPECIAL if needed     */
    cmd = cmd 'special'
  else if type = 'alter' then              /*   NOSPECIAL if needed & */
    cmd = cmd 'nospecial'                  /*   this is an alter      */
 
  if uscon_grp_oper = 'YES' then           /*   OPERATIONS if needed  */
    cmd = cmd 'operations'
  else if type = 'alter' then              /*   NOOPERATIONS if needed*/
    cmd = cmd 'nooperations'               /*   and this is an alter  */
 
  if uscon_grp_acc  = 'YES' then           /*   GRPACC if needed      */
    cmd = cmd 'grpacc'
  else if type = 'alter' then              /*   NOGRPACC if needed and*/
    cmd = cmd 'nogrpacc'                   /*   this is an alter      */
 
  if uscon_grp_audit = 'YES' then          /*   AUDITOR if needed     */
    cmd = cmd 'auditor'
  else if type = 'alter' then              /*   NOAUDITOR if needed   */
    cmd = cmd 'noauditor'                  /*   and this is an alter  */
 
  if type = 'alter',                       /* if an alter, or if  @Q5A*/
    | (uscon_revoke = 'YES',               /* a define then do    @Q5C*/
    |uscon_revoke_date <> ' ',             /* revoke/resume       @Q5C*/
    |uscon_resume_date <> ' ' ) then do    /* set then:           @Q5C*/
 
      rev_cmd = 'connect' uscon_name       /* setup a basic connect   */
      rev_cmd = rev_cmd 'group('uscon_grp_id')'
      rev_revoke = uscon_revoke            /* get revoke flag         */
      if uscon_revoke_date <> ' ' then     /* get revoke date if any  */
        rev_revdate = ,
          substr(uscon_revoke_date,1,4)||,                 /*     @PIC*/
          substr(uscon_revoke_date,6,2)||,                 /*     @PIC*/
          substr(uscon_revoke_date,9,2)                    /*     @PIC*/
      else rev_revdate = ' '               /* else set it to blank    */
      if uscon_resume_date <> ' ' then     /* now do resume date  @PIC*/
        rev_resdate = ,
          substr(uscon_resume_date,1,4)||,                 /*     @PIC*/
          substr(uscon_resume_date,6,2)||,                 /*     @PIC*/
          substr(uscon_resume_date,9,2)                    /*     @PIC*/
      else rev_resdate = ' '               /* else set it to blank    */
      call gen_revoke                      /* and call gen_revoke to  */
      end                                  /* generate needed info    */
 
  call writealt                            /* write the record        */
  end                                      /* End type not delete     */
return
 
/**********************************************************************/
/* Process user associations (0206):                                  */
/*                                                                    */
/* Build commands for handling the user associations in a user        */
/* profile, as much as possible.  We cannot process the fields that   */
/* indicate whether the association is pending, nor the timestamps,   */
/* nor the system error flag,                                         */
/* nor the user who created the entry.  For other differences we      */
/* will build RACLINK commands on OUTALTn to define or                */
/* modify (via UNDEFINE/DEFINE) associations for the user. We will    */
/* build RACLINK commands on OUTREMn to undefine associations, as     */
/* the undefines must be done before DELUSER commands on OUTDELn can  */
/* be done.                                                           */
/*                                                                    */
/**********************************************************************/
genc0206:
parse var datarec 6 usrsf_name,            /* parse the data          */
   15 usrsf_targ_node,
   24 usrsf_targ_user_id,
   33 usrsf_version,
   37 usrsf_peer,
   42 usrsf_managing,
   47 usrsf_managed,
   52 usrsf_remote_pend,
   57 usrsf_local_pend,
   62 usrsf_pwd_sync,
   67 usrsf_rem_refusal,                    /*                    @Q5C*/
   72 usrsf_define_date,
   83 usrsf_define_time,
   99 usrsf_accept_date,
  110 usrsf_accept_time,                    /*                   2@Q5D*/
  126 usrsf_creator_id,
  134                                       /*                    @Q5C*/
 
usrsf_name = strip(usrsf_name)             /* strip blanks from some  */
usrsf_targ_node = strip(usrsf_targ_node)   /* names                   */
usrsf_targ_user_id = strip(usrsf_targ_user_id)
 
 
if type = 'delete' then do                 /* if delete               */
  call genc0206_undefine                   /*  go undefine this one   */
  end                                      /* end "if delete"         */
else if type = 'define' then               /* if define,              */
  call genc0206_define                     /* go define this one      */
else do                                    /* else if alter,          */
  call genc0206_undefine                   /* undefine old one then   */
  call genc0206_define                     /* define the new one      */
  end                                      /* end "if alter"          */
 
return                                     /* return to caller        */
 
 
genc0206_undefine:                         /* Undefine an association:*/
  cmd = 'RACLINK'                          /*   start RACLINK command */
  cmd = cmd 'id('usrsf_name')'             /*   add id(userid)        */
  cmd = cmd 'undefine('                    /*   add undefine keyword  */
  cmd = cmd usrsf_targ_node                /*   add the node id       */
  cmd = cmd'.'usrsf_targ_user_id')'        /*   add .userid)          */
  if type = 'delete' then                  /*   for deletes, write to */
    call writerem                          /*   OUTREMn.              */
  else                                     /*   else write to         */
    call writealt                          /*   OUTALTn.              */
  return                                   /*   return to genc0206    */
 
genc0206_define:                           /* Define an association:  */
  cmd = 'RACLINK'                          /*   start RACLINK command */
  cmd = cmd 'id('usrsf_name')'             /*   add id(userid)        */
  cmd = cmd 'define('                      /*   add define keyword    */
  cmd = cmd usrsf_targ_node                /*   add the node id       */
  cmd = cmd'.'usrsf_targ_user_id')'        /*   add .userid)          */
  if usrsf_peer = 'YES' then do
    cmd = cmd 'PEER('
    if usrsf_pwd_sync = 'YES' then
      cmd = cmd'PWSYNC)'
    else
      cmd = cmd'NOPWSYNC)'
    end
  else if usrsf_managing = 'YES' then
    cmd = cmd 'MANAGED'
  else if usrsf_managed = 'YES' then do
    say '>>> User' usrsf_name,
      ' from input file' 3-ofile 'is missing an association ',
      '"managed-by" user 'usrsf_targ_user_id,
      ' at node 'usrsf_targ_node'.'
    say '>>> DBSYNC has generated command 'cmdcount' in file',
      ' OUTALT'ofile' to define this assocation.'
    say '>>> Please edit the output file, supply the ',
      ' correct node name for user 'usrsf_name', and ensure that',
      ' the AT userid is correct.'
    cmd = 'RACLINK id('usrsf_targ_user_id')'
    cmd = cmd 'define(????????.'usrsf_name')'
    cmd = cmd 'managed AT('usrsf_targ_node'.'userid()')'
    end
  call writealt                            /*   and write it out      */
  return                                   /*   return to genc0206    */
 
/**********************************************************************/
/* Process user certificate data (0207):                              */
/*                                                                    */
/* Build commands for handling the certificate info in a user profile.*/
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build a RACDCERT command on OUTALTn to          */
/* delete a certificate or alter its label, or issue a message if     */
/* a certificate needs to be added (which we can't handle)            */
/*                                                                    */
/* Note: Entire routine implemented as part of:                   @LLA*/
/**********************************************************************/
genc0207:
parse var datarec 6 uscert_name,           /* parse the data          */
   15 uscert_cert_name,
  262 uscert_certlabel,
  294
 
uscert_name = strip(uscert_name)           /* remove blanks           */
uscert_cert_name = strip(uscert_cert_name)
uscert_certlabel = strip(uscert_certlabel)
 
cmd = 'racdcert'                           /* start RACDCERT command  */
select                                     /* add appropriate "id":   */
  when (uscert_name = 'irrcerta')          /* CERTAUTH, SITE, or ID   */
    then cmd = cmd 'CERTAUTH'
  when (uscert_name = 'irrsitec')
    then cmd = cmd 'SITE'
  when (uscert_name = 'irrmulti')
    then cmd = cmd 'MULTIID'
  otherwise cmd = cmd 'ID('uscert_name')'
  end
 
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uscert_name = 1 then              /* if user being      */
      return                               /*   deleted do nothing    */
  else do                                  /*  else identify cert     */
    if uscert_certlabel <> '' then         /*    if labelled, use the */
      tcertname = 'label(',                /*    label                */
        || dquote(uscert_certlabel),
        || ')'
    else do                                /*    else use the serial  */
      call parse_certname uscert_cert_name /*    and issuer's DN  @PYC*/
      tcertname = certserial certissuer
      end
    end                                    /*  end "identify cert"    */
  cmd = cmd 'delete('tcertname'))'         /*  user not deleted:      */
  end                                      /* end if delete           */
 
else if type = 'alter' then do             /* if Alter:               */
 
  if ofile = 1 then                        /* get original certlabel  */
    parse var data1 ,                      /* from "other" data       */
      262 old_certlabel,                   /* record                  */
      294
  else
    parse var data2 ,
      262 old_certlabel,
      294
 
  old_certlabel = strip(old_certlabel)     /* remove blanks           */
 
  if old_certlabel <> '' then              /*    if labelled, use the */
    tcertname = 'label(',                  /*    label                */
      || dquote(old_certlabel),
      || ')'
  else do                                  /*    else use the serial  */
    call parse_certname uscert_cert_name   /*    and issuer's DN  @PYC*/
    tcertname = certserial certissuer
    end
 
  cmd = cmd 'alter('tcertname             /* identify old cert        */
 
  cmd = cmd ') newlabel('                 /* specify new label        */
  cmd = cmd dquote(uscert_certlabel)
  cmd = cmd '))'
  end
 
else do                                    /* type = add: error       */
  say '*** Cannot add certificates automatically. ' ,
      'Manual action required.'
  say '    User = 'uscert_name
  say '    Certificate = 'uscert_cert_name
  say '    Label = 'uscert_certlabel
  say '    INDD1 record being processed: 'count1
  say '    INDD2 record being processed: 'count2
  cmd = cmd 'withlabel('
  cmd = cmd dquote(uscert_certlabel)
  cmd = cmd ')'
  cmd = cmd 'add(?dsname?) ?other_parameters?'
  end
 
call writealt                              /* write the record        */
return
 
 
/**********************************************************************/
/* Process user DFP data (0210):                                      */
/*                                                                    */
/* Build commands for handling the DFP segment in a user profile.     */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the DFP segment information for the user.        */
/*                                                                    */
/**********************************************************************/
genc0210:
parse var datarec 6 usdfp_name,            /* parse the data          */
   15 usdfp_dataappl,
   24 usdfp_dataclas,
   33 usdfp_mgmtclas,
   42 usdfp_storclas,
   50
 
usdfp_name = strip(usdfp_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usdfp_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usdfp_name = 1 then              /* if user being      */
      return                               /*   deleted do nothing    */
  cmd = cmd 'nodfp'                        /*  user not deleted: NODFP*/
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'dfp'                          /* add DFP keyword         */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if usdfp_dataappl <> ' ' then           /* add DATAAPPL if needed */
      cmd = cmd 'dataappl('usdfp_dataappl')'
    else if type = 'alter' then             /* or NODATAAPPL if alter */
      cmd = cmd 'nodataappl'                /* and needed             */
 
    if usdfp_dataclas <> ' ' then           /* add DATACLAS if needed */
      cmd = cmd 'dataclas('usdfp_dataclas')'
    else if type = 'alter' then             /* or NODATACLAS if alter */
      cmd = cmd 'nodataclas'                /* and needed             */
 
    if usdfp_mgmtclas <> ' ' then           /* add MGMTCLAS if needed */
      cmd = cmd 'mgmtclas('usdfp_mgmtclas')'
    else if type = 'alter' then             /* or NOMGMTCLAS if alter */
      cmd = cmd 'nomgmtclas'                /* and needed             */
 
    if usdfp_storclas <> ' ' then           /* add STORCLAS if needed */
      cmd = cmd 'storclas('usdfp_storclas')'
    else if type = 'alter' then             /* or NOSTORCLAS if alter */
      cmd = cmd 'nostorclas'                /* and needed             */
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user TSO data (0220):                                      */
/*                                                                    */
/* Build commands for handling the TSO segment in a user profile.     */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the TSO segment information for the user.        */
/*                                                                    */
/**********************************************************************/
genc0220:
parse var datarec 6 ustso_name,            /* parse the data          */
   15 ustso_account,
   56 ustso_command,
  137 ustso_dest,
  146 ustso_hold_class,
  148 ustso_job_class,
  150 ustso_logon_proc,
  159 ustso_logon_size,
  170 ustso_msg_class,
  172 ustso_logon_max,
  183 ustso_perf_group,
  194 ustso_sysout_class,
  196 ustso_user_data,
  205 ustso_unit_name,
  214 ustso_seclabel,
  222
 
ustso_name = strip(ustso_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd ustso_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.ustso_name = 1 then              /* if user being      */
      return                               /*   deleted do nothing    */
  cmd = cmd 'notso'                        /*   delete TSO segment    */
  end                                      /* end delete              */
 
else do                                    /* else not delete         */
  cmd = cmd 'tso'                          /* add TSO keyword         */
 
  if type = 'alter',                       /* if alter or data exists */
   | substr(datarec,15) <> ' ' then do
    cmd = cmd'('                           /* add ( for data          */
 
    if ustso_account <> ' ' then do        /* if account number exists*/
      cmd = cmd "acctnum("dquote(strip(ustso_account,'T'))")"
      end                                  /* end acct number exists  */
    else if type = 'alter' then            /* if alter and no account */
      cmd = cmd 'noacctnum'                /* number add NOACCOUNT    */
 
    if ustso_command <> ' ' then do        /* if command exists   @PXA*/
      cmd = cmd "command("dquote(strip(ustso_command,'T'))")"  /* @PXA*/
      end                                  /* end command exists  @PXA*/
    else if type = 'alter' then            /* if alter and no command
                                                                  @PXA*/
      cmd = cmd 'nocommand'                /* add NOCOMMAND       @PXA*/
 
    if ustso_dest <> ' ' then              /* add DEST     if needed  */
      cmd = cmd 'dest('ustso_dest')'
    else if type = 'alter' then            /* or NODEST     if alter  */
      cmd = cmd 'nodest'                   /* and needed              */
 
    if ustso_hold_class <> ' ' then        /* add HOLDCLASS if needed */
      cmd = cmd 'holdclass('ustso_hold_class')'
    else if type = 'alter' then            /* or NOHOLDCLASS if alter */
      cmd = cmd 'noholdclass'              /* and needed              */
 
    if ustso_job_class <> ' ' then         /* add JOBCLASS if needed  */
      cmd = cmd 'jobclass('ustso_job_class')'
    else if type = 'alter' then            /* or NOJOBCLASS if alter  */
      cmd = cmd 'nojobclass'               /* and needed              */
 
    if ustso_logon_proc <> ' ' then        /* add PROC     if needed  */
      cmd = cmd 'proc('ustso_logon_proc')'
    else if type = 'alter' then            /* or NOPROC     if alter  */
      cmd = cmd 'noproc'                   /* and needed              */
 
    if ustso_logon_size <> 0,              /* add SIZE if needed      */
     & ustso_logon_size <> ' ' then
      cmd = cmd 'size('right(strip(ustso_logon_size),7)')'
    else if type = 'alter' then            /* or NOSIZE if alter and  */
      cmd = cmd 'nosize'                   /* needed                  */
 
    if ustso_msg_class <> ' ' then         /* add MSGCLASS if needed  */
      cmd = cmd 'msgclass('ustso_msg_class')'
    else if type = 'alter' then            /* or NOMSGCLASS if alter  */
      cmd = cmd 'nomsgclas'                /* and needed              */
 
    if ustso_logon_max <> 0,               /* add MAXSIZE if needed   */
     & ustso_logon_max <> ' ' then
      cmd = cmd 'maxsize('right(strip(ustso_logon_max),7)')'
    else if type = 'alter' then            /* or NOMAXSIZE if alter   */
      cmd = cmd 'nomaxsize'                /* and needed              */
 
  /* cannot do PERF GROUP as RACF commands don't support it */
 
    if ustso_sysout_class <> ' ' then      /* add SYSOUTCLASS if      */
      cmd = cmd 'sysoutclass('ustso_sysout_class')' /* needed, or     */
    else if type = 'alter' then            /* NOSYSOUTCLASS if alter  */
      cmd = cmd 'nosysoutclass'            /* and needed              */
 
    if ustso_user_data <> ' ' then         /* add USERDATA if         */
      cmd = cmd 'userdata('substr(ustso_user_data,3,4)')' /* needed,  */
    else if type = 'alter' then            /* or NOUSERDATA if alter  */
      cmd = cmd 'nouserdata'               /* and needed              */
 
    if ustso_unit_name <> ' ' then         /* add UNIT     if needed  */
      cmd = cmd 'unit('ustso_unit_name')'
    else if type = 'alter' then            /* or NOUNIT     if alter  */
      cmd = cmd 'nounit'                   /* and needed              */
 
    if ustso_seclabel <> ' ' then          /* add SECLABEL if needed  */
      cmd = cmd 'seclabel('ustso_seclabel')'
    else if type = 'alter' then            /* or NOSECLABEL if alter  */
      cmd = cmd 'noseclabel'               /* and needed              */
 
    cmd = cmd')'                           /* close the )             */
    end                                    /* end alter or TSO exists */
  end                                      /* end not delete          */
 
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user CICS data (0230):                                     */
/*                                                                    */
/* Build commands for handling the CICS segment in a user profile.    */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the CICS segment information for the user.       */
/*                                                                    */
/**********************************************************************/
genc0230:
parse var datarec 6 uscics_name,           /* parse the data          */
   15 uscics_opident,
   19 uscics_opprty,
   25 uscics_noforce,
   30 uscics_timeout,
   35
 
uscics_name = strip(uscics_name)           /* remove blanks from name */
 
cmd = 'altuser'                            /* Start ALTUSER command   */
cmd = cmd uscics_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uscics_name = 1 then             /* if user being      */
      return                               /* deleted do nothing      */
    else                                   /* else remember CICS
                                              segment deleted         */
      d.2.ofile.uscics_name = 1
  cmd = cmd 'nocics'                       /* add NOCICS keyword      */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'cics'                         /* add CICS keyword        */
 
  if type = 'alter',                       /* if alter or data exists */
   | substr(datarec,15) <> ' ' then do
    cmd = cmd'('                           /* add ( in front of data  */
 
    if uscics_opident <> ' ' then do       /* add opident if needed,  */
      cmd = cmd "opident("dquote(strip(uscics_opident,'T'))")"
      end
    else if type = 'alter' then            /*Or add NOOPIDENT if alter*/
      cmd = cmd 'noopident'                /* and needed              */
 
    if uscics_opprty <> ' ' then           /* add OPPRTY   if needed  */
      cmd = cmd 'opprty('substr(uscics_opprty,3,3)')'
    else if type = 'alter' then            /* or NOOPPRTY   if alter  */
      cmd = cmd 'noopprty'                 /* and needed              */
 
    if uscics_noforce = 'NO'  then         /* add XRFSOFF(NOFORCE) or */
      cmd = cmd 'xrfsoff(noforce)'
    else                                   /* or XRFSOFF(FORCE) as    */
      cmd = cmd 'xrfsoff(force)'           /* needed                  */
 
    if uscics_timeout <> ' ' then          /* add TIMEOUT  if needed  */
      cmd = cmd 'timeout('substr(uscics_timeout,1,2)||,
                          substr(uscics_timeout,4,2)')'
    else if type = 'alter' then            /* or NOTIMEOUT  if alter  */
      cmd = cmd 'notimeout'                /* and needed              */
 
    cmd = cmd')'                           /* add ending )            */
    end                                    /* end alter or data exists*/
  end                                      /* end not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user CICS operator classes data (0231):                    */
/*                                                                    */
/* Build commands for adding or deleting an operator class in a user's*/
/* CICS segment.                                                      */
/* If the entire user or the entire CICS segment is being deleted     */
/* then we won't generate anything here.                              */
/* Otherwise, we will build an ALTUSER command on OUTALTn to          */
/* modify or delete an operator class.                                */
/*                                                                    */
/**********************************************************************/
genc0231:
parse var datarec 6 uscopc_name,           /* parse the data          */
   15 uscopc_opclass,
   18
 
uscopc_name = strip(uscopc_name)           /* remove blanks from name */
 
if type = 'delete' then do                 /* if delete and user or   */
  if d.1.ofile.uscopc_name = 1,               /* segment deleted      */
   | d.2.ofile.uscopc_name = 1 then           /* do nothing           */
       return
  end
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uscopc_name 'cics('              /* add userid and segment  */
 
if type = 'delete' then                    /* set correct keyword     */
  cmd = cmd'delopclass('
else
  cmd = cmd'addopclass('
 
cmd = cmd substr(uscopc_opclass,2,2)'))'   /* add class name and ))   */
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Warn about user CICS TSL and RSL key data (0232, 0233):            */
/*                                                                    */
/*     Note: Actual support would be very complex,                    */
/*     as we don't allow ADD/DEL for TSLKEY or                        */
/*     RSLKEY, unlike all other repeating fields.                     */
/*                                                                    */
/*                                                                    */
/*    Entire routine:                                            @M5A */
/**********************************************************************/
genc0232:
genc0233:
parse var datarec 6 uscrsl_name,           /* parse the data          */
   15 uscrsl_key,
   20
 
uscrsl_name = strip(uscrsl_name)           /* remove blanks from name */
 
if type = 'delete' then do                 /* if delete and user or   */
  if d.1.ofile.uscrsl_name = 1,               /* segment deleted      */
   | d.2.ofile.uscrsl_name = 1 then           /* do nothing           */
       return
  end
 
say '*** Cannot' type 'CICS RSLKEY or TSLKEY data for' uscrls_name,
    ' on file INDD'3-ofile'.'
    say '    INDD1 record being processed: 'count1
    say '    INDD2 record being processed: 'count2
bumprc = 1
return
 
/**********************************************************************/
/* Process user LANGUAGE data (0240):                                 */
/*                                                                    */
/* Build commands for handling the LANGUAGE segment in a user profile.*/
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the LANGUAGE segment information for the user.   */
/*                                                                    */
/**********************************************************************/
genc0240:
parse var datarec 6 uslan_name,            /* parse the data          */
   15 uslan_primary,
   19 uslan_secondary,
   22
 
uslan_name = strip(uslan_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uslan_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uslan_name = 1 then            /* if user              */
      return                               /* being deleted do nothing*/
  cmd = cmd 'nolanguage'                   /* add NOLANGUAGE keyword  */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'language'                     /* add LANGUAGE keyword    */
  if type = 'alter',                       /* if alter or data exists */
   | substr(datarec,15) <> ' ' then do
 
    cmd = cmd'('                           /* add ( before data       */
    if uslan_primary <> ' ' then           /* add PRIMARY language    */
      cmd = cmd "primary("dquote(strip(uslan_primary,'T'))")"
    else if type = 'alter' then            /* or NOPRIMARY  if alter  */
      cmd = cmd 'noprimary'                /* and needed              */
 
    if uslan_secondary <> ' ' then         /*add SECONDARY language   */
      cmd = cmd "secondary("dquote(strip(uslan_secondary,'T'))")"/*
                                                                      */
    else if type = 'alter' then            /* or NOSECONDARY if alter */
      cmd = cmd 'nosecondary'              /* and needed              */
 
    cmd = cmd')'                           /* add ) to end the data   */
    end                                    /* end alter or data exists*/
  end                                      /* end not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user OPERPARM data (0250):                                 */
/*                                                                    */
/* Build commands for handling the OPERPARM segment in a user profile.*/
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the OPERPARM segment information for the user.   */
/*                                                                    */
/**********************************************************************/
genc0250:
parse var datarec 6 usopr_name,            /* parse the data          */
  15 usopr_storage,
  21 usopr_masterauth,
  26 usopr_allauth,
  31 usopr_sysauth,
  36 usopr_ioauth,
  41 usopr_consauth,
  46 usopr_infoauth,
  51 usopr_timestamp,
  56 usopr_systemid,
  61 usopr_jobid,
  66 usopr_msgid,
  71 usopr_x,
  76 usopr_wtor,
  81 usopr_immediate,
  86 usopr_critical,
  90
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
  91 usopr_eventual,
  96 usopr_info,
 101 usopr_nobrodcast,
 106 usopr_all,
 111 usopr_jobnames,
 116 usopr_jobnamest,
 121 usopr_sess,
 126 usopr_sesst,
 131 usopr_status,
 136 usopr_routecode.1,
 141 usopr_routecode.2,
 146 usopr_routecode.3,
 151 usopr_routecode.4,
 156 usopr_routecode.5,
 161 usopr_routecode.6,
 165
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 166 usopr_routecode.7,
 171 usopr_routecode.8,
 176 usopr_routecode.9,
 181 usopr_routecode.10,
 186 usopr_routecode.11,
 191 usopr_routecode.12,
 196 usopr_routecode.13,
 201 usopr_routecode.14,
 206 usopr_routecode.15,
 211 usopr_routecode.16,
 216 usopr_routecode.17,
 221 usopr_routecode.18,
 226 usopr_routecode.19,
 231 usopr_routecode.20,
 236 usopr_routecode.21,
 240
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 241 usopr_routecode.22,
 246 usopr_routecode.23,
 251 usopr_routecode.24,
 256 usopr_routecode.25,
 261 usopr_routecode.26,
 266 usopr_routecode.27,
 271 usopr_routecode.28,
 276 usopr_routecode.29,
 281 usopr_routecode.30,
 286 usopr_routecode.31,
 291 usopr_routecode.32,
 296 usopr_routecode.33,
 301 usopr_routecode.34,
 306 usopr_routecode.35,
 311 usopr_routecode.36,
 315
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 316 usopr_routecode.37,
 321 usopr_routecode.38,
 326 usopr_routecode.39,
 331 usopr_routecode.40,
 336 usopr_routecode.41,
 341 usopr_routecode.42,
 346 usopr_routecode.43,
 351 usopr_routecode.44,
 356 usopr_routecode.45,
 361 usopr_routecode.46,
 366 usopr_routecode.47,
 371 usopr_routecode.48,
 376 usopr_routecode.49,
 381 usopr_routecode.50,
 386 usopr_routecode.51,
 390
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 391 usopr_routecode.52,
 396 usopr_routecode.53,
 401 usopr_routecode.54,
 406 usopr_routecode.55,
 411 usopr_routecode.56,
 416 usopr_routecode.57,
 421 usopr_routecode.58,
 426 usopr_routecode.59,
 431 usopr_routecode.60,
 436 usopr_routecode.61,
 441 usopr_routecode.62,
 446 usopr_routecode.63,
 451 usopr_routecode.64,
 456 usopr_routecode.65,
 461 usopr_routecode.66,
 465
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 466 usopr_routecode.67,
 471 usopr_routecode.68,
 476 usopr_routecode.69,
 481 usopr_routecode.70,
 486 usopr_routecode.71,
 491 usopr_routecode.72,
 496 usopr_routecode.73,
 501 usopr_routecode.74,
 506 usopr_routecode.75,
 511 usopr_routecode.76,
 516 usopr_routecode.77,
 521 usopr_routecode.78,
 526 usopr_routecode.79,
 531 usopr_routecode.80,
 536 usopr_routecode.81,
 540
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 541 usopr_routecode.82,
 546 usopr_routecode.83,
 551 usopr_routecode.84,
 556 usopr_routecode.85,
 561 usopr_routecode.86,
 566 usopr_routecode.87,
 571 usopr_routecode.88,
 576 usopr_routecode.89,
 581 usopr_routecode.90,
 586 usopr_routecode.91,
 591 usopr_routecode.92,
 596 usopr_routecode.93,
 601 usopr_routecode.94,
 606 usopr_routecode.95,
 611 usopr_routecode.96,
 615
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 616 usopr_routecode.97,
 621 usopr_routecode.98,
 626 usopr_routecode.99,
 631 usopr_routecode.100,
 636 usopr_routecode.101,
 641 usopr_routecode.102,
 646 usopr_routecode.103,
 651 usopr_routecode.104,
 656 usopr_routecode.105,
 661 usopr_routecode.106,
 666 usopr_routecode.107,
 671 usopr_routecode.108,
 676 usopr_routecode.109,
 681 usopr_routecode.110,
 686 usopr_routecode.111,
 690
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 691 usopr_routecode.112,
 696 usopr_routecode.113,
 701 usopr_routecode.114,
 706 usopr_routecode.115,
 711 usopr_routecode.116,
 716 usopr_routecode.117,
 721 usopr_routecode.118,
 726 usopr_routecode.119,
 731 usopr_routecode.120,
 736 usopr_routecode.121,
 741 usopr_routecode.122,
 746 usopr_routecode.123,
 751 usopr_routecode.124,
 756 usopr_routecode.125,
 761 usopr_routecode.126,
 765
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec,
 766 usopr_routecode.127,
 771 usopr_routecode.128,
 776 usopr_logcmdresp,
 785 usopr_migrationid,
 790 usopr_delopermsg,
 799 usopr_retrieve_key,
 808 usopr_cmdsys,
 817 usopr_ud,
 822 usopr_altgrp_id,
 831 usopr_auto,                           /*                     @LVA*/
 836 usopr_hc,                             /*                     @M7A*/
 841 usopr_int,                            /*                     @M7A*/
 846 usopr_unkn,                           /*                     @M7A*/
 850                                       /*                     @M7C*/
 
usopr_name = strip(usopr_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd usopr_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usopr_name = 1 then            /* if user is           */
      return                               /* being deleted do nothing*/
  else                                     /* else remember deletion  */
    d.3.ofile.usopr_name = 1
  cmd = cmd 'nooperparm'                   /* Use NOOPERPARM          */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'operparm'                     /* add operparm keyword    */
  if type = 'alter',                       /* if alter or data exists */
   | substr(datarec,15) <> ' ' then do     /* add ( and the data:     */
    cmd = cmd'('
 
    if usopr_storage <> ' ',
     & usopr_storage <> 0 then             /* add storage info if nec.*/
      cmd = cmd 'storage('substr(usopr_storage,2,4)')'
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'nostorage'                /* NOSTORAGE if necessary  */
 
    if pos('YES',substr(datarec,21,29)) > 0 then do /* if auth
                                              info is present         */
      cmd = cmd 'auth('                    /* add it to command       */
      if usopr_masterauth = 'YES' then
        cmd = cmd 'master'
      if usopr_allauth = 'YES' then
        cmd = cmd 'all'
      else do                              /* don't do sys, etc. if   */
        if usopr_sysauth = 'YES' then      /* user has ALL because    */
          cmd = cmd 'sys'                  /* IRRDBU00 will turn on   */
        if usopr_ioauth = 'YES' then       /* sys, etc. too, and the  */
          cmd = cmd 'io'                   /* command will be rejected*/
        if usopr_consauth = 'YES' then
          cmd = cmd 'cons'
        if usopr_infoauth = 'YES' then
          cmd = cmd 'info'
        end                                /* end don't do sys, etc.  */
      cmd = cmd')'
      end                                  /* end auth info present   */
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'noauth'                   /* NOAUTH if necessary     */
 
    if pos('YES',substr(datarec,51,24)) > 0 then do /* if mform
                                              info is present         */
      cmd = cmd 'mform('                   /* add it to command       */
      if usopr_timestamp = 'YES' then
        cmd = cmd 'T'
      if usopr_systemid = 'YES' then
        cmd = cmd 'S'
      if usopr_jobid = 'YES' then
        cmd = cmd 'J'
      if usopr_msgid = 'YES' then
        cmd = cmd 'M'
      if usopr_x = 'YES' then
        cmd = cmd 'X'
      cmd = cmd')'
      end                                  /* end mform info present  */
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'nomform'                  /* NOMFORM if necessary    */
 
    if pos('YES',substr(datarec,76,34)) > 0 then do /* if level
                                               info is present        */
      cmd = cmd 'level('                    /* add it to command      */
      if usopr_wtor = 'YES' then
        cmd = cmd 'R'
      if usopr_immediate = 'YES' then
        cmd = cmd 'I'
      if usopr_critical = 'YES' then
        cmd = cmd 'C'
      if usopr_eventual = 'YES' then
        cmd = cmd 'E'
      if usopr_info = 'YES' then
        cmd = cmd 'IN'
      if usopr_nobrodcast = 'YES' then
        cmd = cmd 'NB'
      if usopr_all = 'YES' then
        cmd = cmd 'ALL'
      cmd = cmd')'
      end                                  /* end level info present  */
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'nolevel'                  /* NOLEVEL if necessary    */
 
    if pos('YES',substr(datarec,111,24)) > 0 then do /* if monitor
                                               info is present        */
      cmd = cmd 'monitor('                 /* add it to command       */
      if usopr_jobnames = 'YES' then
        cmd = cmd 'jobnames'
      if usopr_jobnamest = 'YES' then
        cmd = cmd 'jobnamest'
      if usopr_sess = 'YES' then
        cmd = cmd 'sess'
      if usopr_sesst = 'YES' then
        cmd = cmd 'sesst'
      if usopr_status = 'YES' then
        cmd = cmd 'status'
      cmd = cmd')'
      end                                  /* end monitor info exists */
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'nomonitor'                /* NOMONITOR if necessary  */
 
    if substr(datarec,136,634) <> ' ' then do /* if route-
                                              code info present       */
      cmd = cmd 'routcode('                /* add it to command       */
      if pos('YES',substr(datarec,136,634)) > 0 then do /* if any
                                              routecodes specified    */
        if pos('NO',substr(datarec,136,634)) > 0 then do /* if some
                                              route code not wanted,
                                              set specific routecodes */
          do i = 1 to 128                  /* process 128 routecodes  */
            if usopr_routecode.i = 'YES' then  /* if this one     @P2C*/
              cmd = cmd i                  /* present add it to cmd   */
            end                            /* end process 128 route...*/
          end                              /* end some not wanted     */
        else                               /* else all wanted         */
          cmd = cmd'ALL'                   /* add ALL to command      */
        end                                /* end any specified       */
      else                                 /* else none specified     */
        cmd = cmd'NONE'                    /* so add NONE to command  */
      cmd = cmd')'                         /* add ) after data        */
      end                                  /* end routecode info ...  */
    else if type = 'alter' then            /* else if alter add       */
      cmd = cmd 'noroutcode'               /* NOROUTCODE if necessary */
 
    if usopr_logcmdresp <> ' ' then        /* if logcmdresp data,     */
      cmd = cmd 'logcmdresp('usopr_logcmdresp')' /* add it to command */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'nologcmdresp'             /* NOLOGCMDRESP if nec.    */
 
    if usopr_migrationid <> ' ' then       /* if migrationid exists,  */
      cmd = cmd 'migid('usopr_migrationid')' /* add it to command     */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'nomigid'                  /* NOMIGID                 */
 
    if usopr_delopermsg <> ' ' then        /* if delopermsg exists,   */
      cmd = cmd 'dom('usopr_delopermsg')'  /* add it to command       */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'nodom'                    /* NODOM                   */
 
    if usopr_retrieve_key <> ' ' then      /* if retrieve key exists  */
      cmd = cmd 'key('usopr_retrieve_key')'/* add it to command       */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'nokey'                    /* NOKEY                   */
 
    if usopr_cmdsys <> ' ' then            /* if cmdsys exists,       */
      cmd = cmd 'cmdsys('usopr_cmdsys')'   /* add it to command       */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'nocmdsys'                 /* NOCMDSYS                */
 
    if usopr_ud <> ' ' then                /* if ud info exists       */
      cmd = cmd 'ud('usopr_ud')'           /* add it to command       */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'noud'                     /* NOUD                    */
 
    if usopr_altgrp_id <> ' ' then         /* if altgrp exists,       */
      cmd = cmd 'altgrp('usopr_altgrp_id')'/* add it to command       */
    else if type = 'alter' then            /* else if alter, add      */
      cmd = cmd 'noaltgrp'                 /* NOALTGRP                */
 
    if usopr_auto <> ' ' then              /* if auto info exists @LVA*/
      cmd = cmd 'auto('usopr_auto')'       /* add it to command   @LVA*/
    else if type = 'alter' then            /* else if alter, add  @LVA*/
      cmd = cmd 'noauto'                   /* NOAUTO              @LVA*/
 
    tempopr = ''                           /* init temp var       @M7A*/
    if usopr_hc <> ' ' then                /* if hc info exists   @M7A*/
      tempopr = 'hc('usopr_hc')'           /* save in temp var    @M7A*/
    else if type = 'alter' then            /* else if alter, add  @M7A*/
      tempopr = 'nohc'                     /* NOHC                @M7A*/
    if tempopr <> '' then do               /* output or nullify   @M7A*/
      if FMID.ofile < 'HRF7730' then       /* HRF7730 or later?   @M7A*/
        tempopr = '/*' tempopr '*/'        /*                     @M7A*/
      cmd = cmd tempopr                    /* add hc info         @M7A*/
      end                                  /*                     @M7A*/
 
    tempopr = ''                           /* init temp var       @M7A*/
    if usopr_int <> ' ' then               /* if int info exists  @M7A*/
      tempopr = 'intids('usopr_int')'      /* save in temp var    @M7A*/
    else if type = 'alter' then            /* else if alter, add  @M7A*/
      tempopr = 'nointids'                 /* NOINTIDS            @M7A*/
    if tempopr <> '' then do               /* output or nullify   @M7A*/
      if FMID.ofile < 'HRF7730' then       /* HRF7730 or later?   @M7A*/
        tempopr = '/*' tempopr '*/'        /*                     @M7A*/
      cmd = cmd tempopr                    /* add int info        @M7A*/
      end                                  /*                     @M7A*/
 
    tempopr = ''                           /* init temp var       @M7A*/
    if usopr_unkn <> ' ' then              /* if unkn info exists @M7A*/
      tempopr = 'unknids('usopr_unkn')'    /* save in temp var    @M7A*/
    else if type = 'alter' then            /* else if alter, add  @M7A*/
      tempopr = 'nounknids'                /* NOUNKNIDS           @M7A*/
    if tempopr <> '' then do               /* output or nullify   @M7A*/
      if FMID.ofile < 'HRF7730' then       /* HRF7730 or later?   @M7A*/
        tempopr = '/*' tempopr '*/'        /*                     @M7A*/
      cmd = cmd tempopr                    /* add unkn info       @M7A*/
      end                                  /*                     @M7A*/
 
 
 
    cmd = cmd')'                           /* add ) to end data       */
    end                                    /* end alter or operparm...*/
  end                                      /* end type not delete     */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user OPERPARM scope data (0251):                           */
/*                                                                    */
/* Build commands for adding or deleting a scope (mscope) in a user's */
/* OPERPARM segment.                                                  */
/* If the entire user or the entire OPERPARM segment is being deleted */
/* then we won't generate anything here.                              */
/* Otherwise, we will build an ALTUSER command on OUTALTn to          */
/* modify or delete an mscope.                                        */
/*                                                                    */
/**********************************************************************/
genc0251:
parse var datarec 6 usoprp_name,           /* parse the data          */
   15 usoprp_system,
   23
 
usoprp_name = strip(usoprp_name)           /* remove blanks from name */
 
if type = 'delete' then do                 /* check if anything to do */
  if d.1.ofile.usoprp_name = 1,
   | d.3.ofile.usoprp_name = 1 then
     return                                /* leave if nothing to do  */
  end                                      /* end type = delete       */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd usoprp_name 'operparm('          /* add userid, keyword     */
if type = 'delete' then                    /* for delete, build a     */
  cmd = cmd'delmscope('                    /* delmscope keyword, else */
else                                       /* build an addmscope      */
  cmd = cmd'addmscope('
cmd = cmd usoprp_system'))'                /* add the mscope value    */
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Process user WORKATTR data (0260):                                 */
/*                                                                    */
/* Build commands for handling the WORKATTR segment in a user profile.*/
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the WORKATTR segment information for the user.   */
/*                                                                    */
/**********************************************************************/
genc0260:
parse var datarec 6 uswrk_name,            /* parse the data          */
   15 uswrk_area_name,
   76 uswrk_building,
  137 uswrk_department,
  198 uswrk_room,
  259 uswrk_addr_line1,
  320 uswrk_addr_line2,
  381 uswrk_addr_line3,
  442 uswrk_addr_line4,
  503 uswrk_account,
  758
 
uswrk_name = strip(uswrk_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uswrk_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uswrk_name = 1 then
    return                                 /* leave if user deleted   */
  cmd = cmd 'noworkattr'                   /* delete workattr segment */
  end                                      /* end if delete           */
else do                                    /* else not delete         */
 
  cmd = cmd 'workattr'                     /* add/alter workattr      */
  if type = 'alter',                       /* if alter or data exists */
   | substr(datarec,15) <> ' ' then do
    cmd = cmd'('                           /* add ( and data          */
 
    if uswrk_area_name <> ' ' then            /* if name exists add it*/
      cmd = cmd "waname("dquote(strip(uswrk_area_name,'T'))")"
    else if type = 'alter' then               /* else if alter use    */
      cmd = cmd 'nowaname'                    /* NOWANAME to delete it*/
 
    if uswrk_building <> ' ' then             /* if building, add it  */
      cmd = cmd "wabldg("dquote(strip(uswrk_building,'T'))")"
    else if type = 'alter' then               /* else if alter use    */
      cmd = cmd 'nowabldg'                    /* NOWABLDG to delete it*/
 
    if uswrk_department <> ' ' then           /* if dept exists, add  */
      cmd = cmd "wadept("dquote(strip(uswrk_department,'T'))")"
    else if type = 'alter' then               /* else if alter use    */
      cmd = cmd 'nowadept'                    /* NOWADEPT to delete it*/
 
    if uswrk_room <> ' ' then                 /* if room exists, add  */
      cmd = cmd "waroom("dquote(strip(uswrk_room,'T'))")"
    else if type = 'alter' then               /* else if alter use    */
      cmd = cmd 'nowaroom'                    /* NOWAROOM to delete it*/
 
    if uswrk_addr_line1 <> ' ' then            /* if addr1 exists, add*/
      cmd = cmd "waaddr1("dquote(strip(uswrk_addr_line1,'T'))")" /*
                                                                      */
    else if type = 'alter' then                /* else if alter use   */
      cmd = cmd 'nowaaddr1'                    /* NOWAADDR1 to del. it*/
 
    if uswrk_addr_line2 <> ' ' then            /* if addr2 exists, add*/
      cmd = cmd "waaddr2("dquote(strip(uswrk_addr_line2,'T'))")" /*
                                                                      */
    else if type = 'alter' then                /* else if alter use   */
      cmd = cmd 'nowaaddr2'                    /* NOWAADDR2 to del. it*/
 
    if uswrk_addr_line3 <> ' ' then            /* if addr3 exists, add*/
      cmd = cmd "waaddr3("dquote(strip(uswrk_addr_line3,'T'))")" /*
                                                                      */
    else if type = 'alter' then                /* else if alter use   */
      cmd = cmd 'nowaaddr3'                    /* NOWAADDR3 to del. it*/
 
    if uswrk_addr_line4 <> ' ' then            /* if addr4 exists, add*/
      cmd = cmd "waaddr4("dquote(strip(uswrk_addr_line4,'T'))")" /*
                                                                      */
    else if type = 'alter' then                /* else if alter use   */
      cmd = cmd 'nowaaddr4'                    /* NOWAADDR4 to del. it*/
 
    if uswrk_account <> ' ' then              /* if accnt exists, add */
      cmd = cmd "waaccnt("dquote(strip(uswrk_account,'T'))")"
    else if type = 'alter' then               /* else if alter use    */
      cmd = cmd 'nowaaccnt'                   /* NOWAACCNT to del. it */
 
    cmd = cmd')'                           /* add ) to end data       */
    end                                    /* end alter or data exists*/
  end                                      /* end not delete          */
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Process user OMVS data (0270):                                     */
/*                                                                    */
/* Build commands for handling the OMVS segment in a user profile.    */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the OMVS segment information for the user.       */
/*                                                                    */
/**********************************************************************/
genc0270:
parse var datarec 6 usomvs_name,           /* parse the data          */
   15 usomvs_uid,
   26 usomvs_home_path,
 1050 usomvs_program,
 2074 usomvs_cputimemax,                                   /*     @LHA*/
 2085 usomvs_assizemax,                                    /*     @LHA*/
 2096 usomvs_fileprocmax,                                  /*     @LHA*/
 2107 usomvs_procusermax,                                  /*     @LHA*/
 2118 usomvs_threadsmax,                                   /*     @LHA*/
 2129 usomvs_mmapareamax,                                  /*     @LHA*/
 2140 usomvs_memlimit,                                     /*     @M2A*/
 2150 usomvs_shmemax,                                      /*     @M2A*/
 2159
 
usomvs_name = strip(usomvs_name)           /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usomvs_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usomvs_name = 1 then        /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'noomvs'                       /*  user not deleted:NOOMVS*/
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'omvs'                         /* add OMVS keyword        */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if usomvs_uid <> ' ' then              /* add UID      if needed  */
      cmd = cmd 'uid('usomvs_uid')'
    else if type = 'alter' then             /* or NOUID      if alter */
      cmd = cmd 'nouid'                     /* and needed             */
 
    if usomvs_home_path <> ' ' then         /* add HOME     if needed */
      cmd = cmd "home("dquote(strip(usomvs_home_path,'T'))")"
    else if type = 'alter' then             /* or NOHOME     if alter */
      cmd = cmd 'nohome'                    /* and needed             */
 
    if usomvs_program <> ' ' then           /* add PROGRAM  if needed */
      cmd = cmd "program("dquote(strip(usomvs_program,'T'))")"
    else if type = 'alter' then             /* or NOPROGRAM  if alter */
      cmd = cmd 'noprogram'                 /* and needed             */
 
    if usomvs_cputimemax <> ' ' then           /*add CPUTIMEMAX if needed*/
      cmd = cmd "cputimemax("usomvs_cputimemax")"
    else if type = 'alter' then             /* or NOCPUTIMEMAX if     */
      cmd = cmd 'nocputimemax'              /* alter needed           */
 
    if usomvs_assizemax <> ' ' then         /*add ASSIZEMAX  if needed*/
      cmd = cmd "assizemax("usomvs_assizemax")"                /* @PSC*/
    else if type = 'alter' then             /* or NOASSIZEMAX if      */
      cmd = cmd 'noassizemax'               /* alter needed           */
 
    if usomvs_fileprocmax <> ' ' then       /*add FILEPROCMAX if needed*/
      cmd = cmd "fileprocmax("usomvs_fileprocmax")"
    else if type = 'alter' then            /* or NOFILEPROCMAX if     */
      cmd = cmd 'nofileprocmax'             /* alter needed           */
 
    if usomvs_procusermax <> ' ' then       /*add PROCUSERMAX if needed*/
      cmd = cmd "procusermax("usomvs_procusermax")"
    else if type = 'alter' then             /* or NOPROCUSERMAX if    */
      cmd = cmd 'noprocusermax'             /* alter needed           */
 
    if usomvs_threadsmax <> ' ' then        /*add THREADSMAX if needed*/
      cmd = cmd "threadsmax("usomvs_threadsmax")"
    else if type = 'alter' then             /* or THREADSMAX if     */
      cmd = cmd 'nothreadsmax'              /* alter needed           */
 
    if usomvs_mmapareamax <> ' ' then      /*add MMAPAREAMAX if needed*/
      cmd = cmd "mmapareamax("usomvs_mmapareamax")"
    else if type = 'alter' then             /* or NOMMAPAREAMAX if    */
      cmd = cmd 'nommapareamax'             /* alter needed           */
 
    if (FMID.ofile < 'HRF7709') then        /* skip 64-bit unless
                                             output file FMID
                                             supports
                                             z/OS R6 or later     @M7C*/
      cmd = cmd "/* "                         /*                  @M6A*/
 
      if usomvs_memlimit <> ' ' then          /*MEMLIMIT needed?    @M2A*/
        cmd = cmd "memlimit("usomvs_memlimit")"                  /* @M2A*/
      else if type = 'alter' then             /* or NOMEMLIMIT if   @M2A*/
        cmd = cmd 'nomemlimit'                /* alter and needed   @Q2C*/
 
      if usomvs_shmemax     <> ' ' then      /*SHMEMMAX needed?     @M2A*/
        cmd = cmd "shmemmax("usomvs_shmemax")"                   /* @M2A*/
      else if type = 'alter' then             /* or NOSHMEMMAX if   @M2A*/
        cmd = cmd 'noshmemmax'                /* alter and needed   @M2A*/
 
    if (FMID.ofile < 'HRF7709') then          /* skip 64-bit unless
                                             output file FMID
                                             supports
                                             z/OS R6 or later     @M7C*/
      cmd = cmd " */"                         /*                  @M6A*/
 
   cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user NETVIEW data (0280):                                  */
/*                                                                    */
/* Build commands for handling the NETVIEW segment in a user profile. */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the NETVIEW segment information for the user.    */
/*                                                                    */
/* If the NETVIEW segment is being deleted we will remember that in   */
/* the d.5.ofile.name variable for use when processing 0281 and 0282. */
/*                                                                    */
/**********************************************************************/
genc0280:
parse var datarec 6 usnetv_name,           /* parse the data      @LEC*/
   15 usnetv_ic,
  271 usnetv_consname,
  280 usnetv_ctl,
  289 usnetv_msgrecvr,
  294 usnetv_ngmfadmn,
  299 usnetv_ngmfvspn,
  307
 
usnetv_name = strip(usnetv_name)           /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usnetv_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usnetv_name = 1 then             /* if user being      */
      return                               /* deleted do nothing      */
    else                                   /* else remember NETVIEW
                                              segment deleted         */
      d.5.ofile.usnetv_name = 1
  cmd = cmd 'nonetview'                    /* add NONETVIEW keyword   */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'netview('                     /* add NETVIEW keyword     */
 
 
  cmd = cmd 'ctl('usnetv_ctl')'            /* add CTL operand         */
 
  cmd = cmd 'msgrecvr('usnetv_msgrecvr')'  /* add MSGRECVR operand    */
 
  if usnetv_consname <> ' ' then           /* add CONSNAME if needed  */
    cmd = cmd "consname("dquote(strip(usnetv_consname,'T'))")"
  else if type = 'alter' then               /* or NOCONSNAME if alter */
    cmd = cmd 'noconsname'                  /* and needed             */
 
  cmd = cmd 'ngmfadmn('usnetv_ngmfadmn')'  /* add NGMFADMN operand    */
 
  if usnetv_ic <> ' ' then                 /* add IC       if needed */
    cmd = cmd "ic("dquote(strip(usnetv_ic,'T'))")"
  else if type = 'alter' then               /* or NOIC       if alter */
    cmd = cmd 'noic'                        /* and needed             */
 
  if usnetv_ngmfvspn <> ' ' then           /* add NGMFVSPN if needed
                                                                  @LEA*/
    cmd = cmd "ngmfvspn("dquote(strip(usnetv_ngmfvspn,'T'))")" /* @LEA*/
  else if type = 'alter' then              /* or NONGMFVSPN if    @LEA*/
    cmd = cmd 'nongmfvspn'                 /* alter and needed    @LEA*/
 
  cmd = cmd')'                             /* Add closing )           */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user NETVIEW operator classes data (0281):                 */
/*                                                                    */
/* Build commands for adding or deleting an operator class in a user's*/
/* NETVIEW segment.                                                   */
/* If the entire user or the entire NETVIEW segment is being deleted  */
/* then we won't generate anything here.                              */
/* Otherwise, we will build an ALTUSER command on OUTALTn to          */
/* add or delete an operator class.                                   */
/*                                                                    */
/**********************************************************************/
genc0281:
parse var datarec 6 usnopc_name,           /* parse the data          */
   15 usnopc_opclass,
   19
 
usnopc_name = strip(usnopc_name)           /* remove blanks from name */
 
if type = 'delete' then do                 /* if delete and user or   */
  if d.1.ofile.usnopc_name = 1,               /* segment deleted      */
   | d.5.ofile.usnopc_name = 1 then           /* do nothing           */
       return
  end
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd usnopc_name 'netview('           /* add userid and segment  */
 
if type = 'delete' then                    /* set correct keyword     */
  cmd = cmd'delopclass('
else
  cmd = cmd'addopclass('
 
cmd = cmd usnopc_opclass'))'               /* add class name and ))   */
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Process user NETVIEW domain data (0282):                           */
/*                                                                    */
/* Build commands for adding or deleting a domain in a user's         */
/* NETVIEW segment.                                                   */
/* If the entire user or the entire NETVIEW segment is being deleted  */
/* then we won't generate anything here.                              */
/* Otherwise, we will build an ALTUSER command on OUTALTn to          */
/* add or delete a domain.                                            */
/*                                                                    */
/**********************************************************************/
genc0282:
parse var datarec 6 usndom_name,           /* parse the data          */
   15 usndom_domains,
   20                                      /*                     @Q5C*/
 
usndom_name = strip(usndom_name)           /* remove blanks from name */
 
if type = 'delete' then do                 /* if delete and user or   */
  if d.1.ofile.usndom_name = 1,               /* segment deleted      */
   | d.5.ofile.usndom_name = 1 then           /* do nothing           */
       return
  end
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd usndom_name 'netview('           /* add userid and segment  */
 
if type = 'delete' then                    /* set correct keyword     */
  cmd = cmd'deldomains('
else
  cmd = cmd'adddomains('
 
cmd = cmd usndom_domains'))'               /* add class name and ))   */
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Process user DCE data (0290):                                      */
/*                                                                    */
/* Build commands for handling the DCE segment in a user profile.     */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the DCE segment information for the user.        */
/*                                                                    */
/* (entire routine added for DCE support)                         @LCA*/
/**********************************************************************/
genc0290:
parse var datarec 6 usdce_name,            /* parse the data          */
   15 usdce_uuid,
   52 usdce_dce_name,
 1076 usdce_homecell,
 2100 usdce_homeuuid,
 2137 usdce_flags,
 2141
 
usdce_name = strip(usdce_name)             /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usdce_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usdce_name = 1 then         /* if user being           */
      return                               /* deleted do nothing      */
  else                                     /* else just               */
    cmd = cmd 'nodce'                      /* add NODCE keyword       */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'dce('                         /* add DCE keyword         */
 
 
  if usdce_uuid <> ' ' then                /* add uuid if defined     */
    cmd = cmd "uuid("strip(usdce_uuid,'T')")"
  else if type = 'alter' then               /* or NOUUID if alter     */
    cmd = cmd 'nouuid'                      /* and needed             */
 
  if usdce_dce_name <> ' ' then            /* add dce name if defined */
    cmd = cmd "dcename("dquote(strip(usdce_dce_name,'T'))")"
  else if type = 'alter' then               /* or NODCENAME if alter  */
    cmd = cmd 'nodcename'                   /* and needed             */
 
  if usdce_homecell <> ' ' then            /* add homecell if defined */
    cmd = cmd "homecell("dquote(strip(usdce_homecell,'T'))")"
  else if type = 'alter' then               /* or NOHOMECELL if alter */
    cmd = cmd 'nohomecell'                  /* and needed             */
 
  if usdce_homeuuid <> ' ' then            /* add homeuuid if defined */
    cmd = cmd "homeuuid("strip(usdce_homeuuid,'T')")"
  else if type = 'alter' then               /* or NOHOMEUUID if alter */
    cmd = cmd 'nohomeuuid'                  /* and needed             */
 
  if usdce_flags = 'YES' then               /* Add AUTOLOGIN          */
    cmd = cmd 'autologin(yes)'
  else if type = 'alter' then               /* or NOAUTOLOGIN if alter*/
    cmd = cmd 'autologin(no)'               /* and needed             */
 
  cmd = cmd')'                             /* Add closing )           */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user OVM data (02A0):                                      */
/*                                                                    */
/* Build commands for handling the OVM  segment in a user profile.    */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the OVM segment information for the user.        */
/*                                                              @LGA  */
/**********************************************************************/
genc02A0:
parse var datarec 6 usovm_name,           /* parse the data          */
   15 usovm_uid,
   26 usovm_home_path,
 1050 usovm_program,
 2074 usovm_fsroot,
 3097                                     /*                      @Q5C*/
 
 
usovm_name = strip(usovm_name)           /* remove blanks from name */
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usovm_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usovm_name = 1 then        /* if user being            */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'noovm'                        /*  user not deleted:NOOvm */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'ovm'                          /* add OVM keyword         */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if usovm_uid <> ' ' then              /* add UID      if needed  */
      cmd = cmd 'uid('usovm_uid')'
    else if type = 'alter' then             /* or NOUID      if alter */
      cmd = cmd 'nouid'                     /* and needed             */
 
    if usovm_home_path <> ' ' then         /* add HOME     if needed */
      cmd = cmd "home("dquote(strip(usovm_home_path,'T'))")"
    else if type = 'alter' then             /* or NOHOME     if alter */
      cmd = cmd 'nohome'                    /* and needed             */
 
    if usovm_program <> ' ' then           /* add PROGRAM  if needed */
      cmd = cmd "program("dquote(strip(usovm_program,'T'))")"
    else if type = 'alter' then             /* or NOPROGRAM  if alter */
      cmd = cmd 'noprogram'                 /* and needed             */
 
    if usovm_fsroot <> ' ' then           /* add FSROOT  if needed */
      cmd = cmd "program("dquote(strip(usovm_fsroot,'T'))")"
    else if type = 'alter' then             /* or NOPROGRAM  if alter */
      cmd = cmd 'nofsroot'                  /* and needed             */
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
 
/**********************************************************************/
/* Process user LNOTES data (02B0):                                   */
/*                                                                    */
/* Build commands for handling the LNOTES segment in a user profile.  */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the LNOTES segment information for the user.     */
/*                                                                    */
/*  Note: Entire routine implemented as part of                   @LJA*/
/**********************************************************************/
genc02B0:
parse var datarec 6 uslnot_name,           /* parse the data          */
   15 uslnot_sname,
   79
 
 
uslnot_name = strip(uslnot_name)           /* remove blanks           */
uslnot_sname = strip(uslnot_sname)
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd uslnot_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uslnot_name = 1 then        /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'nolnotes'                     /*  else seg del: NOLNOTES */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'lnotes'                       /* add LNOTES keyword      */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if uslnot_sname <> ' ' then            /* add SNAME    if needed  */
      cmd = cmd 'sname('dquote(uslnot_sname)')'
    else if type = 'alter' then             /* or NOSNAME    if alter */
      cmd = cmd 'nosname'                   /* and needed             */
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user NDS data (02C0):                                      */
/*                                                                    */
/* Build commands for handling the NDS segment in a user profile.     */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the NDS segment information for the user.        */
/*                                                                    */
/*  Note: Entire routine implemented as part of                   @LKA*/
/**********************************************************************/
genc02C0:
parse var datarec 6 usnds_name,            /* parse the data          */
   15 usnds_uname,
  261
 
 
usnds_name = strip(usnds_name)             /* remove blanks           */
usnds_uname = strip(usnds_uname)
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usnds_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usnds_name = 1 then         /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'nonds'                        /*  else seg del: NONDS    */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'nds'                          /* add NDS    keyword      */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if usnds_uname <> ' ' then             /* add UNAME    if needed  */
      cmd = cmd 'uname('dquote(usnds_uname)')'
    else if type = 'alter' then             /* or NOUNAME    if alter */
      cmd = cmd 'nouname'                   /* and needed             */
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user KERB data (02D0):                                     */
/*                                                                    */
/* Build commands for handling the KERB segment in a user profile.    */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the KERB segment information for the user.       */
/*                                                                    */
/*  Note: Entire routine implemented as part of                   @LRA*/
/**********************************************************************/
genc02D0:
parse var datarec 6 uskerb_name,           /* parse the data          */
   15 uskerb_kerb_name,                    /*                     @PTC*/
  256 uskerb_max_life,
  267 uskerb_key_vers,
  271 uskerb_encrypt_des,
  276 uskerb_encrypt_des3,
  281 uskerb_encrypt_desd,
  286 uskerb_encrypt_a128,                 /*                     @M7A*/
  291 uskerb_encrypt_a256,                 /*                     @M7A*/
  295 . ,                                  /* Reserved            @M7A*/
  351 . ,                                  /* KEYFROM ignored     @M7A*/
  359                                      /*                     @M7C*/
 
 
uskerb_name = strip(uskerb_name)           /* remove blanks           */
uskerb_kerb_name = strip(uskerb_kerb_name) /*                     @PTC*/
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd uskerb_name                      /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uskerb_name = 1 then        /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'nokerb'                       /*  else seg del: NOkerb   */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'kerb'                         /* add kerb   keyword      */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if uskerb_kerb_name <> ' ' then    /* add kerbname if needed  @PTC*/
      cmd = cmd 'kerbname('dquote(uskerb_kerb_name)')'      /*    @PTC*/
    else if type = 'alter' then             /* or NOkerbNAME if alter */
      cmd = cmd 'nokerbname'                /* and needed             */
 
    if uskerb_max_life <> ' ' then      /* add maxlife if needed  @PTC*/
      cmd = cmd 'maxlife('uskerb_max_life')'         /*           @PTC*/
    else if type = 'alter' then             /* or NOmaxlife if alter */
      cmd = cmd 'nomaxlife'                /* and needed             */
 
                                           /*                    4@PTD*/
    cmd = cmd 'encrypt('                    /* add encryption options */
                                            /* handle yes/no separately
                                               for better compatibility
                                               with various releases  */
    if uskerb_encrypt_des = 'YES' then
      cmd = cmd 'DES'
    else if uskerb_encrypt_des = 'NO' then
      cmd = cmd 'NODES'
 
    if uskerb_encrypt_des3 = 'YES' then
      cmd = cmd 'DES3'
    else if uskerb_encrypt_des3 = 'NO' then
      cmd = cmd 'NODES3'
 
    if uskerb_encrypt_desd = 'YES' then
      cmd = cmd 'DESD'
    else if uskerb_encrypt_desd = 'NO' then
      cmd = cmd 'NODESD'
 
    if uskerb_encrypt_a128 <> ' ' then do  /*  AES128 if >= z/OS R9
                                               entire section:    @M7A*/
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '/*'
      if uskerb_encrypt_a128 = 'YES' then
        cmd = cmd 'AES128'
      else if uskerb_encrypt_a128 = 'NO' then
        cmd = cmd 'NOAES128'
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '*/'
      end                                  /* end AES128              */
 
    if uskerb_encrypt_a256 <> ' ' then do  /*  AES256 if >= z/OS R9
                                               entire section:    @M7A*/
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '/*'
      if uskerb_encrypt_a256 = 'YES' then
        cmd = cmd 'AES256'
      else if uskerb_encrypt_a256 = 'NO' then
        cmd = cmd 'NOAES256'
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '*/'
      end                                  /* end AES256              */
 
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user PROXY data (02E0):                                    */
/*                                                                    */
/* Build commands for handling the PROXY segment in a user profile.   */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the PROXY segment information for the user.      */
/*                                                                    */
/*  Note: Entire routine implemented as part of                   @LTA*/
/**********************************************************************/
genc02E0:
parse var datarec 6 usproxy_name,          /* parse the data          */
   15 usproxy_ldap_host,
 1039 usproxy_bind_dn,
 2062
 
 
usproxy_name = strip(usproxy_name)         /* remove blanks           */
usproxy_ldap_host = strip(usproxy_ldap_host)
usproxy_bind_dn = strip(usproxy_bind_dn)
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd usproxy_name                     /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.usproxy_name = 1 then       /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'noproxy'                      /*  else seg del: NOPROXY  */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'proxy'                        /* add PROXY  keyword      */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if usproxy_ldap_host <> ' ' then       /* add LDAPHOST if needed  */
      cmd = cmd 'ldaphost('dquote(usproxy_ldap_host)')'
    else if type = 'alter' then             /* or NOLDAPHOST if alter */
      cmd = cmd 'noldaphost'                /* and needed             */
 
    if usproxy_bind_dn <> ' ' then          /* add BINDDN if needed   */
      cmd = cmd 'binddn('dquote(usproxy_bind_dn)')'
    else if type = 'alter' then             /* or NOBINDDN   if alter */
      cmd = cmd 'nobinddn'                  /* and needed             */
 
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user EIM data (02F0):                                      */
/*                                                                    */
/* Build commands for handling the EIM   segment in a user profile.   */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add,     */
/* delete, or modify the EIM   segment information for the user.      */
/*                                                                    */
/*  Note: Entire routine implemented as part of                   @LZA*/
/**********************************************************************/
genc02F0:
parse var datarec 6 useim_name,            /* parse the data          */
   15 useim_ldapprof,
  261 .                                    /*                     @Q5C*/
 
 
useim_name = strip(useim_name)             /* remove blanks           */
useim_ldapprof = strip(useim_ldapprof)
 
cmd = 'altuser'                            /* start ALTUSER command   */
cmd = cmd useim_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.useim_name = 1 then         /* if user being           */
    return                                 /*   deleted do nothing    */
  cmd = cmd 'noeim'                        /*  else seg del: NOEIM    */
  end                                      /* end if delete           */
 
else do                                    /* else not delete         */
  cmd = cmd 'eim'                          /* add EIM    keyword      */
 
  if type = 'alter',                       /* if alter, or if data is */
   | substr(datarec,15) <> ' ' then do     /* present add ( and the   */
    cmd = cmd'('                           /* data:                   */
 
    if useim_ldapprof <> ' ' then          /* add LDAPPROF if needed  */
      cmd = cmd 'ldapprof('useim_ldapprof')'
    else if type = 'alter' then             /* or NOLDAPPROF if alter */
      cmd = cmd 'noldapprof'                /* and needed             */
 
 
    cmd = cmd')'                           /* Add closing )           */
    end                                    /* End alter or data       */
  end                                      /* End not delete          */
call writealt                              /* write the record        */
return
 
/**********************************************************************/
/* Process user CSDATA data (02G1):                                   */
/*                                                                    */
/* Build commands for handling the CSDATA segment in a user profile.  */
/* If the entire user is being deleted we won't generate anything.    */
/* Otherwise, we will build an ALTUSER command on OUTALTn to add or   */
/* modify the CSDATA segment information for the user.                */
/*                                                                    */
/* note: can't delete entire csdata segment, as IRRDBU00 does not     */
/*       produce a type 02G0 record, and thus we don't have a way to  */
/*       tell that one user has a csdata segment and another doesn't. */
/*       We can only tell about individual fields in csdata           */
/*                                                                    */
/*                                         Entire routine added   @M7A*/
/**********************************************************************/
genc02G1:
parse var datarec 6 uscsd_name,            /* parse the data          */
   15 uscsd_type,
   20 uscsd_key,
   53 uscsd_value,
 1153
 
uscsd_name = strip(uscsd_name)             /* remove blanks from name */
uscsd_key = strip(uscsd_key)               /* and key and trailing    */
uscsd_value = strip(uscsd_value,'T')       /* blanks from value       */
/* Question: can we tell if the value should have trailing blanks?    */
 
cmd = 'altuser'                            /* start altuser command   */
cmd = cmd uscsd_name                       /* add userid              */
 
if type = 'delete' then do                 /* if delete               */
  if d.1.ofile.uscsd_name = 1 then
    return                                 /* leave if user deleted   */
  end                                      /* end if delete           */
 
cmd = cmd 'csdata( '                       /* add/alter csdata        */
 
if uscsd_value <> ' ' then do              /* append the key and value*/
  cmd = cmd uscsd_key"("
 
  if uscsd_type = "NUM " then               /* for numeric values,    */
     uscsd_value = strip(substr(uscsd_value,1,9),'L','0') /* strip
                                              leading zeroes but leave
                                              at least one (total
                                              field is 10 digits)     */
 
  else if uscsd_type = "CHAR" then         /* for char data, double   */
     uscsd_value = dquote(uscsd_value)/* any quote and quote it */
 
  cmd = cmd uscsd_value
 
  cmd = cmd")"
  end
 
else do
  cmd = cmd "no"uscsd_key                   /* or negate the key       */
  end
 
cmd = cmd ")"                              /* add ) to end data       */
 
call writealt                              /* write the command       */
return
 
/**********************************************************************/
/* Build commands for DATASET basic data (0400):                      */
/*   For a define operation:                                          */
/*      (1) Build an ADDSD command to file OUTALTn.  We use this file */
/*          as it is processed after the OUTADDn file, and thus we    */
/*          know that any necessary TAPEVOL profiles will exist before*/
/*          an ADDSD for a tape dataset profile is processed.         */
/*      (2) Build a PERMIT command to file OUTALTn to reset the       */
/*          access list to remove the creator.                    @P9A*/
/*      (3) Build an ALTDSD command to file OUTALTn to specify any    */
/*          GLOBALAUDIT options, if necessary.                        */
/*                                                                    */
/*   For an alter operation:                                          */
/*      (1) Build an ALTDSD command to file OUTALTn for all info.     */
/*                                                                    */
/*   For a delete operation:                                          */
/*      (1) Remember this data set is deleted (use variable           */
/*          d.4.ofile.volser.dsname)                                  */
/*          so that we won't build commands later that affect this    */
/*          data set.                                                 */
/*      (2) Build a DELDSD command to file OUTREMn.               @PCA*/
/**********************************************************************/
genc0400:
parse var datarec 6 dsbd_name,             /* parse the data          */
  51 dsbd_vol,
  58 dsbd_generic,
  63 dsbd_create_date,
  74 dsbd_owner_id,
  83 dsbd_lastref_date,
  94 dsbd_lastchg_date,
 105 dsbd_alter_cnt,
 111 dsbd_control_cnt,
 117 dsbd_update_cnt,
 123 dsbd_read_cnt,
 129 dsbd_uacc,
 138 dsbd_grpds,
 143 dsbd_audit_level,
 152 dsbd_grp_id,
 161 dsbd_ds_type,
 169
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec, /*     */
 170 dsbd_level,
 174 dsbd_device_name,
 183 dsbd_gaudit_level,
 192 dsbd_install_data,
 448 dsbd_audit_okqual,
 457 dsbd_audit_faqual,
 466 dsbd_gaudit_okqual,
 475 dsbd_gaudit_faqual,
 484 dsbd_warning,
 489 dsbd_seclevel,
 493 dsbd_notify_id,
 502 dsbd_retention,
 508 dsbd_erase,
 513 dsbd_seclabel,
 521 external_seclevel,
 560
 
dsbd_name = strip(dsbd_name)               /* remove trailing blanks  */
dsbd_vol = strip(dsbd_vol)
 
if type = 'define' then                    /* use appropriate command */
  cmd = 'addsd'
else if type = 'alter' then
  cmd = 'altdsd'
else do
  cmd = 'deldsd'
  d.4.ofile.dsbd_vol.dsbd_name = 1         /*
                                              remember deletion       */
  end
 
cmd = cmd "'"dsbd_name"'"                  /* add quoted dsn to cmd   */
 
if dsbd_vol <> ' ' & dsbd_vol <> '*MODEL' then /* add volser avail    */
  cmd = cmd 'vol('dsbd_vol')'
 
if dsbd_generic = 'YES' then               /* add GENERIC when needed */
  cmd = cmd 'generic'
 
need_correct_owner = 0                     /* init flag to show we
                                              don't need to set real
                                              owner later         @LNA*/
if type <> 'delete' then do                /* if not delete           */
 
  temp_hlq = substr(dsbd_name,1,pos('.',dsbd_name)-1) /* get HLQ @LNA*/
 
  if (temp_hlq = dsbd_owner_id) |,         /* if owner = HLQ or   @LNA*/
     (g.dsdb_owner_id <> 'y') then         /* no possibility of group
                                              vs user conflict,   @LNA*/
    cmd = cmd 'owner('dsbd_owner_id')'     /* add real owner info     */
 
  else do                                  /* else use HLQ as owner
                                              temporarily to      @LNA*/
    cmd = cmd 'owner('temp_hlq')'          /* ensure ADDSD works  @LNA*/
    need_correct_owner = 1                 /* reset owner later   @LNA*/
    end                                    /*                     @LNA*/
 
  cmd = cmd 'uacc('dsbd_uacc')'            /* add uacc                */
 
  cmd = cmd 'audit('                       /* add audit info:         */
  if dsbd_audit_level = 'NONE' then        /*   audit(none)           */
    cmd = cmd'none)'
  else if dsbd_audit_level = 'SUCCESS' then  /* audit(success(xxx))   */
    cmd = cmd'success('dsbd_audit_okqual'))'
  else if dsbd_audit_level = 'FAIL' then     /* audit(failures(xxx))  */
    cmd = cmd'failures('dsbd_audit_faqual'))'
  else if dsbd_audit_level = 'ALL' then do /* else handle "all" case  */
    cmd = cmd'success('dsbd_audit_okqual') ' /* with both success and */
    cmd = cmd'failures('dsbd_audit_faqual'))'/* failure conditions    */
    end                                    /* end audit(all)          */
 
/* can't handle all cases where the same dataset profile exists       */
/* on both systems, but it is TAPE on one system, and non-VSAM on the */
/* other.  Or non-VSAM on one, and VSAM on the other.  This will only */
/* happen if profile name and volser are the same, but type is        */
/* different.  Occurs because we don't consider dstype when comparing */
/* profile names, and because ADDSD/ALTDSD can't specify VSAM or      */
/* NONVSAM, but only MODEL or TAPE.                                   */
 
  if type = 'define',                      /* add MODEL or TAPE if    */
   & (dsbd_ds_type = 'TAPE',               /* appropriate             */
     |dsbd_ds_type = 'MODEL') then
    cmd = cmd dsbd_ds_type
 
  if dsbd_level <= 99 then                 /* add LEVEL if valid      */
    cmd = cmd 'level('right(strip(dsbd_level),2)')'
 
  if type = 'define',                      /* If a volser exists, then*/
   & dsbd_vol <> ' ',                      /* also specify a unit name*/
   & dsbd_vol <> '*MODEL' then do          /* for ADDSD commands      */
     if dsbd_device_name <> ' ' then
       cmd = cmd 'unit('dsbd_device_name')'
     else do                               /*                     @PKC*/
       if dsbd_ds_type <> 'TAPE' then      /* for DASD data sets  @PKA*/
         cmd = cmd 'unit('dasd_unit')'     /* use da value        @PKA*/
       else                                /* else use tape value @PKA*/
         cmd = cmd 'unit('tape_unit')'
       cmd = cmd set_noset                 /* add SET or NOSET    @PJA*/
       end                                 /*                     @PKA*/
 
     end
 
  if type = 'alter' then                   /* for alter, handle       */
    call gaud0400                          /* GLOBALAUDIT now         */
 
  if dsbd_install_data <> ' ' then do      /* add installation data,  */
    cmd = cmd "data("dquote(strip(dsbd_install_data,'T'))")" /*       */
    end
  else if type = 'alter' then               /* or, for alter, add     */
    cmd = cmd 'nodata'                      /* NODATA if none exists  */
 
  if dsbd_warning = 'YES' then              /* Specify WARNING if     */
    cmd = cmd '  warning'                   /* needed, or             */
  else if type = 'alter' then               /* for alter, NOWARNING   */
    cmd = cmd 'nowarning'                   /* if needed              */
 
  if external_seclevel <> '',              /* add seclevel if present */
    &external_seclevel <> '*none' then
    cmd = cmd 'seclevel('strip(external_seclevel)')'
  else if type = 'alter',                  /* for alter delete the    */
    & external_seclevel = '*none' then     /* seclevel when needed    */
    cmd = cmd 'noseclevel'
 
  if dsbd_notify_id <> ' ' then             /* Specify NOTIFY if      */
    cmd = cmd 'notify('dsbd_notify_id')'    /* needed, or             */
  else if type = 'alter' then               /* for alter, NONOTIFY    */
    cmd = cmd 'nonotify'                    /* if needed              */
 
  if dsbd_retention <> 0,                   /* Specify RETPD if       */
   & dsbd_retention <> ' ' then             /* needed, or             */
    cmd = cmd 'retpd('dsbd_retention')'     /* for alter, RETPD(0)    */
  else if type = 'alter' then               /* if needed              */
    cmd = cmd 'retpd(0)'
 
  if dsbd_erase = 'YES' then                /* Specify ERASE if       */
    cmd = cmd '  erase'                     /* needed, or             */
  else if type = 'alter' then               /* for alter, NOERASE     */
    cmd = cmd 'noerase'                     /* if needed              */
 
  say "line5171" dsbd_seclabel
  if dsbd_seclabel <> ' ' then              /* Specify SECLABEL if    */
    cmd = cmd 'seclabel('dsbd_seclabel')'   /* needed, or             */
  else if type = 'alter' then               /* for alter, NOSECLABEL  */
    cmd = cmd 'noseclabel'                  /* if needed              */
 
  end                                       /* end type not delete    */
 
if type <> 'delete' then                    /* if not a delete    @PCA*/
  call writealt                             /*  cmd on OUTALTn        */
else                                        /*                    @PCA*/
  call writerem                             /* del: use OUTREMn   @PCA*/
 
if need_correct_owner then do               /* if need real owner @LNA*/
  cmd = "altdsd '"dsbd_name"' "             /* build ALTDSD       @LNA*/
  cmd = cmd 'owner('dsbd_owner_id')'        /* add real owner     @LNA*/
  if dsbd_vol <> ' ' & dsbd_vol <> '*MODEL' then  /* build rest   @LNA*/
    cmd = cmd 'vol('dsbd_vol')'                              /*   @LNA*/
  if dsbd_generic = 'YES' then                               /*   @LNA*/
    cmd = cmd 'generic'                                      /*   @LNA*/
  call writealt                             /* write the command  @LNA*/
  end
 
if type = 'define' then do                  /* if reset needed    @P9A*/
  cmd = "permit '"dsbd_name"' "             /* build PE RESET     @P9A*/
  if dsbd_vol <> ' ' & dsbd_vol <> '*MODEL' then             /*   @P9A*/
    cmd = cmd 'vol('dsbd_vol')'                              /*   @P9A*/
  if dsbd_generic = 'YES' then                               /*   @P9A*/
    cmd = cmd 'generic'                                      /*   @P9A*/
  cmd = cmd 'reset'                         /* reset access list  @P9A*/
  call writealt                             /* write the command  @P9A*/
  end                                       /* end reset needed   @P9A*/
 
if type = 'define',                         /* if define, and         */
 & (dsbd_gaudit_level = 'SUCCESS',          /* globalaudit needed,    */
   |dsbd_gaudit_level = 'FAIL',
   |dsbd_gaudit_level = 'ALL') then do
    cmd = "altdsd '"dsbd_name"' "           /* build an ALTDSD command*/
    if dsbd_vol <> ' ' & dsbd_vol <> '*MODEL' then
      cmd = cmd 'vol('dsbd_vol')'
    if dsbd_generic = 'YES' then
      cmd = cmd 'generic'
    call gaud0400                           /* fill in globalaudit    */
    call writealt                           /* write the command      */
    end                                     /* end if define and ...  */
 
return
 
/**********************************************************************/
/* Handle GLOBALAUDIT specifications for DATASET profiles             */
/*                                                                    */
/* Add GLOBALAUDIT info to existing command if any globalaudit info   */
/* is needed.                                                         */
/*                                                                    */
/**********************************************************************/
gaud0400:
cmd = cmd 'globalaudit('                  /* add globalaudit keyword  */
if dsbd_gaudit_level = 'NONE' then        /* if no auditing, set      */
  cmd = cmd'none)'                        /* NONE                     */
else if dsbd_gaudit_level = 'SUCCESS' then /* if success,             */
  cmd = cmd'success('dsbd_gaudit_okqual'))'/* set SUCCESS options     */
else if dsbd_gaudit_level = 'FAIL' then     /* if failures,           */
  cmd = cmd'failures('dsbd_gaudit_faqual'))'/* set FAILURES option    */
else if dsbd_gaudit_level = 'ALL' then do /* else all options, set    */
  cmd = cmd'success('dsbd_gaudit_okqual') '  /* both success and      */
  cmd = cmd'failures('dsbd_gaudit_faqual'))' /* failure options       */
  end                                     /* end all options          */
return
 
/**********************************************************************/
/* Process data for DATASET category data(0401):                      */
/*                                                                    */
/* If the profile is being deleted do nothing.                        */
/*                                                                    */
/* Otherwise, build an ALTDSD command to specify ADDCATEGORY or       */
/* DELCATEGORY for the category associated with this record and write */
/* it to file OUTALTn.                                                */
/*                                                                    */
/**********************************************************************/
genc0401:
parse var datarec 6 dscat_name,           /* parse the data           */
   51 dscat_vol,
   58 external_category,
   97
 
dscat_name = strip(dscat_name)             /* remove blanks from name */
dscat_vol = strip(dscat_vol)               /* and from volser         */
external_category = strip(external_category) /* and from category     */
 
if type = 'delete',                       /* leave if profile deleted */
  & d.4.ofile.dscat_vol.dscat_name = 1 then
    return
 
cmd = 'altdsd'                             /* start altuser command   */
cmd = cmd "'"dscat_name"'"                /* add quoted profile name  */
if dscat_vol <> ' ' & dscat_vol <> '*MODEL' then /* add volser if     */
  cmd = cmd 'vol('dscat_vol')'            /* available                */
else if dscat_vol = ' ' then              /* or GENERIC if needed     */
  cmd = cmd 'generic'
if type = 'delete' then                    /* if delete               */
  cmd = cmd 'delcategory('external_category')' /* then use DELCAT     */
else                                       /* Else add/alter          */
  cmd = cmd 'addcategory('external_category')' /* use ADDCAT          */
call writealt                              /* write to OUTALTn        */
return
 
/**********************************************************************/
/* Process dataset conditional access data (0402):                    */
/*                                                                    */
/* Build commands for handling the conditional access list in a       */
/* DATASET profile. If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build a PERMIT command on OUTALTn to add,       */
/* delete, or modify an access list entry.                            */
/**********************************************************************/
genc0402:
parse var datarec 6 dscacc_name,          /* parse the data           */
   51 dscacc_vol,
   58 dscacc_catype,
   67 dscacc_caname,
   76 dscacc_auth_id,
   85 dscacc_access,
   94 dscacc_access_cnt,
  100 dscacc_net_id,                      /*                      @LWA*/
  109 dscacc_cacriteria,                  /*                      @M7A*/
  353                                     /*                      @M7C*/
 
dscacc_name = strip(dscacc_name)          /* remove blanks from name  */
dscacc_vol = strip(dscacc_vol)
 
if type = 'delete',                       /* leave if profile deleted */
  & d.4.ofile.dscacc_vol.dscacc_name = 1 then
    return
 
dscacc_catype = strip(dscacc_catype)      /* remove blanks from data  */
dscacc_caname = strip(dscacc_caname)      /* remove blanks from data  */
dscacc_net_id = strip(dscacc_net_id)      /* remove blanks        @LWA*/
dscacc_cacriteria = strip(dscacc_cacriteria) /* remove blanks     @M7A*/
 
if dscacc_catype = 'APPCPORT' then        /* For WHEN(APPCPORT()) @LWA*/
  if dscacc_net_id <> ' ' then            /* if qualifier exists  @LWA*/
    dscacc_caname = dscacc_net_id'.'dscacc_caname /* qualify name @LWA*/
  else nop
 
else if dscacc_catype = 'SERVAUTH' then   /* for WHEN(SERVAUTH... @M7A*/
  dscacc_caname=dscacc_cacriteria         /* use cacriteria instead of
                                             caname               @M7A*/
 
cmd = 'permit'                            /* start PERMIT command     */
cmd = cmd "'"dscacc_name"'"               /* add quoted profile name  */
if dscacc_vol <> ' ' & dscacc_vol <> '*MODEL' then /* add volser if   */
  cmd = cmd 'vol('dscacc_vol')'           /* available                */
else if dscacc_vol = ' ' then             /* or GENERIC if needed     */
  cmd = cmd 'generic'
cmd = cmd 'id('dscacc_auth_id')'          /* add the user/group id    */
cmd = cmd 'when('dscacc_catype'('         /* add when(class_name(     */
cmd = cmd||dscacc_caname'))'              /* add the when resource    */
if type = 'delete' then                   /* if deleting the entry,   */
  cmd = cmd 'delete'                      /* add DELETE keyword       */
else                                      /* else add ACCESS keyword  */
  cmd = cmd 'access('dscacc_access')'
 
if dscacc_catype = 'SERVAUTH' &,        /* nullify when(servauth) @M7A*/
   FMID.ofile < 'HRF7708' then          /* if ofile < HRF7708     @M7A*/
     cmd = '/*' cmd '*/'                /*                        @M7A*/
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process dataset volumes data (0403):                               */
/*                                                                    */
/* Build ALTDSD command to add or delete an additional volser for     */
/* a DATASET profile. If an entire profile is being deleted, don't    */
/* generate anything.                                                 */
/**********************************************************************/
genc0403:
parse var datarec 6 dsvol_name,           /* parse the data           */
   51 dsvol_vol,
   58 dsvol_vol_name,
   64
 
if dsvol_vol = dsvol_vol_name then        /* skip record if the volume*/
  return                                  /* being added already exists
                                             in the profile           */
 
dsvol_name = strip(dsvol_name)            /* remove blanks from name  */
dsvol_vol = strip(dsvol_vol)
 
cmd = 'altdsd'                            /* start ALTDSD command     */
cmd = cmd "'"dsvol_name"'"                /* add quoted profile name  */
cmd = cmd 'vol('dsvol_vol')'              /* add main volser          */
if type = 'delete' then do                /* if type = delete         */
  if d.4.ofile.dsvol_vol.dsvol_name = 1 then
    return                                /* leave if profile deleted */
  cmd = cmd 'delvol('dsvol_vol_name')'    /* use DELVOL otherwise     */
  end
else                                      /* else not a delete, so    */
  cmd = cmd 'addvol('dsvol_vol_name')'    /* use an ADDVOL            */
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process dataset access list data (0404):                           */
/*                                                                    */
/* Build commands for handling the standard    access list in a       */
/* DATASET profile. If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build a PERMIT command on OUTALTn to add,       */
/* delete, or modify an access list entry.                            */
/**********************************************************************/
genc0404:
parse var datarec 6 dsacc_name,           /* parse the data           */
   51 dsacc_vol,
   58 dsacc_auth_id,
   67 dsacc_access,
   76 dsacc_access_cnt,
   81
 
dsacc_name = strip(dsacc_name)            /* remove blanks from name  */
dsacc_vol = strip(dsacc_vol)
 
if type = 'delete',                       /* leave if profile deleted */
  & d.4.ofile.dsacc_vol.dsacc_name = 1 then
    return
 
cmd = 'permit'                            /* start PERMIT command     */
cmd = cmd "'"dsacc_name"'"                /* add quoted profile name  */
 
if dsacc_vol <> ' ' & dsacc_vol <> '*MODEL' then /* add volser or     */
  cmd = cmd 'vol('dsacc_vol')'            /* GENERIC as appropriate   */
else if dsacc_vol = ' ' then
  cmd = cmd 'generic'
 
cmd = cmd 'id('dsacc_auth_id')'           /* add user/group id        */
if type = 'delete' then                   /* if deleting, add DELETE  */
  cmd = cmd 'delete'
else                                      /* else add access info     */
  cmd = cmd 'access('dsacc_access')'
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process dataset "installation-reserved" data (0405):               */
/*                                                                    */
/* We can't handle this data, since the RACF commands won't process   */
/* it.  So we will just issue a message if it is encountered and is   */
/* not the same between the two files.                                */
/**********************************************************************/
genc0405:
parse var datarec 6 dsinstd_name,         /* parse the data           */
   51 dsinstd_vol,
   58 dsinstd_usr_name,
   67 dsinstd_usr_data,
  323 dsinstd_usr_flag,
  331
 
dsinstd_name = strip(dsinstd_name) /* remove blanks from name         */
dsinstd_name = strip(dsinstd_name) /* remove blanks from volser       */
if type = 'delete',              /* if the prof is being deleted      */
 & d.4.ofile.dsinstd_vol.dsinstd_name = 1 then
   nop                           /* do nothing                        */
else do                          /* else issue msg                    */
  say '****' type 'Dataset' strip(dsinstd_name) 'Vol('dsinstd_vol') ',
    'contains user-data: Name= ',
    dsinstd_usr_name 'Flag=' dsinstd_usr_flag 'Data= ',
    strip(dsinstd_usr_data)
  bumprc = 1                     /* indicate return code to be bumped */
  end                            /* end "else issue msg"              */
return
 
/**********************************************************************/
/* Process dataset DFP data (0410):                                   */
/*                                                                    */
/* Build commands for handling the DFP segment in a                   */
/* DATASET profile. If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an ALTDSD command on OUTALTn to add,      */
/* delete, or modify the DFP data.                                    */
/**********************************************************************/
genc0410:
parse var datarec 6 dsdfp_name,           /* parse the data           */
   51 dsdfp_vol,
   58 dsdfp_resowner,
   66
 
dsdfp_name = strip(dsdfp_name)            /* strip blanks from name   */
dsdfp_vol = strip(dsdfp_vol)
 
if type = 'delete',                       /* leave if profile deleted */
  & d.4.ofile.dsdfp_vol.dsdfp_name = 1 then
    return
 
cmd = 'altdsd'                            /* start ALTDSD command     */
cmd = cmd "'"dsdfp_name"'"                /* add quoted profile name  */
 
if dsdfp_vol <> ' ' & dsdfp_vol <> '*MODEL' then /* add volser or     */
  cmd = cmd 'vol('dsdfp_vol')'            /* GENERIC as appropriate   */
if dsdfp_vol = ' ' then
  cmd = cmd 'generic'
 
if type = 'delete' then                   /* if delete,               */
  cmd = cmd 'nodfp'                       /* use NODFP                */
else do                                   /* else not delete          */
  cmd = cmd 'dfp'                         /* use DFP                  */
 
  if dsdfp_resowner <> ' ' then           /* if resowner exists,      */
    cmd = cmd'(resowner('dsdfp_resowner'))' /* add it to command  */
  else if type = 'alter' then             /* else for an alter add    */
    cmd = cmd'(noresowner))'             /* NORESOWNER               */
 
  end                                     /* end not delete           */
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process dataset TME data (0421):                               @LIA*/
/*                                                                    */
/* Build commands for handling the TME segment in a                   */
/* DATASET profile. If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an ALTDSD command on OUTALTn to add,      */
/* delete, or modify the TME data.                                    */
/*                                                                    */
/* However, we will generate it as a comment since TME should be used */
/* to administer TME info, not RACF commands                          */
/**********************************************************************/
genc0421:                                                      /* @LIA*/
parse var datarec 6 dstme_name,           /* parse the data       @LIA*/
   51 dstme_vol,
   58 dstme_role,
  305 dstme_access_auth,
  314 dstme_cond_class,
  323 dstme_cond_prof,
  569
 
dstme_name = strip(dstme_name)          /* strip blanks           @LIA*/
dstme_vol = strip(dstme_vol)
dstme_access_auth = strip(dstme_access_auth)
dstme_cond_class = strip(dstme_cond_class)
dstme_cond_prof = strip(dstme_cond_prof)
 
if type = 'delete',                   /* leave if profile deleted @LIA*/
  & d.4.ofile.dstme_vol.dstme_name = 1 then
    return
 
cmd = 'altdsd'                            /* start ALTDSD command @LIA*/
cmd = cmd "'"dstme_name"'"                /* add quoted profile   @LIA*/
 
if dstme_vol <> ' ' & dstme_vol <> '*MODEL' then /* add volser or @LIA*/
  cmd = cmd 'vol('dstme_vol')'            /* GENERIC as needed    @LIA*/
if dstme_vol = ' ' then
  cmd = cmd 'generic'
 
cmd = cmd 'tme('                          /* specify TME keyword  @LIA*/
 
if type = 'delete' then                   /* if delete            @LIA*/
  cmd = cmd 'delroles('                   /* then use DELROLES    @LIA*/
else                                      /* Else add/alter       @LIA*/
  cmd = cmd 'addroles( '                  /* use ADDROLES         @LIA*/
 
cmd = cmd || dstme_role':'                /* add the role name    @LIA*/
cmd = cmd || dstme_access_auth':'         /* and access auth      @LIA*/
cmd = cmd || dstme_cond_class':'          /* and cond class       @LIA*/
cmd = cmd || dstme_cond_prof              /* and cond profile     @LIA*/
 
cmd = cmd ')'                             /* close out the paren  @LIA*/
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment    @LIA*/
 
call writealt                             /* write the record     @LIA*/
return                                    /* done                 @LIA*/
 
 
/**********************************************************************/
/* Build commands for general resource profile basic data (0500):     */
/*   For a define operation:                                          */
/*      (1) Build an RDEFINE command to file OUTALTn, except for  @M7C*/
/*          CDT, SECLABEL, CFIELD, and SECDATA.  CDT, SECLABEL,   @M7A*/
/*          and CFIELD go to                                      @M7A*/
/*          OUTADDn; SECDATA goes to OUTSCDn.  This ensures all   @M7A*/
/*          info needed for RDEFINE commands for other classes    @M7A*/
/*          has already been processed                            @M7A*/
/*      (2) Build a PERMIT ... RESET command to reset the access  @P9A*/
/*          list so the creator doesn'e end up in it.             @P9A*/
/*      (3) Build an RALTER command to file OUTADDn to specify any    */
/*          GLOBALAUDIT options, if necessary.                        */
/*   For an alter operation:                                          */
/*      (1) Build an RALTER command to file OUTALTn for all info, @M7C*/
/*          except for CDT class, which goes to OUTSCDn           @M7A*/
/*          and CDT, SECLABEL, and CFIELD that go to OUTADDn      @M7A*/
/*                                                                    */
/*   For a delete operation:                                          */
/*      (1) Remember this profile is deleted (use variable            */
/*          e.ofile.profile_name with values of the class name        */
/*          so that we won't build commands later that affect this    */
/*          profile.                                                  */
/*          (Note: we use this different variable name & content      */
/*          because a compound variable name must be <= 250 chars.)   */
/*      (2) Build a RDELETE command to file OUTALTn. (could we use    */
/*          OUTDELn?)                                                 */
/**********************************************************************/
genc0500:
parse var datarec 6 grbd_name,            /* parse the data           */
 253 grbd_class_name,
 262 grbd_generic,
 267 grbd_class,
 271 grbd_create_date,
 282 grbd_owner_id,
 291 grbd_lastref_date,
 302 grbd_lastchg_date,
 313 grbd_alter_cnt,
 319 grbd_control_cnt,
 325 grbd_update_cnt,
 331 grbd_read_cnt,
 337 grbd_uacc,
 346 grbd_audit_level,
 355 grbd_level,
 359 grbd_gaudit_level,
 367
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec, /*     */
 368 grbd_install_data,
 624 grbd_audit_okqual,
 633 grbd_audit_faqual,
 642 grbd_gaudit_okqual,
 651 grbd_gaudit_faqual,
 660 grbd_warning,
 665 grbd_singleds,
 670 grbd_auto,
 675 grbd_tvtoc,
 680 grbd_notify_id,
 689 grbd_access_sun,
 694 grbd_access_mon,
 699 grbd_access_tue,
 704 grbd_access_wed,
 709 grbd_access_thu,
 713
       /* Break to allow interpretation on TSO/E releases < 2.4       */
parse var datarec, /*     */
 714 grbd_access_fri,
 719 grbd_access_sat,
 724 grbd_start_time,
 733 grbd_end_time,
 742 grbd_zone_offset,
 748 grbd_zone_direct,
 750 grbd_seclevel,
 754 grbd_appl_data,
 1010 grbd_seclabel,
 1018 external_seclevel,
 1057
 
grbd_name = strip(grbd_name)              /* remove blanks from name  */
grbd_class_name = strip(grbd_class_name)
 
If grbd_audit_okqual = 'X<FF>' then
  grbd_audit_okqual = 'READ'              /* special seclabels have
                                             uninitialized audit
                                             qualifiers           @Q3A*/
 
If grbd_audit_faqual = 'X<FF>' then
  grbd_audit_faqual = 'READ'              /* special seclabels have
                                             uninitialized audit
                                             qualifiers           @Q3A*/
 
oldtype = type                            /* save value of type   @PNA*/
 
if grbd_class_name = 'SECLABEL',          /* If seclabel          @PLA*/
 & type = 'define',                       /* and a define of a    @PLA*/
 & (0 <> wordpos(grbd_name,special_seclabels)) then /* canned one @PLA*/
  type = 'alter'                          /* force alter instead  @PLA*/
 
if 0 = wordpos(grbd_class_name,digtclass) then do/*if ^digt class @LLA*/
  if grbd_class_name = 'SECDATA',
   & type = 'define' then do              /* if defining secdata  @PNA*/
    cmd = 'rdefine secdata 'grbd_name     /* build basic rdef on  @PNA*/
    call writescd                         /* OUTSCDn and use ralt @PNA*/
    type = 'alter'                        /* for rest of info     @PNA*/
    end
 
  if type = 'define' then                 /* if define,               */
    cmd = 'rdefine'                       /* build RDEFINE command    */
  else if type = 'alter' then             /* if alter,                */
    cmd = 'ralter'                        /* build RALTER command     */
  else do                                 /* else delete,             */
    cmd = 'rdelete'                       /* build RDELETE command    */
    e.ofile.grbd_name = ,
      e.ofile.grbd_name grbd_class_name           /* track deletion */
    end                                   /* end else delete          */
 
  cmd = cmd grbd_class_name               /* add class name to command*/
  cmd = cmd grbd_name                     /* add profile name         */
 
  if type <> 'delete' then do             /* if not delete,           */
 
    cmd = cmd 'owner('grbd_owner_id')'    /* add OWNER info           */
    cmd = cmd 'uacc('grbd_uacc')'         /* add UACC info            */
 
    cmd = cmd 'audit('                    /* add AUDIT info:          */
    if grbd_audit_level = 'NONE' then     /* if none, add NONE        */
      cmd = cmd'none)'
    else if grbd_audit_level='SUCCESS' then /* if success, add SUCCESS*/
      cmd = cmd'success('grbd_audit_okqual'))'/* and qualifier        */
    else if grbd_audit_level = 'FAIL' then  /* if fail, add FAILURES  */
      cmd = cmd'failures('grbd_audit_faqual'))'/* and qualifier       */
    else if grbd_audit_level = 'ALL' then do /* else audit(all), add  */
      cmd = cmd'success('grbd_audit_okqual') ' /* ALL and qualifiers  */
      cmd = cmd'failures('grbd_audit_faqual'))'
      end                                 /* end audit(all)           */
 
    if grbd_level <= 99 then              /* if level valid add it    */
      cmd = cmd 'level('right(strip(grbd_level),2)')'
 
    if type = 'alter' then                /* for alter, add           */
      call gaud0500                       /* globalaudit if needed    */
 
    if grbd_install_data <> ' ' then do   /* if installation data is  */
      cmd = cmd "data("dquote(strip(grbd_install_data,'T'))")"
      end
    else if type = 'alter' then           /* or, for alter, add NODATA*/
      cmd = cmd 'nodata'                  /* when needed              */
 
    if grbd_warning = 'YES' then          /* add WARNING if set, or   */
      cmd = cmd 'warning'                 /* NOWARNING for alter      */
    else if type = 'alter' then
      cmd = cmd 'nowarning'
 
    if external_seclevel <> '',            /* add seclevel if present */
      &external_seclevel <> '*none' then
      cmd = cmd 'seclevel('strip(external_seclevel)')'
    else if type = 'alter',                /* for alter delete the    */
      & external_seclevel = '*none' then   /* seclevel when needed    */
      cmd = cmd 'noseclevel'
 
    if grbd_class_name = 'TAPEVOL ' then do /* handle tape-specific
                                               operands               */
      if grbd_singleds = 'YES' then       /* add SINGLEDSN if set, or */
        cmd = cmd 'singledsn'             /* NOSINGLEDSN if alter     */
      else if type = 'alter' then
        cmd = cmd 'nosingledsn'
 
      if grbd_tvtoc = 'YES' then          /* add TVTOC if set, or     */
        cmd = cmd 'tvtoc'                 /* NOTVTOC if alter         */
      else if type = 'alter' then
        cmd = cmd 'notvtoc'
 
      end                                 /* end handle tape-specific */
 
    if grbd_notify_id <> ' ' then         /* add NOTIFY if set, or    */
      cmd = cmd 'notify('grbd_notify_id')' /* NONOTIFY if alter       */
    else if type = 'alter' then
      cmd = cmd 'nonotify'
 
    if grbd_class_name = 'TERMINAL' then do /* if TERMINAL class,     */
      if pos('NO',substr(datarec,689,34)) > 0, /* if dates or times set */
       | substr(datarec,724,17) <> ' ' then do
 
        cmd = cmd 'when('                 /* add WHEN( to command     */
        if pos('NO',substr(datarec,689,34)) > 0 then do /* set days if any
                                               are not allowed        */
          cmd = cmd'days('                /* add DAYS( to command     */
                                            /* Next, specify each day that
                                               is allowed:            */
          if grbd_access_sun = 'YES' then cmd = cmd 'sunday'
          if grbd_access_mon = 'YES' then cmd = cmd 'monday'
          if grbd_access_tue = 'YES' then cmd = cmd 'tuesday'
          if grbd_access_wed = 'YES' then cmd = cmd 'wednesday'
          if grbd_access_thu = 'YES' then cmd = cmd 'thursday'
          if grbd_access_fri = 'YES' then cmd = cmd 'friday'
          if grbd_access_sat = 'YES' then cmd = cmd 'saturday'
          cmd = cmd') '                   /* close DAYS( info         */
          end                             /* end set days if ...      */
        else if type = 'alter' then       /* or, for alter, allow all */
          cmd = cmd'days(anyday)'         /* all days                 */
 
        if substr(datarec,724,17) <> ' ' then do /* if times present  */
          cmd = cmd'time('                /* add time info to command */
          cmd = cmd||substr(grbd_start_time,1,2)||,
                substr(grbd_start_time,4,2)":"||,
                substr(grbd_end_time,1,2)||,
                substr(grbd_end_time,4,2)
          cmd = cmd')'
          end                             /* end if times present     */
        else if type = 'alter' then       /* or for alter add anytime */
          cmd = cmd'time(anytime)'
 
        cmd = cmd')'                      /* close WHEN operand       */
        end                               /* end dates/times set      */
      else if type = 'alter' then         /* or for alter set anyday  */
        cmd = cmd 'when(days(anyday) time(anytime))' /* and anytime   */
 
      if grbd_zone_offset <> ' ' then     /* set timezone if needed,  */
        cmd = cmd 'timezone('grbd_zone_direct ||,
              substr(grbd_zone_offset,1,2)'.'||,
              substr(grbd_zone_offset,4,2)')'
      else if type = 'alter' then         /* or for alter set         */
        cmd = cmd 'notimezone'            /* notimezone               */
 
      end                                 /* end if terminal ...      */
 
    if grbd_appl_data <> ' ' then do      /* if appldata present, add */
      cmd = cmd "appldata("dquote(strip(grbd_appl_data,'T'))")"
      end                                 /* end appldata present     */
    else if type = 'alter' then           /* else for alter, add      */
      cmd = cmd 'noappldata'              /* noappldata               */
 
    if grbd_seclabel <> ' ' then          /* if seclabel present,     */
      cmd = cmd 'seclabel('grbd_seclabel')' /* add it                 */
    else if type = 'alter' then           /* else for alter add       */
      cmd = cmd 'noseclabel'              /* noseclabel               */
 
    end                                   /* end not delete           */
 
  if (0 = wordpos(grbd_class_name,,       /* if not secdata or    @PNA*/
      'SECDATA SECLABEL CDT CFIELD ')),   /* seclabel/CDT/CFIELD  @M7C*/
   | type = 'delete' then                 /* if deleting then     @PNA*/
    call writealt                         /* use OUTALTn          @PNA*/
  else do                                 /*                      @M7C*/
    call writeadd                         /* else use OUTADDn     @PNA*/
    if grbd_class_name = 'SECLABEL' then  /* remember SECLABEL    @M7A*/
      SECLABEL.ofile = 1                  /*                      @M7A*/
    else if grbd_class_name = 'CDT' then  /* remember CDT         @M7A*/
      CDT.ofile = 1                       /*                      @M7A*/
    else if grbd_class_name = 'CFIELD' then /* remember CFIELD    @M7A*/
      CFIELD.ofile = 1                    /*                      @M7A*/
    end                                   /*                      @M7A*/
 
 
  if oldtype = 'define' then do           /* if reset needed      @PNA*/
    cmd = "permit"                        /* build PERMIT         @P9A*/
    cmd = cmd grbd_name                   /* add profile name     @P9A*/
    cmd = cmd "class("grbd_class_name")"  /* add class name       @PAA*/
    cmd = cmd "reset"                     /* reset access list    @P9A*/
    call writealt                         /* use ALTFILEn         @PGC*/
    end                                   /* end reset needed     @P9A*/
 
  if oldtype = 'define' then do           /* if define, handle    @PNA*/
                                          /*   globalaudit by using an*/
                                          /*   RALTER command         */
    if grbd_gaudit_level = 'SUCCESS',     /* if globalaudit needed    */
     | grbd_gaudit_level = 'FAIL',
     | grbd_gaudit_level = 'ALL' then do
      cmd = "ralter" grbd_class_name grbd_name /* use RALTER          */
      call gaud0500                       /* add globalaudit info     */
      call writealt                       /* use ALTFILEn         @PGC*/
      end                                 /* end globalaudit needed   */
    end                                   /* end define               */
  end                                     /* end not a digt class @LLA*/
else do
  if grbd_class_name = 'DIGTCERT',       /* if altering a cert    @LLA*/
   & type = 'alter' then do              /* do what we can        @LLA*/
    call parse_certname grbd_name        /* parse cert name       @LLA*/
    cmd = 'racdcert'                     /* start the command     @LLA*/
      cmd = cmd 'SITE'
    if grbd_appl_data = 'irrcerta' then
      cmd = cmd 'CERTAUTH'
    else cmd = cmd 'ID('strip(grbd_appl_data)')'
    cmd = cmd 'ALTER('certserial certissuer')' /* add cert "name" @LLA*/
    if grbd_uacc = 'ALTER' then          /* add the trust status  @LLA*/
      cmd = cmd 'TRUST'
    else if grbd_uacc = 'NONE' then
      cmd = cmd 'NOTRUST'
    else if (grbd_uacc = 'X<C0>',         /*                      @PWC*/
           | grbd_uacc = 'HIGHTRST') then /*                      @PWC*/
      cmd = cmd 'HIGHTRUST'
    call writealt                        /* write the command     @LLA*/
    end
  else
    call nodigtclass                     /*  else issue warning   @LLA*/
  end
return
 
/**********************************************************************/
/* Handle GLOBALAUDIT specifications for general resource profiles.   */
/*                                                                    */
/* Add GLOBALAUDIT info to existing command if any globalaudit info   */
/* is needed.                                                         */
/*                                                                    */
/**********************************************************************/
gaud0500:
cmd = cmd 'globalaudit('                  /* add globalaudit keyword  */
if grbd_gaudit_level = 'NONE' then        /* if no auditing, set      */
  cmd = cmd'none)'                        /* NONE                     */
if grbd_gaudit_level = 'SUCCESS' then     /* if success, set success  */
  cmd = cmd'success('grbd_gaudit_okqual'))'/* and options             */
else if grbd_gaudit_level = 'FAIL' then   /* if fail, set failures    */
  cmd = cmd'failures('grbd_gaudit_faqual'))'/* and options            */
else if grbd_gaudit_level = 'ALL' then do /* else globalaudit(all):   */
  cmd = cmd'success('grbd_gaudit_okqual') ' /* set success and        */
  cmd = cmd'failures('grbd_gaudit_faqual'))'/* failure options        */
  end                                     /* end globalaudit(all)     */
return
 
/**********************************************************************/
/* Process general resource tvtoc data (0501):                        */
/*                                                                    */
/* If the profile is being deleted do nothing.                        */
/*                                                                    */
/* Otherwise, issue messages to warn the user of the discrepancy      */
/* which DBSYNC cannot currently fix.                                 */
/*                                                                    */
/**********************************************************************/
genc0501:
parse var datarec 6 grtvol_name,          /* parse the data           */
  253 grtvol_class_name,
  262 grtvol_sequence,
  268 grtvol_create_date,                 /* null after massage   @P3C*/
  279 grtvol_discrete,
  284 grtvol_intern_name,
  329 grtvol_intern_vols,
  585 grtvol_create_name,
  629
 
grtvol_name = strip(grtvol_name)          /* remove blanks from names */
grtvol_class_name = strip(grtvol_class_name)
 
if type = 'delete' then do                /* if delete                */
  if e.ofile.grtvol_name <> '' then
    if wordpos(grtvol_class_name,e.ofile.grtvol_name) > 0 then
      return                              /* leave if profile deleted */
  end                                     /* end delete               */
else do                                   /* issue messages           */
  say '*** Cannot' type 'TVTOC data for' grtvol_class_name,
    grtvol_name 'file sequence' strip(grtvol_sequence),
    ' on file INDD'3-ofile'.'
    say '    INDD1 record being processed: 'count1
    say '    INDD2 record being processed: 'count2
  if type <> 'delete' then do     /* if not deleting the profile,     */
    say '   Desired data is: Discrete profile = 'grtvol_discrete
    say '                    Internal name = 'strip(grtvol_intern_name)
    say '                    Volume serials = 'strip(grtvol_intern_vols)
    say '                    Create name = 'strip(grtvol_create_name)
    end                                   /* end "not deleting prof"  */
  bumprc = 1                     /* indicate return code to be bumped */
  end                                     /* end "issue messages"     */
 
return
 
/**********************************************************************/
/* Process general resource category data(0502):                      */
/*                                                                    */
/* If the profile is being deleted do nothing.                        */
/*                                                                    */
/* Otherwise, build an RALTER command to specify ADDCATEGORY or       */
/* DELCATEGORY for the category associated with this record and write */
/* it to file OUTALTn.                                                */
/* Exception: for SECLABEL class, write to OUTADDn                    */
/*                                                                    */
/**********************************************************************/
genc0502:
parse var datarec 6 grcat_name,           /* parse the data           */
  253 grcat_class_name,
  262 external_category,
  301
 
if 0 = wordpos(grcat_class_name,digtclass) then do/*if ^dig-class @LLA*/
  grcat_name = strip(grcat_name)          /* remove blanks from names */
  grcat_class_name = strip(grcat_class_name)
  external_category = strip(external_category) /* and from category   */
 
  cmd = 'ralter'                           /* start ralter command    */
  cmd = cmd grcat_class_name              /* add class name           */
  cmd = cmd grcat_name                    /* add profile name         */
 
  if type = 'delete' then do              /* if delete                */
    if e.ofile.grcat_name <> '' then
      if wordpos(grcat_class_name,e.ofile.grcat_name) > 0 then
      return                              /* leave if profile deleted */
    cmd = cmd 'delcategory('external_category')' /* else use DELCAT   */
    end                                   /* end delete               */
  else                                      /* else not a delete,     */
    cmd = cmd 'addcategory('external_category')' /* use ADDCAT        */
 
  if grcat_class_name <> 'SECLABEL' then   /*                     @M7A*/
    call writealt                          /* write to OUTALTn        */
  else do                                  /*                     @M7A*/
    call writeadd                          /* write to OUTADDn    @M7A*/
    SECLABEL.ofile = 1                     /* remember it         @M7A*/
    end                                    /*                     @M7A*/
  end                                     /* end not a digt class @LLA*/
else call nodigtclass                     /* else issue warning   @LLA*/
return
 
/**********************************************************************/
/* Process general resource member data (0503):                       */
/*                                                                    */
/* Build commands for handling member data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the member data.                                 */
/* Except that for SECDATA we will write to OUTSCDn to ensure     @PNA*/
/* it's available when needed                                     @PNA*/
/**********************************************************************/
genc0503:
/* parse general resource member data */
parse var datarec 6 grmem_name,           /* parse the data           */
  253 grmem_class_name,
  262 grmem_member,
  518 grmem_global_acc,
  527 grmem_pads_data,
  536 grmem_vol_name,
  543 grmem_vmevent_data,
  549 grmem_seclevel,
  555 grmem_category,
  560
 
grmem_name = strip(grmem_name)            /* remove blanks from names */
grmem_class_name = strip(grmem_class_name)
grmem_member = strip(grmem_member)
 
cmd = 'ralter'                            /* start RALTER command     */
cmd = cmd grmem_class_name                /* add class name           */
cmd = cmd grmem_name                      /* add profile name         */
 
if type = 'delete' then do                /* if delete                */
  if e.ofile.grmem_name <> '' then
    if wordpos(grmem_class_name,e.ofile.grmem_name) > 0 then
    return                                /* leave if profile deleted */
  cmd = cmd 'delmem('                     /* else use a delmem        */
  end                                     /* end delete               */
else                                      /* else not a delete,       */
  cmd = cmd 'addmem('                     /* so use an addmem         */
 
if grmem_class_name = 'VMEVENT',
 | grmem_class_name = 'VMXEVENT' then do  /* if VMEVENT/VMXEVENT add  */
  cmd = cmd||grmem_member                 /* member name and          */
  cmd = cmd'/'strip(grmem_vmevent_data)   /* data                     */
  end
 
else if grmem_class_name = 'PROGRAM' then do /* if PROGRAM            */
  cmd = cmd||"'"grmem_member"'"           /* add member in quotes     */
  if grmem_vol_name = '******' then       /* if sysres volume,        */
    cmd = cmd"/'******'"                  /* need to quote the volser */
  else
    cmd = cmd'/'strip(grmem_vol_name)     /* else use volser as is    */
  cmd = cmd'/'strip(grmem_pads_data)      /* add NO/PADSCHK data      */
  end                                     /* end if PROGRAM           */
 
else if grmem_class_name = 'SECDATA' then do /* if SECDATA, add       */
  cmd = cmd||grmem_member                 /* member name and          */
  if grmem_name = 'SECLEVEL' then         /* if SECLEVEL profile, add */
    cmd = cmd'/'substr(grmem_seclevel,3,3)/* seclevel info            */
 
  else if grmem_name = 'CATEGORY',        /* don't create command for */
   & grmem_member = ' HWM' then           /* the ' HWM' member of     */
     return                               /* SECDATA CATEGORY         */
  end                                     /* end if SECDATA           */
 
else if grmem_class_name = 'GLOBAL' then do /* if GLOBAL              */
  if grmem_name = 'DATASET' then          /* if DATASET profile add   */
    cmd = cmd||"'"grmem_member"'"         /* add member in quotes     */
  else                                    /* else just add            */
    cmd = cmd||grmem_member               /* member name.             */
  cmd = cmd'/'strip(grmem_global_acc)     /* Add access level         */
  end                                     /* end if GLOBAL            */
 
else                                      /* else "normal" member, so */
  cmd = cmd||grmem_member                 /* just add member name     */
 
cmd = cmd')'                              /* end it with )            */
 
if grmem_class_name <> 'SECDATA' then     /* if not  SECDATA      @PNA*/
  call writealt                           /* write to OUTALTn     @PNA*/
else call writescd                        /* else OUTSCDn         @PNA*/
 
return
 
/**********************************************************************/
/* Process general resource volumes data (0504):                      */
/*                                                                    */
/* Build commands for handling volume data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add or    */
/* delete volume data for this profile.                               */
/**********************************************************************/
genc0504:
parse var datarec 6 grvol_name,           /* parse the data           */
  253 grvol_class_name,
  262 grvol_vol_name,
  268
 
grvol_name = strip(grvol_name)            /* remove blanks from name  */
grvol_class_name = strip(grvol_class_name)
 
if grvol_name = grvol_vol_name then       /* don't process record for */
  return                                  /* "same" volume            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grvol_class_name                /* add class name           */
cmd = cmd grvol_name                      /* add profile name         */
 
if type = 'delete' then do                /* if delete                */
  if e.ofile.grvol_name <> '' then
    if wordpos(grvol_class_name,e.ofile.grvol_name) > 0 then
    return                                /* leave if profile deleted */
  cmd = cmd 'delvol('grvol_vol_name')'    /* else not deleted, so use
                                             delvol                   */
  end                                     /* end if delete            */
 
else                                      /* else not delete, so      */
  cmd = cmd 'addvol('grvol_vol_name')'    /* use addvol               */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource access data (0505):                       */
/*                                                                    */
/* Build commands for handling volume data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build a PERMIT  command on OUTALTn to add,      */
/* delete, or modify the access list for this profile.                */
/**********************************************************************/
genc0505:
parse var datarec 6 gracc_name,           /* parse the data           */
  253 gracc_class_name,
  262 gracc_auth_id,
  271 gracc_access,
  280 gracc_access_cnt,
  285
 
if 0 = wordpos(gracc_class_name,digtclass) then do/*if ^dig-class @LLA*/
  gracc_name = strip(gracc_name)          /* remove blanks from name  */
  gracc_class_name = strip(gracc_class_name)
 
  if type = 'delete' then                 /* leave if profile deleted */
    if e.ofile.gracc_name <> '' then
      if wordpos(gracc_class_name,e.ofile.gracc_name) > 0 then
        return
 
  cmd = 'permit'                          /* start permit command     */
  cmd = cmd gracc_name                    /* add profile name         */
  cmd = cmd 'class('gracc_class_name')'   /* add class name           */
  cmd = cmd 'id('gracc_auth_id')'         /* add user/group id        */
 
  if type = 'delete' then                 /* if delete,               */
    cmd = cmd 'delete'                    /* add delete keyword       */
  else
    cmd = cmd 'access('gracc_access')'    /* else add access info     */
 
  call writealt                           /* write the record         */
  end                                     /* end not a digt class @LLA*/
else call nodigtclass                     /* else issue warning   @LLA*/
return
 
/**********************************************************************/
/* Process general resource installation-reserved data (0506):        */
/*                                                                    */
/* Can't handle this data, as the RACF commands don't handle it.      */
/* Just issue messages to show it was encountered.                    */
/**********************************************************************/
genc0506:
parse var datarec 6 grinstd_name,         /* parse the data           */
  253 grinstd_class_name,
  262 grinstd_usr_name,
  271 grinstd_usr_data,
  527 grinstd_usr_flag,
  535
 
grinstd_name = strip(grinstd_name) /* remove blanks from name         */
grinstd_class_name = strip(grinstd_class_name) /* and class           */
if type = 'delete' then          /* if the prof is being deleted      */
  if e.ofile.grinstd_name <> '' then
    if wordpos(grinstd_class_name,e.ofile.grinstd_name) > 0 then
      return                     /* do nothing                        */
say '****' type 'General resource ' grinstd_class_name,
  strip(grinstd_name) ' contains user-data: Name= ',
  grinstd_usr_name 'Flag=' grinstd_usr_flag 'Data= ',
  strip(grinstd_usr_data)
bumprc = 1                       /* indicate return code to be bumped */
return
 
/**********************************************************************/
/* Process general resource conditional access data (0507):           */
/*                                                                    */
/* Build commands for handling volume data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build a PERMIT  command on OUTALTn to add,      */
/* delete, or modify the access list for this profile.                */
/**********************************************************************/
genc0507:
parse var datarec 6 grcacc_name,          /* parse the data           */
  253 grcacc_class_name,
  262 grcacc_catype,
  271 grcacc_caname,
  280 grcacc_auth_id,
  289 grcacc_access,
  298 grcacc_access_cnt,
  304 grcacc_net_id,                      /*                      @LWA*/
  313 grcacc_cacriteria,                  /*                      @M7A*/
  557                                     /*                      @M7C*/
 
grcacc_name = strip(grcacc_name)          /* remove blanks from name  */
grcacc_class_name = strip(grcacc_class_name)
 
if type = 'delete' then                   /* leave if profile deleted */
  if e.ofile.grcacc_name <> '' then
    if wordpos(grcacc_class_name,e.ofile.grcacc_name) > 0 then
      return
 
grcacc_catype = strip(grcacc_catype)      /* remove blanks from data  */
grcacc_caname = strip(grcacc_caname)      /* remove blanks from data  */
grcacc_net_id = strip(grcacc_net_id)      /* remove blanks        @LWA*/
grcacc_cacriteria = strip(grcacc_cacriteria,'T') /* remove blanks @M7A*/
 
if grcacc_catype = 'APPCPORT' then        /* For WHEN(APPCPORT()) @LWA*/
  if grcacc_net_id <> ' ' then            /* if qualifier exists  @PRC*/
    grcacc_caname = grcacc_net_id'.'grcacc_caname /* qualify name @LWA*/
 
if grcacc_catype = 'SERVAUTH' then        /* use cacriteria asis  @M7A*/
  grcacc_caname = grcacc_cacriteria       /* for SERVAUTH         @M7A*/
else if grcacc_catype = 'CRITERIA' then do/* but more complex for
                                             CRITERIA             @M7A*/
/* grcacc_cacriteria will be criteria=value, so parse it          @M7A*/
  parse var grcacc_cacriteria temp_crit1 '=' temp_crit2 /*        @M7A*/
  grcacc_caname = temp_crit1"("dquote(temp_crit2)")" /*           @M7A*/
  end                                     /*                      @M7A*/
 
cmd = 'permit'                            /* start permit command     */
cmd = cmd grcacc_name                     /* add profile name         */
cmd = cmd 'class('grcacc_class_name')'    /* add class name           */
cmd = cmd 'id('grcacc_auth_id')'          /* add user/group id        */
cmd = cmd 'when('grcacc_catype'('         /* add when(class_name(     */
cmd = cmd||grcacc_caname'))'              /* add when-resource name   */
if type = 'delete' then                   /* if delete, delete entry  */
  cmd = cmd 'delete'
else
  cmd = cmd 'access('grcacc_access')'     /* else set access authority*/
 
if (grcacc_catype = 'SERVAUTH' &,         /* nullify SERVAUTH and @M7A*/
    FMID.ofile < 'HRF7708') |,            /* CRITERIA if ofile    @M7A*/
   (grcacc_catype = 'CRITERIA' &,         /* FMID too low         @M7A*/
    FMID.ofile < 'HRF7730') then
      cmd = '/*' cmd '*/'
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource SESSION data (0510):                      */
/*                                                                    */
/* Build commands for handling SESSION data in a general resource     */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the SESSION data for this profile.               */
/* (Note: A separate command is built for INTERVAL as it could fail   */
/* based on the SETROPTS SESSIONINTERVAL specification.)              */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/**********************************************************************/
genc0510:
parse var datarec 6 grses_name,           /* parse the data           */
  253 grses_class_name,
  262 grses_session_key,
  271 grses_locked,
  276 grses_key_date,
  287 grses_key_interval,
  293 grses_sls_fail,
  299 grses_max_fail,
  305 grses_convsec,
  313
 
grses_name = strip(grses_name)            /* remove blanks from names */
grses_class_name = strip(grses_class_name)
 
if type = 'delete' then do                /* if delete                */
  if e.ofile.grses_name <> '' then
    if wordpos(grses_class_name,e.ofile.grses_name) > 0 then
      return                              /* leave if profile deleted */
                                          /* and don't bother tracking
                                             deletion of session
                                             segment as record 0511 is
                                             never generated.         */
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grses_class_name                /* add class name           */
cmd = cmd grses_name                      /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOSESSION  */
  cmd = cmd 'nosession'
else do                                   /* else need session info:  */
  cmd = cmd "  session("                  /* add SESSION keyword      */
  if grses_session_key <> ' ' then        /* if session key present,  */
    cmd = cmd "sesskey(x'"||,             /* add it                   */
      c2x(substr(grses_session_key,1,8))"')"
  else if type = 'alter' then             /* else for alters, add     */
    cmd = cmd "nosesskey"                 /* nosesskey.               */
  if grses_locked = 'YES' then            /* Locked?                  */
    cmd = cmd "  lock"                    /* add LOCK if so           */
  else                                    /* else add NOLOCK          */
    cmd = cmd "nolock"
  if grses_convsec <> ' ' then            /* if convsec present       */
    cmd = cmd "  convsec("grses_convsec")"  /* add it                 */
  else                                    /* else add NOCONVSEC       */
    cmd = cmd "noconvsec"
  cmd = cmd")"                            /* finish this command and  */
  call writealt                           /* write it to OUTALTn      */
                                          /* then do INTERVAL:        */
  cmd = 'ralter'                          /* start ralter command     */
  cmd = cmd grses_class_name              /* add class name           */
  cmd = cmd grses_name                    /* add profile name         */
  cmd = cmd "session("                    /* add SESSION keyword      */
  if grses_key_interval > 0 then          /* if interval present,     */
    cmd = cmd "interval("grses_key_interval"))" /* add it and finish  */
  else                                    /* else add NOINTERVAL and  */
    cmd = cmd "nointerval)"               /* and finish the command   */
  end                                     /* end else need session... */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource DLF data (0520):                          */
/*                                                                    */
/* Build commands for handling DLF data in a general resource         */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the DLF data for this profile.                   */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/**********************************************************************/
genc0520:
parse var datarec 6 grdlf_name,           /* parse the data           */
  253 grdlf_class_name,
  262 grdlf_retain,
  266
 
grdlf_name = strip(grdlf_name)            /* remove blanks from name  */
grdlf_class_name = strip(grdlf_class_name)
 
if type = 'delete' then do                /* if delete                */
  if e.ofile.grdlf_name <> '' then
    if wordpos(grdlf_class_name,e.ofile.grdlf_name) > 0 then
      return                              /* leave if profile deleted */
  f.ofile.grdlf_name =,                 /* else track seg. deletion */
    f.ofile.grdlf_name grdlf_class_name
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grdlf_class_name                /* add class name           */
cmd = cmd grdlf_name                      /* add profile name         */
 
if type = 'delete' then                   /* if delete add NODLFDATA  */
  cmd = cmd 'nodlfdata'
else do                                   /* else need dlfdata info:  */
  cmd = cmd '  dlfdata'                   /* add DLFDATA keyword      */
  if grdlf_retain <> ' ' then             /* if data to add,          */
    cmd = cmd '(retain('grdlf_retain'))'  /* add it                   */
  else if type = 'alter' then             /* else for alters, add     */
    cmd = cmd '(noretain)'                /* noretain as default      */
  end                                     /* end else need dlfdata... */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource DLF jobnames data (0521):                 */
/*                                                                    */
/* Build commands for handling DLF jobname data in a general resource */
/* profile.         If the entire profile is being deleted, or the    */
/* DLF segment is being deleted, don't generate anything.             */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the DLF jobname data for this profile.           */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/**********************************************************************/
genc0521:
parse var datarec 6 grdlfj_name,          /* parse the data           */
  253 grdlfj_class_name,
  262 grdlfj_job_names,
  270
 
grdlfj_name = strip(grdlfj_name)          /* remove blanks from name  */
grdlfj_class_name = strip(grdlf_class_name)
 
if type = 'delete' then do                /* if delete then leave if
                                             profile or dlfdata segment
                                             were deleted             */
  if e.ofile.grdlfj_name <> '' then
    if wordpos(grdlfj_class_name,e.ofile.grdlfj_name) > 0 then
      return
  if f.ofile.grdlfj_name <> '' then
    if wordpos(grdlfj_class_name,f.ofile.grdlfj_name) > 0 then
       return
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grdlfj_class_name               /* add class name           */
cmd = cmd grdlfj_name                     /* add profile name         */
cmd = cmd 'dlfdata'                       /* add dlfdata keyword      */
 
if type = 'delete' then                   /* if delete, add the       */
  cmd = cmd '(deljobnames('grdlfj_job_names'))'/* deljobnames keyword */
else                                      /* else add the             */
  cmd = cmd '(addjobnames('grdlfj_job_names'))'/* addjobnames keyword */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource STDATA data (0540):                       */
/*                                                                    */
/* Build commands for handling STDATA data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the STDATA data for this profile.                */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/**********************************************************************/
genc0540:
parse var datarec 6 grst_name,            /* parse the data           */
  253 grst_class_name,
  262 grst_user_id,
  271 grst_group_id,
  280 grst_trusted,
  285 grst_privileged,
  290 grst_trace,
  294
 
grst_name = strip(grst_name)              /* remove blanks from name  */
grst_class_name = strip(grst_class_name)
 
if type = 'delete' then                   /* leave if profile deleted */
  if e.ofile.grst_name <> '' then
    if wordpos(grst_class_name,e.ofile.grst_name) > 0 then
      return
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grst_class_name                 /* add class name           */
cmd = cmd grst_name                       /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOSTDATA   */
  cmd = cmd 'nostdata'
else do                                   /* else need stdata info:   */
  cmd = cmd '  stdata'                    /* add STDATA  keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('                          /* add ( before data        */
    if grst_user_id <> ' ' then           /* Add USER info if needed  */
      cmd = cmd 'user('grst_user_id')'
    else if type = 'alter' then           /* else NOUSER if alter &   */
      cmd = cmd 'nouser'                  /* needed                   */
 
    if grst_group_id <> ' ' then          /* Add GROUP info if needed */
      cmd = cmd 'group('grst_group_id')'
    else if type = 'alter' then           /* else NOGROUP if alter &  */
      cmd = cmd 'nogroup'                 /* needed                   */
 
    cmd = cmd 'trusted('grst_trusted')' /* add TRUSTED yes/no         */
    cmd = cmd 'privileged('grst_privileged')' /* add PRIVILEGED yes/
                                                 no                   */
    cmd = cmd 'trace('grst_trace')'       /* add TRACE yes/no         */
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need stdata...  */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource SVFMR data (0550):                        */
/*                                                                    */
/* Build commands for handling STDATA data in a general resource      */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the SVFMR data for this profile.                 */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* (Entire routine added for SVFMR support.)                      @LDA*/
/**********************************************************************/
genc0550:
parse var datarec 6 grsv_name,            /* parse the data           */
  253 grsv_class_name,
  262 grsv_script_name,
  271 grsv_parm_name,
  279
 
grsv_name = strip(grsv_name)              /* remove blanks from name  */
grsv_class_name = strip(grsv_class_name)
 
if type = 'delete' then                   /* leave if profile deleted */
  if e.ofile.grsv_name <> '' then
    if wordpos(grsv_class_name,e.ofile.grsv_name) > 0 then
      return
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grsv_class_name                 /* add class name           */
cmd = cmd grsv_name                       /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOSVFMR    */
  cmd = cmd 'nosvfmr'
else do                                   /* else need svfmr info:    */
  cmd = cmd '  svfmr'                     /* add SVFMR   keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('                          /* add ( before data        */
 
    if grsv_script_name <> ' ' then       /* Add SCRIPT info if needed*/
      cmd = cmd 'scriptname('grsv_script_name')'
    else if type = 'alter' then           /* else NOSCRIPTNAME if     */
      cmd = cmd 'noscriptname'            /* alter and needed         */
 
    if grsv_parm_name <> ' ' then         /* Add PARM info if needed  */
      cmd = cmd 'parmname('grsv_parm_name')'
    else if type = 'alter' then           /* else NOPARMNAME if       */
      cmd = cmd 'noparmname'              /* alter and needed         */
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need svfmr...   */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource certificate data (0208/05080560/61/62):   */
/*                                                                    */
/* Can't really do anything, so just ignore the differences           */
/* and let the earlier messages that DBSYNC will have produced        */
/* suffice for now.                                                   */
/* (Entire routine added for certificate support.)                @LLA*/
/**********************************************************************/
genc0208:                                                      /* @LUA*/
genc0508:                                                      /* @LUA*/
genc0560:
genc0561:
genc0562:
nodigtclass:
 
if ofile = 1 then do
  say '***Cannot handle this certificate data. ',
      'Manual action may be required'
  say '    Record type = 'substr(datarec,1,4)||,
        '  Class = 'substr(datarec,253,8)
  say '    Certificate = 'substr(datarec,6,245)
  say '    INDD1 record being processed: 'count1
  say '    INDD2 record being processed: 'count2
 
  end
 
return
 
 
/**********************************************************************/
/* Process general resource TME data (0570):                      @LIA*/
/*                                                                    */
/* Build commands for handling TME data in a general resource         */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the TME data for this profile.                   */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* We will generate the command as a comment since the TME admin      */
/* should happen via TME commands not RACF commands                   */
/*                                                                    */
/* (Entire routine added for TME  support.)                       @LIA*/
/**********************************************************************/
genc0570:
parse var datarec 6 grtme_name,            /* parse the data          */
  253 grtme_class_name,
  262 grtme_parent,
  508
 
grtme_name = strip(grtme_name)            /* remove blanks from names */
grtme_class_name = strip(grtme_class_name)
grtme_parent = strip(grtme_parent)
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grtme_name <> '' then
    if wordpos(grtme_class_name,e.ofile.grtme_name) > 0 then
      return                              /* return if profile deleted*/
    else
      g.ofile.grtme_name =,
        g.ofile.grtme_name grtme_class_name /* else track segment
                                               deletion           @PZC*/
end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grtme_class_name                /* add class name           */
cmd = cmd grtme_name                      /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOtme      */
  cmd = cmd 'notme'
else do                                   /* else need svfmr info:    */
  cmd = cmd '  tme  '                     /* add TME     keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
    if grtme_parent <> ' ' then           /* Add PARENT info if needed*/
      cmd = cmd 'parent('grtme_parent')'
    else if type = 'alter' then           /* else NOPARENT if         */
      cmd = cmd 'noparent    '            /* alter and needed         */
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need tme...     */
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment        */
 
call writealt                             /* write the record         */
return
 
 
 
/**********************************************************************/
/* Process general resource TME children data (0571):             @LIA*/
/*                                                                    */
/* Build commands for handling TME children data in a general resource*/
/* profile.         If the entire profile is being deleted, or the    */
/* TME segment is being deleted, don't generate anything.             */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the TME children data for this profile.          */
/*                                                                    */
/* Note: will build the command as a comment since TME admin should   */
/* occur via TME not via RACF commands.                               */
/*                                                                    */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* Note: Entire subroutine created for TME support:               @LIA*/
/**********************************************************************/
genc0571:
parse var datarec 6 grtmec_name,          /* parse the data           */
  253 grtmec_class_name,
  262 grtmec_child,
  508
 
 
grtmec_name = strip(grtmec_name)          /* remove blanks from names */
grtmec_class_name = strip(grtmec_class_name)
grtmec_child = strip(grtmec_child)
 
if type = 'delete' then do                /* if delete then leave if
                                             profile or tme segment
                                             were deleted             */
  if e.ofile.grtmec_name <> '' then
    if wordpos(grtmec_class_name,e.ofile.grtmec_name) > 0 then
      return
  if g.ofile.grtmec_name <> '' then                            /* @PZC*/
    if wordpos(grtmec_class_name,g.ofile.grtmec_name) > 0 then /* @PZC*/
       return
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grtmec_class_name               /* add class name           */
cmd = cmd grtmec_name                     /* add profile name         */
cmd = cmd 'tme'                           /* add tme keyword          */
 
if type = 'delete' then                   /* if delete, add the       */
  cmd = cmd '(delchildren('grtmec_child'))'/* delchildren keyword     */
else                                      /* else add the             */
  cmd = cmd '(addchildren('grtmec_child'))'/* addchildren keyword     */
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment        */
 
call writealt                             /* write the record         */
return
 
 
 
/**********************************************************************/
/* Process general resource TME resource data (0572):             @LIA*/
/*                                                                    */
/* Build commands for handling TME resource data in a general resource*/
/* profile.         If the entire profile is being deleted, or the    */
/* TME segment is being deleted, don't generate anything.             */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the TME resource data for this profile.          */
/*                                                                    */
/* Note: will build the command as a comment since TME admin should   */
/* occur via TME not via RACF commands.                               */
/*                                                                    */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* Note: Entire subroutine created for TME support:               @LIA*/
/**********************************************************************/
genc0572:
parse var datarec 6 grtmer_name,          /* parse the data           */
  253 grtmer_class_name,
  262 grtmer_origin_role,
  509 grtmer_prof_class,
  518 grtmer_prof_name,
  765 grtmer_access_auth,
  774 grtmer_cond_class,
  783 grtmer_cond_prof,
 1029
 
 
grtmer_name = strip(grtmer_name)          /* remove blanks from names */
grtmer_class_name = strip(grtmer_class_name)
grtmer_origin_role = strip(grtmer_origin_role)
grtmer_prof_class = strip(grtmer_prof_class)
grtmer_prof_name = strip(grtmer_prof_name)
grtmer_access_auth = strip(grtmer_access_auth)
grtmer_cond_class = strip(grtmer_cond_class)
grtmer_cond_prof = strip(grtmer_cond_prof)
 
if type = 'delete' then do                /* if delete then leave if
                                             profile or tme segment
                                             were deleted             */
  if e.ofile.grtmer_name <> '' then
    if wordpos(grtmer_class_name,e.ofile.grtmer_name) > 0 then
      return
  if g.ofile.grtmer_name <> '' then                            /* @PZC*/
    if wordpos(grtmer_class_name,g.ofile.grtmer_name) > 0 then /* @PZC*/
       return
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grtmer_class_name               /* add class name           */
cmd = cmd grtmer_name                     /* add profile name         */
cmd = cmd 'tme'                           /* add tme keyword          */
 
if type = 'delete' then                   /* if delete, add the       */
  cmd = cmd '(delresource('               /* delresource  keyword     */
else                                      /* else add the             */
  cmd = cmd '(addresource('               /* addresource  keyword     */
 
cmd = cmd || grtmer_origin_role':'        /* add other data           */
cmd = cmd || grtmer_prof_class':'
cmd = cmd || grtmer_prof_name':'
cmd = cmd || grtmer_access_auth':'
cmd = cmd || grtmer_cond_class':'
cmd = cmd || grtmer_cond_prof
 
cmd = cmd '))'                            /* close the parens         */
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment        */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource TME groups data (0573):               @LIA*/
/*                                                                    */
/* Build commands for handling TME groups data in a general resource  */
/* profile.         If the entire profile is being deleted, or the    */
/* TME segment is being deleted, don't generate anything.             */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the TME resource data for this profile.          */
/*                                                                    */
/* Note: will build the command as a comment since TME admin should   */
/* occur via TME not via RACF commands.                               */
/*                                                                    */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* Note: Entire subroutine created for TME support:               @LIA*/
/**********************************************************************/
genc0573:
parse var datarec 6 grtmeg_name,          /* parse the data           */
  253 grtmeg_class_name,
  262 grtmeg_group,
  270
 
 
grtmeg_name = strip(grtmeg_name)          /* remove blanks from names */
grtmeg_class_name = strip(grtmeg_class_name)
grtmeg_group = strip(grtmeg_group)
 
if type = 'delete' then do                /* if delete then leave if
                                             profile or tme segment
                                             were deleted             */
  if e.ofile.grtmeg_name <> '' then
    if wordpos(grtmeg_class_name,e.ofile.grtmeg_name) > 0 then
      return
  if g.ofile.grtmeg_name <> '' then                            /* @PZC*/
    if wordpos(grtmeg_class_name,g.ofile.grtmeg_name) > 0 then /* @PZC*/
       return
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grtmeg_class_name               /* add class name           */
cmd = cmd grtmeg_name                     /* add profile name         */
cmd = cmd 'tme'                           /* add tme keyword          */
 
if type = 'delete' then                   /* if delete, add the       */
  cmd = cmd '(delgroups('                 /* delgroups  keyword       */
else                                      /* else add the             */
  cmd = cmd '(addgroups('                 /* addgroups  keyword       */
 
cmd = cmd || grtmeg_group                 /* add group name           */
 
cmd = cmd '))'                            /* close the parens         */
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment        */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource TME role data (0574):                 @LIA*/
/*                                                                    */
/* Build commands for handling TME role  data in a general resource   */
/* profile.         If the entire profile is being deleted, or the    */
/* TME segment is being deleted, don't generate anything.             */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the TME role data for this profile.              */
/*                                                                    */
/* Note: will build the command as a comment since TME admin should   */
/* occur via TME not via RACF commands.                               */
/*                                                                    */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* Note: Entire subroutine created for TME support:               @LIA*/
/**********************************************************************/
genc0574:
parse var datarec 6 grtmee_name,          /* parse the data           */
  253 grtmee_class_name,
  262 grtmee_role_name,
  509 grtmee_access_auth,
  518 grtmee_cond_class,
  527 grtmee_cond_prof,
  773
 
 
grtmee_name = strip(grtmee_name)          /* remove blanks from names */
grtmee_class_name = strip(grtmee_class_name)
grtmee_role_name = strip(grtmee_role_name)
grtmee_access_auth = strip(grtmee_access_auth)
grtmee_cond_class = strip(grtmee_cond_class)
grtmee_cond_prof = strip(grtmee_cond_prof)
 
if type = 'delete' then do                /* if delete then leave if
                                             profile or tme segment
                                             were deleted             */
  if e.ofile.grtmee_name <> '' then
    if wordpos(grtmee_class_name,e.ofile.grtmee_name) > 0 then
      return
  if g.ofile.grtmee_name <> '' then                            /* @PZC*/
    if wordpos(grtmee_class_name,g.ofile.grtmee_name) > 0 then /* @PZC*/
       return
  end                                     /* end if delete            */
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grtmer_class_name               /* add class name           */
cmd = cmd grtmer_name                     /* add profile name         */
cmd = cmd 'tme'                           /* add tme keyword          */
 
if type = 'delete' then                   /* if delete, add the       */
  cmd = cmd '(delroles('                  /* delroles  keyword        */
else                                      /* else add the             */
  cmd = cmd '(addroles('                  /* addroles  keyword        */
 
cmd = cmd || grtmee_role_name':'          /* add other data           */
cmd = cmd || grtmee_access_auth':'
cmd = cmd || grtmee_cond_class':'
cmd = cmd || grtmee_cond_prof
 
cmd = cmd '))'                            /* close the parens         */
 
cmd = '/' || '*' cmd '*' || '/'           /* make it a comment        */
 
call writealt                             /* write the record         */
return
 
 
/**********************************************************************/
/* Process general resource KERB data (0580):                     @LRA*/
/*                                                                    */
/* Build commands for handling KERB data in a general resource        */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the KERB data for this profile.                  */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* (Entire routine added for KERB  support.)                      @LRA*/
/**********************************************************************/
genc0580:
parse var datarec 6 grkerb_name,           /* parse the data          */
  253 grkerb_class_name,
  262 grkerb_kerb_name,
  503 grkerb_min_life,
  514 grkerb_max_life,
  525 grkerb_def_life,
  536 grkerb_key_vers,
  540 grkerb_encrypt_des,
  545 grkerb_encrypt_des3,
  550 grkerb_encrypt_desd,
  555 grkerb_encrypt_a128,                 /*                     @M7A*/
  560 grkerb_encrypt_a256,                 /*                     @M7A*/
  564                                      /*                     @M7C*/
 
grkerb_name = strip(grkerb_name)          /* remove blanks from names */
grkerb_class_name = strip(grkerb_class_name)
grkerb_kerb_name = strip(grkerb_kerb_name) /*                     @PTC*/
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grkerb_name <> '' then
    if wordpos(grkerb_class_name,e.ofile.grkerb_name) > 0 then
      return                              /* return if profile deleted*/
                                          /*                     3@PZD*/
end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grkerb_class_name               /* add class name           */
cmd = cmd grkerb_name                     /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOkerb     */
  cmd = cmd 'nokerb'
else do                                   /* else need kerb  info:    */
  cmd = cmd 'kerb'                        /* add kerb    keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
    if grkerb_kerb_name <> ' ' then /*Add kerbname info if needed @PTC*/
      cmd = cmd 'kerbname('dquote(grkerb_kerb_name)')' /*         @PTC*/
    else if type = 'alter' then           /* else NOkerbname if       */
      cmd = cmd 'nokerbname'              /* alter and needed         */
 
    if grkerb_min_life <> ' ',            /* handle min tkt life      */
        &  grkerb_min_life <> 0 then
      cmd = cmd 'mintktlfe('grkerb_min_life')'
    else
      cmd = cmd 'nomintktlfe'
 
    if grkerb_max_life <> ' ',            /* handle max tkt life      */
        &  grkerb_max_life <> 0 then
      cmd = cmd 'maxtktlfe('grkerb_max_life')'
    else
      cmd = cmd 'nomaxtktlfe'
 
    if grkerb_def_life <> ' ',            /* handle def tkt life      */
        &  grkerb_def_life <> 0 then
      cmd = cmd 'deftktlfe('grkerb_def_life')'
    else
      cmd = cmd 'nodeftktlfe'
 
    cmd = cmd 'encrypt('                    /* add encryption options */
                                            /* handle yes/no separately
                                               for better compatibility
                                               with various releases  */
    if grkerb_encrypt_des = 'YES' then
      cmd = cmd 'DES'
    else if grkerb_encrypt_des = 'NO' then
      cmd = cmd 'NODES'
 
    if grkerb_encrypt_des3 = 'YES' then
      cmd = cmd 'DES3'
    else if grkerb_encrypt_des3 = 'NO' then
      cmd = cmd 'NODES3'
 
    if grkerb_encrypt_desd = 'YES' then
      cmd = cmd 'DESD'
    else if grkerb_encrypt_desd = 'NO' then
      cmd = cmd 'NODESD'
 
    if grkerb_encrypt_a128 <> ' ' then do  /*  AES128 if >= z/OS R9
                                               entire section:    @M7A*/
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '/*'
      if grkerb_encrypt_a128 = 'YES' then
        cmd = cmd 'AES128'
      else if grkerb_encrypt_a128 = 'NO' then
        cmd = cmd 'NOAES128'
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '*/'
      end                                  /* end AES128              */
 
    if grkerb_encrypt_a256 <> ' ' then do  /*  AES256 if >= z/OS R9
                                               entire section:    @M7A*/
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '/*'
      if grkerb_encrypt_a256 = 'YES' then
        cmd = cmd 'AES256'
      else if grkerb_encrypt_a256 = 'NO' then
        cmd = cmd 'NOAES256'
      if FMID.ofile < 'HRF7740' then
        cmd = cmd '*/'
      end                                  /* end AES256              */
 
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need kerb       */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource PROXY data (0590):                    @LTA*/
/*                                                                    */
/* Build commands for handling PROXY data in a general resource       */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the PROXY data for this profile.                 */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* (Entire routine added for PROXY support.)                      @LTA*/
/**********************************************************************/
genc0590:
parse var datarec 6 grproxy_name,          /* parse the data          */
  253 grproxy_class_name,
  262 grproxy_ldap_host,
 1286 grproxy_bind_dn,
 2309
 
grproxy_name = strip(grproxy_name)         /* remove blanks from names */
grproxy_ldap_host = strip(grproxy_ldap_host)
grproxy_bind_dn = strip(grproxy_bind_dn)
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grproxy_name <> '' then
    if wordpos(grproxy_class_name,e.ofile.grproxy_name) > 0 then
      return                              /* return if profile deleted*/
                                          /*                     3@PZD*/
end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grproxy_class_name              /* add class name           */
cmd = cmd grproxy_name                    /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOproxy    */
  cmd = cmd 'noproxy'
else do                                   /* else need proxy info:    */
  cmd = cmd 'proxy'                       /* add proxy   keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
 
    if grproxy_ldap_host <> ' ' then    /* Add ldaphost info if needed*/
      cmd = cmd 'ldaphost('dquote(grproxy_ldap_host)')'
    else if type = 'alter' then           /* else NOldaphost if       */
      cmd = cmd 'noldaphost'              /* alter and needed         */
 
    if grproxy_bind_dn <> ' ' then        /* Add binddn info if needed*/
      cmd = cmd 'binddn('dquote(grproxy_bind_dn)')'
    else if type = 'alter' then           /* else NObinddn if         */
      cmd = cmd 'nobinddn'                /* alter and needed         */
 
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need proxy      */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource EIM data (05A0):                      @LZA*/
/*                                                                    */
/* Build commands for handling EIM   data in a general resource       */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the EIM   data for this profile.                 */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* (Entire routine added for EIM   support.)                      @LZA*/
/**********************************************************************/
genc05A0:
parse var datarec 6 greim_name,            /* parse the data          */
  253 greim_class_name,
  262 greim_domain_dn,
 1286 greim_enable,
 1291 .,
 1366 greim_local_reg,
 1622 greim_kerbreg,
 1878 greim_x509reg,
 2133                                      /*                      @Q5C*/
 
greim_name  = strip(greim_name)            /* remove blanks from names */
greim_domain_dn  = strip(greim_domain_dn)
greim_local_reg = strip(greim_local_reg)
greim_kerbreg = strip(greim_kerbreg)
greim_x509reg = strip(greim_x509reg)
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.greim_name <> '' then
    if wordpos(greim_class_name,e.ofile.greim_name) > 0 then
      return                              /* return if profile deleted*/
                                        /*                       3@PZD*/
end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd greim_class_name                /* add class name           */
cmd = cmd greim_name                      /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOEIM      */
  cmd = cmd 'noeim'
else do                                   /* else need eim   info:    */
  cmd = cmd 'eim'                         /* add eim     keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
 
    if greim_domain_dn   <> ' ' then    /* Add domaindn info if needed*/
      cmd = cmd 'domaindn('greim_domain_dn')'
    else if type = 'alter' then           /* else NODOMAINDN if       */
      cmd = cmd 'nodomaindn'              /* alter and needed         */
 
    if greim_enable = 'YES' then        /* Add ENABLE/DISABLE         */
      cmd = cmd 'enable'
    else cmd = cmd 'disable'
 
    if greim_local_reg <> ' ' then        /* Add local registry       */
      cmd = cmd 'localregistry('greim_local_reg')'
    else if type = 'alter' then           /* else NOLOCALREGISTRY if  */
      cmd = cmd 'nolocalregistry'         /* alter and needed         */
 
    if greim_kerbreg   <> ' ' then        /* Add Kerb  registry       */
      cmd = cmd 'kerbregistry('greim_kerbreg')'
    else if type = 'alter' then           /* else NOKERBREGISTRY if   */
      cmd = cmd 'nokerbregistry'          /* alter and needed         */
 
    if greim_x509reg   <> ' ' then        /* Add X509  registry       */
      cmd = cmd 'x509registry('greim_x509reg')'
    else if type = 'alter' then           /* else NOX509REGISTRY if   */
      cmd = cmd 'nox509registry'          /* alter and needed         */
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need proxy      */
 
call writealt                             /* write the record         */
return
 
/**********************************************************************/
/* Process general resource CDTINFO data (05C0);                  @M4A*/
/*                                                                    */
/* Build commands for handling CDTINFO data in a general resource     */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTADDn to add,      */
/* delete, or modify the CDTINFO data for this profile.               */
/*                                                                    */
/* (Entire routine added for CDTINFO support.)                    @M4A*/
/**********************************************************************/
genc05C0:
parse var datarec 6 grcdt_name,            /* parse the data          */
  253 grcdt_class_name,
  262 grcdt_posit,
  273 grcdt_maxlength,
  277 grcdt_maxlenx,
  288 grcdt_defaultrc,
  292 grcdt_keyqualifier,
  303 grcdt_group,
  312 grcdt_member,
  321 grcdt_first_alpha,
  326 grcdt_first_natl,
  331 grcdt_first_num,
  336 grcdt_first_spec,
  341 grcdt_other_alpha,
  346 grcdt_other_natl,
  351 grcdt_other_num,
  356 grcdt_other_spec,
  361 grcdt_oper,
  366 grcdt_defaultuacc,
  375 grcdt_raclist,
  386 grcdt_genlist,
  397 grcdt_prof_allow,
  402 grcdt_secl_req,
  407 grcdt_macprocess,
  416 grcdt_signal,
  421 grcdt_case,
  430 grcdt_generic,                       /*                      @M7A*/
  440                                      /*                      @M7C*/
 
grcdt_name  = strip(grcdt_name)            /* remove blanks from names */
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grcdt_name <> '' then
    if wordpos(grcdt_class_name,e.ofile.grcdt_name) > 0 then
      return                              /* return if profile deleted*/
 
  end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grcdt_class_name                /* add class name           */
cmd = cmd grcdt_name                      /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOCDTINFO  */
  cmd = cmd 'nocdtinfo'
else do                                   /* else need cdtinfo:       */
  cmd = cmd 'cdtinfo'                     /* add cdtinfo keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
 
    if grcdt_posit <> ' ' then          /* Add POSIT or NOPOSIT       */
      cmd = cmd 'posit('strip(grcdt_posit)')'
    else cmd = cmd 'noposit'
 
    if grcdt_maxlength <> ' ' then        /* Add MAXLENGTH or NOMAX...*/
      cmd = cmd 'maxlength('strip(grcdt_maxlength)')'
    else if type = 'alter' then
      cmd = cmd 'nomaxlength'
 
    if grcdt_maxlenx   <> ' ' then        /* Add MAXLENX              */
      cmd = cmd 'maxlenx('strip(grcdt_maxlenx)')'
    else if type = 'alter' then
      cmd = cmd 'nomaxlenx'
 
    if grcdt_defaultrc <> ' ' then        /* Add DEFAULTRC            */
      cmd = cmd 'defaultrc('strip(grcdt_defaultrc)')'
    else if type = 'alter' then
      cmd = cmd 'nodefaultrc'
 
    if grcdt_keyqualifier <> ' ' then     /* Add KEYQUALIFIERS        */
      cmd = cmd 'keyqualifiers('strip(grcdt_keyqualifier)')'
    else if type = 'alter' then
      cmd = cmd 'nokeyqualifiers'
 
    if grcdt_group        <> ' ' then     /* Add GROUP                */
      cmd = cmd 'group('strip(grcdt_group)')'
    else if type = 'alter' then
      cmd = cmd 'nogroup'
 
    if grcdt_member       <> ' ' then     /* Add MEMBER               */
      cmd = cmd 'member('strip(grcdt_member)')' /*                @M7C*/
    else if type = 'alter' then
      cmd = cmd 'nomember'
 
    if substr(datarec,321,340) <> ' ' then do /* FIRST?               */
      cmd = cmd 'first('
      if grcdt_first_alpha = 'YES' then
        cmd = cmd 'alpha'
      if grcdt_first_natl  = 'YES' then
        cmd = cmd 'national'
      if grcdt_first_num   = 'YES' then
        cmd = cmd 'numeric'
      if grcdt_first_spec  = 'YES' then
        cmd = cmd 'special'
      cmd = cmd ')'
      end
 
    if substr(datarec,341,360) <> ' ' then do /* OTHER?               */
      cmd = cmd 'other('
      if grcdt_other_alpha = 'YES' then
        cmd = cmd 'alpha'
      if grcdt_other_natl  = 'YES' then
        cmd = cmd 'national'
      if grcdt_other_num   = 'YES' then
        cmd = cmd 'numeric'
      if grcdt_other_spec  = 'YES' then
        cmd = cmd 'special'
      cmd = cmd ')'
      end
 
    if grcdt_oper         <> ' ' then     /* Add OPER                 */
      cmd = cmd 'operations('strip(grcdt_oper)')'
    else if type = 'alter' then
      cmd = cmd 'nooperations'
 
    if grcdt_defaultuacc  <> ' ' then     /* Add DEFAULTUACC          */
      cmd = cmd 'defaultuacc('strip(grcdt_defaultuacc)')'
    else if type = 'alter' then
      cmd = cmd 'nooperations'
 
    if grcdt_raclist      <> ' ' then     /* Add RACLIST              */
      cmd = cmd 'raclist('strip(grcdt_raclist)')'
    else if type = 'alter' then
      cmd = cmd 'noraclist'
 
    if grcdt_genlist      <> ' ' then     /* Add GENLIST              */
      cmd = cmd 'genlist('strip(grcdt_genlist)')'
    else if type = 'alter' then
      cmd = cmd 'nogenlist'
 
    if grcdt_prof_allow   <> ' ' then     /* Add PROFILESALLOWED      */
      cmd = cmd 'profilesallowed('strip(grcdt_prof_allow)')'
    else if type = 'alter' then
      cmd = cmd 'noprofilesallowed'
 
    if grcdt_secl_req     <> ' ' then     /* Add SECLABELSREQUIRED    */
      cmd = cmd 'seclabelsrequired('strip(grcdt_secl_req)')'
    else if type = 'alter' then
      cmd = cmd 'noseclabelsrequired'
 
    if grcdt_macprocess   <> ' ' then     /* Add MACPROCESSING        */
      cmd = cmd 'macprocessing('strip(grcdt_macprocess)')'
    else if type = 'alter' then
      cmd = cmd 'nomacprocessing'
 
    if grcdt_signal       <> ' ' then     /* Add SIGNAL               */
      cmd = cmd 'signal('strip(grcdt_signal)')'
    else if type = 'alter' then
      cmd = cmd 'nosignal'
 
    if grcdt_case         <> ' ' then     /* Add CASE                 */
      cmd = cmd 'case('strip(grcdt_case)')'
    else if type = 'alter' then
      cmd = cmd 'nocase'
 
    if grcdt_generic      <> ' ' then     /* Add GENERIC           @M7A*/
      cmd = cmd 'generic('strip(grcdt_generic)')'            /*    @M7A*/
    else if type = 'alter' then                              /*    @M7A*/
      cmd = cmd 'nogeneric'                                  /*    @M7A*/
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need cdt        */
 
if (FMID.ofile >= 'HRF7709') then do      /* only write record if
                                             output file FMID supports
                                             z/OS R6 or later     @M7C*/
  call writeadd                           /* write the record to the ADD
                                             file to ensure class is
                                             fully defined before we
                                             need to define profiles in
                                             the class                */
  CDT.ofile = 1                           /* remember adding CDT  @M7A*/
  end                                     /*                      @M7A*/
else do                                   /* else nullify cmd     @M7A*/
  cmd = '/*' cmd '*/'                     /*                      @M7A*/
  call writeadd                           /*                      @M7A*/
  end                                     /*                      @M7A*/
 
return
 
/**********************************************************************/
/* Process general resource ICTX data (05D0);                     @M7A*/
/*                                                                    */
/* Build commands for handling ICTX data in a general resource        */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTALTn to add,      */
/* delete, or modify the ICTX  data for this profile.                 */
/* ###Could build commands to OUTADD, OUTDEL, or OUTALT instead.      */
/*                                                                    */
/* (Entire routine added for ICTX support.)                       @M7A*/
/**********************************************************************/
genc05D0:
parse var datarec 6 grictx_name,           /* parse the data          */
  253 grictx_class_name,
  262 grictx_usemap,
  267 grictx_domap,
  272 grictx_mapreq,
  277 grictx_map_timeout,
  282
 
grictx_name  = strip(grictx_name)         /* remove blanks from names */
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grictx_name <> '' then
    if wordpos(grictx_class_name,e.ofile.grcdt_name) > 0 then
      return                              /* return if profile deleted*/
 
  end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grictx_class_name               /* add class name           */
cmd = cmd grictx_name                     /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOICTX     */
  cmd = cmd 'noictx'
else do                                   /* else need ictx:          */
  cmd = cmd 'ictx'                        /* add ictx    keyword      */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
 
    cmd = cmd 'usemap('grictx_usemap')'   /* Add USEMAP               */
 
    cmd = cmd 'domap('grictx_domap')'     /* Add DOMAP                */
 
    cmd = cmd 'maprequired('grictx_mapreq')' /* Add MAPREQUIRD        */
 
    cmd = cmd 'mappingtimeout('right(grictx_map_timeout,4,'0')')' /*
                                          Add 4 digits of
                                          mappingtimeout              */
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need ictx       */
 
if (FMID.ofile >= 'HRF7730') then         /* only write record if
                                             output file FMID supports
                                             z/OS R8 or later     @M7C*/
  call writealt                           /* write the record to the
                                             alter file               */
return
/**********************************************************************/
/* Process general resource CFDEF data (05E0);                    @M7A*/
/*                                                                    */
/* Build commands for handling CFDEF data in a general resource       */
/* profile.         If the entire profile is being deleted, don't     */
/* generate anything.                                                 */
/* Otherwise, we will build an RALTER command on OUTADDn to add,      */
/* delete, or modify the CFDEF data for this profile.                 */
/*                                                                    */
/* (Entire routine added for CFDEF support.)                      @M7A*/
/**********************************************************************/
genc05E0:
parse var datarec 6 grcfdef_name,          /* parse the data          */
  253 grcfdef_class,
  262 grcfdef_type,
  267 grcfdef_maxlen,
  278 grcfdef_maxval,
  289 grcfdef_minval,
  300 grcfdef_first,
  309 grcfdef_other,
  318 grcfdef_mixed,
  323 grcfdef_help,
  579 grcfdef_listhead,
  619 .
 
grcfdef_name  = strip(grcfdef_name)       /* remove blanks from name  */
 
 
if type = 'delete' then do                /* delete?                  */
  if e.ofile.grcfdef_name <> '' then
    if wordpos(grcfdef_class,e.ofile.grcfdef_name) > 0 then
      return                              /* return if profile deleted*/
 
  end
 
cmd = 'ralter'                            /* start ralter command     */
cmd = cmd grcfdef_class                   /* add class name           */
cmd = cmd grcfdef_name                    /* add profile name         */
 
if type = 'delete' then                   /* if delete add NOCfdef    */
  cmd = cmd 'nocfdef'
else do                                   /* else need cdtinfo:       */
  cmd = cmd 'cfdef'                       /* add cfdef keyword        */
  if type = 'alter',                      /* if alter or data exists  */
   | substr(datarec,262) <> ' ' then do
 
    cmd = cmd'('
 
    if grcfdef_maxlen <> ' ' then         /* add maxlen               */
      cmd = cmd 'maxlength('strip(grcfdef_maxlen,'L',0)')'
 
    if grcfdef_maxval <> ' ' then         /* add maxvalue/nomaxvalue  */
      cmd = cmd 'maxvalue('strip(grcfdef_maxval)')'
    else if type = 'alter' then
      cmd = cmd 'nomaxvalue'
 
    if grcfdef_minval <> ' ' then         /* add minvalue/nominvalue  */
      cmd = cmd 'minvalue('strip(grcfdef_minval)')'
    else if type = 'alter' then
      cmd = cmd 'nominvalue'
 
    if grcfdef_first <> ' ' then          /* Add FIRST                */
      cmd = cmd 'first('strip(grcfdef_first)')'
 
    if grcfdef_other <> ' ' then          /* Add OTHER                */
      cmd = cmd 'other('strip(grcfdef_other)')'
 
    if grcfdef_mixed <> ' ' then          /* Add MIXED                */
      cmd = cmd 'mixed('strip(grcfdef_mixed)')'
 
    if grcfdef_help <> ' ' then           /* add HELP                 */
      cmd = cmd "help("dquote(strip(grcfdef_help))")"
    else if type = 'alter' then
      cmd = cmd "help(' ')"
 
    if grcfdef_listhead <> ' ' then       /* add LISTHEAD             */
      cmd = cmd "listhead("dquote(strip(grcfdef_maxval))")"
    else if type = 'alter' then
      cmd = cmd "listhead(' ')"
 
    cmd = cmd')'                          /* add ) after data         */
    end                                   /* end alter or data exists */
  end                                     /* end else need cdt        */
 
if (FMID.ofile >= 'HRF7750') then do      /* only write record if
                                             output file FMID supports
                                             z/OS R10 or later        */
  call writeadd                           /* write the record to the ADD
                                             file to ensure class is
                                             fully defined before we
                                             need to define profiles in
                                             the class                */
  CFDEF.ofile = 1                         /* remember adding CFDEF    */
  end                                     /*                          */
else do                                   /* else nullify cmd         */
  cmd = '/*' cmd '*/'
  call writeadd
  end
 
return
 
 
 
/**********************************************************************/
/* PARSE_CERTNAME:                                                    */
/* Parse the certificate profile name and derive the serial number    */
/* and issuer's DN.  Entire routine added                         @LLA*/
/**********************************************************************/
 
parse_certname:
  arg tcertname
  tcertname = translate(tcertname,' ','4A'x) /* x'4A' --> blank   @Q5A*/
  endsn = pos('.',tcertname)               /* find end of serial num  */
  certserial = 'SERIALNUMBER(',
            || substr(tcertname,1,endsn-1),/* extract serial number   */
            || ')'
  certissuer = 'ISSUERSDN(',
            || dquote(substr(tcertname,endsn+1)),/* and issuer's DN   */
            || ')'
return
 
 
/**********************************************************************/
/* GEN_REVOKE:                                                        */
/* Determine if any revoke/resume operands are needed on the current  */
/* command and generate them.  If necessary, generate multiple        */
/* commands.  On entry, rev_cmd has the base part of the command if   */
/* we need multiple commands.  rev_revdate has the revoke date,       */
/* rev_resdate has the resume date, and today has today's date.       */
/* (Dates in the form yyyymmdd.)                                      */
/* rev_revoke has the revoke flag.                                    */
/*                                                                    */
/* Cases:                                                             */
/*  revoke  revdate resdate             Case  Action                  */
/*  ------  ------- ------------------- ----  ----------------------- */
/*  YES     blank   blank               (1a)  REVOKE                  */
/*  YES     blank   <=today             (2a)  RESUME                  */
/*  YES     blank   >today              (3a)  REVOKE RESUME(date)     */
/*  YES     <=today blank               (1b)  REVOKE                  */
/*  YES     <=today <=revdate           (1c)  REVOKE                  */
/*  YES     <=today >revdate & <=today  (2b)  RESUME                  */
/*  YES     <=today >today              (3b)  REVOKE RESUME(date)     */
/*  YES     >today  blank               (1d)  REVOKE                  */
/*  YES     >today  <=today             (4a)  RESUME REVOKE(date)     */
/*  YES     >today  >today & <revdate   (5)   REVOKE followed by      */
/*                                            RESUME(date) REVOKE(dt) */
/*  YES     >today  >today & >revdate   (6)   can't handle            */
/*  NO      blank   blank               (7a)  RESUME if altering, @Q5C*/
/*                                            else nothing to do  @Q5C*/
/*  NO      blank   <=today             (7b)  RESUME if altering, @Q5C*/
/*                                            else nothing to do  @Q5C*/
/*  NO      blank   >today              (8a)  invalid                 */
/*  NO      <=today blank               (1e)  REVOKE                  */
/*  NO      <=today >revdate & <=today  (2c)  RESUME                  */
/*  NO      <=today >today              (3c)  REVOKE RESUME(date)     */
/*  NO      <=today <=revdate           (1f)  REVOKE                  */
/*  NO      >today  blank               (4b)  RESUME REVOKE(date)     */
/*  NO      >today  <=today             (4c)  RESUME REVOKE(date)     */
/*  NO      >today  >today & <=revdate  (8b)  invalid                 */
/*  NO      >today  >revdate            (9)   REVOKE(date) RESUME(dt) */
/*                                                                    */
/**********************************************************************/
gen_revoke:
 
  save_revdate = substr(rev_revdate,5,2), /* save mm/dd/yy form   @PIA*/
            ||'/'substr(rev_revdate,7,2),
            ||'/'substr(rev_revdate,3,2)
 
  save_resdate = substr(rev_resdate,5,2), /* save mm/dd/yy form   @PIA*/
            ||'/'substr(rev_resdate,7,2),
            ||'/'substr(rev_resdate,3,2)
 
  select                                  /* Determine which case to
                                             process:                 */
 
    when ,                                /* Case 1?                  */
        (  rev_revoke = 'YES',            /*         (1a)             */
         & rev_revdate = ' ',
         & rev_resdate = ' '),
      | (  rev_revoke = 'YES',            /*         (1b)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate = ' '),
      | (  rev_revoke = 'YES',            /*         (1c)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= rev_revdate),
      | (  rev_revoke = 'YES',            /*         (1d)             */
         & rev_revdate > today,
         & rev_resdate = ' '),
      | (  rev_revoke = 'NO',             /*         (1e)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate = ' '),
      | (  rev_revoke = 'NO',             /*         (1f)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= rev_revdate),
    then do                               /* Handle case 1            */
      cmd = cmd 'revoke'                  /* add revoke keyword       */
      end                                 /* end "handle case 1"      */
 
    when ,                                /* Case 2?                  */
        (  rev_revoke = 'YES',            /*         (2a)             */
         & rev_revdate = ' ',
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= today),
      | (  rev_revoke = 'YES',            /*         (2b)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate >= rev_revdate,
         & rev_resdate <= today),
      | (  rev_revoke = 'NO',             /*         (2c)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate >= rev_revdate,
         & rev_resdate <= today),
    then do                               /* Handle case 2            */
      cmd = cmd 'resume'                  /* add resume keyword       */
      end                                 /* end "handle case 2"      */
 
    when ,                                /* Case 3?                  */
        (  rev_revoke = 'YES',            /*         (3a)             */
         & rev_revdate = ' ',
         & rev_resdate > today),
      | (  rev_revoke = 'YES',            /*         (3b)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate > today),
      | (  rev_revoke = 'NO',             /*         (3c)             */
         & rev_revdate <> ' ',            /*                      @Q5C*/
         & rev_revdate <= today,
         & rev_resdate > today),
    then do                               /* Handle case 3            */
      cmd = cmd 'revoke'                  /* add revoke keyword       */
      cmd = cmd 'resume('save_resdate')'  /* add resume + date    @PIC*/
      end                                 /* end "handle case 3"      */
 
    when ,                                /* Case 4?                  */
        (  rev_revoke = 'YES',            /*         (4a)             */
         & rev_revdate > today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= today),
      | (  rev_revoke = 'NO',             /*         (4b)             */
         & rev_revdate > today,
         & rev_resdate = ' '),
      | (  rev_revoke = 'NO',             /*         (4c)             */
         & rev_revdate > today,
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= today),
    then do                               /* Handle case 4            */
      cmd = cmd 'resume'                  /* add resume keyword       */
      cmd = cmd 'revoke('save_revdate')'  /* add revoke + date    @PIC*/
      end                                 /* end "handle case 4"      */
 
    when ,                                /* Case 5?                  */
        (  rev_revoke = 'YES',            /*         (5)              */
         & rev_revdate > today,
         & rev_resdate > today,
         & rev_resdate < rev_revdate),
    then do                               /* Handle case 5            */
      cmd = cmd 'revoke'                  /* add revoke keyword       */
      call writealt                       /* issue cmd so user becomes
                                             revoked                  */
      cmd = rev_cmd                       /* reinitialize cmd         */
      cmd = cmd 'resume('save_resdate')'  /* add resume + date    @PIC*/
      cmd = cmd 'revoke('save_revdate')'  /* add revoke + date    @PIC*/
      end                                 /* end "handle case 5"      */
 
    when ,                                /* Case 6?                  */
        (  rev_revoke = 'YES',            /*         (6)              */
         & rev_revdate > today,
         & rev_resdate > today,
         & rev_resdate > rev_revdate),
    then do                               /* Process case 6           */
      say '>>>Unexpected revoke/resume information found:'
      say '>>>  User is already revoked, has a future revoke date, and',
          'a future resume date greater than the revoke date.'
      say '>>>  Revoke value: 'rev_revoke
      say '>>>  Revoke date:  'save_revdate                 /*    @PIC*/
      say '>>>  Resume date:  'save_resdate                 /*    @PIC*/
      say '>>>  Command being generated: 'rev_cmd
      if ofile <> 's' then do
        say '>>>  Processing input file INDD'3-ofile
        say '>>>  Command group being processed: 'cmdcount
        say '>>>  INDD1 record being processed: 'count1
        say '>>>  INDD2 record being processed: 'count2
        end
      bumprc = 1                          /* indicate rc to be bumped */
      end                                 /* end "Process case 6"     */
 
    when ,                                /* Case 7?                  */
        (  rev_revoke = 'NO',             /*         (7a)             */
         & rev_revdate = ' ',
         & rev_resdate = ' '),
      | (  rev_revoke = 'NO',             /*         (7b)             */
         & rev_revdate = ' ',
         & rev_resdate <> ' ',            /*                      @Q5C*/
         & rev_resdate <= today),
    then do                               /* Handle case 7            */
      if type = 'alter' then              /* if altering,         @Q5C*/
        cmd = cmd 'resume'                /* then RESUME, else
                                             nothing to do here   @Q5C*/
      end                                 /* end "handle case 7"      */
 
    when ,                                /* Case 8?                  */
        (  rev_revoke = 'NO',             /*         (8a)             */
         & rev_revdate = ' ',
         & rev_resdate > today),
      | (  rev_revoke = 'NO',             /*         (8b)             */
         & rev_revdate > today,
         & rev_resdate > today,
         & rev_resdate <= rev_revdate),   /*                      @PFC*/
    then do                               /* Process case 8           */
      say '>>>Unexpected revoke/resume information found:'
      say '>>>  User is not revoked and has inconsistent revoke/resume',
          'dates.'
      say '>>>  Revoke value: 'rev_revoke
      say '>>>  Revoke date:  'save_revdate                 /*    @PIC*/
      say '>>>  Resume date:  'save_resdate                 /*    @PIC*/
      say '>>>  Command being generated: 'rev_cmd
      if ofile <> 's' then do
        say '>>>  Processing input file INDD'3-ofile
        say '>>>  Command group being processed: 'cmdcount
        say '>>>  INDD1 record being processed: 'count1
        say '>>>  INDD2 record being processed: 'count2
        end
      bumprc = 1                          /* indicate rc to be bumped */
      end                                 /* end "process case 8"     */
 
    when ,                                /* Case 9?                  */
        (  rev_revoke = 'NO',             /*         (9)              */
         & rev_revdate > today,
         & rev_resdate > rev_revdate),
    then do                               /* Handle case 9            */
      cmd = cmd 'revoke('save_revdate')'  /* add revoke + date    @PIC*/
      cmd = cmd 'resume('save_resdate')'  /* add resume + date    @PIC*/
      end                                 /* End "handle case 9"      */
 
    otherwise do                          /* Unexpected combination:  */
      say '>>>Unexpected revoke/resume information found:'
      say '>>>  Revoke value: 'rev_revoke
      say '>>>  Revoke date:  'save_revdate                 /*    @PIC*/
      say '>>>  Resume date:  'save_resdate                 /*    @PIC*/
      say '>>>  Command being generated: 'rev_cmd
      if ofile <> 's' then do
        say '>>>  Processing input file INDD'3-ofile
        say '>>>  Command group being processed: 'cmdcount
        say '>>>  INDD1 record being processed: 'count1
        say '>>>  INDD2 record being processed: 'count2
        end
      bumprc = 1                          /* indicate rc to be bumped */
      end                                 /* End "unexpected combo"   */
 
    end                                   /* End select               */
  return                                  /* Return to caller         */
 
/**********************************************************************/
/* Write a record to OUTADDn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTADDn, keeping count of how many are     */
/*     written.                                                       */
/**********************************************************************/
writeadd:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1tadd = out1tadd + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1add = out1add+1                  /* count the output line    */
     outaddcmd1.out1add = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1add >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1add = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outadd1 (stem outaddcmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTADD1'
     drop outaddcmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2tadd = out2tadd + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2add = out2add+1                  /* count the output line    */
     outaddcmd2.out2add = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2add >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2add = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outadd2 (stem outaddcmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTADD2'
     drop outaddcmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
/**********************************************************************/
/* Write a record to OUTALTn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTALTn, keeping count of how many are     */
/*     written.                                                       */
/**********************************************************************/
writealt:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1talt = out1talt + 1                /* count total alt commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1alt = out1alt+1                  /* count the output line    */
     outaltcmd1.out1alt = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1alt >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1alt = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outalt1 (stem outaltcmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTALT1'
     drop outaltcmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2talt = out2talt + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2alt = out2alt+1                  /* count the output line    */
     outaltcmd2.out2alt = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2alt >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2alt = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outalt2 (stem outaltcmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTALT2'
     drop outaltcmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
/**********************************************************************/
/* Write a record to OUTREMn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTREMn, keeping count of how many are     */
/*     written.                                                       */
/**********************************************************************/
writerem:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1trem = out1trem + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1rem = out1rem+1                  /* count the output line    */
     outremcmd1.out1rem = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1rem >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1rem = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outrem1 (stem outremcmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTREM1'
     drop outremcmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2trem = out2trem + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2rem = out2rem+1                  /* count the output line    */
     outremcmd2.out2rem = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2rem >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2rem = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outrem2 (stem outremcmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTREM2'
     drop outremcmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
/**********************************************************************/
/* Write a record to OUTDELn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTDELn, keeping count of how many are     */
/*     written.                                                       */
/**********************************************************************/
writedel:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1tdel = out1tdel + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1del = out1del+1                  /* count the output line    */
     outdelcmd1.out1del = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1del >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1del = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outdel1 (stem outdelcmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTDEL1'
     drop outdelcmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2tdel = out2tdel + 1                /* count total add commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2del = out2del+1                  /* count the output line    */
     outdelcmd2.out2del = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2del >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2del = 0                          /* set line count to 0  @M1M*/
     "execio * diskw outdel2 (stem outdelcmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error  @M1A*/
       call execio_err1 'OUTDEL2'
     drop outdelcmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
/**********************************************************************/
/* Write a record to OUTCLNn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTCLNn, keeping count of how many are     */
/*     written.                                                       */
/*  Entire routine:                                               @LMA*/
/**********************************************************************/
writecln:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1tcln = out1tcln + 1                /* count total cln commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1cln = out1cln+1                  /* count the output line    */
     outclncmd1.out1cln = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1cln >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1cln = 0                          /* set line count to 0      */
     "execio * diskw outcln1 (stem outclncmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error      */
       call execio_err1 'OUTCLN1'
     drop outclncmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2tcln = out2tcln + 1                /* count total cln commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2cln = out2cln+1                  /* count the output line    */
     outclncmd2.out2cln = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2cln >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2cln = 0                          /* set line count to 0      */
     "execio * diskw outcln2 (stem outclncmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error      */
       call execio_err1 'OUTCLN2'
     drop outclncmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
/**********************************************************************/
/* Write a record to OUTSCDn:                                         */
/*                                                                    */
/* (1) Split the command into  "maxlen" size pieces, where the first  */
/*     piece has some header info.                                    */
/* (2) Write the pieces to OUTSCDn, keeping count of how many are     */
/*     written.                                                       */
/*  Entire routine:                                               @PNA*/
/**********************************************************************/
writescd:
 call splitcmd                            /* split the command        */
 if ofile = 1 then do                     /* if file 1                */
   out1tscd = out1tscd + 1                /* count total scd commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out1scd = out1scd+1                  /* count the output line    */
     outscdcmd1.out1scd = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out1scd >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out1scd = 0                          /* set line count to 0      */
     "execio * diskw outscd1 (stem outscdcmd1." /* write them to file */
     if rc <> 0 then                /* terminate if execio error      */
       call execio_err1 'OUTSCD1'
     drop outscdcmd1.                     /* delete the output lines  */
     end                                  /* end if we've created...  */
   end                                    /* end if file 1            */
 else if ofile = 2 then do                /* else file 2              */
   out2tscd = out2tscd + 1                /* count total scd commands */
   do i = 1 to split_cmd.0                /* loop through pieces      */
     out2scd = out2scd+1                  /* count the output line    */
     outscdcmd2.out2scd = split_cmd.i     /* copy piece to output line*/
     end                                  /* end loop through pieces  */
   if out2scd >= ExecioOutCount then do   /* if we've created enough
                                             output lines             */
     out2scd = 0                          /* set line count to 0      */
     "execio * diskw outscd2 (stem outscdcmd2." /* write them to file */
     if rc <> 0 then                /* terminate if execio error      */
       call execio_err1 'OUTSCD2'
     drop outscdcmd2.                     /* delete the output lines  */
     end                                  /* end if we've created     */
   end                                    /* end file 2               */
 return
 
 
/**********************************************************************/
/* Split a command:                                                   */
/*                                                                    */
/* This routine will take the command that has been created and       */
/* reformat it for inclusion in a REXX exec.  The command will have   */
/* any inner double quotes (") doubled, and will then be placed into  */
/* a set of double quotes.  It will have a header added that will     */
/* show which command number it is, and what input records it was     */
/* generated from.  The command will also be split into pieces no     */
/* larger than 255 bytes to ensure that the resulting REXX exec can   */
/* be edited by PDF Edit.                                             */
/**********************************************************************/
splitcmd:
  cmdx = cmd                              /* save copy of command     */
 
  scanstart = pos('"',cmd)                /* find first " in command  */
  do while scanstart > 0                  /* loop while " found       */
    cmd = insert('"',cmd,scanstart)       /* double the "             */
    scanstart = scanstart + 2             /* bump past the added "    */
    if scanstart > length(cmd) then       /* if past end of command   */
      scanstart = 0                       /* terminate the loop,      */
    else
      scanstart = pos('"',cmd,scanstart)  /* else find next "         */
    end                                   /* end loop while ...       */
                                          /* now all " characters have
                                             been doubled in the
                                             original command         */
  drop split_cmd.                         /* drop previous commands   */
  splitcnt = 0                            /* init line count          */
  splitblanks = ''                        /* set no indent for first
                                             line                     */
  if ofile <> 's',                        /* if outputting to file    */
   & cmdcount > 0 then                    /* and done with file prefix*/
     cmd = ,
        '/*'cmdcount':'count1':'count2'*/ "'cmd /* add header to cmd  */
  do while length(cmd) > 0                /* loop until done with cmd */
    splitcnt = splitcnt + 1               /* bump the line count      */
    if length(cmd) > maxlen then do       /* if command is too long   */
      blankpos = lastpos(' ',substr(cmd,1,min(maxlen,length(cmd))))/*
                                             find last blank in first
                                             part of command so we can
                                             try to split at a blank  */
      if blankpos = 0 then                /* if no blanks found, split*/
        blankpos = maxlen                 /* at position "maxlen"     */
      do while substr(cmd,blankpos,1) = '"' & blankpos > 1 /* backup if
                                             necessary, so we don't
                                             split on a " character   */
        blankpos = blankpos - 1
        end                               /* end backup it ...        */
      if substr(cmd,blankpos,1) = '"' then do /* if we couldn't avoid a
                                             " character, skip this
                                             command and issue message*/
        bumprc = 1                        /* indicate to bump rc by 4 */
        say ">>>unable to create command due to excessive double quotes"
        say ">>>"cmdx
        split_cmd.splitcnt =,
          '/* command' cmdcount 'skipped due to error */'
        return
        end                               /* end if we couldn't...    */
      end                                 /* end if command too long  */
    else
      blankpos = length(cmd)              /* else (cmd not too long) so
                                             use entire command       */
 
    if blankpos < length(cmd) then        /* if more to do,           */
      ls = '"||,'                         /* prepare for split lines  */
    else
      ls = '"'                            /* else prepare to end cmd  */
 
    if ofile <> 's',                      /* if outputting to file    */
     & cmdcount > 0,                      /* and done with file prefix*/
     & splitcnt = 1 then                  /* and processing the first
                                             line for this command    */
        split_cmd.1 = substr(cmd,1,blankpos)ls /* create 1st split    */
    else                                  /* else (file prefix, or
                                             outputting to stem or
                                             additional line for cmd
                                             indent command if needed */
      split_cmd.splitcnt = splitblanks'"'substr(cmd,1,blankpos)ls
 
    if blankpos < length(cmd) then        /* if more to do,           */
      cmd = substr(cmd,blankpos+1)        /* delete first part of cmd */
    else                                  /* else done with cmd, so   */
      cmd = ''                            /* nullify it to end loop   */
    splitblanks = '  '                    /* set indent for next line */
    end                                   /* end loop until done      */
 
  cmd = cmdx                              /* restore command in case
                                             caller needs it          */
  split_cmd.0 = splitcnt                  /* indicate how many stems
                                             were used                */
  return
 
/********************************************************************/
/* Dquote: routine to double the quotes in a string and return the  */
/* string with quotes around it                                     */
/********************************************************************/
dquote:
  parse arg string                       /* get argument            */
  scanstart = pos("'",string)            /* find first quote        */
  do while scanstart > 0                 /* loop if quote found     */
    string = insert("'",string,scanstart)/* double the quote        */
    scanstart = scanstart + 2            /* bump past quotes        */
    if scanstart > length(string) then   /* If past end of arg      */
      scanstart = 0                      /* stop the loop           */
    else                                 /* else find the           */
      scanstart = pos("'",string,scanstart)/* next quote if any     */
    end                                  /* end loop if quote       */
  return "'"string"'"                   /* return quoted string     */
 
/********************************************************************/
/* setdumu: routine to determine the proper dummy group for a       */
/* user and return the group name as a string                       */
/*                                                                  */
/* Entire routine:                                              @LMA*/
/********************************************************************/
setdumu:
 
  if dummyucnt < dummygmaxu then do/* if room in this group         */
    dummygroup = dummygbase || ,
      substr(dummygsuf,dummyunum,1)/* build its group name          */
    end
 
  else do                          /* use next dummy group          */
    newgroup = 0
    dummyunum = dummyunum + 1      /*   set group number            */
    dummyucnt = 0                  /* no users in this group        */
    if dummyunum > dummygtot then do /* if new group needed         */
      dummygtot = dummygtot + 1      /* bump group number           */
      newgroup = 1                   /* remember new group needed   */
      if dummygtot > length(dummygsuf) then do /* if out of suffixes*/
        say '>>> Error: Ran out of dummy group names. ',
          'Increase DUMMYGMAXU if possible' /* complain             */
        signal errdone                    /* quit                   */
        end                               /*                        */
      end
 
    dummygroup = dummygbase || ,     /* build new group name        */
      substr(dummygsuf,dummyunum,1)
    if newgroup = 1 then do          /* if need to add the group    */
      dcmd.1 = '/*'cmdcount':'count1':'count2'*/',
        || '"ADDGROUP' dummygroup dummyguniv ,     /*           @LYC*/
        || '" /* ADD TEMPORARY DUMMY GROUP */'/* build cmd to add the
                                                 dummy group        */
 
      "execio * diskw outrem1 (stem dcmd." /* write cmd to remfiles */
      if rc <> 0 then
        call execio_err1 'OUTREM1'      /* terminate if execio err  */
 
      out1trem = out1trem +1            /* count this command   @LMA*/
 
      "execio * diskw outrem2 (stem dcmd."
      if rc <> 0 then
        call execio_err1 'OUTREM2'      /* terminate if execio err  */
 
      out2trem = out2trem +1            /* count this command   @LMA*/
 
      drop dcmd.
      end
    end
  dummyucnt = dummyucnt + 1           /* bump member count          */
 
  return dummygroup                   /* return dummy group name    */
 
/********************************************************************/
/* setdumg: routine to determine the proper dummy group to use as a */
/* supgroup and return the group name as a string                   */
/*                                                                  */
/* Entire routine:                                              @LMA*/
/********************************************************************/
setdumg:
 
  if dummygcnt < dummygmaxs then do/* if room in this group         */
    dummygroup = dummygbase || ,
      substr(dummygsuf,dummygnum,1) /* build its group name         */
    end
 
  else do                          /* start a new dummy group       */
    newgroup = 0
    dummygnum = dummygnum + 1      /*   set group number            */
    dummygcnt = 0                  /* no subgroups assigned yet     */
    if dummygnum > dummygtot then do /* if new group needed         */
      dummygtot = dummygtot + 1    /* count new group               */
      newgroup = 1                 /* remember we're creating one   */
      if dummygtot > length(dummygsuf) then do/* if no suffixes left*/
        say '>>> Error: Ran out of dummy group names. ',
          'Increase DUMMYGMAXS if possible' /* complain             */
        signal errdone                    /* quit                   */
        end                               /*                        */
      end
 
    dummygroup = dummygbase || ,     /* build new group name        */
      substr(dummygsuf,dummygnum,1)
    if newgroup = 1 then do          /* build new group if needed   */
      dcmd.1 = '/*'cmdcount':'count1':'count2'*/',
        || '"ADDGROUP' dummygroup dummyguniv ,     /*           @LYC*/
        || '" /* ADD TEMPORARY DUMMY GROUP */'/* build cmd to add the
                                                 dummy group        */
 
      "execio * diskw outrem1 (stem dcmd." /* write cmd to remfiles */
      if rc <> 0 then
        call execio_err1 'OUTREM1'      /* terminate if execio err  */
 
      out1trem = out1trem +1            /* count this command   @LMA*/
 
      "execio * diskw outrem2 (stem dcmd."
      if rc <> 0 then
        call execio_err1 'OUTREM2'      /* terminate if execio err  */
 
      out2trem = out2trem +1            /* count this command   @LMA*/
 
      drop dcmd.
      end
    end
  dummygcnt = dummygcnt + 1           /* bump subgroup count        */
 
  return dummygroup                   /* return dummy group name    */
 
 
/********************************************************************/
/* initialize some variables                                        */
/********************************************************************/
InitVars:
DBsyncName = 'DBSync Revision 2.5-Q7C'   /* Program name/revision @Q7C*/
maxlen = 210    /* maximum amount of command data on a line of output */
today = date('S') /* today's date in yyyymmdd form                @PIC*/
bumprc = 0      /* 1 = event occurred that should add 4 to return code*/
out1add = 0     /* number of records waiting to be written to outadd1 */
out2add = 0     /* number of records waiting to be written to outadd2 */
out1alt = 0     /* number of records waiting to be written to outalt1 */
out2alt = 0     /* number of records waiting to be written to outalt2 */
out1del = 0     /* number of records waiting to be written to outdel1 */
out2del = 0     /* number of records waiting to be written to outdel2 */
out1rem = 0     /* number of records waiting to be written to outrem1 */
out2rem = 0     /* number of records waiting to be written to outrem2 */
out1cln = 0     /* number of records waiting to be written
                   to outcln1                                     @LMA*/
out2cln = 0     /* number of records waiting to be written
                   to outcln2                                     @LMA*/
out1scd = 0     /* number of records waiting to be written
                   to outscd1                                     @PNA*/
out2scd = 0     /* number of records waiting to be written
                   to outscd2                                     @PNA*/
out1tadd = 0    /* total number of commands written to outadd1        */
out2tadd = 0    /* total number of commands written to outadd2        */
out1talt = 0    /* total number of commands written to outalt1        */
out2talt = 0    /* total number of commands written to outalt2        */
out1tdel = 0    /* total number of commands written to outdel1        */
out2tdel = 0    /* total number of commands written to outdel2        */
out1trem = 0    /* total number of commands written to outrem1        */
out2trem = 0    /* total number of commands written to outrem2        */
out1tcln = 0    /* total number of commands written to outcln1    @LMA*/
out2tcln = 0    /* total number of commands written to outcln2    @LMA*/
out1tscd = 0    /* total number of commands written to outscd1    @PNA*/
out2tscd = 0    /* total number of commands written to outscd2    @PNA*/
count1 = 0      /* number of records read from indd1                  */
count2 = 0      /* number of records read from indd2                  */
cmdcount = 0    /* number of command-sets generated                   */
read1  = 1      /* 1 = need to read a record from indd1               */
read2  = 1      /* 1 = need to read a record from indd2               */
dd1rc=0         /* return code from last execio to indd1              */
dd2rc=0         /* return code from last execio to indd2              */
done1 = 0       /* 1 = all indd1 records have been processed          */
done2 = 0       /* 1 = all indd2 records have been processed          */
eofmsg1 = 0     /* 1 = message about eof on INDD1 has been issued     */
eofmsg2 = 0     /* 1 = message about eof on INDD2 has been issued     */
i1 = 0          /* number of indd1 records read but not yet processed */
i2 = 0          /* number of indd2 records read but not yet processed */
d1.0 = 0        /* number of indd1 records read on last execio        */
d2.0 = 0        /* number of indd2 records read on last execio        */
selecting = 0   /* no selection (include/exclude) options specified   */
including = 0   /* no include options specified                       */
excluding = 0   /* no exclude options specified                       */
d. = 0          /* stem for recording deleted profiles and segments   */
e. = ''         /* stem for recording deleted profiles and segments   */
f. = ''         /* stem for recording deleted profiles and segments   */
g. = ''         /* stem for detecting user vs group name
                   conflicts                                      @LNA*/
resetdflt. = '' /* stem for recording users whose dfltgrps were reset
                   to dummygroup during remove processing and should
                   be reset to the right dfltgrp if possible          */
dummygbase = strip(substr(dummygroup,1,7)) /* truncate dummygroup to
                   7 characters if needed, and remove trailing
                   blanks                                         @LMA*/
                /* initialize vars for dummygroup processing:     @LMA*/
dummygtot   = 0 /* number of dummygroups generated                @LMA*/
dummygsuf = ,   /* suffixes for dummy groups                      @LMA*/
  '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ$#@'  /*                   @LMA*/
dummyguniv = ''    /* default dummy groups to non-UNIVERSAL       @LYA*/
dummygmaxu  = 1000 /* max number of users per dummygroup          @LMA*/
dummygmaxs  = 1000 /* max number of subgroups per dummy group     @LMA*/
dummyucnt   = dummygmaxu /* number of entries in current dumgrp   @LMA*/
dummygcnt   = dummygmaxs /* number of subgroups of curr  dumgrp   @LMA*/
dummyunum   = 0          /* current dummy group for users         @LMA*/
dummygnum   = 0          /* current dummy group for subgroups     @LMA*/
 
digtclass = 'DIGTCERT DIGTRING DIGTNMAP '  /* digital cert
                                  classes that we can't generate
                                  commands for                    @LLA*/
 
special_seclabels = 'SYSHIGH SYSLOW SYSNONE SYSMULTI ' /* special
                                  SECLABELs created by RACF for which
                                  we must use
                                  RALTER not RDEFINE when one input
                                  DB is empty                     @Q1C*/
 
special_groups = 'SYS1 SYSCTLG VSAMDSET ' /* special groups
                                  created by RACF, so we must use
                                  ALTGROUP not ADDGROUP when one input
                                  DB is empty                     @PMA*/
 
 
RecMsgCount = 1000 /* Issue a "processing record" message every
                      1000 records on each of INDD1 and INDD2         */
ExecioInCount = 100 /* Read this many records at a time from INDDn    */
ExecioOutCount = 100 /* Write to output files after this many lines of
                        output exist for a file                       */
FMID.1  = 'HRF7750'  /* FMID for ofile 1                          @M7C*/
FMID.2  = 'HRF7750'  /* FMID for ofile 2                          @M7C*/
CDT.1   = 0          /* Any CDT defined for ofile 1?              @M7A*/
CDT.2   = 0          /* Any CDT defined for ofile 2?              @M7A*/
CFDEF.1 = 0          /* Any CFDEF defined for ofile 1?            @M7A*/
CFDEF.2 = 0          /* Any CFDEF defined for ofile 2?            @M7A*/
SECLABEL.1 = 0       /* Any SECLABEL defined for ofile 1?         @M7A*/
SECLABEL.2 = 0       /* Any SECLABEL defined for ofile 2?         @M7A*/
 
return
 
/**********************************************************************/
/* Try to detect improper upload to host                          @LFA*/
/**********************************************************************/
ValidateUpload:                          /*                       @LFA*/
 
  troublechars = '|'                     /* char forms of some
                                            troublesome chars     @LFA*/
  troublehex   = '4F'x                   /* hex forms of some
                                            troublesome chars     @LFA*/
 
  if troublechars \== troublehex then do /* upload problems?      @LFA*/
    say '>>DBSYNC exec appears to have been uploaded' /*  yes     @LFA*/
    say '>>  to the host using incorrect character'   /*          @LFA*/
    say '>>  translation.  Terminating.'              /*          @LFA*/
    say '>>If you need assistance with this problem please' /*    @PVA*/
    say '>>  post a message to the RACF-L mailing list with'/*    @PVA*/
    say '>>  DBSYNC in the subject line.'                   /*    @PVA*/
    say '>>Describe the error, including any error messages,'/*   @PVA*/
    say '>>  and mention the DBSYNC level you are running,' /*    @PVA*/
    say '>>  'DBsyncName                                    /*    @PVA*/
    say '>> '                                               /*    @PVA*/
    say '>>If you need information about RACF-L please see' /*    @PVA*/
    say '>>  the documentation supplied with DBSYNC or visit'/*   @PVA*/
    say '>>  http://www-1.ibm.com/servers/eserver/zseries/'||,/*  @PVA*/
        'zos/racf/racf-l.html'                              /*    @PVA*/
 
    exit 12
    end                                  /*                       @LFA*/
  else return                            /* no.. back to mainline @LFA*/
/**********************************************************************/
/* Handle execio output errors:                                       */
/*   Issue error message and signal errdone to close files            */
/**********************************************************************/
execio_err1:
  say '>>>Failure occurred writing to output file 'arg(1)
  signal errdone
 
/**********************************************************************/
/* Handle SYNTAX error condition:                                     */
/*   Issue error message and close files                              */
/**********************************************************************/
syntax: say '>>>SYNTAX raised at line 'sigl
  if sourceline() <> 0 then
    say '>>>Source line is: 'sourceline(sigl)
  signal errdone
/**********************************************************************/
/* Handle NOVALUE error condition:                                    */
/*   Issue error message and close files                              */
/**********************************************************************/
novalue: say '>>>NOVALUE raised at line 'sigl
  parse version . langlevel .
  if langlevel > 3.45 then
    say '>>>Field in error is: 'condition('D')
  if sourceline() <> 0 then
    say '>>>Source line is: 'sourceline(sigl)
errdone:
  say ' '
  say '>>>Command group being processed: 'cmdcount
  say '>>>INDD1 record being processed: 'count1
  say '>>>INDD2 record being processed: 'count2
  say '>>> '
  say '>>>Processing did NOT complete successfully'
  say '>> '                                                /*    @PVA*/
  say '>> If you need assistance with this problem please' /*    @PVA*/
  say '>>   post a message to the RACF-L mailing list with'/*    @PVA*/
  say '>>  DBSYNC in the subject line.'                    /*    @PVA*/
  say '>>Describe the error, including any error messages,' /*   @PVA*/
  say '>>  and mention the DBSYNC level you are running,'  /*    @PVA*/
  say '>>  'DBsyncName                                     /*    @PVA*/
  say '>>  '                                               /*    @PVA*/
  say '>>If you need information about RACF-L please see'  /*    @PVA*/
  say '>>  the documentation supplied with DBSYNC or visit'/*    @PVA*/
  say '>>  http://www-1.ibm.com/servers/eserver/zseries/'||,/*   @PVA*/
      'zos/racf/racf-l.html'                               /*    @PVA*/
  "execio 0 diskr indd1 (finis"
  "execio 0 diskr indd2 (finis"
  /********************************************************/
  /* Try to force out whatever we can to the output files */
  /********************************************************/
  "execio" out1add "diskw outadd1 (stem outaddcmd1. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTADD1'
  "execio" out2add "diskw outadd2 (stem outaddcmd2. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTADD2'
  "execio" out1alt "diskw outalt1 (stem outaltcmd1. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTALT1'
  "execio" out2alt "diskw outalt2 (stem outaltcmd2. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTALT2'
  "execio" out1rem "diskw outrem1 (stem outremcmd1. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTREM1'
  "execio" out2rem "diskw outrem2 (stem outremcmd2. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTREM2'
  "execio" out1del "diskw outdel1 (stem outdelcmd1. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTDEL1'
  "execio" out2del "diskw outdel2 (stem outdelcmd2. finis"
  if rc <> 0 then
    say '>>>Failure occurred writing to output file OUTDEL2'
  "execio" out1cln ,
     "diskw outcln1 (stem outclncmd1. finis"  /*      @LMA*/
  if rc <> 0 then                             /*      @LMA*/
    say '>>>Failure occurred writing to output file OUTCLN1'
  "execio" out2cln ,
     "diskw outcln2 (stem outclncmd2. finis"  /*      @LMA*/
  if rc <> 0 then                             /*      @LMA*/
    say '>>>Failure occurred writing to output file OUTCLN2'
  "execio" out1scd ,
     "diskw outscd1 (stem outscdcmd1. finis"  /*      @PNA*/
  if rc <> 0 then                             /*      @PNA*/
    say '>>>Failure occurred writing to output file OUTSCD1'
  "execio" out2scd ,
     "diskw outscd2 (stem outscdcmd2. finis"  /*      @PNA*/
  if rc <> 0 then                             /*      @PNA*/
    say '>>>Failure occurred writing to output file OUTSCD2'
  exit 16
 
/**********************************************************************/
/* Usage notes on *.ofile.* variables:                                */
/*                                                                    */
/* d.0.ofile.group_name records deleted groups                        */
/* d.1.ofile.user_id records deleted users                            */
/* d.2.ofile.user_id records user with deleted CICS segment           */
/* d.3.ofile.user_id records user with deleted OPERPARM segment       */
/* d.4.ofile.vol.dsn records deleted dataset profile                  */
/* d.5.ofile.user_id records user with deleted NETVIEW segment        */
/* e.ofile.profile_name classname as value, records deleted profile   */
/* f.ofile.profile_name classname as value, records deleted DLF seg.  */
/* g.ofile.profile_name classname as value, records deleted TME seg.  */
/*                                                                    */
/* resetdflt.ofile  records users we've reset defltgrp for            */
/*                                                                    */
/*                                                                    */
/**********************************************************************/
 
