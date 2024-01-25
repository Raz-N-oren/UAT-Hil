/* Created Date: 15/05/21
* 
* 
*/
public class CreditJSON2Apex {
    public Credit Credit;
    public List<OrderedHazardMaterials> orderedHazardMaterials;
    public List<IsStockAvailable> isStockAvailable;
    public List<PurchaseOrder> PurchaseOrder;
    
    public class Credit {
        public string CreditStatus;
        public string CreditStatusReason;
    }
    
    public class OrderedHazardMaterials {
        public String entityNumber;
        public String entityName;
        public String matnr;
        public String maktx;
        public String zmatnrReal;
        public String vmaktx;
        public String idperm;
        public string endda;
        public string maxAmount;
        public string yearAmount;
        public String meins;
        public string aedat;
        public String aenam; 
        public String puse;
        public string maxAmountD;
        public string unNumber;
        public String amountInTonnes;
        public String approved;
    }
     public class AllHazardMaterialsForUser {
        public String userSapNum;
        public String coordinateCatalogNum;
        public Integer permitionNum;
        public String amountPerOrder;
        public String maxYearlyAmount;
        public String unitOfMeasure;
        public Integer validFromDate;
        public Integer validTillDate;
    }
    public class IsStockAvailable {
        public String productSapNum;
        public String amountInTonnes;
        public String approved;
    }
    public class PurchaseOrder {
		public List<String> PurchaseOrder;
		public String Line;
	}
    
    
    public static CreditJSON2Apex parse(String json) {
        
        return (CreditJSON2Apex) System.JSON.deserialize(json, CreditJSON2Apex.class);
    }
}

/* Created Date: 15/05/21
* 
* 

public class CreditJSON2Apex {
    public Credit Credit;
    public List<OrderedHazardMaterials> orderedHazardMaterials;
    public List<IsStockAvailable> isStockAvailable;
    public List<PurchaseOrder> PurchaseOrder;
    
    public class Credit {
        public string creditQuota;
        public string invoiceValue;
        public String vatNum;
        public String termsOfPayment;
    }
    
    public class OrderedHazardMaterials {
        public String entityNumber;
        public String entityName;
        public String matnr;
        public String maktx;
        public String zmatnrReal;
        public String vmaktx;
        public String idperm;
        public string endda;
        public string maxAmount;
        public string yearAmount;
        public String meins;
        public string aedat;
        public String aenam; 
        public String puse;
        public string maxAmountD;
        public string unNumber;
        public String amountInTonnes;
        public String approved;
    }
     public class AllHazardMaterialsForUser {
        public String userSapNum;
        public String coordinateCatalogNum;
        public Integer permitionNum;
        public String amountPerOrder;
        public String maxYearlyAmount;
        public String unitOfMeasure;
        public Integer validFromDate;
        public Integer validTillDate;
    }
    public class IsStockAvailable {
        public String productSapNum;
        public String amountInTonnes;
        public String approved;
    }
    public class PurchaseOrder {
		public List<String> PurchaseOrder;
		public String Line;
	}
    
    
    public static CreditJSON2Apex parse(String json) {
        
        return (CreditJSON2Apex) System.JSON.deserialize(json, CreditJSON2Apex.class);
    }
}*/