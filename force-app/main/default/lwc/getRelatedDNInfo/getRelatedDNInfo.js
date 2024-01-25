import { api, LightningElement } from 'lwc';
import getMatrixLineInfo from "@salesforce/apex/discountDetailsController.getMatrixLineInfo";
import getTotalCredit from "@salesforce/apex/BillingCredit_RelatedDNInfo.getTotalCredit";
import getTotalreturnDN from "@salesforce/apex/BillingCredit_RelatedDNInfo.getTotalreturnDN";
import getTotalDiscount from "@salesforce/apex/BillingCredit_RelatedDNInfo.getTotalDiscount";
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getRelatedDNInformation from "@salesforce/apex/BillingCredit_RelatedDNInfo.getRelatedDNInformation";
import getRelatedItem from "@salesforce/apex/BillingCredit_RelatedDNInfo.getRelatedItem";


export default class GetRelatedDNInfo extends LightningElement { 
    @api productId;
    @api dnId;
    @api accountId;
    @api totalCredit=0;
    @api discountMatrix=0;
    @api totalDNreturn=0;
    @api existingDiscount=0; 
  @api requestedDiscount;
  @api discountMatrixId;
  @api newdiscountamount=0;
  @api totalDNreturnQun=0;
    @api dnUOM;
    dnRec;

    currentAccount;
    currentProduct;
    currentdnId;
  currentrequestedDiscount;
  TotalPriceBeforeDiscount;

    connectedCallback(){
      console.log("connectedCallback Enter GetRelatedDNInfo:", this.productId, this.accountId);
    }

    renderedCallback() {
      console.log("renderedCallback Enter GetRelatedDNInfo:", this.productId, this.accountId);
    
        if (this.currentdnId != this.dnId  ) {
            this.currentdnId = this.dnId;
            this.currentrequestedDiscount = this.requestedDiscount;
            this.getRelatedDNInformation();
            this.getTotalCredit();
            this.getTotalreturnDN();
        }
        ["discountMatrix", "totalDNreturnQun","totalCredit","totalDNreturn","existingDiscount","newdiscountamount","dnUOM"].forEach((prop) => this.dispatchEvent(new FlowAttributeChangeEvent(prop, this[prop])));
    }

    getRelatedDNInformation(){
         getRelatedDNInformation({
        DN: this.dnId
      }).then((res) => {
        console.log("GetRelatedDNInfo-->getRelatedDNInformation 46", res);
      if (res != null) {
        this.dnRec = res;
        this.currentAccount = res.Account__c;
        this.currentProduct = res.Product__c;
        this.dnUOM = res.FinalUnitOfMeasure__c;
        this.TotalPriceBeforeDiscount = res.TotalPriceBeforeDiscount__c;
        console.log("GetRelatedDNInfo-->dnUOM 60", this.dnUOM);
        console.log("GetRelatedDNInfo-->getRelatedDNInformation 61", this.TotalPriceBeforeDiscount);
        this.getTotalDiscount(); 
        this.getDiscountMatrix();

            }
      }).catch((err) => { console.error(err); });
      
   
    }
  
  getDiscountMatrix() {
                  console.log("getDiscountMatrix 34", this.currentAccount,this.currentProduct);  

        getMatrixLineInfo({
            prodId: this.currentProduct,
            accId: this.currentAccount, family: null  
        }).then((res) => {
        if (res != null) {
                      console.log("getDiscountMatrix 34", res);  

         this.discountMatrixId = res.Id;
              this.discountMatrix = res.Max_Discount__c;
               console.log("getDiscountMatrix 34", this.discountMatrix );  

        }
        else {
           this.discountMatrixId = null;
              this.discountMatrix = 0;
          }

        }).catch((err) => { console.error(err); });
    }
  
  getTotalCredit() {
      getTotalCredit({
        DN: this.dnId
      }).then((res) => {
        console.log("GetRelatedDNInfo-->getTotalCredit 97", res);
        this.totalCredit = res;
      }).catch((err) => { console.error(err); });
    
  }
    
     getTotalreturnDN() {
      getTotalreturnDN({
        DN: this.dnId
      }).then((res) => {
          console.log("GetRelatedDNInfo-->getTotalreturnDN 67", res);
          if (res != null) {
            this.totalDNreturn = res[0];
            this.totalDNreturnQun = res[1];
          }
          else {
               this.totalDNreturn = 0;
            this.totalDNreturnQun = 0;
        }
      }).catch((err) => { console.error(err); });
    
     }
    
   
  
  getTotalDiscount() {
    getTotalDiscount({
      dnId: this.dnId
    }).then((res) => {
      console.log("getTotalDiscount-->getTotalDiscount 115", res,this.TotalPriceBeforeDiscount);
      if (res > 0) {

        this.existingDiscount = ((((res) / (this.TotalPriceBeforeDiscount - this.totalDNreturn))) * 100).toFixed(2);
        console.log("getTotalDiscount-->getTotalDiscount existingDiscount:", this.existingDiscount);

      }
      else {
        this.existingDiscount = 0;
      }
         }).catch((err) => { console.error(err); });
    }
}