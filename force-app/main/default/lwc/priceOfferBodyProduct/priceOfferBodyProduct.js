import { api, track, wire, LightningElement } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import Utils from "c/utils";
import getPriceForProduct from '@salesforce/apex/discountDetailsController.getPriceForProduct';
import { createRecord } from 'lightning/uiRecordApi';
import getMatrixLineInfo from '@salesforce/apex/discountDetailsController.getMatrixLineInfo';
import getSalesPoints from '@salesforce/apex/OrderCustomerController.getSalesPoints';
import getProductNameAndDetails from "@salesforce/apex/OrderCustomerController.getProductNameAndDetails";
import getOliRelatedOrderItem from '@salesforce/apex/PriceOfferController.getOliRelatedOrderItem';
import isApprovingFactor from '@salesforce/apex/PriceOfferController.isApprovingFactor';
import calculateTotalTonWeight from '@salesforce/apex/orderItem_CalculateInfo.calculateTotalTonWeight';

// If record already exists - get this fields (rec info)
import OLI_PRODUCT from '@salesforce/schema/OpportunityLineItem.Product2Id';
import OLI_UNIT_PRICE from '@salesforce/schema/OpportunityLineItem.UnitPrice';
import OLI_TOTAL_PRICE from '@salesforce/schema/OpportunityLineItem.TotalPrice';
import OLI_CURRENCY from '@salesforce/schema/OpportunityLineItem.Currency__c';
import OLI_QUANTITY from '@salesforce/schema/OpportunityLineItem.Quantity';
import OLI_UNIT_OF_MEASURE from '@salesforce/schema/OpportunityLineItem.Unit_of_measure__c';
import OLI_OPP_ID from '@salesforce/schema/OpportunityLineItem.OpportunityId';
import OLI_DESCRIPTION from '@salesforce/schema/OpportunityLineItem.Description';
import OLI_TERMS_OF_PAYMENT from '@salesforce/schema/OpportunityLineItem.Terms_of_Payment__c';
import OLI_TRANSACTION_TYPE from '@salesforce/schema/OpportunityLineItem.Transaction_Type__c';
// import OLI_PACKING_TYPE from '@salesforce/schema/OpportunityLineItem.Packing_Type__c';
import OLI_LOADING_POINT from '@salesforce/schema/OpportunityLineItem.Loading_Point__c';
import OLI_FOREIGN_CURRENCY_INVOICE from '@salesforce/schema/OpportunityLineItem.Foreign_currency_invoice__c';
import OLI_DISCOUNT from '@salesforce/schema/OpportunityLineItem.Discount';
import OLI_DELIVERY_COST from '@salesforce/schema/OpportunityLineItem.DeliveryCost__c';
import OLI_TRANSPORTATION_CURRENCY from '@salesforce/schema/OpportunityLineItem.transportation_currency__c';
import OLI_CONVERSION_VALUE_DATE from '@salesforce/schema/OpportunityLineItem.conversionValueDate__c';
import OLI_REFILL_FEES from '@salesforce/schema/OpportunityLineItem.refillFees__c';

import OLI_DELIVERY_UNIT_OF_MEASURE from '@salesforce/schema/OpportunityLineItem.DeliveryUnitOfMeasure__c';

import OLI_PACKAGE_PRICE from '@salesforce/schema/OpportunityLineItem.PackagingPrice__c';
import OLI_OVER_BELOW from '@salesforce/schema/OpportunityLineItem.OverBelowAmount__c';
import OLI_SCALE_QUANTITY from '@salesforce/schema/OpportunityLineItem.ScaleQuantity__c';
import OLI_BASE_PRICE from '@salesforce/schema/OpportunityLineItem.Base_Price__c';
import OLI_PURACHASE_ORDER from '@salesforce/schema/OpportunityLineItem.Purchase_Order__c';

import BasePriceExist from "@salesforce/apex/PriceOfferController.BasePriceExist";


const fields = [
    OLI_PRODUCT,
    OLI_UNIT_PRICE,
    OLI_TOTAL_PRICE,
    OLI_CURRENCY,
    OLI_QUANTITY,
    OLI_UNIT_OF_MEASURE,
    OLI_OPP_ID,
    OLI_DESCRIPTION,
    OLI_TERMS_OF_PAYMENT,
    OLI_TRANSACTION_TYPE,
    // OLI_PACKING_TYPE,
    OLI_LOADING_POINT,
    OLI_FOREIGN_CURRENCY_INVOICE,
    OLI_DISCOUNT,
    OLI_DELIVERY_COST,
    OLI_TRANSPORTATION_CURRENCY,
    OLI_CONVERSION_VALUE_DATE,
    OLI_REFILL_FEES,
    OLI_DELIVERY_UNIT_OF_MEASURE,
    OLI_PACKAGE_PRICE,
    OLI_OVER_BELOW,
    OLI_SCALE_QUANTITY,
    OLI_BASE_PRICE,
    OLI_PURACHASE_ORDER
];
export default class PriceOfferBodyProduct extends LightningElement {
    
