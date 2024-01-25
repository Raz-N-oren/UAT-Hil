@isTest
public class OrderProcesses_Test{
   
    
    public static final List<String> UnitOfMeasure = new List<String>{'TO', 'M3', 'EA', 'KG', 'LTR'};
        private static testMethod void OrderItemUnitOfMeasure_Test(){
            test.startTest();
            Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
            LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('ספק');
            order orderRec= TestDataFactory_Test.createOrder();
            orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id); 
            orderRec.Payer_Approval__c='123123';
            update orderRec;            
            orderItemRec.Quantity+=1;
            orderItemRec.UnitOfMeasure__c='KG';
            update orderItemRec;
            for(string uom:UnitOfMeasure){
                orderItem_CalculateInfo.calculateTotalEachWeight(orderItemRec.Quantity,uom , 1, 1);
                orderItem_CalculateInfo.calculateTotalKGWeight(orderItemRec.Quantity, uom , 1, 1);
                orderItem_CalculateInfo.calculateTotalLTRWeight(orderItemRec.Quantity, uom , 1, 1);
                orderItem_CalculateInfo.calculateTotalTonWeight(orderItemRec.Quantity, uom , 1, 1);
            }
            test.stopTest();
        }
    
      private static testMethod void OrderSupplier_Test(){
            test.startTest();
            Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
            LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('ספק');
            
            order orderRec= TestDataFactory_Test.createOrder();
            orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id); 
            orderRec.Payer_Approval__c='123123';
            update orderRec;            
            orderItemRec.Quantity+=1;
            orderItemRec.UnitOfMeasure__c='KG';
           // update orderItemRec;
         	Test.setMock(HttpCalloutMock.class, new SapCreditNotApproved_Mock(orderItemRec));
            orderRec.triggerProcessor__c=true;
           // update orderRec;
            test.stopTest();
        }

    private static testMethod void OrderStatusChanges_Test(){
        GeneralInterfaceData__mdt check  = [SELECT DeveloperName,ActivateHazardMaterial__c,ActivateCreditCheck__c FROM GeneralInterfaceData__mdt  WHERE MasterLabel='Order'];
        system.debug(loggingLevel.ERROR, 'check:'+check.ActivateHazardMaterial__c+'-->'+check.ActivateCreditCheck__c);
        test.startTest();
          test.setMock(HttpCalloutMock.class, new TankInterfaceMock());
          Product_hierarchy__c ph= TestDataFactory_Test.createMasterProducthierarchy();
          LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('מחסן קונסיגנציה');
          order orderRec= TestDataFactory_Test.createOrder();
          orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,ph.Id, LP.Id);
          orderRec.Status='10';
          orderRec.TransactionType__c='50';
          orderRec.Payer_Approval__c='123123';
          update orderRec; 
          test.stopTest();
          order testData = [SELECT Id,Status FROM Order WHERE Id=:orderRec.Id];
         // system.assertEquals('30', testData.Status,'Status not מאושר');
      } 
    
    private static testmethod void recieveOrderItemInfoHovalot(){
        OrderItem OI = TestDataFactory_Test.createOrderItemWithAllDependenciesForTesting();
        Map<Id,OrderItem> orderItemMap = new Map<Id,OrderItem>();
        OrderStaging__c hovalotUpdateLine= new OrderStaging__c();
		hovalotUpdateLine.OrderItemId__c =OI.Id;
        hovalotUpdateLine.Truck_code__c='082';
        hovalotUpdateLine.DeliveryDate__c=system.today()+3;
        hovalotUpdateLine.LineNumber__c='85';
        hovalotUpdateLine.NumberOfPoint__c='1';
        hovalotUpdateLine.PointStatus__c ='1';
        hovalotUpdateLine.PointIndex__c='95661';
        insert hovalotUpdateLine;
        
        
        
        OrderStaging__c os= new OrderStaging__c();
        os.Order__c=OI.OrderId;
        os.CreditResponse__c= '{'+
                '    "credit": {'+
                '        "creditQuota": 20000.00,'+
                '        "invoiceValue": 19999.25,'+
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
        os.OrderJSON__c='{"Order":{"Note_for_discharge__c":"","Regular_note_to_the_driver__c":"","description__c":"","Sap_Number__c":"913099","Agronom__c":"שני אלגרבלי","settlementCode__c":"6500","Comments__c":"","Status__c":"30","RequestedSupplyDate__c":"2023-03-10T00:00:00.000+00:00","PassingPermit__c":"","OrderConfirmation__c":"8585","OrderNumber":"00002285","Id":"80125000002x9XXAAY","ActionType__c":"20","Env":"qa"},"RelatedContacts":[{"Id":"0032500001h38xrAAA","Phone":"","MobilePhone":"231561546156","Name":"ד ד"}],"OrderLineItems":[{"sap_number__c":"'+oi.Product2.Sap_Number__c+'","ProductCode":"","Extension_Unit_3__c":"","Extension_Quantity_3__c":"","Extension_Code_3__c":"","Extension_ProductCode3__c":"","Extension_Unit_2__c":"","Extension_Quantity_2__c":"","Extension_Code_2__c":"","Extension_ProductCode2__c":"","Extension_Unit_1__c":"","Extension_Quantity_1__c":"","Extension_Code_1__c":"","Extension_ProductCode1__c":"","RelatedContactPhone__c":"","RelatedContactName__c":"","Comment__c":"","OrderId":"80125000002x9XXAAY","LoadingPoint__c":"2015","combined_Packaging__c":"false","RefuelingTransport__c":"false","A_large_vehicle_entered__c":"false","TaxiTransport__c":"false","PrivateTransport__c":"false","DischargeLocation__c":"a0U250000055GJLEA2","TotalQuantityInCubic__c":"10.00","TotalTonWeight__c":"10.00","Quantity":"10.00","UnitOfMeasure__c":"M3","OriginalDeliveryNote__c":"","PurchaseOrderLineItemNumber__c":"0019303909","PurchaseOrderNumber__c":"0019303909","Status__c":"20","OrderItemNumber":"0000002489","Id":"'+oi.Id+'","TransactionType__c":"90","ActionType__c":"20"}]}';
        insert os;      
        test.startTest();
        OrderStagingUpdateCreditResponse.validateAccountApprovedSAP(os,orderItemMap);
        update os;
        os.DangerousSubstanceNotApproved__c=true;
        OrderStagingUpdateCreditResponse.validateAccountApprovedSAP(os,orderItemMap);
        update os;
        
        test.stopTest();
    }
     private static testmethod void checkCreditResponse_test(){
         test.startTest();
         test.setMock(HttpCalloutMock.class, new TankInterfaceMock());
         LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('מחסן קונסיגנציה');
         order orderRec= TestDataFactory_Test.createOrder();
         orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,null, LP.Id);
         orderRec.Status='10';
         orderRec.TransactionType__c='30';
         orderRec.Payer_Approval__c='123123';
         update orderRec; 
         Test.setMock(HttpCalloutMock.class, new SapCreditNotApproved_Mock(orderItemRec));
         orderRec.triggerProcessor__c=true;
         test.stopTest();
     }
      private static testmethod void returnOrder_test(){
                 test.startTest();

         test.setMock(HttpCalloutMock.class, new TankInterfaceMock());
          
         LoadingPoint__c LP= TestDataFactory_Test.createLoadingPoint('מחסן קונסיגנציה');
          order orderRec= TestDataFactory_Test.createOrder();
          
          orderItem orderItemRec= TestDataFactory_Test.createOrderItem(orderRec,null, LP.Id);
          Test.setMock(HttpCalloutMock.class, new SapCreditNotApproved_Mock(orderItemRec));

          orderRec.Status='10';
          orderRec.TransactionType__c='40';
          orderRec.Payer_Approval__c='123123';
          update orderRec; 
         test.stopTest();
     }
}