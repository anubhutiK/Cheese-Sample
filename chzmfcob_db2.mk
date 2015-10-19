# -------------------------------------------------------------------------
# NAME:      chzmfcob_db2.mk
# VERSION:   1.7
#                                                         
#   (C) COPYRIGHT International Business Machines Corp.   
#   1993, 2015                                            
#   All Rights Reserved                                   
#   Licensed Materials - Property of IBM                  
#   5724-B44                                              
#                                                         
#   US Government Users Restricted Rights -               
#   Use, duplication or disclosure restricted by          
#   GSA ADP Schedule Contract with IBM Corp.              
#                                                         
#                                                                       
#            NOTICE TO USERS OF THE SOURCE CODE EXAMPLES                
#                                                                       
# INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE CODE  
# EXAMPLES, BOTH INDIVIDUALLY AND AS ONE OR MORE GROUPS, AS IS          
# WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,            
# INCLUDING, BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF               
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE ENTIRE     
# RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOURCE CODE EXAMPLES,   
# BOTH INDIVIDUALLY AND AS ONE OR MORE GROUPS, IS WITH YOU.  SHOULD     
# ANY PART OF THE SOURCE CODE EXAMPLES PROVE DEFECTIVE, YOU (AND NOT    
# IBM) ASSUME THE ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR     
# CORRECTION.  THIS PROGRAM MAY BE USED, EXECUTED, COPIED, MODIFIED     
# AND DISTRIBUTED WITHOUT ROYALTY FOR THE PURPOSE OF DEVELOPING,        
# MARKETING, OR DISTRIBUTING.                                           
#                                                                       
#                                                                       
# -------------------------------------------------------------------------
# PURPOSE: This makefile is used to build the DB2 MF COBOL version of the
#          CICS CHEESE program.  Before using this makefile:
#
# - Read CHEESE.README
#
# - Set environment variables required for CICS and DB2 application
#   development.  For example, DB2INSTANCE and DB2DIR must be set and
#   the DB2 bin and library directories must be included in the bin and
#   library paths as required for your operating system.  For CICS
#   development environment requirements, refer to the CICS documentation.
#
# - Set DB2DBDFT to the name of the DB2 database to be used for this
#   transaction. The non-XA source code uses the default "cicstest".
#
#   NOTE: As described in CHEESE.README, the cheese.db2 SQL command script
#         creates the CICS.CHEESE table used by this transaction program.
#         This SQL command script will create a database named "cicstest"
#         if one does not already exist.  Edit the script file if you do
#         not want to use a database of this name.
#
# - Set CICSREGION to the name of the CICS region to be used for this
#   transaction. Because the transaction program is copied into the region's
#   bin directory, the region must exist prior to using this makefile.
#
#   NOTE: As described in the CICS Administration Guide, DB2INSTANCE must
#         be set in the region's environment.  On AIX, this must be set in
#         the region's environment file.
#
# - If you want to enable the CEDF transaction for the CHZ1 transaction,
#   uncomment the CEDF export and do the following:
#
#   cicsupdate -c td -r $CICSREGION CEDF Permanent=no
#   cicsupdate -c td -r $CICSREGION CEDF RSLCheck=none
#
# - Review the values of USERID and PASSWD below, which are used in the
#   XAD.  If you do not want to use the default values, change them in
#   this makefile and edit the source file and review the values of:
#
#    DBASE
#    USERNAME
#    PASSWD
#
# This makefile uses the following rules:
#
#          all: Build the executables and the COBOL runtime.
#
#      install: Add the resource definitions to the region.
#
#    uninstall: Remove the resource definitions from the region.
#
#  install_XAD: Add the XAD to the region.
#
#
# -------------------------------------------------------------------------
#

USERID=cicstest
PASSWD=cicstest

CEDF=-d -e
DB2LIB=`test -d $(DB2DIR)/lib32 && echo $(DB2DIR)/lib32 ||  echo $(DB2DIR)/lib`
LDFLAGS="-L${DB2LIB} -ldb2 ${DB2LIB}/sqlgmf.o"

all: CHZ2M.map chzcob.gnt cicsprCOBOL

CHZ2M.map: chzcob_db2.bms
	cicsmap chzcob_db2.bms
	mv CHZ2M.map /var/cics_regions/${CICSREGION}/maps/prime

chzcob.gnt: chzcob.ccp
	COBCPY=${DB2DIR}/include/cobol_mf; \
	export COBCPY; \
	cicstcl ${CEDF} -lCOBOL chzcob.ccp
	mv chzcob.gnt /var/cics_regions/${CICSREGION}/bin
	rm chzcob.ccp
	rm CHZ2
 
chzcob.ccp: chzcob.sqb
	db2 connect to ${DB2DBDFT}; \
	db2 prep chzcob.sqb collection cics; \
	db2 grant execute on package cics.chzcob to public; \
	mv chzcob.cbl chzcob.ccp

install:
	- cicsadd -c tsd -r ${CICSREGION} CHZQUEUE RSLKey=public
	- cicsadd -c tdd -r ${CICSREGION} CHZQ RSLKey=public \
		DestType=extrapartition \
		ExtrapartitionFile=/var/cics_regions/${CICSREGION}/CHZQUEUE \
		RecordType=line_oriented
	- cicsadd -c td -r ${CICSREGION} CHZ2 ProgName="CHZ2"
	- cicsadd -c td -r ${CICSREGION} XHZ2 ProgName="CHZ2"
	- cicsadd -c pd -r ${CICSREGION} CHZ2 PathName="chzcob"
	- cicsadd -c pd -r ${CICSREGION} CHZ2M ProgType=map \
		PathName="CHZ2M.map"

uninstall: 
	cicsdelete -c tsd -r ${CICSREGION} CHZQUEUE 
	cicsdelete -c tdd -r ${CICSREGION} CHZQ 
	cicsdelete -c td -r ${CICSREGION} CHZ2 
	cicsdelete -c td -r ${CICSREGION} XHZ2
	cicsdelete -c pd -r ${CICSREGION} CHZ2
	cicsdelete -c pd -r ${CICSREGION} CHZ2M 

install_XAD:
	cicsadd -c xad -r ${CICSREGION} DB2XAD SwitchLoadFile=cicsxadb2 \
		XAOpen=${DB2DBDFT},${USERID},${PASSWD}

cicsprCOBOL:
	cicsmkcobol ${LDFLAGS}
	mv cicsprCOBOL /var/cics_regions/${CICSREGION}/bin
	rm cobinitsig.gnt

