public class DeliveryNoteItem_PopulateLineItemInfo{
    
    set<Id> relatedDNIds								= new set<Id>();
    set<Id> OrderIds									= new set<Id>();
    Map<Id,List<orderItem>> relatedOIByOrder 			= new Map<Id,List<orderItem>>();
    Map<Id,DeliveryNoteItems__c> oldMap 				= new Map<Id,DeliveryNoteItems__c>();
    static Map<string,DeliveryNote__c> RelatedDNsMap  	= new Map<string,DeliveryNote__c>();

    public DeliveryNoteItem_PopulateLineItemInfo(System.TriggerOperation operation){
        
        oldMap=(Map<Id,DeliveryNoteItems__c>)trigger.OldMap!=null?(Map<Id,DeliveryNoteItems__c>)trigger.OldMap:null;
        SWITCH ON operation{
            WHEN BEFORE_INSERT,BEFORE_UPDATE{
                RelatedDNsMap = new Map<string,DeliveryNote__c>();
                system.debug(loggingLevel.ERROR, 'Entered DeliveryNoteItem_PopulateLineItemInfo BEFORE');
                getRelatedDNInfo();
                getPricingInfo();
            }
            WHEN AFTER_INSERT,AFTER_UPDATE{
                system.debug(loggingLevel.ERROR, 'Entered DeliveryNoteItem_PopulateLineItemInfo AFTER');                
                updateRelatedDN();
            }
        } 
    }
    
    private void getRelatedDNInfo(){
        for(DeliveryNoteItems__c rec:(List<DeliveryNoteItems__c>)trigger.New){
            if(rec.LineItemType__c!='4' && rec.LineItemType__c!='5'){
                relatedDNIds.add(rec.DeliveryNote__c);
                system.debug(loggingLevel.ERROR,'LineItemType__c:'+rec.LineItemType__c );
            }
            if(rec.TransactionType__c=='50'){
                OrderIds.add(rec.Order__c);
            }
        }
        if(!relatedDNIds.isEmpty()){
            RelatedDNsMap = new Map<string,DeliveryNote__c>([SELECT Id,Account__c,Account__r.AccountDivision__c,LoadingPoint__c,OrderItem__r.TransactionType__c,FKBillingCredit__c,TransactionType__c,
                                                             OrderItem__r.TransportType__c,InvoiceDate__c,OrderCreatedDate__c,UnitOfMeasure__c,DischargeQuantity__c ,InventoryManagementOnly__c,PricingDate__c,
                                                             Order__r.NonFreightCharge__c,DischargeWeightInTon__c ,OrderItem__r.Product2.Sap_Number__c,OrderItem__r.product2.Packing__c,LoadingSlipNumber__c,OrderItem__r.Product2.InnerProcess__c,
                                                             OrderItem__r.RelatedOpportunityItem__r.Need_a_cart__c,OrderItem__r.RelatedOpportunityItem__r.Cost_level__c,Dischargequantityuom__c
                                                             FROM DeliveryNote__c
                                                             WHERE ID IN:relatedDNIds]);
        }
        if(!OrderIds.isEmpty()){
             List<orderItem> relatedOIs = new List<orderItem>([SELECT Id,Product2Id,Extension_1__c,Extension_1__r.specific_gravity__c,Extension_1__r.IL_Group__c,
                                                               Extension_Quantity_1__c,Extension_Unit_1__c,Extension_1__r.Product_hierarchy_Code__c,
                                                               Extension_2__c,Extension_2__r.specific_gravity__c,Extension_Quantity_2__c,
                                                               Extension_Unit_2__c,Extension_2__r.Product_hierarchy_Code__c,Extension_2__r.IL_Group__c,
                                                               Extension_3__c,Extension_3__r.specific_gravity__c,Extension_Quantity_3__c,Product2.Sap_Number__c,
                                                               Extension_1__r.Sap_Number__c,Extension_2__r.Sap_Number__c,Extension_3__r.Sap_Number__c,
                                                               Extension_Unit_3__c,Extension_3__r.Product_hierarchy_Code__c,Extension_3__r.IL_Group__c,
                                                               order.Account.Setelment__c,order.Account.Setelment__r.Geographic_Area__c,UnitOfMeasure__c,
                                                               product2.Product_Hiarch_Type__c,product2.IL_Group__c,product2.specific_gravity__c,
                                                                product2.TonWeightCoefficient__c,order.Branch_growth__c,order.AgentReceivesCommission__c,
                                                               product2.Product_hierarchy_Code__c,OrderId,TransactionType__c,order.createdDate,TransportType__c,
                                                               TotalTonWeight__c,Quantity,Order.NonFreightCharge__c,order.Account.OwnerId,Product2.InnerProcess__c,
                                                               order.Account.AccountDivision__c,order.Account.ParentId, Order.TransactionType__c,Order.Paying_Customer__c,
                                                               RelatedOpportunityItem__c,RelatedOpportunityItem__r.Need_a_cart__c,RelatedOpportunityItem__r.Cost_level__c,
                                                                RelatedOpportunityItem__r.Terms_of_Payment__c
                                                               FROM orderItem
                                                               WHERE orderId IN:OrderIds ]);
            
            for(orderItem OI:relatedOIs){
                if(relatedOIByOrder.get(oi.OrderId)!=null){
                    relatedOIByOrder.get(oi.OrderId).add(oi);
                }
                else{
                    relatedOIByOrder.put(oi.orderId,new List<orderItem>{oi});
                }
            }
        }
    }
    
