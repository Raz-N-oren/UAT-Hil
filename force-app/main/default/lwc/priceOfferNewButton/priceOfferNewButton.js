import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

export default class PriceOfferNewButton extends NavigationMixin(LightningElement) {
    @api recordTypeId;
    priceOfferRecId;
    fertPlanRecId;

    connectedCallback(){
        console.log(`001. PriceOfferNewButton -> connectedCallback`);
        this.navigateToLwc();
    }

    @wire(getObjectInfo, {objectApiName: 'Opportunity'})
    getObjectData({data, error}){
        if(data){
            console.log(`002. data: ${JSON.stringify(data)}`);
            console.log(`003. data.recordTypeInfos: ${JSON.stringify(data.recordTypeInfos)}`);
            const infos = Object.values(data.recordTypeInfos);
            this.priceOfferRecId = infos.find(rec => rec.name === 'Price Offers' || rec.name === 'הצעת מחיר').recordTypeId;
            this.fertPlanRecId = infos.find(rec => rec.name === 'Fertilize Plan' || rec.name === 'תוכנית דישון').recordTypeId;
            console.log(`004. this.priceOfferRecId: ${JSON.stringify(this.priceOfferRecId)}`);
            console.log(`005. this.fertPlanRecId: ${JSON.stringify(this.fertPlanRecId)}`);
        }
        if(error){
            console.log(`006. Error: ${JSON.stringify(error)}`);
        }
    }

    @api
    navigateToLwc(){             // DEV                                         // UAT
        console.log(`007. this.recordTypeId: ${this.recordTypeId}`);
        // if(this.recordTypeId == '0122z000000TqAzAAK' || this.recordTypeId == '01225000001sW47AAE'){ // price offer
        if(this.recordTypeId == this.priceOfferRecId){ // price offer
            console.log(`008. PriceOfferNewButton -> connectedCallback -> (if) price offer`);

            this[NavigationMixin.Navigate]({
                type: 'standard__component',
                attributes: {
                    componentName: "c__NavigateToLWCPriceOffer"
                },
                state: {
                    c__recordTypeId: this.recordTypeId
                }
            });
        } else {
            console.log(`009. PriceOfferNewButton -> connectedCallback -> (else) fertilize plan`);

            // Navigate to the Oppotrunity standard 'new' page
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Opportunity',
                    actionName: 'new'
                },
                state: {
                    nooverride: 1,
                    backgroundContext: '/lightning/o/Opportunity/list?filterName=Recent'
                }
            });
        }
    }

    closeModal(event){
        console.log(`010. PriceOfferNewButton -> closeModal`);

        // Navigate to the Oppotrunity home page
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'home'
            }
        });
    }

    submitDetails(event){
        console.log(`011. PriceOfferNewButton -> closeModal -> recordTypeId: ${JSON.stringify(this.recordTypeId)}`);
        /*this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            // type: 'standard__objectPage',
            // type: 'standard__component',
            attributes: {
                objectApiName: 'Opportunity',
                actionName: 'new'
                // componentName: 'c__PriceOfferWrapper'
            }
            // },
            // state: {
            //     defaultFieldValues: 'Scope__c=כימיקלים, Status__c=Draft, RecordTypeId=0122z000000TqAzAAK'
            // }
        });*/
    }

    get showComponent(){
        this.recordTypeId == this.fertPlanRecId ? true : false;
    }
}