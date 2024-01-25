global with sharing class YearlyPlanEmailByPlotsController {
  
  
  public class CustomException extends Exception {}
  
  private final String TIME_PERIOD = 'תקופה';
  private final String PRODUCT_NAME = 'שם הדשן';
  private final String NOTES = 'הערות';
  private final String QUANTITY_PER_HECTRE = 'כמות לדונם \\ קוב (ליטר)';
  private final String QUANTITY_PER_PLOT = 'כמות לחלקה (קוב)';
  private final String N = 'N';
  private final String P = 'P';
  private final String K = 'K';

  private boolean initiated = false; // asserts 'set' method 'oppIdFromVFEmailTemplate' will accure only once
  private Map<String, List<OpportunityLineItem> > oppLinesByPlots = new Map<String, List<OpportunityLineItem> >(); // <Plot Names, List with OppLineItems of the plot in the key>
  private list<OpportunityLineItem> oppLineItems;
  private Map<String, OpportunityLineItem> oppLineItemsMap;
  private Map<String, Map<String, String>> oppLineGroupeResultsMap = new Map<String, Map<String, String>>();	 // Holds final Map with OppLine grouped by product for the Bottom Summary table
  private List<String> monthes;
  private List<String> columnTitle =  new List<String>{TIME_PERIOD, PRODUCT_NAME, NOTES, QUANTITY_PER_HECTRE, QUANTITY_PER_PLOT,K,P,N}; // Plots Column headrs - Will show at the table as the same order of list
  private Map<String, Map<String,Decimal>>  sumOfPlotsSizeMap =  new Map<String, Map<String,Decimal>>(); // each element in Map contains the sum of all plots from the same type
  private Integer amountOfOppLineItems = 0;
  String fatalExceptionMessage; 
  global String oppIdFromVFEmailTemplate {
    get;
    set{
      if (initiated) {
        return;
      }
      
      oppIdFromVFEmailTemplate = value;
      try {
        oppLineItems = queryOppLineFromOpportunity(oppIdFromVFEmailTemplate); // get opplines items from soql
        amountOfOppLineItems = oppLineItems.size();
        AggregateResult[] queryOppLineGroupeResult = queryOppLineGroupedByProductName(oppIdFromVFEmailTemplate); // get opplines from soql for te bottom summary table
        initMonthes(queryOppLineGroupeResult);
        
        prepareOppLineGroupeResultForTableView(queryOppLineGroupeResult); // manipulate the data for the BOTTOM table before showing in the VisualForce page
        prepareOppLineResultForTableView(oppLineItems); // manipulate the data for the PLOTS tables before showing in the VisualForce page
        
      }
      catch (QueryException e) {
        System.debug('Exception' + e );
        fatalExceptionMessage =  'שגיאה בקבלת מידע, בדוק פרטי תכנית שנתית';
        return;
      } 
      catch(CustomException e){
        System.debug('Exception' + e );
        fatalExceptionMessage = e.getMessage();
        return;
      }
      catch (Exception e) {
        System.debug('General Exception' + e );
        fatalExceptionMessage =  'התקבלה שגיאה בעיבוד המידע';
        return;
      } 
      
      
    }
  }
  
  
  private void prepareOppLineResultForTableView(list<OpportunityLineItem> oppLineItems){
    for (OpportunityLineItem item : oppLineItems) {
      if(!oppLinesByPlots.containsKey(item.Plots__c)){
        oppLinesByPlots.put(item.Plots__c, new List<OpportunityLineItem>());
        sumOfPlotsSizeMap.put(item.Plots__c, new Map<String, Decimal>());
        if (item.Plot_Size__c == null) {
          item.Plot_Size__c = 0;
        }
        sumOfPlotsSizeMap.get(item.Plots__c).put('Size', item.Plot_Size__c); 
        sumOfPlotsSizeMap.get(item.Plots__c).put('SummedN', 0);
        sumOfPlotsSizeMap.get(item.Plots__c).put('SummedP', 0);
        sumOfPlotsSizeMap.get(item.Plots__c).put('SummedK', 0);
      }
      oppLinesByPlots.get(item.Plots__c).add(item);
      OpportunityLineItem oppli = (OpportunityLineItem)oppLinesByPlots?.get(item.Plots__c)[oppLinesByPlots.get(item.Plots__c).size()-1];
      oppli.Quantity_per_hectare__c = oppli.Quantity_per_hectare__c?.setScale(2);
      oppli.Quantity = oppli.Quantity?.setScale(2);
      oppli.N__c = oppli.N__c?.setScale(2);
      oppli.P__c = oppli.P__c?.setScale(2);
      oppli.K__c = oppli.K__c?.setScale(2);

      
      if(item.N__c == null){item.N__c = 0;}
      if(item.P__c == null){item.P__c = 0;}
      if(item.K__c == null){item.K__c = 0;}
      
      sumOfPlotsSizeMap.get(item.Plots__c).put('SummedN',  sumOfPlotsSizeMap.get(item.Plots__c).get('SummedN') + item.N__c.setScale(2));
      sumOfPlotsSizeMap.get(item.Plots__c).put('SummedP',  sumOfPlotsSizeMap.get(item.Plots__c).get('SummedP') + item.P__c.setScale(2));
      sumOfPlotsSizeMap.get(item.Plots__c).put('SummedK',  sumOfPlotsSizeMap.get(item.Plots__c).get('SummedK') + item.K__c.setScale(2));
      
    }
    initiated = true;
  }
  
  public YearlyPlanEmailByPlotsController(){
    // Empty constructor reqired for custom controllers
  }     
  
  private list<OpportunityLineItem> queryOppLineFromOpportunity(String oppId) { 
    Opportunity opp =
    [
    select
    Id,(
    SELECT
    Id,
    Product2Id,
    Quantity,
    UnitPrice,
    SortOrder,
    Product2.Name,
    Quantity_per_hectare__c,
    N__c,
    P__c,
    K__c,
    Description,
    Plots__c,
    Date__c,
    Plot_Size__c
    FROM
    OpportunityLineItems
    Order By
    Plots__c,
    Date__c,
    CreatedDate,
    LastModifiedDate DESC,
    Is_Extension__c
    )
    from
    Opportunity
    Where
    Id =: oppId
    Limit
    1
    ];
    oppLineItemsMap = new Map<String, OpportunityLineItem>(opp.OpportunityLineItems);
    return opp.OpportunityLineItems;
  }   
  
  
  private AggregateResult[] queryOppLineGroupedByProductName(String oppId) {
    AggregateResult[] oppLineGrouped =
    [
    SELECT
    Product2.Name,
    SUM(Quantity) QuantitySum,
    Date__c
    FROM
    OpportunityLineItem
    WHERE
    OpportunityId =: oppId
    GROUP BY
    Product2.Name,
    Date__c
    ];
    
    return oppLineGrouped;
  } 
  
  
  
  
  // Bottom Summary table
  private void prepareOppLineGroupeResultForTableView(List<AggregateResult> queryOppLineGroupeResult){
    
    /*
    Structure of map:
    Map<String, Map<String, String>> oppLineGroupeResultsMap
    oppLineGroupeResultsMap ==>  Name ==> { { Sum ==> 99} { month1 ==> 88} { month2 ==> 77} }
    */
    
    for (AggregateResult productNameKey : queryOppLineGroupeResult)  {
      
      String productName = String.valueOf(productNameKey.get('Name'));
      String productQuantitySumForDate = '0';
      
      if (productNameKey.get('QuantitySum') != null) {
        Decimal quantitySum = ((Decimal)productNameKey.get('QuantitySum')).setScale(2);
        productQuantitySumForDate = String.valueOf(quantitySum);
      }
  
      
      if (!(productNameKey.get('Date__c') instanceof Date)) {
        throw new CustomException('פורמט שגוי עבור התאריך של אחד מהפריטים');
      }
      Date productDate = Date.valueOf(productNameKey.get('Date__c'));
      String formatedDate = String.valueOf(productDate.month()) + '/' + String.valueOf(productDate.year()).right(2);
      
      if(!oppLineGroupeResultsMap.containsKey(productName)){ // If Product is not in map yet
        oppLineGroupeResultsMap.put(productName, new Map<String, String>());
        oppLineGroupeResultsMap.get(productName).put('Sum', '0'); // put intial value for sum of quantity
        for (String month : monthes) {
          oppLineGroupeResultsMap.get(productName).put(month, ''); // put intial value for quantity per month 
        }
        
      }
      
      Decimal intSumQuantity = Decimal.valueOf(oppLineGroupeResultsMap.get(productName).get('Sum')) + Decimal.valueOf(productQuantitySumForDate);
      oppLineGroupeResultsMap.get(productName).put('Sum', String.valueOf(intSumQuantity) );
      oppLineGroupeResultsMap.get(productName).put(formatedDate, productQuantitySumForDate);
    }
    
  }
  
  
  private void initMonthes(AggregateResult[] queryOppLineGroupeResult){
    if (queryOppLineGroupeResult.size() < 1) {
      // Return as there is there is no OppLines to sum there quantity.
      // Exception will be propertly be handled later in this case.
      return;
    }
    
    monthes = new List<String>();
    final Integer MONTHES_IN_YEAR = 12;
    
    Date dateOfOppLine = Date.valueOf(queryOppLineGroupeResult[0].get('Date__c'));
    String year = String.valueOf(dateOfOppLine.year());
    
    for (Integer i = 1; i <= MONTHES_IN_YEAR ; i++) { // create '[month]/[year(2 last digits)]' dynamicly 
    monthes.add(i + '/' + year.right(2));
  }
  
  
} 

public Map<String, List<OpportunityLineItem> > getPlotsMap(){
  return oppLinesByPlots;
}

public List<String> getColumnTitle(){
  return columnTitle;
}

public Map<String, Map<String,Decimal>> getSumOfPlotsSizeMap(){
  return sumOfPlotsSizeMap;
}

public Map<String, Map<String, String>> getOppLineGroupeResultsMap(){
  return oppLineGroupeResultsMap;
}

public List<String> getMonthes(){
  return monthes;
}

public Integer getAmountOfOppLineItems(){
  return  amountOfOppLineItems;
}
public String getFatalExceptionMessage(){
  return fatalExceptionMessage;
}




}