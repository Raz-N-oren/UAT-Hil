import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import formFactor from '@salesforce/client/formFactor';
import { fieldForDiscount } from "c/utils";
import { NavigationMixin } from 'lightning/navigation';
import getMatrixLineInfo from '@salesforce/apex/discountDetailsController.getMatrixLineInfo';
import getPriceForProduct from '@salesforce/apex/discountDetailsController.getPriceForProduct';
import getPrice from '@salesforce/apex/priceCalculationInfo.getPrice';
import getAccountClassification from '@salesforce/apex/discountDetailsController.getAccountClassification';
import getProductGravity from '@salesforce/apex/discountDetailsController.getProductGravity';
import getRequestedDiscount from '@salesforce/apex/discountDetailsController.getRequestedDiscount';
import Utils from "c/utils";
import Id from '@salesforce/schema/Account.Id';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';


export default class DiscountDetails extends NavigationMixin(LightningElement) {
    @track hasDiscountInUrl = false;
       
    AccountIdRecord;
             @api recordId;
             @api objectApiName;
             discountObject;
             priceAfterDiscount;
             disName = '';
             fil1 = 'לקוח';
             fil2 = 'מוצר';
             status = '';
             classification = '';
             createdBy = '';
             currency = '';
             area = '';
             lastModifiedBy = '';
             max = '';
             note = '';
             ownerId = '';
             product = null;
             productFamily = '';
             productSubFamily = '';
             requested = '';
             settlement = '';
             startDate = this.currentMonthFirstDay;
             endDate = this.currentYearLastDay;
             target = '';
             reason = '';
             fil1BeforeEdit = '';
             fil2BeforeEdit = '';
             hideMe = true;
             productPrice = 0;
             customerSize = '';
             maxDiscount = 0;
             targetDiscount = 0;
             tonnePriceBeforeDiscount = 0;
             tonnePriceAfterDiscount = 0;
             cubePriceBeforeDiscount = 0;
             cubePriceAfterDiscount = 0;
             discount = 0;
             @api Name='test';
             specificGravityValue = '';
             isAccount = false;
             isSettlement = false;
             isArea = false;
             @track isProduct = false;
             isProductFamily = false;
             isProductSubFamily = false;
             isEdit = true;
             submitionFlag = false;
             submitionAndNewFlag=false;
             @api AccountId;
             @api ProductId;
             @api SelectedCaseRecord;
             @api SelectedCaseRecord2;
             @track test;
             acc = this.AccountId !== '' ? this.AccountId : '';
             thereIsGravity = false;           
             
         connectedCallback() {
            const currentUrl = window.location.href;
            this.hasDiscountInUrl = currentUrl.includes('Discount');
            console.log("check true/false, includes discount/not",this.hasDiscountInUrl);
            console.log("discountTest",this.AccountId,this.ProductId);
            console.log("RAZCHECK,81 ,connectedCallback ,this.isProduct ",this.isProduct);
            this.product=this.ProductId;
            this.acc=this.AccountId;
            this.fil1 = 'לקוח';
            this.isAccount = true;
            this.isArea = false;
            this.isSettlement = false;
            this.settlement = '';
            this.area = '';
            this.test = this.ProductId;
            // this.product=this.test;
            // console.log(this.product,"001 84");
                // this.acc=this.AccountId ? "" : this.AccountId;
                // this.acc=this.AccountId;
            // this.isProduct = true;
                 if (!this.recordId) {
                 this.isEditMode = true;
                 } else {
                  this.isEditMode = false;
                  }
                  this.getMatrixLineInfo();
                  console.log("RAZCHECK, 102, this.acc",this.acc);
              }
              renderedCallback(){
                console.log("RAZCHECK,104 ,renderedCallback ,this.isProduct ",this.isProduct);
                console.log("RAZCHECK, 102 106, this.acc",this.acc);
                console.log("RAZCHECK, 102 106, this.productFamily",this.productFamily);
              }

