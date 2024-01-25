public class orderItem_CalculateInfo {
    List<Id> productsId = new List<Id>();
    List<Id> orderIds = new List<Id>();
    Map<Id, Product2> productsMap = new Map<Id, Product2>();
    Map<Id, Order> ordersMap = new Map<Id, Order>();
    MAP<Id,orderItem> oldMap= new MAP<Id,orderItem>();
    List<Order> orderToUpdate= new List<Order>();
    static List<Order> updateOrders = new List<Order>();

    public orderItem_CalculateInfo(System.TriggerOperation operation){
        oldMap=(MAP<Id,orderItem>)trigger.OldMap;
        try{
            SWITCH ON operation{
                WHEN BEFORE_UPDATE,BEFORE_INSERT{
                    getProductInfo();
                    convertToTon();
                }
                WHEN AFTER_UPDATE{
                    updateOrders();
                }
            }

        
        }
        catch(DMLException e){
            system.debug(logginglevel.ERROR, 'orderItem Error:'+e);
            
        }
    }
    
    private void getProductInfo(){
        for(orderItem rec:(List<orderItem>)trigger.New){
              system.debug(loggingLevel.ERROR, 'order Item info:'+rec);
            orderItem oldRec = oldMap!=null && !oldMap.isEmpty()? oldMap.get(rec.Id):null;
          if(oldRec==null|| rec.InCorrectPricing__c==true || oldRec.Product2Id!=rec.Product2Id || oldRec.Price_from_customer_order__c!=rec.Price_from_customer_order__c
            || oldRec.UnitOfMeasure__c!=rec.UnitOfMeasure__c|| oldRec.Quantity!=rec.Quantity){
                   productsId.add(rec.Product2Id);
                   orderIds.add(rec.OrderId);
                   if(rec.Extension_1__c!=null)
                       productsId.add(rec.Extension_1__c); 
                   if(rec.Extension_2__c!=null)
                       productsId.add(rec.Extension_2__c);
                   if(rec.Extension_3__c!=null)
                       productsId.add(rec.Extension_3__c); 
             }
        }
        
        if(!productsId.isEmpty())
                    system.debug(loggingLevel.ERROR, 'productsId:'+productsId);

        productsMap = new Map<Id, Product2>([SELECT Id,Name, K__c, N__c, P__c, B__c, Ca__c, CL__c, CO__c, Fe__c, IS__c, Mg__c, Mn__c, PH__c, ZN__c,Green__c,
                                             IsActive, External_Id__c, Packing__c, Permit__c, Family,Product_hierarchy__c,Product_Hiarch_Type__c,
                                             TonWeightCoefficient__c,IL_Group__c,Product_hierarchy__r.External_ID__c, QuantityUnitOfMeasure, 
                                             specific_gravity__c,Product_hierarchy_Code__c,Crystallization_temperature__c
                                             FROM Product2 WHERE Id IN:productsId]); 
        system.debug(loggingLevel.ERROR, 'productsMap:'+productsMap);
    }
    
    private void convertToTon(){
        for(orderItem rec:(List<orderItem>)trigger.New){
            try{
              
                orderItem oldRec = oldMap!=null && !oldMap.isEmpty()? oldMap.get(rec.Id):null;
                product2 prdInfo=productsMap.get(rec.Product2Id);
                product2 ext1Info=productsMap.get(rec.Extension_1__c);
                product2 ext2Info=productsMap.get(rec.Extension_2__c);
                product2 ext3Info=productsMap.get(rec.Extension_3__c);
                
            if( oldRec==null || oldRec.Product2Id!=rec.Product2Id || rec.InCorrectPricing__c==true
                 || oldRec.Quantity!=rec.Quantity|| oldRec.Price_from_customer_order__c!=rec.Price_from_customer_order__c|| oldrec.UnitOfMeasure__c!=rec.UnitOfMeasure__c){
                       
                       rec.TotalTonWeight__c=calculateTotalTonWeight(rec.Quantity ,rec.UnitOfMeasure__c,prdInfo.specific_gravity__c!=null?prdInfo.specific_gravity__c:0,prdInfo.TonWeightCoefficient__c!=null?prdInfo.TonWeightCoefficient__c:0);
                       rec.TotalQuantityInCubic__c=calculateTotalCubeWeight(rec.Quantity ,rec.UnitOfMeasure__c,prdInfo.specific_gravity__c!=null?prdInfo.specific_gravity__c:0,prdInfo.TonWeightCoefficient__c!=null?prdInfo.TonWeightCoefficient__c:0 );
                       
                       if(rec.Extension_1__c!=null && rec.Extension_Quantity_1__c!=null && rec.Extension_Quantity_1__c>0.00){
                           rec.TotalTonWeight__c+=calculateTotalTonWeight(rec.Extension_Quantity_1__c ,rec.Extension_Unit_1__c,ext1Info.specific_gravity__c!=null?ext1Info.specific_gravity__c:0,ext1Info.TonWeightCoefficient__c!=null?ext1Info.TonWeightCoefficient__c:0);
                           rec.TotalQuantityInCubic__c+=calculateTotalCubeWeight(rec.Extension_Quantity_1__c ,rec.Extension_Unit_1__c,ext1Info.specific_gravity__c!=null?ext1Info.specific_gravity__c:0,ext1Info.TonWeightCoefficient__c!=null?ext1Info.TonWeightCoefficient__c:0);
                       }
                       if(rec.Extension_2__c!=null && rec.Extension_Quantity_2__c!=null && rec.Extension_Quantity_2__c>0.00){
                           rec.TotalTonWeight__c+=calculateTotalTonWeight(rec.Extension_Quantity_2__c ,rec.Extension_Unit_2__c,ext2Info.specific_gravity__c!=null?ext2Info.specific_gravity__c:0,ext2Info.TonWeightCoefficient__c!=null?ext2Info.TonWeightCoefficient__c:0);
                           rec.TotalQuantityInCubic__c+=calculateTotalCubeWeight(rec.Extension_Quantity_2__c ,rec.Extension_Unit_2__c,ext2Info.specific_gravity__c!=null?ext2Info.specific_gravity__c:0,ext2Info.TonWeightCoefficient__c!=null?ext2Info.TonWeightCoefficient__c:0);
                       }
                       if(rec.Extension_3__c!=null && rec.Extension_Quantity_3__c!=null && rec.Extension_Quantity_3__c>0.00){
                           rec.TotalTonWeight__c+=calculateTotalTonWeight(rec.Extension_Quantity_3__c ,rec.Extension_Unit_3__c,ext3Info.specific_gravity__c!=null?ext3Info.specific_gravity__c:0,ext3Info.TonWeightCoefficient__c!=null?ext3Info.TonWeightCoefficient__c:0);
                           rec.TotalQuantityInCubic__c+=calculateTotalCubeWeight(rec.Extension_Quantity_3__c ,rec.Extension_Unit_3__c,ext3Info.specific_gravity__c!=null?ext3Info.specific_gravity__c:0,ext3Info.TonWeightCoefficient__c!=null?ext3Info.TonWeightCoefficient__c:0);
                       }
                       
                      checkPricing(rec,oldRec);                       
                  }
            }
            catch(exception e){
               rec.addError('OrderItem error:'+e.getMessage()+String.valueOf(e.getLineNumber()));
                System.debug(LoggingLevel.ERROR,'ERROR  at line ' + String.valueOf(e.getLineNumber())); 
                System.debug(LoggingLevel.ERROR,'order Item Error:'+ + e.getMessage()+ e.getStackTraceString()); 

              

                
            }
        }
    }
    
    public static Decimal calculateTotalCubeWeight(Decimal Quantity,string UnitOfMeasure,Decimal gravity,Decimal productWeight){
        system.debug('calculateTotalCubeWeight -gravity:'+gravity +'--Quantity:'+Quantity+'--UnitOfMeasure:'+UnitOfMeasure+'--productWeight:'+productWeight );
        productWeight=productWeight!=null && productWeight>0?productWeight:1.00;
        gravity=gravity!=null && gravity>1.00?gravity:1.00;
        Decimal calc=0.00;
        SWITCH ON UnitOfMeasure{
            WHEN 'M3'{
                calc=Quantity.setScale(3);
            }
            WHEN 'LTR'{
                calc=Quantity.divide(1000, 3);
            }
            WHEN 'KG'{
                calc=(Quantity / gravity).divide(1000, 3);
            }
            WHEN 'TO'{
                calc=(Quantity / gravity).setScale(3);
            }
            WHEN 'EA'{
                calc= (Quantity*gravity/productWeight).setScale(3);
            }
        }
        return calc;
    }  

    public static Decimal calculateTotalKGWeight(Decimal Quantity,string UnitOfMeasure,Decimal gravity,Decimal productWeight){
        system.debug('calculateTotalKGWeight -gravity:'+gravity +'--Quantity:'+Quantity+'--UnitOfMeasure:'+UnitOfMeasure+'--productWeight:'+productWeight );
        productWeight=productWeight!=null && productWeight>0?productWeight:1.00;
        gravity=gravity!=null && gravity>1.00?gravity:1.00;
        Decimal calc=0.00;
        SWITCH ON UnitOfMeasure{
            WHEN 'M3'{
                calc=(Quantity * gravity * 1000).setScale(3);
            }
            WHEN 'LTR'{
                calc=(Quantity * gravity ).setScale(3);        
            }
            WHEN 'KG'{
                
                calc=Quantity.setScale(3);
            }
            WHEN 'TO'{
                calc=(Quantity * gravity * 1000).setScale(3);
            }
            WHEN 'EA'{
                calc= (Quantity * gravity / productWeight).setScale(3);
            }
        }
        return calc;
    }  
    
    public static Decimal calculateTotalLTRWeight(Decimal Quantity,string UnitOfMeasure,Decimal gravity,Decimal productWeight){
        system.debug('calculateTotalLTRWeight -gravity:'+gravity +'--Quantity:'+Quantity+'--UnitOfMeasure:'+UnitOfMeasure+'--productWeight:'+productWeight );
        productWeight=productWeight!=null && productWeight>0?productWeight:1.00;
        gravity=gravity!=null && gravity>1.00?gravity:1.00;
        Decimal calc=0.00;
        SWITCH ON UnitOfMeasure{
            WHEN 'M3'{
                calc=(Quantity * 1000).setScale(3);
            }
            WHEN 'LTR'{
                calc=Quantity.setScale(3);
            }
            WHEN 'KG'{
                calc=(Quantity / gravity).setScale(3);
            }
            WHEN 'TO'{
                calc=(Quantity * gravity * 1000).setScale(3);
            }
            WHEN 'EA'{
                calc= (Quantity*gravity/productWeight).setScale(3);
            }
        }
        return calc;
    }  

    public static Decimal calculateTotalEachWeight(Decimal Quantity,string UnitOfMeasure,Decimal gravity,Decimal productWeight){
        system.debug('calculateTotalEachWeight -gravity:'+gravity +'--Quantity:'+Quantity+'--UnitOfMeasure:'+UnitOfMeasure+'--productWeight:'+productWeight );
        productWeight=productWeight!=null && productWeight>0?productWeight:1.00;
        gravity=gravity!=null && gravity>1.00?gravity:1.00;
        Decimal calc=0.00;
        SWITCH ON UnitOfMeasure{
            WHEN 'M3'{
                calc=(Quantity/gravity*productWeight).setScale(3);
            }
            WHEN 'LTR'{
                calc=(Quantity/gravity*productWeight).divide(1000, 3);
            }
            WHEN 'KG'{
                calc=(Quantity*productWeight).divide(1000, 3);
            }
            WHEN 'TO'{
                calc=(Quantity * productWeight).setScale(3);
            }
            WHEN 'EA'{
                calc= Quantity.setScale(3);
            }
        }
        return calc;
    }  
    
    @auraEnabled
    public static Decimal calculateTotalTonWeight(Decimal Quantity,string UnitOfMeasure,Decimal gravity,Decimal productWeight){
        productWeight=productWeight!=null && productWeight>0.00 && productWeight>0?productWeight:1.00;
        gravity=gravity!=null && gravity>1.00?gravity:1.00;
        system.debug('calculateTotalTonWeight -gravity:'+gravity +'--Quantity:'+Quantity+'--UnitOfMeasure:'+UnitOfMeasure+'--productWeight:'+productWeight );
         Decimal calc=0.00;
       
        SWITCH ON UnitOfMeasure{
            WHEN 'M3'{
                calc=(Quantity * gravity).setScale(3);
            }
            WHEN 'LTR'{
                calc=(Quantity * gravity).divide(1000, 3);
            }
            WHEN 'KG'{
                calc=Quantity.divide(1000, 3);
            }
            WHEN 'TO'{
                calc=Quantity.setScale(3);
            }
            WHEN 'EA'{
                calc=(Quantity/productWeight).setScale(3);
            }
        }
         system.debug(loggingLevel.ERROR,'sum ton calc:'+calc);

        return calc;
    }  
 
    public  void checkPricing(orderItem rec,orderItem oldRec){
        if(oldRec==null|| rec.InCorrectPricing__c==true || oldRec.Product2Id!=rec.Product2Id || oldRec.Price_from_customer_order__c!=rec.Price_from_customer_order__c
           || oldRec.UnitOfMeasure__c!=rec.UnitOfMeasure__c|| oldRec.Quantity!=rec.Quantity){
               getRelatedOrderData();
               rec.OrderAccount__c = rec.OrderAccount__c==null && ordersMap.get(rec.OrderId)!=null?ordersMap.get(rec.OrderId).AccountId:rec.OrderAccount__c;
               IL_Price_Book__c relatedPB 	= new IL_Price_Book__c();
               IL_Price_Book__c ext1PB		= new IL_Price_Book__c();
               IL_Price_Book__c ext2PB		= new IL_Price_Book__c();
               IL_Price_Book__c ext3PB		= new IL_Price_Book__c();
               decimal convertedQuantity =0;
               decimal convertedPrice=0;
               product2 prdInfo=productsMap.get(rec.Product2Id);
               product2 ext1Info=productsMap.get(rec.Extension_1__c);
               product2 ext2Info=productsMap.get(rec.Extension_2__c);
               product2 ext3Info=productsMap.get(rec.Extension_3__c);
               
               /* Get related IL priceBooks*/
               relatedPB=priceCalculationInfo.getPBRecord(rec.Product2Id, ordersMap.get(rec.OrderId).AccountId, rec.AccountDivision__c,rec.UnitOfMeasure__c,rec.quantity,rec.LoadingPoint__c, rec.TransportType__c,productsMap.get(rec.Product2Id).IL_Group__c , system.today());
               ext1PB=ext1Info!=null? priceCalculationInfo.getPBRecord(rec.Extension_1__c, ordersMap.get(rec.OrderId).AccountId, rec.AccountDivision__c,
                                                                       rec.UnitOfMeasure__c,rec.quantity,rec.LoadingPoint__c, rec.TransportType__c,
                                                                       ext1Info.IL_Group__c!=null?ext1Info.IL_Group__c:null ,
                                                                       system.today()):null;
               
               ext2PB= ext2Info!=NULL? priceCalculationInfo.getPBRecord(rec.Extension_2__c, ordersMap.get(rec.OrderId).AccountId, rec.AccountDivision__c,
                                                                        rec.UnitOfMeasure__c,rec.quantity,rec.LoadingPoint__c, rec.TransportType__c,
                                                                        ext2Info.IL_Group__c!=null?ext2Info.IL_Group__c:null , 
                                                                        system.today()):null;
               ext3PB=ext3Info!=null? priceCalculationInfo.getPBRecord(rec.Extension_3__c, ordersMap.get(rec.OrderId).AccountId, rec.AccountDivision__c,
                                                                       rec.UnitOfMeasure__c,rec.quantity,rec.LoadingPoint__c, rec.TransportType__c,
                                                                       ext3Info.IL_Group__c!=null?ext3Info.IL_Group__c:null , 
                                                                       system.today()):null;
               
               
               if(relatedPB!=NULL ){
                   relatedPB.Product_Service__r = prdInfo;
                   rec.ProductPriceBook__c= relatedPB.Id;
                   system.debug(LOGGINGLEVEL.ERROR,'rec.ProductPriceBook__c:'+rec.ProductPriceBook__c);
                   if(ext1PB!=null){
                        ext1PB.Product_Service__r = ext1Info;
                       rec.EXT1PriceBook__c =ext1PB!=null?ext1PB.id:null;
                       system.debug(LOGGINGLEVEL.ERROR,'ext1PB:'+ext1PB);}
                   if(ext2PB!=null){
                       ext2PB.Product_Service__r = ext2Info;
                       rec.EXT2PriceBook__c =ext2PB!=null?ext2PB.id:null;
                       system.debug(LOGGINGLEVEL.ERROR,'ext2PB:'+ext2PB);}
                   if(ext3PB!=null){
                       ext3PB.Product_Service__r = ext3Info;
                       rec.EXT3PriceBook__c =ext3PB!=null?ext3PB.id:null;
                       system.debug(LOGGINGLEVEL.ERROR,'ext3PB:'+ext3PB);
                    }
                   
                
                   decimal prodPrice  =  convertamount( 'TO',rec.UnitOfMeasure__c,rec.Quantity, prdInfo)*priceCalculationInfo.calculateUnitPrice(relatedPB);
                   decimal ext1Price =  (ext1PB!=null && rec.Extension_1__c!=null?convertamount( 'TO',rec.Extension_Unit_1__c,rec.Extension_Quantity_1__c,ext1Info)*priceCalculationInfo.calculateUnitPrice(ext1PB):0);
                   decimal ext2Price = (ext2PB!=null && rec.Extension_2__c!=null?convertamount('TO',rec.Extension_Unit_2__c,rec.Extension_Quantity_2__c,ext2Info)*priceCalculationInfo.calculateUnitPrice(ext2PB):0);
                   decimal ext3Price =   (ext3PB!=null && rec.Extension_3__c!=null?convertamount( 'TO',rec.Extension_Unit_3__c,rec.Extension_Quantity_3__c,ext3Info)*priceCalculationInfo.calculateUnitPrice(ext3PB):0);
                   
                   system.debug(logginglevel.error,'prodPrice:'+prodPrice+'*'+priceCalculationInfo.calculateUnitPrice(relatedPB)+' ext1Price:'+ext1Price+'*'+priceCalculationInfo.calculateUnitPrice(ext1PB)+' ext2Price:'+ext2Price+' ext3Price:'+ext3Price);
                   
                   convertedQuantity =  convertamount('TO',rec.UnitOfMeasure__c,rec.Quantity,prdInfo)+
                       (rec.Extension_Quantity_1__c!=null?convertamount( 'TO',rec.Extension_Unit_1__c,rec.Extension_Quantity_1__c,ext1Info):0)+
                       (rec.Extension_Quantity_2__c!=null?convertamount('TO',rec.Extension_Unit_2__c,rec.Extension_Quantity_2__c,ext2Info):0)+
                       (rec.Extension_Quantity_3__c!=null?convertamount( 'TO',rec.Extension_Unit_3__c,rec.Extension_Quantity_3__c,ext3Info):0);
                    
                   rec.TotalTonWeight__c=convertedQuantity!=null?convertedQuantity:0;
                   rec.TotalLinePrice__c=prodPrice+ext1Price+ext2Price+ext3Price;
                   /*get Avg price for TON*/
                   rec.PriceForTon__c= rec.TotalLinePrice__c!=0 && rec.TotalLinePrice__c!=null && rec.TotalTonWeight__c!=null && rec.TotalTonWeight__c!=0?rec.TotalLinePrice__c/rec.TotalTonWeight__c:0;      
                   if(rec.Price_from_customer_order__c!=null && rec.Price_from_customer_order__c>0 &&rec.Price_from_customer_order__c!=priceCalculationInfo.calculateUnitPrice(relatedPB)){
                       rec.InCorrectPricing__c=true;
                       system.debug(logginglevel.ERROR,'IncorrectPricing:status changed to 10'+' priceCalculationInfo.calculateUnitPrice(relatedPB):'+priceCalculationInfo.calculateUnitPrice(relatedPB));
                   }
                   else{
                       rec.InCorrectPricing__c=false;
                       
                   }
                   ordersMap.get(rec.OrderId).recheckCredit__c=oldRec!=null  && oldRec.TotalLinePrice__c!=rec.TotalLinePrice__c?true:false;
                   system.debug(LOGGINGLEVEL.ERROR,'checkPricing:'+(convertedPrice +'+'+ convertedQuantity));
                   system.debug(LOGGINGLEVEL.ERROR,'recheckCredit__c:'+ordersMap.get(rec.OrderId).recheckCredit__c);
                   rec.RelatedOpportunity__c=rec.RelatedOpportunity__c==null && rec.RelatedOpportunityItem__c==null?relatedPB.Opportunity__c:null;
                   rec.RelatedOpportunityItem__c=rec.RelatedOpportunity__c==null && rec.RelatedOpportunityItem__c==null?relatedPB.RelatedOpportunityItem__c:null;
                   if(ordersMap.get(rec.OrderId).recheckCredit__c==true){
                       updateOrders.add( ordersMap.get(rec.OrderId));
                   }
               }
               
           }
    }
    
    public decimal convertamount(String targetUOM, String UOM,Decimal amount,product2 prodinfo){
        Decimal ProductSpecificGravity=prodinfo.specific_gravity__c!=null?prodinfo.specific_gravity__c:null;
        Decimal TonWeightCoefficient=prodinfo.TonWeightCoefficient__c!=null?prodinfo.TonWeightCoefficient__c:null;
        system.debug(loggingLevel.ERROR, 'convertamount func:-->targetUOM:'+targetUOM+' UOM-->'+UOM+' amount-->'+amount+' ProductSpecificGravity-->'+ProductSpecificGravity+' TonWeightCoefficient-->'+TonWeightCoefficient);
        decimal convertNu=priceCalculationInfo.convertAmountToUnitOfMeasure(targetUOM, UOM,amount,ProductSpecificGravity,TonWeightCoefficient);
        system.debug(loggingLevel.ERROR, 'convertNu:'+convertNu);
        return convertNu;
    }
    
    public void getRelatedOrderData(){
        if(!orderIds.isEmpty() && ordersMap.isEmpty()){
            ordersMap  = new Map<Id, Order>([SELECT Id,AccountId,recheckCredit__C,SapValidationsPerformed__c From Order WHERE Id IN:orderIds]);
        }
    }
    
    private void updateOrders(){
        if(!updateOrders.isEmpty()){
            update updateOrders;
        }
    }
}