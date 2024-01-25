public class BillingCredit_RelatedDNInfo {
    private set<Id> dnIds= new set<Id>();
    private Map<Id,DeliveryNote__c> relatedDNs= new Map<Id,DeliveryNote__c>();
    
    public BillingCredit_RelatedDNInfo(){
        getRelatedDNInfo();
        setTotalPricing();
    }
    
    @auraEnabled
    public static string checkTotalCreditForDN(Id DN, decimal quantity , string  unitOfMeasure, decimal amount){
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: DN:'+DN+'  quantity:'+quantity+'   unitOfMeasure:'+unitOfMeasure+'  amount:'+amount);
        string errorMsg 							= null;
        decimal totalcredit 						= 0;
        decimal productPrice						= 0;
        decimal newCredit							= 0;
        Decimal totalDis							= 0;
        Decimal totalQuantity						= 0;
        Decimal totalAmount							= 0;
        Decimal usedCredit							= 0;
        if(DN!=null ){        
            List<DeliveryNote__c>  DNrec 			= new List<DeliveryNote__c>([SELECT Id,TotalPriceBeforeDiscount__c,TotalPriceAfterDiscount__c,Name
                                                                                 ,DischargeQuantity__c,TotalLinesDiscount__c,
                                                                                 totalCreditBillingValue__c,TotalCreditBilling__c,TotalLinePrice__c,TotalLinesQuantity__c, 
                                                                                 (SELECT Id,product__c,FK_ProductDiscount__c,ProductSpecificGravity__c FROM Delivery_Note_Line_Items__r where LineItemType__c='1')
                                                                                 FROM DeliveryNote__c 
                                                                                 WHERE Id=:DN]);
            
            DeliveryNoteItems__c mainProduct = new DeliveryNoteItems__c();
            
            for(DeliveryNote__c rec:DNrec){
                for(DeliveryNoteItems__c DNI:rec.Delivery_Note_Line_Items__r){
                    mainProduct=DNI;
                }
                
            }
            
            List<Discount__c> DisRec				= mainProduct!=null && mainProduct.FK_ProductDiscount__c!=null? new List<Discount__c>([SELECT Max_Discount__c FROM Discount__c WHERE Id=:mainProduct.FK_ProductDiscount__c]):null;
            if( DNrec[0]!=null){
                
                productPrice						= DNrec[0].TotalLinePrice__c;
                AggregateResult[] groupedResults 	= [SELECT SUM(Sum__c)sumAmount,SUM(TotalWeight__c)sumQuantity FROM Billing_Credit__c WHERE Delivery_Note__c=:DN];
                totalAmount							= (Decimal)groupedResults[0].get('sumAmount')!=null?(Decimal)groupedResults[0].get('sumAmount'):0;    
                totalQuantity						= (Decimal)groupedResults[0].get('sumQuantity')!=null?(Decimal)groupedResults[0].get('sumQuantity'):0;   
                if(DNrec[0].TotalPriceBeforeDiscount__c>0 && DNrec[0].TotalPriceAfterDiscount__c>0  && amount>0){
                    totalDis 						= ((DNrec[0].TotalPriceBeforeDiscount__c-DNrec[0].TotalPriceAfterDiscount__c + totalAmount+amount)/ DNrec[0].TotalPriceBeforeDiscount__c)*100;
                }
                totalcredit 						= amount>0?(totalAmount+(totalQuantity*DNrec[0].TotalLinePrice__c)):(totalAmount+(totalQuantity*DNrec[0].TotalLinePrice__c))/DNrec[0].TotalLinePrice__c;
                newCredit							= amount>0?amount:quantity;
                system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalQuantity:'+totalQuantity+'productPrice:'+productPrice+'  totalAmount:'+totalAmount+'  totalDis:'+totalDis);
                system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalcredit:'+totalcredit+'  newCredit:'+newCredit);
                
            }
            decimal totalDNAvailableCredit 				= amount>0?DNrec[0].TotalPriceAfterDiscount__c-totalcredit:DNrec[0].TotalLinesQuantity__c-totalcredit;
            if(totalDNAvailableCredit<newCredit){
                system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalDNAvailableCredit:'+totalDNAvailableCredit+'  totalcredit:'+totalcredit+' left credit:'+totalDNAvailableCredit);
                errorMsg='You have exceeded the amount of credit in Delivery Note '+DNrec[0].Name+', the Max credit allowed is:'+totalDNAvailableCredit;
                return errorMsg;
            }
            if(DisRec!=null && !DisRec.isEmpty() && DisRec[0]!=null ){
                errorMsg = DisRec[0].Max_Discount__c<totalDis? label.Exceeded_Discount:errorMsg;
            }
            if(DNrec!=null &&  !DNrec.isEmpty() && DNrec[0]!=null  && DNrec[0].DischargeQuantity__c<totalQuantity){
                errorMsg = errorMsg!=null?'\n' +label.Exceeded_Quantity:label.Exceeded_Quantity;
            }
            if(DNrec!=null &&  DisRec!=null &&!DisRec.isEmpty() && DNrec[0]!=null && DNrec[0].TotalPriceAfterDiscount__c<totalAmount){
                errorMsg = errorMsg!=null?'\n' +label.Exceeded_Amount:label.Exceeded_Amount;
            }
        } 
        
        return errorMsg;
    }

    
    
    @auraEnabled
    public static DeliveryNoteItems__c  getRelatedItem(string dnId,string prodId){
        List<DeliveryNoteItems__c> getItems =[SELECT  UnitOfMeasure__c FROM DeliveryNoteItems__c WHERE Product__c=:prodId  AND DeliveryNote__c=:dnId];
        return !getItems.isEmpty()?getItems[0]:null;
        
    }
    @auraEnabled
    public static decimal getTotalCredit(Id DN){
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: DN:'+DN);
        Decimal totalQuantity						= 0;
        Decimal totalAmount							= 0;
        Decimal totalCalculate						= 0;
        Decimal totalCredit							= 0; 
        AggregateResult[] groupedReturnDNResults 	= [SELECT SUM(TotalPriceAfterDiscount__c)sumAmount FROM DeliveryNote__c WHERE RelatedDeliveryNote__c=:DN AND billingDoc__c!=null];
		Decimal totalReturnDNsAmount 				=(Decimal)groupedReturnDNResults[0].get('sumAmount')!=null?(Decimal)groupedReturnDNResults[0].get('sumAmount'):0;
        AggregateResult[] groupedCreditResults 		= [SELECT SUM(Sum__c)sumAmount,SUM(TotalWeight__c)sumQuantity,SUM(TotalCredit__c)totalCredit FROM Billing_Credit__c WHERE Delivery_Note__c=:DN];
        totalAmount									= (Decimal)groupedCreditResults[0].get('sumAmount')!=null?(Decimal)groupedCreditResults[0].get('sumAmount'):0;    
        totalQuantity								= (Decimal)groupedCreditResults[0].get('sumQuantity')!=null?(Decimal)groupedCreditResults[0].get('sumQuantity'):0;   
        totalCredit									= (Decimal)groupedCreditResults[0].get('totalCredit')!=null?(Decimal)groupedCreditResults[0].get('totalCredit'):0;
        totalCalculate								= totalReturnDNsAmount+(totalCredit<0?totalCredit*-1:totalCredit);
        
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalQuantity:'+totalQuantity);
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalCredit:'+totalCredit);
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalReturnDNsAmount:'+totalReturnDNsAmount);
        system.debug(loggingLevel.ERROR,'checkTotalCreditForDN: totalcredit:'+totalCalculate);           
        
        return (totalCalculate<0?totalCalculate*-1:totalCalculate).setScale(2);
    }
    
    @auraEnabled
    public static decimal getTotalDiscount(Id dnId){
        system.debug(loggingLevel.ERROR,'getTotalDiscount: DN:'+dnId);
        Decimal totalCredit							= 0; 
        AggregateResult[] groupedCreditResults 		= [SELECT SUM(Sum__c)sumAmount,SUM(TotalCredit__c)totalCredit 
                                                       FROM Billing_Credit__c 
                                                       WHERE Delivery_Note__c=:dnId 
                                                       AND Reason__c='פיצוי הנחה'];
        totalCredit									= (Decimal)groupedCreditResults[0].get('totalCredit')!=null?(Decimal)groupedCreditResults[0].get('totalCredit'):0;
        totalCredit									= totalCredit>0?totalCredit:-1*totalCredit;
        system.debug(loggingLevel.ERROR,'getTotalDiscount: totalCredit:'+totalCredit);
        return totalCredit.setScale(2);
    }
    
     @auraEnabled
    public static List<Decimal> getTotalreturnDN(Id DN){
        List<Decimal> relatedInfo= new    List<Decimal>();
        system.debug(loggingLevel.ERROR,'getTotalreturnDN: DN:'+DN);
        AggregateResult[] groupedReturnDNResults 	= [SELECT SUM(TotalPriceAfterDiscount__c)sumAmount ,SUM(TotalLinesQuantity__c)sumQuantity FROM DeliveryNote__c WHERE RelatedDeliveryNote__c=:DN AND billingDoc__c!=null];
        Decimal totalReturnDNsAmount 				= (Decimal)groupedReturnDNResults[0].get('sumAmount')!=null?(Decimal)groupedReturnDNResults[0].get('sumAmount'):0;
        Decimal totalReturnDNsQuantity 				= (Decimal)groupedReturnDNResults[0].get('sumQuantity')!=null?(Decimal)groupedReturnDNResults[0].get('sumQuantity'):0;
        relatedInfo.add(totalReturnDNsAmount);
        relatedInfo.add(totalReturnDNsQuantity);
        system.debug(loggingLevel.ERROR,'getTotalreturnDN: relatedInfo:'+relatedInfo);
        system.debug(loggingLevel.ERROR,'getTotalreturnDN: totalReturnDNsAmount:'+totalReturnDNsAmount);
        return relatedInfo;
    }
    
    @auraEnabled
    public static DeliveryNote__c getRelatedDNInformation(string DN){
        system.debug(loggingLevel.error,'getRelatedDNInfo:'+DN);
        DeliveryNote__c  relatedDN = new  DeliveryNote__c();
        List<DeliveryNote__c> relatedDNs  = [SELECT Product__C,Product__r.name,Account__r.name,TotalPriceBeforeDiscount__c,
                                             Account__c,Account__r.AccountDivision__c,BillingDoc__c,delivery_cost__c,order__r.TransactionType__c,
                                             DeliveryCostAfterDiscount__c,Delivery_discount__c,DeliveryDiscountAmount__c,FinalUnitOfMeasure__c,
                                             PayingAccount__c,PayingAccount__r.name,IntermediaryWarehouseName__c,TotalPriceDiscount__c,
                                             IntermediaryWarehouseId__c,TotalLinePrice__c,TotalLinesDiscount__c, TotalLinePriceAfterDiscount__c,
                                             TotalPriceAfterDiscount__c,TotalLinesQuantity__c FROM DeliveryNote__c WHERE ID =:DN];
        relatedDN = !relatedDNs.isEmpty()?relatedDNs[0]:null;
        system.debug(loggingLevel.error,'getRelatedDNInfo-->relatedDN:'+relatedDN);

        return relatedDN;
    }

    
    public void getRelatedDNInfo(){
        for(Billing_Credit__c rec:(List<Billing_Credit__c>)trigger.New){
            dnIds.add(rec.Delivery_Note__c);
        }
        if(!dnIds.isEmpty()){
            relatedDNs= new Map<Id,DeliveryNote__c>([SELECT Id, Account__r.AccountDivision__c,LoadingPoint__c,TotalLinePrice__c,
                                                     InvoiceDate__c,Product__r.IL_Group__c,Product__r.specific_gravity__c,TotalPriceAfterDiscount__c,
                                                     OrderItem__r.TransportType__c
                                                     
                                                     FROM DeliveryNote__c 
                                                     WHERE ID IN:dnIds]);
        } 
    }
    
    public void setTotalPricing(){
        for(Billing_Credit__c rec:(List<Billing_Credit__c>)trigger.New){
            decimal pricing=0;
            system.debug(loggingLevel.error, 'billing rec:'+rec);
            decimal total=null;
            if(rec.Quantity__c>0){
                rec.Sum__c=null;
                if(relatedDNs.get(rec.Delivery_Note__c)!=null){
                    DeliveryNote__c DN = relatedDNs.get(rec.Delivery_Note__c);
                    List<Case> relatedCases = [select Id,Delivery_Note__c FROM Case WHERE Delivery_Note__c=:rec.Delivery_Note__c];
                    rec.RelatedCase__c = !relatedCases.isEmpty()?relatedCases[0].Id:null;
                    rec.TotalWeight__c= orderItem_CalculateInfo.calculateTotalTonWeight(rec.Quantity__c,rec.Unit_of_measure__c,DN.Product__r.specific_gravity__c,null);
                    system.debug(loggingLevel.ERROR, 'credit rec TotalWeight__c:'+rec.TotalWeight__c);
                    total	= rec.TotalCredit__c ;
	
                }
                else{
                    product2 pr= priceCalculationInfo.getProduct(rec.Product__c);
                    rec.TotalWeight__c= orderItem_CalculateInfo.calculateTotalTonWeight(rec.Quantity__c,rec.Unit_of_measure__c,pr.specific_gravity__c,null);
                    total=rec.TotalPBPrice__c!=null?rec.TotalPBPrice__c:0;
                }
                
                system.debug(loggingLevel.ERROR, 'pricing:'+pricing);
            }
            else if(rec.Sum__c!=null){
                total	= rec.Sum__c;
                system.debug(loggingLevel.error, 'billing Sum__c:'+rec.Sum__c);
                if(rec.Reason__c=='פיצוי הנחה' && rec.Delivery_Note__c!=null){
                    decimal existingDic=  getTotalDiscount(rec.Delivery_Note__c);
                    Discount_matrix_Line__c DML = discountDetailsController.getMatrixLineInfo(rec.Account__c,rec.Product__c,null);
                    rec.DiscountmatrixLine__c =DML!=null?DML.Id:null;
                }
            }
            
            rec.TotalCredit__c=rec.Action_Type__c!='50' && total!=null?-1*total:total; 
        }
    }
}