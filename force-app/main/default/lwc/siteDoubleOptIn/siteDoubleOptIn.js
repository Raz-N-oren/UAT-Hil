import { api, LightningElement, track, wire } from 'lwc';
import DOI_OBJECT from '@salesforce/schema/Double_OPT_In__c';
import EMAIL_FIELD from '@salesforce/schema/Double_OPT_In__c.Email__c';
import VERIFY_FIELD from '@salesforce/schema/Double_OPT_In__c.LandscaperProNewsletter__c';
import IMAGE from '@salesforce/resourceUrl/DoubleOptIn_Img';
import createNewDOI from '@salesforce/apex/DoubleOptIN_Controller.createNewDOI';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';



export default class SiteDoubleOptIn extends  LightningElement {
    @api name;
    @api recId;
    @track newDOIrecord=null;
    image=IMAGE;
    @api verifyEmail;
    @api relatedemail;
    @track unsubscribe=false;
    
connectedCallback(){
    console.log('Handel Click result:'+this.relatedemail+'--'+this.recId+'--'+this.name+'--'+this.verifyEmail);

    if(this.verifyEmail=='true'){
        this.unsubscribe=true;
    }
    this.handleClick();
}

        handleClick() {
            
                createNewDOI({ email:this.relatedemail,verify:this.verifyEmail, recRelatedId:this.recId })
                    .then((result) => {
                        this.newDOIrecord=result;
                    }).catch(error => {
                        console.error(error);
                    })
                }

        unsubscribeClick() {

            this.unsubscribe=false;
            createNewDOI({ email:this.relatedemail,verify:false, recRelatedId:this.recId })
            .then((result) => {
                this.newDOIrecord=result;
            }).catch(error => {
                console.error(error);
            })
        }



    
}