/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 06-11-2023
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global class getProductDiscount {
    
    public static  Map<string,Discount__c>  setPricingMap(Set<Id> productsId,Set<string> subFamilyIds,Set<string> groupFamIds ,string status ){
        Map<string,Discount__c> DiscountMap = new Map<string,Discount__c>();
        date startDate	= system.today();
        date endDate	= system.today();
        List<discount__c> discounts	= new List<Discount__c>([SELECT  Id, Account__c, Account__r.Name, CurrencyIsoCode, Display_Filter_1__c, Display_Filter_2__c, 
                                                             End_Date__c, Product__c,Product__r.Product_Hiarch_Type__c,Product__r.IL_Group__c,Geographic_Area__c,
                                                             Requested_Discount__c, Start_Date__c, Status__c,Grade__C,Product_Family_new__r.External_ID__c,
                                                             Settlement__c,Product_Family_new__r.Group__c,Sub_Product_Family__c,Sub_Product_Family__r.External_ID__c
                                                             FROM Discount__c 
                                                             WHERE (Status__c =:status)
                                                             AND ( Product__c IN: productsId 
                                                                  OR Sub_Product_Family__r.External_ID__c IN:subFamilyIds 
                                                                  OR Product_Family_new__r.Group__c	 IN:groupFamIds ) 
                                                             AND Start_Date__c < :startDate
                                                             AND End_Date__c > :endDate]);
        
        if(!discounts.isEmpty()){
            system.debug(loggingLevel.ERROR,'discounts size:'+discounts.size() );
            for(Discount__c rec:discounts){
                string discountType=null;
                if(rec.Account__c!=null){
                    discountType=rec.Account__c;
                }
                if(rec.Settlement__c!=null){
                    discountType=rec.Settlement__c;
                }
                if(rec.Geographic_Area__c!=NULL){
                    discountType=rec.Geographic_Area__c;
                }
                if(discountType!=null){
                    if(rec.Product__c!=null)
                        DiscountMap.put(discountType+'-'+rec.Product__c,rec);
                    if(rec.Sub_Product_Family__c!=null && rec.Sub_Product_Family__r.External_ID__c!=null)
                        DiscountMap.put(discountType+'-'+rec.Sub_Product_Family__r.External_ID__c,rec);
                    if(rec.Product_Family_new__c !=null && rec.Product_Family_new__r.External_ID__c!=null){
                        DiscountMap.put(discountType+'-'+rec.Product_Family_new__r.External_ID__c,rec);                
                    }
                }
            }
        }
        return DiscountMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static Discount__c getDiscountRec(string prd,string Account,Map<Id,string> ParentAccountMap,Map<string,Discount__c> DiscountMap){
        system.debug(loggingLevel.ERROR,'prd: '+prd);
        system.debug(loggingLevel.ERROR,'Account '+Account);
        Discount__c relatedDiscount= findRelatedDiscount( prd, Account,'תקף');
        return relatedDiscount;
    }
    
    private static Discount__c findRelatedDiscount( string prd,string Account, string status){
        Map<Id,Integer> ParentAccountMap= null;
        Map<string,Discount__c> DiscountMap = new Map<string,Discount__c>();
        
        Discount__c relatedDiscount= null;
        if( prd!=null){
            Product2 prdInfo 		= priceCalculationInfo.getProduct(prd);
            Account acc				= Account!=null && Account!=''?priceCalculationInfo.getAccount(Account):null;
            string Setelment		= acc!=null?acc.Setelment__c:null;
            string GeoArea			= acc!=null && acc.Setelment__c!=null?acc.Setelment__r.Geographic_Area__c:null;
            string ProductHirec 	= prdInfo.Product_hierarchy_Code__c;
            string ILGroup			= prdInfo.IL_Group__c;
            decimal discount		= 0.00;
            ParentAccountMap		= Account!=null && Account!=''? priceCalculationInfo.setParentAccountMap(Account, ParentAccountMap):null;
            system.debug(loggingLevel.ERROR,'Setelment:'+Setelment);
            system.debug(loggingLevel.ERROR,'GeoArea:'+GeoArea);
            system.debug(loggingLevel.ERROR,'ILGroup:'+ILGroup);
            
            if(DiscountMap==null || DiscountMap.isEmpty()){
                Set<Id> productsId = new  Set<Id>();
                if(prd!=null){
                    productsId.add(prd);
                }
                Set<string> subFamilyIds= new  Set<string>();
                if(ProductHirec!=null){
                    subFamilyIds.add(ProductHirec);
                }
                Set<string> groupFamIds = new  Set<string>();
                if(ILGroup!=null){
                    groupFamIds.add(ILGroup);
                }
                DiscountMap=setPricingMap(productsId,subFamilyIds,groupFamIds,status);
                system.debug(loggingLevel.ERROR,'DiscountMap line 76:'+DiscountMap);
                
            }
            if(DiscountMap!=null && !DiscountMap.isEmpty()){
                Integer grade =0;
                if(ParentAccountMap!=null && ParentAccountMap.size()>1 ){
                    system.debug(loggingLevel.ERROR, 'ParentAccountMap:'+ParentAccountMap);
                    for(string accountId:ParentAccountMap.keyset()){
                             system.debug(loggingLevel.ERROR, 'ParentAccountMap grade:'+grade+' ParentAccountMap.get(accountId):'+ParentAccountMap.get(accountId));
                        if(DiscountMap.get(accountId+'-'+prd)!=null && (grade<ParentAccountMap.get(accountId)||grade==0)){ //לקוח+מוצר 
                            grade=ParentAccountMap.get(accountId);
                            relatedDiscount=DiscountMap.get(accountId+'-'+prd);
                        }
                        else if(DiscountMap.get(accountId+'-'+ProductHirec)!=null && (grade<ParentAccountMap.get(accountId)||grade==0)){// לקוח +תת משפחת מוצרים
                            grade=ParentAccountMap.get(accountId);
                            relatedDiscount=DiscountMap.get(accountId+'-'+ProductHirec);
                        }
                        else if(DiscountMap.get(accountId+'-'+ILGroup)!=null && (grade<ParentAccountMap.get(accountId)||grade==0)){// לקוח +משפחת מוצרים
                            grade=ParentAccountMap.get(accountId);
                            relatedDiscount=DiscountMap.get(accountId+'-'+ILGroup);
                        }
                    }
                }
                
                if(DiscountMap.get(Account+'-'+prd)!=null && grade==0){ //לקוח+מוצר 
                    relatedDiscount=DiscountMap.get(Account+'-'+prd);
                }
                else if(DiscountMap.get(Account+'-'+ProductHirec)!=null && grade==0){// לקוח +תת משפחת מוצרים
                    relatedDiscount=DiscountMap.get(Account+'-'+ProductHirec);
                    system.debug(loggingLevel.ERROR,'ProductHirec discount:'+relatedDiscount );
                    
                }
                else if(DiscountMap.get(Account+'-'+ILGroup)!=null  && grade==0){// לקוח +משפחת מוצרים
                    relatedDiscount=DiscountMap.get(Account+'-'+ILGroup);
                    system.debug(loggingLevel.ERROR,'ILGroup discount:'+relatedDiscount );
                    
                }
                else if(DiscountMap.get(Setelment+'-'+prd )!=null  && grade==0){// ישוב+מוצר
                    relatedDiscount=DiscountMap.get(Setelment+'-'+prd);            
                }
                else if(DiscountMap.get(Setelment+'-'+ProductHirec)!=null && grade==0){//ישוב+תת משפחת מוצר 
                    relatedDiscount=DiscountMap.get(Setelment+'-'+ProductHirec);  
                }
                else if(DiscountMap.get(Setelment+'-'+ILGroup)!=null && grade==0 ){//ישוב+משפחת מוצר    
                    relatedDiscount=DiscountMap.get(Setelment+'-'+ILGroup);
                }
                else if(DiscountMap.get(GeoArea+'-'+prd)!=null && grade==0){//אזור+מוצר
                    relatedDiscount=DiscountMap.get(GeoArea+'-'+prd);
                }
                else if(DiscountMap.get(GeoArea+'-'+ProductHirec )!=null && grade==0){//אזור +תת משפחת מוצר
                    relatedDiscount=DiscountMap.get(GeoArea+'-'+ProductHirec);
                }
                else if(DiscountMap.get(GeoArea+'-'+ILGroup)!=null && grade==0){//אזור +משפחת מוצר
                    relatedDiscount=DiscountMap.get(GeoArea+'-'+ILGroup);
                }
            }
            
        }
        system.debug(loggingLevel.ERROR,'Discount found:'+relatedDiscount );
        return relatedDiscount;
    }
    
    
    public static  Map<Id,Integer> setchildAccountMap(set<Id> relatedAccounts, Map<Id,Integer> ChildAccountMap){
        if(!relatedAccounts.isEmpty() ){
            system.debug(loggingLevel.ERROR, 'setParentAccountMap-->relatedAccounts value:'+relatedAccounts);
            integer checkNumber=6;
            for(Id parentId :relatedAccounts){
                ChildAccountMap.PUT(parentId,0);
            }
            
            for(Integer i=1;i<checkNumber;i++){
                queryChildAccount(relatedAccounts,ChildAccountMap,i);
            }
        }
        system.debug(loggingLevel.ERROR, 'setParentAccountMap-->relatedAccounts value:'+ChildAccountMap);

        return ChildAccountMap;
    }
    
    @AuraEnabled(cacheable=true)
    public static string queryParentAccount(Id Account){
        Account parentAcc= new Account();
        parentAcc=[Select Id,ParentId FROM Account WHERE Id=:Account];
        return  parentAcc.ParentId;
    }
    
    public static  void queryChildAccount(set<Id> relatedAccounts,Map<Id,Integer> ChildAccountMap,Integer i){
        List<Account> childAcc= new List<Account>();
        childAcc=[Select Id,ParentId FROM Account WHERE ParentId IN:relatedAccounts];
        system.debug(loggingLevel.ERROR, 'queryChildAccount-->childAcc:'+childAcc.size());
        relatedAccounts.clear();
        for(Account acc:childAcc){
            ChildAccountMap.put(acc.Id,i);
            relatedAccounts.add(acc.Id);
        }
        system.debug(loggingLevel.ERROR, 'queryChildAccount-->ChildAccountMap value:'+ChildAccountMap.size());
    }
    
    
    public class FlowInputs{
        @InvocableVariable
        public Discount__c disRec;
    }
    
    @InvocableMethod(label='UpsertDiscountLines')
    public static void approvedDiscountRec(List<FlowInputs> requests){
        try{
            for(FlowInputs rec: requests){
                system.debug(loggingLevel.ERROR, 'upsertDeliveryDiscountLines rec info:'+rec);
                if(rec.disRec!=null){
                    try{
                    upsertRelaventDeliveryNotes(rec.disRec);
                    }
                    catch(Exception e){
                        
                    }
                }
            }
        }
        catch(DMLException DML){
        }
    }
    
    
    /* 
    * Created By: Lilach Mis
    * Description: Searches Related Delivery Notes and Delivery Notes Line Items 
    * by product/ product Family and Account/Settelment/Geographic Area and either 
    * creates new discountType line or updates existing lines
    * Uses methods from class DeliveryNoteItem_UpsertLines:
    * **upsertDeliveryNote
    * **setDNIRec
    */
    public static void upsertRelaventDeliveryNotes(Discount__c disRec){
        system.debug(loggingLevel.ERROR, 'upsertRelaventDeliveryNotes-->disRec:'+disRec);
        Map<Id,Map<Id,Integer>> AccountRelatedToDN= new Map<Id,Map<Id,Integer>>();
        Map<Id,Integer> ChildAccountMap= new Map<Id,Integer>();
        Set<Id> relatedAccounts= new Set<Id>();
        Map<Id, Product_hierarchy__c> prodHierarchyInfo= new Map<Id,Product_hierarchy__c>([SELECT Division__c, External_ID__c, Family__c, Group__c, Type__c, IL_Group__c, Id FROM Product_hierarchy__c where Id=:disRec.Product_Family_new__c]);
        if(!prodHierarchyInfo.isEmpty()){
            disRec.Product_Family_new__r=prodHierarchyInfo.get(disRec.Product_Family_new__c);
        }
        if(disRec.Account__c!=null){
            relatedAccounts.add(disRec.Account__c);
            ChildAccountMap.put(disRec.Account__c,0);
            ChildAccountMap= relatedAccounts!=null?setchildAccountMap(relatedAccounts, ChildAccountMap):null;
        }


        List<DeliveryNote__c> relatedDeliveryNoteLines = new List<DeliveryNote__c>([SELECT Id,Order__c,OrderItem__c,DeliveryNoteLineId__c,Product__c,Account__c,AccountSettlement__c,GeographicArea__c,
                                                                                    (SELECT Id,DeliveryNote__c,TotalPrice__c ,LineDiscount__c,Product__c,FK_ProductDiscount__c,LineItemType__c,UniqueId__c,
                                                                                     TotalWeight__c ,FK_ProductDiscount__r.Grade__c,Product__r.IL_Group__c,ProductILGroup__c ,ProductHierarchy__c ,Product__r.Product_hierarchy_Code__c
                                                                                     FROM Delivery_Note_Line_Items__r 
                                                                                     WHERE LineItemType__c='1' OR LineItemType__c='2' OR LineItemType__c='8' ORDER BY DeliveryNote__c ,LineItemType__c) 
                                                                                    FROM DeliveryNote__c 
                                                                                    WHERE Interface_Response__c =NULL 
                                                                                    AND billingDoc__C=null
                                                                                    AND( Account__c IN : ChildAccountMap.keySet()
                                                                                        OR (Account__r.Setelment__c!=null AND Account__r.Setelment__c =:disRec.Settlement__c)
                                                                                        OR (Account__r.Setelment__r.Geographic_Area__c!=NULL AND Account__r.Setelment__r.Geographic_Area__c=:disRec.Geographic_Area__c))
                                                                                    AND(((Product__c!=null AND Product__c =:disRec.Product__c)
                                                                                            OR(Product__r.Product_hierarchy_Code__c!=null AND Product__r.Product_hierarchy_Code__c=: disRec.Product_Family_new__r.External_ID__c )
                                                                                            OR(Product__r.IL_Group__c!=null AND Product__r.IL_Group__c=:disRec.Product_Family_new__r.Group__c)))]);
        if(relatedDeliveryNoteLines!=null){  
            List<DeliveryNoteItems__c> createLineItemsList = new List<DeliveryNoteItems__c>();

            system.debug(loggingLevel.ERROR, 'relatedDeliveryNoteLines found:'+relatedDeliveryNoteLines);

           
            for(DeliveryNote__c DNRec:relatedDeliveryNoteLines){
               
                AccountRelatedToDN.put(DNRec.Id,ChildAccountMap);
            }
            
            for(DeliveryNote__c rec:relatedDeliveryNoteLines){
                system.debug(loggingLevel.ERROR, 'upsertRelaventDeliveryNotes-->DN rec:'+rec);
                DeliveryNoteItems__c discountLine=null;
                decimal TotalDiscount=0;
                decimal totalSumLine=0;
                for(DeliveryNoteItems__c DNI:rec.Delivery_Note_Line_Items__r){
                    system.debug(loggingLevel.ERROR, 'upsertRelaventDeliveryNotes-->DNI rec:'+DNI);
                               system.debug(loggingLevel.ERROR, 'upsertRelaventDeliveryNotes-->DNI rec:'+DNI);
                    if(/*(DNI.Product__c==disRec.Product__c ||
                        (DNI.ProductHierarchy__c !=null && prodHierarchyInfo.get(disRec.Product_Family_new__c)!=null && DNI.ProductHierarchy__c==prodHierarchyInfo.get(disRec.Product_Family_new__c).External_ID__c)||
                        (DNI.ProductILGroup__c!=null && prodHierarchyInfo.get(disRec.Product_Family_new__c)!=null &&  DNI.ProductILGroup__c==prodHierarchyInfo.get(disRec.Product_Family_new__c).Group__c))&&*/
                       (DNI.FK_ProductDiscount__c==null || (DNI.FK_ProductDiscount__c!=null && disRec.Grade__c>DNI.FK_ProductDiscount__r.Grade__c))){
                           DNI.FK_ProductDiscount__c=disRec.Id;
                           DNI.LineDiscount__c=disRec.Requested_Discount__c;
                           system.debug(loggingLevel.ERROR, '1.disRec.Requested_Discount__c:'+ disRec.Requested_Discount__c+'--DNI.TotalPrice__c:'+DNI.TotalPrice__c+'-->DNI.TotalWeight__c:'+DNI.TotalWeight__c);
                           system.debug(loggingLevel.ERROR, '2.revaluateRelatedDiscount func--> UPDATE TotalDiscount:'+TotalDiscount+' totalSumLine:'+totalSumLine);
                           createLineItemsList.add(DNI);
                           totalSumLine +=DNI.TotalPrice__c!=null?DNI.TotalPrice__c*(DNI.TotalWeight__c!=null?DNI.TotalWeight__c:0):0;
                           totalDiscount+=DNI.LineDiscount__c*(DNI.TotalPrice__c!=null?DNI.TotalPrice__c*(DNI.TotalWeight__c!=null?DNI.TotalWeight__c:0):0);
                    }
                 
                    
                    if(DNI.LineItemType__c=='8'){
                        discountLine=DNI;
                        discountLine.LineDiscount__c =totalDiscount/totalSumLine;
                        system.debug(loggingLevel.ERROR, '3.discountLine exist:'+discountLine+' discount requested:'+discountLine.LineDiscount__c);
                        createLineItemsList.add(discountLine);
                    }
                }
                if(totalDiscount>0 && discountLine==null){
                    string UniqueId = rec.DeliveryNoteLineId__c +'-8';
                    discountLine = DeliveryNoteItem_UpsertLines.setDNIRec(null,rec,null,UniqueId,'8',null,null);
                    discountLine.LineDiscount__c =totalDiscount/totalSumLine;
                    system.debug(loggingLevel.ERROR, '4.revaluateRelatedDiscount func-->totalDiscount:'+discountLine.LineDiscount__c+'LineDiscount__c:'+discountLine);
                    createLineItemsList.add(discountLine);
                }

            }
            
            system.debug(loggingLevel.ERROR, 'test');
            
            if(createLineItemsList.size()>0){
                system.debug(loggingLevel.ERROR, 'upsertRelaventDeliveryNotes-->createLineItemsList :'+createLineItemsList);
                DeliveryNoteItem_UpsertLines.upsertDeliveryNote(createLineItemsList);
            }
        }
    }
    
    
    /* 
    * Created By: Lilach Mis
    * trigger: Fires when a discount record gets approved 
    * Description: Searches Discounts in status ממתין לאישור 
    * based on the existing method findRelatedDiscount 
    * used in class:
    * **DeliveryNote_CalculateTotalPricing - if discount record found, PendingApprovalDiscount__c 
    field type cb is checked
    */
    public static Discount__c getPendingApprovalDiscountRec(string prd,string Account){
        system.debug(loggingLevel.ERROR,'prd: '+prd);
        system.debug(loggingLevel.ERROR,'Account '+Account);
        Discount__c relatedDiscount= findRelatedDiscount( prd, Account,'ממתין לאישור');
        return relatedDiscount;
    }
    
}