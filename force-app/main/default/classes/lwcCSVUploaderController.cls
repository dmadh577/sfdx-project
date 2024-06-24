/*This code reads a CSV file and processes its contents. It removes double quotes from the CSV line and splits it
into an array of values.  if certain fields are blank or contain invalid values. If any of these checks fail, 
the line is added to a list of failed rows and an error message is added to a list of error messages. 
If the line passes all the checks, the code creates a new record in Salesforce. It checks if the record is a 
duplicate by comparing certain fields with existing records. If the record is a duplicate, it is added to the list 
of failed rows and an error message is added to a list of error messages. If the record is not a duplicate, 
it is added to a map of new records to be created later. The code also creates maps of certain objects to be used 
later in the processing.*/

public with sharing class lwcCSVUploaderController {
    public static List<String> errorMsgList = new List<String>();
    public static List<String> failedRows = new List<String>();
    public static Map<Integer,List<String>> failedRowsMap = new Map<Integer,List<String>>();
    public static Map<String,set<Integer>> failedRowsMapIndex = new Map<String,set<Integer>>();
    public static Map<String,String> failedRowsMapIndex1 = new Map<String,String>();
    public static Map<Integer,string>csvDatamap=new Map<Integer,string>();
    public static Map<string,Integer>csvDatamap1=new Map<string,Integer>();
    //public static Integer indexValue;
    public static String csvRows;
    public static String errorMsg;
    public static String lanenameexcel;
    public static Integer failedCount = 0;
    //public static Integer[] failedRowsNo = new Integer[]{};
    public static Boolean skipRec = false;
    public static List<String> laneNameList = new list<String>();
    public static List<String> validRateMethodsList = new List<String>();
    public static List<String> validStateValuesList = new List<String>();
    public static List<String> validCountryValuesList = new List<String>();
    public static Map<String, rtms__Zone__c> validZoneNamesMap = new Map<String, rtms__Zone__c>();
    public static Map<String, Account> validLocationNamesMap = new Map<String, Account>();
    public static Map<String, rtms__Accessorial__c> validAccessorialNamesMap = new Map<String, rtms__Accessorial__c>();
    public static Map<String,rtms__FuelSurcharge__c> validFSCNamesMap = new Map<String,rtms__FuelSurcharge__c>();
    public static Map<String, Account> validTerminalNamesMap = new Map<String, Account>();
    public static Map<String, Commodity__c> validCommodityNamesMap = new Map<String, Commodity__c>();
    public static Map<String, rtms__Mode__c> validModeNamesMap = new Map<String, rtms__Mode__c>();
    public static Map<String, String> csvimportMap1 = new Map<String, String>();
    public static Map<String, String> csvimportMap = new Map<String, String>();
    public static Map<String, rtms__Lane__c> newLaneMap = new Map<String, rtms__Lane__c>();
    public static Map<String, Account> dupLaneMap = new Map<String, Account>();
    public static List<Account> accList=new List<Account>();
    public static boolean dupFail=false;
    public static lwcCSVUploaderController__c lwcCSVcustomsetting=lwcCSVUploaderController__c.getValues('fileUploadRateEntry');
    public static Map<string,string> rateentryRatetypePicval=new Map<string,string>();
    public static Map<string,string> rateentryPricetypesubmitted=new Map<string,string>();
    public static Map<string,string> calcuPriceTypePickval=new Map<string,string>();
    public static final string FreightAccessorial  = 'Freight+Accessorial';
    public static final string FreightFuelAccessorial  =  'Freight+Fuel+Accessorial';
    public static final string FreightFuel = 'Freight+Fuel';
    public static final string Freight = 'Freight';
    public static final string Accessorial = 'Accessorial';
    
    public static final string Base='Base'; 
    public static final string Fuel ='Fuel';
    
    public static final string rateEntry  = 'rtms__RateEntry__c';
    public static final string rateType ='rtms__Rate_Type__c';
    public static final string priceType = 'Price_Type_Submitted__c';
    public static final string rcCalctype = 'rtms__Calculation_Type__c';
    public static final string reCalc = 'rtms__RateEntryCalculation__c';
    public static final string rate_Method = 'rtms__Rate_Method__c';
    public static final string Lane = 'rtms__Lane__c';
    public static final string Origin_State_Province = 'rtms__Origin_State_Province__c';
    public static final string Origin_Country= 'rtms__Origin_Country__c';
    public static final string Pricing_Notes = 'Pricing Notes';
    public static final string Asset_Only ='Asset Only';
    public static final string Brokerage_Only =    'Brokerage Only';
    
    @AuraEnabled
    public static string uploadQueueable(Id contentDocumentId, string tpId,string modeId, string rateMethod, string rfpId, string status, string quoteId, date effDate, date expDate){
        try{
            TriggerHandlerRateEntry.shouldRunTrigger = false;
            
            ContentVersion contentVersionObj = [ SELECT Id, VersionData FROM 
                                                ContentVersion WHERE 
                                                ContentDocumentId =:contentDocumentId ];
            list<rtms__Lane__c> laneList = new list<rtms__Lane__c>();
            rateentryRatetypePicval=getPickList(rateEntry,rateType);
            rateentryPricetypesubmitted=getPickList(rateEntry,priceType);
            calcuPriceTypePickval=getPickList(reCalc,rcCalctype);
            
            List<rtms__RateEntry__c> existingrateEntries =  [SELECT Id, rtms__Lane__r.Name,Lane_Name__c,Commodity__r.Name,rtms__Category__c,
                                                            rtms__Mode2__r.Name,rtms__Effective_Date__c,rtms__Expiration_Date__c,
                                                            rtms__Minimum_Weight__c,rtms__Rate_Type__c,Price_Type_Submitted__c,
                                                            Terminal1__r.Name, rtms__Status__c, rtms__Accessorial__r.Name
                                                            FROM rtms__RateEntry__c WHERE rtms__Transportation_Profile__c  =: tpId];
            Set<String> existingLaneNames = new Set<String>();
            Map<String, rtms__RateEntry__c> duplicateMaps = new Map<String, rtms__RateEntry__c>();
            for(rtms__RateEntry__c rateEntry : existingrateEntries){
                existingLaneNames.add(rateEntry.Lane_Name__c);
                duplicateMaps.put(rateEntry.Lane_Name__c,rateEntry);
            }
            
            Map<String, rtms__RateEntry__c> newRateEntryMap = new Map<String, rtms__RateEntry__c>();
            Map<String, rtms__RateEntry__c> newRateEntryAccessMap = new Map<String, rtms__RateEntry__c>();
            //List<rtms__RateEntry__c> newRateEntryList = new List<rtms__RateEntry__c>();
            
            Map<String, rtms__RateEntryAccessorial__c> rateEntryAccessorialMap = new Map<String, rtms__RateEntryAccessorial__c>();
            map<String, String> failedaccessorialMap = new Map<String, String>();
            map<String, String> failedRateEntryMap = new Map<String, String>();
            Integer successCount = 0;
            List<rtms__Lane__c> insertLaneList = new List<rtms__Lane__c>();
            String data= contentVersionObj.VersionData.toString();
            //String lanenameexists;
            List<String> failedRows = new List<String>();
            String[] csvFileLines=data.split('\n');
            //to get all valid picklist values.
            //validRateMethodsList = getValidRateMethodsList();
            validRateMethodsList = getPickListlabels(reCalc, rate_Method);
            //validStateValuesList = getValidStateValuesList();
            validStateValuesList =getPickListlabels(Lane, Origin_State_Province);
            //validCountryValuesList = getValidCountryValuesList();
            validCountryValuesList = getPickListlabels(Lane, Origin_Country);
            validZoneNamesMap = getValidZoneNames();
            accList=getallAccounts();
            validLocationNamesMap = getvalidLocationNames(accList);
            dupLaneMap=getduplicateLocationNames(accList);
            validAccessorialNamesMap = getvalidAccessorialNames();
            validFSCNamesMap = getvalidFSCNames();
            validModeNamesMap = getvalidModeNames();
            validCommodityNamesMap = getvalidCommodityNames();
            validTerminalNamesMap = getvalidTerminalNames();
            
            
            //start reading the CSV file record by record and validating the data.
            for(Integer i=1;i<csvFileLines.size();i++){
                validateFields(i, lanenameexcel, csvFileLines, failedaccessorialMap,laneNameList,newLaneMap, effDate, expDate,rfpId, tpId, status, quoteId, newRateEntryAccessMap, duplicateMaps, existingLaneNames, newRateEntryMap, rateEntryAccessorialMap, csvimportMap, csvimportMap1);
            }
            
            //system.debug('failedaccessorialMap--'+JSON.serializePretty(failedaccessorialMap));
            //system.debug('rateEntryAccessorialMap--'+JSON.serializePretty(rateEntryAccessorialMap));
            //system.debug('newRateEntryMap--'+JSON.serializePretty(newRateEntryMap));
            //system.debug('csvimportMap1--'+JSON.serializePretty(csvimportMap1));
            //system.debug('csvimportMap--'+JSON.serializePretty(csvimportMap));
            //system.debug('csvimportMap--'+JSON.serializePretty(newLaneMap));
            //system.debug('failedrows--'+JSON.serializePretty(failedRows));
            for(String failedKey : failedaccessorialMap.keySet()){
                for(String mapKey : rateEntryAccessorialMap.keySet()){
                    rtms__RateEntryAccessorial__c accrecord = rateEntryAccessorialMap.get(mapKey);
                    String failedlanenameexcel = accrecord.Lane_name__c;
                    
                    if(mapKey.contains(failedKey)){
                        
                        rateEntryAccessorialMap.remove(mapKey);
                        for(String importkey :csvimportMap1.keySet()){
                            
                            if(importkey.contains(failedKey)){
                                String failedrecord = csvimportMap1.get(importkey);
                                string failedlanenameexcel1=failedRowsMapIndex1.get(importkey);
                                integer validIndex=csvDatamap1.get(failedlanenameexcel1);
                                
                                Integer Count = 0;
                                for (String str : csvFileLines) {
                                    if (str == failedrecord) {
                                        count++;
                                    }
                                }
                                
                                Integer Countnew = 0;
                                String cleanedCsvRows = csvRows.replaceAll('[^a-zA-Z0-9]', '');
                                String cleanedrow = failedrecord.replaceAll('[^a-zA-Z0-9]', '');
                                Countnew = cleanedCsvRows.split(cleanedrow, -1).size() - 1;
                                
                                if(Countnew<Count){
                                    if(csvRows==null){
                                        csvRows =failedrecord; 
                                    }
                                    if(csvRows!=null && !csvRows.toString().contains(failedrecord)){
                                        csvRows +=failedrecord;
                                    }
                                
                                    errorMsg = lwcCSVcustomsetting.NoRateEntryPresent__c+ ' "' + failedlanenameexcel1 + '"';
                                    errorMsgList.add(errorMsg);
                                    for(integer index:csvDatamap.keyset()){
                                        
                                        if(failedrecord==csvDatamap.get(index) && index==validIndex){
                                            if(failedRowsMap!=null){
                                                if( failedRowsMap.get(index)!=null){
                                                    if(!failedRowsMap.get(index).Contains(errorMsg)){
                                                    failedRowsMap.get(index).add(errorMsg);   
                                                    } 
                                                }
                                                else{
                                                    
                                                    failedRowsMap.put(index,new List<string>{errorMsg});   
                                                }
                                                
                                            }
                                            else{
                                                failedRowsMap.put(1,new List<string>{errorMsg});
                                            }
                                            
                                            break;                                                                      
                                        }
                                    }
                                }
                            }
                        }
                        failedCount++;
                    }
                }
                
                for(String rateKey : newRateEntryMap.keySet()){
                    if(failedKey.Contains(rateKey)){
                        rtms__RateEntry__c parentRateEntry = newRateEntryMap.get(rateKey);
                        
                        String failedlanenameexcel = parentRateEntry.Lane_name__c;
                        
                        if(parentRateEntry.rtms__Rate_Type__c == rateentryRatetypePicval.get(FreightAccessorial) || parentRateEntry.rtms__Rate_Type__c == FreightFuelAccessorial){
                            failedRateEntryMap.put(rateKey,failedlanenameexcel);
                        }
                        for(String importkey :csvimportMap1.keySet()){
                            
                            newRateEntryMap.remove(rateKey);
                            if(importkey.contains(rateKey)){
                                failedlanenameexcel=failedRowsMapIndex1.get(importkey);
                                integer validIndex=csvDatamap1.get(failedlanenameexcel);
                            
                                String failedrecord = csvimportMap1.get(importkey);
                                
                                Integer Count = 0;
                                for (String str : csvFileLines) {
                                    //system.debug('failedrecordfailedrecordstr'+str);
                                    if (str == failedrecord) {
                                        system.debug('123---');
                                        count++;
                                    }
                                }
                                Integer Countnew = 0;
                                String cleanedCsvRows = csvRows.replaceAll('[^a-zA-Z0-9]', '');
                                String cleanedrow = failedrecord.replaceAll('[^a-zA-Z0-9]', '');
                                Countnew = cleanedCsvRows.split(cleanedrow, -1).size() - 1;
                                if(Countnew<Count || Countnew == 0){
                                
                                    if(csvRows!=null && !csvRows.toString().contains(failedrecord)){
                                        csvRows +=failedrecord;
                                        
                                    }
                                    if(csvRows==null){
                                        csvRows =failedrecord;
                                    }
                                    
                                    errorMsg = lwcCSVcustomsetting.NoAccessorialspresent__c + ' "' + failedlanenameexcel + '"';
                                    errorMsgList.add(errorMsg);
                                    for(integer index:csvDatamap.keyset()){
                                        
                                        if(failedrecord==csvDatamap.get(index) && index== validIndex){
                                            if(failedRowsMap!=null){
                                                if(failedRowsMap.get(index)!=null){
                                                    failedRowsMap.get(index).add(errorMsg);  
                                                }
                                                else{
                                                    failedRowsMap.put(index,new List<string>{errorMsg});
                                                }
                                            }
                                            else{
                                                failedRowsMap.put(1,new List<string>{errorMsg});
                                                }
                                            break;
                                        }  
                                    }
                                }
                            }
                        }
                        failedCount++; 
                    }
                }
            }

            //to check rate entry and accessorial rate methods if include in freight is true.
            for(String rateKey : newRateEntryMap.keySet()){
                rtms__RateEntry__c parentRateEntry = newRateEntryMap.get(rateKey);
                String parentRateMethod = parentRateEntry.Rate_Method__c;
                //newRateEntryMap.remove(rateKey);
                if(parentRateEntry.rtms__Rate_Type__c == rateentryRatetypePicval.get(FreightAccessorial) || parentRateEntry.rtms__Rate_Type__c == FreightFuelAccessorial){
                    Boolean failedRec = false;
                    for(String mapKey : rateEntryAccessorialMap.keySet()){
                        if(mapKey.contains(rateKey)){
                            rtms__RateEntryAccessorial__c accrecord = rateEntryAccessorialMap.get(mapKey);
                            if(accrecord.Include_In_Freight__c && parentRateMethod !=accrecord.Rate_Method__c && !failedRec){
                                failedRec = true;
                                newRateEntryMap.remove(rateKey);
                                failedCount++;
                                String failedrecord = csvimportMap1.get(rateKey);
                                
                                if(csvRows!=null && failedrecord!=null && !csvRows.toString().contains(failedrecord) ){
                                    csvRows +=failedrecord;
                                    //system.debug('csvRows ==> after adding'+ JSON.serializePretty(csvRows));
                                }
                                if(csvRows==null && failedrecord!=null){
                                    csvRows =failedrecord;
                                }
                                
                                failedRateEntryMap.put(rateKey,parentRateMethod);
                                errorMsg = lwcCSVcustomsetting.RateEntryandAccessorial__c+' ' +rateKey;
                                errorMsgList.add(errorMsg);
                                for(integer index:csvDatamap.keyset()){
                                    
                                    if(failedrecord==csvDatamap.get(index)){
                                        
                                        if(failedRowsMap!=null){
                                            if( failedRowsMap.get(index)!=null)
                                            {
                                                failedRowsMap.get(index).add(errorMsg);
                                                
                                            }
                                            else{
                                                failedRowsMap.put(index,new List<string>{errorMsg});   
                                            }
                                        }
                                        else{
                                            failedRowsMap.put(1,new List<string>{errorMsg});
                                        }
                                        
                                        break;
                                    }
                                }
                            }     
                        }
                    }  
                }
            }
            
            //end of checking rate methods.
            
            //system.debug('failedRateEntryMap--'+JSON.serializePretty(failedRateEntryMap));
            //system.debug('rateEntryAccessorialMap-1-'+JSON.serializePretty(rateEntryAccessorialMap));
            for(String failedKey : failedRateEntryMap.keySet()){
                for(String mapKey : rateEntryAccessorialMap.keySet()){
                    rtms__RateEntryAccessorial__c accrecord = rateEntryAccessorialMap.get(mapKey);
                    String failedlanenameexcel = accrecord.Lane_name__c;
                    if(mapKey.contains(failedKey)){
                        rateEntryAccessorialMap.remove(mapKey);
                        for(String importkey :csvimportMap1.keySet()){
                            if(importkey.contains(failedKey)){
                                String failedrecord = csvimportMap1.get(importkey);
                                
                                Integer Count = 0;
                                for (String str : csvFileLines) {
                                    if (str == failedrecord) {
                                        count++;
                                    }
                                }
                                
                                Integer Countnew = 0;
                                String cleanedCsvRows = csvRows.replaceAll('[^a-zA-Z0-9]', '');
                                String cleanedrow = failedrecord.replaceAll('[^a-zA-Z0-9]', '');
                                Countnew = cleanedCsvRows.split(cleanedrow, -1).size() - 1;
                                
                                if(Countnew<Count){
                                    if(csvRows !=null && !csvRows.toString().contains(failedrecord)){
                                        csvRows +=failedrecord;  
                                    }
                                    if(csvRows == null){
                                        csvRows =failedrecord;
                                    }
                                    errorMsg = lwcCSVcustomsetting.NoAccessorialspresent__c+ ' ' + failedKey;
                                    errorMsgList.add(errorMsg);
                                    for(integer index:csvDatamap.keyset()){
                                        //system.debug('failedrecord4==>'+failedrecord);
                                        //system.debug('failedrecord Map==>'+csvDatamap.get(index));
                                        if(failedrecord==csvDatamap.get(index)){
                                            if(failedRowsMap!=null){
                                                if(/*indexValue!=null && */failedRowsMap.get(index)!=null){
                                                    failedRowsMap.get(index).add(errorMsg);  
                                                }
                                                else{
                                                    failedRowsMap.put(index,new List<string>{errorMsg});   
                                                }
                                                system.debug(errorMsg+' coming from ==>'+JSON.serializePretty(failedRowsMap.get(index)));
                                            }
                                            else{failedRowsMap.put(1,new List<string>{errorMsg});
                                                system.debug(errorMsg+' coming from ==>'+JSON.serializePretty(failedRowsMap.get(1)));
                                            }
                                            break;
                                        }
                                    }      
                                }
                            }
                        }   
                        failedCount++;   
                    }
                }
            }
            
            //system.debug('rateEntryAccessorialMap---2-'+JSON.serializePretty(rateEntryAccessorialMap));
            //system.debug('rateEntryAccessorialMapSize---2-'+rateEntryAccessorialMap.size() );
            //system.debug('newRateEntryMap-2-'+JSON.serializePretty(newRateEntryMap));
            //Added below code for no child check---start
            Set<String> myKeySet = new Set<String>();
            for(String key : rateEntryAccessorialMap.keySet()){
                Boolean rateentryexist = false;
                for(String rateKey : newRateEntryMap.keySet()){
                    if(key.contains(rateKey) && !rateentryexist){
                        rateentryexist = true;
                    }
                }if(!rateentryexist){
                    rateEntryAccessorialMap.remove(key);
                    
                    if(csvRows !=null && !csvRows.toString().contains(csvimportMap.get(key))){
                        csvRows += csvimportMap.get(key);
                    
                    }
                    if(csvRows==null){
                        csvRows = csvimportMap.get(key);
                    }
                    errorMsg = lwcCSVcustomsetting.NoRateEntryPresent__c+ ' "' + key + '"';
                    errorMsgList.add(errorMsg);
                    for(integer index:csvDatamap.keyset()){
                        
                        if(csvimportMap.get(key)==csvDatamap.get(index)){
                            if(failedRowsMap!=null){
                                if(failedRowsMap.get(index)!=null)
                                {
                                    if(!failedRowsMap.get(index).Contains(errorMsg)){
                                        failedRowsMap.get(index).add(errorMsg);  
                                    }   
                                }
                                else{
                                    failedRowsMap.put(index,new List<string>{errorMsg});   
                                }
                            } else{
                                failedRowsMap.put(1,new List<string>{errorMsg});
                            }
                            
                            break;
                        }
                    }
                    
                    failedCount++; 
                } else {
                    myKeySet.add(key);
                }
            }
            
            Boolean isPartialMatchFound = false;
            for(String rateKey : newRateEntryMap.keySet()){
                rtms__RateEntry__c freightentry = newRateEntryMap.get(rateKey);
                if(freightentry.rtms__Rate_Type__c==FreightFuelAccessorial || freightentry.rtms__Rate_Type__c==rateentryRatetypePicval.get(FreightAccessorial)){
                    isPartialMatchFound = false;
                    for(String s : myKeySet) {
                        if(s.contains(rateKey)) {
                            isPartialMatchFound = true;
                            break; // Stop the loop once a match is found
                        }
                    }
                    
                    if(!isPartialMatchFound){
                        newRateEntryMap.remove(rateKey);
                        
                        if(csvRows !=null && !csvRows.toString().contains(csvimportMap.get(rateKey))){
                            csvRows += csvimportMap.get(rateKey);
                        
                        }
                        if(csvRows==null){
                            csvRows += csvimportMap.get(rateKey);
                        }
                        
                        failedCount++;
                        errorMsg = lwcCSVcustomsetting.NoAccessorialspresent__c + ' "' + rateKey + '"';
                        errorMsgList.add(errorMsg);
                        for(integer index:csvDatamap.keyset()){
                        
                            if(csvimportMap.get(rateKey)==csvDatamap.get(index)){
                                if(failedRowsMap!=null){
                                    if( failedRowsMap.get(index)!=null)
                                    {
                                        failedRowsMap.get(index).add(errorMsg);  
                                    }
                                    else{
                                        failedRowsMap.put(index,new List<string>{errorMsg});   
                                    }
                                }
                                else{
                                    failedRowsMap.put(1,new List<string>{errorMsg});
                                }
                                break;
                            }
                        }
                    }
                }
            }
            
            //Added below code for no child check---End
            List<rtms__Lane__c> queriedlaneList = [select Id,Name from rtms__Lane__c where Name IN : laneNameList];
            //system.debug('laneNameList==='+JSON.serializePretty(laneNameList));
            //system.debug('queriedlaneList==='+JSON.serializePretty(queriedlaneList));
            for(String lane : laneNameList){
                Boolean check = false;
                if(queriedlaneList.size()>0){
                    for(rtms__Lane__c lanerec : queriedlaneList){
                        if(lanerec.Name == lane && !check){
                            check = true;
                            rtms__Lane__c updateLane = newLaneMap.get(lane);
                            updateLane.Id = lanerec.Id;
                            newLaneMap.put(lane, updateLane);
                            //system.debug('failedlanemap==='+JSON.serializePretty(newLaneMap));
                            for(String KeyRate : newRateEntryMap.keySet()){
                                if(KeyRate.contains(lane)){
                                    rtms__RateEntry__c updateRateEntry = newRateEntryMap.get(KeyRate);
                                    updateRateEntry.rtms__Lane__c = lanerec.Id;
                                    newRateEntryMap.put(KeyRate, updateRateEntry);
                                }   
                            }
                            for(String Key : newRateEntryAccessMap.keySet()){
                                if (key.contains(lanerec.name)){
                                    rtms__RateEntry__c updateAccRateEntry = newRateEntryAccessMap.get(key);
                                    updateAccRateEntry.rtms__Lane__c=lanerec.Id;
                                    newRateEntryAccessMap.put(lane, updateAccRateEntry);
                                }
                            }
                        }
                    }
                }
                if(!check){
                    rtms__Lane__c insertLane = newLaneMap.get(lane);
                    insertLaneList.add(insertLane);
                }
            }
            
            //to insert the new lanes and attach the lane to the rate entry and accessorial if it has.
            if(insertLaneList.size()>0){
                
                SObjectAccessDecision securityDecision = Security.stripInaccessible(
                    AccessType.CREATABLE, insertLaneList);
                List<rtms__Lane__c> insertLaneListnew =  securityDecision.getRecords();
                
                insert insertLaneListnew;
                Set <Id> InsertLaneIds = new Set<Id>();
                for(rtms__Lane__c insertlane : insertLaneListnew){
                    InsertLaneIds.add(insertlane.Id);
                }
                //system.debug('insertlane'+InsertLaneIds +insertLaneList.size());
                insertLaneList = [select Id, Name from rtms__Lane__c where Id IN : InsertLaneIds];
                //system.debug('insertLaneList--'+JSON.serializePretty(insertLaneList));
                //system.debug('newLaneMap--'+JSON.serializePretty(newLaneMap));
                //system.debug('newRateEntryMap--'+JSON.serializePretty(newRateEntryMap));
                //system.debug('newRateEntryAccessMap--'+JSON.serializePretty(newRateEntryAccessMap));
                for(rtms__Lane__c insertlane : insertLaneList){
                    string lanewithoutcommas = insertlane.Name.replaceAll(',', '');
                    rtms__Lane__c updateLane = newLaneMap.get(lanewithoutcommas);
                    ///system.debug('newLaneMap--'+JSON.serializePretty(insertlane.Name));
                    //system.debug('newLaneMap--'+JSON.serializePretty(updateLane));
                    //updateLane.Id = insertlane.Id;
                    //newLaneMap.put(lanewithoutcommas, updateLane);
                    newLaneMap.put(lanewithoutcommas, insertlane);
                    for(String rateKey : newRateEntryMap.keySet()){
                        if(rateKey.Contains(lanewithoutcommas)){
                            rtms__RateEntry__c updateRateEntry = newRateEntryMap.get(rateKey);
                            updateRateEntry.rtms__Lane__c = insertlane.Id;
                            newRateEntryMap.put(rateKey, updateRateEntry);
                        }
                    }
                    for(String Key : newRateEntryAccessMap.keySet()){
                        if (key.contains(lanewithoutcommas)){
                            rtms__RateEntry__c updateAccRateEntry = newRateEntryAccessMap.get(key);
                            updateAccRateEntry.rtms__Lane__c=insertlane.Id;
                            newRateEntryAccessMap.put(key, updateAccRateEntry);
                        }
                    }
                }
            }
            
            List<rtms__RateEntry__c> recordList1 = new List<rtms__RateEntry__c>(newRateEntryMap.values());
            List<rtms__RateEntry__c> recordList2 = new List<rtms__RateEntry__c>(newRateEntryAccessMap.values());
            List<rtms__RateEntry__c> recordListfinal = new List<rtms__RateEntry__c>();
            recordListfinal.addAll(recordList1);
            recordListfinal.addAll(recordList2);
            Set<rtms__RateEntry__c> uniqueSet = new Set<rtms__RateEntry__c>(recordListfinal);
            List<rtms__RateEntry__c> recordList3 = new List<rtms__RateEntry__c>(uniqueSet);
            List<rtms__RateEntry__c> recordList = new List<rtms__RateEntry__c>();
            
            Database.SaveResult[] rEList = Database.insert(recordList3, false);
            for (Database.SaveResult re : rEList) {
                if (re.isSuccess()) {
                    successCount++;                                                         
                }else{
                    for(Database.Error objErr : re.getErrors()) {
                        failedCount++;
                    }
                }
            }
            for(rtms__RateEntry__c singlerec:recordList3){
                if(singlerec.id!=null){
                    recordList.Add(singlerec);
                }
            }
            Set<Id> newRateEntryIds = new Set<Id>();
            List<rtms__RateEntryCalculation__c> recordCalcList = new List<rtms__RateEntryCalculation__c>();
            for(rtms__RateEntry__c record : recordList){
                newRateEntryIds.add(record.Id);
                if(record.rtms__Rate_Type__c !=rateentryRatetypePicval.get(Fuel)){
                    rtms__RateEntryCalculation__c calc = new rtms__RateEntryCalculation__c();
                    calc.rtms__Rate_Method__c = record.Rate_Method__c;
                    calc.rtms__Calculation_Type__c = calcuPriceTypePickval.get(Base);
                    calc.rtms__Rate_Entry__c = record.Id;
                    calc.Accessorial_Amount__c = record.Freight_Rate__c;
                    recordCalcList.add(calc);
                    //System.debug('MD==>'+calc);
                    //System.debug('MD==>'+calc.rtms__Rate_Entry__c);
                }
            }
            
            List<rtms__RateEntry__c> laneRateEntryList = [select Id, rtms__Lane__r.name,Lane_Name__c,Freight_Rate__c,Net_Freight__c,Total_Freight__c,Total_Accessorial__c from rtms__RateEntry__c where Id IN :newRateEntryIds AND rtms__Rate_Type__c !=: rateentryRatetypePicval.get(Accessorial)];
            for(rtms__RateEntry__c laneEntry : laneRateEntryList){
                Decimal totalFreight = laneEntry.Freight_Rate__c;
                Decimal netFreight = laneEntry.Freight_Rate__c;
                Decimal totalAccesorial = 0;
                String laneName = laneEntry.Lane_Name__c;
                for(String Key : rateEntryAccessorialMap.keySet()){
                    if (Key.toLowerCase().contains(laneName.toLowerCase())){
                        rtms__RateEntryAccessorial__c updateAccessorial = rateEntryAccessorialMap.get(key);
                        if(updateAccessorial.Include_In_Freight__c == true){
                            netFreight = netFreight+updateAccessorial.rtms__Charge__c;
                        }else{
                            totalAccesorial = totalAccesorial+updateAccessorial.rtms__Charge__c;
                        }
                        totalFreight = totalFreight+updateAccessorial.rtms__Charge__c;
                        updateAccessorial.rtms__Rate_Entry__c = laneEntry.Id;
                        updateAccessorial.Rate_Entry__c = laneEntry.Id;
                        rateEntryAccessorialMap.put(key,updateAccessorial);
                    }
                }
                laneEntry.Total_Freight__c = totalFreight;
                laneEntry.Net_Freight__c = netFreight;
                laneEntry.Total_Accessorial__c = totalAccesorial;
            }
            
            if(recordCalcList.size()>0){
                insert recordCalcList;
                List<rtms__RateEntryCalculationCell__c> recordCellList = new List<rtms__RateEntryCalculationCell__c>();
                for(rtms__RateEntryCalculation__c calcRecord : recordCalcList){
                    rtms__RateEntryCalculationCell__c cell = new rtms__RateEntryCalculationCell__c();
                    cell.rtms__Value__c = calcRecord.Accessorial_Amount__c;
                    cell.rtms__Rate_Entry_Calculation__c = calcRecord.Id;
                    recordCellList.add(cell);
                }
                insert recordCellList;
            }
            
            List<rtms__RateEntryAccessorial__c> recordAccessorialList = new List<rtms__RateEntryAccessorial__c>(rateEntryAccessorialMap.values());
            //insert recordAccessorialList;
            List<Database.SaveResult> srList = Database.insert(recordAccessorialList, false);
            for (Integer i = 0; i < srList.size(); i++) {
                if (!srList[i].isSuccess()) {
                    
                    rtms__RateEntryAccessorial__c failedRecord = recordAccessorialList[i];
                    String failedLane = failedRecord.Lane_Name__c;
                    failedCount++;
                    errorMsg = lwcCSVcustomsetting.No_Rate_Entry_for_this_Accessorial__c + ' "' + recordAccessorialList[i].rtms__Accessorial__r.name + '"' ;
                    errorMsgList.add(errorMsg);
                
                    for(integer index:csvDatamap.keyset()){
                        
                        if(csvimportMap.get(failedLane)==csvDatamap.get(index)){
                            if(failedRowsMap!=null){
                                if(failedRowsMap.get(index)!=null){
                                    failedRowsMap.get(index).add(errorMsg);
                                }
                                else{
                                    failedRowsMap.put(index,new List<string>{errorMsg});   
                                }
                                
                            }
                            else{
                                failedRowsMap.put(1,new List<string>{errorMsg});
                            }
                            break;
                        }   
                    }
                    
                    if(csvRows!=null && !csvRows.toString().contains(csvimportMap.get(failedLane))){
                        csvRows += csvimportMap.get(failedLane);    
                    }
                    if(csvRows==null){
                        csvRows = csvimportMap.get(failedLane);
                    }
                }else{
                    successCount++;
                }
            }
            
            update laneRateEntryList;
            
            sendEmails(csvFileLines[0], successCount);
            
            TriggerHandlerRateEntry.shouldRunTrigger = true;
            return lwcCSVcustomsetting.RecordsProcessedSuccessfully__c +successCount+ lwcCSVcustomsetting.Records_failed__c +failedCount +lwcCSVcustomsetting.Rate_Entries_String__c+ ' '+newRateEntryMap.size();
        }catch(Exception e){
            TriggerHandlerRateEntry.shouldRunTrigger = true;
            //system.debug('eeer'+e.getMessage()+ 'stack' +e.getStackTraceString()+ 'type name'+e.getTypeName());
            return lwcCSVcustomsetting.Thefollowingexceptionhasoccured__c +' ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static string saveFile(Id contentDocumentId, string tpId,
                                  string modeId, string rateMethod, string rfpId, string status, 
                                  string quoteId, date effDate, date expDate){
                                      System.enqueueJob(new uploadCSVQueueable(contentDocumentId,tpId,modeId, rateMethod,rfpId,
                                                                               status,quoteId,effDate,expDate));
                                      
                                      return lwcCSVcustomsetting.File_Processing_has_started__c;
                                  }
    
    private static void sendEmails(String csvHeader, Integer successCount){
        failedCount=failedRowsMap.size();
        EmailClass.sendEmails(csvHeader,successCount, failedCount,csvRows, dupFail,/*errorMsgList*/ failedRowsMap );
    }
    
    
    private static void validateFields(Integer i, String lanenameexcel, String[] csvFileLines, map<String, String> failedaccessorialMap, List<String> laneNameList, Map<String, rtms__Lane__c> newLaneMap, date effDate, date expDate, string rfpId, string tpId, string status, string quoteId,  Map<String, rtms__RateEntry__c> newRateEntryAccessMap, Map<String, rtms__RateEntry__c> duplicateMaps,   Set<String> existingLaneNames,  Map<String, rtms__RateEntry__c> newRateEntryMap,  Map<String, rtms__RateEntryAccessorial__c> rateEntryAccessorialMap, Map<String, String> csvimportMap, Map<String, String> csvimportMap1){
        try{
            skipRec = false;
            Id commId = null;
            Id terminalId = null;
            Id fschargeId = null;
            Id modeListId = null;
            rtms__Lane__c objLane = new rtms__Lane__c();
            //to remove the double quotes
            pattern mypattern = pattern.compile('"([^"]*)"');
            Matcher matcher = mypattern.matcher(csvFileLines[i]);
            String replacedString = csvFileLines[i];
            
            while (matcher.find()) {
                String quotedValue = matcher.group(0);
                String extractedValue = matcher.group(1);
                String replacedValue = extractedValue.replace(',', ''); // Remove commas within the extracted value
                replacedString = replacedString.replace(quotedValue, replacedValue);
                
            }
            
            string[] csvRecordData = replacedString.split(',');
            if(csvDatamap!=null && csvDatamap.values().contains(csvFileLines[i])){
                //do nothing as we have already this data and same error can occur 
                system.debug(i+' Contains value==>'+csvFileLines[i]);
                skipRec=true;
            }
            else{
                csvDatamap.put(i,csvFileLines[i]);
            }
            
            system.debug(i+'valuesforlogging==> '+ JSON.serializePretty(csvDatamap.get(i)));
            if(!skipRec){
                if(String.isBlank(csvRecordData[14])){
                handleFailure(lwcCSVcustomsetting.Rate_Type_Cannot_be_Blank__c, i, csvFileLines);
            }else if(String.isBlank(csvRecordData[28])) {
                handleFailure(lwcCSVcustomsetting.Mode_Cannot_be_Blank__c, i, csvFileLines);
            }else if(String.isBlank(csvRecordData[25]) && csvRecordData[14].trim() != rateentryRatetypePicval.get(Fuel) && csvRecordData[14].trim() !=rateentryRatetypePicval.get(Accessorial) && csvRecordData[17].trim() != rateentryPricetypesubmitted.get(Brokerage_Only)) {
                handleFailure(lwcCSVcustomsetting.Terminal_Cannot_be_Blank__c, i, csvFileLines);
            }else if(String.isBlank(csvRecordData[19]) && csvRecordData[14].trim() ==rateentryRatetypePicval.get(Accessorial) && csvRecordData[27].trim() == Pricing_Notes ) {
                handleFailure(lwcCSVcustomsetting.Pricing_Notes_Cannot_be_Blank__c, i, csvFileLines);
            }else if(csvRecordData[14].trim()!=rateentryRatetypePicval.get(Fuel)  &&(String.isBlank(csvRecordData[27]) || !validRateMethodsList.contains(csvRecordData[27].trim().toLowerCase()))){
                handleFailure(lwcCSVcustomsetting.Rate_Method_missing_spelled_incorrect__c	, i, csvFileLines);
            }else if(csvRecordData[14].trim() !=rateentryRatetypePicval.get(Fuel) && (String.isBlank(csvRecordData[21]) || String.isBlank(csvRecordData[22])) && csvRecordData[27].trim() != Pricing_Notes ){
                handleFailure(lwcCSVcustomsetting.Charge_Type_Rate_Cannot_be_Blank__c, i, csvFileLines);
            }else if(csvRecordData[14].trim()!=rateentryRatetypePicval.get(Fuel) && csvRecordData[14].trim()!=rateentryRatetypePicval.get(Freight) && csvRecordData[14].trim()!=rateentryRatetypePicval.get(FreightAccessorial) && csvRecordData[14].trim()!=rateentryRatetypePicval.get(Accessorial) && csvRecordData[14].trim() != FreightFuel && csvRecordData[14].trim() != FreightFuelAccessorial){
                handleFailure(lwcCSVcustomsetting.Rate_Type_is_Wrong__c+' "' + '<span style="color: blue;">' + csvRecordData[14] + '</span>"', i, csvFileLines);
            }else if((csvRecordData[14].trim() ==rateentryRatetypePicval.get(Fuel) || csvRecordData[14].trim() == FreightFuel || (csvRecordData[14].trim() ==FreightFuelAccessorial && csvRecordData[21].trim()==Freight)) && String.isBlank(csvRecordData[24])){
                handleFailure(lwcCSVcustomsetting.Fuel_Surcharge_is_missing__c, i, csvFileLines);
            }else{
                /*skipRec =*/ verifyField(0,csvRecordData,csvFileLines,i, skipRec);
                //if(!skipRec){
                /*skipRec =*/ verifyField(7,csvRecordData,csvFileLines,i, skipRec);
                //}
                
                if(/*!skipRec &&*/ (csvRecordData[14].trim() == FreightFuel  && csvRecordData[21].trim()!=Freight)){
                    handleFailure(lwcCSVcustomsetting.Freight_spelled_wrong__c  + ' "' + csvRecordData[21] + '"', i, csvFileLines);
                }
                if(/*!skipRec && */(csvRecordData[14].trim() ==rateentryRatetypePicval.get(Accessorial) || csvRecordData[14].trim() ==rateentryRatetypePicval.get(FreightAccessorial) || csvRecordData[14].trim() ==FreightFuelAccessorial) && csvRecordData[21].trim() != Freight){
                    rtms__Accessorial__c accrl = new rtms__Accessorial__c();
                    accrl = validAccessorialNamesMap.get(csvRecordData[21].trim().toLowerCase());
                    if(accrl == null){
                        
                        handleFailure(lwcCSVcustomsetting.Invalid_Charge_Type__c + ' "' + csvRecordData[21] + '"', i, csvFileLines);
                        if((csvRecordData[14].trim() ==rateentryRatetypePicval.get(FreightAccessorial) ||csvRecordData[14].trim() ==FreightFuelAccessorial) && csvRecordData[21].trim() !=Freight){
                            string failedLanename ='';
                            failedLanename = prepareLanenameexcelHelper.LanenameexcelHelper(String.join(csvRecordData, ','));
                            //failedLanename = result.lanenameexcel;
                            Integer[] indicesToCheck = new Integer[]{17, 24, 25, 26, 28, 29};
                                for (Integer index : indicesToCheck) {
                                    if (csvRecordData[index] != null) {
                                        failedLanename += String.valueOf(csvRecordData[index]).trim()+ ' ';
                                    }
                                }
                            failedaccessorialMap.put(failedLanename, csvFileLines[i]);
                        }
                    }
                }
                if(/*!skipRec && */!String.isBlank(csvRecordData[26])){
                    Commodity__c cmdty = new Commodity__c();
                    cmdty = validCommodityNamesMap.get(csvRecordData[26].trim().toLowerCase());
                    system.debug('commodity'+cmdty);
                    if(cmdty == null){
                        handleFailure(lwcCSVcustomsetting.Invalid_Commodity__c+ ' "' + (csvRecordData[26].trim()) + '"', i, csvFileLines);
                    }else{
                        commId = cmdty.Id;
                    }
                }
                if(/*!skipRec &&*/ !String.isBlank(csvRecordData[28])){
                    rtms__Mode__c mode = new rtms__Mode__c();
                    mode = validModeNamesMap.get(csvRecordData[28].trim().toLowerCase());
                    if(mode == null){
                        handleFailure(lwcCSVcustomsetting.Invalid_Mode__c + ' "' + csvRecordData[28] + '"', i, csvFileLines);    
                    }else{
                        modeListId = mode.Id;
                    }
                }
                if(/*!skipRec && */!String.isBlank(csvRecordData[24])){
                    rtms__FuelSurcharge__c fuelSurcharge = new rtms__FuelSurcharge__c();
                    fuelSurcharge = validFSCNamesMap.get(csvRecordData[24].trim().toLowerCase());
                    if(fuelSurcharge == null){
                        handleFailure(lwcCSVcustomsetting.Invalid_FuelSurcharge__c  + ' "' + csvRecordData[24] + '"', i, csvFileLines);    
                    }else{
                        fschargeId = fuelSurcharge.Id;
                    }
                }
                if(/*!skipRec &&*/ !String.isBlank(csvRecordData[25])){
                    Account terminal1 = new Account();
                    terminal1 = validTerminalNamesMap.get(csvRecordData[25].trim().toLowerCase());
                    if(terminal1 == null){
                        handleFailure(lwcCSVcustomsetting.Invalid_Terminal__c + ' "' + csvRecordData[25] + '"', i, csvFileLines);    
                    }else{
                        terminalId = terminal1.Id;
                    }
                }
                if(/*!skipRec &&*/ !String.isBlank(csvRecordData[17])){
                    if(csvRecordData[17].trim() != rateentryPricetypesubmitted.get(Asset_Only) && csvRecordData[17].trim() !=rateentryPricetypesubmitted.get(Brokerage_Only)) {
                        handleFailure(lwcCSVcustomsetting.Price_Type_Submitted_is_Invalid__c  + ' "' + csvRecordData[17] + '"', i, csvFileLines);
                        string failedPriceLanename ='';
                        failedPriceLanename =  prepareLanenameexcelHelper.LanenameexcelHelper(String.join(csvRecordData, ','));
                        //failedPriceLanename = result.lanenameexcel;
                        failedaccessorialMap.put(failedPriceLanename, csvFileLines[i]);
                    }
                }
            }
            
            
                String lanenameaccess = '';
                lanenameexcel = '';
                
                if(csvRecordData[21].trim() == Freight || csvRecordData[14].trim() ==rateentryRatetypePicval.get(Accessorial) || csvRecordData[14].trim() ==rateentryRatetypePicval.get(Fuel) || csvRecordData[14].trim() ==  Freight+Fuel){
                    lanenameexcelobjLaneHelper.LaneResult result = lanenameexcelobjLaneHelper.setLaneFields(String.join(csvRecordData, ','), validLocationNamesMap, validZoneNamesMap);
                        lanenameexcel = result.lanenameexcel;
                    if(failedRowsMap.get(i)==null){
                        
                        objLane = result.objLane;
                        laneNameList.add(lanenameexcel);
                        Set<String> uniqueStrings = new Set<String>(laneNameList);
                        laneNameList = new List<String>(uniqueStrings);
                        newLaneMap.put(lanenameexcel, objLane);                   
                        rtms__RateEntry__c objrateEntry = new rtms__RateEntry__c();
                        objrateEntry.rtms__RFP__c = rfpId;
                        objrateEntry.Rate_Method__c = csvRecordData[27].trim();
                        objrateEntry.rtms__Transportation_Profile__c = tpId;
                        objrateEntry.rtms__Minimum_Weight__c = (String.isBlank(csvRecordData[29])) ? 0 : decimal.valueOf(csvRecordData[29]);
                        objrateEntry.rtms__Status__c = status;
                        objrateEntry.rtms__Quote_Contract_Id__c = quoteId;
                        
                        if(terminalId != null){
                            objrateEntry.Terminal1__c = terminalId;
                        }
                        if(csvRecordData[14].trim() ==rateentryRatetypePicval.get(Accessorial)){
                            rtms__Accessorial__c accrl = new rtms__Accessorial__c();
                            //String accessorialName = csvRecordData[18].trim().toLowerCase();
                            accrl = validAccessorialNamesMap.get(csvRecordData[21].trim().toLowerCase());
                            if(accrl != null){
                                objrateEntry.rtms__Accessorial__c = accrl.Id;
                            }
                        }
                        if(csvRecordData[14].trim() ==rateentryRatetypePicval.get(Fuel) || csvRecordData[14].trim() == FreightFuel || csvRecordData[14].trim() == FreightFuelAccessorial){
                            if(fschargeId != null ){
                                objrateEntry.rtms__Fuel_Surcharge__c = fschargeId;
                            }
                        }
                        objrateEntry.rtms__Effective_Date__c = effDate;
                        objrateEntry.rtms__Expiration_Date__c = expDate;
                        objrateEntry.rtms__Rate_Type__c = csvRecordData[14].trim();
                        objrateEntry.Price_Type_Submitted__c =csvRecordData[17].trim();
                        if(commId != null){
                            objrateEntry.Commodity__c = commId;
                        }
                        if(modeListId!=null){
                            objrateEntry.rtms__Mode2__c = modeListId;
                        }
                        objrateEntry.rtms__Distance__c = (String.isBlank(csvRecordData[15])) ? 0 : decimal.valueOf(csvRecordData[15]);
                        objrateEntry.Round_Trip_Miles__c = (String.isBlank(csvRecordData[16])) ? 0 : decimal.valueOf(csvRecordData[16]);
                        objrateEntry.rtms__Minimum_Weight__c = (String.isBlank(csvRecordData[29])) ? 0 : decimal.valueOf(csvRecordData[29]);
                        objrateEntry.rtms__Expected_Load_Volume__c = (String.isBlank(csvRecordData[18])) ? 0 : decimal.valueOf(csvRecordData[18].trim());
                        objrateEntry.Pricing_Notes__c=(csvRecordData[19]);
                        objrateEntry.Internal_Notes__c = (String.isBlank(csvRecordData[20])) ? '' : csvRecordData[20].trim();
                        if(csvRecordData[14].trim() != rateentryRatetypePicval.get(Fuel)){
                            objrateEntry.Freight_Rate__c = (String.isBlank(csvRecordData[22])) ? 0 :decimal.valueOf((csvRecordData[22].replace('$', '')).trim());
                        }
                        
                        if (!String.isBlank(csvRecordData[31])) {
                            objrateEntry.rtms__Weight_Units__c = csvRecordData[31];
                        }
                        objrateEntry.rtms__Category__c = 'Customer';
                        String lanename = lanenameexcel;
                        Integer[] indicesToCheck = new Integer[]{17, 24, 25, 26, 28, 29};
                            for (Integer index : indicesToCheck) {
                                if (csvRecordData[index] != null) {
                                    lanenameexcel += String.valueOf(csvRecordData[index]).trim()+ ' ';
                                }
                            }
                        lanenameexcel = lanenameexcel.trim();
                        objrateEntry.Lane_Name__c = lanenameexcel;
                        
                        if(csvRecordData[14].trim() ==rateentryRatetypePicval.get(Accessorial)){
                            objrateEntry.Net_Freight__c = (String.isBlank(csvRecordData[22])) ? 0 :decimal.valueOf((csvRecordData[22].replace('$', '')).trim());
                            objrateEntry.Total_Freight__c = (String.isBlank(csvRecordData[22])) ? 0 :decimal.valueOf((csvRecordData[22].replace('$', '')).trim());
                            lanenameexcel = lanenameexcel+' '+csvRecordData[21];
                            objrateEntry.Lane_Name__c = lanenameexcel;
                            
                            if (!newRateEntryAccessMap.containsKey(lanenameexcel)){
                                if(checkExRateEntry(duplicateMaps,existingLaneNames,lanenameexcel, effDate, expDate, csvRecordData[14])){
                                    handleFailure(lwcCSVcustomsetting.Existing_Rate_Entry__c + ' "' + lanenameexcel + '"', i, csvFileLines);
                                    failedaccessorialMap.put(lanenameexcel, csvFileLines[i]);
                                }else{	
                                    newRateEntryAccessMap.put(lanenameexcel,objrateEntry);
                                    newRateEntryMap.put(lanenameexcel,objrateEntry);
                                }
                            }else{
                                handleFailure(lwcCSVcustomsetting.Duplicate_Accessorial__c  + ' "' + csvRecordData[21]+ '"', i, csvFileLines);
                            }
                        }
                        else{
                            system.debug('lanenameexcel00--'+lanenameexcel);
                            system.debug('newRateEntryMap00--'+JSON.serializePretty(newRateEntryMap));
                            if (!newRateEntryMap.containsKey(lanenameexcel)){
                                if(checkExRateEntry(duplicateMaps,existingLaneNames,lanenameexcel, effDate, expDate, csvRecordData[14].trim())){
                                    handleFailure(lwcCSVcustomsetting.Existing_Rate_Entry__c  + ' "' + lanenameexcel + '"', i, csvFileLines);
                                    failedaccessorialMap.put(lanenameexcel, csvFileLines[i]);
                                }else{
                                    newRateEntryMap.put(lanenameexcel,objrateEntry);
                                }
                            }else{
                                handleFailure(lwcCSVcustomsetting.Duplicate_Rate_Entry__c  + ' "' + lanenameexcel + '"', i, csvFileLines);
                                failedaccessorialMap.put(lanenameexcel, csvFileLines[i]);
                            }
                        }
                    }
                    //Adding this logic for invalid Accessorial Revist this logic
                    if(/*!skipRec &&*/ csvRecordData[14].trim() ==rateentryRatetypePicval.get(FreightAccessorial) && validAccessorialNamesMap.get(csvRecordData[21].trim().toLowerCase())==null){
                    	handleFailure(lwcCSVcustomsetting.NoAccessorialspresent__c  + ' "' + lanenameexcel + '"', i, csvFileLines);
                	}
                    
                }
                
                else{
                    lanenameexcel = prepareLanenameexcelHelper.LanenameexcelHelper(String.join(csvRecordData, ','));
                    lanenameaccess = lanenameexcel;
                    Integer[] indicesToCheck = new Integer[]{17, 24, 25, 26, 28, 29, 21};
                        for (Integer index : indicesToCheck) {
                            if (csvRecordData[index] != null) {
                                lanenameexcel += String.valueOf(csvRecordData[index].trim()) + ' ';
                            }
                        }
                    lanenameexcel = lanenameexcel.trim();
                    rtms__RateEntryAccessorial__c accesorial = new rtms__RateEntryAccessorial__c();
                    rtms__Accessorial__c acc = new rtms__Accessorial__c();
                    try{
                        system.debug('ExceptionData==>'+csvRecordData[21].trim().toLowerCase());
                        acc = validAccessorialNamesMap.get(csvRecordData[21].trim().toLowerCase());
                        accesorial.rtms__Accessorial__c = acc.Id;
                    }catch(Exception e){
                        
                    }
                    accesorial.Rate_Method__c = csvRecordData[27].trim();
                    accesorial.rtms__Charge__c = (String.isBlank(csvRecordData[22])) ? 0 : decimal.valueOf((csvRecordData[22].replace('$', '')).trim());
                    if(csvRecordData[23].trim() =='Y' || csvRecordData[23].trim() == 'TRUE'){
                        accesorial.Include_In_Freight__c = true;
                    }else {
                        accesorial.Include_In_Freight__c = false;
                    }
                    if(!rateEntryAccessorialMap.containsKey(lanenameexcel)){
                        accesorial.Lane_Name__c = lanenameexcel;
                        rateEntryAccessorialMap.put(lanenameexcel, accesorial);
                        
                    }else{
                        handleFailure(lwcCSVcustomsetting.Duplicate_Accessorial__c + ' "' + lanenameexcel + '"', i, csvFileLines);
                        failedaccessorialMap.put(lanenameexcel, csvFileLines[i]);
                    }
                }
                //if(lanenameexcel!=''){
                if(failedRowsMapIndex.containskey(lanenameexcel)){
                    failedRowsMapIndex.get(lanenameexcel).add(i);
                }
                else{
                    failedRowsMapIndex.put(lanenameexcel,new set<Integer>{i}); 
                }
                
                failedRowsMapIndex1.put(lanenameexcel+i,lanenameexcel);
                //}
                csvDatamap1.put(lanenameexcel,i);
                csvimportMap.put(lanenameexcel,csvFileLines[i]);
                csvimportMap1.put(lanenameexcel+i,csvFileLines[i]);
            
                
            }
            
            
        }catch(Exception e){
            handleFailure(lwcCSVcustomsetting.Data_issue__c+' ' + lanenameexcel + '"', i, csvFileLines);
        }
    }
    
    private static void handleFailure(String message, Integer index, String[] csvFileLines) {
        //skipRec = true;
        if(failedRowsMap.containsKey(index) ){
            failedRowsMap.get(index).add(message);
            system.debug('MD2==>'+JSON.serializePretty(failedRowsMap));   
            //skipRec = true;                
        }
        else{
            failedRowsMap.put(index, new List<string>{message});
            system.debug('MD==>'+failedRowsMap);
        }
        errorMsgList.add(message);
        failedRows.add(csvFileLines[index]);
        if(csvRows == null){
            
            csvRows = csvFileLines[index];
            system.debug('csvRows ==>'+ JSON.serializePretty(csvRows));
            
        }
        else {
            if(!csvRows.tostring().contains(csvFileLines[index])){
                system.debug('csvRows ==>'+ JSON.serializePretty(csvRows));
                system.debug('csvRows ==>'+ JSON.serializePretty(csvFileLines[index]));
                csvRows += csvFileLines[index]; 
                system.debug('csvRows ==> aftrer adding'+ JSON.serializePretty(csvRows));
            }
            
        }
        failedCount++;
        
    }
    
    private static Map<string,string> getPickList(string objName, string FieldApiName){
        String objectName = objName;
        String fieldName =FieldApiName;
        Map<string,string> picklitsVal=new Map<string,string>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry single : ple){
            picklitsVal.put(single.label,single.value);
        }   
        return picklitsVal;
    }  
    
    private static Boolean verifyField(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        switch on csvRecordData[index].trim() {
            when 'Country'{
                return verifyCountry(index,csvRecordData,csvFileLines,row, skipRec);
            }
            when 'State' {
                return verifyState(index,csvRecordData,csvFileLines,row, skipRec);
            }
            when 'City/State' {
                return verifyCityState(index, csvRecordData, csvFileLines, row, skipRec);
            }
            when 'Postal Code' {
                return verifyPostalCode(index, csvRecordData,csvFileLines, row, skipRec);
            }
            when 'Zip3' {
                return verifyZip3(index, csvRecordData, csvFileLines, row, skipRec);
            }
            when 'Zip5' {
                return verifyZip5(index, csvRecordData, csvFileLines, row, skipRec);
            }
            when  'Zone' {
                return verifyZone(index, csvRecordData, csvFileLines, row, skipRec);
            }
            when  'Location' {
                return verifyLocation(index, csvRecordData, csvFileLines, row, skipRec);
            }
            when else{
                //return false;
                return verifyOriginDest(index, csvRecordData, csvFileLines, row, skipRec);
            }
        }
    }
    private static Boolean verifyOriginDest(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        //skipRec = true;
        if(index ==0){
            handleFailure(lwcCSVcustomsetting.Invalid_Origin_Type__c, row, csvFileLines);
        }else{
            handleFailure(lwcCSVcustomsetting.Invalid_Destination_Type__c, row, csvFileLines);
        }
        return skipRec;      
    }
    
    private static Boolean verifyCountry(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Country' && !skipRec){
            if(String.isBlank(csvRecordData[index+4]) || !validCountryValuesList.contains(csvRecordData[index+4].trim().toLowerCase())){
                // skipRec = true;
                if(index ==0){
                    handleFailure(lwcCSVcustomsetting.Origin_Country_cannot_be_blank_Wrong__c, row, csvFileLines);
                }else{
                    handleFailure(lwcCSVcustomsetting.Destination_Country_cannot_be_blank_Wron__c, row, csvFileLines);
                }
            }
        }    
        return skipRec;      
    }
    
    private static Boolean verifyState(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'State' && !skipRec){
            if(String.isBlank(csvRecordData[index+2]) || !validStateValuesList.contains(csvRecordData[index+2].trim().toLowerCase())){
                //skipRec = true;
                if(index ==0){
                    handleFailure(lwcCSVcustomsetting.Destination_Country_cannot_be_blank_Wron__c, row, csvFileLines);
                }else{
                    handleFailure(lwcCSVcustomsetting.Destination_State1_cannot_be_blank_Wrong__c	, row, csvFileLines);
                }
            }
        }    
        return skipRec;
    }
    
    private static Boolean verifyCityState(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'City/State' && !skipRec){
            if((String.isBlank(csvRecordData[index+1])) || String.isBlank(csvRecordData[index+2]) || !validStateValuesList.contains(csvRecordData[index+2].trim().toLowerCase()) || String.isBlank(csvRecordData[index+4])){
                //skipRec = true;
                if(String.isBlank(csvRecordData[index+1])){
                    if(index == 0){
                        handleFailure(lwcCSVcustomsetting.Origin_City_cannot_be_blank__c, row, csvFileLines);
                    }else{
                        handleFailure(lwcCSVcustomsetting.Destination_City_cannot_be_blank__c, row, csvFileLines);
                    }
                }else if(String.isBlank(csvRecordData[index+2]) || !validStateValuesList.contains(csvRecordData[index+2].trim().toLowerCase())){
                    if(index == 0){
                        handleFailure(lwcCSVcustomsetting.Origin_State_cannot_be_blank_Wrong__c, row, csvFileLines);
                    }else{
                        handleFailure(lwcCSVcustomsetting.Destination_State_cannot_be_blank_Wrong__c, row, csvFileLines);
                    }
                }else{
                    if(index == 0){
                        handleFailure(lwcCSVcustomsetting.Origin_Country_cannot_be_blank_Wrong__c, row, csvFileLines);
                    }else{
                        handleFailure(lwcCSVcustomsetting.Destination_Country_cannot_be_blank_Wron__c, row, csvFileLines);
                    }
                }  
            }
        }  
        
        return skipRec;
    }  
    
    private static Boolean verifyPostalCode(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Postal Code' && !skipRec){
            if((String.isBlank(csvRecordData[index+3]))){
                //skipRec = true;
                if(index == 0){
                    handleFailure(lwcCSVcustomsetting.Origin_Postal_Code_cannot_be_blank__c, row, csvFileLines);
                }else{
                    handleFailure(lwcCSVcustomsetting.Destination_Postal_Code_cannot_be_blank__c, row, csvFileLines);
                }
            }
        }    
        return skipRec;
    }
    
    private static Boolean verifyZip3(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Zip3' && !skipRec){
            if((String.isBlank(csvRecordData[index+3])) || decimal.valueOf(csvRecordData[index+3].length()) > 3){
                //skipRec = true;
                if(index == 0){
                    handleFailure(lwcCSVcustomsetting.Origin_Zip_3_cannot_be_blank_should_be_3__c, row, csvFileLines);
                }else{
                    handleFailure(lwcCSVcustomsetting.Destination_Zip_3_cannot_be_blank_should__c, row, csvFileLines);
                }
            }
        }    
        return skipRec;
    }
    
    private static Boolean verifyZip5(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Zip5' && !skipRec){
            if((String.isBlank(csvRecordData[index+3]) || decimal.valueOf(csvRecordData[index+3].length()) > 5)){
                //skipRec = true;
                if(index == 0){
                    handleFailure(lwcCSVcustomsetting.Origin_Zip_5_cannot_be_blank_should_be_5__c	, row, csvFileLines);
                }else{
                    handleFailure(lwcCSVcustomsetting.Destination_Zip_5_cannot_be_blank_should__c, row, csvFileLines);
                }
            }
        }    
        return skipRec;
    }
    
    private static Boolean verifyZone(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Zone' && !skipRec){
            if(String.isBlank(csvRecordData[index+5]) ||
               (!validZoneNamesMap.containsKey(csvRecordData[index+5].trim().toLowerCase()))){
                   //skipRec = true;
                   if(index == 0){
                       handleFailure(lwcCSVcustomsetting.Origin_Zone_cannot_be_blank_Wrong__c, row, csvFileLines);
                   }else{
                       handleFailure(lwcCSVcustomsetting.Destination_Zone_cannot_be_blank_Wrong__c, row, csvFileLines);
                   }
               }
        }    
        return skipRec;
    }
    private static Boolean verifyLocation(Integer index, String [] csvRecordData, String [] csvFileLines, Integer row, Boolean skipRec){
        if(csvRecordData[index].trim() == 'Location' && !skipRec){
            
            if(!String.isBlank(csvRecordData[index+6]) && dupLaneMap.containsKey(csvRecordData[index+6].trim().toLowerCase())){
                //skipRec = true;
                dupFail=true;
                handleFailure(lwcCSVcustomsetting.Duplicate_Locations__c+' '+ csvRecordData[index+6] +lwcCSVcustomsetting.Enter_Rate_Entry_Manually__c, row, csvFileLines);
            }
            
            else if(String.isBlank(csvRecordData[index+6]) ||
                    (!validLocationNamesMap.containsKey(csvRecordData[index+6].trim().toLowerCase()))){
                        //skipRec = true;
                        
                        if(index == 0){
                            handleFailure(lwcCSVcustomsetting.Origin_Location_cannot_be_blank_Wrong__c, row, csvFileLines);
                        } else{
                            handleFailure(lwcCSVcustomsetting.Destination_Location_cannot_be_blank_Wro__c, row, csvFileLines);
                        }
                    }
            
        }    
        return skipRec;
    }
    
    private static List<string> getPickListlabels(string objName, string FieldApiName){
        String objectName = objName;
        String fieldName =FieldApiName;
        List<string> picklitsVal=new List<string>();
        Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
        
        Schema.DescribeSObjectResult r = s.getDescribe() ;
        
        Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
        
        Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
        
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry single : ple){
            picklitsVal.add(single.getLabel().toLowerCase());
        }   
        return picklitsVal;
    }
    
    private static map<String, rtms__Zone__c> getValidZoneNames(){
        List<rtms__Zone__c> validZoneNamesList = [SELECT Id, Name FROM rtms__Zone__c];
        Map<String, rtms__Zone__c> validZoneNamesMap = new Map<String, rtms__Zone__c>();
        for(rtms__Zone__c zone : validZoneNamesList){
            validZoneNamesMap.put(zone.name.toLowerCase(), zone);
        } 
        return validZoneNamesMap;        
    }
    private static List<Account> getallAccounts(){
        return [SELECT Id, Name FROM Account];
    }
    private static map<String, Account> getvalidLocationNames(List<Account> accList){
        //List<Account> validLocationNamesList = [SELECT Id, Name FROM Account];
        List<Account> validLocationNamesList =accList;
        Map<String, Account> validLocationNamesMap = new Map<String, Account>();
        for(Account location : validLocationNamesList){
            String locNameswithoutCommas = location.Name.replaceAll(',', '');   
            validLocationNamesMap.put(locNameswithoutCommas.toLowerCase(), location);
        }
        return validLocationNamesMap;        
    }
    private static map<String, Account> getduplicateLocationNames(List<Account> accList){
        List<Account> validLocationNamesList =accList;
        Map<String, Account> validLocationNamesMap = new Map<String, Account>();
        Map<String, Account> dupLaneMap = new Map<String, Account>();
        for(Account location : validLocationNamesList){
            String locNameswithoutCommas = location.Name.replaceAll(',', '');
            if(validLocationNamesMap.containskey(locNameswithoutCommas.toLowerCase())){
                dupLaneMap.put(locNameswithoutCommas.toLowerCase(),location );
            }
            validLocationNamesMap.put(locNameswithoutCommas.toLowerCase(), location);
        }
        return dupLaneMap;        
    }
    
    private static map<String, rtms__Accessorial__c> getvalidAccessorialNames() {
        Map<String, rtms__Accessorial__c> validAccessorialNamesMap = new Map<String, rtms__Accessorial__c>();
        List<rtms__Accessorial__c> validAccessorialNamesList = [select id, Name from rtms__Accessorial__c];
        for(rtms__Accessorial__c accessorial : validAccessorialNamesList){
            validAccessorialNamesMap.put(accessorial.Name.toLowerCase(), accessorial);
        }
        return validAccessorialNamesMap;
    }
    
    private static map<String, Account> getValidTerminalNames() {
        List<Account> validTerminalNamesList = [SELECT Id, Name FROM Account where rtms__TMS_Type__c INCLUDES ('Bulkmatic Terminal')];
        Map<String, Account> validTerminalNamesMap = new Map<String, Account>();
        for(Account terminal : validTerminalNamesList){
            validTerminalNamesMap.put(terminal.name.toLowerCase(), terminal);
        }
        return validTerminalNamesMap;
    }
    
    private static map<String, Commodity__c> getValidCommodityNames() {
        Map<String, Commodity__c> validCommodityNamesMap = new Map<String, Commodity__c>();
        List<Commodity__c> validCommodityNamesList = [SELECT Id, Name FROM Commodity__c];
        for(Commodity__c commodity : validCommodityNamesList){
            validCommodityNamesMap.put(commodity.name.toLowerCase(), commodity);
        }
        return validCommodityNamesMap;
    }
    
    private static map<String, rtms__Mode__c> getValidModeNames(){
        List<rtms__Mode__c> validModeNamesList = [SELECT Id, Name FROM rtms__Mode__c];
        Map<String, rtms__Mode__c> validModeNamesMap = new Map<String, rtms__Mode__c>();
        for(rtms__Mode__c mode : validModeNamesList){
            validModeNamesMap.put(mode.name.toLowerCase(), mode);
        }
        return validModeNamesMap;
    }
    
    private static map<String, rtms__FuelSurcharge__c> getvalidFSCNames(){
        List<rtms__FuelSurcharge__c> validFSCNamesList = [select Id,Name from rtms__FuelSurcharge__c];
        Map<String,rtms__FuelSurcharge__c> validFSCNamesMap = new Map<String,rtms__FuelSurcharge__c>();
        for(rtms__FuelSurcharge__c fsc : validFSCNamesList){
            validFSCNamesMap.put(fsc.name.toLowerCase(),fsc);
        }
        return validFSCNamesMap;
    }
    
    private static Boolean checkExRateEntry(Map<String, rtms__RateEntry__c> duplicateMaps, Set<String> exLanes, String laneName, date effDate, date expDate, String rateType ){
        Boolean result = false;
        if(exLanes.contains(laneName)){
            rtms__RateEntry__c record = duplicateMaps.get(laneName);
            date effDateDup;
            date expDateDup;
            String rateTypeDup;
            effDateDup = record.rtms__Effective_Date__c;
            expDateDup = record.rtms__Expiration_Date__c;
            rateTypeDup = (record.rtms__Rate_Type__c == null) ? '' : record.rtms__Rate_Type__c;
            if(effDate == effDateDup && expDate == expDateDup && rateTypeDup == rateType){
                result = true;
            }
        }
        return result;
    }
    
}