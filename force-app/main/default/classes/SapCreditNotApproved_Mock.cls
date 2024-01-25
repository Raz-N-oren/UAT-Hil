@isTest
public class SapCreditNotApproved_Mock implements HttpCalloutMock {
static orderItem  OI = NEW orderItem();
    public SapCreditNotApproved_Mock(orderItem OIRecord){
        OI=OIRecord;
    }
  public HttpResponse respond( HttpRequest request  ) {
        HttpResponse response = new HttpResponse();
        String jsonBody = '{'+
                '    "credit": {'+
                '        "creditQuota": 20000.00,'+
                '        "invoiceValue": 199.25,'+
                '        "vatNum": "IL3254568",'+
                '        "termsOfPayment": ""'+
                '    },'+
                '    "orderedHazardMaterials": ['+
                '        {'+
                '            "entityNumber": "306483",'+
                '            "entityName": "'+oi.Product2.Name+'",'+
                '            "matnr": "000000009991081241",'+
                '            "maktx": "Phosphoric Acid 50%",'+
                '            "zmatnrReal": "'+oi.Product2.Sap_Number__c+'",'+
                '            "vmaktx": "PHOSPHORIC ACID 85%",'+
                '            "idperm": "40252",'+
				'            "endda": 20231027,'+
                '            "maxAmount": "0.000",'+
            	'            "yearAmount": "40.000",'+
            	'            "meins": "TON",'+
            	'            "aedat": "20230322",'+
            	'            "aenam": "GAFINGAR",'+
            	'            "puse": "0000000000",'+
            	'            "doknr": "0000000000",'+
            	'            "maxAmountD": "40.000 ",'+
            	'            "unNumber": "testDS"'+
                '        }'+
                '    ],'+
                '    "allHazardMaterialsForUser": ['+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "coordinateCatalogNum": "jhgf543513",'+
                '            "permitionNum": "abcd1234",'+
                '            "amountPerOrder": 200.50,'+
                '            "maxYearlyAmount": 25000.75,'+
                '            "unitOfMeasure": "Tonne",'+
                '            "validFromDate": "30/03/2021",'+
                '            "validTillDate": "01/11/2021"'+
                '        }'+
                '    ],'+
                '    "isStockAvailable": ['+
                '        {                   '+
                '            "productSapNum": "000000006020300019",'+
                '            "amountInTonnes": 20.25,'+
                '            "DeliveryDate": "08/08/2021",'+
                '            "approved": true'+
                '        }'+
                '    ],'+
  				'    "PurchaseOrder": ['+
   				'        {                  '+
      			'    "PurchaseOrder": ['+
      			'	   "00000912142"'+
      			'    ],'+
      			'    "Line": "00000"'+
    			'        }'+
  				'    ]'+
                '}'+
                '';
             
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response;
    }
}