    private void getPricingInfo(){
        for(DeliveryNoteItems__c rec:(List<DeliveryNoteItems__c>)trigger.New){ 
            Map<string,IL_Price_Book__c> getPBInfo= new Map<string,IL_Price_Book__c>();
            DeliveryNoteItems__c old 		= oldMap!=null && oldMap.get(rec.id)!=null?oldMap.get(rec.id):null;
            DeliveryNote__c DN 				=  RelatedDNsMap.get(rec.DeliveryNote__c);
           /* if(rec.Product__c!=null && DN!=null && DN.InventoryManagementOnly__c==false && DN.FKBillingCredit__c==null && DN.TransactionType__c!='10' &&( rec.RelatedPriceBook__c==null || rec.LineItemType__c=='6' || rec.LineItemType__c=='7'||(old!=null&&  old.ReplaceMainProduct__c!=rec.ReplaceMainProduct__c))){*/
            if(old!=null&&  old.ReplaceMainProduct__c!=rec.ReplaceMainProduct__c && rec.LineItemType__c!='7'&& rec.DischargeQuantity__c!=null && rec.LineItemType__c!='6'){
                
                getPBInfo 					= priceCalculationInfo.setPriceAndPBRec(rec,(rec.ReplaceMainProduct__c!=null?rec.ReplaceMainProduct__c:rec.Product__c), DN.Account__c,DN.Account__r.AccountDivision__c,DN.Dischargequantityuom__c ,rec.TotalWeight__c,DN.LoadingPoint__c, DN.OrderItem__r.TransportType__c, rec.ProductILGroup__c,DN.PricingDate__c);
                system.debug(loggingLevel.ERROR, '-->getPricingInfo-->getPBInfo:'+getPBInfo);
                
                string targetUOM			= getPBInfo.get(rec.UniqueId__c)!=null && getPBInfo.get(rec.UniqueId__c).Unit_Of_Meager__c!=null?getPBInfo.get(rec.UniqueId__c).Unit_Of_Meager__c :DN.Dischargequantityuom__c;
                rec.RelatedPriceBook__c 	= getPBInfo.get(rec.UniqueId__c)!=null?getPBInfo.get(rec.UniqueId__c).Id:null;       
                if(rec.LineItemType__c!='6'&& rec.LineItemType__c!='7' && getPBInfo.get(rec.UniqueId__c)!=null){
                    decimal priceamount 	= priceCalculationInfo.calculateUnitPrice(getPBInfo.get(rec.UniqueId__c)); 
                    rec.UnitOfMeasure__c = targetUOM;
                    if(targetUOM=='TO' && DN.Dischargequantityuom__c =='EA'){
                        rec.TotalPrice__c  		= (DN.DischargeWeightInTon__c/DN.DischargeQuantity__c)*priceamount;
                        rec.TotalCubeWeight__c=0;
                        rec.TotalPriceInCube__c=0;
                        if(rec.LineItemType__c=='1' && DN.OrderItem__r.product2.Packing__c!=null){
                            List<IL_Price_Book__c> relatedPackingPrice = new  List<IL_Price_Book__c>([SELECT Id,Fixed_Price__c 
                                                                                                      FROM IL_Price_Book__c
                                                                                                      WHERE Packing__c=: DN.OrderItem__r.product2.Packing__c
                                                                                                      AND status__c='תקף']);
                            system.debug(loggingLevel.ERROR, 'relatedPackingPrice:'+relatedPackingPrice);
                            rec.RelatedPacking__c=relatedPackingPrice[0]!=null?relatedPackingPrice[0].Id:null;
                            rec.UnitOfMeasure__c='EA';
                        }
                    }
                    else{
                        rec.TotalPrice__c  		= priceamount;
                        rec.TotalPriceInCube__c	= getPBInfo.get(rec.UniqueId__c)!=NULL&& rec.TotalPrice__c!=null?priceCalculationInfo.convertAmountToUnitOfMeasure(targetUOM,'M3',priceamount,getPBInfo.get(rec.UniqueId__c).Product_Service__r.specific_gravity__c,getPBInfo.get(rec.UniqueId__c).Product_Service__r.TonWeightCoefficient__c):0;
                        
                    }
                    rec.CurrencyIsoCode  	= getPBInfo.get(rec.UniqueId__c).Foreign_currency_invoice__c==true?getPBInfo.get(rec.UniqueId__c).CurrencyIsoCode:'ILS';//relevant to Sap
                    system.debug(loggingLevel.ERROR,'DeliveryNoteItem_PopulateLineItemInfo-->getPricingInfo:CurrencyIsoCode-'+rec.CurrencyIsoCode+'-TotalPrice__c-'+rec.TotalPrice__c+'-TotalPriceInCube__c-'+rec.TotalPriceInCube__c);
                    rec.SumLineBeforeDiscount__c=rec.LineItemType__c!='7'&& rec.DischargeQuantity__c!=null?rec.TotalPrice__c*rec.DischargeQuantity__c:0;
                }
            }	
            
            if(rec.TotalPrice__c!=null && rec.DischargeQuantity__c!=null)
                rec.SumLineBeforeDiscount__c=rec.LineItemType__c!='7'&& rec.DischargeQuantity__c!=null && rec.LineItemType__c!='6'?rec.TotalPrice__c*rec.DischargeQuantity__c:0;
            
            if(rec.LineItemType__c=='6' || rec.LineItemType__c=='7'){
                calcTotalFertJob(rec,DN);
            }
            if(rec.LineItemType__c=='3' && DN.InventoryManagementOnly__c==false){ //set pricing when delivery cost null
                setTransportDeliveryPricing(rec,DN);
            }
        }
    }
    
