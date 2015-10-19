# -------------------------------------------------------------------------
# NAME:      chzc_db2.mk
# VERSION:   1.10
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
# PURPOSE: This makefile is used to build the DB2 C version of the
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
#   NOTE: As described in CHEESE.README, the CHEESE.db2 SQL command script
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
# This makefile uses the following rules:
#
#	     XA: To build the XA version. This is the default.
#
#  	  NONXA: To build the non-XA version without authorization.
#
#	 NONXAE: To build the non-XA version with specific authorization.
#		 In which case, use USERNAME and PASSWORD (below) to specify
#                the user account and password to be used to connect to the
#                database.  The default is cicstest,cicstest.
#
#	install: To add the resource definitions to the region.
#
#     uninstall: To remove the resource definitions from the region.
#
#   install_XAD: To add the XAD to the region without authorization.
#
#  install_XADE: To add the XAD to the region with specific authorization.
#		 In which case, use USERNAME and PASSWORD (below) to specify
#                the user account and password to be used to connect to the
#                database.  The default is cicstest,cicstest.
#
#-----------------------------------------------------------------------------
#
#

USERNAME=cicstest
PASSWORD=cicstest

CEDF=-d -e
DB2LIB=`test -d $(DB2DIR)/lib32 && echo $(DB2DIR)/lib32 ||  echo $(DB2DIR)/lib`

LDFLAGS="-L${DB2LIB} -ldb2"

all: XA

clean:
	rm *.map *.h *.ccs chzc

XA: chzc.sqc
	cicsmap chzc_db2.bms
	mv chz1m.map /var/cics_regions/${CICSREGION}/maps/prime
	db2 connect to ${DB2DBDFT}; \
	db2 prep chzc.sqc collection cics; \
	db2 grant execute on package cics.chzc to public; \
	mv chzc.c chzc.ccs
	CCFLAGS="-I${DB2DIR}/include"; \
	LDFLAGS=${LDFLAGS}; \
	export CCFLAGS; \
	export LDFLAGS; \
	cicstcl ${CEDF} -lC chzc.ccs
	mv chzc /var/cics_regions/${CICSREGION}/bin
	rm chz1.h
	rm chzc.ccs

NONXA: chzc.sqc
	cicsmap chzc_db2.bms
	mv chz1m.map /var/cics_regions/${CICSREGION}/maps/prime
	db2 connect to ${DB2DBDFT}; \
	db2 prep chzc.sqc collection cics; \
	db2 grant execute on package cics.chzc to public; \
	mv chzc.c chzc.ccs
	CCFLAGS='-I${DB2DIR}/include -Dnon_XA -DDATABASE="${DB2DBDFT}"'; \
	LDFLAGS=${LDFLAGS}; \
	export CCFLAGS; \
	export LDFLAGS; \
	cicstcl ${CEDF} -lC chzc.ccs
	mv chzc /var/cics_regions/${CICSREGION}/bin
	rm chz1.h
	rm chzc.ccs

NONXAE: chzc.sqc
	cicsmap chzc_db2.bms
	mv chz1m.map /var/cics_regions/${CICSREGION}/maps/prime
	db2 connect to ${DB2DBDFT}; \
	db2 prep chzc.sqc collection cics; \
	db2 grant execute on package cics.chzc to public; \
	mv chzc.c chzc.ccs
	CCFLAGS='-I${DB2DIR}/include -Dnon_XA -Dauthorization \
	-DDATABASE="${DB2DBDFT}" -DUSERID="${USERNAME}" \
	-DPASSWD="${PASSWORD}"'; \
	LDFLAGS=${LDFLAGS}; \
	export CCFLAGS; \
	export LDFLAGS; \
	cicstcl ${CEDF} -lC chzc.ccs
	mv chzc /var/cics_regions/${CICSREGION}/bin

install:
	- cicsadd -c tsd -r ${CICSREGION} CHZQUEUE RSLKey=public
	- cicsadd -c tdd -r ${CICSREGION} CHZQ RSLKey=public \
		DestType=extrapartition \
		ExtrapartitionFile=/var/cics_regions/${CICSREGION}/CHZQUEUE \
		RecordType=line_oriented
	- cicsadd -c td -r ${CICSREGION} CHZ1 ProgName="CHZ1"
	- cicsadd -c pd -r ${CICSREGION} CHZ1 PathName="chzc"
	- cicsadd -c pd -r ${CICSREGION} CHZ1M ProgType=map \
		PathName="chz1m.map"

uninstall:
	cicsdelete -c tsd -r ${CICSREGION} CHZQUEUE
	cicsdelete -c tdd -r ${CICSREGION} CHZQ
	cicsdelete -c td -r ${CICSREGION} CHZ1
	cicsdelete -c pd -r ${CICSREGION} CHZ1
	cicsdelete -c pd -r ${CICSREGION} CHZ1M

install_XAD:
	cicsadd -c xad -r ${CICSREGION} DB2XAD SwitchLoadFile=cicsxadb2 \
		XAOpen=${DB2DBDFT}

install_XADE:
	cicsadd -c xad -r ${CICSREGION} DB2XAD SwitchLoadFile=cicsxadb2 \
		XAOpen=${DB2DBDFT},${USERNAME},${PASSWORD}
