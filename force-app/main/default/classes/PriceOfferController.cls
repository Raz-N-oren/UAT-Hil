public with sharing class PriceOfferController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOliIdsByOpp(Id oppId) { 
        List<OpportunityLineItem> olisToReturn = new List<OpportunityLineItem>();
        olisToReturn = [SELECT Id, Product2Id, UnitPrice, TotalPrice, Currency__c, Quantity, Is_Extension__c, Unit_of_measure__c, OpportunityId, Description, Terms_of_Payment__c, Transaction_Type__c,Packing_Type__c, Loading_Point__c, Foreign_currency_invoice__c, Discount FROM OpportunityLineItem WHERE OpportunityId = :oppId AND Is_Extension__c != true LIMIT 20];
        return olisToReturn;
    }

    // @AuraEnabled(cacheable=true)
    // public static List<Account> getAccountSapId(Id accId){
    //     return [SELECT Sap_Number__c FROM Account WHERE Id = :accId];  
    
    // }
    @AuraEnabled(cacheable=true)
    public static List<LoadingPoint__c> getLoadingPointBySapId(Id contrId){
    List<Account> contractors = [SELECT Sap_Number__c FROM Account WHERE Id = :contrId];
    
        if (contractors.size() == 1) {
            String sapNumber = contractors[0].Sap_Number__c;
        
            return [SELECT Id, Name, LoadingPointSapId__c FROM LoadingPoint__c WHERE LoadingPointSapId__c = :sapNumber];
        }
        else {
            return new List<LoadingPoint__c>();
        }
    } 
    


    // SELECT Sap_Number__c,
    //    (SELECT LoadingPointSapId__c, Id, Name FROM LoadingPoints__r)
    // FROM Account
    // WHERE Sap_Number__c = (SELECT LoadingPointSapId__c FROM LoadingPoints__r)


    @AuraEnabled(cacheable=true)
    public static boolean BasePriceExist(Id accountId, Id productId){
        boolean PB=false;
        Account acc =  priceCalculationInfo.getAccount(AccountId);
        system.debug(loggingLevel.error,'BasePriceExist:accountId-'+accountId+'/ productId-'+productId);
        if(acc!=null && acc.ProductCustomerClassification__c!=null){
                    system.debug(loggingLevel.error,'BasePriceExist:ProductCustomerClassification__c-'+acc.ProductCustomerClassification__c+'/ productId-'+productId);

            List<IL_Price_Book__c>  BasePB = new List<IL_Price_Book__c>([SELECT Id 
                                                                         FROM IL_Price_Book__c 
                                                                         WHERE 
                                                                         ProductCustomerClassification__c=:acc.ProductCustomerClassification__c
                                                                         AND 
                                                                         Product_Service__c =:productId
                                                                        AND Status__c = 'תקף']);
            PB=BasePB!=null && !BasePB.isEmpty()?true:false;
            
        }
        
        return PB;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<Discount__c> getDiscount(Id accId, Id prodId){ 
        List<Discount__c> discountsToReturn = new List<Discount__c>();
        discountsToReturn = [
            SELECT  Id, Account__c, Account__r.Name, CurrencyIsoCode, Display_Filter_1__c, Display_Filter_2__c, 
            End_Date__c, Product__c, Requested_Discount__c, Start_Date__c, Status__c
            FROM Discount__c 
            WHERE   Status__c ='תקף' AND Account__c =: accId AND Product__c =: prodId 
            AND Start_Date__c < TODAY AND End_Date__c > TODAY
        ];
        return discountsToReturn;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Plot__c> getAllPlots(Id accId) { 
        string SHORTACC= string.valueOf(accId).substring(0, 15);
        List<Plot__c> plotsFound = new List<Plot__c>([SELECT Id, Name, Plot_Size__c, Branch_growth__r.Name,Parent_Account_ID__c  from Plot__c Where Parent_Account_ID__c  = :accId OR Parent_Account_ID__c=:SHORTACC LIMIT 20]);
        system.debug(loggingLevel.ERROR, 'getAllPlots-->accId:'+accId+'  plots found:'+plotsFound);

        return plotsFound ;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<IL_Price_Book__c> getFertJobPriceBook(Id prodId, String prodFamily){ 
      List<IL_Price_Book__c> PBToReturn = new List<IL_Price_Book__c>([
            SELECT  Id, Aggregation_mode__c, Base_amount__c, Crane_price__c, CurrencyIsoCode, End_Date__c, 
            Extra_amount__c, Extra_rate_Scale_1__c, Extra_rate_Scale_2__c, Extra_rate_Scale_3__c, 
            Fixed_Price__c, Product_Service__c, RecordTypeId, Scale_Price_1__c, Scale_Price_2__c, 
            Scale_Price_3__c, Start_Date__c, Status__c, Product_Family_new__c, Unit_Of_Meager__c
            FROM IL_Price_Book__c 
            WHERE   Status__c ='תקף' AND Product_Service__c =: prodId 
            AND Start_Date__c <= TODAY AND (End_Date__c >= TODAY OR End_Date__c=NULL)]);
        system.debug(loggingLevel.error,'PBToReturn:'+PBToReturn +' - for product:'+prodId);
        return PBToReturn;
    }

    @AuraEnabled
    public static void updatePricebookClosedQuate(Id oppId) { 
    //List to store pricebooks to be updated
    List<IL_Price_Book__c> PBToUpdate = new List<IL_Price_Book__c>();
        
    //SOQL for loop
    //Loop through each pricebook record returned
    for(IL_Price_Book__c pb: [SELECT Id, Name,End_Date__c,Status__c FROM IL_Price_Book__c WHERE Opportunity__c =: oppId]){
        pb.Status__c = 'לא תקף';
        pb.End_Date__c = system.today();
        
        //Add pricebook to our list
        PBToUpdate.add(pb);
    }
    
    //Run a DML update statement, now all pricebook records in the list will change to close
    update PBToUpdate;

}

    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOliRelatedOrderItem(Id oppLineItemId) { 
      return [SELECT Id, Product2Id, Product2.specific_gravity__c,  Quantity, UnitOfMeasure__c from OrderItem WHERE RelatedOpportunityItem__c =: oppLineItemId LIMIT 20];
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean isApprovingFactor(Id oppId){
        System.debug(logginglevel.ERROR,'isApprovingFactor 001.: ' + oppId );

        boolean isApprovingFactor = false;
        List<PermissionSetAssignment> FCAdmin = new  List<PermissionSetAssignment>();
        List<ProcessInstance> allPI = new List<ProcessInstance>([SELECT Id,TargetObjectId,TargetObject.Name,SubmittedBy.FirstName,SubmittedBy.LastName,
                                                                 CreatedDate,LastActorId,LastActor.Name,
                                                                 (SELECT ID FROM WorkItems WHERE ActorId =:userInfo.getUserId()),
                                                                 (SELECT Actor.Name,Comments FROM Steps WHERE StepStatus = 'Started') FROM ProcessInstance WHERE TargetObjectId=:oppId
                                                                 ORDER BY CreatedDate DESC ]); 
                                                                 System.debug(logginglevel.ERROR,'isApprovingFactor 002.: ' + isApprovingFactor +allPI);
        for(ProcessInstance PI :allPI){
            if(!PI.WorkItems.isEmpty()){
                isApprovingFactor=true;
            }
            System.debug(logginglevel.ERROR,'isApprovingFactor 003.: ' + isApprovingFactor +allPI);  
       
        }
        return isApprovingFactor;
    }
}