import { LightningElement, wire, api, track } from "lwc";
import { getRecord } from 'lightning/uiRecordApi';
// import getPlots from "@salesforce/apex/YearlyPlanController.getPlots";
import getAllPlots from "@salesforce/apex/PriceOfferController.getAllPlots";
import updateLastViewed from '@salesforce/apex/CustomLookUpController.updateLastViewed';
import getPriceForProduct from '@salesforce/apex/discountDetailsController.getPriceForProduct';
import getDiscount from '@salesforce/apex/getProductDiscount.getDiscountRec';
import getFertPrdPriceBeforeDiscount from '@salesforce/apex/FertalzationJobCalc.getFertPrdPriceBeforeDiscount';
import getFertPrdPriceAfterDiscount from '@salesforce/apex/FertalzationJobCalc.getFertPrdPriceAfterDiscount';
import getTotalFertJob from '@salesforce/apex/FertalzationJobCalc.getTotalFertJob';
import getFertJobPriceBook from '@salesforce/apex/PriceOfferController.getFertJobPriceBook';
import Utils from "c/utils";
import { formatter } from "c/utils";
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { refreshApex } from '@salesforce/apex';
import FORM_FACTOR from '@salesforce/client/formFactor';

// Fields for the product lookup search
import PROD_ID from '@salesforce/schema/Product2.Id';
import PROD_NAME from '@salesforce/schema/Product2.Name';
import PROD_IL_GROUP from '@salesforce/schema/Product2.IL_Group__c';
import PROD_FERT_JOB_NUM from '@salesforce/schema/Product2.Fertilize_Job_number_of_product__c';
import PROD_SRC_SYS from '@salesforce/schema/Product2.Source_System__c';

import OLI_PRODUCT from '@salesforce/schema/OpportunityLineItem.Product2Id';
import OLI_PROD_NAME from '@salesforce/schema/OpportunityLineItem.Product2.Name';
import OLI_NUM_OF_PRODS from '@salesforce/schema/OpportunityLineItem.Product2.Fertilize_Job_number_of_product__c';
import OLI_COST_LEVEL from '@salesforce/schema/OpportunityLineItem.Cost_level__c';
import OLI_PLACE_OF_UNLOADING from '@salesforce/schema/OpportunityLineItem.Discharge_Location__c';
import OLI_PLACE_OF_UNLOADING_NAME from '@salesforce/schema/OpportunityLineItem.Discharge_Location__r.Name';
import OLI_NEED_A_CART from '@salesforce/schema/OpportunityLineItem.Need_a_cart__c';
import OLI_IS_EXTENSION from '@salesforce/schema/OpportunityLineItem.Is_Extension__c';
import OLI_EXTENSION_1 from '@salesforce/schema/OpportunityLineItem.Extension_1__c';
import OLI_EXTENSION_2 from '@salesforce/schema/OpportunityLineItem.Extension_2__c';
import OLI_DESCRIPTION from '@salesforce/schema/OpportunityLineItem.Description';
import OLI_QUANTITY from '@salesforce/schema/OpportunityLineItem.Quantity';
import OLI_QUANTITY_DUNAM from '@salesforce/schema/OpportunityLineItem.Quantity_per_hectare__c';
import OLI_UNIT_OF_MEASURE from '@salesforce/schema/OpportunityLineItem.Unit_of_measure__c';
import OLI_TOTAL_PRICE from '@salesforce/schema/OpportunityLineItem.TotalPrice';
import OLI_UNIT_PRICE from '@salesforce/schema/OpportunityLineItem.UnitPrice';
import OLI_CURRENCY from '@salesforce/schema/OpportunityLineItem.Currency__c';
import OLI_DISCOUNT from '@salesforce/schema/OpportunityLineItem.Discount';
import OLI_ACTUAL_QUANTITY_PER_HECTARE from '@salesforce/schema/OpportunityLineItem.ActualQuantityPerHectare__c';
import OLI_ACTUAL_UNIT_OF_MEASURE from '@salesforce/schema/OpportunityLineItem.ActualUnitOfMeasure__c';


import OLI_PLOTS from '@salesforce/schema/OpportunityLineItem.Plots__c';

const lookupFields = [PROD_ID, PROD_NAME, PROD_FERT_JOB_NUM, PROD_IL_GROUP, PROD_SRC_SYS];
const fertFields = [OLI_PRODUCT, OLI_PROD_NAME, OLI_QUANTITY, OLI_QUANTITY_DUNAM, OLI_UNIT_OF_MEASURE, OLI_UNIT_PRICE, OLI_TOTAL_PRICE, OLI_CURRENCY, OLI_DISCOUNT, OLI_ACTUAL_QUANTITY_PER_HECTARE, OLI_ACTUAL_UNIT_OF_MEASURE];
const fields = [
    OLI_PRODUCT,
    OLI_PROD_NAME,
    OLI_NUM_OF_PRODS,
    OLI_PLOTS,
    OLI_COST_LEVEL,
    OLI_PLACE_OF_UNLOADING,
    OLI_PLACE_OF_UNLOADING_NAME,
    OLI_NEED_A_CART,
    OLI_IS_EXTENSION,
    OLI_EXTENSION_1,
    OLI_EXTENSION_2,
    OLI_DESCRIPTION
];


