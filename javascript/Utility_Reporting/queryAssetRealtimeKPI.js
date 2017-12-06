//for(var assetinfo in assetInfo.assetInfo){
//    logger.warn("data:"+assetinfo.assetID);
//}

var result = { dataShape: { fieldDefinitions : {} }, rows: [] };
result.dataShape.fieldDefinitions['assetID']={name:'assetID',baseType:'STRING'};
//result.dataShape.fieldDefinitions['granularity']={name:'granularity',baseType:'STRING'};
//result.dataShape.fieldDefinitions['startDate']={name:'startDate',baseType:'STRING'};
//result.dataShape.fieldDefinitions['endDate']={name:'endDate',baseType:'STRING'};
result.dataShape.fieldDefinitions['message']={name:'message',baseType:'STRING'};
result.dataShape.fieldDefinitions['result']={name:'result',baseType:'INFOTABLE'};
try{
    for(var index=0;index<assetInfo.array.length;index++){
		var assetID = assetInfo.array[index].assetID;
        var params = {
            assetID: assetID /* STRING */,
            lineID: assetInfo.array[index].lineID /* STRING */,
            lineName: assetInfo.array[index].lineName /* STRING */
        };
		
        //logger.warn("Utility_Reporting, Thing params to validate:"+params.toSource());
        // result: BOOLEAN
        var validationresult = me.validateAssetAndLine(params);
        
        
        
        //20171122 update to include sensor data in package.
		var oneassetresult = { dataShape: { fieldDefinitions : {} }, rows: [] };
        var oneNewEntry = new Object();
        //one asset result includes data from realtime kpi table and then stream and then infotable and then individual properties.
        
		//result.dataShape.fieldDefinitions['assetID']={name:'assetID',baseType:'STRING'};
        if(validationresult){
            var foundheaders = new Array();
            foundheaders.push('name');
            foundheaders.push('description');
            foundheaders.push('thingTemplate');
            var querystring = "select *,update_date as timestamp from cognipro.realtime_kpiresults where machine_id='" + assetID +"' order by update_date desc limit 1";
            try{
				// result: INFOTABLE
                var realtimekpiresult = Things["DB_Reporting_External"].generalQuery({query: querystring});
                //merge realtime_kpi table into real time data.
                if(realtimekpiresult.rows.length>0){
                    // infotable datashape iteration
                    var dataShapeFields = realtimekpiresult.dataShape.fields;
                    for (var fieldName in dataShapeFields) {
                        oneassetresult.dataShape.fieldDefinitions[dataShapeFields[fieldName].name]={name:dataShapeFields[fieldName].name,baseType:String(dataShapeFields[fieldName].baseType)};
                        oneNewEntry[dataShapeFields[fieldName].name]=realtimekpiresult.rows[0][dataShapeFields[fieldName].name];
                        foundheaders.push(dataShapeFields[fieldName].name);
                        
                        //logger.warn('Utility_Reporting, foundheaders.push(dataShapeFields[fieldName].name) ' + dataShapeFields[fieldName].name);
                    }
                }
                //logger.warn("Utility_Reporting, step 1: realtimekpiresult:"+realtimekpiresult.ToJSON());
                //merge stream data into result.
                var hasStream = false;
                var streamName;
                try{
                    streamName = Things[assetID].specialStreamName;
                    if(!(streamName == undefined || streamName == null || streamName == '' || streamName.length<3)){
                        hasStream = true;
                    }
                }catch(e){
                    hasStream = false;
                    logger.error("Utility_Reporting, Thing:"+assetID+ " doesn't have specialStreamName property, TS*Consolidation may be missed in template");
                }
                //setup property from stream
                //logger.warn("Utility_Reporting, step 2:"+params.toSource());
                if(hasStream){
                    var params = {
                        oldestFirst: false /* BOOLEAN */,
                        maxItems: 1 /* NUMBER */,
                        sourceTags: undefined /* TAGS */,
                        endDate: undefined /* DATETIME */,
                        query: undefined /* QUERY */,
                        source: assetID /* STRING */,
                        startDate: undefined /* DATETIME */,
                        tags: undefined /* TAGS */
                    };

                    // result: INFOTABLE
                    var streamresult = Things[streamName].QueryStreamData(params);
                    if(streamresult.rows.length>0){
                        var dataShapeFields = streamresult.dataShape.fields;
                        for (var fieldName in dataShapeFields) {
                            oneassetresult.dataShape.fieldDefinitions[dataShapeFields[fieldName].name]={name:dataShapeFields[fieldName].name,baseType:String(dataShapeFields[fieldName].baseType)};
                            oneNewEntry[dataShapeFields[fieldName].name]=streamresult.rows[0][dataShapeFields[fieldName].name];
                            foundheaders.push(dataShapeFields[fieldName].name);
                            //logger.warn('Utility_Reporting, Stream Processing field name is ' + dataShapeFields[fieldName].name);
                            //logger.warn('field basetype is ' + dataShapeFields[fieldName].baseType);
                        }
                    }
                }
                //logger.warn("Utility_Reporting, step 3:"+params.toSource());
                //merge info table results.
                // result: INFOTABLE
                //logger.warn("Utility_Reporting for thing:"+assetID);
                var propertiesresult = Things[assetID].GetPropertyValues();
				if(propertiesresult.rows.length>0){
                    var dataShapeFields = propertiesresult.dataShape.fields;
                    
                    //logger.warn("Utility_Reporting, step 3.1:"+params.toSource());
                    
                    for (var fieldName in dataShapeFields) {
                        if(String(dataShapeFields[fieldName].baseType) === 'INFOTABLE'){
                            //logger.warn('Utility_Reporting, Infotable fields Processing field name is ' + dataShapeFields[fieldName].name +" with datasize:"+propertiesresult.rows.length);
                            var infofeildvalue = propertiesresult.rows[0][dataShapeFields[fieldName].name];
                            if(infofeildvalue===undefined || infofeildvalue===null){
                                continue;
                            }
                            if(infofeildvalue.rows.length==0){
                                logger.warn("Utility_Reporting, an infotable has 0 rows:"+dataShapeFields[fieldName].name);
                                continue
                            }
                                                        
                            var infoDataShapeFields = infofeildvalue.dataShape.fields;
                            for(var infoFieldName in infoDataShapeFields){
                                if(foundheaders.indexOf(infoDataShapeFields[infoFieldName].name) === -1){
                                    oneassetresult.dataShape.fieldDefinitions[infoDataShapeFields[infoFieldName].name]={name:infoDataShapeFields[infoFieldName].name,baseType:String(infoDataShapeFields[infoFieldName].baseType)};
                                    oneNewEntry[infoDataShapeFields[infoFieldName].name]=infofeildvalue.rows[0][infoDataShapeFields[infoFieldName].name];
                                    foundheaders.push(infoDataShapeFields[infoFieldName].name);
                                    //logger.warn('Utility_Reporting, Infotable subfields Processing field name is ' + dataShapeFields[fieldName].name);
                                }
                            }
                            //logger.warn("Utility_Reporting, step 3.3:"+params.toSource());
                        }
                    }
                    //logger.warn("Utility_Reporting, step 5:"+params.toSource());
                    for (var fieldName in dataShapeFields) {
                        if(String(dataShapeFields[fieldName].baseType) !== 'INFOTABLE'){
                            //logger.warn('Utility_Reporting, Infotable fields Processing field name2 is ' + dataShapeFields[fieldName].name +" with datasize:"+propertiesresult.rows.length);
                            if(foundheaders.indexOf(dataShapeFields[fieldName].name) !== -1){
                                //logger.warn('Utility_Reporting, duplicated individual Processing field name is ' + dataShapeFields[fieldName].name);
                                continue;
                            }
                            var fieldvalue = propertiesresult.rows[0][dataShapeFields[fieldName].name];
                            if(fieldvalue===undefined || fieldvalue===null){
                                continue;
                            }
                            
                            oneassetresult.dataShape.fieldDefinitions[dataShapeFields[fieldName].name]={name:dataShapeFields[fieldName].name,baseType:String(dataShapeFields[fieldName].baseType)};
                            oneNewEntry[dataShapeFields[fieldName].name]=propertiesresult.rows[0][dataShapeFields[fieldName].name];
                            foundheaders.push(dataShapeFields[fieldName].name);
                            //logger.warn('Utility_Reporting, individual Processing field name is ' + dataShapeFields[fieldName].name);
                        }
                    }
                }
                //logger.warn("Utility_Reporting, step 6:"+params.toSource());
                //logger.warn('Utility_Reporting, individual Processing finished! :'+assetID);
                //alarm sum handling.
                
                var params = {
                    thingName: assetID /* STRING */
                };

                // result: INFOTABLE dataShape: Unittest_DS_AlarmsumResult
                var alarmresult = Things["UnitTest.DB_External"].query_alarm_state_timesum_realtime(params);
				for(var alarmsumindex=0;alarmsumindex<alarmresult.rows.length;alarmsumindex++){
                    var row = alarmresult.rows[alarmsumindex];
                    var propertyName = row.property_name;
                    if(foundheaders.indexOf(propertyName) !== -1){
                        oneNewEntry[propertyName] = row.property_sum;
                    }else{
                        oneassetresult.dataShape.fieldDefinitions[propertyName]={name:propertyName,baseType:"NUMBER"};
                        oneNewEntry[propertyName] = row.property_sum;
                    }
                }
				//logger.warn('Utility_Reporting, query_alarm_state_timesum_realtime! :'+assetID);
                
                oneassetresult['rows'][0] = oneNewEntry;

                var newEntry = new Object();
                newEntry.assetID = assetInfo.array[index].assetID;
                if(oneassetresult.rows.length>0){
                	newEntry.message = "MessageID_145";	//since it's impossible for one asset doesn't have any value, therefore this will be MessageID_145 always.
                }else{
                	newEntry.message = "MessageID_107";
                }
                
                newEntry.result = oneassetresult;
                result.rows[index]=newEntry;
            }catch(e){
                logger.error("Utility_Reporting: queryAssetRealtimeKPI error:"+e + " assetID:"+assetInfo.array[index].assetID);
                var newEntry = new Object();
                newEntry.assetID = assetInfo.array[index].assetID;
                newEntry.message = "MessageID_146";	//System Error, but indeed DB connection error.
                //newEntry.result = singleresult;
                result.rows[index]=newEntry;

            }
        }else{
            logger.warn("Utility_Reporting: queryAssetRealtimeKPI warn: unauthorized access");
            var newEntry = new Object();
            newEntry.assetID = assetInfo.array[index].assetID;
            newEntry.message = "MessageID_103";	//Authentication error.
            //newEntry.result = singleresult;
            result.rows[index]=newEntry;
        }
    }
}catch(e){
    logger.error("queryAssetRealtimeKPI in Utility_Reporting:"+e);
    var newEntry = new Object();
    //newEntry.assetID = assetInfo.array[index].assetID;
    newEntry.message = "MessageID_146";	//System Error, but indeed DB connection error.
    //newEntry.result = singleresult;
    result.rows[0]=newEntry;
}