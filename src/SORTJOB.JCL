//IBMUSERR JOB 1,MSGCLASS=H
// SET DD1='COLIN.RACF.DZ25D.NLOAD.OLD'
// SET DD2='COLIN.RACF.DZ31A.NLOAD.OLD'
//SORT  PROC DD1=
//S1 EXEC PGM=IEFBR14
//OUTDD1 DD DISP=(MOD,DELETE),DSN=&DD1..SORT5,
//         SPACE=(CYL,(1,1)),DCB=(LRECL=4096,RECFM=VB,BLKSIZE=13030)
//*
//SORT1   EXEC PGM=SORT
//SYSOUT    DD SYSOUT=*
//SORTIN    DD DISP=SHR,DSN=&DD1
//SORTOUT   DD DISP=(NEW,CATLG),SPACE=(CYL,(1,1)),
//          DSN=&DD1..SORT5
//SYSIN   DD *
   SORT FIELDS=(5,2,CH,A,7,1,AQ,A,8,549,CH,A)
   ALTSEQ CODE=(F080,F181,F282,F383,F484,F585,F686,F787,F888,F989,
     C191,C292,C393,C494,C595,C696,C797,C898,C999,
     D1A1,D2A2,D3A3,D4A4,D5A5,D6A6,D7A7,D8A8,D9A9,
     E2B2,E3B3,E4B4,E5B5,E6B6,E7B7,E8B8,E9B9)
    OPTION   VLSHRT,DYNALLOC=(SYSDA,3)
//  PEND
// EXEC PROC=SORT,DD1=COLIN.RACF.DZ25D.NLOAD.OLD
// EXEC PROC=SORT,DD1=COLIN.RACF.DZ31A.NLOAD.OLD
//
//SORT2   EXEC PGM=SORT
//SYSOUT    DD SYSOUT=*
//SORTIN    DD DISP=SHR,DSN=&DD2
//SORTOUT   DD DISP=(NEW,CATLG),SPACE=(CYL,(1,1)),
//          DSN=&DD2..SORT
//SYSIN   DD *
   SORT FIELDS=(5,2,CH,A,7,1,AQ,A,8,549,CH,A)
   ALTSEQ CODE=(F080,F181,F282,F383,F484,F585,F686,F787,F888,F989,
     C191,C292,C393,C494,C595,C696,C797,C898,C999,
     D1A1,D2A2,D3A3,D4A4,D5A5,D6A6,D7A7,D8A8,D9A9,
     E2B2,E3B3,E4B4,E5B5,E6B6,E7B7,E8B8,E9B9)
    OPTION   VLSHRT,DYNALLOC=(SYSDA,3)