export default class FertJobBodyProduct extends LightningElement {

    ///// dischargeLocation //
    @track dischargeLocation = { id: null, name: null };
    @track dischargeLocationName;
    @track dischargeLocationId;
    tankPointsFields = 'Id, Name, Account__c, Account__r.Name, RelatedContact__c, RelatedContact__r.Name, RelatedContact__r.Phone, RelatedContact__r.MobilePhone';


    @api oliId;
    @api oliRecord;
    submitClicked = false;

    ///////    Opp vars    ///////

    @api oppId;
    @api oppRecord;
    @api accountId; // Account Id to get only relevant plots

    /////////////////////////////////

    /////   Fert Job vars   /////  
    @track prodFamily = '';
    @track caculateTotalFertJobPrice;
    @track firstPriceDiscount;
    @track secondPriceDiscount;
@track dischargeLocationRequierd = true;

    @track selectedProd;
    @track allPlotsData;
    @track selectedPlots = [];
    @track selectedPlotsData = [];
    costLevel; // can be A, B or C
    @track needCart = 'No';

    @track wiredPlotsData;
    allPlotsDataMap;
    sumSize;
    plotNames;
    growthName;

    submitedOppRec;
    submitedFertJobRec;
    submitedfert1Rec;
    submitedfert2Rec;

    ////////////////////////////

    /////   Fert Prod 1 vars   /////

    @track fertId1; // the oli id
    firstProduct;
    firstProdQuantity; // per dunam
    firstUnitOfMeasure;
    firstProductDiscount;
    firstProductPrice;
    firstTotalPrice;
    firstPrice
    /////////////////////////////////

    /////   Fert Prod 2 vars   /////

    @track fertId2; // the oli id
    secondProduct;
    secondProdQuantity; // per dunam
    secondUnitOfMeasure;
    secondProductDiscount;
    secondProductPrice;
    secondTotalPrice;
    secondPrice
    /////////////////////////////////

    openPlotModalAdder = false;
    openDischargeLocationAdder = false;
    isAddingNote = false;
    extrawhereclause = ' AND (Fertilize_Job_number_of_product__c = \'1\' OR Fertilize_Job_number_of_product__c = \'2\')';
    lookupFields = lookupFields.map(field => field.fieldApiName).join(', ');
    hasRendered = true;
    channelName = "/event/Plot_Created__e"; // Channel name for subscribing into PlatformEvents
    @track fertJobPriceBook;
    fertJobTotalPrice = 0;
    
    @api defaultCurrencyIsoCode = 'ILS';

    @wire(getRecord, { recordId: '$oliId', fields: fields })
    getFertJobInfo({ error, data }) {
        if (data) {
            console.log("getFertJobInfo: ", JSON.stringify(data))
            this.selectedProd = {
                Name: data.fields.Product2.value.fields.Name.value,
                Fertilize_Job_number_of_product__c:
                    data.fields.Product2.value.fields.Fertilize_Job_number_of_product__c.value,
                Id: data.fields.Product2Id.value
            };
            this.selectedProductId = data.fields.Product2Id.value;

            this.costLevel = data.fields.Cost_level__c.value;
            this.dischargeLocationId = data.fields.Discharge_Location__c.value;
            this.dischargeLocationName = data.fields.Discharge_Location__r.displayValue;
            this.needCart = data.fields.Need_a_cart__c.value;
            this.fertId1 = data.fields.Extension_1__c.value;
            this.selectedPlots = data.fields.Plots__c.value.split(", ");

            this.updateSelectedPlotsData();
            this.updateMultiSelect();
            this.calculatePlots(false);

            if (this.isTwoFertJob)
                this.fertId2 = data.fields.Extension_2__c.value;

            if (data.fields?.Description?.value)
                this.isAddingNote = true;

        } else if (error) {
            console.log(`Error: ${JSON.stringify(error)}`);
            let message = "@wire(getRecord): Unknown error in priceOfferBodyProduct component\n";

            if (Array.isArray(error.body))
                message += error.body.map((e) => e.message).join(", ");
            else if (typeof error.body.message === "string")
                message += error.body.message;

            Utils.showToast(this, "שגיאה", message, "error");
        }
    }
    fertJob1InfoUpdate(fertJob, data) {
        const passEventr = new CustomEvent('fertjob1infoupdate', {
            detail: { fertJob, data }
        });
        this.dispatchEvent(passEventr);
    }

    fertJob2InfoUpdate(fertJob, data) {
        const passEventr = new CustomEvent('fertjob2infoupdate', {
            detail: { fertJob, data }
        });
        this.dispatchEvent(passEventr);
    }

