logger.debug("Start of processOneLineRemote");
var currentTime=new Date();
//var currentTime = parseDate("20171104034527", "yyyyMMddHHmmss"); //test date
var currentTimeString = dateFormat(currentTime, "yyyyMMddHHmmss") ;
var currentHourString = currentTimeString.substring(0,10)+"0000";	//20171102030000, hour round up.
var currentMinuteString = currentTimeString.substring(0,12) +"00";

var params = {
	//line_name: line_name /* STRING */,
    line_name: line_name.substring(5) /* STRING */, //get rid of leading "Line_"
	par_timestamp: currentTimeString/* STRING */
};

// result: INFOTABLE dataShape: "DS_ShiftDefinitions"
var shiftresult = me.get_shift_info(params);
if(shiftresult['rows'].length != 1){
    throw ("Can't find proper shift definition for:" + line_name + " at time:"+currentTimeString );
}
var shiftStartTimeString = shiftresult['rows'][0]['start_time'];
var shiftEndTimeString = shiftresult['rows'][0]['end_time'];
var shift_name = shiftresult['rows'][0]['shift_name'];
var shift_id = shiftresult['rows'][0]['shift_id'];
var dailyshift_id = shiftresult['rows'][0]['shift_instance_id'];

//var lastKPIJITTime = Things["Line_"+line_name].lastKPIJITTime;
var lastKPICacheTime = Things[line_name].lastKPICacheTime;
var lastKPICacheTimeString = dateFormat(lastKPICacheTime,"yyyyMMddHHmmSS");
var ideal_run_rate = shiftresult['rows'][0]['ideal_run_rate'];

var newShift=false;
var newHour =false;
var newMinute = false;

if(lastKPICacheTimeString < shiftStartTimeString)	newShift = true;
if(lastKPICacheTimeString < currentHourString) 		newHour = true;
if(lastKPICacheTimeString < currentMinuteString) 	newMinute = true;


try{
    Things[line_name].lastKPICacheTime = currentTime;	//update it before action, inorder to avoid racing issue.
    //if any processing is missed due to error, it will not be called again and again.
    
    //get all associated asset and type.
    //Type format: type1;type2;type3
    //Asset format: {type1asset1,type1asset2};{type2asset1,type2asset2}
    
    var params = {
        line_name: line_name /* STRING */
    };
    
    // result: INFOTABLE dataShape: "DS_AssetTypeAndName"
    var assetresult = me.getAssetsByLine(params);
    var assettypes = null; //type1,type1,type2 etc
    var assetnames = null; //vpp01,vpp02 etc
    var assetvaluestreams = null; //vs-vpp1, vs=vpp2 etc
    var assetstreams = null;		//only valid for VPP. "","",STREAM_VPP3002 etc.
    var countableassetnames = null;
    
    for(var index=0;index<assetresult['rows'].length;index++){
        //logger.warn("-->"+index+"  "+assetresult['rows'][index]['asset_name']);
        var assetname = assetresult['rows'][index]['asset_name']; //asset name which has 'Asset_'
        var remoteThingName = assetname.substring(6); //get rid of leading "asset_"
        var thingTemplateType = Things[remoteThingName].thingTemplateType;
        if(Things[assetname].isCountable){
            if(countableassetnames == null){
                countableassetnames = remoteThingName;
            }else{
                countableassetnames = countableassetnames + "," + remoteThingName;
            }
        }
            
        if(assetnames == null){
            assetnames = remoteThingName;	//first one.
        }else{
            assetnames = assetnames + "," + remoteThingName;
        }
        
        if(assettypes == null){
            assettypes = thingTemplateType;
        }else{
            assettypes = assettypes + "," + thingTemplateType;
        }
        
        if(assetvaluestreams == null){
            assetvaluestreams = Things[remoteThingName].GetValueStream();
        }else{
            assetvaluestreams = assetvaluestreams + "," +  Things[remoteThingName].GetValueStream();
        }
        
        if(assetstreams == null){
            assetstreams = Things[remoteThingName].specialStreamName;
        }else{
            assetstreams = assetstreams + "," + Things[remoteThingName].specialStreamName;
        }
    }
    
    assettypes = "{" + assettypes + "}";
    assetnames = "{" + assetnames + "}";
    assetvaluestreams = "{" + assetvaluestreams + "}";
    assetstreams = "{" + assetstreams + "}";
    countableassetnames = "{" + countableassetnames + "}";
    
    logger.info("Utility_Granularity Remote types:"+assettypes + " ;names:"+assetnames+" ;valuestreams:"+assetvaluestreams+" ;streams:"+assetstreams + " newShift:"+newShift+" newHour:"+newHour);    

}catch(e){

    logger.error("Utility_Granularity has error during asset data preparation, set shift, hour and minute to false:"+line_name);
    newShift=false;
    newHour =false;
    newMinute = false;    
}

