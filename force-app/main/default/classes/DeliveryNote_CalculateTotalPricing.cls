public class DeliveryNote_CalculateTotalPricing {
    Set<Id> orderItemsId                       			= new Set<Id>();
    Set<Id> orderIds                          			= new Set<Id>();
    Set<Id> accountIds                          		= new Set<Id>();
    
    Map<Id,OrderItem> orderItemMaps             		= new Map<Id,OrderItem>();
    Map<string,OrderItem> OIRelatedToOrderMaps  		= new Map<string,OrderItem>();
    
    Map<Id,DeliveryNote__c> oldMapTrigger    			= (Map<Id,DeliveryNote__c>)trigger.OldMap;
    static Map<Id, List<DeliveryNoteItems__c>> DNLineItemsMap 	= new Map<Id, List<DeliveryNoteItems__c>>();
   	static Map<Id,Billing_Credit__c> groupedResults		= New Map<Id,Billing_Credit__c>();
    set<string> existingCredit 							= new set<string>();
    
   static List<DeliveryNoteItems__c> createNewDNI 		= new  List<DeliveryNoteItems__c>();
    
    public DeliveryNote_CalculateTotalPricing(System.TriggerOperation operation){

     SWITCH ON operation{
            WHEN BEFORE_UPDATE{
                createNewDNI= new  List<DeliveryNoteItems__c>();
                system.debug(loggingLevel.ERROR, 'Entered DeliveryNote_CalculateTotalPricing - BEFORE');
                
                setorderItemMaps();
                getRelatedDeliveryNoteLines();
                setTotalLinesInfo();
            }
            WHEN AFTER_UPDATE{
                system.debug(loggingLevel.ERROR, 'Entered DeliveryNote_CalculateTotalPricing - AFTER');
                replaceMainProductPricing();
                sendDNToSap();
                if(!groupedResults.IsEmpty()){
                    update groupedResults.values();
                } 
                if(!createNewDNI.isEmpty()){
                    system.debug(loggingLevel.ERROR, 'createNewDNI:'+createNewDNI);
                    upsert createNewDNI UniqueId__c;
                }
            }
        }
    }
    
    private void setorderItemMaps(){
        for(DeliveryNote__c DN: (List<DeliveryNote__c>)trigger.new){
            Map<Id,Set<Id>> ParentAccountMap = new Map<Id,Set<Id>>();
            if(DN.InvoiceDate__c==null && DN.SupplyDate__c!=null  && DN.FKBillingCredit__c==null)
                DN.InvoiceDate__c=DN.SupplyDate__c;
            if(DN.Account__c!=null)
                accountIds.add(DN.Account__c);
            if(DN.OrderItem__c!=null)
                orderItemsId.add(DN.OrderItem__c);
            if(DN.Order__c!=NULL)
                orderIds.add(DN.Order__c);
        }
        
        if(!orderItemsId.isEmpty()){
            List<orderItem> getRelatedOI= new List<orderItem>([SELECT Id,Extension_1__c,Extension_1__r.specific_gravity__c,Extension_1__r.IL_Group__c,
                                                               Extension_Quantity_1__c,Extension_Unit_1__c,Extension_1__r.Product_hierarchy_Code__c,
                                                               Extension_2__c,Extension_2__r.specific_gravity__c,Extension_Quantity_2__c,
                                                               Extension_Unit_2__c,Extension_2__r.Product_hierarchy_Code__c,Extension_2__r.IL_Group__c,
                                                               Extension_3__c,Extension_3__r.specific_gravity__c,Extension_Quantity_3__c,
                                                               Extension_1__r.Sap_Number__c,Extension_2__r.Sap_Number__c,Extension_3__r.Sap_Number__c,
                                                               Extension_Unit_3__c,Extension_3__r.Product_hierarchy_Code__c,Extension_3__r.IL_Group__c,
                                                               order.Account.Setelment__c,order.Account.Setelment__r.Geographic_Area__c,UnitOfMeasure__c,
                                                               product2.Product_Hiarch_Type__c,product2.IL_Group__c,product2.specific_gravity__c,product2.TonWeightCoefficient__c,
                                                               product2.Product_hierarchy_Code__c,OrderId,TransactionType__c,order.createdDate,TransportType__c,
                                                               TotalTonWeight__c,Quantity,Order.NonFreightCharge__c,Product2.Sap_Number__c,order.Account.OwnerId,
                                                               order.Account.AccountDivision__c,order.Account.ParentId, Order.TransactionType__c,RelatedOpportunityItem__c,
                                                               RelatedOpportunityItem__r.Need_a_cart__c,RelatedOpportunityItem__r.Cost_level__c,order.Account.Owner.IsActive
                                                               FROM orderItem
                                                               WHERE Id IN:orderItemsId OR orderId IN :orderIds]);
            for(orderItem recOI:getRelatedOI){
                orderItemMaps.put(recOI.Id, recOI);
                OIRelatedToOrderMaps.put(recOI.OrderId+'-'+recOI.Product2Id, recOI);
            }
        } 
    }
    
    private void getRelatedDeliveryNoteLines(){
        if(DNLineItemsMap.isEmpty()){
            List<DeliveryNote__c> relatedDeliveryNoteLines = [SELECT Id,InventoryManagementOnly__c,(SELECT Id,DeliveryCost__c,DeliveryNote__c,DischargeQuantity__c,FertJobCalc__c,
                                                                                                    FertProdBeforeDis__c,UnitOfMeasure__c,FK_ProductDiscount__c,LineDiscount__c,
                                                                                                    DiscountAmount__c,LineItemType__c,TotalCubeWeight__c,TotalPriceInCube__c,
                                                                                                    LinePrice__c,LinePriceCube__c,TotalPrice__c,TotalWeight__c,Product__c,
                                                                                                    ProductSpecificGravity__c,UniqueId__c,RelatedPriceBook__r.DeliveryUnitOfMeasure__c,
                                                                                                    RelatedPriceBook__r.Payment_Terms__c,ReplaceMainProduct__c,RelatedPriceBook__r.CurrencyIsoCode,
                                                                                                    DeliveryNote__r.RelatedDeliveryNote__r.status__C,RelatedPriceBook__r.Unit_Of_Meager__c 
                                                                                                     FROM Delivery_Note_Line_Items__r ) 
                                                              from DeliveryNote__c WHERE Id IN:(List<DeliveryNote__c>)trigger.new ];
            for(DeliveryNote__c rec:relatedDeliveryNoteLines){
                DNLineItemsMap.put(rec.Id, rec.Delivery_Note_Line_Items__r);
               
            }
        }
    }
    
    private  void getPendingApprovalDiscount(DeliveryNote__c DN){
        if(DNLineItemsMap.get(DN.Id)!=null && (DN.TotalLinesDiscount__c==0||DN.TotalLinesDiscount__c==null) && DN.InventoryManagementOnly__c==false && DN.TransactionType__c!='10' &&DN.TransactionType__c!='50' && DN.TransactionType__c!=null){
            for(DeliveryNoteItems__c DNI:DNLineItemsMap.get(DN.Id)){
                if(DNI.LineItemType__c=='1' || DNI.LineItemType__c=='2' ||
                   DNI.LineItemType__c=='6'){
                       Discount__c relatedDiscount     = getProductDiscount.getPendingApprovalDiscountRec(DNI.Product__c,DN.Account__c);
                       if(relatedDiscount!=null && relatedDiscount.Requested_Discount__c>0){
                           DN.PendingApprovalDiscount__c=true;
                       }
                   }
            } 
        }
        else{
            DN.PendingApprovalDiscount__c=false;
        }
    }
    
    private void setBillingLines(DeliveryNote__c DN){
        decimal startQuantity=DN.TotalLinesQuantity__c;
        decimal totalDNPrice= DN.TotalLinePrice__c*DN.TotalLinesQuantity__c;
        system.debug(loggingLevel.ERROR, ' Billing credit:TotalLinePrice__c-'+ DN.TotalLinePrice__c+' -->DN.TotalLinesQuantity__c-'+DN.TotalLinesQuantity__c+'='+totalDNPrice);
        
        decimal existQuantityCreditToDN =0;
        decimal existSumCreditToDN =0;
        DeliveryNoteItems__c prdLine= new DeliveryNoteItems__c();
        
        if(!DNLineItemsMap.isEmpty() && DNLineItemsMap.get(DN.Id)!=null ){
            for(DeliveryNoteItems__c DNI:DNLineItemsMap.get(DN.Id)){
                if(DNI.LineItemType__c=='1'){
                    prdLine=DNI;
                }
                if(DNI.LineItemType__c=='4'){
                    existQuantityCreditToDN+=DNI.TotalWeight__c>0?DNI.TotalWeight__c:0;
                    existSumCreditToDN+=DNI.TotalPrice__c>0?DNI.TotalPrice__c:0;
                    existingCredit.add(DNI.UniqueId__c);
                                        system.debug(loggingLevel.ERROR, '1.Billing credit:TotalLinePrice__c-='+totalDNPrice);
                }
            }
            startQuantity=DN.TotalLinesQuantity__c-existQuantityCreditToDN;
            totalDNPrice= totalDNPrice-existSumCreditToDN;
            system.debug(loggingLevel.ERROR,'dn.FKBillingCredit__c:'+dn.FKBillingCredit__c);
            if(dn.FKBillingCredit__c==null && dn.TransactionType__c!='40' && dn.TransactionType__c!='10')
                getTotalBillingCredit(DN,prdLine,startQuantity,totalDNPrice);
        }
    }
    
    private void getTotalBillingCredit(DeliveryNote__c DN,DeliveryNoteItems__c prdLine,Decimal startQuantity,Decimal totalDNPrice){
        decimal totalCredit=0;
        decimal totalCreditSum=0;
        decimal totalCreditQuan=0;
        
        if(groupedResults.isEmpty()){
            system.debug(loggingLevel.ERROR, 'accountIds line 146:'+accountIds);
            

            groupedResults= New Map<Id,Billing_Credit__c>([SELECT Id, Name, Action_Type__c, Account__c, Delivery_Note__c, Document_Date__c, Value_Date__c, 
                                                           Loading_Point__c, Wearhouse__c, Paying_Customer__c, Product__c, Type__c, Quantity__c, Sum__c, 
                                                           Unit_of_measure__c, Expiration_Date__c, Status__c, Invoicing__c, Reason__c, Comment__c, 
                                                           TotalCredit__c, UsedCredit__c, isMaxedCredit__c, refund_year__c, business_unit__c, 
                                                           customer_type__c, start_date__c, deal_type__c, TotalWeight__c 
                                                           FROM Billing_Credit__c WHERE  
                                                           status__c='30' AND
                                                           (
                                                               Account__c IN:accountIds 
                                                               OR
                                                               Paying_Customer__c IN:accountIds
                                                           )
                                                           AND 
                                                           Product__c=:dn.Product__c]);
        }
        system.debug(loggingLevel.ERROR, 'groupedResults:'+groupedResults);
        
        
        for(Billing_Credit__c recBC:groupedResults.values()){
            system.debug(loggingLevel.ERROR, 'recBC.isMaxedCredit__c:'+recBC.isMaxedCredit__c+'--startQuantity:'+startQuantity+' --totalDNPrice:'+totalDNPrice);
            system.debug(loggingLevel.ERROR, 'recBC uniqe idetifier:'+DN.DeliveryNoteLineId__c +'-'+recBC.Id);
            system.debug(loggingLevel.ERROR, 'recBC existingCredit:'+existingCredit);

            if(recBC.isMaxedCredit__c==false && !existingCredit.contains(DN.DeliveryNoteLineId__c +'-'+recBC.Id)){
                system.debug(loggingLevel.ERROR, 'recBC:'+recBC);
                decimal credit =0;
                if(recBC.Sum__c>0)
                    credit= recBC.UsedCredit__c>0?recBC.Sum__c-recBC.UsedCredit__c:recBC.Sum__c;
                else
                    credit= recBC.UsedCredit__c>0?recBC.Quantity__c-recBC.UsedCredit__c: recBC.Quantity__c;
                 
                if(recBC.Account__c==DN.Account__c && startQuantity>0 && totalDNPrice>0){
                    decimal BCTonQuantity=0;
                    decimal BCSum=0;
                    decimal usedCredit=0;
                    
                    If(totalCredit<totalDNPrice&& recBC.Product__c!=null && prdLine!=null && prdLine.Product__c==recBC.Product__c  && credit>0 ){
                        decimal TonQuantity             = recBC.Quantity__c>0 ?orderItem_CalculateInfo.calculateTotalTonWeight(credit, recBC.Unit_of_measure__c, PRDlINE.ProductSpecificGravity__c, NULL):0;
                        decimal quantConvertToAmount    = TonQuantity*DN.TotalLinePrice__c;
                        if(TonQuantity>0){
                            BCTonQuantity               = quantConvertToAmount<totalDNPrice?quantConvertToAmount/DN.TotalLinePrice__c:(quantConvertToAmount-(quantConvertToAmount-totalDNPrice))/DN.TotalLinePrice__c;
                            usedCredit                  = convertTon(BCTonQuantity,PRDlINE.ProductSpecificGravity__c,recBC.Unit_of_measure__c) ;
                        }
                        else{
                            BCSum                       = totalDNPrice<credit?recBC.Sum__c-(credit-totalDNPrice):credit;
                            usedCredit                  = totalDNPrice<credit?recBC.Sum__c-totalDNPrice:credit;
                        }
                        
                        startQuantity                   = BCTonQuantity>0?startQuantity-BCTonQuantity:startQuantity;
                        totalDNPrice                    = BCTonQuantity>0?totalDNPrice - BCTonQuantity*DN.TotalLinePrice__c:totalDNPrice<BCSum?0:totalDNPrice-recBC.Sum__c;
                        totalCredit                    += BCTonQuantity>0?BCTonQuantity:BCSum;
                    }
                    else if(totalCredit<DN.TotalLinePriceAfterDiscount__c && recBC.Sum__c>0 && recBC.Product__c==null && (0<startQuantity &&  totalDNPrice>0)){
                        BCSum           = totalDNPrice<recBC.Sum__c?recBC.Sum__c-(recBC.Sum__c-totalDNPrice):recBC.Sum__c;
                        usedCredit      = totalDNPrice<recBC.Sum__c?recBC.Sum__c-totalDNPrice:recBC.Sum__c;
                        totalDNPrice    = totalDNPrice<recBC.Sum__c && totalDNPrice>0?0:totalDNPrice-recBC.Sum__c;
                        totalCredit    += totalDNPrice<recBC.Sum__c?recBC.Sum__c-(recBC.Sum__c-totalDNPrice):recBC.Sum__c;
                    }
                    system.debug(loggingLevel.ERROR, ' Billing credit:usedCredit:'+usedCredit);
                    if(usedCredit>0 ){
                        string UniqueId = DN.DeliveryNoteLineId__c +'-'+recBC.Id;
                        //create Credit Billing record
                        DeliveryNoteItems__c DNI = new DeliveryNoteItems__c();
                        DNI.FK_BillingCredit__c=recBC.iD;
                        DNI.UniqueId__c=UniqueId;
                        DNI.TotalWeight__c=BCTonQuantity==0?0:BCTonQuantity;
                        DNI.TotalPrice__c=BCTonQuantity>0?0:recBC.TotalCredit__c;  
                        DNI.SumLineBeforeDiscount__c=BCTonQuantity>0?DNI.TotalPrice__c*BCTonQuantity:0;
                        DNI   = DeliveryNoteItem_UpsertLines.setDNIRec( DNI,DN,null,UniqueId,'4',orderItemMaps.get(DN.OrderItem__c),null);
                        createNewDNI.add(DNI);
                        DNLineItemsMap.get(DN.Id).add(DNI);
                        groupedResults.get(recBC.Id).UsedCredit__c=usedCredit;
                    }
                }
            }
        }
        
        system.debug(loggingLevel.ERROR, ' Billing credit:DNLineItemsMap-'+DNLineItemsMap.values());
        
        if(DNLineItemsMap.get(DN.Id)!=NULL){
            for(DeliveryNoteItems__c DNI:DNLineItemsMap.get(DN.Id)){
                if(DNI.LineItemType__c=='4'){
                    if(DNI.TotalPrice__c>0 || DNI.TotalPrice__c<0 ){
                        totalCreditSum+=DNI.TotalPrice__c;
                    }
                    if(dni.TotalWeight__c!=0 && dni.TotalWeight__c!=null){
                        totalCreditQuan+=dni.TotalWeight__c;
                    }
                }
            }
            system.debug(loggingLevel.ERROR, 'total credit info:totalCreditQuan-'+totalCreditQuan+' totalCreditSum-'+totalCreditSum);
            DN.TotalCreditBilling__c    = totalCreditQuan;
            DN.totalCreditBillingValue__c=totalCreditSum;
        }
    }
    
    private void setTotalLinesInfo(){
        for(DeliveryNote__c DN: (List<DeliveryNote__c>)trigger.new){
            if( dn.FKBillingCredit__c==null ){
            decimal totalCubeWeight=0;
            decimal totalWeight=0;
            decimal totalCubePrice=0;
            decimal totalPrice=0;
            decimal totalDiscount=0;
            decimal deliveryCost=0;
            decimal deliveryDiscount=0;
            decimal DiscountAmount=0;
            string originalDeliveryNoteStatus =Null;
            string DeliveryUnitOfMeasure='';
            Id  mainProduct = null;
            string paymentTerms =DN.Payment_Terms__c;
            system.debug(loggingLevel.ERROR, 'DNLineItemsMap.get(DN.Id):'+DNLineItemsMap.get(DN.Id));
            if(DNLineItemsMap.get(DN.Id)!=NULL){
                for(DeliveryNoteItems__c DNI:DNLineItemsMap.get(DN.Id)){
                    system.debug(loggingLevel.ERROR, 'DNLineItemsMap.get(DN.Id) line info:'+DNI);
                    if(DNI.DeliveryNote__r.RelatedDeliveryNote__r.status__C!='70' && DNI.DeliveryNote__r.RelatedDeliveryNote__r.status__C!='60' && DN.TransactionType__c=='40')
                        originalDeliveryNoteStatus = '60';
                    if(DNI.LineItemType__c=='1' ||DNI.LineItemType__c=='6' || (DNI.LineItemType__c=='7' && DN.InventoryManagementOnly__c==true)){
                        mainProduct=DNI.Product__c!=null?DNI.Product__c:null;
                        string uom=DN.Dischargequantityuom__c!=null?DN.Dischargequantityuom__c:dn.UnitOfMeasure__c;
                        if(DNI.RelatedPriceBook__r.Unit_Of_Meager__c!=null){
                            DN.FinalUnitOfMeasure__c = uom=='EA' && DNI.RelatedPriceBook__r.Unit_Of_Meager__c=='TO'?'EA':DNI.RelatedPriceBook__r.Unit_Of_Meager__c;
                        }
                        else
                            DN.FinalUnitOfMeasure__c=uom;
                        DN.CurrencyIsoCode=DNI.RelatedPriceBook__c!=null?DNI.RelatedPriceBook__r.CurrencyIsoCode:'ILS';
                        paymentTerms=paymentTerms==null && DNI.RelatedPriceBook__c!=null?DNI.RelatedPriceBook__r.Payment_Terms__c:paymentTerms;
                        DeliveryUnitOfMeasure=DNI.RelatedPriceBook__r.DeliveryUnitOfMeasure__C;
                    }
                    if( (dn.InventoryManagementOnly__c==true && DNI.LineItemType__c=='7') ||( DNI.LineItemType__c!='7' && DNI.LineItemType__c!='4' && DNI.LineItemType__c!='5')){
                        if(DNI.LineItemType__c!='3'){ 
                            if(DNI.TotalCubeWeight__c!=null)
                                totalCubeWeight+=DNI.TotalCubeWeight__c;
                            if(DNI.TotalWeight__c!=null)
                                totalWeight+=DNI.TotalWeight__c;
                            if(DNI.TotalPriceInCube__c!=null)
                                totalCubePrice+=DNI.LinePriceCube__c;
                            if(DNI.TotalPrice__c!=null)
                                totalPrice+=DNI.LinePrice__c*DNI.TotalWeight__c;
                        }
                        if(DNI.DeliveryCost__c!=NULL){ deliveryCost+=DNI.DeliveryCost__c;}
                        if(DNI.LineItemType__c=='3' && DNI.LineDiscount__c!=NULL)
                            deliveryDiscount+=DNI.LineDiscount__c;                     
                        if(DNI.LineItemType__c=='8' && DNI.LineDiscount__c!=NULL)
                            totalDiscount+=DNI.LineDiscount__c; 
                    }
                }
            }
                DN.Payment_Terms__c 		= paymentTerms;
                DN.Product__c               = mainProduct;
                DN.TotalLinePrice__c        = totalWeight!=null && totalWeight!=0 ?(totalPrice/totalWeight).setScale(3):0;
                DN.TotalLineCubePrice__c    = totalCubePrice>0?totalCubePrice.setScale(3):0;
                DN.TotalLinesDiscount__c    = totalDiscount>0?totalDiscount.setScale(2):0;
                DN.TotalLinesQuantity__c    = totalWeight;
                DN.TotalLineCubeQuantity__c = totalCubeWeight;
                DN.delivery_cost__c         = deliveryCost;
                DN.DeliveryUnitOfMeasure__c = DeliveryUnitOfMeasure;
                system.debug(loggingLevel.ERROR,'deliveryCost  pricing:'+deliveryCost+'--> DN.delivery_cost__c*totalWeight: '+(DN.DischargeQuantity__c!=null?DN.delivery_cost__c*totalWeight:DN.delivery_cost__c*1));
                DN.Delivery_discount__c     = deliveryDiscount;
                DN.Status__c=DN.DischargeQuantity__c>0 && DN.TransactionType__c=='10'|| originalDeliveryNoteStatus=='60'?'60':DN.Status__c;
                system.debug(loggingLevel.ERROR,'DN.InventoryManagementOnly__c:'+DN.InventoryManagementOnly__c+'  dn.InvoiceApproved__c:'+dn.InvoiceApproved__c);
                IF(DN.InventoryManagementOnly__c==false  && dn.InvoiceApproved__c==true && DN.Status__c!='60' && DN.TransactionType__c!='40' && DN.TransactionType__c!='10' ){   
                    setBillingLines(DN);
                    getPendingApprovalDiscount(DN);
                }
            }            
         
        }
    }
    
    public void sendDNToSap(){
        for(DeliveryNote__c DN: (List<DeliveryNote__c>)trigger.new){
            if( DN.InvoiceApproved__c==TRUE && DN.TransactionType__c!='10' && oldMapTrigger.get(DN.id)!=null && oldMapTrigger.get(DN.id).InvoiceApproved__c!=DN.InvoiceApproved__c && DN.Interface_Response__c ==NULL){
                system.debug(loggingLevel.ERROR, 'Create DNS');
                string JSON= DeliveryNote_SetJSONSapInvoice.buildJSON(DN);
                DeliveryNote_SetJSONSapInvoice.createNewDNSRecord(JSON,DN);
            }
        }
    }

    public  void replaceMainProductPricing(){
        for(DeliveryNote__c DN: (List<DeliveryNote__c>)trigger.new){
            DeliveryNote__c old=  oldMapTrigger!=null?oldMapTrigger.get(DN.Id):null;
            if(DN.ReplaceMainProduct__c!=old.ReplaceMainProduct__c){
                for(DeliveryNoteItems__c DNI:DNLineItemsMap.get(DN.Id)){
                    
                if(DNI.LineItemType__c=='1' && DNI.ReplaceMainProduct__c!=DN.ReplaceMainProduct__c){
                    system.debug(loggingLevel.ERROR, 'DNI.ReplaceMainProduct__c:'+DNI.ReplaceMainProduct__c+'  DN.ReplaceMainProduct__c:'+DN.ReplaceMainProduct__c);
                    
                    DNI.ReplaceMainProduct__c=DN.ReplaceMainProduct__c;
                        createNewDNI.add(DNI);
                    }
                }
            }
        }
    }
    
    public static decimal convertTon(Decimal TonQuantity,Decimal ProductSpecificGravity,string unitOfMeasure){
        ProductSpecificGravity= ProductSpecificGravity>0?ProductSpecificGravity:1;
        Decimal originalUnitOfMeasure = 0;
        SWITCH ON unitOfMeasure{
          
            WHEN 'LTR'{
                originalUnitOfMeasure=TonQuantity*1000/ProductSpecificGravity;
            }
            WHEN 'KG'{
                originalUnitOfMeasure=TonQuantity*1000;
            }
              WHEN 'M3'{
                originalUnitOfMeasure=TonQuantity/ProductSpecificGravity;
            }
            WHEN ELSE{
                originalUnitOfMeasure=TonQuantity;
            }
        }
        return originalUnitOfMeasure;
    }
}