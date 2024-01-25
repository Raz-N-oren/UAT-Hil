public with sharing class CustomLookUpController {
    @AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String objectName, String extraWhereClause) {
        String fieldsToReturn = 'id, Name';
        return CustomLookUpController.fetchExtendedLookUpValues(searchKeyWord, objectName, fieldsToReturn, extraWhereClause);
    }

    @AuraEnabled
    public static List<sObject> fetchExtendedLookUpValues(String searchKeyWord, String objectName,String fieldsToQuery,String extraWhereClause) {
        String realObjectName = String.escapeSingleQuotes(objectName);
        String realFieldsToQuery = String.escapeSingleQuotes(fieldsToQuery);
        String searchKey =  searchKeyWord + '%';

        if(realObjectName == 'Product2' ||
            realObjectName == 'Branch_growth__c' ||
            realObjectName == 'Plot_Tank_Junction__c' ||
            realObjectName == 'Account' ||
            realObjectName == 'Tank__c' ||
            realObjectName == 'DeliveryNote__c'
        ){
            searchKey = + '%' + searchKeyWord + '%';
        }
        
        List<sObject> returnList = new List <sObject>();

        String sQuery = '';

        System.debug(logginglevel.Error+'001. searchKeyWord: ' + searchKeyWord);
        System.debug(logginglevel.Error+'002. objectName: ' + objectName);
        System.debug(logginglevel.Error+'003. fieldsToQuery: ' + fieldsToQuery);
        System.debug(logginglevel.Error+'004.  extraWhereClause?: ' + extraWhereClause);
        if(realObjectName == 'OrderItem' ){
        // sQuery = 'SELECT '+  'Id, Name, LoadingPointName__c , LoadingPointSapId__c, LoadingPointType__c' +' FROM ' + 'LoadingPoint__c' + ' WHERE Name LIKE \'%' + searchKey + '%\' '+'AND LoadingPointType__c != \'' +'מחסן קונסיגנציה'+ '\' ';
        sQuery = 'SELECT '+  'Id, Name, LoadingPointName__c , LoadingPointSapId__c, LoadingPointType__c' +' FROM ' + 'LoadingPoint__c' + ' WHERE Name LIKE \'%' + searchKey + '%\' '+extraWhereClause;

    }
        if(realObjectName == 'Tank__c' && String.isBlank(searchKeyWord)){
            sQuery += 'SELECT '+  realFieldsToQuery +' FROM ' + realObjectName + ' WHERE Id != null ';
        }
        else if(realObjectName == 'DeliveryNote__c' ){
         
           sQuery += 'SELECT ' +realFieldsToQuery+' FROM DeliveryNote__c' + ' WHERE Name LIKE \'%' + searchKey + '%\''+extraWhereClause;
                       System.debug(logginglevel.ERROR+'003. inside if of deliveryNote__c extraWhereClause: ' + extraWhereClause);

           System.debug(logginglevel.ERROR+'003. inside if of deliveryNote__c realFieldsToQuery: ' + realFieldsToQuery);
        }  
        else if(realObjectName == 'Account'){
            System.debug('inside else if account ' + realObjectName);
            // WHERE SAP_Account_Group__c = 'NOTI' AND (AccountSource = 'FER' OR AccountSource = 'ILF')
            //SAP_Account_Group__c
            sQuery += 'FIND \''+searchKeyWord+'\' IN NAME FIELDS RETURNING '+ realObjectName +'('+ realFieldsToQuery+' '+ extraWhereClause+')' +' LIMIT 25';
            System.debug('sQuery FIND b4 sending to DB ' + sQuery);
            List <list<sObject>> lstOfRecords = search.query(sQuery);
            for (List<SObject> dynamicList: lstOfRecords) {
                for (sObject obj: dynamicList) {
                    returnList.add(obj);
                }
            }
            return returnList;
        } else {
            System.debug('last else ' + realObjectName);
            System.debug('last else searchKey' + searchKey);

            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
            if (realObjectName != 'OrderItem') {                
                sQuery += 'SELECT '+  realFieldsToQuery +' FROM ' + realObjectName + ' WHERE Name LIKE \'%' + searchKey + '%\'';
                System.debug('sQuery - lastly b4 sending! ' + sQuery);
            }  
        }
        // String sQuery =  'select '+  realFieldsToQuery +' from ' + realObjectName + ' where Name LIKE \'%' + searchKeyWord + '%\' '; // TODO: Escape single quets!

        if(String.isNotBlank(extraWhereClause)){
            sQuery += extraWhereClause;
        }

        if(realObjectName == 'Product2' || realObjectName == 'Tank__c' ){
            sQuery+=' ORDER BY Name LIMIT 20';
        } else {
            sQuery+=' ORDER BY createdDate DESC LIMIT 20';     // If want add limit 10  
        }
        try {
            System.debug('001. sQuery: ' + sQuery);
            List <sObject> lstOfRecords = Database.query(sQuery);
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        } catch (Exception e) {
            System.debug('Error ocured: ' + sQuery + '\n' + e.getMessage());
            throw new AuraHandledException('That didn\'n work:'+sQuery+'\n' + e.getMessage());
        }
        System.debug('002. returnList: ' + returnList);
        return returnList;
    }
    
    @AuraEnabled
    public static List<sObject> getLastViewRecords(String objectName, String fieldsToQuery, String extraWhereClause) {
        String realObjectName = String.escapeSingleQuotes(objectName);
        String realFieldsToQuery = String.escapeSingleQuotes(fieldsToQuery);
	
        List<sObject> returnList = new List <sObject>();

        // Improved performance of query
        // Get the recently veiwed records Ids to return
        List<RecentlyViewed> recentlyViewedRecs = [
            SELECT Id 
            FROM RecentlyViewed 
            WHERE Type = :realObjectName ORDER BY LastViewedDate DESC limit 10   // If want add limit 10  
        ];

        list<Id> recIds = new List<Id>((new Map<Id, RecentlyViewed>(recentlyViewedRecs)).keySet());

        // Get the records with all the requierd fields (Dynamically)

        String sQuery =  'SELECT ' + realFieldsToQuery + ' FROM ' + realObjectName + ' WHERE Id IN : recIds'+(String.isNotBlank(extraWhereClause)? ' AND (' + extraWhereClause + ')':+'');     
        sQuery+=' ORDER BY LastViewedDate DESC';     
        try {
            List <sObject> lstOfRecords = Database.query(sQuery);
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Querying didn\'n work: '+sQuery+'\n'+e.getMessage());
        }
        return returnList;

      
    }

    // Update the Lastviewed field and Object for the specific record
    @AuraEnabled
    public static void updateLastViewed(String objectName, Id recId){
        String realObjectName = String.escapeSingleQuotes(objectName);
        
        String sQuery =  'SELECT Id FROM ' + realObjectName + ' WHERE Id = \'' + recId + '\' FOR VIEW';
        Database.query(sQuery);
    }
}