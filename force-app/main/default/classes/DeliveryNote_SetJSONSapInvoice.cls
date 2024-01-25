global class DeliveryNote_SetJSONSapInvoice {
  
    static Map<Id,Delivery_Note_Staging__c> relatedInvoiceJSON = new Map<Id,Delivery_Note_Staging__c> ();
    
    
    @InvocableMethod(label='Create Delivery Note Staging For Callout Operation')
    public static List<FlowOutputs> CreateDeliveryNoteStaging(List<FlowInputs> requests) {
        List<FlowOutputs> results = new List<FlowOutputs>();
        try{
            for(FlowInputs rec: requests){
                FlowOutputs FO = new FlowOutputs();
                FO.DMLResult=createNewDNSRecord( buildJSON(rec.approvedDN),rec.approvedDN).Id;
                system.debug(loggingLevel.ERROR,'DN rec:'+rec.approvedDN);
                results.add(FO);
            }
        }
        catch(DMLException DML){
        }
        return  results;
    }
    
    
    
    //output details which goes from apex to flow
    public class FlowOutputs{
        @InvocableVariable
        public String DMLResult;
    }
    //input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public DeliveryNote__c approvedDN;
        
        @InvocableVariable
        public boolean Foreign_currency_invoice;
        
        
    }
    
    
    public static string buildJSON(DeliveryNote__c approvedDN){
        List<DeliveryNoteItems__c> relatedDNI = new List<DeliveryNoteItems__c>([SELECT DeliveryNote__c,DischargeQuantity__c,LineItemType__c,DeliveryNote__r.order__r.OriginalDeliveryNote__r.DeliveryNoteLineId__c,
                                                                                OrderItem__c,Order__c,ProductHierarchy__c,ProductILGroup__c,RelatedPriceBook__r.Account__r.AccountDivision__c,DeliveryNote__r.RelatedDeliveryNote__r.DeliveryNoteLineId__c,
                                                                                FK_BillingCredit__r.Delivery_Note__c,FK_BillingCredit__c,DeliveryNote__r.FKBillingCredit__c,FK_BillingCredit__r.Delivery_Note__r.BillingDoc__c,
                                                                                ProductQuantityFromTotal__c,ProductSapNumber__c,ProductSpecificGravity__c,Product__c,RelatedPriceBook__r.ChemicalTransportCurrency__c,
                                                                                RelatedPriceBook__c,RelatedPriceBook__r.Foreign_currency_invoice__c	,RelatedPriceBook__r.CurrencyIsoCode,TotalCubeWeight__c,TotalPriceInCube__c,TotalPrice__c,
                                                                                TotalWeight__c,TransactionType__c,UniqueId__c,RelatedPriceBook__r.SpecialCommission__c,RelatedPriceBook__r.Payment_Terms__c,
                                                                                DeliveryNote__r.RelatedDeliveryNote__r.TransactionType__c
                                                                                FROM DeliveryNoteItems__c
                                                                                WHERE DeliveryNote__c=:approvedDN.Id]);
        
        DeliveryNoteItems__c billingLine = new DeliveryNoteItems__c();
        DeliveryNoteItems__c mainProduct = new DeliveryNoteItems__c();
        string DocType =approvedDN.TransactionType__c!=null && approvedDN.TransactionType__c!=''?approvedDN.TransactionType__c:'30';
        string ORD_REASON='004';
        string PURCH_NO_C= '';
        for( DeliveryNoteItems__c rec:relatedDNI){
            if(rec.LineItemType__c=='1' ||rec.LineItemType__c=='6' || (rec.LineItemType__c=='7' && approvedDN.InventoryManagementOnly__c==true) ){
                mainProduct=rec;
                if(approvedDN.TransactionType__c=='80'){ 
                    DocType='30';
                    ORD_REASON='503';
                }
                else if(approvedDN.TransactionType__c=='40'){ 
                    DocType=mainProduct.DeliveryNote__r.RelatedDeliveryNote__r.TransactionType__c=='20'?'25':DocType;
                    ORD_REASON= '516';
                }
                PURCH_NO_C= approvedDN.FKBillingCredit__c==NULL?(mainProduct.DeliveryNote__r.order__r.OriginalDeliveryNote__c!=null?mainProduct.DeliveryNote__r.order__r.OriginalDeliveryNote__r.DeliveryNoteLineId__c:approvedDN.OrderPayerApproval__c):PURCH_NO_C;

            }
            if( approvedDN.FKBillingCredit__c!=NULL && (rec.LineItemType__c=='4'||rec.LineItemType__c=='5')){
                billingLine=rec;
                if(billingLine.FK_BillingCredit__r.Delivery_Note__c!=null ){DocType = billingLine.LineItemType__c=='4'?'80':'70';}
                else{
                    DocType = billingLine.LineItemType__c=='4'?'35':'30'; 
                    
                }
                PURCH_NO_C=billingLine.DeliveryNote__r.RelatedDeliveryNote__r.DeliveryNoteLineId__c!=null? billingLine.DeliveryNote__r.RelatedDeliveryNote__r.DeliveryNoteLineId__c:approvedDN.DeliveryNoteLineId__c;
                system.debug(loggingLevel.ERROR,'PURCH_NO_C:'+PURCH_NO_C);
                
                ORD_REASON=billingLine.LineItemType__c=='4'?'506':'523';
            }
        }
        
    
        system.debug(loggingLevel.ERROR,'mainProduct.ProductSapNumber__c:'+mainProduct.ProductSapNumber__c+'  --'+mainProduct);
        string Json=null;
        DeliveryNote__c DN= approvedDN;
        system.debug(loggingLevel.ERROR,'DN.delivery_cost__c:'+DN.delivery_cost__c+'  --dn.TotalLinesQuantity__c:'+dn.TotalLinesQuantity__c);
        boolean isChemical =mainProduct!=null && mainProduct.RelatedPriceBook__r.Account__r.AccountDivision__c=='כימיקלים'?true:false;
        string currencyTransport = mainProduct.RelatedPriceBook__r.ChemicalTransportCurrency__c=='USD'||mainProduct.RelatedPriceBook__r.ChemicalTransportCurrency__c=='EUR' ?mainProduct.RelatedPriceBook__r.ChemicalTransportCurrency__c:'ILS';
        boolean isForeignCurrency=mainProduct.RelatedPriceBook__c!=null?mainProduct.RelatedPriceBook__r.Foreign_currency_invoice__c:false;
        string currencyISO =mainProduct.RelatedPriceBook__c!=null?mainProduct.RelatedPriceBook__r.CurrencyIsoCode:'ILS';
        Decimal creditDNValue = 0.00;
        if(billingLine!=null && billingLine.TotalWeight__c!=null && DN.TotalCreditBilling__c!=null){
            creditDNValue= (billingLine.LineItemType__c=='5'?DN.TotalCreditBilling__c:(billingLine.LineItemType__c=='4' && DN.TotalCreditBilling__c<0?DN.TotalCreditBilling__c:-DN.TotalCreditBilling__c))*DN.TotalLinePrice__c;
        }
        else if(billingLine!=null && billingLine.TotalWeight__c==null && DN.totalCreditBillingValue__C!=null){
            system.debug(loggingLevel.ERROR, 'DN.totalCreditBillingValue__C:-DN.totalCreditBillingValue__C):'+DN.totalCreditBillingValue__C);
            creditDNValue= (billingLine.LineItemType__c=='5'?DN.totalCreditBillingValue__C:( billingLine.LineItemType__c=='4' && DN.totalCreditBillingValue__C<0?DN.totalCreditBillingValue__C:-DN.totalCreditBillingValue__C));
        }
        string FertInfo =DN.InventoryManagementOnly__c==false? setFertInfo(relatedDNI,approvedDN):'';
        string AgentReceivesCommission=DN.AgentReceivesCommission__c!=null?
            '{'+
            '"PARTN_ROLE": "Y1",'+
            '"PARTN_NUMB": "'+ DN.AgentReceivesCommission__c+'",'+
            '"ITM_NUMBER": "0"'
            +'},':'';
        string ZD = DN.TransactionType__c=='20' || DocType=='25'?
             '{'+
            '"PARTN_ROLE": "ZD",'+
            '"PARTN_NUMB": "5000456",'+
            '"ITM_NUMBER": ""'+
            '},':'';
        string ZW = DN.IntermediaryWarehouseSap__c!=null?
            '{'+
            '"PARTN_ROLE": "ZW",'+
            '"PARTN_NUMB": "'+DN.IntermediaryWarehouseSap__c+'",'+
            '"ITM_NUMBER": ""'+
            '},':'';
        system.debug(loggingLevel.ERROR, 'DN:'+DN);
        if(DN.InvoiceApproved__c==true){
            Json='{'+
                '"BINARY_RELATIONSHIPTYPE": "",'+
                '"SALES_HEADER_IN": {'+
                '"DOC_TYPE": "'+DocType+'",'+
                '"SALES_ORG": "7010",'+
                '"DISTR_CHAN": "02",'+
                '"DIVISON": "01",'+
                '"NAME": "",'+
                '"TELEPHONE": "",'+
                '"ZZINV_EMAIL": "",'+//לשים את המייל הארגוני מהלקוח
                '"INCOTERMS2": "",'+
                '"PMNTTRMS": "",'+
                '"ORD_REASON": "'+ORD_REASON+'",'+
                '"ZZCRDT_TXT": "",'+
    			'"ZZPLSTN_APP": "'+(DN.Authorizationinvoice__c!=null?DN.Authorizationinvoice__c:'')+'",'+
    			'"ZZSTRN":  "",'+
                '"BILL_DATE": "'+(DN.FKBillingCredit__c!=NULL?NULL :DN.ExchangeRateDate__c) +'",'+
                '"PURCH_NO_C": "'+PURCH_NO_C+'",'+
                '"REF_1_S": "",'+
                '"DOC_DATE": "'+DN.OrderCreatedDate__c+'",'+
                '"CURRENCY": "'+(DN.FKBillingCredit__c== NULL && isForeignCurrency==true?currencyISO:'ILS')+'",'+
                '"FKK_CONACCT": "",'+
                '"VERSION": "",'+
                '"PARENT": "'+(DN.ParentAccountSap__c!=null  ?DN.ParentAccountSap__c.replace('"','\\"'):DN.ParentAccountSap__c)+'",'+
                '"BRANCH": "'+(DN.BranchGrowth__c!=null?DN.BranchGrowth__c.replace('"','\\"'):DN.BranchGrowth__c)+'",'+
                '"PLOT": "'+DN.Plot__c+'",'+
                '"DISCHARGE": "'+(DN.DischargeLocationName__c!=null?DN.DischargeLocationName__c.replace('"','\\"'):DN.DischargeLocationName__c)+'",'+
                '"ORDCRM": "'+DN.OrderName__c+'",'+
                '"ORDCRML": "'+DN.OrderItemName__c+'",'+
                '"DELVNOTE": "'+(DN.FKBillingCredit__c!=NULL && billingLine!=null?billingLine.DeliveryNote__r.RelatedDeliveryNote__r.DeliveryNoteLineId__c:DN.DeliveryNoteNo__c)+'",'+
                '"DELVNOTEL": "'+DN.DeliveryNoteLineNo__c+'",'+
                '"DELVNOTEID": "'+DN.DeliveryNoteLineId__c+'",'+
                '"ZZLOADPOINT": "'+(DN.LoadingPointName__c!=null?DN.LoadingPointName__c.replace('"','\\"'):DN.LoadingPointName__c)+'",'+
                '"PAYMENTTEARMS": "'+mainProduct.RelatedPriceBook__r.Payment_Terms__c+'",'+
                '"REF_DOC": "'+(billingLine!=NULL?billingLine.FK_BillingCredit__r.Delivery_Note__r.BillingDoc__c:'')+'",'+
                '"PRICE_DATE": "'+DN.SupplyDate__c+'"'+
                '},'+
                '"SALES_CONDITIONS_IN": ['+
                '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "ZPRM",'+
                '"COND_VALUE": "'+(isForeignCurrency==false && currencyISO!='ILS'?string.valueOf(DN.TotalPriceBeforeDiscount__c):'0.00')+'",'+
                (isForeignCurrency==false && currencyISO!='ILS'?'"CURRENCY": "'+currencyISO+'",':'')+
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": "'+(DN.FKBillingCredit__c!=NULL && (DN.TotalCreditBilling__c<=0||DN.TotalCreditBilling__c==null)?string.valueOf(creditDNValue):(DN.FKBillingCredit__c==NULL &&((isForeignCurrency==true && currencyISO!='ILS')||currencyISO=='ILS')?string.valueOf(DN.TotalPriceBeforeDiscount__c):'0.00')) +'",'+
                '"CURRENCY_2": "'+(DN.FKBillingCredit__c==NULL?currencyISO:'ILS')+'",'+
                '"FACTBASVAL": "0.000",'+
                '"SCALBASVAL": "0.00"'+
                '},'+
                '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "ZD0%",'+
                '"COND_VALUE": "'+DN.TotalLinesDiscount__c+'",'+
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": "",'+
                '"CURRENCY_2": "ILS",'+
                '"FACTBASVAL": "0.000",'+
                '"SCALBASVAL": "0.00"'+
                '},'+
                '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "RB00",'+
                '"COND_VALUE": "0.0000",'+
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": "0.00",'+
                '"CURRENCY_2": "ILS",'+
                '"FACTBASVAL": "0.000",'+
                '"SCALBASVAL": "0.00"'+
                '},'+
               '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "ZPR7",'+
                '"COND_VALUE": "'+(DN.FKBillingCredit__c==NULL && ((isChemical==false && mainProduct.RelatedPriceBook__r.CurrencyIsoCode!='ILS')||currencyTransport!='ILS')&& DN.delivery_cost__c!=null && dn.TotalLinesQuantity__c!=null ?DN.delivery_cost__c*(isChemical==false?dn.DischargeWeightInTon__c:1)+dn.StandByHoursPricing__c:0.00)+'",'+ //להחריג ללקוח כימיקלים את המטבע של התמחור****
                '"CURRENCY":"'+(DN.FKBillingCredit__c==NULL && (isChemical==false && mainProduct.RelatedPriceBook__r.CurrencyIsoCode!='ILS')?mainProduct.RelatedPriceBook__r.CurrencyIsoCode:currencyTransport!='ILS'?currencyTransport:'')+'",'+// לקחת את השדה מטבע הובלה על המחירון
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": "'+ (DN.FKBillingCredit__c==NULL && ((mainProduct.RelatedPriceBook__r.CurrencyIsoCode=='ILS' && isChemical==false) || (isChemical==true &&currencyTransport=='ILS')) && DN.delivery_cost__c!=null && dn.TotalLinesQuantity__c!=null?DN.delivery_cost__c*(isChemical==false?dn.DischargeWeightInTon__c:1)+dn.StandByHoursPricing__c :0.00)+'",'+//סכום ההובלה מחיר הובל* כמות 
                '"CURRENCY_2": "'+(DN.FKBillingCredit__c==NULL && ((mainProduct.RelatedPriceBook__r.CurrencyIsoCode=='ILS' && isChemical==false) || (isChemical==true &&currencyTransport=='ILS'))?'ILS':'')+'",'+
                '"FACTBASVAL": "",'+ 
                '"SCALBASVAL": ""'+
                '},'+
                '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "ZD2F",'+
                '"COND_VALUE": "0.0000",'+
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": "'+(DN.DischargeWeightInTon__c>0 && DN.delivery_cost__c!=null && DN.Delivery_discount__c !=null ?(-DN.Delivery_discount__c *DN.delivery_cost__c* (isChemical==false?dn.DischargeWeightInTon__c:1)/100 ).setScale(3):0)+'",'+//סכום של הנחת הובלה
                '"CURRENCY_2": "ILS",'+
                '"FACTBASVAL": "0.000",'+
                '"SCALBASVAL": "0.00"'+
                '},'+
                
                '{'+
                 '"ITM_NUMBER": "10",'+
                 '"COND_ST_NO": "000",'+
                 '"COND_COUNT": "00",'+
                 '"COND_TYPE": "ZPCM",'+//רק לזיכויים לתעודת חיוב  התנאי הזה
                 '"COND_VALUE": "0.0000",'+
                 '"CONBASEVAL": "0",'+
                 '"NUMCONVERT": "0",'+
                 '"DENOMINATO": "0",'+
                 '"ACCESS_SEQ": "00",'+
                 '"CONDCOUNT": "0.00",'+
                 '"ROUNDDOFFDI": "0.00",'+
                 '"CONDVALUE": "'+(DN.FKBillingCredit__c!=NULL?0:DN.totalCreditBillingValue__C)+'",'+
                 '"CURRENCY_2": "ILS ",'+
                 '"FACTBASVAL": "0.000",'+
                 '"SCALBASVAL": "0.00"'+
                '},'+
                '{'+
                 '"ITM_NUMBER": "10",'+
                 '"COND_ST_NO": "000",'+
                 '"COND_COUNT": "00",'+
                 '"COND_TYPE": "ZPCQ",'+//רק לזיכויים כמותיים לתעודת חיוב  התנאי הזה
                 '"COND_VALUE": "0.00",'+
                 '"CONBASEVAL": "0",'+
                 '"NUMCONVERT": "0",'+
                 '"DENOMINATO": "0",'+
                 '"ACCESS_SEQ": "00",'+
                 '"CONDCOUNT": "0.00",'+
                 '"ROUNDDOFFDI": "0.00",'+
                 '"CONDVALUE": "'+(DN.FKBillingCredit__c==NULL && DN.TotalCreditBilling__c>0?string.valueOf(DN.TotalCreditBilling__c*DN.TotalLinePrice__c.setScale(3)):DN.FKBillingCredit__c!=NULL && DN.TotalCreditBilling__c>0?string.valueOf(DN.totalCreditBillingValue__C):'0.00')+'",'+//חישוב של הפיצוי הכמותי כפול מחיר ליחידה
                 '"CURRENCY_2": "ILS ",'+
                 '"FACTBASVAL": "0.000",'+
                 '"SCALBASVAL": "0.00"'+
                '},'+
                '{'+
                '"ITM_NUMBER": "10",'+
                '"COND_ST_NO": "000",'+
                '"COND_COUNT": "00",'+
                '"COND_TYPE": "ZPCP",'+
                '"COND_VALUE": "'+(mainProduct.RelatedPriceBook__r.SpecialCommission__c!=null?mainProduct.RelatedPriceBook__r.SpecialCommission__c:100.00)+'",'+
                '"CONBASEVAL": "0",'+
                '"NUMCONVERT": "0",'+
                '"DENOMINATO": "0",'+
                '"ACCESS_SEQ": "00",'+
                '"CONDCOUNT": "0.00",'+
                '"ROUNDDOFFDI": "0.00",'+
                '"CONDVALUE": " ",'+
                '"CURRENCY_2": "",'+
                '"FACTBASVAL": "0.000",'+
                '"SCALBASVAL": "0.00"'+
                '}'+
                '],'+
                '"SALES_ITEMS_IN": ['+
                '{'+
                '"ITM_NUMBER": "0010",'+
                '"HG_LV_ITEM": "00000",'+
                '"MATERIAL": "'+ mainProduct.ProductSapNumber__c +'",'+
                '"ZZMAT_STAT":  " ",'+
      			'"ZZSER_NO": " ",'+
                 FertInfo+
                '"ALTERN_TO_ITM": "0000",'+
                '"DLV_GROUP": "000",'+
                '"TARGET_QTY": "'+(DN.FKBillingCredit__c==NULL && DN.TotalLinesQuantity__c!=null?string.valueOf(DN.TotalLinesQuantity__c.setScale(3)):'1.00') +'",'+
                '"ZZALT_QTY": "'+ (dn.FinalUnitOfMeasure__c!='M3'&& DN.Dischargequantityuom__c=='M3'?string.valueof(DN.TotalLineCubeQuantity__c.setScale(3)):'') +'",'+
				'"ZZALT_UM":"'+(dn.FinalUnitOfMeasure__c!='M3'&& DN.Dischargequantityuom__c=='M3'?'M3':'')+'",'+
				'"ZZALT_PR":"'+(dn.FinalUnitOfMeasure__c!='M3'&& DN.Dischargequantityuom__c=='M3'?string.valueof(DN.TotalLineCubePrice__c.setScale(3)):'')+'",'+
                '"ZZ_PRUNT":"'+DN.TotalLinePrice__c+'",'+
				'"ZZCOMPE_QTY":"'+(DN.FKBillingCredit__c!=NULL?0:DN.TotalCreditBilling__c)+'",'+// עבור תנאי ZCPQ זיכוי כמותי 
                '"TARGET_QU": "'+(DN.FinalUnitOfMeasure__c!='EA'?DN.FinalUnitOfMeasure__c:'EA')+'",'+
                '"PRICE_DATE": "'+DN.SupplyDate__c+'",'+
				'"SERV_DATE ": "'+DN.SupplyDate__c+'",'+
				'"ZZPROPOSAL ": "'+(DN.RelatedOpportunity__c!=null?DN.RelatedOpportunity__c.replace('"','\\"'):DN.RelatedOpportunity__c)+'",'+
                '"ZZCULTIVATION": "",'+
                '"ZZCHECK": "'+DN.LabTestId__c+'",'+
				'"ZZEXEC_DATE": "'+DN.SupplyDate__c+'",'+//change this to תאריך ביצוע של הבדיקה
                '"PMNTTRMS ": "'+DN.Payment_Terms__c+'",'+
				'"ZZCIA": "",'+
                '"REF_1": "00",'+
                '"PURCH_NO_C": "0",'+
                '"REF_1_S": "0",'+
                '"ADD_VAL_DY": "0",'+
                '"TARG_QTY_NUM": "0",'+
                '"TARG_QTY_DENOM": "0",'+
                '"ROUND_DLV_DY": "0.000",'+
                '"MAX_DEVIAT_AMNT": "0.000",'+
                '"MAX_DEV_PERC": "0",'+
                '"MAX_DEV_DAYS": "0",'+
                '"OVER_DLV_TOL": "0",'+
                '"UNDER_DLV_TOL": "0",'+
                '"SALES_QTY_NUM": "0",'+
                '"SALES_QTY_DENOM": "0",'+
                '"GROSS_WEIGHT": "0",'+
                '"NET_WEIGHT": "0",'+
                '"VOLUME": "0",'+
                '"DLV_PRIO": "0",'+
                '"ORDER_PROB": "0",'+
                '"MAX_PL_DLV": "0",'+
                '"COMPANY_QUANT": "0",'+
                '"TARGET_VAL": "0",'+
                '"DEPREC_PER": "0",'+
                '"REF_DOC_IT": "0"'+
                '}'+
                '],'+
                '"SALES_PARTNERS":['+
                '{'+
                '"PARTN_ROLE": "AG",'+
                '"PARTN_NUMB": "'+(DN.TransactionType__c=='20'|| docType=='25' ?DN.loadingPointSAPNo__c:'' )+'",'+
                '"ITM_NUMBER": "0"'+
                '},'+
                '{'+
                '"PARTN_ROLE": "WE",'+
                '"PARTN_NUMB": "'+DN.AccountSap__c+'",'+
                '"ITM_NUMBER": "0"'+
                '},'+
                '{'+
                '"PARTN_ROLE": "RG",'+
                '"PARTN_NUMB": "'+DN.PayingAccountSap__c+'",'+
                '"ITM_NUMBER": "0"'+
                '},'+
                ZW+
                AgentReceivesCommission+
                ZD+
                '{'+
                '"PARTN_ROLE": "ZZ",'+
                '"PARTN_NUMB": "",'+
                '"ITM_NUMBER": "0"'+
                '}'+
                ']'+
                '}';
            Json=Json.replaceAll('null', '');
            system.debug(loggingLevel.error, 'json:'+Json);
            
        }
        return Json;
    }
    public static Delivery_Note_Staging__c createNewDNSRecord(string jsonDNS,DeliveryNote__c DN){
        Delivery_Note_Staging__c newDNS= new Delivery_Note_Staging__c();
        newDNS.DeliveryNoteStaging_Type__c='INVOICE';
        newDNS.InvoiceJSON__c=jsonDNS;
        newDNS.RelatedDeliveryNote__c=DN.Id;
        insert newDNS;
        return newDNS;
    }
    private static string setFertInfo(List<DeliveryNoteItems__c> relatedDNI, DeliveryNote__c DN){
        string fertInfo='';
        string prd1Info='';
        string prd2Info='';
        if(!relatedDNI.isEmpty()){
            for(DeliveryNoteItems__c rec:relatedDNI){
                if(rec.LineItemType__c=='7' && prd1Info=='' ){
                    prd1Info= '"ZZMAT1":"'+rec.ProductSapNumber__c+'",'+
                        '"ZZQTY1":"'+rec.TotalWeight__c+'",'+
                        '"ZZUM1":"TO",';
                }
                else if(rec.LineItemType__c=='7' && prd2Info==''){
                    prd2Info= '"ZZMAT2":"'+rec.ProductSapNumber__c+'",'+
                        '"ZZQTY2":"'+rec.TotalWeight__c+'",'+
                        '"ZZUM2":"TO",';
                }
            }
        }
        fertInfo=prd1Info+prd2Info;
        system.debug(loggingLevel.ERROR,'fertInfo:'+prd1Info+prd2Info);
        return fertInfo;
    }
     
}