    @api oliId;
    @api oliRecord;
    @api oppId;
    @api oppRecord;
    @api accountId;
    @api recKey;
    @api defaultCurrencyIsoCode = 'ILS';
    maxDiscount = 0;
    targetDiscount = 0;
    isLoading = false;
    isApprovingFactorValue = false;
    isRegularTransactionType = false;
    basePriceCheckBoxValue = false;
    @track loadingPointOptions = [];
    isBasePriceExist = true;
    @track productName = '';
    @track oliRec = {
        Id: null,
        Product2Id: null,
        UnitPrice: null,
        Currency__c: this.defaultCurrencyIsoCode,
        Quantity: 1,
        Unit_of_measure__c: 'KG',
        OpportunityId: null,
        Terms_of_Payment__c: null,
        Transaction_Type__c: 'Regular', // רגיל' כברירת מחדל'
        // Packing_Type__c: null,
        Loading_Point__c: null,
        Description: null,
        Discount: 0,
        DeliveryCost__c: null,
        transportation_currency__c:null,
        conversionValueDate__c:null,
        refillFees__c:null,
        DeliveryUnitOfMeasure__c: null,
        PackagingPrice__c:null,
        OverBelowAmount__c:null,
        ScaleQuantity__c:null,
        Base_Price__c:null,
        Purchase_Order__c:null,
        Foreign_currency_invoice__c:null
    }

    isAddingNote = false;
    prodPrice; // prince {tonne: val, cube: val}
    loopCounter = 0;

    connectedCallback() {
        this.arrangeCurrentRec();
        this.updateDefaultUnitOfMeasure();
        this.getSalesPoints();
        this.getOliRelatedOrderItem();
    }
    // renderedCallback() {
        // this.isApprovingFactor();
    // }


    arrangeCurrentRec() {
        if (!this.oliRecord.Id) {
            console.log("RAZCHECK, 130,this.oliRecord ",JSON.stringify(this.oliRecord));
            this.oliRec = {
                Id: this.oliRecord.Id,
                Product2Id: this.oliRecord.Product2Id,
                UnitPrice: this.oliRecord.UnitPrice,
                Currency__c: this.oliRecord.Currency__c ? this.oliRecord.Currency__c : this.defaultCurrencyIsoCode,
                Quantity: Number.isInteger(this.oliRecord.Quantity) ? this.oliRecord.Quantity : 1,
                Unit_of_measure__c: this.oliRecord.Unit_of_measure__c,
                OpportunityId: this.oliRecord.OpportunityId,
                Terms_of_Payment__c: this.oliRecord.Terms_of_Payment__c,
                Transaction_Type__c: this.oliRecord.Transaction_Type__c,
                // Packing_Type__c: this.oliRecord.Packing_Type__c,
                Loading_Point__c: this.oliRecord.Loading_Point__c,
                Description: this.oliRecord.Description,
                Discount: 0,
                DeliveryCost__c: this.oliRecord.DeliveryCost__c,
                transportation_currency__c:this.oliRecord.transportation_currency__c,
                conversionValueDate__c:this.oliRecord.conversionValueDate__c,
                refillFees__c:this.oliRecord.refillFees__c,
                DeliveryUnitOfMeasure__c: this.oliRecord.DeliveryUnitOfMeasure__c,
                
                PackagingPrice__c:this.oliRecord.PackagingPrice__c,
                OverBelowAmount__c:this.oliRecord.OverBelowAmount__c,
                ScaleQuantity__c:this.oliRecord.ScaleQuantity__c,
                Base_Price__c:this.oliRecord.Base_Price__c,
                Purchase_Order__c:this.oliRecord.Purchase_Order__c,
                Foreign_currency_invoice__c:this.oliRecord.Foreign_currency_invoice__c,
            }
            console.log("RAZCHECK, 130,this.oliRec ",JSON.stringify(this.oliRec));

        }
        if(this.oppId){
            isApprovingFactor({oppId: this.oppId }).then((result) => {
                console.log("RAZCHECK, 162 isApprovingFactor: ", result);
                    this.isApprovingFactorValue= result;
        
            }).catch(err => {
                console.log("error isApprovingFactor: ", err);
            });    
        }
    }

