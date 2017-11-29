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
//logger.warn("shiftinfo result:"+shiftresult.ToJSON());
if(shiftresult['rows'].length != 1){
    throw ("Can't find proper shift definition for:" + line_name + " at time:"+currentTimeString );
}
var shiftStartTimeString = shiftresult['rows'][0]['start_time'];
var shiftEndTimeString = shiftresult['rows'][0]['end_time'];
var shift_name = shiftresult['rows'][0]['shift_name'];
var dailyshift_id = shiftresult['rows'][0]['shift_instance_id'];

//var lastKPIJITTime = Things["Line_"+line_name].lastKPIJITTime;
var lastKPIJITTime = Things[line_name].lastKPIJITTime;
var lastKPIJITTimeString = dateFormat(lastKPIJITTime,"yyyyMMddHHmmSS");
var ideal_run_rate = shiftresult['rows'][0]['ideal_run_rate'];

var newShift=false;

if(lastKPIJITTimeString < shiftStartTimeString)   newShift=true;


Things[line_name].lastKPIJITTime = currentTime;	//update it before action, inorder to avoid racing issue.
//if any processing is missed due to error, it will not be called again and again.

//get all associated asset and type.
//Type format: type1;type2;type3
//Asset format: {type1asset1,type1asset2};{type2asset1,type2asset2}

var params = {
	line_name: line_name /* STRING */
};

// result: INFOTABLE dataShape: "DS_AssetTypeAndName"
var assetresult = me.getAssetsByLine(params);
var asset_type_dict = {};	//
var availability_window = {};
var capacity_potential_window = {};
var throughput_window = {};
var efficiency_window = {};

//calculate planned_production_time
var planned_start_time=parseDate(shiftStartTimeString,'yyyyMMddHHmmss');
var planned_current_time = parseDate(currentMinuteString,'yyyyMMddHHmmss');
var planned_production_time = dateDifference(planned_current_time,planned_start_time)/1e3;	//convert to seconds.

for(var index=0;index<assetresult['rows'].length;index++){
    //logger.warn("-->"+index+"  "+assetresult['rows'][index]['asset_name']);
    var remoteThingName = assetresult['rows'][index]['asset_name'].substring(6); //get rid of leading "asset_"
    var remoteTemplateName = Things[remoteThingName].thingTemplateType; //20171110 11:31, pickup type configured in TS*Consolidation instead of template name.
    if(remoteTemplateName in asset_type_dict){
        asset_type_dict[remoteTemplateName] = asset_type_dict[remoteTemplateName] +"," + remoteThingName; 	//consider to replace , with ;.
    }else{
        asset_type_dict[remoteTemplateName]=remoteThingName;
        availability_window[remoteTemplateName] = Things[remoteThingName].availability_window;
        capacity_potential_window[remoteTemplateName] = Things[remoteThingName].capacity_potential_window;
        throughput_window[remoteTemplateName] = Things[remoteThingName].throughput_window;
        efficiency_window[remoteTemplateName] = Things[remoteThingName].efficiency_window;
        
    }
}

for(type_name in asset_type_dict){
    if(newShift){
        //logger.warn("This is a NEW shift:"+shiftresult.ToJSON());
        //update shift start and duration time 
        Things[line_name].current_shift_start = parseDate(shiftStartTimeString,'yyyyMMddHHmmss');
        Things[line_name].current_shift_end = parseDate(shiftEndTimeString,'yyyyMMddHHmmss');
        Things[line_name].shiftStartTime = shiftStartTimeString.substring(6,8)+":"+shiftStartTimeString.substring(8,10);
		// dateDifference(date1:DATETIME,date2:DATETIME):NUMBER
        var difference = dateDifference(Things[line_name].current_shift_end, Things[line_name].current_shift_start)/60000 -1;
		//in minutes.
        var hour_duration = Math.floor(difference/60);
        Things[line_name].shiftDuration = hour_duration +":" + (difference - hour_duration * 60);
        //end
    }
    
    var params = {
            line_name: line_name /* STRING */,
            type_name: type_name /* STRING */,
            machine_ids: "{" + asset_type_dict[type_name] +"}" /* STRING */, //pack it as an array for stored procedure
            current_shift_start_time: shiftStartTimeString /* STRING */,
        	currentMinuteString: currentMinuteString,
            availability_window: availability_window[type_name] /* INTEGER */,
            capacity_potential_window: capacity_potential_window[type_name] /* INTEGER */,
            throughput_window: throughput_window[type_name] /* INTEGER */,
            efficiency_window: efficiency_window[type_name] /* INTEGER */,
        	planned_production_time: planned_production_time,
        	ideal_run_rate: ideal_run_rate,
            dailyshift_id: dailyshift_id,
            shift_name: shift_name
        };
        logger.warn("Utility_Granularity processOneLineJIT for one type:" + params.toSource());
        // result: INFOTABLE dataShape: "DS_SingleString_General"
        var type_result = me.processOneLineOneTypeJIT(params);
        //logger.warn(type_name +":--------->"+type_result.ToJSON());
    
    
}

