import { LightningElement, api, track } from 'lwc';
import Utils from "c/utils";
import { formatter } from "c/utils";
import { NavigationMixin } from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import { createRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import getPricebookEntryId from '@salesforce/apex/OrderCustomerController.getPricebookEntryId';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getParentAccount from '@salesforce/apex/OrderCustomerController.getParent';
import getRelatedLoadingPoint from '@salesforce/apex/OrderCustomerController.getRelatedLoadingPoint';
import getUserProfile from '@salesforce/apex/OrderCustomerController.getUserProfile';
import updatePricebookClosedQuate from '@salesforce/apex/PriceOfferController.updatePricebookClosedQuate';
import isApprovingFactor from '@salesforce/apex/PriceOfferController.isApprovingFactor';
import getLoadingPointBySapId from "@salesforce/apex/PriceOfferController.getLoadingPointBySapId";


import Id from '@salesforce/user/Id';

import ID_FIELD from '@salesforce/schema/Opportunity.Id';

import All_CREATED_FIELD from '@salesforce/schema/Opportunity.All_OLIs_Created__c';

export default class PriceOfferWrapper extends NavigationMixin(LightningElement) {
    userId = Id;
    @api recordId;
    @track oppRecord;
    isApprovingFactorVar;
    isHebrew= false;
    isBasePriceProductExiting = true;
    // type of price suggestion - offer component - offered plan/Fertilize Plan
    @api recordTypeId;
    contractorId = '';
    orderDataMeanWhile=  {};

    @api accountId;
    
    submitedOppRec;
    today = new Date().toISOString();
    defaultCurrencyIsoCode = 'ILS';
    profileName;
    connectedCallback() {
        this.getUserProfile();
        this.isApprovingFactor();
    }

    isApprovingFactor() {
        isApprovingFactor({ oppId: this.recordId }).then(result => { //סוג היוזר    
            console.log("oppId?",this.oppRecord,this.recordId); 
            this.isApprovingFactorVar = result;
            console.log("isApprovingFactor",this.isApprovingFactorVar);
        }).catch(error => {
            console.log(`009. Error: ${JSON.stringify(error)}`);
        })
    }

    getUserProfile() {
        getUserProfile({ Id: this.userId }).then(result => { //סוג היוזר
            this.profileName = result[0].Profile.Name;
            console.log("getUserProfile: ", result,this.profileName);

            if(result[0].LanguageLocaleKey == "he"){
                this.isHebrew = true;
            }

            this.defaultCurrencyIsoCode = result[0].DefaultCurrencyIsoCode;
        }).catch(error => {
            console.log(`008. Error: ${JSON.stringify(error)}`);
        })
    }

    orderNumber;
    oppLineItem1Id; // מוצר הזדמנות 1
    oppLineItem2Id;// 2

    // פתיחת הזמנה מאחורי הקלעים רק לעסקת דישון
    orderData = {
        oliId: '',
        fertJob: '',
        product1: { id: '', name: '' },
        product2: { id: '', name: '' },
        quantity1: '',
        quantity2: '',
        unitOfMeasure1: '',
        unitOfMeasure2: '',
        executionDate: '',
        dischargeLocation: '',
        contractor: { id: '', name: '' },
        warehouse: '',
        payer: '',
        plotsSize: '',
        loadingPoint: '',
        crane: false,
        trailerDays: '',
        contractorPricePerAcre: ''
    }

    fertJob1InfoUpdate(event) {
        console.log("fertJob1InfoUpdate Data: ", JSON.stringify(event.detail))
        let fertJob = event.detail.fertJob;
        let data = event.detail.data;
        this.oppLineItem1Id = fertJob.id;
        this.orderData.product1.id = fertJob.product;
        this.orderData.product1.name = `כמות  ${fertJob.productName} לדונם בפועל`;
        this.orderData.quantity1 = data.fields?.ActualQuantityPerHectare__c?.value ? data.fields.ActualQuantityPerHectare__c.value : fertJob.quantity;
        this.orderData.unitOfMeasure1 = data.fields?.ActualUnitOfMeasure__c?.value ?  data.fields?.ActualUnitOfMeasure__c?.value : Utils.getUnitOfMeasureName(fertJob.unitOfMeasure);
    }

    fertJob2InfoUpdate(event) {
        console.log("fertJob2InfoUpdate Data: ", JSON.stringify(event.detail))
        let fertJob = event.detail.fertJob;
        let data = event.detail.data;
        this.oppLineItem2Id = fertJob.id;
        this.orderData.product2.id = fertJob.product;
        this.orderData.product2.name = `כמות  ${fertJob.productName} לדונם בפועל`;
        this.orderData.quantity2 = data.fields?.ActualQuantityPerHectare__c?.value ? data.fields.ActualQuantityPerHectare__c.value : fertJob.quantity;
        this.orderData.unitOfMeasure2 = data.fields?.ActualUnitOfMeasure__c?.value ?  data.fields?.ActualUnitOfMeasure__c?.value : Utils.getUnitOfMeasureName(fertJob.unitOfMeasure);
    }
    updateOppData(event) { //דוחף האינפוטס מהבן
        this.oppRecord = event.detail.oppRecord;
        console.log("Oop Data: ", JSON.stringify(this.oppRecord))
        console.log("order Data: ", JSON.stringify(event.detail.orderData))

        this.orderData.executionDate = event.detail.orderData.executionDate;
        this.orderData.trailerDays = event.detail.orderData.trailerDays;
        this.orderData.contractorPricePerAcre = event.detail.orderData.contractorPricePerAcre;
        this.orderData.crane = event.detail.orderData.crane;
        this.orderData.plotsSize = event.detail.orderData.plotsSize;
        this.accountId = event.detail.oppRecord.account.id;
        this.orderData.contractor.id = event.detail.oppRecord.contractor.id;
        this.contractorId = event.detail.oppRecord.contractor.id;
        this.orderData.contractor.name = event.detail.oppRecord.contractor.name;
        this.orderData.warehouse = event.detail.oppRecord.warehouse.id;
        // this.getRelatedLoadingPoint(event.detail.oppRecord.contractor.name); // מקומות פריקה
        this.orderDataMeanWhile = this.orderData; 

        this.getLoadingPointBySapId(event.detail.oppRecord.contractor.id); // מקומות פריקה
    }
    // called on 'clear form' button click event
    @api resetForm(isNew) { //ניקוי שדות
        this.template.querySelector("c-price-offer-head").resetForm(isNew);
        this.template.querySelector("c-price-offer-body").resetForm(isNew);
    }
    updateAccountId(event) { // וונאס נבחר לקוח בבן הדר - מעדכנים פה את האבא עם האקאונט שנבחר
        this.accountId = event.detail.accountId;
    }
    // -- steps before submition --
    //  1. validate opp(ortunity) fields
    //  2. check at least one oli exists
    //  3. validate all oli's fields
    //  4. if 1-3 returns true submit opp
    //  5. if 4 succeed submit olis

    //  1. validate opp fields
    submitPriceOffer() {
        this.template.querySelector("c-price-offer-head").validateFields();
    }

    //  2. check at least one oli exists + 3. validate all oli's fields
    approveOppValidation(event) {
        if (event.detail.isValid) {
            this.template.querySelector("c-price-offer-body").validateFields();
        }
    }

    //  4. if 1-3 returns true submit opp
    approveOlisValidation(event) {
        if (event.detail.isValid) {
            this.template.querySelector("c-price-offer-head").submitOpp();
        }
    }

    //  5. if 4 succeed submit olis
    // called from the 'head' component after saveing the Opportunity (receives the Opp ID)
    oppSubmited(event) {
        try {
            this.recordId = event.detail.oppRecord.id;
            this.submitedOppRec = event.detail.oppRecord;
            this.template.querySelector("c-price-offer-body").submitOLIs(event.detail.oppRecord);
        }
        catch (err) {
            console.log("on opp error Submited: ", err);
        }
    }

    approveOliscreation(event) { 
        if (event.detail.isCreated) {
            const redirectToId = this.recordId;
            this.updateOpportunityRecord(redirectToId);
            Utils.showToast(this, "הצעת המחיר נשמרה בהצלחה!", this.submitedOppRec.fields.Name.value, "success");
            this.resetForm(true);
            this.recordId = null;

            // redirect to the opportunity record page
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: redirectToId,
                    objectApiName: "Opportunity",
                    actionName: "view"
                }
            });
        } else
            Utils.showToast(this, "שגיאה", "בעיה בשמירת המוצרים, יש לנסות שוב מאוחר יותר.", "error");
    }


    updateOpportunityRecord(recordId) { // חיווי רשומה חדשה נוצרה 
        // Create the recordInput object
        const fields = {};
        fields[ID_FIELD.fieldApiName] = recordId;
        fields[All_CREATED_FIELD.fieldApiName] = true;
        const recordInput = { fields };

        updateRecord(recordInput).then(() => {
                console.log(`316. PriceOfferWrapper -> updateOpportunityRecord -> In then`);
                // Display fresh data in the form
                // return refreshApex(this.contact);
            }).catch(error => {
                Utils.showToast(this, "שגיאה", error.body.message, "error");
                console.error(`316. PriceOfferWrapper -> updateOpportunityRecord -> In then`, error);
            });
    }

    updatePricebookAndClosedQuate() { //עדכן מחירון
        updatePricebookClosedQuate({ oppId: this.recordId }).then(res => {
            console.log("updatePricebookClosedQuate success: ", res);
            this.closePriceQuote();
        }).catch(err => {
            console.error(err);
        })
    }

    closePriceQuote() {
        const fields = { 'Id': this.recordId, 'Status__c': "invalid", 'Valid_To__c' : this.today };
        const recordInput = { fields };
        console.log("closePriceQuote: " , fields)
        updateRecord(recordInput).then(() => {
            Utils.showToast(this, "הצעת המחיר עודכנה בהצלחה!", this.title, "success");
            console.log('Success: הצלחה בעדכון הזדמנות זו');
             // redirect to the opportunity record page
             this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.recordId,
                    objectApiName: "Opportunity",
                    actionName: "view"
                }
            });
        }).catch(error => {
            console.log('Error: ',error);
        });
    }
    copyRec() {
        this.template.querySelector("c-price-offer-head").copyRec();
        this.template.querySelector("c-price-offer-body").copyRec();
        this.recordId = null;
    }

    updateDefaultUnitOfMeasure() {
        this.template.querySelector("c-price-offer-body").updateDefaultUnitOfMeasure();
    }

    fertJobPriceUpdate(event) {
        this.template.querySelector("c-price-offer-head").totalPrice = formatter.format(event.detail.total.totalPrice);
        this.template.querySelector("c-price-offer-head").totalPricePerHectar = formatter.format(event.detail.total.totalPrice / event.detail.total.totalHectars);
    }
    showExtraFieldsToCharge = false;
    openExtraFieldsToChargeClient() {
        this.getLoadingPointBySapId(this.contractorId);
        this.showExtraFieldsToCharge = true;
    }
    closeExtraFieldsToCharge() {
        this.showExtraFieldsToCharge = false;
    }

    dateHandler(event) {
        this.orderData.executionDate = event.detail.value;
    }

    plotsSizeHandler(event) {
        this.orderData.plotsSize = event.detail.value;
    }

    quantity1Handler(event) {
        this.orderData.quantity1 = event.detail.value;
    }

    quantity2Handler(event) {
        this.orderData.quantity2 = event.detail.value;
    }

    unitOfMeasure1Handler(event) {
        this.orderData.unitOfMeasure1 = event.detail.value;
    }
    unitOfMeasure2Handler(event) {
        this.orderData.unitOfMeasure2 = event.detail.value;
    }

    craneCheckboxHandler(event) {
        this.orderData.crane = event.target.checked;
    }

    trailerDaysHandler(event) {
        this.orderData.trailerDays = event.detail.value;
    }

    contractorPricePerAcreHandler(event) {
        this.orderData.contractorPricePerAcre = event.detail.value;
    }

    getLoadingPointBySapId(contrId) {
        getLoadingPointBySapId({ contrId: contrId }).then((result) => {
            console.log("RAZCHECK,304, getLoadingPointBySapId,: ", result);
            console.log("RAZCHECK,304, getLoadingPointBySapId,:ID ", result[0]?.Id);
            this.orderData.loadingPoint = result[0]?.Id;
        }).catch(err => {
            console.log("error getLoadingPointBySapId: ", err);
            this.customerSize = '';
        })
    }

    getRelatedLoadingPoint(name) { //הבאת מקום פריקה קשור לשם קבלן מבצע מהשרת
        getRelatedLoadingPoint({ name: name }).then(res => {
            console.log("RAZCHECK, 304 , 555, getRelatedLoadingPoint: ", res);
            this.orderData.loadingPoint = res[0]?.Id;
        }).catch(err => {
            console.log(err);
        })
    }

    submitChargeClient() {
        try {
            
            this.orderData = {
                fertJob: '',
                product1: { id: '', name: this.orderData.product1.name ? this.orderData.product1.name : null },
                product2: { id: '', name: this.orderData.product2.name ? this.orderData.product2.name : null },
                quantity1: this.orderData.quantity1 ? this.orderData.quantity1 : '',
                quantity2: this.orderData.quantity2 ? this.orderData.quantity2 : '',
                unitOfMeasure1: this.orderData.unitOfMeasure1 ? this.orderData.unitOfMeasure1 : '',
                unitOfMeasure2: this.orderData.unitOfMeasure2 ? this.orderData.unitOfMeasure2 : '',
                executionDate: this.orderData.executionDate ? this.orderData.executionDate : '',
                dischargeLocation: '',
                contractor: { id: '', name: '' },
                warehouse: '',
                payer: '',
                plotsSize: this.orderData.plotsSize ? this.orderData.plotsSize : '',
                loadingPoint: this.orderData.loadingPoint ? this.orderData.loadingPoint : '',
                crane: this.orderData.crane ? this.orderData.crane : false,
                trailerDays: this.orderData.trailerDays ? this.orderData.trailerDays :  '',
                contractorPricePerAcre: this.orderData.contractorPricePerAcre ? this.orderData.contractorPricePerAcre : ''
            }
            console.log("RAZCHECK,333,this.orderData ",this.orderData);
            this.template.querySelector("c-price-offer-head").submitOrderData();
            this.template.querySelector("c-price-offer-body").submitOrderData();
        } catch (err) {
            console.error(err)
        } finally {
            this.chargeClientHandler();
            this.closeExtraFieldsToCharge();
        }
    }

    chargeClientHandler() {
        console.log("chargeClientHandler inside term")
        try {
            // new order
            this.createOrder(this.accountId, this.orderData.executionDate, '50', this.orderData.loadingPoint);
            this.updateOpp();
            if (this.oppLineItem1Id){
                this.updateOppLineItem(this.oppLineItem1Id, this.orderData.quantity1, this.orderData.unitOfMeasure1);
            }
            if (this.oppLineItem2Id){
                this.updateOppLineItem(this.oppLineItem2Id,  this.orderData.quantity2, this.orderData.unitOfMeasure2);
            }     
        } catch (err) {
            console.error(err)
        }
    }

    submitTransferToConsignmentWarehouse() {
        try {
            console.log("RAZCHECK, 378 ,submitTransferToConsignmentWarehouse , this.orderData.loadingPoint ",this.orderData?.loadingPoint);
            console.log("RAZCHECK, 378 ,submitTransferToConsignmentWarehouse , this.orderData ",this.orderData);
            this.orderData = {
                fertJob: '',
                product1: { id: '', name: this.orderData.product1.name ? this.orderData.product1.name : null },
                product2: { id: '', name: this.orderData.product2.name ? this.orderData.product2.name : null },
                quantity1: this.orderData.quantity1 ? this.orderData.quantity1 : '',
                quantity2: this.orderData.quantity2 ? this.orderData.quantity2 : '',
                unitOfMeasure1: this.orderData.unitOfMeasure1 ? this.orderData.unitOfMeasure1 : '',
                unitOfMeasure2: this.orderData.unitOfMeasure2 ? this.orderData.unitOfMeasure2 : '',
                executionDate: this.orderData.executionDate ? this.orderData.executionDate : '',
                dischargeLocation: '',
                contractor: { id: '', name: '' },
                warehouse: '',
                payer: '',
                plotsSize: this.orderData.plotsSize ? this.orderData.plotsSize : '',
                loadingPoint: null,
                crane: this.orderData.crane ? this.orderData.crane : false,
                trailerDays: this.orderData.trailerDays ? this.orderData.trailerDays :  '',
                contractorPricePerAcre: this.orderData.contractorPricePerAcre ? this.orderData.contractorPricePerAcre : ''
            }
            console.log("RAZCHECK, 380,this.orderData, ",this.orderData)
            this.template.querySelector("c-price-offer-head").submitOrderData();
            this.template.querySelector("c-price-offer-body").submitOrderData();
        } catch (err) {
            console.error(err)
        } finally {
            this.transferToConsignmentWarehouse();
        }
    }


    updateContractorAndWarehouse(event) {
        console.log("priceOfferWrapper order data: ", JSON.stringify(event.detail))
        this.orderData.contractor.id = event.detail.contractor.id;
        this.orderData.contractor.name = event.detail.contractor.name;
        this.orderData.warehouse = event.detail.warehouse;

        getParentAccount({ recordId: event.detail.warehouse }).then(response => {
            this.orderData.payer = response[0]?.ParentId;
        }).catch(error => {
            console.error(error);
        })
    }

    updateOrderData(event) {
        console.log("priceOfferWrapper order data: ", JSON.stringify(event.detail))
        this.orderData.fertJob = event.detail.fertJob;
        this.orderData.product1.id = event.detail.product1;
        this.orderData.product2.id = event.detail.product2;
        this.orderData.quantity1 = this.orderData.quantity1 ? this.orderData.quantity1 : event.detail.quantity1;
        this.orderData.quantity2 = this.orderData.quantity2 ? this.orderData.quantity2 : event.detail.quantity2;
        this.orderData.unitOfMeasure1 = this.orderData.unitOfMeasure1 ? this.orderData.unitOfMeasure1 : event.detail.unitOfMeasure1;
        this.orderData.unitOfMeasure2 = this.orderData.unitOfMeasure2 ? this.orderData.unitOfMeasure2 : event.detail.unitOfMeasure2;
        this.orderData.dischargeLocation = event.detail.dischargeLocation;
        this.orderData.plotsSize = this.orderData.plotsSize ? this.orderData.plotsSize : event.detail.plotsSize;
        this.orderData.oliId = event.detail.id;
    }

    twoDayesAheadGenerator() {
        const myCurrentDate = new Date();
        const myFutureDate = new Date(myCurrentDate);
        myFutureDate.setDate(myFutureDate.getDate() + 2);//myFutureDate is now 2 days in the future
        return myFutureDate.toISOString();
    }
    transferToConsignmentWarehouse() {
        console.log("transferToConsignmentWarehouse: ", this.orderData)
        if (this.orderData.contractor.id && this.orderData.product1.id && this.orderData.quantity1 && this.orderData.dischargeLocation && this.orderData.plotsSize) {
            // new order
            this.createOrder(this.orderData.contractor.id, this.twoDayesAheadGenerator(), '10', this.orderData?.loadingPoint);
        }
    }
    orderId;
    createOrder(acc, supplyDate, type, loadingPoint) {
        const fields = {
            "Pricebook2Id": "01s4K0000017MZ1QAM",
            "EffectiveDate": new Date(),
            "Status": "Draft", 
            // "Status":  type == '50' ? "50" : "10",
            "Status":  "10",
            "CurrencyIsoCode": this.defaultCurrencyIsoCode,
            "AccountId": acc,
            "RequestedSupplyDate__c": supplyDate,
            "TransactionType__c": type,
            "IntermediaryWarehouse__c": type == '50' ? this.orderData.warehouse : null,
            "Paying_Customer__c": type == '50' ? this.orderData.payer : null,
            "Description" : `ההזמנה נפתחה מעבודת דישון : ${this.headerLabel} `
        };

        const recordInput = { apiName: "Order", fields };
        console.log("fields to create: ", fields);
        createRecord(recordInput).then(order => {
                console.log("new order created: ", order);
                this.orderId = order.id;
                try {
                    this.orderNumber = order.fields.OrderNumber.value;
                    try {
                        this.getPricebookEntryId(this.orderData.product1.id).then(result => {
                            console.log("type 444:",type);
                            this.createOrderItem(this.orderData.product1.id, this.orderData.quantity1 * this.orderData.plotsSize, Utils.getUnitOfMeasureCode(this.orderData.unitOfMeasure1), order.id, result[0].Id, loadingPoint, '10');
                        })
                        if (this.orderData.product2.id) {
                            this.getPricebookEntryId(this.orderData.product2.id).then(result => {
                                this.createOrderItem(this.orderData.product2.id, this.orderData.quantity2 * this.orderData.plotsSize, Utils.getUnitOfMeasureCode(this.orderData.unitOfMeasure2), order.id, result[0].Id, loadingPoint, '10');
                            })
                        }
                        if (type == '50') {
                            this.getPricebookEntryId(this.orderData.fertJob).then(result => {
                                this.createOrderItem(this.orderData.fertJob, +this.orderData.plotsSize, 'EA', order.id, result[0]?.Id, loadingPoint, "10");
                            })
                        }
                    } catch (err) {
                        console.log("Error: ", err);
                        throw new Error(err);
                    }
                }
                catch (error) {
                    console.error(error)
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'שגיאה ביצירת הזמנה',
                            message: error,
                            variant: 'error'}),
                    );
                    deleteRecord(this.orderId).then(() => {
                        console.log("Draft order deleted");
                    }).catch(err => {
                        console.error(err);
                    })
                }
            }).catch(error => {
                console.log("Error: ", error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'שגיאה ביצירת הזמנה',
                        message: error,
                        variant: 'error',
                    }),
                );
            });
    }


    //  Create New Order Items
    createOrderItem(product, quantity, unitOfMeasure, orderId, pricebookEntryId, loadingPoint, type) {
        console.log("RAZCHECK , 506 ,555,loadingPoint createOrderItem ", loadingPoint);
        const fields = {
            "OrderId": orderId,
            "PricebookEntryId": pricebookEntryId,
            "Product2Id": product,
            "Quantity": quantity,
            "UnitPrice": 0,
            "Status__c": type == '50' ? '40' : '10',
            "UnitOfMeasure__c": unitOfMeasure,
            "DischargeLocation__c": this.orderData.dischargeLocation,
            "LoadingPoint__c": loadingPoint,
            "RelatedOpportunity__c" : this.recordId,
            "RelatedOpportunityItem__c" : this.orderData.oliId
        };

        const recordInput = { apiName: "OrderItem", fields };
        console.log("RAZCHECK, 522, fields  createorderitem on priceofferwrapper: ", fields);
        console.log("RAZCHECK, 522 523, recordInput  createorderitem on priceofferwrapper: ", recordInput);

        createRecord(recordInput).then(res => {
                console.log("new item created: ", res);
                if (type === '10') {
                    if (this.orderData.product2.id && this.orderData.product2.id == product) {
                        this.triggerProcessorHandler(this.orderNumber, orderId);
                    }
                    else if (!this.orderData.product2.id) {
                        this.triggerProcessorHandler(this.orderNumber, orderId);
                    }
                }
                if (type === '50') {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "הצלחה!",
                            message: 'הזמנה מספר: ' + this.orderNumber + " עודכנה בהצלחה!",
                            variant: 'success',
                        }),
                    );
                }
            }).catch(error => {
                console.log("Error creating order Item: ", error)
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'שגיאה ביצירת הזמנה',
                        message: error,
                        variant: 'error',
                    }),
                );
                deleteRecord(orderId).then(() => {
                    console.log("Draft order deleted");
                }).catch(err => {
                    console.error(err);
                })
            });
    }
    //


    // Trigger to backend that had been changes to an order.
    triggerProcessorHandler(orderNumber, orderId) {
        console.log("triggerProcessorHandler")
        if (orderId) {
            const fields = { 'Id': orderId, 'triggerProcessor__c': true };
            const recordInput = { fields };
            const orderNum = orderNumber != 'הזמנה חדשה' ? orderNumber : this.orderNumber;
            updateRecord(recordInput).then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "הצלחה!",
                        message: 'הזמנה מספר: ' + orderNum + " עודכנה בהצלחה!",
                        variant: 'success',
                    }),
                );
                if (!this.isDesktop) {
                    window.scrollTo(0, 0);
                }
            }).catch(error => {
                console.log('Error: ',error);
            });
        }
    }

    updateOpp() {
        const fields = { 'Id': this.recordId, 'ExecutionDate__c': this.orderData.executionDate, 'ActualAmountOfAcres__c' : this.orderData.plotsSize, "crane__c" : this.orderData.crane, "trailerDays__c" : this.orderData.trailerDays, "contractorPricePerAcre__c" : this.orderData.contractorPricePerAcre};
        const recordInput = { fields };
        console.log("updateOpp: " , fields)
        updateRecord(recordInput).then(() => {
            console.log('Success: הצלחה בעדכון הזדמנות זו');
        }).catch(error => {
            console.log('Error: ',error);
        });
    }

    updateOppLineItem(fertId, quantity, unitOfMeasure) {
        const fields = { 'Id': fertId , 'ActualQuantityPerHectare__c': quantity, 'ActualUnitOfMeasure__c' : unitOfMeasure};
        const recordInput = { fields };
        updateRecord(recordInput).then(() => {
            console.log('Success: הצלחה בעדכון מוצר הזדמנות זו');
        }).catch(error => {
            console.log('Error: ',error);
        });
    }

    getBasePriceValidation(event){
        console.log("RAZCHECK, base price from son of the son, 606 ", JSON.stringify(event.detail));
        this.isBasePriceProductExiting = event.detail;
    }

    // getPricebookEntryId of product, needed to create orderitem
    async getPricebookEntryId(product2Id) {
        return new Promise(async (resolve, reject) => {
            const pricebookEntryId = await getPricebookEntryId({ productId: product2Id });
            resolve(pricebookEntryId);
        }).catch(error => {
            console.error(error.body.message);
        })
    }
    //


    get unitOfMeasureOptions() {
        return [
            { label: "קוב", value: "קוב" },
            { label: "ליטר", value: "ליטר" },
            { label: "טון", value: "טון" },
            { label: "קילו", value: "קילו" },
            { label: "יחידה", value: "יחידה" },
        ];
    }
    get oppStatus() {
        if (this.oppRecord?.status != 'Draft' || this.oppRecord?.status != 'טיוטה') {
            return this.oppRecord?.status;
        }
        else {
            if (this.recordId) {
                return 'ממתין לאישור';
            }
            else {
                return 'טיוטה';
            }
        }
    }

    get isDraft() {
        return this.oppRecord?.status == 'Draft' || this.oppRecord?.status == 'טיוטה';
    }

    get isNotDraft() {
        return !this.isDraft;
    }

    get isSubmitPriceOfferAviabale(){
        console.log("RAZCHECK, 654 , this.isBasePriceProductExiting",this.isBasePriceProductExiting);
        if(!this.isBasePriceProductExiting){
            return true;
        }
        else if(this.isApprovingFactorVar){
            return false;
        }
        else{
            return !this.isDraft;
        }
    }
    
    get headerLabel() { //שם ההזדמנות
        return (this.oppRecord?.name) ? this.oppRecord.name : 'הצעת מחיר חדשה';
    }

    get oppScope() {
        return (this.oppRecord?.scope) ? this.oppRecord.scope : '';
    }

    get headerClass() {
        if (FORM_FACTOR == 'Large') { // Desktop
            return "desktopHeader";
        } else if (FORM_FACTOR == 'Medium') { // Tablet
            return "tabletHeader";
        } else if (FORM_FACTOR == 'Small') { // Mobile
            return "mobileHeader";
        }
    }

    get headerDivClass() {
        if (FORM_FACTOR == 'Large') { // Desktop
            return "headerDesktopDiv";
        } else if (FORM_FACTOR == 'Medium') { // Tablet
            return "headerMobileDiv";
        } else if (FORM_FACTOR == 'Small') { // Mobile
            return "headerMobileDiv";
        }
    }

    get footerDivClass() {
        if (FORM_FACTOR == 'Large') { // Desktop
            return "footerDesktopDiv";
        } else if (FORM_FACTOR == 'Medium') { // Tablet
            return "headerMobileDiv";
        } else if (FORM_FACTOR == 'Small') { // Mobile
            return "headerMobileDiv";
        }
    }

    get isDesktop() {
        return FORM_FACTOR == 'Large';
    }

    get isMobile() {
        return FORM_FACTOR == 'Small';
    }

    get showNameAndStatus() {
        return this.isDesktop || this.oppRecord?.name;
    }

    get title() {
        return (this.oppRecord?.scope) ? `הצעת מחיר (${this.oppRecord.scope})` : `הצעת מחיר`;
    }

    get btnText() {
        const SEND_OFFER = 'שליחת הצעה';
        const UPDATE_OFFER = 'עדכון הצעה';
        return this.recordId ? UPDATE_OFFER : SEND_OFFER;
    }

    get isFertJob() {
        return this.oppRecord?.type == 'עבודת דישון' ? true : false;
    }
    get displayExtraBtns() {
        return this.oppRecord?.type == 'עבודת דישון' && this.recordId ? true : false;
    }
    get displayCloseOppBtn() {
        return this.oppRecord?.status != 'Draft' && this.oppRecord?.type == "עסקת מסגרת" ? true : false;
    }
    get container() {
        console.log();
        if ((this.oppRecord?.status == 'Draft' && this.oppRecord?.status == 'טיוטה')
        ) {
            return 'disabled';
        }
        else {
            return '';
        }
    }

}