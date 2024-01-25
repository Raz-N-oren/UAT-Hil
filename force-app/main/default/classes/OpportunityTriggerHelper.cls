public with sharing class OpportunityTriggerHelper {
    
    public static void manageOpportunities() {
    System.debug('315. OpportunityTriggerHelper -> manageOpportunities -> Schema.SObjectType.Opportunity.getRecordTypeInfosByName(): ' + Schema.SObjectType.Opportunity.getRecordTypeInfosByName());
        List<RecordType> oppRecordType = [SELECT Id, Name, SobjectType, IsActive FROM RecordType WHERE SobjectType='Opportunity' AND Name='Price Offers' ];
        Id oppRecordTypeId = oppRecordType[0].Id; // Get the 'Price Offers' record type Id
        system.debug(logginglevel.ERROR,'oppRecordTypeId:'+oppRecordTypeId);

        Map<string,ILPriceBookInfo__mdt>  Nuxiclear= new Map<string,ILPriceBookInfo__mdt>();
        List<Opportunity> chemicalOpps = new List<Opportunity>(); // Chemical Opps that waiting for Manager Approval
        Map<Id, List<OpportunityLineItem>> mapedOLIs= new Map<Id, List<OpportunityLineItem>>();
        
        List<OpportunityLineItem> OLIs = [
            SELECT 
                Base_Price__c,
                Currency__c,
                Description,
                Foreign_currency_invoice__c,
                Loading_point__c, 
                OpportunityId, 
                Opportunity.Account.ProductCustomerClassification__c,
                Product2Id, 
                Product2.Sap_Number__c,
                Product2.specific_gravity__c,
                Product2.TonWeightCoefficient__c,
                Quantity,
                RefillFees__c,
                PackagingPrice__c,
                Terms_of_Payment__c,
                TotalPrice,
                Transaction_Type__c,
                UnitPrice, 
                Unit_of_measure__c,
                OverBelowAmount__c,
                ScaleQuantity__c,
                DeliveryUnitOfMeasure__c,
                transportation_currency__c,
            	conversionValueDate__c,
                DeliveryCost__c,
            	Purchase_Order__c
            FROM OpportunityLineItem 
            WHERE OpportunityId = :Trigger.newMap.keySet()
        ];

        // Sort the OLIs by Opportunity ID
        sortOLIs(OLIs, mapedOLIs);
        
        for(Opportunity opp : (List<Opportunity>)Trigger.new){
            Opportunity oldOpp = new Opportunity();
           system.debug(loggingLevel.ERROR,'CurrencyIsoCode:'+opp.CurrencyIsoCode);
            if(Trigger.oldMap != null){
                oldOpp = (Opportunity)Trigger.oldMap.get(opp.Id);
            }

            if( opp.RecordTypeId == oppRecordTypeId && 
                (opp.Status__c == 'Waiting for Manager Approval' || opp.Status__c == 'ממתין לאישור מנהל') 
            ){
                if(opp.Scope__c == 'כימיקלים'){
                    chemicalOpps.add(opp);
                }
            }
        }

        // Call conversion method only if the list is not empty
        if(!chemicalOpps.isEmpty())
            createPBEntries(chemicalOpps, mapedOLIs,Nuxiclear);
    }

    private static void createPBEntries(List<Opportunity> chemicalOpps, Map<Id, List<OpportunityLineItem>> mapedOLIs,Map<string,ILPriceBookInfo__mdt>  Nuxiclear){
        List<RecordType>  chemicalRecTypeId= new List<RecordType>();
        List<IL_Price_Book__c> insertPriceBookEntries = new List<IL_Price_Book__c>();
        List<IL_Price_Book__c> UPDATEtPriceBookEntries = new List<IL_Price_Book__c>();

        for(Opportunity chemOpp : chemicalOpps){ // Loop over the Opportunities
            for(OpportunityLineItem oli : mapedOLIs.get(chemOpp.Id)){ 
                  List<IL_Price_Book__c> BasePB =null;
                if(chemicalRecTypeId.isEmpty()){
                    chemicalRecTypeId= new List<RecordType>([ SELECT Name, Id, DeveloperName, SobjectType FROM RecordType where DeveloperName='Chimical' AND SobjectType ='IL_Price_Book__c']);
                    List<ILPriceBookInfo__mdt>  NuxiclearList= new List<ILPriceBookInfo__mdt>([SELECT Id,UnitOfMeasure__c,ProductSAPNumber__c FROM ILPriceBookInfo__mdt]);
                    for(ILPriceBookInfo__mdt rec:NuxiclearList){
                        Nuxiclear.put(rec.ProductSAPNumber__c,rec);
                    }
                }
                if(oli.Base_Price__c==true&& OLI.Opportunity.Account.ProductCustomerClassification__c!=NULL){
                    BasePB = new List<IL_Price_Book__c>([SELECT Id ,BaseFixedPrice__c
                                                                                FROM IL_Price_Book__c 
                                                                                WHERE 
                                                                                ProductCustomerClassification__c=:OLI.Opportunity.Account.ProductCustomerClassification__c
                                                                               AND 
                                                                               Product_Service__c =:oli.Product2Id]);
                }
               //set ILPB unit of measure
                string pbUOM = (Nuxiclear.get(oli.Product2.Sap_Number__c)!=null?Nuxiclear.get(oli.Product2.Sap_Number__c).UnitOfMeasure__c:'TO');
        
                IL_Price_Book__c newPB = getRelatedPriceBook(oli);
                    // From the Opportunity
                    newPB.recordTypeId=chemicalRecTypeId[0].Id;
                    newPB.Account__c = chemOpp.AccountId;
                    newPB.Base_Price__c =oli.Base_Price__c;
                    newPB.Transaction_Type__c = chemOpp.Type;
                    newPB.Start_Date__c = chemOpp.Valid_from__c;
                    newPB.End_Date__c = chemOpp.Valid_To__c;
                    newPB.Opportunity__c = chemOpp.Id;
                    newPB.RelatedOpportunityItem__c=oli.Id;
                    // From the OpportunityLineItem
                    newPB.Product_Service__c = oli.Product2Id;
                    newPB.Fixed_Price__c = priceCalculationInfo.convertAmountToUnitOfMeasure(pbUOM, oli.Unit_of_measure__c, oli.UnitPrice, oli.Product2.specific_gravity__c,oli.Product2.TonWeightCoefficient__c);
                    newPB.Unit_Of_Meager__c = pbUOM;
                    newPB.conversionValueDate__c=OLI.conversionValueDate__c;
                    newPB.Purchase_Order__c=oli.Purchase_Order__c;
                    newPB.Payment_Terms__c = oli.Terms_of_Payment__c;
                    newPB.CurrencyIsoCode = oli.Currency__c;
                    newPB.Foreign_currency_invoice__c = oli.Foreign_currency_invoice__c;
                    newPB.Loading_Point__c = oli.Loading_Point__c;
                    newPB.transport_Type__c = oli.Transaction_Type__c;
                    newPB.Description__c = oli.Description;
                    newPB.OverBelowAmount__c =oli.OverBelowAmount__c;
                    newPB.OverBelowQuantity__c=oli.ScaleQuantity__c;
                    newPB.Status__c = 'תקף';
                    newPB.DeliveryUnitOfMeasure__c=OLI.DeliveryUnitOfMeasure__c;
                    newPB.ChemicalTransportCurrency__c=OLI.transportation_currency__c;
                    newPB.ChemicalTransportPrice__c=OLI.DeliveryCost__c;
                	newPB.RefillFees__c=oli.RefillFees__c;
                	newPB.Packing_Price__c=oli.PackagingPrice__c;
                	newPB.BasePriceBook__c=BasePB!=null && BasePB[0]!=null?BasePB[0].Id:null;
                	newPB.BaseFixedPrice__c=BasePB!=null && BasePB[0]!=null?BasePB[0].BaseFixedPrice__c:0;
                
                if(!(chemOpp.Type == 'רגילה')){
                    newPB.Quantity__c = oli.Quantity;
                }
                if(newPB.Id!=null){
                    UPDATEtPriceBookEntries.add(newPB);
                }
                else{
                    insertPriceBookEntries.add(newPB);
                    
                }
            }
        }
        if(UPDATEtPriceBookEntries!=null)
            update UPDATEtPriceBookEntries;
        if(insertPriceBookEntries!=null)
            insert(insertPriceBookEntries);
    }

    
    private static IL_Price_Book__c getRelatedPriceBook(OpportunityLineItem oli){
        List<IL_Price_Book__c> newPB = new  List<IL_Price_Book__c>([SELECT Id,recordTypeId,Account__c,Base_Price__c,Transaction_Type__c,Start_Date__c,RefillFees__c,
                                                                    End_Date__c, Product_Service__c,Fixed_Price__c,Unit_Of_Meager__c,conversionValueDate__c,Packing_Price__c,
                                                                    Purchase_Order__c,Payment_Terms__c,CurrencyIsoCode,Foreign_currency_invoice__c,Loading_Point__c,
                                                                    transport_Type__c,Description__c,OverBelowAmount__c,OverBelowQuantity__c,DeliveryUnitOfMeasure__c,
                                                                    ChemicalTransportCurrency__c,ChemicalTransportPrice__c,BasePriceBook__c FROM IL_Price_Book__c 
                                                                    WHERE RelatedOpportunityItem__c=: oli.Id]);
        IL_Price_Book__c foundPB= !newPB.IsEmpty()?newPB[0]: new IL_Price_Book__c();
        return foundPB;

    }
    // Method that sort the OLIs by Opportunity ID
    private static void sortOLIs(
        List<OpportunityLineItem> OLIs, 
        Map<Id, List<OpportunityLineItem>> mapedOLIs){
        for(OpportunityLineItem oli : OLIs){
            List<OpportunityLineItem> tempList = mapedOLIs.get(oli.OpportunityId);
            if(tempList == null){
                mapedOLIs.put(oli.OpportunityId, new List<OpportunityLineItem>{oli});
            }
            else{
                tempList.add(oli);
            }
        }
    } 
}