             get currentMonthFirstDay() {
                 const currentMonth = new Date().getMonth();
                 const currentYear = new Date().getFullYear();
         
                 const firstDayOfTheMonth = new Date(currentYear, currentMonth, 2).toISOString();
                 return firstDayOfTheMonth;
             }
         
             get currentYearLastDay() {
                 const currentYear = new Date().getFullYear();
         
                 const lastDay = new Date(currentYear, 11, 32).toISOString();
                 return lastDay;
             }
         
             @wire(getRecord, { recordId: '$recordId', fields: fieldForDiscount })
             wiredRecord({ error, data }) {
                 if (error) {
                     let message = 'Unknown error';
                     if (Array.isArray(error.body)) {
                         message = error.body.map(e => e.message).join(', ');
                     } else if (typeof error.body.message === 'string') {
                         message = error.body.message;
                     }
                     this.dispatchEvent(
                         new ShowToastEvent({
                             title: 'Error loading discount',
                             message,
                             variant: 'error',
                         }),
                     );
                     console.log('error message: ' + message);
                 } else if (data) {
                     console.log('wiredRecord: ', JSON.stringify(data));
                     // debugger
                     this.discountObject = data;
                     this.disName = data.fields.Name.value;
                     this.fil1 =  this.fil1? this.fil1: data.fields.Display_Filter_1__c.value;
                     this.fil2 = this.fil2 ?this.fil2:data.fields.Display_Filter_2__c.value;
                     this.status = this.status?this.status : data.fields.Status__c.value;
                     this.acc = this.acc?this.acc:data.fields.Account__c.value;
                     this.customerSize = this.customerSize?this.customerSize: data.fields.Account_Classification__c.value;
                     this.createdBy = data.fields.CreatedById.value;
                     this.currency = data.fields.CurrencyIsoCode.value;
                     this.area = data.fields.Geographic_Area__c.value;
                     this.lastModifiedBy = data.fields.LastModifiedById.value;
                     this.targetDiscount = data.fields.Target_Discount__c.value;
                     this.maxDiscount = data.fields.Max_Discount__c.value;
                     this.note = data.fields.Note__c.value;
                     this.ownerId = data.fields.OwnerId.value;
                     this.product = this.product?this.product :data.fields.Product__c.value;
                     this.productFamily = data.fields.Product_Family_new__c.value;
                     this.productSubFamily = data.fields.Sub_Product_Family__c.value;
                     this.requested = data.fields.Requested_Discount__c.value;
                     this.settlement = data.fields.Settlement__c.value;
                     this.startDate = data.fields.Start_Date__c.value;
                     this.endDate = data.fields.End_Date__c.value;
                     this.reason = data.fields.Reazon__c.value;
                     this.getMatrixLineInfo();
                     // change boolean variabls according to picklist values
                     this.changeFil1({ detail: { value: this.Display_Filter_1__c } });
                     this.changeFil2({ detail: { value: this.Display_Filter_2__c } });
                 }
             }
         
         
             getMatrixLineInfo() {
                 console.log("getMatrixLineInfo: ", " accId:", this?.acc, " prodId: ", this?.product, "family: ", this.family);
         
                 getMatrixLineInfo({ accId: this?.acc, prodId: this?.product, family: this.family }).then(data => {
                     console.log("wiredMatrixLineInfo: ", JSON.stringify(data));
                     this.maxDiscount = data.Max_Discount__c;
                     this.targetDiscount = data.Target_Discount__c;
                     if (this.customerSize){this.customerSize=data.Customer_Size__c;} else{ this.getCustomerSize(); }
                 }).catch(error => {
                     console.log("Error get matrix data: ", JSON.stringify(error));
                     this.maxDiscount = 0;
                     this.targetDiscount = 0;
                     this.customerSize = '';
                     this.getCustomerSize();
                 })
             }

