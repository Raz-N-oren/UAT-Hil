public  with sharing class OpprtunityLineItem_calcProduct {
    Map<Id,OpportunityLineItem> relatedInfo = null;
    
    public OpprtunityLineItem_calcProduct(){
        if(userInfo.getUserId()=='00525000008EuuQAAS')
            calculateInfo();
    }
    
    private void calculateInfo(){
        for(OpportunityLineItem rec: (List<OpportunityLineItem>)trigger.New){
            if(relatedInfo==null){
                relatedInfo = new  Map<Id,OpportunityLineItem>([SELECT Id,opportunity.AccountId,Product2.IL_Group__c,Product2.specific_gravity__c,
                                                                opportunity.Transaction_Type__c,opportunity.Account_Division__c 
                                                                FROM OpportunityLineItem WHERE Id IN:(List<OpportunityLineItem>)trigger.New]);
            }
            OpportunityLineItem relatedRecInfo =relatedInfo!=null && relatedInfo.get(rec.Id)!=null?relatedInfo.get(rec.Id):null;
            if(relatedRecInfo!=null){
                rec.TotalTonPrice__c=priceCalculationInfo.getPrice(rec.Product2Id, relatedRecInfo.opportunity.AccountId,  
                                                                   relatedRecInfo.opportunity.Account_Division__c, rec.Unit_of_measure__c,rec.Quantity,
                                                                   rec.Loading_Point__c, relatedRecInfo.opportunity.Transaction_Type__c,
                                                                   relatedRecInfo.Product2.IL_Group__c, system.today());
                rec.TotalCubePrice__c=relatedRecInfo.Product2.specific_gravity__c==null?rec.TotalTonPrice__c:rec.TotalTonPrice__c*relatedRecInfo.Product2.specific_gravity__c;
            	
                rec.FK_PriceBook__c =priceCalculationInfo.getPBRecord(rec.Product2Id, relatedRecInfo.opportunity.AccountId,relatedRecInfo.opportunity.Account_Division__c,
                                                                      rec.Unit_of_measure__c,rec.Quantity,rec.Loading_Point__c, 
                                                                      relatedRecInfo.opportunity.Transaction_Type__c, relatedRecInfo.Product2.IL_Group__c, 
                                                                      system.today()).Id;
                Discount__c relatedDiscount = getProductDiscount.getDiscountRec(rec.Product2Id, relatedRecInfo.opportunity.AccountId, null, null);
                rec.FK_Discount__c = relatedDiscount!=null?relatedDiscount.Id:null;
            }
        }
    }
}