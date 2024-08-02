# DBSYNC
UpdatedRACF DBSYNC

## Updated 

The original IBM DBSYNC from 2012 is in https://public.dhe.ibm.com/eserver/zseries/zos/racf/dbsync/ , and I could find
no later updates to it.

I have taken it, and extened it to support newer functions and RACF changes.

The base documentation is [here](https://public.dhe.ibm.com/eserver/zseries/zos/racf/dbsync/dbsync.doc.txt) 
My updates are [here](doc/colin.md) 

## Update details

1. user basic data (0200): bad seclevel data.  Corrected this and added support for new fields
2. add support for MFA 
3. add support for ICSF
4. add support for IDTPARMS
5. add support for general resource certificate information record  (1560)
6. add support for SSIGNON


