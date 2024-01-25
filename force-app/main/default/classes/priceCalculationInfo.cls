global class priceCalculationInfo {
    static Map<Id,Integer>  ParentAccountMap = new Map<Id,Integer>();
    public static Map<string,IL_Price_Book__c> setPriceAndPBRec(DeliveryNoteItems__c rec,Id productId,Id Account,string AccountDivision, String measurementUnit,decimal amount,Id loadingPoint,string transportType,string IL_Group,Date invoiceDate){
        Map<string,IL_Price_Book__c> getPBInfo= new Map<string,IL_Price_Book__c>();
        Product2 prod = getProduct(productId);
        IL_Group = IL_Group!=null?IL_Group:prod!=null && prod.IL_Group__c!=null?prod.IL_Group__c:null;
       
        system.debug(loggingLevel.ERROR, 'priceCalculationInfo-->getPriceAndPBRec line 6:'+productId+'-->Account'+ Account+'-->measurementUnit:'+measurementUnit);
        system.debug(loggingLevel.ERROR, 'priceCalculationInfo-->getPriceAndPBRec line 7:-->transportType'+ transportType+'-->loadingPoint:'+loadingPoint+'-->amount:'+amount);
        IL_Price_Book__c priceAndProd = getPBRecord(productId,Account,AccountDivision,measurementUnit,amount,loadingPoint,transportType,IL_Group,invoiceDate);
        if(prod != null && priceAndProd != null){
            priceAndProd.Product_Service__r = prod;
        }
        if(priceAndProd!=null){getPBInfo.put(rec.UniqueId__c,priceAndProd);}
        system.debug(loggingLevel.ERROR, 'priceCalculationInfo-->getPriceAndPBRec Line 11:getPBInfo-->'+getPBInfo);
        return getPBInfo;
    }
    
    public static Decimal calculateUnitPrice(IL_Price_Book__c priceAndProd){
        Decimal amountPrice =0;
        if(priceAndProd!=null){
            amountPrice = (calculatePrice(priceAndProd) + 
                           (priceAndProd.Fixed_Price__c != null ? priceAndProd.Fixed_Price__c : 0) +
                           (priceAndProd.BaseFixedPrice__c != null ? priceAndProd.BaseFixedPrice__c : 0) + 
                           (priceAndProd.transport__c != null ? priceAndProd.transport__c : 0)
                          ).setScale(10);
            amountPrice= amountPrice>0?amountPrice:0;
        }
        system.debug(loggingLevel.ERROR, 'PriceCalculation amountPrice Line 29:'+amountPrice);
        return amountPrice;
    }
    
    public static decimal convertAmountToUnitOfMeasure(String targetUOM, String UOM,Decimal amount,Decimal ProductSpecificGravity,Decimal TonWeightCoefficient){
        decimal convertdAmount=0;
        targetUOM=targetUOM==null?'TO':targetUOM;
        UOM =UOM==null?'TO':UOM;
        switch on targetUOM{
            WHEN 'TO' {
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->calculateTotalTonWeight:amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                convertdAmount = orderItem_CalculateInfo.calculateTotalTonWeight(amount, UOM, ProductSpecificGravity,TonWeightCoefficient);
            }
            WHEN 'M3' {
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->calculateTotalCubeWeight:amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                convertdAmount = orderItem_CalculateInfo.calculateTotalCubeWeight(amount, UOM, ProductSpecificGravity,TonWeightCoefficient);
            }
            WHEN 'EA' {
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->calculateTotalEachWeight:amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                convertdAmount = orderItem_CalculateInfo.calculateTotalEachWeight(amount, UOM, ProductSpecificGravity,TonWeightCoefficient);
            }
            WHEN 'KG' {
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->calculateTotalKGWeight:amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                convertdAmount = orderItem_CalculateInfo.calculateTotalKGWeight(amount, UOM, ProductSpecificGravity,TonWeightCoefficient);                                           
            }
            WHEN 'LTR' {
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->calculateTotalLTRWeight:amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                convertdAmount = orderItem_CalculateInfo.calculateTotalLTRWeight(amount, UOM, ProductSpecificGravity,TonWeightCoefficient);                                            
            }
            WHEN ELSE{
                system.debug(loggingLevel.ERROR,'priceCalculationInfo-->convertAmountToUnitOfMeasure(null):amount-'+amount+'-UOM-'+UOM+'ProductSpecificGravity-'+ProductSpecificGravity+'-TonWeightCoefficient-'+TonWeightCoefficient);
                
            }
        }
        return convertdAmount;   
    }
    
    // func that recieves the component(product) Id, measurement unit and the amunt and returns the price
    @auraEnabled 
    public static Decimal getPrice(Id productId,Id Account,string AccountDivision, String measurementUnit,decimal amount, 
                                   Id loadingPoint,string transportType ,string IL_Group,Date invoiceDate){
                                       transportType=transportType==null||transportType==''?'Regular':transportType;
                                       system.debug(loggingLevel.ERROR, 'PriceCalculation GET PRICE INFO:'+productId+'-->Account'+ Account+'-->measurementUnit:'+measurementUnit);
                                       system.debug(loggingLevel.ERROR, 'PriceCalculation GET PRICE INFO2:-->transportType'+ transportType+'-->loadingPoint:'+loadingPoint+'-->amount:'+amount);
                                       Product2 prod = getProduct(productId);
                                       IL_Group = IL_Group!=null?IL_Group:prod!=null && prod.IL_Group__c!=null?prod.IL_Group__c:null;
                                       IL_Price_Book__c priceAndProd = getPBRecord(productId,Account,AccountDivision,measurementUnit,amount,loadingPoint,transportType,IL_Group,invoiceDate);
                                       system.debug(loggingLevel.ERROR, 'PriceCalculation PriceBook Id LINE 9:'+priceAndProd+' IL_Group:'+IL_Group);
                             
                                       if(priceAndProd == null){
                                           return -1;
                                       }
                                       if(prod != null && priceAndProd != null){
                                           priceAndProd.Product_Service__r = prod;
                                       }
                                       Decimal amountPrice = calculateUnitPrice(priceAndProd);
                                       system.debug(loggingLevel.ERROR, 'PriceCalculation amountPrice LINE 26:'+amountPrice);
                                       
                                       Decimal totalPrice=0.00;
                                       return amountPrice;
                                   }
    
    // func that recieves the component (product name or id)
    // and retrive it from DB and the related price from the price book,
    // returns the components data and price
    @auraEnabled
    public static IL_Price_Book__c getPBRecord(Id productId,Id Account,string AccountDivision,String measurementUnit,decimal amount,Id loadingPoint,
                                               string transportType,string IL_Group,Date invoiceDate){
                                                   transportType=transportType==null||transportType==''?'Regular':transportType;
                                                   System.debug(loggingLevel.error,'amount:'+amount+'-->productId:'+productId+'\nAccount:'+Account+'\nAccountDivision:'+AccountDivision+'\nloadingPoint:'+loadingPoint+'\ntransportType:'+transportType+'\nIL_Group:'+IL_Group+'\ninvoiceDate:'+invoiceDate);
                                                   setParentAccountMap(Account, ParentAccountMap);
                                                   System.debug(loggingLevel.error,'ParentAccountMap:'+ParentAccountMap);
                                                   List<IL_Price_Book__c> pricesAndPruducts = [
                                                       SELECT  Id, Name, Account__c, Start_Date__c, End_Date__c, Packing__c, Product_Family__c, Status__c,CurrencyIsoCode,Foreign_currency_invoice__c,
                                                       Fixed_Price__c,Account__r.AccountDivision__c, Product_Service__r.Name, k__c, N__c, p__c, B__c, Ca__c, CL__c, Co__c, Fe__c, IS__c, 
                                                       Mg__c, Mn__c, Ph__c, Zn__c, transport__c, Product_Service__r.K__c, Product_Service__r.N__c, 
                                                       Product_Service__r.P__c, Product_Service__r.B__c, Product_Service__r.Ca__c, Product_Service__r.Green__c,
                                                       Product_Service__r.CL__c, Product_Service__r.CO__c, Product_Service__r.Fe__c,
                                                       Product_Service__r.IS__c, Product_Service__r.Mg__c, Product_Service__r.Mn__c, Product_Family_new__r.group__c,
                                                       Product_Service__r.PH__c, Product_Service__r.ZN__c, Product_Service__r.IsActive,Product_Family_new__r.External_ID__c,
                                                       Product_Service__r.External_Id__c, Product_Service__r.id, Product_Service__r.Packing__c, Loading_Point__c,transport_Type__c,
                                                       Product_Service__r.Permit__c, Product_Service__r.Family, Product_Service__r.QuantityUnitOfMeasure, 
                                                       Product_Service__r.specific_gravity__c,Aggregation_mode__c, Base_amount__c, Crane_price__c,FillingFees__c, 
                                                       Extra_amount__c, Extra_rate_Scale_1__c, Extra_rate_Scale_2__c, Extra_rate_Scale_3__c, Payment_Terms__c ,Purchase_Order__c,
                                                       Product_Service__c, RecordTypeId, Scale_Price_1__c, Scale_Price_2__c, Transaction_Type__c,OverBelowAmount__c,OverBelowQuantity__c,
                                                       Scale_Price_3__c, Product_Family_new__c, Unit_Of_Meager__c,Opportunity__c,ConvertedTransportType__c,RelatedOpportunityItem__c,
                                                       DeliveryUnitOfMeasure__c,ChemicalTransportCurrency__c,ChemicalTransportPrice__c,BaseFixedPrice__c,Second_extra_unit_of_measure__c,
                                                       Extra_unit_of_measure__c,SecondExtraAmount__c,SecondExtraRateScale1__c,SecondExtraRateScale2__c,SecondExtraRateScale3__c
                                                       FROM IL_Price_Book__c
                                                       WHERE (Status__c = 'תקף' )
                                                       AND(
                                                           (Product_Service__c  = : productId AND Account__c IN:ParentAccountMap.keySet() )
                                                           OR
                                                           (Account__c!=null AND Account__r.AccountDivision__c='כימיקלים' AND Account__c IN:ParentAccountMap.keySet() AND Product_Service__c =: productId
                                                            AND(
                                                                (Loading_Point__c=:loadingPoint AND ConvertedTransportType__c=:transportType)
                                                                OR
                                                                (Loading_Point__c=:loadingPoint AND transport_Type__c=NULL)
                                                                OR 
                                                                (ConvertedTransportType__c=:transportType AND Loading_Point__c=NULL)
                                                            )
                                                           )
                                                           OR(Account__c = null 
                                                              AND(
                                                                  (Product_Service__c  =: productId )// מוצר בלבד
                                                                  OR
                                                                  (Product_Family_new__c!=null AND Product_Family_new__r.group__c=:IL_Group  )//משפחה בלבד
                                                              )
                                                             )
                                                       )
                                                   ];
                                                   System.debug(loggingLevel.Error,'pricesAndPruducts line 111:'+pricesAndPruducts);
                                                   return arrangeMap(ParentAccountMap,pricesAndPruducts,AccountDivision,invoiceDate,loadingPoint,transportType,amount);
                                               }
    
    private static IL_Price_Book__c arrangeMap(Map<Id,Integer> ParentAccountMap,List<IL_Price_Book__c> pricesAndPruducts,string AccountDivision,Date invoiceDate,string loadingPoint,string transportType, decimal amount){
        IL_Price_Book__c relatedPB = new IL_Price_Book__c();
        Integer chemicalPricing = 0;
        Integer AccountGrade=ParentAccountMap.size();
        for(IL_Price_Book__c pap : pricesAndPruducts){
            Date  dt=system.today(); //InvoiceDate!=null?InvoiceDate:system.today();
            SYSTEM.debug(LOGGINGlEVEL.ERROR, 'relatedPB INFO:/npap.Start_Date__c:'+pap.Start_Date__c+'\npap.End_Date__c:'+pap.End_Date__c);
            
            if(pap.Start_Date__c<=dt  && (pap.End_Date__c==null || pap.End_Date__c>=dt)){
                SWITCH ON  AccountDivision{
                    WHEN 'כימיקלים'{
                        if(pap.Product_Service__c!=null && pap.Account__c!=null  && (AccountGrade>ParentAccountMap.get(pap.Account__c)|| AccountGrade==ParentAccountMap.size()) && (
                            (pap.OverBelowAmount__c==null && pap.OverBelowQuantity__c==null)||
                            (amount>0 && pap.OverBelowAmount__c=='over' && pap.OverBelowQuantity__c<amount )||
                            (pap.OverBelowAmount__c=='below' &&  (pap.OverBelowQuantity__c>=amount||amount==null)))){
                                AccountGrade=ParentAccountMap.get(pap.Account__c)!=null?ParentAccountMap.get(pap.Account__c):AccountGrade;
                                if(pap.Loading_Point__c!=null && pap.Loading_Point__c==loadingPoint && pap.Transaction_Type__c!=null  && pap.ConvertedTransportType__c==transportType){//לפי מוצר+לקוח+נק העמסה+סוג הובלה
                                    if(((pap.OverBelowAmount__c=='over' && pap.OverBelowQuantity__c<amount)||(pap.OverBelowAmount__c=='below' && (pap.OverBelowQuantity__c>=amount||amount==null)))){
                                        relatedPB=pap;
                                        break;
                                    }
                                    else{
                                        chemicalPricing=1; 
                                        relatedPB=pap;
                                    }
                                }
                                else if(loadingPoint!=null && pap.Loading_Point__c==loadingPoint && pap.Transaction_Type__c==null && (chemicalPricing>3 || chemicalPricing==0)){//לפי מוצר+לקוח+נקודת העמסה  
                                    if(((pap.OverBelowAmount__c=='over' && pap.OverBelowQuantity__c<amount)||(pap.OverBelowAmount__c=='below' && (pap.OverBelowQuantity__c>=amount||amount==null))) && (chemicalPricing>2 || chemicalPricing==0)){
                                       chemicalPricing=2; 
                                       relatedPB=pap;
                                   }
                                    else{
                                        chemicalPricing=3; 
                                        relatedPB=pap;
                                    }
                                }
                                else if(transportType!=NULL && pap.ConvertedTransportType__c==transportType && pap.Loading_Point__c==null ){//לפי מוצר+לקוח+סוג הובלה
                                    if(((pap.OverBelowAmount__c=='over' && pap.OverBelowQuantity__c<amount)||(pap.OverBelowAmount__c=='below' &&(pap.OverBelowQuantity__c>=amount||amount==null))) && (chemicalPricing>4 || chemicalPricing==0)){
                                        chemicalPricing=4; 
                                        relatedPB=pap;
                                    }
                                    else if(chemicalPricing>5 || chemicalPricing==0){
                                         chemicalPricing=5; 
                                        relatedPB=pap;
                                    }
                                }
                                else if(pap.Loading_Point__c==null && pap.Transaction_Type__c==null ){//לפי מוצר+לקוח
                                     if(((pap.OverBelowAmount__c=='over' && pap.OverBelowQuantity__c<amount)||(pap.OverBelowAmount__c=='below' &&(pap.OverBelowQuantity__c>=amount||amount==null))) && (chemicalPricing>6 || chemicalPricing==0)){
                                        chemicalPricing=6; 
                                        relatedPB=pap;
                                     }
                                    else{
                                        chemicalPricing=7; 
                                        relatedPB=pap;
                                    }
                                }
                            }
                    }
                    WHEN ELSE{
                        if(AccountGrade>ParentAccountMap.get(pap.Account__c)||  AccountGrade==ParentAccountMap.size()){
                            AccountGrade=ParentAccountMap.get(pap.Account__c)!=null?ParentAccountMap.get(pap.Account__c):AccountGrade;
                            if(pap.Product_Service__c!=null  && pap.Account__c!=null ){//לפי מוצר+לקוח
                                relatedPB=pap;
                                break;
                            }
                            else if(pap.Product_Service__c!=null && pap.Account__c==null){//לפי מוצר
                                relatedPB=pap;
                                
                            }
                            else if(pap.Product_Family_new__c!=null && pap.Product_Family_new__r.External_ID__c!=null && pap.Product_Service__c==null && pap.Account__c==null){//לפי משפחה 
                                relatedPB=pap;
                            }
                            else{
                                SYSTEM.debug(LOGGINGlEVEL.ERROR, 'relatedPB Line 144:AccountDivision:'+AccountDivision+'--pap.Product_Service__c'+pap.Product_Service__c+' --pap.Account__c:'+pap.Account__c);
                                
                            }
                        }
                    }
                    
                }
            }
        }
        SYSTEM.debug(LOGGINGlEVEL.ERROR, 'relatedPB FOUND:'+relatedPB);
        
        return relatedPB;
    }
    
    // func that recieves tonne amount, comp info and its price and make the calculations, returns the final price
    public static Decimal calculatePrice(IL_Price_Book__c priceAndProd){
        // in the calculation - checking if the value is null -> assign '0' instead 
        if(priceAndProd == null){
            return null;
        }
        system.debug(loggingLevel.ERROR, 'PriceCalculation priceAndProd LINE 230:'+priceAndProd);
        
        
        Decimal result = (
            ((priceAndProd.Product_Service__r.K__c != null ? priceAndProd.Product_Service__r.k__c : 0)
             * (priceAndProd.k__c != null ? priceAndProd.k__c : 0)) + 
            ((priceAndProd.Product_Service__r.N__c != null ? priceAndProd.Product_Service__r.N__c : 0)
             * (priceAndProd.N__c != null ? priceAndProd.N__c : 0)) + 
            ((priceAndProd.Product_Service__r.P__c != null ? priceAndProd.Product_Service__r.p__c : 0)
             * (priceAndProd.p__c != null ? priceAndProd.p__c : 0)) + 
            ((priceAndProd.Product_Service__r.B__c != null ? priceAndProd.Product_Service__r.B__c : 0)
             * (priceAndProd.B__c != null ? priceAndProd.B__c : 0)) + 
            ((priceAndProd.Product_Service__r.Ca__c != null ? priceAndProd.Product_Service__r.Ca__c : 0) 
             * (priceAndProd.Ca__c != null ? priceAndProd.Ca__c : 0)) + 
            ((priceAndProd.Product_Service__r.CL__c != null ? priceAndProd.Product_Service__r.CL__c : 0) 
             * (priceAndProd.CL__c != null ? priceAndProd.CL__c : 0)) +
            ((priceAndProd.Product_Service__r.CO__c != null ? priceAndProd.Product_Service__r.Co__c : 0) 
             * (priceAndProd.Co__c != null ? priceAndProd.Co__c : 0)) + 
            ((priceAndProd.Product_Service__r.Fe__c != null ? priceAndProd.Product_Service__r.Fe__c : 0) 
             * (priceAndProd.Fe__c != null ? priceAndProd.Fe__c : 0)) + 
            ((priceAndProd.Product_Service__r.Green__c != null ? priceAndProd.Product_Service__r.Green__c : 0) 
             * (priceAndProd.IS__c != null ? priceAndProd.IS__c : 0)) +
            ((priceAndProd.Product_Service__r.Mg__c != null ? priceAndProd.Product_Service__r.Mg__c : 0) 
             * (priceAndProd.Mg__c != null ? priceAndProd.Mg__c : 0)) + 
            ((priceAndProd.Product_Service__r.Mn__c != null ? priceAndProd.Product_Service__r.Mn__c : 0) 
             * (priceAndProd.Mn__c != null ? priceAndProd.Mn__c : 0)) + 
            ((priceAndProd.Product_Service__r.PH__c != null ? priceAndProd.Product_Service__r.Ph__c : 0) 
             * (priceAndProd.Ph__c != null ? priceAndProd.Ph__c : 0)) + 
            ((priceAndProd.Product_Service__r.ZN__c != null ? priceAndProd.Product_Service__r.Zn__c : 0) 
             * (priceAndProd.Zn__c != null ? priceAndProd.Zn__c : 0))
        ).setScale(3);
        system.debug(loggingLevel.ERROR, 'N P K result:'+result);
        
        return result;
    }
    
   public static Decimal weightAmountConvert(String type, Decimal amount, Decimal productSpecificGravity, decimal TonWeightCoefficient){
        productSpecificGravity=productSpecificGravity!=null?productSpecificGravity:1;
        TonWeightCoefficient=TonWeightCoefficient!=null?TonWeightCoefficient:1;

        Decimal result=amount.setScale(3);
        switch on type {
            when 'TonneToCube' {
                result = (amount * productSpecificGravity).setScale(3);
            }
            when 'CubeToTonne' {
                result = (amount/productSpecificGravity).setScale(3);
            }
            when 'LiterToTonne' {
                result = (amount/productSpecificGravity).divide(1000, 3);
            }
            when 'LiterToCube' {
                result = amount.divide(1000, 3);
            }
            when 'KiloToTonne' {
                result = amount.divide(1000, 3);
            }
             when 'KiloToCube' {
                result = (amount*productSpecificGravity).divide(1000, 3);
            }
            when 'EachToTonne' {
                result = (amount*TonWeightCoefficient).setScale(3);// Validate with Yaron
            }
        }
        return result;
    }
    
    @auraEnabled
    public static Product2 getProduct(Id productId){
        List<Product2> prod = [
            SELECT Name, K__c, N__c, P__c, B__c, Ca__c, CL__c, CO__c, Fe__c, IS__c, Mg__c, Mn__c, PH__c, ZN__c,Green__c,
            IsActive, External_Id__c, id, Packing__c, Permit__c, Family,Product_hierarchy__c,Product_Hiarch_Type__c,
            TonWeightCoefficient__c,IL_Group__c,Product_hierarchy__r.External_ID__c, QuantityUnitOfMeasure, 
            specific_gravity__c,Product_hierarchy_Code__c,Crystallization_temperature__c,Accumulation_state__c
            FROM Product2
            WHERE id =: productId
        ];
        return prod.size() > 0 ? prod[0] : null;
    }
    
    public static Account getAccount(Id AccountId){
        List<Account> accS = [
            SELECT Name,AccountDivision__c,Setelment__r.Geographic_Area__c, Setelment__c,ProductCustomerClassification__c
            FROM Account
            WHERE id =: AccountId
        ];
        return accS.size() > 0 ? accS[0] : null;
    }
    
    public static  Map<Id,Integer> setParentAccountMap(Id AccountId, Map<Id,Integer> ParentAccountMap){
        ParentAccountMap= ParentAccountMap!=null?ParentAccountMap:new Map<Id,Integer>();
        if(AccountId!=null ){
            system.debug(loggingLevel.ERROR, 'setParentAccountMap-->AccountId value:'+AccountId);
            integer checkNumber=10;
            string Account = AccountId;
            ParentAccountMap.PUT(Account,0);
            string acc=string.ValueOf(Account);
            for(Integer i=0;i<checkNumber;i++){
                acc=queryParentAccount(acc);
                if(acc!=null){
                    ParentAccountMap.put(acc,I++);
                }
                else{
                    break;
                }
            }
        }
        return ParentAccountMap;
    }
    
    public static string queryParentAccount(Id Account){
        Account parentAcc= new Account();
        string parentAccount=null;
        if(Account!=null){
            parentAcc=[Select Id,ParentId FROM Account WHERE ID=:Account];
            parentAccount=parentAcc.ParentId;
        }
        system.debug(logginglevel.ERROR, 'Line 374 -->queryParentAccount for Account Id:'+Account+' parent account found:'+parentAccount);

        return  parentAccount;
    }
    
}