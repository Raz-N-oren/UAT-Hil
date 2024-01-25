public with sharing class SalesInformationTriggerHelper {
    public static void runOverRecords (List<Sales_Information__c> salesInfos){
        Map<String, id> productsMap = new Map<String, id>();

        Map<String, Map<String, id>> sysMap = new Map<String, Map<String, id>>();
        for(String srcSys : AccountStagingTriggerHelper.sourceSys){
            sysMap.put(srcSys, new Map<String, id>());
        }
        getExternalIds(salesInfos, sysMap, productsMap);
        connectLookups(salesInfos, sysMap, productsMap);  
    }

    private static void getExternalIds(
        List<Sales_Information__c> salesInfos,
        Map<String, Map<String, id>> sysMap,
        Map<String, id> productsMap
    ){
        // Get all external IDs for all Accounts and Products
        for(Sales_Information__c sInfo : salesInfos){
            // ILF, EVR and BKG are not really a systems change them to FER, QAD and TRK
            if(sInfo.Source_System__c == 'ILF') sInfo.Source_System__c = 'FER';
            else if(sInfo.Source_System__c == 'EVR') sInfo.Source_System__c = 'QAD';
            else if(sInfo.Source_System__c == 'BKG') sInfo.Source_System__c = 'TRK';
            else if(sInfo.Source_System__c == 'FUE') sInfo.Source_System__c = 'FNT';
            
            String accSrc = (new set<String>(AccountStagingTriggerHelper.sourceSys)).contains(sInfo.Source_System__c) ? 
                sInfo.Source_System__c : 'FER';

            if(String.isNotBlank(sInfo.Ship_To_SAP_Number__c)){
                (sysMap.get(accSrc)).put(sInfo.Ship_To_SAP_Number__c, null);
            }
            if(String.isNotBlank(sInfo.Sold_To_Sap_Number__c))
                (sysMap.get(accSrc)).put(sInfo.Sold_To_Sap_Number__c, null);
            if(String.isNotBlank(sInfo.Source_System__c) && String.isNotBlank(sInfo.Product_SAP_Nmuber__c))
                productsMap.put(sInfo.Source_System__c + sInfo.Product_SAP_Nmuber__c, null);
        }
            
        List<Account> accRec = [
            SELECT Id, AccountSource, External_Id__c, Amfert_SAP_number__c, IBP_SAP_number__c, India_Thali_Number__c,
                QAD1_sap_C__c, BRAZIL_SAP_NUMBER__c, US_SAP_NUMBER__c, lAND__c, TRK_SAP__c, Fun_erp_number__c
            FROM Account
            WHERE External_Id__c IN : (sysMap.get('FER')).keySet()
                OR Amfert_SAP_number__c IN : (sysMap.get('AMF')).keySet()
                OR IBP_SAP_number__c IN : (sysMap.get('IBP')).keySet()
                OR QAD1_sap_C__c IN : (sysMap.get('QAD')).keySet()
                OR BRAZIL_SAP_NUMBER__c IN : (sysMap.get('BRA')).keySet()
                OR US_SAP_NUMBER__c IN : (sysMap.get('PLP')).keySet()
                OR Fun_erp_number__c IN :(sysMap.get('FNT')).keySet()
                OR TRK_SAP__c IN :(sysMap.get('TRK')).keySet()
                OR lAND__c IN :(sysMap.get('E0035')).keySet()
                OR India_Thali_Number__c IN :(sysMap.get('E0228')).keySet()
        ];
        
        List<Product2> productsReq = [
            SELECT Id, External_Id__c, Source_System__c 
            FROM Product2 
            WHERE External_Id__c IN : productsMap.keySet()
        ];
        
        arrangeDataToMaps(accRec, productsReq, sysMap, productsMap);
    }

    private static void arrangeDataToMaps(
        List<Account> accRec,
        List<Product2> productsReq,
        Map<String, Map<String, id>> sysMap,
        Map<String, id> productsMap
    ){
        for(Account acc : accRec){
            if(String.isNotBlank(acc.External_Id__c))
                (sysMap.get('FER')).put(acc.External_Id__c, acc.Id);
            if(String.isNotBlank(acc.Amfert_SAP_number__c))
                (sysMap.get('AMF')).put(acc.Amfert_SAP_number__c, acc.Id);
            if(String.isNotBlank(acc.IBP_SAP_number__c))
                (sysMap.get('IBP')).put(acc.IBP_SAP_number__c, acc.Id);
            if(String.isNotBlank(acc.QAD1_sap_C__c))
                (sysMap.get('QAD')).put(acc.QAD1_sap_C__c, acc.Id);
            if(String.isNotBlank(acc.BRAZIL_SAP_NUMBER__c))
                (sysMap.get('BRA')).put(acc.BRAZIL_SAP_NUMBER__c, acc.Id);
            if(String.isNotBlank(acc.US_SAP_NUMBER__c))
                (sysMap.get('PLP')).put(acc.US_SAP_NUMBER__c, acc.Id);
            if(String.isNotBlank(acc.Fun_erp_number__c))
                (sysMap.get('FNT')).put(acc.Fun_erp_number__c, acc.Id);
            if(String.isNotBlank(acc.TRK_SAP__c))
                (sysMap.get('TRK')).put(acc.TRK_SAP__c, acc.Id);
            if(String.isNotBlank(acc.lAND__c))
                (sysMap.get('E0035')).put(acc.lAND__c, acc.Id);
            if(String.isNotBlank(acc.India_Thali_Number__c))
                (sysMap.get('E0228')).put(acc.India_Thali_Number__c, acc.Id);
        }

        for(Product2 prod : productsReq){
            productsMap.put(prod.External_Id__c, prod.Id);
        }
    }

    private static void connectLookups(
        List<Sales_Information__c> salesInfos,
        Map<String, Map<String, id>> sysMap,
        Map<String, id> productsMap
    ){        
        for(Sales_Information__c sInfo : salesInfos){
            if(String.isNotBlank(sInfo.Source_System__c)){
                String accSrc = 
                    (new set<String>(AccountStagingTriggerHelper.sourceSys)).contains(sInfo.Source_System__c) ? 
                    sInfo.Source_System__c : 'FER';

                if(String.isNotBlank(sInfo.Product_SAP_Nmuber__c))
                    sInfo.Product__c = productsMap.get(sInfo.Source_System__c + sInfo.Product_SAP_Nmuber__c);
                if(String.isNotBlank(sInfo.Ship_To_SAP_Number__c))
                    sInfo.Ship_To_Account__c = (sysMap.get(accSrc)).get(sInfo.Ship_To_SAP_Number__c);
                if(String.isNotBlank(sInfo.Sold_To_Sap_Number__c))
                    sInfo.Sold_To_Account__c = (sysMap.get(accSrc)).get(sInfo.Sold_To_Sap_Number__c);
            }
        }
    }
}