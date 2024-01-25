public with sharing class ProductStagingTriggerHelper {
  @future
  public static void upsertRecords(Set<Id> productStagingId) {

    List<Product2> productsToUpsert = new List<Product2>();
    List<Product_Staging__c> productsStagesToUpdate = new List<Product_Staging__c>();
    List<PricebookEntry> pricebookEntriesToinsert = new List<PricebookEntry>();


    
    for (List<Product_Staging__c> proStageList : [
      SELECT
        Id,
        Active__c,
        Status__c,
        Product_Description__c,
        Product_Name__c,
        Sap_Number__c,
        Sensitive_product__c,
        Print_only_at_full_price_list__c,
        Unit_of_measure__c,
        specific_gravity__c,
        Toxic_substance__c,
        dangerous_substance__c,
        Quantity_without_permit_inspection__c,
        Quantity_without_inspection_of_HOMS_lice__c,
        Permit__c,
        N__c,
        P__c,
        K__c,
        Ca__c,
        Co__c,
        Fe__c,
        IS__c,
        Mg__c,
        Mn__c,
        PH__c,
        XX__c,
        ZN__c,
        B__c,
        CL__c,
        Place_Holder_1__c,
        Place_Holder_2__c,
        Place_Holder_3__c,
        Place_Holder_4__c,
        Extension_1__c,
        Extension_2__c,
        Extension_3__c,
        Extension_4__c,
        Extension_5__c,
        Extension_6__c,
        Extension_7__c,
        Extension_8__c,
        Global_Division__c,
        Global_Prod_Family__c,
        Global_Product_Group__c,
        Global_Product_Type__c,
        Origin__c,
        Packing__c,
        Storage_sites__c,
        Product_hierarchy__c,
        Source_System__c,
        External_ID__c,
        Master_product__c,
        UN_number__c,
        Dingers_Good__c,
        Green__c,
        Quantity_in_surface__c,
        Product_Type__c,
        CurrencyIsoCode,
        Accumulation_state__c,
        New_Division_F__c,
        Production_Site__c,
        Production_Site_Text__c
        
              FROM Product_Staging__c
      WHERE Id IN :productStagingId
    ]) {

      for (Product_Staging__c proStage : proStageList) {
          system.debug(loggingLevel.ERROR,'proStage.Source_System__c:'+proStage.Source_System__c);
          if(proStage.Source_System__c=='FER'||proStage.Source_System__c=='ILF'){/// Lilach modified it
              proStage.CurrencyIsoCode='ILS';
              system.debug(loggingLevel.ERROR,'proStage.CurrencyIsoCode:'+proStage.CurrencyIsoCode);

          }
        addToProducts(proStage,productsToUpsert);
      }



    }


    if (!productsToUpsert.isEmpty()) {
      processProductsUpsert(productsToUpsert, pricebookEntriesToinsert, productsStagesToUpdate);
    }

    if (!pricebookEntriesToinsert.isEmpty()) {
      insert pricebookEntriesToinsert;
    }
    
    if (!productsStagesToUpdate.isEmpty()) {
      update productsStagesToUpdate;
    }
  }

  private static void processProductsUpsert(List<Product2> productsToUpsert, List<PricebookEntry> pricebookEntriesToinsert, List<Product_Staging__c> productsStagesToUpdate) {
    
    Database.UpsertResult[] upsertResult = Database.upsert(productsToUpsert, Product2.External_ID__c , false);
    String stdPriceBookId ='';
    for (Pricebook2 pb : [select id, name from Pricebook2 where isStandard = true] ){
      stdPriceBookId = pb.Id;
    }
    
    for (Integer i = 0; i < upsertResult.size(); i++) {
      Product_Staging__c proStage = new Product_Staging__c(
        Id = productsToUpsert[i].ProductStageId__c
      );
      if (upsertResult[i].isSuccess()) {
        proStage.Status__c = 'Success';
        
        if(upsertResult[i].isCreated()){
          addToPricebookEntries(productsToUpsert[i], stdPriceBookId, pricebookEntriesToinsert);
        }

      } else {
        proStage.Error_Message__c='';
        for (Database.Error er : upsertResult[i].getErrors()) {
          proStage.Error_Message__c += er.getMessage() + ' ';
          proStage.Status__c = 'Error';
        }
      }

      productsStagesToUpdate.add(proStage);
    }
  }


  private static void addToPricebookEntries(
    Product2 product,
    String stdPriceBookId,
    List<PricebookEntry> pricebookEntriesToinsert
  ) {

    PricebookEntry priceBookE = new PricebookEntry();
    priceBookE.Product2Id = product.Id;
    priceBookE.UnitPrice = 0;
    priceBookE.Pricebook2Id = stdPriceBookId;
    priceBookE.CurrencyIsoCode=product.CurrencyIsoCode;
      system.debug(loggingLevel.Error,'priceBookE.CurrencyIsoCode:'+priceBookE.CurrencyIsoCode);
    priceBookE.IsActive = TRUE;

    pricebookEntriesToinsert.add(priceBookE);

  }

  private static void addToProducts(
    Product_Staging__c proStage,
    List<Product2> productsToUpsert
  ) {
      Product2 masterProduct;
      Product2 ex1;
      Product2 ex2;
      Product2 ex3;
      Product2 ex4;
      Product2 ex5;
      Product2 ex6;
      Product2 ex7;
      Product2 ex8;
      Packing__c packing;
      string extantion1; 
      string extantion2; 
      string extantion3; 
	  proStage.Source_System__c=proStage.Source_System__c=='ILF'?'FER':proStage.Source_System__c;/// Lilach modified it
      
   //   if (proStage.Master_product__c!=null)
  //    { masterProduct = new Product2(External_ID__c = proStage.Source_System__c + proStage.Master_product__c);}
      if (proStage.Extension_1__c!=null)
      { ex1 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_1__c);
       system.debug(loggingLevel.ERROR,'ex1:'+ex1+ 'External Id:'+proStage.Source_System__c + proStage.Extension_1__c);}
      if (proStage.Extension_2__c!=null)
      {ex2 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_2__c);}
      if (proStage.Extension_3__c!=null)
      {ex3 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_3__c);}
      if (proStage.Extension_4__c!=null)
      {ex4 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_4__c);}
      if (proStage.Extension_5__c!=null)
      {ex5 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_5__c);}
      if(proStage.Extension_6__c!=null)
      {ex6 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_6__c);}
      if (proStage.Extension_7__c!=null)
      {ex7 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_7__c);}
      if (proStage.Extension_8__c!=null)
      {ex8 = new Product2(External_ID__c = proStage.Source_System__c + proStage.Extension_8__c);}
    if (proStage.Packing__c!=null)
    {packing = new Packing__c(SAP_Number__c = proStage.Packing__c);}

      Product2 pro = new Product2();

     // Add a field For Ratio - take N P K fields and find the מכנה משותף הכי נמוך ואז לחלק את כל המספרים בו 
    //  לדוגמה 3-9-3 יהיה 1-3-1 כי 3 הוא המכנה המשותף 

      pro.IsActive = proStage.Active__c;   
      pro.External_ID__c = proStage.External_ID__c;   
      if (proStage.Source_System__c=='FER'){
          pro.Name = proStage.Product_Description__c;  
      }else{
           pro.Name = proStage.Product_Name__c;   
        }
      pro.CurrencyIsoCode =proStage.CurrencyIsoCode;
      pro.Description = proStage.Product_Description__c;   
      pro.Master_product__r = masterProduct;   
      pro.Extension_1__r = ex1!=null?ex1:null;   
      pro.Extension_2__r = ex2!=null?ex2:null;     
      pro.Extension_3__r = ex3!=null?ex3:null;  
      pro.Extension_4__r = ex4!=null?ex4:null;    
      pro.Extension_5__r = ex5!=null?ex5:null;     
      pro.Extension_6__r = ex6!=null?ex6:null;     
      pro.Extension_7__r = ex7!=null?ex7:null;     
      pro.Extension_8__r = ex8!=null?ex8:null;             
    //  pro.Packing__r = packing;   
      pro.Sap_Number__c = proStage.Sap_Number__c.replaceFirst('^0+', '');   
      pro.Sensitive_product__c = proStage.Sensitive_product__c;   
      pro.Print_only_at_full_price_list__c = proStage.Print_only_at_full_price_list__c;   
      pro.QuantityUnitOfMeasure = proStage.Unit_of_measure__c;   
      pro.Product_hierarchy_Code__c= proStage.Product_hierarchy__c;
      pro.Quantity_in_surface__c = proStage.Quantity_in_surface__c;
      pro.Green__c = proStage.Green__c;
      pro.specific_gravity__c = proStage.specific_gravity__c;   
      pro.Toxic_substance__c = proStage.Toxic_substance__c;   
      pro.dangerous_substance__c = proStage.dangerous_substance__c;   
      pro.Quantity_without_permit_inspection__c = proStage.Quantity_without_permit_inspection__c;   
      pro.Quantity_without_inspection_of_HOMS_lice__c = proStage.Quantity_without_inspection_of_HOMS_lice__c;   
      pro.Permit__c = proStage.Permit__c;   
      pro.N__c = proStage.N__c;   
      pro.P__c = proStage.P__c;   
      pro.K__c = proStage.K__c;  
      if (proStage.N__c !=null &&  proStage.P__c!=null && proStage.K__c!=null)
      {
      pro.NPKratio__c = convertRatio(Integer.valueOf(proStage.N__c),Integer.valueOf(proStage.P__c),Integer.valueOf(proStage.K__c)); 
      pro.NPratio__c = convertRatio(Integer.valueOf(proStage.N__c),Integer.valueOf(proStage.P__c),null);
      pro.NKratio__c = convertRatio(Integer.valueOf(proStage.N__c),Integer.valueOf(proStage.K__c),null);   
  	  pro.PKratio__c = convertRatio(Integer.valueOf(proStage.P__c),Integer.valueOf(proStage.K__c),null);   
      }
      pro.CL__c = proStage.CL__c;   
      pro.CO__c = proStage.Co__c;   
      pro.Fe__c = proStage.Fe__c;   
      pro.IS__c = proStage.IS__c;   
      pro.Mg__c = proStage.Mg__c;   
      pro.Mn__c = proStage.Mn__c;   
      pro.PH__c = proStage.PH__c;   
      pro.XX__c = proStage.XX__c;   
      pro.ZN__c = proStage.ZN__c;   
      pro.B__c = proStage.B__c;   
      pro.Global_Division__c = proStage.Global_Division__c;   
      pro.Global_Prod_Family__c = proStage.Global_Prod_Family__c;   
      pro.Global_Product_Group__c = proStage.Global_Product_Group__c;   
      pro.Origin__c = proStage.Origin__c; 
      pro.Source_System__c = proStage.Source_System__c;   
      pro.UN_number__c = proStage.UN_number__c; 
      pro.Accumulation_state__c = prostage.Accumulation_state__c;
      pro.New_Division_F__c=prostage.New_Division_F__c;
      pro.Production_Site__c=prostage.Production_Site__c;
      pro.Production_Site_Text__c=prostage.Production_Site_Text__c;
      pro.Dingers_Good__c = prostage.Dingers_Good__c;
      pro.ProductStageId__c = proStage.Id; 
      if (proStage.Place_Holder_1__c!=NULL) 
      {pro.Family=proStage.Place_Holder_1__c.replace('-','_');
          }
      
      productsToUpsert.add(pro);
  }

  public static String convertRatio(Integer num1, Integer num2, Integer num3){
    String ratioToReturn = '';
    Integer minimum = getMinimum(num1, num2, num3);
    
    // returns the original NPKs formatted as String
    if (minimum <= 1) { 
      ratioToReturn = num1 + '-' + num2;
      if (num3!= null)
        ratioToReturn+= '-' + num3;
      return  ratioToReturn;
    }
    // devide non 0 numbers with min number 
    return devideAndFormat(num1,num2,num3, minimum);

}