    @wire(getRecord, { recordId: '$oliId', fields })
    populateOliFields({ error, data }) {
        try {
            this.isLoading = true;
            console.log("offer body product> populateOliFields data: ", JSON.stringify(data))
            if (data && !this.oliRec.Product2Id) { // Get record just once
                this.oliRec.Product2Id = data.fields.Product2Id.value;
                this.oliRec.UnitPrice = data.fields.UnitPrice.value;
                this.oliRec.Currency__c = data.fields.Currency__c.value;
                this.oliRec.Quantity = data.fields.Quantity.value;
                this.oliRec.Unit_of_measure__c = data.fields.Unit_of_measure__c.value;
                this.oliRec.OpportunityId = data.fields.OpportunityId.value;
                this.oliRec.Terms_of_Payment__c = data.fields.Terms_of_Payment__c.value;
                this.oliRec.Transaction_Type__c = data.fields.Transaction_Type__c.value;
                // this.oliRec.Packing_Type__c = data.fields.Packing_Type__c.value;
                this.oliRec.Loading_Point__c = data.fields.Loading_Point__c.value;
                this.oliRec.Foreign_currency_invoice__c = data.fields.Foreign_currency_invoice__c.value;
                this.oliRec.Description = data.fields.Description.value;
                this.oliRec.Discount = data.fields.Discount.value ? data.fields.Discount.value : 0;
                this.oliRec.DeliveryCost__c = data.fields.DeliveryCost__c.value;
                this.oliRec.transportation_currency__c = data.fields.transportation_currency__c.value;
                this.oliRec.conversionValueDate__c = data.fields.conversionValueDate__c.value;
                this.oliRec.refillFees__c = data.fields.refillFees__c.value;
                this.oliRec.DeliveryUnitOfMeasure__c = data.fields.DeliveryUnitOfMeasure__c.value;

                this.oliRec.PackagingPrice__c = data.fields.PackagingPrice__c.value;
                this.oliRec.OverBelowAmount__c = data.fields.OverBelowAmount__c.value;
                this.oliRec.ScaleQuantity__c = data.fields.ScaleQuantity__c.value;
                this.oliRec.Base_Price__c = data.fields.Base_Price__c.value;
                this.oliRec.Purchase_Order__c = data.fields.Purchase_Order__c.value;

                if (data.fields.Description.value)
                    this.isAddingNote = true;
                if (!this.isChemicals && !this.isFertJob) {
                    this.oliRec.UnitPrice = data.fields.UnitPrice.value;
                }

                this.getMatrixLineInfo();
                this.getProductPrice();

            } else if (error) {
                console.log(`Error: ${JSON.stringify(error)}`);
                let message = "@wire(getRecord): Unknown error in priceOfferBodyProduct component\n";

                if (Array.isArray(error.body))
                    message += error.body.map((e) => e.message).join(", ");
                else if (typeof error.body.message === "string")
                    message += error.body.message;
                Utils.showToast(this, "שגיאה", message, "error");
            }
        } catch (err) {
            console.error(err)
        }
        finally {
            this.isLoading = false;
        }
    }

    removeProduct(event) {
        this.dispatchEvent(new CustomEvent("removeoli", { detail: this.oliRecord }));
    }

    prodSelected(e) {
        this.oliRec.Product2Id = e.detail.value[0];
        this.oliRec.UnitPrice = null;
        this.oliRec.Base_Price__c = false;
        this.basePriceCheckBoxValue = false;
        try {
            console.log("RAZCHECK, 233,e.detail ",JSON.stringify(e.detail));
            console.log("RAZCHECK, 233,this.oliRec.Product2Id ",this.oliRec?.Product2Id);
            if(this.oliRec?.Product2Id !== "" && this.oliRec?.Product2Id){
                getProductNameAndDetails({productId:this.oliRec?.Product2Id }).then((response) => {
                    console.log("RAZCHECK, 233 238, getProductNameAndDetails",response[0]);
                    console.log("RAZCHECK, 233 , getProductNameAndDetails name",response[0].Name);
                    this.productName = response[0].Name;
                if (response[0].QuantityUnitOfMeasure) {
                        // במידה וקיים יחידת מידה דיפולטיבית למוצר
                        console.log("RAZCHECK, 238 , getProductNameAndDetails , QuantityUnitOfMeasure",response[0].QuantityUnitOfMeasure);
                        this.oliRec.Unit_of_measure__c = response[0].QuantityUnitOfMeasure;
               }
               else{

                 if (response[0].IL_BU__c == "כימיקלים" && response[0].IL_Group_name__c !== "נוקסיקליר") {
                    console.log("RAZCHECK,244 238 , getProductNameAndDetails ,כימיקלים TON");
                    this.rec.unitOfMeasure =this.oliRec.Unit_of_measure__c = "TO";
                }
                if (response[0].IL_BU__c == "כימיקלים" && response[0].IL_Group_name__c == "נוקסיקליר") {
                     console.log("RAZCHECK,248 238 , getProductNameAndDetails ,כימיקלים , נוקסיקליר ,",);
                     if(response[0].Packing__c){
                       console.log("RAZCHECK,250 238 , getProductNameAndDetails ,כימיקלים , נוקסיקליר ,EA",);
                       this.rec.unitOfMeasure =this.oliRec.Unit_of_measure__c = "EA";
                    }
                    else{
                       console.log("RAZCHECK,254 238 , getProductNameAndDetails ,כימיקלים , נוקסיקליר ,M3",);
                       this.rec.unitOfMeasure = this.oliRec.Unit_of_measure__c ="M3";
                    }
                }
                
            }
            console.log("RAZCHECK,260 238 , getProductNameAndDetails ,this.rec.unitOfMeasure",this.rec.unitOfMeasure);
                    if(this.productName !== ""){

                        if (this.productName.includes("נוקסיקליר")) {
                            
                            console.log("RAZCHECK, 233,this.oliRec.Unit_of_measure__c = m3 ");
                            this.oliRec.Unit_of_measure__c = "M3";
                        } else {
                            console.log("RAZCHECK, 233,this.oliRec.Unit_of_measure__c = TO ");
                            this.oliRec.Unit_of_measure__c = "TO";
                        }
                    }
                  }).catch((err) => console.log(err)
                  )
            }
            else{
                this.productName = "";
            }
            this.getProductPrice();
            console.log("this.accountId: ", this.accountId, "prodId: ", this.oliRec.Product2Id, "family: ", this.productFamily)
            this.getMatrixLineInfo();
        } catch (err) {
            console.error(err)
        }
        finally {

            // if(this.productName !== ""){

            //     if (this.productName.includes("נוקסיקליר")) {
            //         this.oliRec.Unit_of_measure__c = "M3";
            //     } else {
            //         this.oliRec.Unit_of_measure__c = "TO";
            //     }
            // }
            this.updatePrice();
            console.log("RAZCHECK, 233, this.oliRec.Unit_of_measure__c", this.oliRec.Unit_of_measure__c)
            console.log("RAZCHECK, 233, this.productName", this.productName)
        }
    }

