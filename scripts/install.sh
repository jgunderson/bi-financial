#!/bin/sh
RUN_DIR=$(pwd)
LOG_FILE=$RUN_DIR/build_bi.log
mv $LOG_FILE $LOG_FILE.old
log() {
	echo $@
	echo $@ >> $LOG_FILE
}

varlog() {
	log $(eval "echo $1 = \$$1")
}

cdir() {
	cd $1
	log "Changing directory to $1"
}

RUNALL=true
BI_FINANCIAL_DIR=$RUN_DIR/..
BI_OPEN_DIR=$RUN_DIR/../../bi-open
export BISERVER_HOME=$RUN_DIR/../../ErpBI

if  ! test -d $BI_OPEN_DIR ;
then
	log ""
	log "##############################################################"
    log "Sorry bi_open folder not found.  You must clone xtuple/bi_open"
	log "and run bi_open/scripts/build_bi.sh"
	log "##############################################################"
	log ""
    exit 1
fi
if  ! test -d $BISERVER_HOME ;
then
	log ""
	log "#############################################################################"
    log "Sorry ErpBI folder not found.  You must first run bi_open/scripts/build_bi.sh"
	log "to install ErpBI"
	log "#############################################################################"
	log ""
    exit 1
fi

log ""
log "########################################################"
log "Build OLAP schema and move schema and ETL files to ErpBI"
log "at "$BISERVER_HOME
log "########################################################"
log ""
cp $BI_FINANCIAL_DIR/olap-schema/src/erpi-tenant-xtuple.xml $BI_OPEN_DIR/olap-schema/src/erpi-for-build.xml
cdir $BI_OPEN_DIR/olap-schema
mvn install 2>&1 | tee -a $LOG_FILE
java -jar Saxon-HE-9.4.jar -s:$BI_OPEN_DIR/olap-schema/src/erpi-for-build.xml -xsl:style.xsl -o:$BI_OPEN_DIR/olap-schema/target/erpi-schema.xml
mvn process-resources 2>&1 | tee -a $LOG_FILE

cdir $BI_FINANCIAL_DIR/etl
mvn install 2>&1 | tee -a $LOG_FILE
mvn process-resources 2>&1 | tee -a $LOG_FILE

log ""
log "######################################################"
log "                FINISED! READ ME                      "
log "You must now run the ETL to load the data mart.  See: "
log "bi_open/scripts/build_bi.sh -l"
log "######################################################"
log ""