             getRequestedDiscount() {
                 console.log("RAZCHECK,195: ", " accId:", this?.acc, " prodId: ", this?.product);
         
                 getRequestedDiscount({ accId: this?.acc, prodId: this?.product}).then(data => {
                     console.log("RAZCHECK,195: data ", JSON.stringify(data));
                     console.log("RAZCHECK,195: data ", JSON.stringify(data[0].Requested_Discount__c));
                     console.log("RAZCHECK,195: data ", JSON.stringify(typeof(data[0].Requested_Discount__c)));
                     if(data[0].Requested_Discount__c){
                         this.requested = data[0].Requested_Discount__c;
                     }

                 }).catch(error => {
                     console.log("Error get Requested Discount: ", JSON.stringify(error));
                 })
             }

             getProductGravityValue(){
                console.log("RAZCHECK,getProductGravityValue, 186, prodId: ",this?.product);

                getProductGravity({prodId: this?.product}).then(data=>{
                    console.log("RAZCHECK, getProductGravity, 186",JSON.stringify(data));
                    console.log("RAZCHECK, getProductGravity.specific_gravity__c, 186",JSON.stringify(data[0].specific_gravity__c));
                    this.specificGravityValue = data[0].specific_gravity__c;
                    if(data[0].specific_gravity__c){
                        this.thereIsGravity = true;
                    }
                }).catch(error=>{
                    console.log("Error get gravity data: ", JSON.stringify(error));
                    this.specificGravityValue = '';
                    this.thereIsGravity = false;
                })

             }
         
             totalCubePrice = 0;
             totalTonesPrice = 0;
             // once product or account Ids changing - wire fired the customized methud getPriceForProduct
             @wire(getPriceForProduct, { productId: "$product", accountId: "$acc" })
             priceCalculation({ data, error }) {
                 if (data) {
                     console.log(data,"line 151 data");
                     this.productPrice = data.Tonnes;
                     this.totalCubePrice = data.Cubes;
                     this.totalTonesPrice = data.Tonnes;
                     console.log("data: ", data);
                     if (data.Tonnes == -1 && data.Cubes == -1) {
                         Utils.showToast(this, "שגיאה", 'לא קיים מחירון תקף עבור מוצר זה', "error");
                     } else {
                         this.tonnePriceBeforeDiscount = data.Tonnes.toFixed(2);
                         this.cubePriceBeforeDiscount = data.Cubes.toFixed(2);
                         this.calculatePricesAfterDiscount(null);
                     }
                 }
                 else if (error) {
                     this.tonnePriceBeforeDiscount = 0;
                     this.tonnePriceAfterDiscount = 0;
                     this.cubePriceBeforeDiscount = 0;
                     this.cubePriceAfterDiscount = 0;
                     this.productPrice = 0;
                     this.totalCubePrice = 0;
                     this.totalTonesPrice = 0;
                 }
             }
         
             getCustomerSize() {
                 getAccountClassification({ accId: this.acc }).then(result => {
                     console.log("getAccountClassification: ", JSON.stringify(result))
                     this.customerSize = result[0]?.Classification__c;
                     console.log("RAZCHECK,getAccountClassification, this.customerSize ", JSON.stringify(result))
                 }).catch(error => {
                     console.error(error);
                 })
             }
         
             // update requested discount precentages  
             updateDiscount() {
                 this.requested = ((1 - (this.tonnePriceAfterDiscount / this.tonnePriceBeforeDiscount)) * 100).toFixed(2);
             }
         
