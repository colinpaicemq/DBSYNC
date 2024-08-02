//IBMRUN3 JOB 1,MSGCLASS=H,CLASS=A                                      00010005
// SET  VER=D&SYSVER                                                    00020005
//*  SET  VER=DZ31A                                                     00021007
//*  PROC VER=D&SYSVER.                                                 00030005
// SET DD=COLIN.RACF.&VER..NLOAD.OLD                                    00040005
//S1 EXEC PGM=IEFBR14                                                   00050005
//OUTDD DD DISP=(MOD,DELETE),DSN=&DD,                                   00060005
//         SPACE=(CYL,(1,1)),DCB=(LRECL=4096,RECFM=VB,BLKSIZE=13030)    00070005
//*                                                                     00080005
//UNLOAD EXEC PGM=IRRDBU00,PARM=NOLOCKINPUT                             00090005
//SYSPRINT DD SYSOUT=*                                                  00100005
//INDD1 DD DISP=SHR,DSN=SYS1.RACFDS VOL=SER=A3CFG1,UNIT=3390            00110006
//OUTDD DD DISP=(NEW,CATLG),DSN=&DD,                                    00120005
//         SPACE=(CYL,(1,1)),DCB=(LRECL=4096,RECFM=VB,BLKSIZE=13030)    00130005
//                                                                      00140006
//OUTDD DD DISP=(NEW,CATLG),DSN=IBMUSER.RACF.UNLOAD.D5,VOL=SER=SARES1,  00150000
//         SPACE=(CYL,(1,1)),DCB=(LRECL=4096,RECFM=VB,BLKSIZE=13030),   00160000
//         UNIT=3390                                                    00170000
