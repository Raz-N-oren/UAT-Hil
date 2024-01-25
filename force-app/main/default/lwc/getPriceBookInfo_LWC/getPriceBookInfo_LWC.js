import { api, LightningElement } from 'lwc';
import getPBRecord from "@salesforce/apex/priceCalculationInfo.getPBRecord";
import getPriceForProduct from "@salesforce/apex/priceCalculationInfo.getPrice";
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';


export default class GetPriceBookInfo_LWC extends LightningElement {

    @api productId;
    @api dnId;
    @api accountId;
    @api accountDivision;
    @api prodPrice;
    @api priceBookId;
    @api totalCredit;

    currentAccount;
    currentProduct;
    currentaccountDivision;
    currentPrice;
  currentPriceBookId;
  currentdnId;

    connectedCallback(){
      console.log("connectedCallback Enter GetPriceBookInfo_LWC:", this.productId, this.accountId);
    }

  renderedCallback() {
    if (this.currentdnId != this.dnId) {
      this.currentdnId = this.dnId;
            this.getTotalCredit();
    }
  
  if (this.currentAccount != this.accountId || this.currentProduct != this.productId) {
      console.log("renderedCallback Enter GetPriceBookInfo_LWC:", this.productId, this.accountId);
      this.currentAccount = this.accountId;
      this.currentProduct = this.productId;
      this.currentaccountDivision = this.accountDivision;
      this.getPriceForProduct();
      this.getPBRecord();
  }
    
  
["prodPrice", "priceBookId","totalCredit"].forEach((prop) =>
      this.dispatchEvent(new FlowAttributeChangeEvent(prop, this[prop])));
  }

    getPriceForProduct(){
         
           let yourDate = new Date();
               yourDate.toISOString().split('T')[0];
               console.log("getPrice 591",this.productId,  this.accountId, this.accountDivision,1,null,  null,null)
              getPriceForProduct({ productId: this.productId, Account: this.accountId, AccountDivision: this.accountDivision,measurementUnit: "TO",amount:1,
                 loadingPoint: null, transportType: null,IL_Group:null,Date:null // הסלשתי 18.12 כי בפונ' צריך רק את ה2 שהשארתי
                  }).then((res) => {
                    console.log("prodPriceBeforeDiscount 424",res);
                                    this.prodPrice = res; // השמה למחירון מתחת למחיר מיוחד
                    this.currentPrice = res;
                           }).catch((err) => {console.error(err);});
    }
   
   
    getPBRecord() {

          getPBRecord({ productId: this.productId, Account: this.accountId, IL_Group: null, transportType: null,
                  AccountDivision: this.accountDivision, loadingPoint: null, invoiceDate: null,
          }).then((result) => {

                          console.log("productPriceBook result",JSON.stringify(result));
                            if (Object.keys(result).length > 0) {
                              this.priceBookId = result.Id;
                            this.currentPriceBookId=result.Id;
                              console.log("productPriceBook", this.priceBookId );
                          }         
                  }).catch((err) => {console.error(err);}); 
    }
  
  

}