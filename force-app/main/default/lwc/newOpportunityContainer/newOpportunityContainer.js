import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';


export default class NewOpportunityContainer extends LightningElement {
    // container for creating new Opportunity
    @api recordTypeId; //כנראה שזה או הצ"ח או תכנת שנתית
    priceOfferRecId;
    fertPlanRecId;
    

    @api initComponent() {
        this.template.querySelector('c-price-offer-wrapper').resetForm(true);
    }
    
    @wire(getObjectInfo, {objectApiName: 'Opportunity'})
    getObjectData({data, error}){
        if(data){
            const infos = Object.values(data.recordTypeInfos);
            this.priceOfferRecId = infos.find(rec => rec.name === 'Price Offers' || rec.name === 'הצעת מחיר')?.recordTypeId;
            this.fertPlanRecId = infos.find(rec => rec.name === 'Fertilize Plan' || rec.name === 'תוכנית דישון')?.recordTypeId;

            if(!this.recordTypeId){
                this.recordTypeId = data.defaultRecordTypeId;
            }
        }
        if(error){
            console.log(`061. PriceOfferNewButton -> @wire -> Error: ${JSON.stringify(error)}`);
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////              getters                        //////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    get isPriceOffer(){
        return this.recordTypeId == this.priceOfferRecId || this.priceOfferRecId?.startsWith(this.recordTypeId) || this.recordTypeId == '01225000001sW47';
    }
    get isFertPlan(){
        return this.recordTypeId == this.fertPlanRecId || this.fertPlanRecId?.startsWith(this.recordTypeId) || this.recordTypeId == '0124K000000Y3b6';
    }
}