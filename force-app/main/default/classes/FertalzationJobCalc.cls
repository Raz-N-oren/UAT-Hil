global class FertalzationJobCalc {
    public static Map<String, Decimal> getPriceForProduct(Product2 prod , Id accountId,Id loadingPointId) {
        Account acc = accountId!=null?PriceCalculationInfo.getAccount(accountId):null;
        Map<String, Decimal> prices = new Map<String, Decimal>();
        try{
            //price in Tonnes
            prices.put('Tonnes', priceCalculationInfo.getPrice(prod.Id, accountId, acc!=null?acc.AccountDivision__c:null, 'TO',1, loadingPointId, null, null, null));
            system.debug(loggingLevel.ERROR,'prices.get(Tonnes):'+prices.get('Tonnes'));
            if(prices.get('Tonnes') == null){ 
                prices.put('Tonnes', -1);
                prices.put('Cubes', -1);
                return prices;
            }
            //price in Cubes
            prices.put('Cubes', priceCalculationInfo.weightAmountConvert('TonneToCube', prices.get('Tonnes'), prod.specific_gravity__c,prod.TonWeightCoefficient__c));
            system.debug(loggingLevel.ERROR,'prices.get(Cubes):'+prices.get('Cubes'));
        } catch (Exception e) {
            System.debug('Error has occured in getPriceForProduct: ');
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return prices;
    }    
    
    public static Decimal convertToTonnes(string UnitOfMeasure,Decimal QuantityPerHectare, Product2 prd){
        Decimal result=1;
        string convertUnit=null;
        SWITCH ON  UnitOfMeasure {
            WHEN 'TO'{
                convertUnit='TonneToTonne';
            }
            WHEN 'EA'{
                convertUnit='EachToTonne';
            }
            WHEN 'M3'{
                convertUnit = 'CubeToTonne';
            }
            WHEN 'KG'{
                convertUnit='KiloToTonne';
            }
            WHEN 'LTR'{
                convertUnit='LiterToTonne';
            }
            WHEN ELSE{
                return 0;
            }
        }
        result = priceCalculationInfo.weightAmountConvert(convertUnit, QuantityPerHectare, prd.specific_gravity__c,prd.TonWeightCoefficient__c).setScale(10);
        return result;
    }
    
    @auraEnabled
    public static Decimal getFertPrdPriceBeforeDiscount(Id prdId,Id AccId,Id loadingPointId, Decimal QuantityPerHectare,Decimal plotTotalSize, string unitMeasure){
        system.debug(loggingLevel.ERROR,'getFertPrdPriceBeforeDiscount Params:-->prdId:'+prdId+'-->QuantityPerHectare:'+QuantityPerHectare+'-->plotTotalSize'+plotTotalSize+'-->unitMeasure:'+unitMeasure);
        
        Decimal totalPrice=0;
        Product2 prd = priceCalculationInfo.getProduct(prdId);
        Map<String, Decimal> pricingPerMeasure 	= getPriceForProduct(prd, AccId,loadingPointId);
        decimal fertPrdPrice 					= pricingPerMeasure.get('Tonnes')!=null? (convertToTonnes(unitMeasure,QuantityPerHectare,prd)*plotTotalSize*pricingPerMeasure.get('Tonnes')).setScale(2):1;
        system.debug(loggingLevel.ERROR,'fertPrdPrice calculation:'+plotTotalSize+'*'+convertToTonnes(unitMeasure,QuantityPerHectare,prd)+'*'+pricingPerMeasure.get('Tonnes')+'='+fertPrdPrice);
        if(fertPrdPrice!=null){
            totalPrice							= fertPrdPrice;
        }
        system.debug(loggingLevel.ERROR, 'getFertPrdPriceBeforeDiscount total price:'+totalPrice);

        return totalPrice;
    }
    
    @auraEnabled
    public static Decimal getFertPrdPriceAfterDiscount(Id prdId, Id accId, Decimal fertPrdPriceBeforeDisc){
        system.debug(loggingLevel.ERROR, 'getFertPrdPriceAfterDiscount params:-->prdId'+prdId+'-->accId:'+accId+'-->fertPrdPriceBeforeDisc:'+fertPrdPriceBeforeDisc);

        Product2 prd 			= priceCalculationInfo.getProduct(prdId);
        Account acc				= priceCalculationInfo.getAccount(accId);
        
        Decimal totalPrice=fertPrdPriceBeforeDisc;
        if(prd!=null && acc!=null){
            Discount__c disc	=  getProductDiscount.getDiscountRec(prd.Id, acc.Id, null, null);
            if(disc!=null){
                totalPrice 		= fertPrdPriceBeforeDisc*(1-disc.Requested_Discount__c/100);
            }
        }
        system.debug(loggingLevel.ERROR, 'getFertPrdPriceAfterDiscount total price:'+totalPrice);
        return totalPrice;
    }
    
    @auraEnabled
    public static Decimal getTotalFertJob(Id accId,Id PrdId,Id Fert1, Id Fert2,Decimal QuantityPerHectare1,string unitMeasure1, 
                                          Decimal QuantityPerHectare2,string unitMeasure2,string needCart,string costLevel,
                                          Decimal plotTotalSize,Decimal Fert1Price,Decimal Fert2Price){
                                                Decimal totalPrice=0;
                                              system.debug(loggingLevel.ERROR,'getTotalFertJob Params:-->accId'+accId+'-->prdId:'+prdId+'-->Fert1:'+Fert1+'-->Fert2:'+Fert2+'-->QuantityPerHectare1:'+QuantityPerHectare1+'-->unitMeasure1:'+unitMeasure1);
                                              system.debug(loggingLevel.ERROR,'-->QuantityPerHectare2:'+QuantityPerHectare2+'-->unitMeasure2:'+unitMeasure2+'-->plotTotalSize'+plotTotalSize+'-->costLevel:'+costLevel+'-->needCart:'+needCart);
                                              system.debug(loggingLevel.ERROR,'-->Fert1Price'+Fert1Price+'-->Fert2Price:'+Fert2Price);
                                              Product2 prd 			= priceCalculationInfo.getProduct(prdId);
                                              Product2 Fert1prd 		= priceCalculationInfo.getProduct(Fert1);
                                              Product2 Fert2prd 		= Fert2!=null?priceCalculationInfo.getProduct(Fert2):null;
                                              Decimal calcExtraAmount	= 0;
                                              Decimal calcExtraScale	= 0;
                                             try{
                                                 Decimal firstPerHectare= orderItem_CalculateInfo.calculateTotalTonWeight(QuantityPerHectare1,unitMeasure1,Fert1prd.specific_gravity__c,null);
                                                 Decimal secPerHectare	= Fert2prd!=null?orderItem_CalculateInfo.calculateTotalTonWeight(QuantityPerHectare2,unitMeasure2,Fert2prd.specific_gravity__c,null):1;
                                                 totalPrice				= Fert2Price!=null?Fert1Price+Fert2Price:Fert1Price;
                                                 decimal needCartCalc	= needCart=='Yes'?priceCalculationInfo.getPBRecord('01t25000007VsJDAA0', null, null,'TO',1, null, null, null, system.today()).Fixed_Price__c:0;
                                                 IL_Price_Book__c PB	= priceCalculationInfo.getPBRecord(prd.Id, accId, null, 'TO',1,null, null, prd.IL_Group__c, system.today());
                                                 system.debug(loggingLevel.ERROR, 'Fert Job PB:'+PB);
                                                 system.debug(loggingLevel.ERROR, 'plotTotalSize:'+plotTotalSize);
                                                                                                  system.debug(loggingLevel.ERROR, 'plotTotalSize:'+plotTotalSize);


                                                  if(PB!=null && plotTotalSize!=null){
                                                      SWITCH ON costLevel{
                                                          WHEN 'A'{
                                                              system.debug(loggingLevel.ERROR, 'PB.Scale_Price_1__c:'+PB.Scale_Price_1__c);
                                                              totalPrice 	+= plotTotalSize* (PB.Scale_Price_1__c!=null?PB.Scale_Price_1__c:1);
                                                          }
                                                          WHEN 'B'{
                                                              system.debug(loggingLevel.ERROR, 'PB.Scale_Price_2__c:'+PB.Scale_Price_2__c);
                                                              totalPrice 	+= plotTotalSize* (PB.Scale_Price_2__c!=null?PB.Scale_Price_2__c:1);
                                                          }
                                                          WHEN 'C'{                    
                                                              system.debug(loggingLevel.ERROR, 'PB.Scale_Price_3__c:'+PB.Scale_Price_3__c);
                                                              totalPrice 	+= plotTotalSize* (PB.Scale_Price_3__c!=null?PB.Scale_Price_3__c:1);
                                                          }
                                                      }
                                                      calcExtraScale(PB,Fert1prd,QuantityPerHectare1,calcExtraAmount,calcExtraScale,totalPrice);
                                                      if(Fert2prd!=null){
                                                          calcExtraScale(PB,Fert2prd,QuantityPerHectare2,calcExtraAmount,calcExtraScale,totalPrice);
                                                      }
                                                  }
                                                  totalPrice+=plotTotalSize/300*needCartCalc;
                                              }
                                              catch(Exception e){
                                                  throw new AuraHandledException('getTotalFertJob:'+  e.getMessage()  );
                                                  
                                              }
                                              return totalPrice;
                                          }   
    
    private static void  calcExtraScale(IL_Price_Book__c PB, product2 Fert, Decimal QuantityPerHectare,decimal calcExtraAmount, decimal calcExtraScale, decimal totalPrice){
        decimal extraAmount 	=0; 
        string extraSelected=null;
        if(Fert.Accumulation_state__c=='2' && PB.Second_extra_unit_of_measure__c=='LTR'||PB.Extra_unit_of_measure__c=='LTR' ){
            extraAmount=PB.Second_extra_unit_of_measure__c=='LTR'?PB.SecondExtraAmount__c:PB.Extra_amount__c;
            extraSelected=PB.Second_extra_unit_of_measure__c=='LTR'?'2':'1';
        }
        else{
            extraAmount=PB.Second_extra_unit_of_measure__c=='KG'?PB.SecondExtraAmount__c:PB.Extra_amount__c;
            extraSelected=PB.Second_extra_unit_of_measure__c=='LTR'?'2':'1';
            
        }
        if(PB.Base_amount__c!=null && extraAmount!=null ){
            calcExtraAmount			+= QuantityPerHectare-PB.Base_amount__c;
            calcExtraScale			+=calcExtraAmount>0 && extraAmount>0? calcExtraAmount/extraAmount:1;
            if(calcExtraScale>0){
                if(calcExtraScale<=1){
                    totalPrice			+= calcExtraScale*(extraSelected=='2'?pb.SecondExtraRateScale1__c :PB.Extra_rate_Scale_1__c);
                }
                else if(calcExtraScale<=2){
                    totalPrice			+= calcExtraScale*(extraSelected=='2'?pb.SecondExtraRateScale2__c :PB.Extra_rate_Scale_2__c);
                }
                else if(calcExtraScale<=3 ){
                    totalPrice			+= calcExtraScale*(extraSelected=='2'?pb.SecondExtraRateScale3__c :PB.Extra_rate_Scale_3__c);
                }      
            }
        }
        system.debug(loggingLevel.error,'calcExtraScale:totalPrice:'+totalPrice+' --calcExtraScale:'+calcExtraScale);
    }
}