try{
    if(newShift){
        //need to retrive last shift by minues one minute of starting time to get it.
        var current_shift_start_time_value = parseDate(shiftStartTimeString, "yyyyMMddHHmmss");
        var last_minute_in_last_shift = dateAddMinutes(current_shift_start_time_value, -1);
    
    
        var lastparams = {
            line_name: line_name.substring(5) /* STRING */,
            par_timestamp: dateFormat(last_minute_in_last_shift,"yyyyMMddHHmmss") /* STRING */
        };
    
        // result: INFOTABLE dataShape: "DS_ShiftDefinitions"
        var lastshiftresult = me.get_shift_info(lastparams);
        if(lastshiftresult['rows'].length != 1){
            logger.error("Unable to find shift info for line:"+ line_name +" at:"+dateFormat(last_minute_in_last_shift,"yyyyMMddHHmmss"));
        }else{
            var lastdailyshift_id=lastshiftresult['rows'][0]['shift_instance_id'];
            var lastshift_id = lastshiftresult['rows'][0]['shift_id'];
            var lastshiftname = lastshiftresult['rows'][0]['shift_name'];
    
            var params = {
                dailyshiftid: lastdailyshift_id /* STRING */,
                shiftid: lastshift_id /* STRING */,
                machine_types: assettypes /* STRING */,
                value_streams: assetvaluestreams /* STRING */,
                machine_ids: assetnames /* STRING */,
                ideal_run_rate: ideal_run_rate /* INTEGER */,
                shiftname: lastshiftname /* STRING */,
                end_time_string: lastshiftresult['rows'][0]['end_time'] /* STRING */,
                streams: assetstreams /* STRING */,
                start_time_string: lastshiftresult['rows'][0]['start_time'] /* STRING */,
                countable_machine_ids: countableassetnames
            };
    
            logger.warn("Remote Shift:"+params.toSource());
            // result: INFOTABLE dataShape: DS_SingleString_General
            var shiftkpiresult = Things["DB_Metadata"].DB_Asset_KPI_Bytime_Batch_Shift(params);
            
            //line shift calculation code here.
            var total_count = 0.0;
            var reject_count = 0.0;
            if(shiftkpiresult['rows'].length>0){
                var rowstring = shiftkpiresult['rows'][0]['asset_kpi_bytime_batch_shift'];
                var valuearray = rowstring.substring(1,rowstring.length-1).split(",");
                total_count = Number(valuearray[0]);
                reject_count = Number(valuearray[1]);
            }
            
            var good_count = total_count - reject_count;
            
            var kpi_start_time= parseDate(lastshiftresult['rows'][0]['start_time'],'yyyyMMddHHmmss');
            var kpi_end_time = parseDate(lastshiftresult['rows'][0]['end_time'],'yyyyMMddHHmmss');
    
            var params = {
                start_time: kpi_start_time /* DATETIME */,
                end_time: kpi_end_time /* DATETIME */,
                operation_state: 1 /* INTEGER */
            };
    
            // result: INTEGER
            var run_time = Things[line_name].calculate_run_time(params);
    
            params.operation_state = 2;
            var planned_downtime = Things[line_name].calculate_run_time(params);
    
            params.operation_state = 3;
            var unplanned_downtime = Things[line_name].calculate_run_time(params);
    
            var planned_production_time = dateDifference(kpi_end_time,kpi_start_time)/1000;	//convert to seconds
    
            var performanceoee = 0.0;
            if(ideal_run_rate > 0 && run_time > 0){
                performanceoee = total_count * 100.0/ (ideal_run_rate * run_time);
            }
    
            var qualityoee = 0.0;
            if(total_count > 0){
                qualityoee = good_count * 100.0/ total_count;
            }
    
            var availabilityoee = 0.0;
            if(planned_production_time > 0){
                availabilityoee =run_time * 100 / planned_production_time;
            }
    
            var params = {
                kpi_planprodtime: planned_production_time /* NUMBER */,
                kpi_planneddowntime: planned_downtime /* NUMBER */,
                kpi_goodcount: good_count /* NUMBER */,
                kpi_qualityoee: qualityoee /* NUMBER */,
                shiftname: lastshiftname /* STRING */,
                kpi_availabilityoee: availabilityoee /* NUMBER */,
                kpi_totalcount: total_count /* NUMBER */,
                kpi_unplanneddowntime: unplanned_downtime /* NUMBER */,
                update_date: new Date() /* DATETIME */,
                kpi_rejectcount: reject_count /* NUMBER */,
                kpi_runtime: run_time /* NUMBER */,
                linename: line_name /* STRING */,
                kpi_oee: availabilityoee * performanceoee * qualityoee/10000  /* NUMBER */,
                dailyshift_id: lastdailyshift_id /* STRING */,
                kpi_performanceoee: performanceoee /* NUMBER */,
                starttime:kpi_start_time,
                endtime: kpi_end_time
            };
    
            // result: NUMBER
            logger.warn("Utility_Granularity processOneLineRemote for one shift:" + params.toSource());
            Things["DB_External"].insert_shift_linekpiresults(params);
        }
    }  

}catch(e){
    logger.error("Utility_Granularity has error during new shift processing, line:"+line_name);
}

