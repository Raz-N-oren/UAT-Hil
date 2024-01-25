global class DeliveryNoteItem_UpsertLines {
   static  Map<string,DeliveryNoteItems__c>  returnDeliveryNoteItems = new  Map<string,DeliveryNoteItems__c> ();
 
    // create related delivery line items
    public static void createLineItems(DeliveryNote__c rec,OrderItem OIrec){
        List<DeliveryNoteItems__c> createLineItemsList = new List<DeliveryNoteItems__c>();
        System.debug(loggingLevel.ERROR,'DeliveryNoteItem_UpsertLines-->createLineItems func:'+OIrec);
        decimal totalTonWeight =0;
        decimal totalCubeWeight =0;
        decimal totalDiscount =0;
        decimal totalSumLine =0;
        
        if(rec.FKBillingCredit__c==null &&  OIrec!=null && (OIrec.TransactionType__c=='30'||OIrec.TransactionType__c=='10'||OIrec.TransactionType__c=='20'||OIrec.TransactionType__c=='60'||OIrec.TransactionType__c=='40'||OIrec.TransactionType__c=='80')){
            DeliveryNoteItems__c typeProduct  = setDNIRec(null,rec,OIrec.Product2Id,rec.DeliveryNoteLineId__c+'-'+OIrec.Product2Id,'1',OIrec,createLineItemsList);
            createLineItemsList.add(typeProduct);
            totalTonWeight	+= typeProduct.TotalWeight__c!=null?typeProduct.TotalWeight__c:0;
            totalCubeWeight	+= typeProduct.TotalWeight__c!=null?typeProduct.TotalCubeWeight__c:0;
            totalSumLine 	+=typeProduct.TotalPrice__c!=null && typeProduct.TotalWeight__c!=null? typeProduct.TotalPrice__c*typeProduct.TotalWeight__c:0;
            totalDiscount	+= typeProduct.LineDiscount__c!=null ?typeProduct.LineDiscount__c*typeProduct.TotalPrice__c*typeProduct.TotalWeight__c:0;
            if(OIrec.Extension_1__c!=null){
                string UniqueId = rec.DeliveryNoteLineId__c+'-'+OIrec.Extension_1__c;
                DeliveryNoteItems__c typeExt1  = setDNIRec(null,rec,OIrec.Extension_1__c,UniqueId,'2',OIrec,createLineItemsList);
                createLineItemsList.add(typeExt1);
                totalTonWeight 	+= typeExt1.TotalWeight__c!=null?typeExt1.TotalWeight__c:0;
                totalCubeWeight	+= typeExt1.TotalCubeWeight__c!=null?typeExt1.TotalCubeWeight__c:0;
                totalSumLine 	+=typeExt1.TotalPrice__c*typeExt1.TotalWeight__c;
                totalDiscount	+= typeExt1.LineDiscount__c!=null ?typeExt1.LineDiscount__c*typeExt1.TotalPrice__c*typeExt1.TotalWeight__c:0;
            }
            if(OIrec.Extension_2__c!=null){
                string UniqueId = rec.DeliveryNoteLineId__c+'-'+OIrec.Extension_2__c;
                DeliveryNoteItems__c typeExt2  = setDNIRec(null,rec,OIrec.Extension_2__c,UniqueId,'2',OIrec,createLineItemsList);
                createLineItemsList.add(typeExt2);
                totalTonWeight	+= typeExt2.TotalWeight__c!=null?typeExt2.TotalWeight__c:0;
                totalCubeWeight	+= typeExt2.TotalCubeWeight__c!=null?typeExt2.TotalCubeWeight__c:0;
                totalSumLine 	+= typeExt2.TotalPrice__c*typeExt2.TotalWeight__c;
                totalDiscount	+= typeExt2.LineDiscount__c!=null ?typeExt2.LineDiscount__c*typeExt2.TotalPrice__c*typeExt2.TotalWeight__c:0;
            }
            if(OIrec.Extension_3__c!=null){
                string UniqueId = rec.DeliveryNoteLineId__c+'-'+OIrec.Extension_3__c;
                DeliveryNoteItems__c typeExt3  = setDNIRec(null,rec,OIrec.Extension_3__c,UniqueId,'2',OIrec,createLineItemsList);
                createLineItemsList.add(typeExt3);
                totalTonWeight	+= typeExt3.TotalWeight__c!=null?typeExt3.TotalWeight__c:0;
                totalCubeWeight	+= typeExt3.TotalCubeWeight__c!=null?typeExt3.TotalCubeWeight__c:0;
                totalSumLine 	+= typeExt3.TotalPrice__c*typeExt3.TotalWeight__c;
                totalDiscount	+= typeExt3.LineDiscount__c!=null?typeExt3.LineDiscount__c*typeExt3.TotalPrice__c*typeExt3.TotalWeight__c:0;
            }
            if(OIrec.Order.Account.AccountDivision__c!='כימיקלים' && OIrec.Product2.InnerProcess__c==false && OIrec.TransportType__c!='Without'  && rec.TransactionType__c!='10' && OIrec.TransactionType__c!='80' && rec.TransactionType__c!='20'  && rec.TransactionType__c!='40'){
                string UniqueId = rec.DeliveryNoteLineId__c +'-3';
                DeliveryNoteItems__c typeDelivery  = setDNIRec(null,rec,null,UniqueId,'3',OIrec,createLineItemsList);
                createLineItemsList.add(typeDelivery);
            }
            if(totalDiscount>0 ){
                system.debug(loggingLevel.ERROR, 'totalDiscount:'+totalDiscount);
                string UniqueId = rec.DeliveryNoteLineId__c +'-8';
                DeliveryNoteItems__c typeDis  = setDNIRec(null,rec,null,UniqueId,'8',OIrec,createLineItemsList);
                typeDis.LineDiscount__c =totalDiscount/totalSumLine;
                system.debug(loggingLevel.ERROR, 'LineDiscount__c:'+typeDis.LineDiscount__c);
                createLineItemsList.add(typeDis);
            }
        }
        if(OIrec.TransactionType__c=='50'){
            System.debug(loggingLevel.ERROR,' FertJob:'+OIrec.Product2Id+'rec.DeliveryNoteLineId__c:'+rec.DeliveryNoteLineId__c+ ' OIrec.TransactionType__c:'+OIrec.TransactionType__c );
            DeliveryNoteItems__c FertJob;
            if(rec.InventoryManagementOnly__c==true ){ 
                FertJob  = setDNIRec(null,rec,OIrec.Product2Id,rec.DeliveryNoteLineId__c+'-Inventory-'+OIrec.Product2Id,'7',OIrec,createLineItemsList);
                system.debug(loggingLevel.ERROR, 'FertJob Inventory:'+FertJob);
                createLineItemsList.add(FertJob);
            }
            else{
                FertJob  = setDNIRec(null,rec,OIrec.Product2Id,rec.DeliveryNoteLineId__c+'-'+OIrec.Product2Id,'6',OIrec,createLineItemsList);
                createLineItemsList.add(FertJob);
                List<orderItem> relatedOIs = new List<orderItem>([SELECT Id,Product2Id,Extension_1__c,Extension_1__r.specific_gravity__c,Extension_1__r.IL_Group__c,
                                                                  Extension_Quantity_1__c,Extension_Unit_1__c,Extension_1__r.Product_hierarchy_Code__c,
                                                                  Extension_2__c,Extension_2__r.specific_gravity__c,Extension_Quantity_2__c,
                                                                  Extension_Unit_2__c,Extension_2__r.Product_hierarchy_Code__c,Extension_2__r.IL_Group__c,
                                                                  Extension_3__c,Extension_3__r.specific_gravity__c,Extension_Quantity_3__c,Product2.Sap_Number__c,
                                                                  Extension_1__r.Sap_Number__c,Extension_2__r.Sap_Number__c,Extension_3__r.Sap_Number__c,
                                                                  Extension_Unit_3__c,Extension_3__r.Product_hierarchy_Code__c,Extension_3__r.IL_Group__c,
                                                                  order.Account.Setelment__c,order.Account.Setelment__r.Geographic_Area__c,UnitOfMeasure__c,
                                                                  product2.Product_Hiarch_Type__c,product2.IL_Group__c,product2.specific_gravity__c,product2.Packing__c,
                                                                  product2.TonWeightCoefficient__c,order.Branch_growth__c,order.AgentReceivesCommission__c,
                                                                  product2.Product_hierarchy_Code__c,OrderId,TransactionType__c,order.createdDate,TransportType__c,
                                                                  TotalTonWeight__c,Quantity,Order.NonFreightCharge__c,order.Account.OwnerId,Product2.InnerProcess__c,
                                                                  order.Account.AccountDivision__c,order.Account.ParentId, Order.TransactionType__c,Order.Paying_Customer__c,
                                                                  RelatedOpportunityItem__c,RelatedOpportunityItem__r.Need_a_cart__c,RelatedOpportunityItem__r.Cost_level__c,
                                                                  RelatedOpportunityItem__r.Terms_of_Payment__c 
                                                                  FROM orderItem
                                                                  WHERE orderId =:rec.Order__c]);
                system.debug(loggingLevel.ERROR,'relatedOIs size():'+relatedOIs.size());
                
                for(orderItem recOI:relatedOIs){
                    if(OIrec.Id!=recOI.Id){
                        string UniqueId = rec.DeliveryNoteLineId__c+'-'+recOI.Id;
                        DeliveryNoteItems__c typeExt7  = setDNIRec(null,rec,recOI.product2Id,UniqueId,'7',recOI,createLineItemsList);
                        createLineItemsList.add(typeExt7);
                    }
                }
            }
            System.debug(loggingLevel.ERROR,' createLineItemsList 1 size:'+createLineItemsList.size());
        }        
        upsertDeliveryNote(createLineItemsList);
    }
    
    public static DeliveryNoteItems__c setDNIRec(DeliveryNoteItems__c DNI,DeliveryNote__c rec,string prdId,string UniqueId,string DNIType,OrderItem OIrec,List<DeliveryNoteItems__c> createLineItemsList){
        DeliveryNoteItems__c newRec = DNI==null?new DeliveryNoteItems__c():DNI;
        newRec.DeliveryNote__c			= rec.Id;
        newRec.LineItemType__c			= DNIType;
        newRec.Order__c					= rec.Order__c;
        newRec.orderItem__c				= rec.OrderItem__c;  
        newRec.UniqueId__c				= UniqueId;
        if(DNIType!='3' && DNIType!='4' && prdId!=null){
            newRec.Product__c				= prdId;
            newRec.ProductSapNumber__c		= OIrec.Product2.Sap_Number__c;
            calcQuantityFromTotal(newRec,rec, newRec.Product__c,OIrec,createLineItemsList);
            if(rec.TransactionType__c!='10' && rec.TransactionType__c!='80' && rec.TransactionType__c!='50' && rec.TransactionType__c!='40'){
                Discount__c relatedDiscount		= getProductDiscount.getDiscountRec(prdId,rec.Account__c, null,null);
                system.debug(loggingLevel.error,'foundDiscount:'+relatedDiscount);
                newRec.FK_ProductDiscount__c	= relatedDiscount!=null?relatedDiscount.Id:null;
                newRec.LineDiscount__c			= relatedDiscount!=null ?relatedDiscount.Requested_Discount__c:null;
            }
        }
        return newRec;
    }
    
    private static void calcQuantityFromTotal(DeliveryNoteItems__c newRec,DeliveryNote__c DN,Id prd,orderItem oi,List<DeliveryNoteItems__c> createLineItemsList){
        decimal QuantityFromTotal		= 0;
        decimal prdTonWeightFromTotal 	= 0;
        decimal specific_gravity 		= 0;
        decimal coefficiantTonWeight 	= 0;
        decimal quantity 				= DN.DischargeQuantity__c>0?DN.DischargeQuantity__c:DN.LoadingQuantity__c;
        string uom						= DN.Dischargequantityuom__c!=null?DN.Dischargequantityuom__c: DN.UnitOfMeasure__c;
        if(prd!=null && (oi.TransactionType__c=='30'||oi.TransactionType__c=='20'||oi.TransactionType__c=='10'||oi.TransactionType__c=='60'||oi.TransactionType__c=='40'||oi.TransactionType__c=='80')){
            if(prd==oi.Product2Id){                
                QuantityFromTotal			= oi.Quantity!=null?(orderItem_CalculateInfo.calculateTotalTonWeight(oi.Quantity,oi.UnitOfMeasure__c,oi.product2.specific_gravity__c,null)/oi.TotalTonWeight__c*100).setScale(2):null;
                specific_gravity 			= oi.product2.specific_gravity__c;
                coefficiantTonWeight		= oi.product2.TonWeightCoefficient__c;
            }
            else{
                if(prd==oi.Extension_1__c && oi.Extension_Quantity_1__c>0){
                    QuantityFromTotal	= (orderItem_CalculateInfo.calculateTotalTonWeight(oi.Extension_Quantity_1__c,oi.Extension_Unit_1__c,oi.Extension_1__r.specific_gravity__c,null)/oi.TotalTonWeight__c*100).setScale(2);
                    specific_gravity 	= oi.Extension_1__r.specific_gravity__c;
                    coefficiantTonWeight= oi.Extension_1__r.TonWeightCoefficient__c;
                }
                else if(prd==oi.Extension_2__c && oi.Extension_Quantity_2__c>0){
                    QuantityFromTotal	= (orderItem_CalculateInfo.calculateTotalTonWeight(oi.Extension_Quantity_2__c,oi.Extension_Unit_2__c,oi.Extension_2__r.specific_gravity__c,null)/oi.TotalTonWeight__c*100).setScale(2);
                    specific_gravity 	= oi.Extension_2__r.specific_gravity__c;
                    coefficiantTonWeight= oi.Extension_2__r.TonWeightCoefficient__c;
                }
                else if(prd==oi.Extension_3__c && oi.Extension_Quantity_3__c>0){
                    QuantityFromTotal	= (orderItem_CalculateInfo.calculateTotalTonWeight(oi.Extension_Quantity_3__c,oi.Extension_Unit_3__c,oi.Extension_3__r.specific_gravity__c,null)/oi.TotalTonWeight__c*100).setScale(2);
                    specific_gravity = oi.Extension_3__r.specific_gravity__c; 
                    coefficiantTonWeight= oi.Extension_3__r.TonWeightCoefficient__c;
                }
            }
            system.debug(loggingLevel.ERROR, 'setDNIRec QuantityFromTotal:'+QuantityFromTotal);
            setCalcValues(DN,newRec,oi, QuantityFromTotal,quantity,uom,specific_gravity,coefficiantTonWeight, createLineItemsList);  
        }
        if(prd!=null && oi.TransactionType__c=='50'){
            QuantityFromTotal=100;
            prdTonWeightFromTotal=newRec.LineItemType__c=='6'?DN.DischargeWeightInTon__c:priceCalculationInfo.convertAmountToUnitOfMeasure('TO',oi.UnitOfMeasure__c,oi.Quantity,oi.product2.specific_gravity__c,coefficiantTonWeight);
            setCalcValues(DN,newRec,oi, QuantityFromTotal,oi.Quantity,oi.UnitOfMeasure__c,oi.product2.specific_gravity__c,coefficiantTonWeight,createLineItemsList);
        }
    }
    
 
    
    private static void setCalcValues(DeliveryNote__c DN,DeliveryNoteItems__c rec,orderItem oi,Decimal QuantityFromTotal,Decimal DischargeQuantity,string UnitOfMeasure,Decimal specific_gravity, Decimal TonWeightCoefficient,List<DeliveryNoteItems__c> createLineItemsList){
        if(DischargeQuantity!=null && DischargeQuantity!=0 && rec.Product__c!=null && dn.TransactionType__c!='40'){
            Map<string,IL_Price_Book__c> getPBInfo= new Map<string,IL_Price_Book__c>();
            getPBInfo 					= priceCalculationInfo.setPriceAndPBRec(rec,rec.Product__c, DN.Account__c,DN.Account__r.AccountDivision__c,DN.Dischargequantityuom__c ,rec.TotalWeight__c,DN.LoadingPoint__c, DN.OrderItem__r.TransportType__c, rec.ProductILGroup__c,DN.PricingDate__c);
            string targetUOM			= getPBInfo.get(rec.UniqueId__c)!=null && getPBInfo.get(rec.UniqueId__c).Unit_Of_Meager__c!=null?getPBInfo.get(rec.UniqueId__c).Unit_Of_Meager__c :UnitOfMeasure;
            system.debug(loggingLevel.ERROR, 'setCalcValues QuantityFromTotal:targetUOM:'+targetUOM+'->UnitOfMeasure:'+UnitOfMeasure+'->QuantityFromTotal:'+QuantityFromTotal+'-->DischargeQuantity:'+DischargeQuantity);
            rec.ProductQuantityFromTotal__c	= QuantityFromTotal;
            if(targetUOM=='TO'&& DN.DischargeWeightInTon__c>0){
                rec.DischargeQuantity__c		= QuantityFromTotal!=null? QuantityFromTotal*DN.DischargeWeightInTon__c/100:0; 
            }
            else{
                rec.DischargeQuantity__c		= QuantityFromTotal!=null? QuantityFromTotal * priceCalculationInfo.convertAmountToUnitOfMeasure(targetUOM,UnitOfMeasure,DischargeQuantity,specific_gravity,TonWeightCoefficient)/100:1;    
            }
          
            system.debug(logginglevel.ERROR,' rec.DischargeQuantity__c:'+ rec.DischargeQuantity__c);
            if(rec.LineItemType__c!='6'&& rec.LineItemType__c!='7'){
                rec.TotalWeight__c				= rec.DischargeQuantity__c!=null?rec.DischargeQuantity__c:0;
                rec.TotalCubeWeight__c			= rec.TotalWeight__c!=null? priceCalculationInfo.convertAmountToUnitOfMeasure('M3',targetUOM,rec.TotalWeight__c,specific_gravity,TonWeightCoefficient):0;
                System.debug(loggingLevel.ERROR,'DNI TotalTonWeight__c:'+rec.TotalWeight__c+'---DischargeQuantity__c:'+rec.DischargeQuantity__c);
                if(rec.Product__c!=null && DN!=null && DN.InventoryManagementOnly__c==false && DN.FKBillingCredit__c==null && DN.TransactionType__c!='10'){
                    rec.RelatedPriceBook__c 	= getPBInfo.get(rec.UniqueId__c)!=null?getPBInfo.get(rec.UniqueId__c).Id:null; 
                    /*calc pricebook info*/
                    if(rec.LineItemType__c!='6'&& rec.LineItemType__c!='7' && getPBInfo.get(rec.UniqueId__c)!=null){
                        decimal priceamount 	= priceCalculationInfo.calculateUnitPrice(getPBInfo.get(rec.UniqueId__c)); 
                        rec.CurrencyIsoCode  	= getPBInfo.get(rec.UniqueId__c).Foreign_currency_invoice__c==true?getPBInfo.get(rec.UniqueId__c).CurrencyIsoCode:'ILS';//relevant to Sap
                        if(targetUOM=='TO' && UnitOfMeasure=='EA' && oi.TransactionType__c!='50'){
                            rec.TotalWeight__c		= Dn.DischargeQuantity__c;
                            rec.TotalPrice__c  		= priceamount!=null?((DN.DischargeWeightInTon__c/DN.DischargeQuantity__c)*priceamount).setScale(3):0.00;
                            rec.TotalCubeWeight__c	= 0;
                            rec.TotalPriceInCube__c	= 0;
                            if(rec.LineItemType__c=='1' && oi.product2.Packing__c!=null){
                                List<Packing__c > relatedPackingPrice = new  List<Packing__c>([SELECT Id,PackingPrice__c FROM Packing__c WHERE Id=: oi.product2.Packing__c AND Active__c=true]);
                                
                                system.debug(loggingLevel.ERROR, 'relatedPackingPrice:'+relatedPackingPrice);
                                rec.ProductPacking__c	=relatedPackingPrice[0]!=null?relatedPackingPrice[0].Id:null;
                                if(relatedPackingPrice[0]!=null && relatedPackingPrice[0].PackingPrice__c>0 && rec.TotalPrice__c>0){
                                  rec.TotalPrice__c = rec.TotalPrice__c +relatedPackingPrice[0].PackingPrice__c;
                                }
                                  
                            }
                        }
                        else{ 
                            rec.TotalPrice__c = priceamount!=null?priceamount.setScale(3):0.00;
                            rec.TotalPriceInCube__c	= rec.TotalPrice__c>0?priceCalculationInfo.convertAmountToUnitOfMeasure(targetUOM,'M3',priceamount,specific_gravity,TonWeightCoefficient):0;
                        }
                        
                        system.debug(loggingLevel.ERROR,'priceCalculationInfo-->setPriceAndPBRec:CurrencyIsoCode-'+rec.CurrencyIsoCode+'-TotalPrice__c-'+rec.TotalPrice__c+'-TotalPriceInCube__c-'+rec.TotalPriceInCube__c);
                        //create Chemical transport if needed
                        system.debug(loggingLevel.ERROR,'AccountDivision__c:'+DN.Account__r.AccountDivision__c+'-->ChemicalTransportPrice__c:'+getPBInfo.get(rec.UniqueId__c).ChemicalTransportPrice__c);
                        if(getPBInfo.get(rec.UniqueId__c)!=null && DN.Account__r.AccountDivision__c=='כימיקלים' && getPBInfo.get(rec.UniqueId__c).ChemicalTransportPrice__c>0 && oi.TransportType__c!='Without' ){
                            string UniqueId = DN.DeliveryNoteLineId__c +'-3';
                            createChemicalTransportDNI( DN, getPBInfo.get(rec.UniqueId__c),UniqueId,rec, createLineItemsList);
                        }
                        if(getPBInfo.get(rec.UniqueId__c)!=null && getPBInfo.get(rec.UniqueId__c).FillingFees__c>0){//דמי מילוי
                            string UniqueId = DN.DeliveryNoteLineId__c +'-9';
                            createFeelingFeesDNI(DN, getPBInfo.get(rec.UniqueId__c),UniqueId,rec, createLineItemsList);
                        }
                    }  
                }                
            }
            else{
                rec.TotalWeight__c				= rec.LineItemType__c=='6' && rec.DischargeQuantity__c!=null?rec.DischargeQuantity__c:priceCalculationInfo.convertAmountToUnitOfMeasure('TO',oi.UnitOfMeasure__c,oi.Quantity,specific_gravity,TonWeightCoefficient);
            }
        }
        else if(DN.TransactionType__c=='40'){
            if(returnDeliveryNoteItems.isEmpty()){
                returnDeliveryNoteItems=getReturnDeliveryNoteItems(DN);
                system.debug(logginglevel.error,'returnDeliveryNoteItems:'+returnDeliveryNoteItems);
            }
            
            if(returnDeliveryNoteItems.get(rec.LineItemType__c)!=null ||(rec.LineItemType__c!='1' && returnDeliveryNoteItems.get(rec.LineItemType__c+'-'+rec.Product__c)!=null)){
                system.debug(loggingLevel.error,'setCalcValues for return delivery note');
                DeliveryNoteItems__c relatedDNI = returnDeliveryNoteItems.get(rec.LineItemType__c)!=null?returnDeliveryNoteItems.get(rec.LineItemType__c):returnDeliveryNoteItems.get(rec.LineItemType__c+'-'+rec.Product__c);
                rec.DischargeQuantity__c	=	rec.DischargeQuantity__c;
                rec.DeliveryCost__c     	= 	relatedDNI.DeliveryCost__c;
                rec.RelatedPacking__c   	=	relatedDNI.RelatedPacking__c;
                rec.ProductPacking__c   	=	relatedDNI.ProductPacking__c;
                rec.RelatedPriceBook__c 	=	relatedDNI.RelatedPriceBook__c;
                rec.CurrencyIsoCode     	=	relatedDNI.CurrencyIsoCode;
                rec.TotalPrice__c       	=	relatedDNI.TotalPrice__c;
                rec.FK_ProductDiscount__c	=	relatedDNI.FK_ProductDiscount__c;
                rec.LineDiscount__c			= 	relatedDNI.LineDiscount__c;
                rec.TotalWeight__c			=  rec.DischargeQuantity__c!=null?QuantityFromTotal * priceCalculationInfo.convertAmountToUnitOfMeasure(relatedDNI.UnitOfMeasure__c,UnitOfMeasure,DischargeQuantity,specific_gravity,TonWeightCoefficient)/100:1;
                rec.TotalCubeWeight__c		= rec.TotalWeight__c!=null? priceCalculationInfo.convertAmountToUnitOfMeasure('M3',relatedDNI.UnitOfMeasure__c,rec.TotalWeight__c,specific_gravity,TonWeightCoefficient):0;
             }
        }
    }
    
    private static Map<string,DeliveryNoteItems__c> getReturnDeliveryNoteItems(DeliveryNote__c DN){
        Map<string,DeliveryNoteItems__c>  relatedItems = new  Map<string,DeliveryNoteItems__c>();
        List<DeliveryNoteItems__c> relatedDNI = new  List<DeliveryNoteItems__c>([SELECT Id,LineItemType__c,DischargeQuantity__c,DeliveryCost__c,DiscountAmount__c,
                                                                                 RelatedPacking__c,ProductPacking__c,RelatedPriceBook__c,CurrencyIsoCode,Product__c,
                                                                                 TotalCubeWeight__c,LinePrice__c,TotalPrice__c,TotalWeight__c,UnitOfMeasure__c,
                                                                                 FK_ProductDiscount__c,LineDiscount__c
                                                                                 FROM DeliveryNoteItems__c WHERE DeliveryNote__c=:DN.RelatedDeliveryNote__c]);
        for(DeliveryNoteItems__c DNI:relatedDNI){
            
            Map<string,DeliveryNoteItems__c> DNIMap = new  Map<string,DeliveryNoteItems__c>();
            relatedItems.put((DNI.LineItemType__c!='1'?DNI.LineItemType__c+'-'+DNI.Product__c:DNI.LineItemType__c),DNI);
        }
        return relatedItems;
    }    
    
    private static void createFeelingFeesDNI(DeliveryNote__c DN,IL_Price_Book__c PBInfo,string UniqueId,DeliveryNoteItems__c rec,List<DeliveryNoteItems__c> createLineItemsList){
        DeliveryNoteItems__c newRec = new DeliveryNoteItems__c();
        newRec.DeliveryNote__c			= DN.Id;
        newRec.LineItemType__c			= '9';
        newRec.Order__c					= DN.Order__c;
        newRec.orderItem__c				= DN.OrderItem__c;  
        newRec.UniqueId__c				= UniqueId;
        newRec.TotalPrice__c			= PBInfo.FillingFees__c+PBInfo.Packing_Price__c;
        createLineItemsList.add(newRec);
    }
    
    private  static void createChemicalTransportDNI(DeliveryNote__c DN,IL_Price_Book__c PBInfo,string UniqueId,DeliveryNoteItems__c rec,List<DeliveryNoteItems__c> createLineItemsList){
        DeliveryNoteItems__c newRec = new DeliveryNoteItems__c();
        newRec.DeliveryNote__c			= DN.Id;
        newRec.LineItemType__c			= '3';
        newRec.Order__c					= DN.Order__c;
        newRec.orderItem__c				= DN.OrderItem__c;  
        newRec.UniqueId__c				= UniqueId;
        newRec.DeliveryCost__c			= PBInfo.ChemicalTransportPrice__c;
        createLineItemsList.add(newRec);
        
    }
    
    public static void upsertDeliveryNote(List<DeliveryNoteItems__c> createLineItemsList){
        if(!createLineItemsList.isEmpty()){
            System.debug(loggingLevel.ERROR,'createLineItemsList 2 size:'+createLineItemsList.size());
            Database.UpsertResult[] results = Database.upsert(createLineItemsList, DeliveryNoteItems__c.UniqueId__c);
            for(Integer index = 0, size = results.size(); index < size; index++){
                if(results[index].isSuccess()) {
                    System.debug(createLineItemsList[index].UniqueId__c +'createLineItemsList - Was Upserted Successfully');
                } else{
                    Database.Error err = results.get(index).getErrors().get(0);                    
                    System.debug('Error createLineItemsList -- '+err.getMessage() + '\nStatus Code : '+err.getStatusCode()+'\n Fields : '+err.getFields());
                }
            }
        }
    }
}