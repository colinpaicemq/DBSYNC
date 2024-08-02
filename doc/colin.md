# Colin Paice's updates to DBSYNC

## Updated JCL

I updated the JCL to run the program to make it more compact.

```
//IBMUSRA  JOB 1,MSGCLASS=H 
// SET DDA='DISP=(MOD,CATLG)' 
// SET DDB='UNIT=SYSDA,SPACE=(CYL,(25,25),RLSE)' 
// SET DDC='DCB=(RECFM=VB,LRECL=600,BLKSIZE=6400)' 
...
//DBSYNC EXEC PGM=IKJEFT01,REGION=5000K,DYNAMNBR=50,PARM
...
//OUTADD1  DD DSN=COLIN.DBSYNC.ADDFILE1,&DDA,&DDB,&DDC 
//OUTADD2  DD DSN=COLIN.DBSYNC.ADDFILE2,&DDA,&DDB,&DDC 
...
```

Instead of

```
//IBMUSRA  JOB 1,MSGCLASS=H                                          
... 
//DBSYNC EXEC PGM=IKJEFT01,REGION=5000K,DYNAMNBR=50,PARM='%MDBSYNC' 
...
//OUTADD1  DD DSN=COLIN.DBSYNC.ADDFILE1, 
//            DISP=(MOD,CATLG), 
//            UNIT=SYSDA,SPACE=(CYL,(25,25),RLSE), 
//            DCB=(RECFM=VB,LRECL=600,BLKSIZE=6400) 
//OUTADD2  DD DSN=COLIN.DBSYNC.ADDFILE2, 
//            DISP=(MOD,CATLG), 
//            UNIT=SYSDA,SPACE=(CYL,(25,25),RLSE), 
//            DCB=(RECFM=VB,LRECL=600,BLKSIZE=6400) 
//OUTALT1  DD DSN=COLIN.DBSYNC.ALTFILE1, 
//            DISP=(MOD,CATLG), 
//            UNIT=SYSDA,SPACE=(CYL,(25,25),RLSE), 
//            DCB=(RECFM=VB,LRECL=600,BLKSIZE=6400) 
```

I also use

```
//S1 EXEC PGM=IDCAMS,REGION=0M 
//SYSPRINT DD SYSOUT=* 
//SYSIN DD * 
  DELETE COLIN.DBSYNC.**  NONVSAM MASK 
/* 
```
to delete all the output files before I start.   Note: You should check there are no dataset you want beginning with COLIN.DBSYNC.* as they will be deleted.

## Updated code

I did not want to do a major rewrite to the code, so have written execs to process the records.  For example for type
* General resource MFA factor definition record (05H0) * 
I created an exec GENC05H0.   This is self contained.

Rather than write to the //OUTADD1 ... data sets, they write to function specific, such as 
//MFAADD1, //MFAADD2 
//MFADEL1, //MFADEL2, //MFAALT1, //MFAALT2 


I had these going to the spool, but you could easily have this going to a dataset, especially if you use JCL like 

> //OUTADD2  DD DSN=COLIN.DBSYNC.ADDFILE2,&DDA,&DDB,&DDC