try{
    if(newHour){
        var currentHourValue = parseDate(currentHourString,'yyyyMMddHHmmss');
        var lastHourValue = dateAddHours(currentHourValue, -1 );	//minus one hour as a start time.
        var lastHourString = dateFormat(lastHourValue,'yyyyMMddHHmmss');
        
        var params = {
            dailyshiftid: dailyshift_id /* STRING */,
            shiftid: shift_id /* STRING */,
            machine_types: assettypes /* STRING */,
            value_streams: assetvaluestreams /* STRING */,
            machine_ids: assetnames /* STRING */,
            ideal_run_rate: ideal_run_rate /* INTEGER */,
            shiftname: shift_name /* STRING */,
            end_time_string: currentHourString /* STRING */,
            streams: assetstreams /* STRING */,
            kpi_date: lastHourString.substring(0,8) /* STRING */,
            start_time_string: lastHourString /* STRING */,
            kpi_hour: lastHourString.substring(8,10) /* STRING */,
            countable_machine_ids: countableassetnames
        };
    
        logger.warn("Remote Hour:"+params.toSource());
        // result: INFOTABLE dataShape: DS_SingleString_General
        var hourkpiresult = Things["DB_Metadata"].DB_Asset_KPI_Bytime_Batch_Hour(params);
        
        var total_count = 0.0;
        var reject_count = 0.0;
        if(hourkpiresult['rows'].length>0){
            var rowstring = hourkpiresult['rows'][0]['asset_kpi_bytime_batch_hour'];
            logger.warn("Remote Hour Line:"+rowstring);
            
            var valuearray = rowstring.substring(1,rowstring.length-1).split(",");
            total_count = Number(valuearray[0]);
            reject_count = Number(valuearray[1]);
        }
    
        var good_count = total_count - reject_count;
    
        var kpi_start_time= parseDate(lastHourString,'yyyyMMddHHmmss');
        var kpi_end_time = currentHourValue;
    
        var params = {
            start_time: kpi_start_time /* DATETIME */,
            end_time: kpi_end_time /* DATETIME */,
            operation_state: 1 /* INTEGER */
        };
    
        // result: INTEGER
        var run_time = Things[line_name].calculate_run_time(params);
    
        params.operation_state = 2;
        var planned_downtime = Things[line_name].calculate_run_time(params);
    
        params.operation_state = 3;
        var unplanned_downtime = Things[line_name].calculate_run_time(params);
    
        var planned_production_time = dateDifference(kpi_end_time,kpi_start_time)/1000;	//convert to seconds
    
        var performanceoee = 0.0;
        if(ideal_run_rate > 0 && run_time > 0){
            performanceoee = total_count * 100.0/ (ideal_run_rate * run_time);
        }
    
        var qualityoee = 0.0;
        if(total_count > 0){
            qualityoee = good_count * 100.0/ total_count;
        }
    
        var availabilityoee = 0.0;
        if(planned_production_time > 0){
            availabilityoee =run_time * 100 / planned_production_time;
        }
    
        var params = {
            kpi_planprodtime: planned_production_time /* NUMBER */,
            kpi_planneddowntime: planned_downtime /* NUMBER */,
            kpi_goodcount: good_count /* NUMBER */,
            kpi_qualityoee: qualityoee /* NUMBER */,
            //shiftname: lastshiftname /* STRING */,
            kpi_availabilityoee: availabilityoee /* NUMBER */,
            kpi_date: lastHourString.substring(0,8) /* STRING */,
            kpi_totalcount: total_count /* NUMBER */,
            kpi_unplanneddowntime: unplanned_downtime /* NUMBER */,
            update_date: new Date() /* DATETIME */,
            kpi_rejectcount: reject_count /* NUMBER */,
            kpi_runtime: run_time /* NUMBER */,
            linename: line_name /* STRING */,
            kpi_oee: availabilityoee * performanceoee * qualityoee/10000  /* NUMBER */,
            //dailyshift_id: lastdailyshift_id /* STRING */,
            kpi_performanceoee: performanceoee /* NUMBER */,
            starttime:kpi_start_time,
            endtime: kpi_end_time,
            kpi_hour: lastHourString.substring(8,10)
        };
    
        // result: NUMBER
        logger.warn("Utility_Granularity processOneLineRemote for one hour:" + params.toSource());
        Things["DB_External"].insert_hour_linekpiresults(params);
    }    

}catch(e){
    logger.error("Utility_Granularity has error during new hour processing, line:"+line_name);
}