    private void setTransportDeliveryPricing(DeliveryNoteItems__c rec,DeliveryNote__c DN){
        system.debug(loggingLevel.error,'Enter setTransportDeliveryPricing Function: Line 3 DeliveryCost__c:'+ rec.DeliveryCost__c);
        if(rec.FullDeliveryDiscount__c==false && DN.Account__r.AccountDivision__c!='כימיקלים'){
            rec.LineDiscount__c=NULL;            
            if(DN.Order__r.NonFreightCharge__c==true|| rec.FullDeliveryDiscount__c==true){
                system.debug(loggingLevel.ERROR, 'Delivery full discount :NonFreightCharge__c-'+DN.Order__r.NonFreightCharge__c+ '-- FullDeliveryDiscount__c:'+rec.FullDeliveryDiscount__c);
                rec.LineDiscount__c=100;
            } 
            else if(DN.DischargeQuantity__c>0  && DN.OrderItem__r.TransactionType__c!='50'  && DN.OrderItem__c!=null && DN.OrderItem__r.Product2Id!=null && DN.OrderItem__r.Product2.InnerProcess__c==false){
                List<IL_Price_Book__c> relatedPBList= new List<IL_Price_Book__c>([SELECT Id,Loading_Point__c,Product_Family_new__c,
                                                                                  Transaction_Type__c,Start_Date__c,End_Date__c,Fixed_Price__c
                                                                                  FROM IL_Price_Book__c 
                                                                                  WHERE RecordType.Name='transport' LIMIT 1]);
                rec.DeliveryCost__c	=relatedPBList!=null && !relatedPBList.isEmpty()?relatedPBList[0].Fixed_Price__c:0.00;
                system.debug(loggingLevel.error,'rec.DeliveryCost__c='+ rec.DeliveryCost__c);
                rec.SumLineBeforeDiscount__c	=rec.DeliveryCost__c*DN.DischargeQuantity__c;
                
                AggregateResult[] groupedResults=[SELECT DeliveryNote__r.LoadingSlipNumber__c, sum(TotalWeight__c)totalWeight,sum(TotalCubeWeight__c)totalCubeWeight 
                                                  FROM DeliveryNoteItems__c 
                                                  WHERE DeliveryNote__r.LoadingSlipNumber__c =:DN.LoadingSlipNumber__c 
                                                  AND DeliveryNote__r.Account__c=:DN.Account__c 
                                                  Group By DeliveryNote__r.LoadingSlipNumber__c];
                if(!groupedResults.isEmpty()){
                    Decimal totalTon=(decimal)groupedResults[0].get('totalWeight');
                    Decimal totalcube=(decimal)groupedResults[0].get('totalCubeWeight');
                    system.debug(loggingLevel.ERROR, 'totalTon delivery discount  line 127:'+totalTon);
                    if(totalTon>3 ||totalcube>1){
                        rec.LineDiscount__c=100; 
                        system.debug(loggingLevel.ERROR, 'delivery discount  line 156:'+ rec.LineDiscount__c);

                    }
                }
            }
        }
    }
    
