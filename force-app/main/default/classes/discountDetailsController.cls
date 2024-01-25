public with sharing class discountDetailsController {
    @AuraEnabled(cacheable=true)
    public static Discount_matrix_Line__c getMatrixLineInfo(string accId, string prodId, string family) {
        System.debug(logginglevel.ERROR,'getMatrixLineInfo: Account ID - ' + accId + ', Product ID - ' + prodId + ', Family - ' + family);

        Discount_matrix_Line__c disMatLine; 
        String prodFamily;
        List<Account> acc;
        List<Product2> prod;
        List<Product_Group_Category__c> category;
        try {
            if (accId != null && (prodId != null || family != null)) {
                acc = [
                    SELECT Classification__c, Setelment__c, Setelment__r.Form_of_settlement__c
                    FROM Account
                    WHERE id = :accId
                ];
                
                if (prodId != null) {
                    prod = [SELECT IL_Group__c FROM Product2 WHERE id = :prodId];
                    if (prod.size() > 0) {
                        prodFamily = prod[0].IL_Group__c;
                    }
                }
                if (prodFamily != null) {
                    category = [
                        SELECT Product_Family_Category__c
                        FROM Product_Group_Category__c
                        WHERE Product_hierarchy_New__r.External_ID__c = :prodFamily
                    ];
                }
                if (family != null) {
                    List<Product_hierarchy__c> getGroupFamily = [SELECT Group__c FROM Product_hierarchy__c WHERE Id=:family];
                    if(getGroupFamily[0]!=null){
                        category = [
                            SELECT Product_Family_Category__c
                            FROM Product_Group_Category__c
                            WHERE Product_hierarchy_New__r.External_ID__c = :getGroupFamily[0].Group__c
                        ];
                    }
                }
                if (category != null && category.size() > 0 && String.isNotBlank(acc[0].Classification__c)) {
                    disMatLine = [
                        SELECT
                            Id,
                            Name,
                            Customer_Size__c,
                            Discount_Matrix__c,
                            Discount_Matrix_Status__c,
                            Max_Discount__c,
                            Target_Discount__c,
                            Parent_Status__c,
                            Product_Family__c
                        FROM Discount_matrix_Line__c
                        WHERE
                            Customer_Size__c = :acc[0].Classification__c
                            AND Product_Family__c = :category[0].Product_Family_Category__c
                            AND Discount_Matrix_Status__c = 'תקף'
                    ];
                }
                if (
                    acc[0]?.Setelment__r?.Form_of_settlement__c != null && acc[0].Setelment__r.Form_of_settlement__c == '1' ) {
                    disMatLine.Max_Discount__c = integer.valueof(disMatLine.Max_Discount__c) + 2;
                }
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage()+ '-' );
        }
        System.debug(disMatLine);

        return disMatLine;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getPriceForProduct(Id productId, Id accountId ) {
        Product2 prod = PriceCalculationInfo.getProduct(productId);
        Account acc = accountId!=null?PriceCalculationInfo.getAccount(accountId):null;

        Map<String, Decimal> prices = new Map<String, Decimal>();
        try {
            prices.put('Tonnes', -1);
            prices.put('Cubes', -1);
            decimal priceForTon 	= priceCalculationInfo.getPrice(productId, accountId, acc!=null?acc.AccountDivision__c:null, 'TO',1, null, null, null, null);
            decimal priceForCube 	= priceCalculationInfo.convertAmountToUnitOfMeasure('M3', 'TO', priceForTon, prod.specific_gravity__c,prod.TonWeightCoefficient__c);
            /* price in Tonnes*/
            prices.put('Tonnes', (priceForTon!=null?priceForTon:-1));
            /* price in Cubes*/
            prices.put('Cubes', (priceForCube!=NULL?priceForCube:-1));
            
            system.debug(loggingLevel.ERROR,'prices.get(Tonnes):'+prices.get('Tonnes'));
            system.debug(loggingLevel.ERROR,'prices.get(Cubes):'+priceForCube);


        } catch (Exception e) {
            System.debug('Error has occured in getPriceForProduct: ');
            System.debug(e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return prices;
    }
   
    @AuraEnabled
    public static List<Account> getProductDiscountRange(String accId){
      return [SELECT Classification__c FROM Account WHERE Id = :accId];
    }
    
    @AuraEnabled
    public static List<Product2> getProductGravity(Id prodId){
      return [SELECT specific_gravity__c FROM Product2 WHERE Id = :prodId];
    }


    @AuraEnabled
    public static List<Account> getProductFamilyDiscountRange(String accId){
      return [SELECT Classification__c FROM Account WHERE Id = :accId];
    }

    @AuraEnabled
    public static List<Account> getAccountClassification(String accId){
      return [SELECT Classification__c FROM Account WHERE Id = :accId];
    }

    @AuraEnabled
    public static List<Discount__c> getRequestedDiscount(Id accId, Id prodId){
        
      return [SELECT Requested_Discount__c FROM Discount__c WHERE Account__r.Id = :accId AND Product__r.Id = :prodId];
    }

}