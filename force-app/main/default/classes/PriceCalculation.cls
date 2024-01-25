public with sharing class PriceCalculation {
    // func that recieves the component(product) Id, measurement unit and the amunt and returns the price
    public static Decimal getPrice(Id productId, Decimal amount, String measurementUnit){
        Product2 prod = new Product2();
        IL_Price_Book__c priceAndProd = getCompAndPrice(new List<Id>{productId}).get(productId);
        if(priceAndProd == null){
            prod = getProduct(productId);
            if(prod?.Family != null){
                priceAndProd = getFamilyPrice(prod.Family);
            }

            if(prod != null && priceAndProd != null){
                priceAndProd.Product_Service__r = prod;
            }
        }

        if(priceAndProd == null){
            return null;
        }

        Decimal amountPrice = (calculatePrice(priceAndProd) + 
            (priceAndProd.Fixed_Price__c != null ? priceAndProd.Fixed_Price__c : 0) + 
            (priceAndProd.transport__c != null ? priceAndProd.transport__c : 0)
        ).setScale(2);

        amountPrice *= amount;

        Decimal totalPriceTonne;

        switch on measurementUnit{
            when 'קוב', 'Cube' {
                totalPriceTonne = weightAmountConvert(
                    'CubeToTonne',
                    amountPrice,
                    priceAndProd.Product_Service__r.specific_gravity__c
                );
            }
            when 'ליטר', 'Liter' {
                totalPriceTonne = weightAmountConvert(
                    'LiterToTonne',
                    amountPrice,
                    priceAndProd.Product_Service__r.specific_gravity__c
                );
            }
            when 'קילו', 'Kilo' {
                totalPriceTonne = weightAmountConvert(
                    'KiloToTonne',
                    amountPrice,
                    priceAndProd.Product_Service__r.specific_gravity__c
                );
            }
            when else {
                totalPriceTonne = amountPrice;
            }
        }
        return totalPriceTonne;
    }

    // func that recieves the component (product name or id) 
    // and retrive it from DB and the related price from the price book, 
    // returns the components data and price
    public static Map<Id, IL_Price_Book__c> getCompAndPrice(List<Id> productIds){
        List<IL_Price_Book__c> pricesAndPruducts = [
            SELECT  Id, Name, Account__c, Start_Date__c, End_Date__c, Packing__c, Product_Family__c, Status__c, 
                    Fixed_Price__c, Product_Service__r.Name, k__c, N__c, p__c, B__c, Ca__c, CL__c, Co__c, Fe__c, IS__c, 
                    Mg__c, Mn__c, Ph__c, Zn__c, transport__c, Product_Service__r.K__c, Product_Service__r.N__c, 
                    Product_Service__r.P__c, Product_Service__r.B__c, Product_Service__r.Ca__c, 
                    Product_Service__r.CL__c, Product_Service__r.CO__c, Product_Service__r.Fe__c, 
                    Product_Service__r.IS__c, Product_Service__r.Mg__c, Product_Service__r.Mn__c, 
                    Product_Service__r.PH__c, Product_Service__r.ZN__c, Product_Service__r.IsActive, 
                    Product_Service__r.External_Id__c, Product_Service__r.id, Product_Service__r.Packing__c, 
                    Product_Service__r.Permit__c, Product_Service__r.Family, Product_Service__r.QuantityUnitOfMeasure, 
                    Product_Service__r.specific_gravity__c
            FROM IL_Price_Book__c
            WHERE (Status__c = 'תקף') AND (Product_Service__c  IN : productIds) AND (Account__c = null)
        ];
        System.debug(pricesAndPruducts);
        return arrangeMap(pricesAndPruducts);
    }

    public static IL_Price_Book__c getFamilyPrice(String family){
        List<IL_Price_Book__c> familyPrice = [
            SELECT Id, Name, Packing__c, Product_Family__c, Status__c, k__c, N__c, p__c, B__c, Ca__c, CL__c, Co__c, 
                Fe__c, IS__c, Mg__c, Mn__c, Ph__c, Zn__c, Fixed_Price__c, transport__c
            FROM IL_Price_Book__c
            WHERE (Status__c = 'תקף') AND (Product_Family__c  =: family)
        ];
        return familyPrice.size() > 0 ? familyPrice[0] : null;
    }

    public static Product2 getProduct(Id productId){
        List<Product2> prod = [
            SELECT Name, K__c, N__c, P__c, B__c, Ca__c, CL__c, CO__c, Fe__c, IS__c, Mg__c, Mn__c, PH__c, ZN__c,
                IsActive, External_Id__c, id, Packing__c, Permit__c, Family, QuantityUnitOfMeasure, specific_gravity__c
            FROM Product2
            WHERE id =: productId
        ];
        return prod.size() > 0 ? prod[0] : null;
    }

    private static Map<Id, IL_Price_Book__c> arrangeMap(List<IL_Price_Book__c> pricesAndPruducts){
        Map<Id, IL_Price_Book__c> productsMap = new Map<Id, IL_Price_Book__c>();
        for(IL_Price_Book__c pap : pricesAndPruducts){
            productsMap.put(pap.Product_Service__r.id, pap);
        }
        return productsMap;
    }

    // func that recieves tonne amount, comp info and its price and make the calculations, returns the final price
    public static Decimal calculatePrice(IL_Price_Book__c priceAndProd){
        // in the calculation - checking if the value is null -> assign '0' instead 
        if(priceAndProd == null){
            return null;
        }

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
            ((priceAndProd.Product_Service__r.IS__c != null ? priceAndProd.Product_Service__r.IS__c : 0) 
                * (priceAndProd.IS__c != null ? priceAndProd.IS__c : 0)) +
            ((priceAndProd.Product_Service__r.Mg__c != null ? priceAndProd.Product_Service__r.Mg__c : 0) 
                * (priceAndProd.Mg__c != null ? priceAndProd.Mg__c : 0)) + 
            ((priceAndProd.Product_Service__r.Mn__c != null ? priceAndProd.Product_Service__r.Mn__c : 0) 
                * (priceAndProd.Mn__c != null ? priceAndProd.Mn__c : 0)) + 
            ((priceAndProd.Product_Service__r.PH__c != null ? priceAndProd.Product_Service__r.Ph__c : 0) 
                * (priceAndProd.Ph__c != null ? priceAndProd.Ph__c : 0)) + 
            ((priceAndProd.Product_Service__r.ZN__c != null ? priceAndProd.Product_Service__r.Zn__c : 0) 
                * (priceAndProd.Zn__c != null ? priceAndProd.Zn__c : 0))
        ).setScale(2);

        return result;
    }

    
    // func that make the conversion between Tonne / Cube / Liter / Kilo, 
    // get conversion type, amount and product specific gravity
    // return the value after conversion
    public static Decimal weightAmountConvert(String type, Decimal amount, Decimal productSpecificGravity){
        Decimal result;
        switch on type {
            when 'TonneToCube' {
                result = amount.divide(productSpecificGravity, 2);
            }
            when 'CubeToTonne' {
                result = (amount * productSpecificGravity).setScale(2);
            }
            when 'TonneToTonne' {
                result = amount.setScale(2);
            }
            when 'LiterToTonne' {
                result = (amount * productSpecificGravity).divide(1000, 2);
            }
            when 'KiloToTonne' {
                result = amount.divide(1000, 2);
            }
        }
        return result;
    }
}