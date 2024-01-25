public with sharing class YearlyPlanController {  
    
    @AuraEnabled(cacheable=true)
    public static List<Plot__c> getPlots(String accountId) {
        System.debug('001. accountId: ' + accountId); 
        List<Plot__c> plotsToReturn = new List<Plot__c>();
        List<Branch_growth__c> branches = [SELECT Account__c,(SELECT Id, Name, Plot_Size__c, Branch_growth__r.Name FROM Plots__r) FROM Branch_growth__c WHERE Account__c =: accountId Limit 20];
        for (Branch_growth__c branch: branches){
            plotsToReturn.addAll(branch.Plots__r);
        }
        System.debug('002. plotsToReturn: ' + plotsToReturn);
        return plotsToReturn;
    }   
    
    
    
    @AuraEnabled(cacheable=true)
    public static List<Opp_Line_Item_Data__mdt> getOppLineItemDataMdt(String type) { 
        
        Opp_Line_Item_Data__mdt[] oppLineItemMetaDataList = [SELECT Id__c, MasterLabel, DeveloperName FROM Opp_Line_Item_Data__mdt WHERE Type__c =: type];
        return oppLineItemMetaDataList;
        
    }
    
    
    @AuraEnabled(cacheable=true)
    public static String getPlotGrowthType(String plotId) {         
        for (Growth__c growth : [SELECT Id, Growth_Type__c
        FROM Growth__c WHERE Plot__c=: plotId ORDER BY CreatedDate DESC] ){
            return growth.Growth_Type__c;                
        }
        return null;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Fertilization_suggestions__c> getFertilizationSuggestions(String growthType) { 
        List<Fertilization_suggestions__c> fertilizationSuggestions = new List<Fertilization_suggestions__c>();
        for (Fertilization_suggestions__c fertSugg : [SELECT Id, Growth__c, Stage_in_growth__c, N__c, P__c, K__c 
        FROM Fertilization_suggestions__c WHERE Growth__c=: growthType]){
            fertilizationSuggestions.add(fertSugg);
        }
        return fertilizationSuggestions;
    }
    
    @AuraEnabled(cacheable=true)
    public static list<OpportunityLineItem> getOppProducts(String oppId) {
        Opportunity opp =  [select Id ,(SELECT Id,Product2Id,Quantity,UnitPrice,SortOrder,Product2.Name, 
        Quantity_per_hectare__c, N__c, P__c, K__c, Plots__c,Date__c,Plot_Size__c
        ,Extension_1__c,Extension_2__c,Extension_3__c,
        Extension_4__c,Extension_5__c,Extension_6__c, Extension_7__c,Extension_8__c,Is_Extension__c, Description
        FROM OpportunityLineItems Order By Date__c, CreatedDate, LastModifiedDate DESC, Is_Extension__c) from Opportunity Where Id =: oppId Limit 1];
        return opp.OpportunityLineItems;
    }  
    
    
    @AuraEnabled
    public static Boolean captureAccId( String oppId ) {
        Last_Viewed_Account__c lva = Last_Viewed_Account__c.getInstance( UserInfo.getUserId() );
        Opportunity opp = [SELECT AccountId from Opportunity WHERE Id =: oppId LIMIT 1];
        if( lva.Account_Id__c != opp.AccountId) {
            lva.SetupOwnerId 	= UserInfo.getUserId();
            lva.Account_Id__c 	= opp.AccountId;
            UPSERT lva Id;
            return true;
        }
        else {
            return false;
        }
    }  
    

    


    
}