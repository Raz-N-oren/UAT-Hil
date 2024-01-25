public with sharing class AccountGetSapInfo {
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> GetAccountSapInfo(string recordId){
        
        List<Account> querySapIdRes = [SELECT Sap_Number__c FROM Account WHERE Id = :recordId];
        string accountSapId = querySapIdRes[0].Sap_Number__c;
        // Check all including 'allHazardMaterialsForUser'
        String payload =' {'+
                    '   "credit": {'+
                    '        "userSapNum": '+accountSapId+
                    '    },'+
                    '    "orderedHazardMaterials": ['+
                    '        {'+
                    '            "userSapNum": '+accountSapId+','+
                    '            "productSapNum": "000000006051560133",'+
                    '            "amountInTonnes": 25.25'+
                    '        },'+
                    '        {'+
                    '            "userSapNum": "911033",'+
                    '            "productSapNum": "000000006006430001",'+
                    '            "amountInTonnes": 12.64'+
                    '        },'+
                    '        {'+
                    '            "userSapNum": "911033",'+
                    '            "productSapNum": "000000006020307821",'+
                    '            "amountInTonnes": 0.95'+
                    '        }'+
                    '    ],'+
                    '    "allHazardMaterialsForUser": {'+
                    '        "userSapNum": "911033"'+
                    '    },'+
                    '    "isStockAvailable": ['+
                    '        {                  '+
                    '            "productSapNum": "000000006051560133",'+
                    '            "amountInTonnes": 25.5,'+
                    '            "DeliveryDate": "20190813"'+
                    '        },'+
                    '        {                   '+
                    '            "productSapNum": "000000006020307821",'+
                    '            "amountInTonnes": 3.20,'+
                    '            "DeliveryDate": "20210812"'+
                    '        },'+
                    '        {            '+
                    '            "productSapNum": "000000006006430001",'+
                    '            "amountInTonnes": 0.70,'+
                    '            "DeliveryDate": "20210821"'+
                    '        }'+
                    '    ]'+
                    '}'+
                    '';

            Token__mdt[] tokens = [SELECT Token__c, endpointForJson__c FROM Token__mdt];
            string tokenAccess = tokens[0].Token__c;
        	system.debug('token info: '+tokens[0]);
            string endpointForJson = tokens[0].endpointForJson__c;
    
            // ---- Now sending the Payload ----
            String authorizationHeader = 'Bearer ' + tokenAccess;
            
            HttpRequest sendJsonDataRequest = new HttpRequest();
            sendJsonDataRequest.setMethod('POST');
            sendJsonDataRequest.setHeader('Authorization', authorizationHeader);
            sendJsonDataRequest.setHeader('Content-Type', 'application/json');
            sendJsonDataRequest.setBody(payload);
            sendJsonDataRequest.setEndpoint(endpointForJson);
            
            Http binding2 = new Http();
            HttpResponse response2 = binding2.send(sendJsonDataRequest);
            
            String resPayload = response2.getBody();
            
            String split = resPayload.substring(resPayload.length()-3, resPayload.length()-2);
            if(split == ','){
            resPayload = resPayload.substring(0, resPayload.length()-3) + '}';
            }
        
            Map<String,Object> jsonDataResponse = (Map<String,Object>) JSON.deserializeUntyped(resPayload);
            
            return jsonDataResponse;
            }
        
        
        
            
    }