    private void calcTotalFertJob(DeliveryNoteItems__c rec,DeliveryNote__c DN){
        if(rec.LineItemType__c=='6' && DN.InventoryManagementOnly__c==false){
            orderItem fert1Ton=null;
            orderItem  fert2Ton=null;
            decimal fert1quantityPerHecter=0;
            decimal fert2quantityPerHecter=0;
            decimal fert1Price =0;
            decimal fert2Price =0;
            system.debug(loggingLevel.ERROR, 'relatedOIByOrder.get(rec.order__C) size:'+relatedOIByOrder.get(rec.order__C).size());             
            for(orderItem recOI:   relatedOIByOrder.get(rec.order__C)){
                if(recOI.Id!=rec.OrderItem__c){
                    if(fert1Ton==null){
                        fert1Ton=recOI;
                        system.debug(loggingLevel.ERROR, 'fert1Ton:'+recOI);  
                    }
                    else if(fert1Ton!=null){
                        fert2Ton= recOI;   
                        system.debug(loggingLevel.ERROR, 'fert2Ton:'+recOI);  
                    }
                }
            }             
            system.debug(logginglevel.error,'fert1Ton.Quantity:'+fert1Ton.Quantity+' rec.DischargeQuantity__c:'+rec.DischargeQuantity__c);
            fert1quantityPerHecter=fert1Ton!=null?fert1Ton.Quantity/rec.DischargeQuantity__c:1;
            fert2quantityPerHecter=fert2Ton!=null?fert2Ton.Quantity/rec.DischargeQuantity__c:1;
            if(fert1Ton!=null)
                fert1Price=FertalzationJobCalc.getFertPrdPriceAfterDiscount(fert1Ton.Product2Id, DN.Account__c, FertalzationJobCalc.getFertPrdPriceBeforeDiscount(fert1Ton.Product2Id,DN.Account__c ,DN.LoadingPoint__c, fert1quantityPerHecter,rec.DischargeQuantity__c, fert1Ton.UnitOfMeasure__c));
            if(fert2Ton!=null)
                fert2Price=FertalzationJobCalc.getFertPrdPriceAfterDiscount(fert2Ton.Product2Id, DN.Account__c,FertalzationJobCalc.getFertPrdPriceBeforeDiscount(fert2Ton.Product2Id,DN.Account__c ,DN.LoadingPoint__c, fert2quantityPerHecter,rec.DischargeQuantity__c, fert2Ton.UnitOfMeasure__c));
            
            rec.FertJobCalc__c= FertalzationJobCalc.getTotalFertJob(DN.Account__c,rec.Product__c,fert1Ton.Product2Id,
                                                                    fert2Ton!=null?fert2Ton.Product2Id:null, fert1quantityPerHecter,'TO', 
                                                                    fert2quantityPerHecter, 'TO', 
                                                                    DN.OrderItem__r.RelatedOpportunityItem__r.Need_a_cart__c,
                                                                    DN.OrderItem__r.RelatedOpportunityItem__r.Cost_level__c, 
                                                                    rec.DischargeQuantity__c ,fert1Price, fert2Price);
            rec.TotalPrice__c = rec.FertJobCalc__c/rec.DischargeQuantity__c;
            rec.TotalCubeWeight__c=0;
            rec.TotalPriceInCube__c=0;
            rec.SumLineBeforeDiscount__c=rec.FertJobCalc__c;
            system.debug(loggingLevel.ERROR, ' rec.FertJobCalc__c:'+ rec.FertJobCalc__c);
        }
    }
    
    private void updateRelatedDN(){
        system.debug(loggingLevel.ERROR, '1.RelatedDNsMap size:'+ RelatedDNsMap.values());
        if(!RelatedDNsMap.isEmpty()){
            system.debug(loggingLevel.ERROR, '2.RelatedDNsMap size:'+ RelatedDNsMap.values());
            update RelatedDNsMap.values();
        }
    }
}