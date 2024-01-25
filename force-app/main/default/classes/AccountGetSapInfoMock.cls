@isTest
public class AccountGetSapInfoMock implements HttpCalloutMock {
	
    public HttpResponse respond( HttpRequest request ) {
        HttpResponse response = new HttpResponse();
        String jsonBody = '{'+
                '    "credit": {'+
                '        "creditQuota": 20000.00,'+
                '        "invoiceValue": 1234.25,'+
                '        "vatNum": "IL3254568",'+
                '        "termsOfPayment": "SomeText"'+
                '    },'+
                '    "orderedHazardMaterials": ['+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "productSapNum": "000000006020300019",'+
                '            "amountInTonnes": 25.25,'+
                '            "approved": true'+
                '        },'+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "productSapNum": "000000006020302584",'+
                '            "amountInTonnes": 12.60,'+
                '            "approved": false '+
                '        },'+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "productSapNum": "000000006020307821",'+
                '            "amountInTonnes": 0.95,'+
                '            "approved": true'+
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
                '        },'+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "coordinateCatalogNum": "jhgf543514",'+
                '            "permitionNum": "abcd1235",'+
                '            "amountPerOrder": 200.50,'+
                '            "maxYearlyAmount": 25000.75,'+
                '            "unitOfMeasure": "Tonne",'+
                '            "validFromDate": "30/01/2021",'+
                '            "validTillDate": "01/08/2021"'+
                '        },'+
                '        {'+
                '            "userSapNum": "306483",'+
                '            "coordinateCatalogNum": "jhgf543515",'+
                '            "permitionNum": "abcd1236",'+
                '            "amountPerOrder": 200.50,'+
                '            "maxYearlyAmount": 25000.75,'+
                '            "unitOfMeasure": "Tonne",'+
                '            "validFromDate": "30/02/2021",'+
                '            "validTillDate": "01/05/2021"'+
                '        }'+
                '    ],'+
                '    "isStockAvailable": ['+
                '        {                   '+
                '            "productSapNum": "000000006020300019",'+
                '            "amountInTonnes": 20.25,'+
                '            "DeliveryDate": "08/08/2021",'+
                '            "approved": true'+
                '        },'+
                '        {                   '+
                '            "productSapNum": "000000006020307821",'+
                '            "amountInTonnes": 3.20,'+
                '            "DeliveryDate": "12/08/2021",'+
                '            "approved": false'+
                '        },'+
                '        {                   '+
                '            "productSapNum": "000000006020302584",'+
                '            "amountInTonnes": 0.70,'+
                '            "DeliveryDate": "21/08/2021",'+
                '            "approved": true'+
                '        }'+
                '    ]'+
                '}'+
                '';
        response.setBody(jsonBody);
        response.setStatusCode(200);
        return response;
    }
}