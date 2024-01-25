@isTest
public with sharing class PriceCalculation_Test {
    @isTest
    static void weightAmountConvert_Test() {
        List<String> conversionTypes = new List<String>{
            'TonneToCube',
                'CubeToTonne',
                'TonneToTonne',
                'LiterToTonne',
                'KiloToTonne'
                };
                    
                    List<Decimal> amount = new List<Decimal>{ 2.5, 3, 0.75, 200, 700 };
                        List<Decimal> expectedResults = new List<Decimal>{ 2.27, 3.3, 0.75, 0.22, 0.70 };
                            List<Decimal> results = new Decimal[conversionTypes.size()];
        Decimal productSpecificGravity = 1.1;
        
        Test.startTest();
        for (Integer i = 0; i < conversionTypes.size(); i++) {
            if (results.size() > 0 && conversionTypes.size() > 0 && amount.size() > 0) {
                results[i] = PriceCalculation.weightAmountConvert(
                    conversionTypes[i],
                    amount[i],
                    productSpecificGravity
                );
            }
        }
        Test.stopTest();
    }
    
    
    @isTest
    static void calculatePrice_Test() {
        Decimal tonneAmount = 1.25;
        
        //Create Product (not inserted in data factory)
        Product2 product = TestDataFactory_Test.createProductForTesting(1)[0];
        insert product;
        System.debug('--PriceCalculation_Test-- product: ' + product);
        
        // Create IL_Price_Book
        IL_Price_Book__c price = TestDataFactory_Test.createIlPriceBookForTesting(product.id);
        // when sending to 'calculatePrice' func shuuld be with the related product delails
        price.Product_Service__r = product;
        System.debug('--PriceCalculation_Test-- In test IL_Price_Book__c: ' + price);
        
        Decimal expectedResult = ((product.K__c * price.k__c) +
                                  (product.N__c * price.N__c) +
                                  (product.P__c * price.p__c) +
                                  (product.B__c * price.B__c) +
                                  (product.Ca__c * price.Ca__c) +
                                  (product.CL__c * price.CL__c) +
                                  (product.CO__c * price.Co__c) +
                                  (product.Fe__c * price.Fe__c) +
                                  (product.IS__c * price.IS__c) +
                                  (product.Mg__c * price.Mg__c) +
                                  (product.Mn__c * price.Mn__c) +
                                  (product.PH__c * price.Ph__c) +
                                  (product.ZN__c * price.Zn__c));
        
        Decimal result = PriceCalculation.calculatePrice(price);
        System.debug('--PriceCalculation_Test-- expectedResult: ' + expectedResult);
        System.debug('--PriceCalculation_Test-- result: ' + result);
        // System.assertEquals(expectedResult, result, 'Wrong price calculation.');
        //System.assertEquals(647, result, 'Wrong price calculation.');
    }
    
    @isTest
    static void getPrice_Test() {
        Product2 product = TestDataFactory_Test.createProductForTesting(1)[0];
        insert product;
        IL_Price_Book__c price = TestDataFactory_Test.createIlPriceBookForTesting(product.id);
        Decimal amount = 50;
        
        Decimal tatalPriceForTonnes = PriceCalculation.getPrice(product.Id, amount, 'טון');
        Decimal tatalPriceForCubes = PriceCalculation.getPrice(product.Id, amount, 'קוב');
        Decimal tatalPriceForLiters = PriceCalculation.getPrice(product.Id, amount, 'ליטר');
        Decimal tatalPriceForKilos = PriceCalculation.getPrice(product.Id, amount, 'קילו');
        
        System.debug('tatalPriceForTonnes: ' + tatalPriceForTonnes);
        System.debug('tatalPriceForCubes: ' + tatalPriceForCubes);
        System.debug('tatalPriceForLiters: ' + tatalPriceForLiters);
        System.debug('tatalPriceForKilos: ' + tatalPriceForKilos);
        /*
System.assertEquals(39850.00, tatalPriceForTonnes, 'Wrong price calculation for tonnes.');
System.assertEquals(49812.50, tatalPriceForCubes, 'Wrong price calculation for cubes.');
System.assertEquals(49.81, tatalPriceForLiters, 'Wrong price calculation for liters.');
System.assertEquals(39.85, tatalPriceForKilos, 'Wrong price calculation for kilos.');*/
    }
}