    unitSelected(e) {
        console.log("RAZCHECK, 312, unitof_measure Selected: ", e.detail.value)
        this.oliRec.Unit_of_measure__c = e.detail.value;
        this.updatePrice();
    }
    discountChanged(e) {
        this.oliRec.Discount = e.detail.value;
        this.updatePrice();
    }
    unitPriceSelected(e) {        this.oliRec.UnitPrice = e.detail.value;
        this.updateDiscount();
    }
    currencySelected(e) {
         this.oliRec.Currency__c = e.detail.value
        console.log("RAZCHECK 288 ,this.oliRec.Currency__c ",this.oliRec.Currency__c);
        if(this.oliRec.Currency__c == "EUR" || this.oliRec.Currency__c == "USD"){
            this.oliRec.conversionValueDate__c = "יום הספקה";
        }
        else{
            this.oliRec.conversionValueDate__c = null;
        }
        console.log("RACHECK,288,this.oliRec.conversionValueDate__c ",this.oliRec.conversionValueDate__c);
        }
    quantityChanged(e) { this.oliRec.Quantity = e.detail.value }
    termsOfPaymentSelected(e) { this.oliRec.Terms_of_Payment__c = e.detail.value }
    transactionTypeSelected(e) {
        console.log("RAZCHECK, 242,e.detail.value ",e.detail.value);
        if(this.oliRec.Transaction_Type__c != "Including transport" && this.oliRec.DeliveryCost__c == 0 ){
            this.oliRec.DeliveryCost__c = null;
         }
         this.oliRec.Transaction_Type__c = e.detail.value;
         console.log("RAZCHECK, 242,this.oliRec.Transaction_Type__c ",this.oliRec.Transaction_Type__c);
         if(this.oliRec.Transaction_Type__c == "Regular"){
            console.log("RAZCHECK,245,this.oliRec.Transaction_Type__c,TRUE",this.oliRec.Transaction_Type__c);
            this.isRegularTransactionType = true;
         }
         else{
            this.isRegularTransactionType = false;;
         }	
         console.log("RAZCHECK,245,this.isRegularTransactionType",this.isRegularTransactionType);
         if(this.oliRec.Transaction_Type__c == "Including transport"){
            this.oliRec.DeliveryCost__c = 0;
         }
    
    }
    
    // packingTypeSelected(e) {

        //  this.oliRec.Packing_Type__c = e.detail.value;
    //     console.log("RAZCHECK, 271,e ",e);
    //     console.log("RAZCHECK, 271,e.detail.value ",e.detail?.value);
    //     console.log("RAZCHECK, 271,this.oliRec.Packing_Type__c ",this.oliRec?.Packing_Type__c);
    //      if(e.detail?.value){
    //          this.oliRec.Packing_Type__c = e.detail?.value;
    //          console.log("RAZCHECK, 271,this.oliRec.Packing_Type__c ",this.oliRec.Packing_Type__c);
    //     }
    // }

