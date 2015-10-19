# -------------------------------------------------------------------------
# NAME:      db2xa.mk
# VERSION:   1.13
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
#
# -------------------------------------------------------------------
# PURPOSE: This makefile is used to build the DB2 two-phase commit switch 
#          load file used with CICS. Before using this makefile:
#
# - Read the section in the CICS Administration Guide that describes
#   CICS resource manager support.
#
# - Verify that the DB2 environment is set. For example, the DB2DIR
#   and DB2INSTANCE environment variables must be set, the DB2 bin directory
#   must be included in PATH, and the DB2 lib directory must be included
#   in the library path.
#
# -------------------------------------------------------------------------
#
# Refer to the DB2 release notes, product documentation, and demo for
# information about DB2 requirements  and possible changes in the DB2 
# library structure. 
#
# The switch load file is built with the following command:
#
#          make -f db2xa.mk
#
# -------------------------------------------------------------------------
#
DB2LIB=`test -d $(DB2DIR)/lib32 && echo $(DB2DIR)/lib32 ||  echo $(DB2DIR)/lib`

all: db2xa.c
	xlc_r -v -I/usr/lpp/cics/include \
	db2xa.c \
	-o db2xa \
	-eCICS_XA_Init \
	-L/usr/lpp/cics/lib \
	-L$(DB2LIB) \
        -lsarpc \
	-lcicsrt \
	-lEncina \
	/usr/lpp/cics/lib/regxa_swxa.o \
	-ldb2
