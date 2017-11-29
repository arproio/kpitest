function getTimeString(d){
    return d.toJSON();
}

logger.warn("UnitTest_Fixture_Util, getThingAllPropertiesWithValue start:"+thingName + "; withbackfill:"+withbackfill+" ; Start_time:"+ getTimeString(start_time) + " ;"+end_time);
var params = {
	thingName: thingName /* STRING */
};

// result: INFOTABLE dataShape: "undefined"
var propertyresult = me.getAllPropertiesWithValue(params);

var result = { dataShape: { fieldDefinitions : {} }, rows: [] };

var infotabledict = {};

for(var index=0; index< propertyresult.rows.length; index++){
    var propertyrow = propertyresult['rows'][index];
    
    if(propertyrow.baseType == 'INFOTABLE'){
        //result.dataShape.fieldDefinitions[propertyrow.name] = { name: propertyrow.name, baseType: propertyrow.baseType };
        
        var params = {
            oldestFirst: undefined /* BOOLEAN */,
            maxItems: 1 /* NUMBER */,
            propertyName: propertyrow.name /* STRING */,
            endDate: undefined /* DATETIME */,
            query: undefined /* QUERY */,
            startDate: undefined /* DATETIME */
        };

        // result: INFOTABLE dataShape: InfoTableValueStream
        var infotablepropertyresult = Things[thingName].QueryInfoTablePropertyHistory(params);
        var infoheaderarray = new Array();
        if(infotablepropertyresult.rows.length>0){
            var infovalue = infotablepropertyresult.rows[0].value;	//suppose an infotable
            // infotable datashape iteration
            var dataShapeFields = infovalue.dataShape.fields;
            
            for (var fieldName in dataShapeFields) {
                var infopropertyname = "frominfo_"+ dataShapeFields[fieldName].name;
                var infopropertytype = dataShapeFields[fieldName].baseType;
                //logger.warn('Unittest.Fixture_util:' + propertyrow.name +':field name is ' + infopropertyname + 'field basetype is ' + infopropertytype);
                result.dataShape.fieldDefinitions[infopropertyname] = { name: infopropertyname, baseType: String(infopropertytype) };
                infoheaderarray.push(infopropertyname);
            }
        }
        infotabledict[propertyrow.name] = infoheaderarray;
        //logger.debug("Unittest.Fixture_util::"+propertyrow.name+" has headers:"+infoheaderarray.length+ " values:"+infoheaderarray[0]);
        
    }else{
		result.dataShape.fieldDefinitions[propertyrow.name] = { name: propertyrow.name, baseType: propertyrow.baseType };
    }
}
//result.dataShape.fieldDefinitions['timestamp'] = { name: 'timestamp', baseType: 'DATETIME' };
//result.dataShape.fieldDefinitions['timestampstring'] = { name: 'timestampstring', baseType: 'STRING' };
result.dataShape.fieldDefinitions['timestamp'] = { name: 'timestamp', baseType: 'STRING' };

//logger.warn("UnitTest_Fixture_Util:"+result.toSource());
var hasStream = false;
var streamName;
var streamHeader = new Array();
try{
    streamName = Things[thingName].specialStreamName;
    if(!(streamName == undefined || streamName == null || streamName == '' || streamName.length<3)){
        hasStream = true;
    }
}catch(e){
    hasStream = false;
    logger.error("UnitTest_Fixture_Util, Thing:"+thingName+ " doesn't have specialStreamName property, TS*Consolidation may be missed in template");
}

if(hasStream){
    var params = {
        oldestFirst: undefined /* BOOLEAN */,
        maxItems: 1 /* NUMBER */,
        sourceTags: undefined /* TAGS */,
        endDate: undefined /* DATETIME */,
        query: undefined /* QUERY */,
        source: thingName /* STRING */,
        startDate: undefined /* DATETIME */,
        tags: undefined /* TAGS */
    };
    // result: INFOTABLE
    var oneresult = Things[streamName].QueryStreamData(params);
    if(oneresult.rows.length==0){
        hasStream = false;	//no data exist, doesn't need to proceed
    }else{
        // infotable datashape iteration
        var dataShapeFields = oneresult.dataShape.fields;
        for (var fieldName in dataShapeFields) {
            var property_name = dataShapeFields[fieldName].name;
            if(property_name != 'timestamp'){
                property_name = "fromstream_" + property_name
            	result.dataShape.fieldDefinitions[property_name] = { name: property_name, baseType: String(dataShapeFields[fieldName].baseType) };
                streamHeader.push(property_name);
            }
        }
    }
}