    handleLoadingPointChange(e) {
        // console.log("RAZCHECK, 256, event ",e);
        console.log("RAZCHECK, 256,event ",JSON.stringify(e.detail));
         this.oliRec.Loading_Point__c = e.detail.value;
        console.log("RAZCHECK, 256,this.oliRec.Loading_Point__c ",this.oliRec.Loading_Point__c);
        console.log("RAZCHECK, 256,e.detail.value ",e.detail.value);
        }
    foreignCurrencyChanged(e) {
        console.log("RACHECK,329,e ",e);
        console.log("RACHECK,329,e.detail ",JSON.stringify(e.detail));
        console.log("RACHECK,329,e.detail.value ",e.detail.value);
        console.log("RACHECK,329,e.detail.checked ",e.detail.checked);
        this.oliRec.Foreign_currency_invoice__c = e.detail.checked;
        console.log("RACHECK,329,this.oliRec.Foreign_currency_invoice__c ",this.oliRec.Foreign_currency_invoice__c);
         }
    descriptionChanged(e) { this.oliRec.Description = e.detail.value }
    deliveryCostChanged(e) { this.oliRec.DeliveryCost__c = e.detail.value }
    transportationCurrencyChanged(e) { this.oliRec.transportation_currency__c = e.detail.value }
    conversionValueDateChanged(e) {
         this.oliRec.conversionValueDate__c = e.detail.value;
         console.log("RACHECK,348,this.oliRec.conversionValueDate__c ",this.oliRec.conversionValueDate__c);
        }
    refillFeesChanged(e) { this.oliRec.refillFees__c = e.detail.value }
    deliveryUnitOfMeasureChanged(e) { this.oliRec.DeliveryUnitOfMeasure__c = e.detail.value }
    packagePriceChanged(e) { this.oliRec.PackagingPrice__c = e.detail.value }
    overBelowChanged(e) { this.oliRec.OverBelowAmount__c = e.detail.value }
    scaleQuantityChanged(e) { this.oliRec.ScaleQuantity__c = e.detail.value }
    BasePriceSelected(e) {
        const price = this.template.querySelectorAll(".priceInput");
        price.forEach((priceInput) => {
            console.log("RAZCHECK,307 , priceInput.value",priceInput.value);
            console.log("RAZCHECK,307 , priceInput.required",priceInput.required);
            console.log("RAZCHECK,307 , priceInput.invalid",priceInput.invalid);
            priceInput.reportValidity();
            priceInput.invalid = false;
        })
        this.basePriceCheckBoxValue = e.detail.checked;
        console.log("RAZCHECK, 282,this.oliRec.Base_Price__c ",this.oliRec.Base_Price__c);
         this.oliRec.Base_Price__c = e.detail.checked;
        console.log("RAZCHECK, 284,this.oliRec.Base_Price__c ",this.oliRec.Base_Price__c);
        console.log("RAZCHECK, 285,this.this.oppRecord.account.id ",this.oppRecord?.account?.id);
        console.log("RAZCHECK, 286,this.this.accountId ",this.accountId);
        if(this.oliRec.Base_Price__c){
            this.oliRec.UnitPrice = 0;
        BasePriceExist( {accountId:this.oppRecord?.account?.id, productId: this.oliRec?.Product2Id}).then(result => {
            console.log(`RAZCHECK, 288,  accountId ${this.oppRecord?.account?.id}, productId ${this.oliRec?.Product2Id}`);
            console.log("RAZCHECK, 288,  BasePriceExist results:",JSON.stringify(result));
           if (result==true) {
            const passEvent = new CustomEvent('basepricevalidation', {detail: true});
            this.dispatchEvent(passEvent);
            return;
           } else {
            this.isBasePriceExist= false;;
            const passEventt = new CustomEvent('basepricevalidation', {detail: false});
            this.dispatchEvent(passEventt);
            Utils.showToast(this,' שגיאה: חסר מחיר מחירון למוצר זה. לא ניתן לשמור הצעת מחיר', "error");
          }
          }).catch(error=>console.log("BasePriceExist error:",error));
            }
            else if(!this.basePriceCheckBoxValue){
            const passEventt = new CustomEvent('basepricevalidation', {detail: true});
            this.dispatchEvent(passEventt);
            }
        }
    PurchaseOrderSelected(e) { this.oliRec.Purchase_Order__c = e.detail.value }

    @api validateOli() {
        let isValid = false;

        if (!this.oliRec.Product2Id)
            Utils.showToast(this, "חסר מוצר", 'יש לבחור מוצר עבור כל שורות המוצר', "error");
        else if (!this.oliRec.Unit_of_measure__c)
            Utils.showToast(this, "חסרה יחידת מידה", 'יש לבחור יחידת מידה עבור כל שורות המוצר', "error");
        else if (this.oliRec.Discount == null)
            Utils.showToast(this, "חסרה הנחה", 'יש לבחור אחוז הנחה עבור כל שורות המוצר', "error");
        else if (this.isChemicals && !this.oliRec.Transaction_Type__c)
            Utils.showToast(this, "חסר סוג הובלה", 'יש לבחור סוג הובלה עבור כל שורות המוצר', "error");
        else if (this.isChemicals && !this.oliRec.Currency__c)
            Utils.showToast(this, "חסר מטבע", 'יש לבחור מטבע עבור כל שורות המוצר', "error");
        else if (!this.oliRec.UnitPrice && !this.basePriceCheckBoxValue)
            Utils.showToast(this, "חסר מחיר", 'יש לבחור מחיר עבור כל שורות המוצר', "error");
        else if ((this.oppRecord?.type === 'עסקת מסגרת' || this.oppRecord?.type === 'שרות') && !this.oliRec.Quantity)
            Utils.showToast(this, "חסר כמות", 'יש לבחור כמות עבור כל שורות המוצר', "error");
        else
            isValid = true;

        const passEventr = new CustomEvent('approveolivalidation', {
            detail: { isValid: isValid, key: this.oliRecord.key }
        });
        this.dispatchEvent(passEventr);
    }

