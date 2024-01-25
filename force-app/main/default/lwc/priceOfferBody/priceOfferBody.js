import { LightningElement, api, track, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import getOliIdsByOpp from '@salesforce/apex/PriceOfferController.getOliIdsByOpp';
import Utils from "c/utils";
import { refreshApex } from '@salesforce/apex';

export default class PriceOfferBody extends LightningElement {
    @api recordId;
    @api submitedOppRec;
    @api oppRecord;
    @api accountId;
    @track oppLineItemIds = [];
    @api defaultCurrencyIsoCode = 'ILS'
    oppId;
    wiredOlis;
    deletedOlis = [];
    validateOlis = [];
    createdOlis = [];
    fertJobOliPrice = [];
    connectedCallback() {

        if (!this.oppLineItemIds.length) {
            this.addQli();
        }
    }

    @wire(getOliIdsByOpp, { oppId: '$recordId' })
    populateOppLineFields(result) {
        this.wiredOlis = result;
        console.log("priceOfferBody > populateOppLineFields: ", JSON.stringify(result));
        if (result.data?.length) {
            this.oppLineItemIds = result.data.map(oli => {
                if (oli.Is_Extension__c != true) return { key: oli.Id, id: oli.Id }
            });
            this.fertJobOliPrice = this.oppLineItemIds.map(oli => { return { key: oli.key, oliTotalPrice: null, hectars: null } });
        } else if (result.error) {
            console.log(`042. PriceOfferBody -> @wire -> error: ${JSON.stringify(result.error)}`);
            let message = "@wire(getRecord): Unknown error";
            if (Array.isArray(result.error.body)) {
                message = result.error.body.map((e) => e.message).join(", ");
            } else if (typeof result.error.body.message === "string") {
                message = result.error.body.message;
            }
            Utils.showToast(this, "שגיאה", message, "error");
        }
    }

    @api submitOrderData() {
        this.template.querySelectorAll("c-fert-job-body-product").forEach(component => {
            component.submitOrderData();
        })
    }

    updateOrderData(event) {
        const passEventr = new CustomEvent('updateorderdata', {
            detail: event.detail
        });
        this.dispatchEvent(passEventr);
    }

    duplicateOli(event) {
        const tempKeyHolder = this.getKey;
        const oliRec = {...event?.detail?.oliRec}
        try {
            this.oppLineItemIds.unshift({...oliRec, key: tempKeyHolder, id: null});
        } catch (err) {
            console.error(err)
        }
        finally{
            this.template.querySelectorAll(`c-price-offer-body-product`).forEach(component => {
                console.log(`c-price-offer-body-product`)
                if (component.key == tempKeyHolder) {
                    component.populateRec(event.detail.oliRec);
                }
            })
        }
        console.log("098- duplicateOli: ", oliRec)
    }

    addQli() {
        let tempKeyHolder = this.getKey;
        this.oppLineItemIds.unshift({ key: tempKeyHolder, id: null });
        this.fertJobOliPrice.unshift({ key: tempKeyHolder, oliTotalPrice: null, hectars: null });
    }

    removeOli(event) {
        this.oppLineItemIds = this.oppLineItemIds.filter(item => item.key !== event.detail.key);
        if (event.detail.id)
            this.deletedOlis.push(event.detail.id);

        if (this.fertJobOliPrice?.length) {
            this.fertJobOliPrice = this.fertJobOliPrice.filter(item => item.key !== event.detail.key);
            this.updateTotalPrice();
        }
    }
    @api async resetForm(isNew) {
        if (isNew === true) {
            await refreshApex(this.wiredOlis);
            this.deletedOlis = [];
            this.validateOlis = [];
            this.createdOlis = [];
            this.fertJobOliPrice = [];
            this.oppLineItemIds = [];
            this.recordId = null;
            this.addQli();
        } else {
            this.deletedOlis = [];
            this.validateOlis = [];
            this.createdOlis = [];
            this.fertJobOliPrice = [];
            this.oppLineItemIds = [];
            this.addQli();
        }
    }

    @api copyRec() {
        this.recordId = null;
        const oliRecs = this.template.querySelectorAll('.oliRec');
        oliRecs.forEach(oliElement => {
            oliElement.copyRec();
        });
    }

    @api validateFields() {
        try {
            // create array for olis validation results
            this.validateOlis = this.oppLineItemIds.map(oli => { return { key: oli.key, valid: null } });

            // run validation for each product line (OLI)
            this.template.querySelectorAll('.oliRec').forEach(oliElement => {
                oliElement.validateOli();
            });
        } catch (err) {
            console.log("Error, offer body validateFields: ", err)
        }
    }

    //  update the 'this.validateOlis' array and make a check if it's the last check
    approveOliValidation(event) {
        //Find index of specific oli using findIndex method.    
        const objIndex = this.validateOlis.findIndex((oli => oli.key == event.detail.key));
        this.validateOlis[objIndex].valid = event.detail.isValid;

        // check if all olis returned validation results
        let finishValidation = !this.validateOlis.some(oli => oli.valid === null);

        // when finished all
        if (finishValidation) {
            let allPassed = this.validateOlis.every(res => res.valid === true);
            allPassed = this.oppLineItemIds.length && allPassed;

            const passEventr = new CustomEvent('approveolisvalidation', {
                detail: { isValid: allPassed }
            });
            this.dispatchEvent(passEventr);
        }
    }

    @api submitOLIs(submitedOppRec) { // callback of oli creation (in DB) and checks if all olis created
        try {

            this.oppId = submitedOppRec.id;
            this.createdOlis = this.oppLineItemIds.map(oli => { return { key: oli.key, created: null } });
            // Activate the 'submit' func for each OLI
            this.template.querySelectorAll('.oliRec').forEach(oliElement => {
                oliElement.submitOLI(submitedOppRec);
            });

            // Delete OLI from DB
            if (this.deletedOlis.length) {
                this.deletedOlis.forEach(oliId => {
                    deleteRecord(oliId)
                        .catch((error) => {
                            console.log(`035. Error occurred: ${error}`);
                            Utils.showToast(this, `שגיאה במחיקת Opportunity line Item מס' ${oliId}`, message, "error");
                        });
                });
            }
        } catch (err) {
            console.log("submitOLIs on offer body component Error: ", err);
        }
    }

    oliCreated(event) {
        //Find index of specific oli using findIndex method.    
        const objIndex = this.createdOlis.findIndex((oli => oli.key == event.detail.key));

        this.createdOlis[objIndex].created = event.detail.isCreated;

        // check if all olis returned validation results
        let finishCreation = !this.createdOlis.some(oli => oli.created === null);

        // when finished all
        if (finishCreation) {
            let allPassed = this.createdOlis.every(oli => oli.created === true);
            if (allPassed && this.oppRecord.scope == 'דשנים' && this.oppRecord.type == 'רגילה')
                this.createDiscounts();
            const passEvent = new CustomEvent('approveoliscreation', {
                detail: { isCreated: allPassed }
            });
            this.dispatchEvent(passEvent);
        }
    }

    fertJobPriceUpdate(event) {
        //Find index of specific oli using findIndex method.    
        const objIndex = this.fertJobOliPrice.findIndex((oli => oli.key == event.detail.key));

        this.fertJobOliPrice[objIndex].hectars = event.detail.plotSize;
        this.fertJobOliPrice[objIndex].oliTotalPrice = event.detail.price;
        this.updateTotalPrice();
    }

    createDiscounts() {
        this.template.querySelectorAll('c-price-offer-body-product').forEach(oliElement => {
            oliElement.createDiscount();
        });
    }

    @api updateDefaultUnitOfMeasure() {
        this.template.querySelectorAll('c-price-offer-body-product').forEach(oliElement => {
            oliElement.updateDefaultUnitOfMeasure();
        });
    }

    updateTotalPrice() {
        const res = this.fertJobOliPrice.reduce((previosVal, currentVal) => {
            if (!previosVal.totalPrice)
                previosVal.totalPrice = 0;

            if (currentVal.oliTotalPrice)
                previosVal.totalPrice += +currentVal.oliTotalPrice;

            if (!previosVal.totalHectars)
                previosVal.totalHectars = 0;

            if (currentVal.hectars)
                previosVal.totalHectars += +currentVal.hectars;

            return previosVal;
        }, { totalPrice: 0, totalHectars: 0 });
        console.log("p-OfferBody > total-price: ", JSON.stringify(res))
        const passEventr = new CustomEvent('fertjobpriceupdate', {
            detail: { total: res }
        });
        this.dispatchEvent(passEventr);
    }
    fertJob1InfoUpdate(event) {
        const passEventr = new CustomEvent('fertjob1infoupdate', {
            detail: event.detail
        });
        this.dispatchEvent(passEventr);
    }

    fertJob2InfoUpdate(event) {
        const passEventr = new CustomEvent('fertjob2infoupdate', {
            detail: event.detail
        });
        this.dispatchEvent(passEventr);
    }

    getBasePriceValidation(event){
        console.log("RAZCHECK 263, base price from product,",event);
        const passEvent = new CustomEvent('basepricevalidation', {detail:event.detail});
        this.dispatchEvent(passEvent);
    }
    
    // Create random unique key for each OLI  
    get getKey() {
        return Math.floor(Math.random() * 10000);
    }

    get isFertJob() {
        return this.oppRecord?.type === 'עבודת דישון';
    }

    // get accountId() {
    //     return this.oppRecord?.account?.id;
    // }

    get isDraft() {
        return this.oppRecord?.status == 'Draft' || this.oppRecord?.status == 'טיוטה';
    }

    get isNotDraft() {
        return !this.isDraft;
    }
}