             // fired when the price field changed
             productPriceChangeHandler(event) {
                 this.productPrice = event.detail.value;
         
                 this.cubePriceBeforeDiscount = this.totalCubePrice;
                 this.cubePriceAfterDiscount = event.detail.value;
         
                 this.tonnePriceBeforeDiscount = this.totalTonesPrice;
                 this.tonnePriceAfterDiscount = event.detail.value;
         
                 // מחירים - decloration above. calculate discount precentages according to dynamic price
                 this.updateDiscount();
         
                 // calculate tonne vs cube
                 if (this.tonnePriceBeforeDiscount) {
                     this.tonnePriceAfterDiscount = (
                         this.tonnePriceBeforeDiscount * (1 - (this.requested ? this.requested : 0) / 100)
                     ).toFixed(2);
                 }
                 if (this.cubePriceBeforeDiscount) {
                     this.cubePriceAfterDiscount = (
                         this.cubePriceBeforeDiscount * (1 - (this.requested ? this.requested : 0) / 100)
                     ).toFixed(2);
                 }
                 this.template.querySelector(".discount-input").checkValidity();
             }
         
             
             handleDuplicate() {
                 this.startDate = this.currentMonthFirstDay;
                 this.endDate = this.currentYearLastDay;
         
                 // navigate to a new standard record page with the current object given fields (according to recordId)
                 this[NavigationMixin.GenerateUrl]({
                     type: "standard__recordPage",
                     attributes: {
                         recordId: this.recordId,
                         objectApiName: 'Discount__c',
                         actionName: 'clone'
                     }
                 }).then(url => {
                     window.open(url, "_blank");
                 });
         
             }
         
         
             // לקוח / איזור / ישוב 
             changeFil1(event) {
                 if (event?.detail?.value) {

                     this.fil1 = String(event.detail.value);
                 }
                 if (this.fil1 == 'לקוח') {

                     this.isAccount = true;
                     this.isArea = false;
                     this.isSettlement = false;
                     this.settlement = '';
                     this.area = '';
                 } else if (this.fil1 == 'ישוב') {

                     this.isAccount = false;
                     this.isArea = false;
                     this.isSettlement = true;
                     this.acc = '';
                     this.area = '';
                 } else if (this.fil1 == 'אזור') {

                     this.isAccount = false;
                     this.isArea = true;
                     this.isSettlement = false;
                     this.settlement = '';
                     this.acc = '';
                 } else {

                     this.isAccount = false;
                     this.isArea = false;
                     this.isSettlement = false;
                     this.settlement = '';
                     this.acc = '';
                     this.area = '';
                 }
             }
         
             // מוצר / משפחת מוצר / תת מוצר
             changeFil2(event) {
                console.log("RAZCHECK, 340 , dilsplay, filter,event.detail.value ", event.detail.value);
                 if (event?.detail?.value) {
                     this.fil2 = String(event.detail.value);
                 }
                 if (this.fil2 == 'מוצר' || event?.detail?.value == 'מוצר') {
                     this.isProduct = true;
                     this.isProductSubFamily = false;
                     this.isProductFamily = false;
                 }
                 else if (this.fil2 == 'משפחת מוצר' || event?.detail?.value == 'משפחת מוצר') {
                     this.isProduct = false;
                     this.isProductSubFamily = false;
                     this.isProductFamily = true;
                     this.product = null;
                 }
                 else if (this.fil2 == 'תת מוצר' || event?.detail?.value == 'תת מוצר') {
                     this.isProduct = false;
                     this.isProductFamily = false;
                     this.isProductSubFamily = true;
                     this.product = null;
                 } else {
                     this.isProduct = false;
                     this.isProductFamily = false;
                     this.isProductSubFamily = false;
                 }
             }
         
             accChanged(event) {
                 if (event?.detail?.value) {
                     this.acc = String(event.detail.value);
                     this.getCustomerSize();
                 }
                 if(this.acc && this.product){
                    console.log("RAZCHECK,195, 390: ", " accId:", this?.acc, " prodId: ", this?.product);
                    this.getRequestedDiscount();
                }
             }
         
