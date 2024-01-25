/**
* @description       : Handels 
* @author            : Lilach Mis
* @group             : 
* @last modified on  : 03-26-2022
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class DoubleOptIN_Controller {
    
    @AuraEnabled
    public static String createNewDOI(string email,boolean verify, string recRelatedId){
        try {
            string DOIrec='';
            Double_OPT_In__c newRec= new Double_OPT_In__c();
            newRec.email__c = email;
            newRec.LandscaperProNewsletter__c = verify;
            newRec.RelatedDigitalExId__c = recRelatedId;
            
            insert newRec;
            DOIrec= newRec.Id;
            
            return DOIrec;
        } catch (Exception e) {throw new AuraHandledException(e.getMessage());}
    }
    
    
    
}