try{
    if(newMinute){
        var lastKPIMinuteString = lastKPICacheTimeString.substring(0,12)+"00";
        var lastKPIMinuteTime = parseDate(lastKPIMinuteString,'yyyyMMddHHmmss');
        var currentMinuteTime = parseDate(currentMinuteString,'yyyyMMddHHmmss');
        
        var minutes = dateDifference(currentMinuteTime,lastKPIMinuteTime)/6e4;	// 60 * 1000 to minutes
        logger.warn("Remote lastKPIMinuteTime:"+lastKPIMinuteTime+" ; currentMinuteTime:"+currentMinuteTime + " ; minutes:"+minutes);
        
        var params = {
            dailyshiftid: dailyshift_id /* STRING */,
            shiftid: shift_id /* STRING */,
            machine_types: assettypes /* STRING */,
            value_streams: assetvaluestreams /* STRING */,
            machine_ids: assetnames /* STRING */,
            kpi_minute: lastKPICacheTimeString.substring(10,12) /* STRING */,
            minutes: minutes /* INTEGER */,
            ideal_run_rate: ideal_run_rate /* INTEGER */,
            shiftname: shift_name /* STRING */,
            streams: assetstreams /* STRING */,
            kpi_date: lastKPICacheTimeString.substring(0,8) /* STRING */,
            kpi_hour: lastKPICacheTimeString.substring(8,10) /* STRING */
        };
        logger.warn("Remote Minute:"+params.toSource());
        // result: INFOTABLE dataShape: DS_SingleString_General
        Things["DB_Metadata"].DB_Asset_KPI_Bytime_Batch_Minute(params);
        
    }    
}catch(e){
    logger.error("Utility_Granularity has error during new minute processing, line:"+line_name);
}