             productChanged(event) {
                // console.log("RAZCHECK,350, event.detail",JSON.stringify(event.detail));
                // console.log("RAZCHECK,350, event.detail.value",event.detail.value);
                // debugger;
                 this.product = String(event.detail.value[0]);
                 console.log("RAZCHECK, 351 , this.product", this.product);
                 if(this.product){
                    this.isProduct = true;
                    console.log("RAZCHECK, 351 ,this.isProduct = true;");
                }
                else if(!this.product || this.product?.length == 0 || this.product === undefined){
                    this.isProduct = false;
                    console.log("RAZCHECK, 351 ,this.isProduct = false;");
                 }

                 this.getMatrixLineInfo();
                 this.getProductGravityValue();

                 if(this.acc && this.product){
                     console.log("RAZCHECK,195, 409: ", " accId:", this?.acc, " prodId: ", this?.product);
                     this.getRequestedDiscount();
                 }
         
             }
         
             productFamilyChanged(event) {
                 if (event?.detail?.value) {
                     this.productFamily = event.detail.value[0];
                     this.getMatrixLineInfo();
                 }
             }
             productSubFamilyChanged(event) {
                 if (event?.detail?.value) {
                     this.productSubFamily = String(event.detail.value);
                     this.getMatrixLineInfo();
                 }
             }
         
             // happens only if a discount was entered
             calculatePricesAfterDiscount(event) {
                 if (event?.detail?.value) {
                     this.requested = Number(event.detail.value);
                 }
                 else if (event?.detail && (!event.detail.value)) {
                     this.requested = 0;
                 }
                 if (this.tonnePriceBeforeDiscount) {
                     this.tonnePriceAfterDiscount = (this.tonnePriceBeforeDiscount * (1 - (this.requested ? this.requested : 0) / 100)).toFixed(2);
                     this.productPrice = this.tonnePriceAfterDiscount;
                 }
                 if (this.cubePriceBeforeDiscount) {
                     this.cubePriceAfterDiscount = (this.cubePriceBeforeDiscount * (1 - (this.requested ? this.requested : 0) / 100)).toFixed(2);
                 }
             }
            //  get getPriceAfterDiscount(){
            //     return  this.tonnePriceAfterDiscount;
            //  }
         
             editRecord() {
                 this.isEditMode = true;
                 this.fil1BeforeEdit = this.fil1;
                 this.fil2BeforeEdit = this.fil2;
             }
         
             handleReset(event) {
                 this.fil1 = this.fil1BeforeEdit;
                 this.fil2 = this.fil2BeforeEdit;
                 const inputFields = this.template.querySelectorAll('lightning-input-field');
                 if (inputFields) {
                     inputFields.forEach(field => { field.reset() });
                 }
                 this.isEditMode = false;
                 this.changeFil1();
                 this.changeFil2();
         
                 if (!this.recordId) {
                     this.isEditMode = false;
                     // Navigate to the Account home page
                     this[NavigationMixin.Navigate]({
                         type: 'standard__objectPage',
                         attributes: {
                             objectApiName: 'Discount__c',
                             actionName: 'home'
                         }
                     });
                 }
             }
         
        //  get testush (){
            
        //     return this.tonnePriceAfterDiscount;
        //  }
             submitForm(event) {
                 console.log("001 421 submitForm",event);
                 event.preventDefault();
                 let isFormValid = true;
                 try {
                     this.template.querySelectorAll('lightning-input').forEach(element => {
                         // present required fileds to USER! - reportValidity (same as Joi) validation of required fields, and other adjustable fields
                         element.reportValidity();
                         // if the current iterable object is not valid as required...
                         if (!element.checkValidity()) {
                             isFormValid = false;
                         }
                     })
                     if (this.submitionFlag && isFormValid) {
                         //if both handler bollean value and checked are true..
                         this.template.querySelector('lightning-record-edit-form').submit();
                         this.submitionFlag = false;
         
                     } if (this.submitionAndNewFlag && isFormValid) {
                         this.template.querySelector('lightning-record-edit-form').submit();
                     }
                 } catch (err) {
                     console.error(err);
                 }
             }
         