    @api submitOLI(submitedOppRec) {
        this.oliRec.OpportunityId = submitedOppRec.id;

        const btn = this.template.querySelector('.oliSubmit1');
        if (btn) { btn.click() }
    }

    submitForm(event) {
        event.preventDefault();
        const fieldsSub = event.detail.fields;
        console.log("RAZCHECK,473 ,fieldsSub ",JSON.stringify(event.detail.fields));
        console.log("RAZCHECK,473 before,fieldsSub UnitPrice",JSON.stringify(event.detail.fields.UnitPrice));
        console.log("RAZCHECK,473 ,this.oliRec.UnitPrice ",this.oliRec.UnitPrice);
        fieldsSub.OpportunityId = this.oliRec.OpportunityId;
        fieldsSub.Loading_Point__c = this.oliRec.Loading_Point__c == 'ללא' ? null : this.oliRec.Loading_Point__c;
        fieldsSub.DeliveryCost__c = this.oliRec.DeliveryCost__c;
        fieldsSub.Currency__c = this.oliRec.Currency__c;
        fieldsSub.transportation_currency__c = this.oliRec.transportation_currency__c;
        fieldsSub.conversionValueDate__c = this.oliRec.conversionValueDate__c;
        fieldsSub.refillFees__c = this.oliRec.refillFees__c;
        fieldsSub.PackagingPrice__c = this.oliRec.PackagingPrice__c;
        fieldsSub.OverBelowAmount__c = this.oliRec.OverBelowAmount__c;
        fieldsSub.ScaleQuantity__c = this.oliRec.ScaleQuantity__c;
        fieldsSub.Base_Price__c = this.oliRec.Base_Price__c;
        fieldsSub.Purchase_Order__c = this.oliRec.Purchase_Order__c;
        fieldsSub.Foreign_currency_invoice__c = this.oliRec.Foreign_currency_invoice__c;
        fieldsSub.UnitPrice = +this.oliRec.UnitPrice;
        if(fieldsSub.UnitPrice == null){
            fieldsSub.UnitPrice = 0;
        }
        if (!this.isChemicals || this.oppRecord?.type === 'רגילה')
            fieldsSub.Quantity = 1;
        fieldsSub.Unit_of_measure__c = this.oliRec.Unit_of_measure__c;

        if (!this.isChemicals && !this.isFertJob) {
            // delete fieldsSub.UnitPrice;
            // fieldsSub.TotalPrice = +this.oliRec.UnitPrice;
            fieldsSub.UnitPrice = +this.oliRec.UnitPrice;
            fieldsSub.Discount = +this.oliRec.Discount;
        }
        // console.log(`RAZCHECK, 351,this.oliRec.Base_Price__c  ${this.oliRec.Base_Price__c}`);
        // console.log(`RAZCHECK, 351,fieldsSub.Base_Price__c  ${fieldsSub.Base_Price__c}`);
        console.log("RAZCHECK,473 after,fieldsSub UnitPrice",JSON.stringify(event.detail.fields.UnitPrice));
        console.log(`295. 473 PriceOfferBodyProduct -> submitForm -> fieldsSub: ${JSON.stringify(fieldsSub)}`);
        this.template.querySelector('lightning-record-edit-form').submit(fieldsSub);
    }

    handleSuccess(event) {
        // update the body component
        let isCreated = false;
        if (event?.detail?.id) {
            isCreated = true;
        }
        const oliCreatedEvent = new CustomEvent('olicreated', {detail: { isCreated: isCreated, key: this.oliRecord.key }});
        this.dispatchEvent(oliCreatedEvent);
    }

    handleError(event) {
        console.log(`027. PriceOfferBodyProduct -> handleError -> event.detail: `, event.detail);
        console.log(`028. PriceOfferBodyProduct -> handleError -> event.detail: ${JSON.stringify(event.detail)}`);
        console.log(`029. PriceOfferBodyProduct -> handleError -> event.detail.message: ${JSON.stringify(event.detail.message)}`);
        Utils.showToast(this, "Error", `Error: ${event.detail.message}`, "Error");
    }

    toggleNote() {
        this.isAddingNote = !this.isAddingNote;
    }

    @api copyRec() {
        this.oliId = null;
        this.oliRec.Id = null;
        this.oliRec.OpportunityId = null;
    }
    @api populateRec(rec) {
        console.log("099- populateRec: ", JSON.stringify(rec))
        this.oliRec = rec;
        console.log("populateRec 0100",JSON.stringify(this.oliRec));
    }
    duplicateProduct() {
        console.log("097- duplicateProduct: ", JSON.stringify(this.oliRec))
        const duplicateOliLine = new CustomEvent('oliduplication', {
            detail: { oliRec: this.oliRec }
        });
        this.dispatchEvent(duplicateOliLine);
    }