var rowindex = 0;
var timestampdict = {};


var statresult = { dataShape: { fieldDefinitions : {} }, rows: [] };
statresult.dataShape.fieldDefinitions['property_name'] = { name: 'property_name', baseType: 'STRING' };
statresult.dataShape.fieldDefinitions['value_count'] = { name: 'value_count', baseType: 'INTEGER' };


for(var index=0; index< propertyresult.rows.length; index++){
    var propertyrow = propertyresult['rows'][index];
    
    //logger.warn("Unittest.Fixture_util: Start to processing: " + propertyrow.name);
    
    var params = {
        propertyName: propertyrow.name /* STRING */,
        endDate: end_time /* DATETIME */,
        thingName: thingName /* STRING */,
        startDate: start_time /* DATETIME */,
        propertyType: propertyrow.baseType
    };

    // result: INFOTABLE dataShape: "undefined"
    var oneresult = me.getLoggedPropertiesValueForThingByType(params);
    logger.warn("Unittest.Fixture_util: Property Name:"+propertyrow.name+" has values:"+oneresult.rows.length);
    //start to record each property has how many values.
    var newEntry=new Object();
    newEntry.property_name = propertyrow.name;
    newEntry.value_count = oneresult.rows.length;
    statresult.rows[index] = newEntry;
	//logger.warn("Unittest.Fixture_util:" + propertyrow.name + " has result:"+oneresult.rows.length);
    
    for(var onerowindex=0;onerowindex<oneresult.rows.length;onerowindex++){
        
		var onerow = oneresult.rows[onerowindex];
        //logger.warn("Unittest.Fixture_util: We are " + propertyrow.name + " is:"+onerowindex + " and overall:"+rowindex +" with value:"+onerow.value);
        
        
    	//var timestampstring = dateFormat(onerow.timestamp,'yyyyMMddHHmmssfff');
        //var d = onerow.timestamp;
        //var timestampstring = d.getFullYear()+"/"+(d.getMonth()+1)+"/"+d.getDate() + " "+ d.getHours()+":"+d.getMinutes()+":"+d.getSeconds()+" "+d.getMilliseconds();
        var timestampstring = getTimeString(onerow.timestamp);
        
        if(/*timestampstring in timestampdict*/ timestampdict.hasOwnProperty(timestampstring)){
            //logger.warn("Unittest.Fixture_util: found:"+timestampstring +" with value:"+timestampdict[timestampstring]);
            var oldindex = timestampdict[timestampstring];
            var oldEntry = result.rows[oldindex];
           	
            if(propertyrow.baseType == "INFOTABLE"){
                //oldEntry[propertyrow.name] = onerow.value;
                var infoheaderarray = infotabledict[propertyrow.name];
                var infofieldvalues = onerow.value;
                if(infofieldvalues.rows.length>0){
                    for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                        oldEntry[infoheaderarray[headerindex]] = infofieldvalues.rows[0][infoheaderarray[headerindex].substring(9)];
                    }
                }
            }else{
            	oldEntry[propertyrow.name] = onerow.value;
            }
            //if(propertyrow.baseType != "BOOLEAN") logger.warn("Unittest.Fixture_util:" + timestampstring + " -- has old index:"+oldindex +" just update value:"+onerow.value);
            
        }else{
            var newEntry= new Object();
            if(propertyrow.baseType == "INFOTABLE"){
                var infoheaderarray = infotabledict[propertyrow.name];
                var infofieldvalues = onerow.value;
                if(infofieldvalues.rows.length>0){
                    for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                        newEntry[infoheaderarray[headerindex]] = infofieldvalues.rows[0][infoheaderarray[headerindex].substring(9)];
                    }
                }
                
            }else{
            	newEntry[propertyrow.name] = onerow.value;
            }
            newEntry['timestamp'] = timestampstring /*onerow.timestamp*/;
            //newEntry['timestampstring'] = timestampstring;
            result['rows'][rowindex] = newEntry;
            
            timestampdict[timestampstring] = rowindex;
            //if(propertyrow.baseType != "BOOLEAN") logger.warn("Unittest.Fixture_util:" + timestampstring + " -- has index:"+rowindex +" just add value:"+onerow.value);
            //logger.warn("Unittest.Fixture_util: after new:"+timestampstring +" with value:"+timestampdict[timestampstring]);
            rowindex = rowindex + 1;
        }
    }
}
//logger.warn("UnitTest_Fixture_Util: hasStream:"+hasStream + " and name:"+streamName);
if(hasStream){
    
    var params = {
        oldestFirst: false /* BOOLEAN */,
        maxItems: 86401 /* NUMBER */,
        sourceTags: undefined /* TAGS */,
        endDate: end_time /* DATETIME */,
        query: undefined /* QUERY */,
        source: thingName /* STRING */,
        startDate: start_time /* DATETIME */,
        tags: undefined /* TAGS */
    };

    // result: INFOTABLE
    var streamresult = Things[streamName].QueryStreamData(params);
    for(var streamindex=0;streamindex<streamresult.rows.length;streamindex++){
        var onerow = streamresult.rows[streamindex];
        //var d = onerow.timestamp;
        //var timestampstring = d.getFullYear()+"/"+(d.getMonth()+1)+"/"+d.getDate() + " "+ d.getHours()+":"+d.getMinutes()+":"+d.getSeconds()+" "+d.getMilliseconds();
        var timestampstring = getTimeString(onerow.timestamp);
        if(/*timestampstring in timestampdict*/ timestampdict.hasOwnProperty(timestampstring)){
            //logger.warn("Unittest.Fixture_util: may find:"+timestampstring +" with value:"+timestampdict[timestampstring]);
            var oldindex = timestampdict[timestampstring];
            var oldEntry = result.rows[oldindex];
            for(var headerindex = 0; headerindex < streamHeader.length; headerindex++){
                oldEntry[streamHeader[headerindex]] = onerow[streamHeader[headerindex].substring(11)];
            }
        }else{
            var newEntry= new Object();
            for(var headerindex = 0; headerindex < streamHeader.length; headerindex++){
                newEntry[streamHeader[headerindex]] = onerow[streamHeader[headerindex].substring(11)];
            }
            newEntry['timestamp'] = timestampstring /*onerow.timestamp*/;
            //newEntry['timestampstring'] = timestampstring;
            result['rows'][rowindex] = newEntry;
            
            timestampdict[timestampstring] = rowindex;
            //if(propertyrow.baseType != "BOOLEAN") logger.warn("Unittest.Fixture_util:" + timestampstring + " -- has index:"+rowindex +" just add value:"+onerow.value);
            
            rowindex = rowindex + 1;
        }
    }
}


