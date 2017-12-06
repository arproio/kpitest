
//check an element exists in an array or not.
function include(arr,obj) {
    return (arr.indexOf(obj) !== -1);
}
//pickup common exist elements.
function pickupElements(source, target){
    var existing = [];
    for each (elm in source){
        if(include(target,elm)){
            existing.push(elm);
        }
    }
    return existing;
}
//found out what missed in target from source
function pickupNonElements(source, target){
    var nonexisting = [];
    for each (elm in source){
        //logger.warn("elm:"+elm);
        if(!include(target,elm) && typeof(elm)=="string" ){
            nonexisting.push(elm);
        }
    }
    return nonexisting;
}

var timestampkey  = me.getTimeStampKey();
var startdate=start_date_string.substring(0,10) + " " + start_date_string.substring(11,23);
var enddate=end_date_string.substring(0,10) + " " + end_date_string.substring(11,23);

var propertyList = (parameterList.split(","));
var kpiexisting = new Array();
try{
    var colquerystring = "select column_name from information_schema.columns where table_name='";
    if(granularity == "Hour"){
        colquerystring = colquerystring + "hour_kpiresults';";
    }else if(granularity == "Shift"){
        colquerystring = colquerystring + "shift_kpiresults';";
    }else if(granularity == "Minute"){
        colquerystring = colquerystring + "minute_kpiresults';";
    }else if(granularity == "Channel"){
        colquerystring = colquerystring + "channel_kpiresults';";
    }

    var colresult = Things["DB_Reporting_External"].generalQuery({query:colquerystring});

    for each (row in colresult.rows){
        if(propertyList.indexOf(row['column_name']) !== -1){
            kpiexisting.push(row['column_name']);
        }
    }
}catch(e){
    logger.error("queryAssetHistoricPropertiesFromKPI has error in property check:" + e);
    throw "MessageID_146 "+String(e);
}

var kpinonexisting = pickupNonElements(propertyList, kpiexisting);
//to_char(start_date_string at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
//logger.warn("Utility_Reporting:"+kpiexisting.toString());
var existingresult = { dataShape: { fieldDefinitions : {} }, rows: [] };
var shiftresult = { dataShape: { fieldDefinitions : {} }, rows: [] };
//result = "no value";
var queryString = "";
if(kpiexisting.length>0){
    
    queryString = "select " + kpiexisting.toString();
    if(granularity=="Hour"){
        queryString = queryString + ",kpi_date,kpi_hour,starttime,endtime, endtime as "+timestampkey+" from cognipro.hour_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Shift"){
        queryString = queryString + ",dailyshift_id,shiftname,starttime,endtime, endtime as "+timestampkey+" from cognipro.shift_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Minute"){
        queryString = queryString + ",kpi_date,kpi_minute,starttime,endtime, endtime as "+timestampkey+" from cognipro.minute_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Channel"){
        queryString = queryString + ",dailyshift_id,shiftname,starttime,endtime, endtime as "+timestampkey+" from cognipro.channel_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }
}else{
    //except alarm and state sum properties, no regular property exists.
    queryString = "select " ;
    if(granularity=="Hour"){
        queryString = queryString + "kpi_date,kpi_hour,starttime,endtime, endtime as "+timestampkey+" from cognipro.hour_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Shift"){
        queryString = queryString + "dailyshift_id,shiftname,starttime,endtime, endtime as "+timestampkey+" from cognipro.shift_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Minute"){
        queryString = queryString + "kpi_date,kpi_minute,starttime,endtime, endtime as "+timestampkey+" from cognipro.minute_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }else if(granularity=="Channel"){
        queryString = queryString + "dailyshift_id,shiftname,starttime,endtime, endtime as "+timestampkey+" from cognipro.channel_kpiresults where machine_id='" + assetID + "' \n";
        queryString = queryString + " and starttime between '"+startdate+"' and '" + enddate +"'";
    }
}

var params = {
    query: queryString /* STRING */
};
//result=queryString;
logger.warn("Utility_Reporting:"+params.toSource());
// result: INFOTABLE
try{
    existingresult = Things["DB_Reporting_External"].generalQuery(params);
    if(granularity=="Shift"){
        var querystring = "select distinct property_name from cognipro.alarm_state_timesum_shift where starttime between '"+startdate+"' and '" + enddate +"'";
        var colresult = Things["DB_Reporting_External"].generalQuery({query:querystring});
        
        var alarmlist=new Array();
        for each (row in colresult.rows){
            if(propertyList.indexOf(row['property_name']) !== -1){
                alarmlist.push(row['property_name']);
            }
        }
        //logger.warn("col query string:"+querystring + " and alarmlist:"+alarmlist.length);
        if(alarmlist.length>0){
            var dataShapeFields = existingresult.dataShape.fields;
        
            for (var fieldName in dataShapeFields) {
                var propertyname = dataShapeFields[fieldName].name;
                var propertytype = dataShapeFields[fieldName].baseType;
                //logger.warn('Unittest.Fixture_util:' + propertyrow.name +':field name is ' + infopropertyname + 'field basetype is ' + infopropertytype);
                shiftresult.dataShape.fieldDefinitions[propertyname] = { name: propertyname, baseType: String(propertytype) };
    
            }
            
            for(var alarmindex=0;alarmindex<alarmlist.length;alarmindex++){
                shiftresult.dataShape.fieldDefinitions[alarmlist[alarmindex]] = { name: alarmlist[alarmindex], baseType: 'NUMBER' };
            }
            
            //logger.warn("queryAssetHistoricPropertiesFromKPI:"+shiftresult.toSource());
            
            //var rowindex=0;
            //logger.warn("col query string existingresult.ToJSON():"+existingresult.ToJSON());
            var dataShapeFields = existingresult.dataShape.fields;
            logger.warn("shiftresult dataShapeFields:"+dataShapeFields);
            
            for(var rowindex=0;rowindex<existingresult.rows.length;rowindex++){
                var row = existingresult.rows[rowindex];
                
                var newEntry = new Object();
                for (var fieldName in dataShapeFields) {
                    var propertyname = dataShapeFields[fieldName].name;
                    newEntry[propertyname] = row[propertyname];
                }
                
                for(var alarmindex=0;alarmindex<alarmlist.length;alarmindex++){
                    var querystring = "select property_sum from cognipro.alarm_state_timesum_shift where machine_id='" + assetID +"' and property_name='"+alarmlist[alarmindex];
                    querystring = querystring +"' and endtime=to_timestamp('"+dateFormat(row['timestamp'],'yyyyMMddHHmmss')+"','YYYYMMDDHH24MISS')";
                    var propertyresult = Things["DB_Reporting_External"].generalQuery({query:querystring});

                    logger.warn("query string:"+querystring + " and result:"+propertyresult.length);

                    if(propertyresult.rows.length>0){
                        newEntry[alarmlist[alarmindex]] =propertyresult.rows[0]['property_sum'];
                    }
                }       
                //rowindex++;
                shiftresult["rows"][rowindex]=newEntry;
            }
        }else{
            shiftresult = existingresult;
        }
    }
    
    //result = existingresult.rows.length;
}catch(e){
    logger.error("queryAssetHistoricPropertiesFromKPI has error:"+e);
    //result = e;
    throw "MessageID_146 "+String(e);
}


if(granularity=="Shift"){
    result = shiftresult;
}else{
                        
	result = existingresult;
}