// calculates the min value from NPK excluding '0'
public static Integer getMinimum(Integer num1, Integer num2, Integer num3){
    Integer min;

      if(num1 == null){
        min = gcd(num2, num3);
      }
      else if(num2 == null){
        min = gcd(num1, num3);
      }
      else if(num3 == null){
        min = gcd(num1, num2);
      }
      else{
        min = findGCD(new List<Integer>{num1, num2, num3});
      }
  
    // Integer min;
    // if (num1!=0 && num2!= 0) {
    //     min = Math.min(num1, num2);
    // }
    // else {
    //     min = num1+num2;
    //     if (min == 0 && num3!=null) {return num3;} 
    // }
    // if (num3 != 0 && num3!=null) {
    //     min = Math.min(min, num3);
    // }
    return min;
}


public static String devideAndFormat(Integer num1, Integer num2, Integer num3, Integer minimum){

    if(num3!=null){
      if(num1==0 && num2==0 && num3==0){
        return num1 + '-' + num2 + '-' + num3; // TODO: To check this line : potentially useless
      }
      if(Math.mod(num1, minimum) == 0 && Math.mod(num2, minimum) == 0  && Math.mod(num3, minimum) == 0){
        return num1/minimum + '-' + num2/minimum + '-' + num3/minimum;
      }      
      return num1 + '-' + num2 + '-' + num3;
    }else{
      if(num1==0||num2==0){
        return num1/minimum + '-' + num2/minimum;
      }
      if(Math.mod(num1, minimum) == 0 && Math.mod(num2, minimum) == 0  ){
        return num1/minimum + '-' + num2/minimum;
      }    
      return num1 + '-' + num2;    
    }     
}



  // Function to return gcd of a and b 
  public static Integer gcd(Integer a, Integer b)  //TODO: change to private
  { 
      if (a == 0) 
          return b; 
      return gcd(Math.mod(b, a), a); 
  } 

  // Function to find gcd of array of 
  // numbers 
  public static Integer findGCD(List<Integer> arr) //TODO: change to private
  { 
      Integer result = 0; 
      for (Integer element: arr){ 
          result = gcd(result, element); 

          if(result == 1) 
          { 
             return 1; 
          } 
      } 

      return result; 
  } 
	




}