    @wire(getRecord, { recordId: "$fertId1", fields: fertFields })
    getFert1Info({ error, data }) {
        if (data) {
            console.log("getFert1Info: ", JSON.stringify(data));
            this.firstProdQuantity = data.fields.Quantity_per_hectare__c.value;
            this.firstUnitOfMeasure = data.fields.Unit_of_measure__c.value;
            this.firstProduct = data.fields.Product2Id.value;
            this.firstTotalPrice = data.fields.TotalPrice.value;
            this.firstProductDiscount = data.fields.Discount.value;
            // this.firstFert = data.fields.Product2;
            let fertJob = {
                id: this.fertId1,
                product: this.firstProduct,
                productName: data.fields.Product2.displayValue,
                quantity: this.firstProdQuantity,
                unitOfMeasure: this.firstUnitOfMeasure
            }
            this.fertJob1InfoUpdate(fertJob, data)
            this.handleFirstDiscountPrice();
        } else if (error) {
            console.log(`Error: ${JSON.stringify(error)}`);
            let message = "@wire(getRecord): Unknown error in priceOfferBodyProduct component\n";

            if (Array.isArray(error.body))
                message += error.body.map((e) => e.message).join(", ");
            else if (typeof error.body.message === "string")
                message += error.body.message;

            Utils.showToast(this, "שגיאה", message, "error");
        }

    }

    @wire(getRecord, { recordId: '$fertId2', fields: fertFields })
    getFert2Info({ error, data }) {
        if (data) {
            console.log("getFert2Info: ", JSON.stringify(data));

            this.secondProdQuantity = data.fields.Quantity_per_hectare__c.value;
            this.secondUnitOfMeasure = data.fields.Unit_of_measure__c.value;
            this.secondProduct = data.fields.Product2Id.value;
            this.secondTotalPrice = data.fields.TotalPrice.value;
            this.secondPriceDiscount = data.fields.Discount.value;

            let fertJob = {
                id: this.fertId2,
                product: this.secondProduct,
                productName: data.fields.Product2.displayValue,
                quantity: this.secondProdQuantity,
                unitOfMeasure: this.secondUnitOfMeasure
            }
            this.fertJob2InfoUpdate(fertJob, data)
            this.handleSecondDiscountPrice();

        } else if (error) {
            console.log(`Error: ${JSON.stringify(error)}`);
            let message = "@wire(getRecord): Unknown error in priceOfferBodyProduct component\n";

            if (Array.isArray(error.body))
                message += error.body.map((e) => e.message).join(", ");
            else if (typeof error.body.message === "string")
                message += error.body.message;

            Utils.showToast(this, "שגיאה", message, "error");
        }

    }