    // get product price {Tonne, Cube}
    getProductPrice() {
        getPriceForProduct({ productId: this.oliRec?.Product2Id }).then(result => {
                this.prodPrice = result;
                console.log("prodPrice: ", Object.values(this.prodPrice)[0]);
            }).catch(error => {
                console.log(`005. PriceOfferBodyProduct -> getPB -> error:`, error);
            });
    }

    updatePrice() {
        if (this.oppRecord?.scope == 'דשנים' && this.oliRec.Product2Id && this.prodPrice && Object.keys(this.prodPrice)?.length) {
            this.oliRec.UnitPrice = (this.convertPrice() * (1 - (this.oliRec.Discount / 100))).toFixed(2);
        }
    }

    convertPrice() {
        switch (this.oliRec.Unit_of_measure__c) {
            case 'ק"ג': return this.prodPrice.Tonnes / 1000;
            case 'KG': return this.prodPrice.Tonnes / 1000;
            case 'טון': return this.prodPrice.Tonnes;
            case "TO": return this.prodPrice.Tonnes;
            case 'ליטר': return this.prodPrice.Cubes / 1000;
            case 'LTR': return this.prodPrice.Cubes / 1000;
            case 'קוב': return this.prodPrice.Cubes;
            case "M3": return this.prodPrice.Cubes;
        }
    }

    updateDiscount() {
        if (this.oppRecord?.scope == 'דשנים' && this.oliRec.Product2Id && this.prodPrice && Object.keys(this.prodPrice).length) {
            switch (this.oliRec.Unit_of_measure__c) {
                case 'ק"ג': this.oliRec.Discount = ((1 - ((1000 * this.oliRec.UnitPrice) / this.prodPrice.Tonnes)) * 100).toFixed(2);
                    break;
                case 'KG': this.oliRec.Discount = ((1 - ((1000 * this.oliRec.UnitPrice) / this.prodPrice.Tonnes)) * 100).toFixed(2);
                    break;
                case 'טון': this.oliRec.Discount = ((1 - (this.oliRec.UnitPrice / this.prodPrice.Tonnes)) * 100).toFixed(2);
                    break;
                case 'TO': this.oliRec.Discount = ((1 - (this.oliRec.UnitPrice / this.prodPrice.Tonnes)) * 100).toFixed(2);
                    break;
                case 'ליטר': this.oliRec.Discount = ((1 - ((1000 * this.oliRec.UnitPrice) / this.prodPrice.Cubes)) * 100).toFixed(2);
                    break;
                case 'LTR': this.oliRec.Discount = ((1 - ((1000 * this.oliRec.UnitPrice) / this.prodPrice.Cubes)) * 100).toFixed(2);
                    break;
                case 'קוב': this.oliRec.Discount = ((1 - (this.oliRec.UnitPrice / this.prodPrice.Cubes)) * 100).toFixed(2);
                    break;
                case 'M3': this.oliRec.Discount = ((1 - (this.oliRec.UnitPrice / this.prodPrice.Cubes)) * 100).toFixed(2);
                    break;
            }
        }
    }

    getSalesPoints() { // נקודות מכירה
        getSalesPoints().then(res => {
            if (res.length > 0) {
                this.loadingPointOptions = [];
                this.loadingPointOptions.push({ label: 'ללא', value: 'ללא' })
                res.forEach(point => {
                    if (point.LoadingPointType__c != 'מחסן קונסיגנציה') {
                        this.loadingPointOptions.push({ label: point.LoadingPointName__c, value: point.Id })
                    }
                })
            }
        }).catch(err => {
            console.error(err.body.message);
        })
    }

    @api updateDefaultUnitOfMeasure() {
        if (this.oppRecord?.scope || this.loopCounter > 10) {
            this.oliRec.Unit_of_measure__c = this.isChemicals ? 'TO' : 'M3';
            this.updatePrice();
        }
        else {
            this.loopCounter++;
            setTimeout(() => { this.updateDefaultUnitOfMeasure(); }, 100);
        }
    }