//Things[line_name].evaluate_product_count();
var reject_count_sum = 0.0;
var total_count_sum = 0.0;

for(var index=0;index<assetresult['rows'].length;index++){
    //logger.warn("-->"+index+"  "+assetresult['rows'][index]['asset_name']);
    var assetThingName = assetresult['rows'][index]['asset_name']; //don't get rid of leading "asset_"
    reject_count_sum = reject_count_sum + Things[assetThingName].reject_count;
    if(Things[assetThingName].isCountable){
        total_count_sum = total_count_sum + Things[assetThingName].total_count;
    }
}
Things[line_name].total_count = total_count_sum;
Things[line_name].good_count = total_count_sum - reject_count_sum;

var kpi_start_time= parseDate(shiftStartTimeString,'yyyyMMddHHmmss');
var kpi_end_time = parseDate(currentMinuteString,'yyyyMMddHHmmss');

var params = {
	start_time: kpi_start_time /* DATETIME */,
	end_time: kpi_end_time /* DATETIME */,
	operation_state: 1 /* INTEGER */
};

// result: INTEGER
Things[line_name].run_time = Things[line_name].calculate_run_time(params);

params.operation_state = 2;
Things[line_name].planned_downtime = Things[line_name].calculate_run_time(params);

params.operation_state = 3;
Things[line_name].unplanned_downtime = Things[line_name].calculate_run_time(params);

Things[line_name].planned_production_time = dateDifference(kpi_end_time,kpi_start_time)/1000;	//convert to seconds

var performanceoee = 0.0;
if(ideal_run_rate > 0 && Things[line_name].run_time > 0){
    performanceoee = total_count_sum * 100.0/ (ideal_run_rate * Things[line_name].run_time);
}

var qualityoee = 0.0;
if(total_count_sum > 0){
    qualityoee = Things[line_name].good_count * 100.0/ total_count_sum;
}

var availabilityoee = 0.0;
if(Things[line_name].planned_production_time > 0){
    availabilityoee = Things[line_name].run_time * 100 / Things[line_name].planned_production_time;
}

var params = {
	kpi_planprodtime: Things[line_name].planned_production_time /* NUMBER */,
	kpi_planneddowntime: Things[line_name].planned_downtime /* NUMBER */,
	kpi_goodcount: Things[line_name].good_count /* NUMBER */,
	kpi_qualityoee: qualityoee /* NUMBER */,
	shiftname: shift_name /* STRING */,
	kpi_availabilityoee: availabilityoee /* NUMBER */,
	kpi_totalcount: total_count_sum /* NUMBER */,
	kpi_unplanneddowntime: Things[line_name].unplanned_downtime /* NUMBER */,
	update_date: new Date() /* DATETIME */,
	kpi_rejectcount: reject_count_sum /* NUMBER */,
	kpi_runtime: Things[line_name].run_time /* NUMBER */,
	linename: line_name /* STRING */,
	kpi_oee: availabilityoee * performanceoee * qualityoee/10000  /* NUMBER */,
	dailyshift_id: dailyshift_id /* STRING */,
	kpi_performanceoee: performanceoee /* NUMBER */
};

logger.info("Utility_Granularity processOneLineJIT insert realtime line kpi:"+params.toSource());
// result: NUMBER
Things["DB_External"].insert_realtime_linekpiresults(params);



//logger.debug("JIT:"+line_name+ " ;Start time:"+kpi_start_time+" ; end_time:"+kpi_end_time +" ;Planned Production time:"+ Things[line_name].planned_production_time);
    
//result= currentTimeString +" ;\tMinute:"+currentMinuteString+" ;\tStart:"+shiftStartTimeString +" ;\tnewShift:"+newShift;