    @wire(getAllPlots, { accId: "$accountId" })
    plots(result) {
        this.wiredPlotsData = result; // Track the 'wiredPlotsData'
        console.log("plots: ", result, this.accountId)
        if (result.data && (this.accountId != null && this.accountId != "")) {
            this.allPlotsData = result.data.map((record) =>
                Object.assign({ label: record.Name, value: record.Id })
            );
            Utils.sortDualListboxValues(this.allPlotsData);
            this.allPlotsDataMap = result.data.map((record) =>
                Object.assign({
                    key: record.Id,
                    label: record.Name,
                    size: record.Plot_Size__c,
                    growth: record.Branch_growth__r.Name
                })
            );
            this.updateMultiSelect();
        } else if (result.error) {
            console.log(`231. FertJobBodyProduct -> @wire plots - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
            console.log(`FertJobBodyProduct -> @wire plots: `, error);
            this.error = result.error;
            this.allPlotsData = null;
        }
    }

    @wire(getPriceForProduct, { productId: "$firstProduct" })
    firstProdPrice(result) {
        if (result.data) {
            this.firstProductPrice = result.data;
            this.firstPrice = result.data.Tonnes;
            console.log("8080: this.firstProductPrice: ", this.firstProductPrice)
            this.handleFirstDiscountPrice();
        } else if (result.error) {
            console.log(`237. FertJobBodyProduct -> @wire secondProdPrice - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
        }

    }

    @wire(getPriceForProduct, { productId: "$secondProduct" })
    secondProdPrice(result) {
        if (result.data) {
            this.secondProductPrice = result.data;
            this.handleSecondDiscountPrice();
        } else if (result.error) {
            console.log(`238. FertJobBodyProduct -> @wire secondProdPrice - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
        }
    }

    @wire(getDiscount, { Account: "$accountId", prd: "$firstProduct" })
    firstProdDiscount(result) {
        console.log("get Lilach Discount: ", JSON.stringify(result))
        if (result.data) {
            // if there is atlist one discount
            this.firstProductDiscount = result.data?.Requested_Discount__c;
        } else if (result.error) {
            console.log(`239. FertJobBodyProduct -> @wire plots - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
        } else // there is no discount
            this.firstProductDiscount = null;
    }

    @wire(getDiscount, { Account: "$accountId", prd: "$secondProduct" })
    secondProdDiscount(result) {
        if (result.data) {
            // if there is atlist one discount
            this.secondProductDiscount = result.data?.Requested_Discount__c;
        } else if (result.error) {
            console.log(`249. FertJobBodyProduct -> @wire plots - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
        }
        else // there is no discount
            this.secondProductDiscount = null;
    }
    @wire(getFertJobPriceBook, { prodId: "$selectedProductId" })
    fertJobPB(result) {
        console.log(" this.fertJobPriceBook: ", JSON.stringify(result));

        if (result.data) {
            // if there is atlist one price book
            if (result.data?.length) {
                this.fertJobPriceBook = result.data[0];
                console.log(" this.fertJobPriceBook: ", this.fertJobPriceBook);
                console.log(" this.this.firstTotalPrice: ", this.firstTotalPrice + ',this.secondTotalPrice:' + this.secondTotalPrice);
                this.getTotalFertJob(this.accountId, this.selectedProductId, this.firstProduct, this.secondProduct, this.firstProdQuantity, this.firstUnitOfMeasure,
                    this.secondProdQuantity, this.secondUnitOfMeasure, this.needCart, this.costLevel, this.sumSize, this.firstTotalPrice, this.secondTotalPrice)
            }
            // there is no discount
            else {
                this.fertJobPriceBook = null;
                Utils.showToast(this, "חסר מחירון", 'אין מחירון תקף למוצר זה', "error");

            }
        } else if (result.error) {
            console.log(`323. FertJobBodyProduct -> @wire fertJobPB - in ERROR-> result.error: ${JSON.stringify(result.error)}`);
        }
    }
    getFertPrdPriceBeforeDiscount(prdId, quantity, sumSize, unitMeasure) {
        // const unitOfMeasure = Utils.getUnitOfMeasureName(unitMeasure);
        console.log("getFertPrdPriceBeforeDiscount query: ",{ prdId: prdId, AccId: this.accountId, QuantityPerHectare: quantity, plotTotalSize: sumSize, unitMeasure: unitMeasure })
        getFertPrdPriceBeforeDiscount({ prdId: prdId, AccId: this.accountId, QuantityPerHectare: quantity, plotTotalSize: sumSize, unitMeasure: unitMeasure }).then(res => {
            console.log("getFertPrdPriceBeforeDiscount: ", res)
            if (this.firstProduct == prdId) {
                this.firstPrice = res;
            }
            if (this.secondProduct == prdId) {
                this.secondPrice = res;
                console.log('this.secondPrice:' + this.secondPrice);
            }
            this.getFertPrdPriceAfterDiscount(prdId, this.accountId, res)
        }).catch(err => {
            console.error(err)
        })
    }

    getFertPrdPriceAfterDiscount(prdId, accId, fertPrdPriceBeforeDisc) {
        console.log("getFertPrdPriceAfterDiscount: fertPrdPriceBeforeDisc", fertPrdPriceBeforeDisc)
        getFertPrdPriceAfterDiscount({ prdId: prdId, accId: accId, fertPrdPriceBeforeDisc: fertPrdPriceBeforeDisc }).then(res => {
            console.log("getFertPrdPriceAfterDiscount: ", res)
            console.log("getFertPrdPriceAfterDiscount: ", this.selectedProductId, this.firstProduct, this.secondProduct, this.firstProdQuantity, 
            this.firstUnitOfMeasure, this.secondProdQuantity, this.secondUnitOfMeasure, this.needCart, this.costLevel, this.sumSize, this.firstTotalPrice, this.secondTotalPrice)
            if (this.firstProduct == prdId) {
                this.firstTotalPrice = res;
                this.firstPriceDiscount = `${formatter.format(this.firstTotalPrice)} (${((fertPrdPriceBeforeDisc - res) / fertPrdPriceBeforeDisc * 100).toFixed(0)}%-)`;
            }
            if (this.secondProduct == prdId) {
                this.secondTotalPrice = res;
                this.secondPriceDiscount = `${formatter.format(this.secondTotalPrice)} (${((fertPrdPriceBeforeDisc - res) / fertPrdPriceBeforeDisc * 100).toFixed(0)}%-)`;
            }
            this.getTotalFertJob(this.accountId, this.selectedProductId, this.firstProduct, this.secondProduct, this.firstProdQuantity, this.firstUnitOfMeasure,
                this.secondProdQuantity, this.secondUnitOfMeasure, this.needCart, this.costLevel, this.sumSize, this.firstTotalPrice, this.secondTotalPrice)
        }).catch(err => {
            console.error(err)
        })
    }

    getTotalFertJob(accId, PrdId, Fert1, Fert2, QuantityPerHectare1, unitMeasure1, QuantityPerHectare2, unitMeasure2, needCart, costLevel, plotTotalSize, Fert1Price, Fert2Price) {
        getTotalFertJob({ accId, PrdId, Fert1, Fert2, QuantityPerHectare1, unitMeasure1, QuantityPerHectare2, unitMeasure2, needCart, costLevel, plotTotalSize, Fert1Price, Fert2Price }).then(res => {
            console.log("getTotalFertJob: ", res)
            this.caculateTotalFertJobPrice = `${formatter.format(res)}`;
            this.dispatchEvent(new CustomEvent( "fertjobpriceupdate",
                { detail: { price: res, plotSize: this.sumSize, key: this.oliRecord.key } }
            ));
        }).catch(err => {
            console.error(err)
        })
    }


    handleSubscribe() {
        this.registerErrorListener();    // Callback invoked whenever a new event message is received

        const messageCallback = function (response) { // Response contains the payload of the new message received
            // console.log('YPE: PlatformEvent Recieved: New Plot was created. \nRefreshing UI...');
            refreshApex(this.wiredPlotsData); // Refresh the wired method which include wiredPlotsData. This will force the UI to refresh
        };

        // console.log("Subscribing...");
        subscribe(this.channelName, -1, messageCallback.bind(this)).then(response => { // Invoke subscribe method of empApi. Pass reference to messageCallback
            // console.log('Subscription request sent to: ', JSON.stringify(response.channel));  // Response contains the subscription information on subscribe call
            this.subscription = response;
        });
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            // console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    unsubscribeFromCreatedPlotEventListener() {
        // console.log('in unsubscribe...');
        unsubscribe(this.subscription, response => {
            // console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    updateSelectedPlots(e) {
        this.selectedPlots = e.detail.selectedValues;
        this.updateSelectedPlotsData();
        this.calculatePlots(true);
    }

    calculatePlots(changeCostLevel) {
        try {

            this.sumSize = 0;
            this.plotNames = "";
            this.growthName = "";
            for (const i in this.selectedPlotsData) {
                this.sumSize += this.selectedPlotsData[i].size;
                this.plotNames += this.selectedPlotsData[i].label + " ; ";
                this.growthName = this.selectedPlotsData[i].growth;
            }
            this.plotNames = this.plotNames.slice(0, -2);

            if (changeCostLevel) {
                if (this.sumSize < 100)
                    this.costLevel = 'A';
                else if (this.sumSize < 200)
                    this.costLevel = 'B';
                else
                    this.costLevel = 'C';
            }
            this.handleFirstDiscountPrice()
        } catch (err) {
            console.log("error calculate Plots: ", err);
        }
    }

    updateSelectedPlotsData() {
        if (this.allPlotsDataMap?.length) {
            this.selectedPlotsData = this.selectedPlots.map(
                (select) => this.allPlotsDataMap.filter((option) => option.key == select)[0]
            );
        }
    }

    toggleNote() {
        this.isAddingNote = !this.isAddingNote;
    }

    removeProduct(event) {
        this.dispatchEvent(new CustomEvent("removeoli", { detail: this.oliRecord }));
    }

    @track selectedProductId;
    prodSelected(event) {
        console.log("012",event.detail.selectedRec);
        if (event?.detail?.selectedRec) {
            this.selectedProd = event.detail.selectedRec;
            this.selectedProductId = event.detail.selectedRecordId;
            this.prodFamily = event.detail.selectedRec?.IL_Group__c ? event.detail.selectedRec?.IL_Group__c : '';
            console.log("prodSelected : ", JSON.stringify(this.selectedProd), "Id: ", this.selectedProductId);
            updateLastViewed({ objectName: 'Product2', recId: event.detail.selectedRec.Id })
                .catch(err => {
                    console.log(`067. FertJobBodyProduct -> prodSelected -> error: ${JSON.stringify(err)}`);
                    console.error('Error ocured on Lastviewed update: ' + err);
                });
        }
        else { // Product unselected
            this.selectedProd = null;
        }
    }

    costLevelChanged(event) {
        if (event?.detail) {
            this.costLevel = event.detail.value;
            if (this.firstProduct) {
                this.handleFirstDiscountPrice();
            }
            if (this.secondProduct) {
                this.handleSecondDiscountPrice();
            }
        }
    }

    dischargeLocationChanged(event) {
        if (event?.detail)
            this.dischargeLocationId = event.detail.selectedRecordId;
        this.dischargeLocationName = event.detail.selectedValue;
    }

    needCartChanged(event) {
        this.needCart = event.detail.value;
        if (this.firstProduct) {
            this.handleFirstDiscountPrice();
        }
        if (this.secondProduct) {
            this.handleFirstDiscountPrice();
        }
    }

    firstProductChanged(event) {
        if (event?.detail) {
            console.log("firstProductChanged: ", JSON.stringify(event.detail))
            this.firstProduct = event.detail.value[0];
            this.handleFirstDiscountPrice();
        }
    }

    secondProductChanged(event) {
        if (event?.detail) {
            this.secondProduct = event.detail.value[0];
            this.handleSecondDiscountPrice();
        }
    }

    firstProdQuantityChanged(event) { // 
        this.firstProdQuantity = event.detail.value;
        this.handleFirstDiscountPrice();
    }

    secondProdQuantityChanged(event) {
        this.secondProdQuantity = event.detail.value;
        this.handleSecondDiscountPrice();
    }

    firstUnitOfMeasureChanged(event) { // פונקציה זו נקראת פעמיים - גם בהזד' חדשה וגם בקיימת!
        if (event?.detail) {
            this.firstUnitOfMeasure = event.detail.value;
            console.log("firstUnitOfMeasure in firstUnitOfMeasureChanged",this.firstUnitOfMeasure);
            this.handleFirstDiscountPrice();
        }
    }

    secondUnitOfMeasureChanged(event) { // אינפוט כמות לדונם אחרי שמירה, בהזדמנות קיימת - לא נכון! לא נקראת בכלל!
        if (event?.detail) {
            this.secondUnitOfMeasure = event.detail.value;
            console.log("line 587 secondUnitOfMeasureChanged",this.secondUnitOfMeasure);
            this.handleSecondDiscountPrice();
        }
    }

    @api validateOli() {
        try {
            this.calculatePlots(false);

            let isValid = false;
            // Check fert Job
            if (!this.selectedProd)
                Utils.showToast(this, "(סוג עבודה)חסר מוצר", 'יש לבחור מוצר עבור כל שורות המוצר', "error");
            else if (!this.selectedPlots.length)
                Utils.showToast(this, "לא נבחרו חלקות", 'יש לבחור לפחות חלקה אחת עבור כל שורות המוצר', "error");
            else if (!this.sumSize)
                Utils.showToast(this, "גודל החלקות הוא 0", 'סך גודל החלקות צריך להיות גדול מ 0 עבור כל שורות המוצר', "error");
            else if (!this.costLevel)
                Utils.showToast(this, "לא נבחרה מדרגת עלות", 'יש לבחור מדרגת עלות עבור כל שורות המוצר', "error");
            else if (!this.dischargeLocationId)
                Utils.showToast(this, "לא נבחר מקום פריקה", 'יש לבחור מקום פריקה עבור כל שורות המוצר', "error");
            else if (!this.fertJobPriceBook)
                Utils.showToast(this, "חסר מחירון", 'אין מחירון תקף למוצר זה', "error");

            // Check first fertilizer
            else if (!this.firstProduct.length)
                Utils.showToast(this, "חסר דשן", 'יש לבחור דשן עבור כל שורות המוצר', "error");
            else if (!this.firstProdQuantity)
                Utils.showToast(this, "חסרה כמות", 'יש לבחור כמות עבור כל שורות המוצר', "error");
            else if (!this.firstUnitOfMeasure)
                Utils.showToast(this, "חסרה יחידת מידה", 'יש לבחור יחידת מידה עבור כל שורות המוצר', "error");
            else if (!this.firstTotalPrice)
                Utils.showToast(this, "חסרה יחידת מידה", '!לא ניתן לשמור הצעת מחיר ללא מחיר של דשן', "error");

            // Check second fertilizer
            else if (this.isTwoFertJob && !this.secondProduct.length)
                Utils.showToast(this, "חסר דשן", 'יש לבחור דשן עבור כל שורות המוצר', "error");
            else if (this.isTwoFertJob && !this.secondProdQuantity)
                Utils.showToast(this, "חסרה כמות", 'יש לבחור כמות עבור כל שורות המוצר', "error");
            else if (this.isTwoFertJob && !this.secondUnitOfMeasure)
                Utils.showToast(this, "חסרה יחידת מידה", 'יש לבחור יחידת מידה עבור כל שורות המוצר', "error");
            else if (this.isTwoFertJob && !this.secondTotalPrice)
                Utils.showToast(this, "חסרה יחידת מידה", 'לא ניתן לשמור הצעת מחיר ללא מחיר של דשן', "error");

            else {
                isValid = true;
            }
            const passEventr = new CustomEvent('approveolivalidation', {
                detail: { isValid: isValid, key: this.oliRecord.key }
            });
            this.dispatchEvent(passEventr);
        } catch (err) {
            console.log("error validate fert job oli: ", err);
        }
    }

    @api submitOLI(submitedOppRec) {
        this.submitedOppRec = submitedOppRec;
        this.submitClicked = true;

        // submit fert1
        const btnFer1 = this.template.querySelector('.fert1Submit');
        if (btnFer1) { btnFer1.click() }
    }

    // fert 1
    submitFert1(event) {
        event.preventDefault();

        const fieldsSub = event.detail.fields;
        fieldsSub.OpportunityId = this.submitedOppRec.id;
        fieldsSub.Is_Extension__c = true;
        fieldsSub.Quantity = this.firstProdQuantity * this.sumSize;
        fieldsSub.UnitPrice = +this.firstTotalPrice.toFixed(2);
        fieldsSub.Discount = this.firstProductDiscount;
        console.log("submitFert1: ", JSON.stringify(fieldsSub))
        if (this.submitClicked)
            this.template.querySelector('lightning-record-edit-form.fert1').submit(fieldsSub);
    }

    // fert 2
    submitFert2(event) {
        event.preventDefault();

        const fieldsSub = event.detail.fields;
        fieldsSub.OpportunityId = this.submitedOppRec.id;
        fieldsSub.Is_Extension__c = true;
        fieldsSub.Quantity = this.secondProdQuantity * this.sumSize;
        fieldsSub.UnitPrice = +this.secondTotalPrice.toFixed(2);
        fieldsSub.Discount = this.secondPriceDiscount;

        if (this.submitClicked)
            this.template.querySelector('lightning-record-edit-form.fert2').submit(fieldsSub);
    }


    handleFert1Success(event) {
        console.log(`102. FertJobBodyProduct -> handleFert1Success -> event.detail: ${JSON.stringify(event.detail)}`);
        this.submitedfert1Rec = event.detail;

        if (this.isTwoFertJob) {
            // submit fert2 (if exists)
            const btnFer2 = this.template.querySelector('.fert2Submit');
            if (btnFer2 && this.isTwoFertJob) {
                btnFer2.click()
            }
        } else {
            // submit fert job
            const btnFerJob = this.template.querySelector('.fertJobSubmit');
            if (btnFerJob) { btnFerJob.click() }
        }
    }

    handleFert2Success(event) {
        this.submitedfert2Rec = event.detail;

        // submit fert job
        const btnFerJob = this.template.querySelector('.fertJobSubmit');
        if (btnFerJob) { btnFerJob.click() }
    }

    handleFertError(event) {
        Utils.showToast(this, "שגיאה", event.detail.message + event.detail.detail, "error");
        console.log("Error handleFertError: ", JSON.stringify(event.detail))
    }

    // fertJob
    submitForm(event) {
        event.preventDefault();

        if (this.submitClicked) {

            const fieldsSub = event.detail.fields;
            console.log("fertJobField submit: ", JSON.stringify(fieldsSub))
            fieldsSub.OpportunityId = this.submitedOppRec.id;
            fieldsSub.Product2Id = this.selectedProd.Id;
            console.log("fieldsSub.Product2Id",fieldsSub.Product2Id);
            fieldsSub.Quantity = 1;
            fieldsSub.Plots__c = this.selectedPlots.join(", ");
            fieldsSub.Plot_Size__c = this.sumSize;
            fieldsSub.Discharge_Location__c = this.dischargeLocationId;
            fieldsSub.Is_Extension__c = false;
            fieldsSub.Extension_1__c = this.submitedfert1Rec.id;
            if (this.isTwoFertJob) {
                fieldsSub.Extension_2__c = this.submitedfert2Rec.id;
            }
            fieldsSub.UnitPrice = +this.fertJobTotalPrice.toFixed(2);
            fieldsSub.Discount = 0;
            fieldsSub.Currency__c = this.defaultCurrencyIsoCode;
            this.template.querySelector('.fertJob').submit(fieldsSub);
            this.submitClicked = false;
        }
    }

    handleSuccess(event) {
        this.returnResStatus(true);
    }

    handleError(event) {
        console.log(`048. FertJobBodyProduct -> handleError -> event.detail: ${JSON.stringify(event.detail)}`);
        this.returnResStatus(false);
    }

    returnResStatus(success) {
        const passEvent = new CustomEvent('olicreated', {
            detail: { isCreated: success, key: this.oliRecord.key }
        });
        this.dispatchEvent(passEvent);
    }

    @api copyRec() {
        this.oliId = null;
        if (this.oppRecord?.id)
            this.oppRecord.id = null;
        this.fertId1 = null;
        this.fertId2 = null;
    }

    // open modal
    editTankPointHandler() {
        this.openDischargeLocationAdder = true;
        if (!this.isDesktop) {
            window.scrollTo(0, 0);
        }
    }

    closeDischargeLocationModalAdder() {
        this.openDischargeLocationAdder = false;
    }

    handleTankPointsEditFormSucces(event) {
        if (event.detail.id && (this.dischargeLocationId == '' || this.dischargeLocationId == null)) {
            this.dischargeLocationId = event.detail.id;
        }
    }

    plotModalAdderHandler() {
        this.openPlotModalAdder = true;
        if (!this.isDesktop) {
            window.scrollTo(0, 0);
        }
    }

    closePlotModalAdder() {
        this.openPlotModalAdder = false;
    }

    submitPlotsHandler(event) {
        event.preventDefault();
        let fields = event.detail.fields;
        fields.Account__c = this.accountId;
        fields.AccountID__c = this.accountId;
        this.closePlotsModalAdder();
        this.template.querySelector('.plotsForm').submit(fields);
    }

    handlePlotAdderFormSucces(event) {
        Utils.showToast(this, "חלקה חדשה נוצרה בהצלחה", '', "success");
        try {
            refreshApex(this.wiredPlotsData); // Refresh the wired method which include wiredPlotsData. This will force the UI to refresh
            this.closePlotModalAdder();
        } catch (err) {
            console.error(err)
        }
    }

    selectedBranchGrowthOfAccountId = null;
    branchGrowthHandler(event) {
        if (event.detail.selectedRecordId == null) {
            this.selectedBranchGrowthOfAccountId = null;
        }
        else {
            this.selectedBranchGrowthOfAccountId = event.detail.selectedRecordId;;
        }
    }
    selectedFertilizerHeadOfBranchId = null;
    handleBranchFertilizerHeadSelection(event) {
        if (event.detail == null) {
            this.selectedFertilizerHeadOfBranchId = null;
        }
        else {
            this.selectedFertilizerHeadOfBranchId = event.detail.Id;
        }
    }

    editPlotsHandler() {
        this.openPlotsModalAdder = true;
        if (!this.isDesktop) {
            window.scrollTo(0, 0);
        }
    }

    closePlotsModalAdder() {
        this.openPlotsModalAdder = false;
    }

    handlePlotsSuccess() {

    }
    handlePlotsSubmit() {

    }

    updateMultiSelect() {
        if (this.allPlotsData?.length || this.selectedPlots?.length) {
            const multiSelectComp = this.template.querySelector('c-mutli-select-picklist')
            if (multiSelectComp) {
                multiSelectComp.updateSelectedValuesData(
                    this.selectedPlots,
                    this.allPlotsData
                );
            }
        }
    }

    handleFirstDiscountPrice() {
        console.log("handleFirstDiscountPrice",this.firstProduct , this.firstProdQuantity , this.firstUnitOfMeasure , this.sumSize);
        if (this.firstProduct && this.firstProdQuantity && this.firstUnitOfMeasure && this.sumSize) { // אם כל הערכים הראשונים הם טרוטים
            this.getFertPrdPriceBeforeDiscount(this.firstProduct, this.firstProdQuantity, this.sumSize, this.firstUnitOfMeasure)
        }
    }

    handleSecondDiscountPrice() {
        console.log("handleSecondDiscountPrice",this.secondProduct , this.secondProdQuantity , this.secondUnitOfMeasure , this.sumSize);

        if (this.secondProduct && this.secondProdQuantity && this.secondUnitOfMeasure && this.sumSize) {
            this.getFertPrdPriceBeforeDiscount(this.secondProduct, this.secondProdQuantity, this.sumSize, this.secondUnitOfMeasure)
        }
    }

    @api submitOrderData() {
        try {
            // Check fert Job
            if (!this.selectedProd) {
                Utils.showToast(this, "(סוג עבודה)חסר מוצר", 'יש לבחור מוצר עבור כל שורות המוצר', "error");
            }
            else if (!this.firstProduct) {
                Utils.showToast(this, "חסר דשן", 'יש לבחור דשן עבור כל שורות המוצר', "error");
            }
            else if (!this.firstProdQuantity) {
                Utils.showToast(this, "חסרה כמות", 'יש לבחור כמות עבור כל שורות המוצר', "error");
            }
            else if (!this.firstUnitOfMeasure) {
                Utils.showToast(this, "חסרה יחידת מידה", 'יש לבחור יחידת מידה עבור כל שורות המוצר', "error");
            }
            else if (!this.sumSize) {
                Utils.showToast(this, "גודל החלקות הוא 0", 'סך גודל החלקות צריך להיות גדול מ 0 עבור כל שורות המוצר', "error");
            }
            else if (!this.dischargeLocationId) {
                Utils.showToast(this, "לא נבחר מקום פריקה", 'יש לבחור מקום פריקה עבור כל שורות המוצר', "error");
            }
            else if (this.isTwoFertJob && !this.secondProduct.length) {
                Utils.showToast(this, "חסר דשן", 'יש לבחור דשן עבור כל שורות המוצר', "error");
            }
            else if (this.isTwoFertJob && !this.secondProdQuantity) {
                Utils.showToast(this, "חסרה כמות", 'יש לבחור כמות עבור כל שורות המוצר', "error");
            }
            else if (this.isTwoFertJob && !this.secondUnitOfMeasure) {
                Utils.showToast(this, "חסרה יחידת מידה", 'יש לבחור יחידת מידה עבור כל שורות המוצר', "error")
            }
            else {
                const passEventr = new CustomEvent('updateorderdata', {
                    detail: {
                        fertJob: this.selectedProductId,
                        product1: this.firstProduct,
                        product2: this.secondProduct ? this.secondProduct : null,
                        quantity1: this.firstProdQuantity,
                        quantity2: this.secondProdQuantity ? this.secondProdQuantity : null,
                        unitOfMeasure1: this.firstUnitOfMeasure,
                        unitOfMeasure2: this.secondUnitOfMeasure ? this.secondUnitOfMeasure : null,
                        dischargeLocation: this.dischargeLocationId,
                        plotsSize: this.sumSize,
                        id: this.oliId
                    }
                });
                this.dispatchEvent(passEventr);
            }
        } catch (err) {
            console.error(err)
        }
    }

    get branchGrowthId() {
        return this.selectedBranchGrowthOfAccountId;
    }

    get fertilizerHeadId() {
        return this.selectedFertilizerHeadOfBranchId;
    }

    get fertilizerHeadWhereClause() {
        return `AND Branch_growth__c = '${this.branchGrowthId}'`;
    }

    get isForEditIcon() {
        return (this.dischargeLocationId == '' || this.dischargeLocationId == null) ? "utility:add" : "utility:edit";
    }

    get isForEditTitle() {
        return (this.dischargeLocationId == '' || this.dischargeLocationId == null) ? "הוספה" : "עריכה";
    }

    get toggleNoteBtnText() {
        return this.isAddingNote ? "- הסרת הערה" : "+ הוספת הערה";
    }

    get isTwoFertJob() {
        return this.selectedProd?.Fertilize_Job_number_of_product__c == '2';
    }

    get prodName() {
        return this.selectedProd?.Name;
    }

    get prodId() {
        return this.selectedProd?.Id;
    }

    get isDraft() {
        return this.oppRecord?.status == 'Draft' || this.oppRecord?.status == 'טיוטה';
    }

    get isNotDraft() {
        return !this.isDraft;
    }

    get tankPointsExtraWhereClause() {
        return this.accountId ? "AND Account__c = '" + this.accountId + "'" : '';
    }

    get dischargeLocationModalTitle() {
        if ((this.dischargeLocationId == '' || this.dischargeLocationId == null) && this.openDischargeLocationAdder) {
            return "הוספת מקום פריקה חדש";
        }
        else {
            return "עריכת מקום פריקה";
        }
    }

    get totalDunams() {
        return this.sumSize ? ` סה"כ גודל חלקות ${this.sumSize} ד'` : '';
    }

    get isDesktop() {
        switch (FORM_FACTOR) {
            case 'Large':
                return true;
            case 'Medium':
                return false;
            case 'Small':
                return false;
            default:
        }
    }
}