    @api createDiscount() {
        const discountFields = {
            'Account__c': this.oppRecord.account.id,
            'Opportunity__c': this.oppId,
            'Display_Filter_1__c': 'לקוח',
            'Display_Filter_2__c': 'מוצר',
            'Start_Date__c': this.oppRecord.validFrom,
            'End_Date__c': this.oppRecord.validTo,
            'Product__c': this.oliRec.Product2Id,
            'Note__c': this.oliRec.Description,
            'Status__c': 'טיוטה',
            'Requested_Discount__c': this.oliRec.Discount
        };

        const discountRecord = { apiName: "Discount__c", fields: discountFields };

        createRecord(discountRecord).then(result => {
        }).catch(error => {
            console.log(`297. priceOfferBodyProduct -> createDiscount -> error: ${JSON.stringify(error)}`);
            Utils.showToast(this, "שגיאה", error.body.message, "error");
        });
    }
    productFamily;
    getMatrixLineInfo() {
        getMatrixLineInfo({ accId: this.oppRecord?.account?.id, prodId: this.oliRec?.Product2Id, family: this?.productFamily }).then((result) => {
            console.log("wiredMatrixLineInfo: ", result);
            // this.customerSize = data.Customer_Size__c;
            this.maxDiscount = result?.Max_Discount__c;
            this.targetDiscount = result?.Target_Discount__c;
        }).catch(err => {
            console.log("error getMatrixLineInfo: ", err);
            this.maxDiscount = 0;
            this.targetDiscount = 0;
        })
    }

    orderAmountOfProduct = 0;
    getOliRelatedOrderItem() {
        this.orderAmountOfProduct = 0;
        if (this.oliId) {
            getOliRelatedOrderItem({ oppLineItemId: this.oliId }).then((result) => {
                console.log("getOliRelatedOrderItem: ", result);
                result.forEach(item => {
                    if (item.UnitOfMeasure__c == 'TO') {
                        this.orderAmountOfProduct += item.Quantity;
                    }
                    else {
                        calculateTotalTonWeight({ Quantity: item.Quantity, UnitOfMeasure: item.UnitOfMeasure__c, gravity: item.Product2?.specific_gravity__c, productWeight: 0 }).then((result) => {
                            console.log("calculateTotalTonWeight: ", result);
                            this.orderAmountOfProduct += result;
                           
                        }).catch(err => {
                            console.log("error calculateTotalTonWeight: ", err);
                        })
                    }
                })
            }).catch(err => {
                console.log("error getOliRelatedOrderItem: ", err);
            })
        }
    }

    get showOrderAmountOfProduct() {
        return this.orderAmountOfProduct > 0 ? true : false;
    }
    get isQuantityVisible() {
        return (this.oppRecord?.type === 'עסקת מסגרת' || this.oppRecord?.type === 'שרות') ?
            "slds-col slds-size_1-of-2 slds-large-size_2-of-12 minWidth" : "slds-hide"
    }

    get showPriceForLiter() {
        return (this.oliRec.Unit_of_measure__c === 'LTR' || this.oliRec.Unit_of_measure__c === 'M3' || this.oliRec.Unit_of_measure__c === 'ליטר' || this.oliRec.Unit_of_measure__c === 'קוב') ?
            "slds-col slds-size_1-of-1 slds-large-size_1-of-4 verticalLineRight" : "slds-hide";
    }

    get priceForLiter() {
        if (this.oliRec.UnitPrice && (this.oliRec.Unit_of_measure__c === 'ליטר' || this.oliRec.Unit_of_measure__c === 'LTR'))
            return this.oliRec.UnitPrice;
        else if (this.oliRec.UnitPrice && (this.oliRec.Unit_of_measure__c === 'קוב' || this.oliRec.Unit_of_measure__c === 'M3'))
            return this.oliRec.UnitPrice / 1000;
        else
            return 0;
    }

    get toggleNoteBtnText() {
        return this.isAddingNote ? "- פרטים נוספים" : "+ פרטים נוספים";
    }

    get isChemicals() {
        return this.oppRecord?.scope === 'כימיקלים';
    }

    get isFertJob() {
        return this.oppRecord?.type === 'עבודת דישון';
    }

    get isDraft() {
        return this.oppRecord?.status == 'Draft' || this.oppRecord?.status == 'טיוטה';
    }

    get isNotDraft() {
        if(this.isApprovingFactorValue){
            return false;
        }
        else{
            return !this.isDraft;
        }
    }

    get getDeliveryCostGetter() {
        if(this.oliRec.Transaction_Type__c === "Including transport"){
            console.log("RAZCHECK ,getDeliveryCostGetter, 619, true ");
            return true;
        }
        else{
            if(this.isApprovingFactorValue){
                return false;
            }
            else{
                return !this.isDraft;
            }
        }
    }

    get isPriceAvailable(){
        if(this.isApprovingFactorValue){
            return false;
        }
        else{
            if(this.basePriceCheckBoxValue){
                return true;
            }
            else{
                return !this.isDraft;
            } 
        }

    }

    get isBasePriceAvailable(){
        if(!this.oppRecord?.account?.id || !this.oliRec?.Product2Id ){
            return true;
        }
        else{
            return !this.isDraft;
        }
    }

    get showMatrixData() {
        return (this.oppRecord?.scope == 'דשנים' && (this.oppRecord?.type === 'עסקת מסגרת' || this.oppRecord?.type === 'רגילה')) ?
            true : false;
    }

    get isRegularTransactionTypeValue(){
        return this.isRegularTransactionType ? true : false;
    }

    get isBasePriceValueTrue(){
        return this.basePriceCheckBoxValue ? false : true;
    }
}