if(withbackfill){
    //var d = start_time;
    //var timestampstring = d.getFullYear()+"/"+(d.getMonth()+1)+"/"+d.getDate() + " "+ d.getHours()+":"+d.getMinutes()+":"+d.getSeconds()+" "+d.getMilliseconds();
    var starttimestring = getTimeString(start_time);
    logger.warn("UnitTest_Fixture_Util getThingAllPropertiesWithValue, backfilled first time:"+starttimestring);
    if( !(/*starttimestring in timestampdict*/ timestampdict.hasOwnProperty(timestampstring))){
        var newEntry = new Object();
        newEntry['timestamp'] = starttimestring /*start_time*/;
        //newEntry['timestampstring']=starttimestring;
        result['rows'][rowindex] = newEntry;
        rowindex = rowindex + 1;
    }
}


var params = {
	sortColumn: 'timestamp' /* STRING */,
	t: result /* INFOTABLE */,
	ascending: false /* BOOLEAN */
};

// result: INFOTABLE
var result = Resources["InfoTableFunctions"].Sort(params);

if(withbackfill){
    logger.warn("UnitTest.Fixture_Util: Start to process with back fill. properties:" + propertyresult.rows.length);
    for(var index=0; index< propertyresult.rows.length; index++){
        var propertyrow = propertyresult['rows'][index];
        var infoheaderarray;
        var defaultvaluedict = {};	//default value dict for infotable properties.
        
        if(propertyrow.baseType == 'INFOTABLE'){
        	infoheaderarray = infotabledict[propertyrow.name];
            if(infoheaderarray == undefined || infoheaderarray == null || infoheaderarray.length==0){
                logger.warn("UnitTest.Fixture_Util: this infotable will not be processed:"+propertyrow.name);
                continue;	//we don't need to process blank header for nested infotable.
            }
        }
            
        var params = {
            propertyName: propertyrow.name /* STRING */,
            endDate: start_time /* DATETIME */,
            propertyType: propertyrow.baseType /* STRING */,
            thingName: thingName /* STRING */
        };

        // result: INFOTABLE dataShape: "undefined"
        var oneresult = me.getLoggedPropertiesValueForThingByTypeSingle(params);
		
		//by assumption, it should have one row record here, if not, it's just doesn't have value before the start_time.
        if(oneresult.rows.length>0){
            //yes, has value before start_time.
            var defaultvalue=oneresult.value;	//default value for none infotable property
            
            if(propertyrow.baseType == 'INFOTABLE'){
                //logger.warn("UnitTest.Fixture_Util: setup default value for:"+propertyrow.name);
                for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                    //setup default value dict for nested infotable fields.
                    defaultvaluedict[infoheaderarray[headerindex]] = defaultvalue.rows[0][infoheaderarray[headerindex].substring(9)];
                }
                //logger.warn("UnitTest.Fixture_Util: 2 defaultvaluedict:"+defaultvaluedict.toSource());
            }
            
            for(var rowindex = result.rows.length-1;rowindex >= 0; rowindex--){
                if(propertyrow.baseType == 'INFOTABLE'){
                    //in order to detect cell value, I have to detect all fields from infotable.
                    var infotablegrouphasvalue = false;	//whether this infotable originally is blank.
                    for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                        //check existing value dict for nested infotable fields.
                        var singlecellvalue = result.rows[rowindex][infoheaderarray[headerindex]];
                        if(! (singlecellvalue == undefined || singlecellvalue == null || singlecellvalue == '')){
                            infotablegrouphasvalue = true;
                            break;
                        }
                    }
                    if(infotablegrouphasvalue){
                        //copy current value to default dict
                        for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                            defaultvaluedict[infoheaderarray[headerindex]] = result.rows[rowindex][infoheaderarray[headerindex]];
                        }
                    }else{
                        //copy default value dict cell to result cell
                        for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                            result.rows[rowindex][infoheaderarray[headerindex]] = defaultvaluedict[infoheaderarray[headerindex]] ;
                        }
                    }

                }else{  //non-infotable properties
                    var cellvalue = result.rows[rowindex][propertyrow.name];	//get row cell value for none infotable fields.
                	if(cellvalue == undefined || cellvalue == null || cellvalue ==''){
                        result.rows[rowindex][propertyrow.name] = defaultvalue;
                    }else{
                        defaultvalue = cellvalue;
                    }
                }
            }
        }else{
            logger.debug("UnitTest.Fixture_Util:"+propertyrow.name+" has no value before:"+start_time);
            //two choices for back fill. option 1 is to use default value, option 2 is to keep empty until first
            //one has value.
            //go with option 2.
            var firstvaluefound = false;
            for(var rowindex = result.rows.length-1;rowindex >= 0; rowindex--){
                if(propertyrow.baseType == 'INFOTABLE'){
                    var infotablegrouphasvalue = false;	//whether this infotable originally is blank.
                    for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                        //check existing value dict for nested infotable fields.
                        var singlecellvalue = result.rows[rowindex][infoheaderarray[headerindex]];
                        if(! (singlecellvalue == undefined || singlecellvalue == null || singlecellvalue == '')){
                            infotablegrouphasvalue = true;
                            break;
                        }
                    }

                    //if it has value and firstvaluefound is false, then initialize default value.
                    if(infotablegrouphasvalue ){
                        //initialize or copy new default value.
                        for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                            //setup default value dict for nested infotable fields.
                            defaultvaluedict[infoheaderarray[headerindex]] = result.rows[rowindex][infoheaderarray[headerindex]];
                        }
                        if(!firstvaluefound){
                            firstvaluefound = true;    
                        }
                    }else{
                        if(firstvaluefound){
                            //back fill
                            for(var headerindex = 0; headerindex<infoheaderarray.length; headerindex++){
                                //setup default value dict for nested infotable fields.
                                result.rows[rowindex][infoheaderarray[headerindex]] = defaultvaluedict[infoheaderarray[headerindex]];
                            }
                        }
                    }
                }else{
                    //for non-infotable property.
                    var cellvalue = result.rows[rowindex][propertyrow.name];	//get row cell value for none infotable fields.
                	if(cellvalue == undefined || cellvalue == null || cellvalue ==''){
                        if(firstvaluefound){
                            result.rows[rowindex][propertyrow.name] = defaultvalue;
                        }
                    }else{
                        defaultvalue = cellvalue;
                        if(!firstvaluefound){
                            firstvaluefound = true;
                        }
                    }
                }
            }

        }
    }
    if(hasStream){
        //back fill stream properties value.
        var params = {
            oldestFirst: undefined /* BOOLEAN */,
            maxItems: 1 /* NUMBER */,
            sourceTags: undefined /* TAGS */,
            endDate: start_time /* DATETIME */,
            query: undefined /* QUERY */,
            source: thingName /* STRING */,
            startDate: undefined /* DATETIME */,
            tags: undefined /* TAGS */
        };
        // result: INFOTABLE
        var oneresult = Things[streamName].QueryStreamData(params);
        var defaultvaluedict = {};
        var hasDefault = false;
        if(oneresult.rows.length>0){
            //setup default value.
            for(var headerindex=0;headerindex<streamHeader.length;headerindex++){
                defaultvaluedict[streamHeader[headerindex]] = oneresult.rows[0][streamHeader[headerindex].substring(11)];
            }
            hasDefault = true;
        }
        
        var firstvaluefound = false;
        for(var rowindex = result.rows.length-1;rowindex >= 0; rowindex--){
            var streamgrouphasvalue = false;
            
            var row = result.rows[rowindex];
            for(var headerindex=0;headerindex<streamHeader.length;headerindex++){
                var cellvalue = row[streamHeader[headerindex]];
                if( !(cellvalue == undefined || cellvalue == null || cellvalue == '')){
                    streamgrouphasvalue = true;
                    break;
                }
            }
            
            if( !streamgrouphasvalue && !hasDefault){
                continue;
            }
            if(streamgrouphasvalue){
                for(var headerindex=0;headerindex<streamHeader.length;headerindex++){
                    defaultvaluedict[streamHeader[headerindex]] = row[streamHeader[headerindex]];
                }
                hasDefault = true;
            }
            if(!streamgrouphasvalue && hasDefault){
                for(var headerindex=0;headerindex<streamHeader.length;headerindex++){
                     result.rows[rowindex][streamHeader[headerindex]] = defaultvaluedict[streamHeader[headerindex]];
                }
            }
        }
    }
    
    
}

var finalresult = { dataShape: { fieldDefinitions : {} }, rows: [] };
finalresult.dataShape.fieldDefinitions['data'] = { name: 'data', baseType: 'INFOTABLE' };
finalresult.dataShape.fieldDefinitions['stat'] = { name: 'stat', baseType: 'INFOTABLE' };
var newEntry = new Object();
newEntry.data = result;
newEntry.stat = statresult;
finalresult.rows[0] = newEntry;

result = finalresult;


//logger.warn("UnitTest_Fixture_Util,withbackfill:"+withbackfill+", final result:"+result.ToJSON());