             submitClicked() {
                console.log("submitClicked, 448,raz");
                // console.log("submitClicked, 448,raz, isEdit",this.isEditMode);
                // console.log("submitClicked, 448,raz, this.AccountId",this.AccountId);
                console.log("submitClicked, 448,raz, this.hasDiscountInUrl",this.hasDiscountInUrl);
                this.submitionFlag = true;
             }
             submitAndNewClicked() {
                 this.submitionAndNewFlag = true; 
             }
         
             handleSuccess(event) {
                // debugger;
                console.log("001 455 handleSuccess", event);
                this.recordId = String(event.detail.id);

                this.isEditMode = false;
                Utils.showToast(this, "הצלחה", "הנחה חדשה נוצרה בהצלחה!", "success");
          
                if(this.submitionAndNewFlag){
                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Discount__c',
                            actionName: 'new',
                            recordId: ''
                        }
                    });  
                }
                else{
                    console.log("if(this.submitionFlag),484,Raz",this.submitionFlag);
                    this[NavigationMixin.Navigate]({
                        type: 'standard__objectPage',
                        attributes: {
                            objectApiName: 'Discount__c',
                            actionName: 'home'
                        }
                    });
                }
                // Check if the user arrived through the DeliveryNote__c page/object
 // Check if the user arrived through the DeliveryNote__c page/object
 //  if (this.submitionAndNewFlag) {
    if (!this.hasDiscountInUrl) {
    //     console.log("if, 448,488,raz, this.hasDiscountInUrl",this.hasDiscountInUrl);
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__objectPage',
    //         attributes: {
    //             objectApiName: 'DeliveryNote__c',
    //             actionName: 'home'
    //         },
    //         state: {       
    //             filterName: 'Recent' 
    //         }
    //     });    
    setTimeout(function() {
        window.close(); 
      }, 10000);
          } 
    Utils.showToast(this, "הצלחה", "הנחה חדשה נוצרה בהצלחה!", "success");
    }   

             handleError(event) {
                 Utils.showToast(this, "שגיאה", event.detail, "error");
                 console.log(`277. DiscountDetails -> handleError -> event.detail: ${JSON.stringify(event.detail)}`);
             }
         
             // display matrix rectangle
             get showMatrixData() {
                 return (this.fil1 == 'לקוח' && this.acc ) ? true : false;
             }
         
             // display prices rectangle
             get showPrice() { return (this.fil2 == 'מוצר' && this.product) ? true : false; }
             
             // change css classes according to screen size
             get tabClass() { return formFactor === 'Small' ? 'slds-col' : 'slds-grid'; }
             get oneOfTwo() { return formFactor === 'Small' ? 'slds-col' : 'slds-col slds-size_1-of-2'; }
             get oneOfThree() { return formFactor === 'Small' ? 'slds-col' : 'slds-col slds-size_1-of-3'; }
         
         
             // in matrix rectangle - classify and assign מוצר(null) / משפחת מוצרים / תת מוצר 
             get family() {
                 if (this.product){
                 return null;
                 }
                 if (this.productFamily) {
                     return this.productFamily;
                 }
                 if (this.productSubFamily) {
                     return this.productSubFamily;
                 }
             }

             get specificGravity() {
                if(this.specificGravityValue && this.specificGravityValue != '' ){
                  return this.specificGravityValue;
                }
                else{
                   return ``;
                }
              }

             get isAccountAndProuctDisplay() {
                if(this.isAccount && this.fil2 == 'מוצר' ){
                    console.log("RAZCHECK,591 ,isAccountAndProuctDisplay ---> True ");
                    return true;
                }
                else{
                    console.log("RAZCHECK,591 ,isAccountAndProuctDisplay ---> false ");
                   return false;
                }
              }

             get isProuctDisplay() {
                if(this.fil2 == 'מוצר' ){
                    console.log("RAZCHECK,591 ,isAccountAndProuctDisplay ---> True ");
                    return true;
                }
                else{
                   return false;
                }
              }
         
}