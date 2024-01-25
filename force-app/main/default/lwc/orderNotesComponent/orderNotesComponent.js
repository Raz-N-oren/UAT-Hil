import { LightningElement, api, track } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from "lightning/navigation";
export default class NotesComponent extends LightningElement {
    @api accountId = null;
    notesDescriptionFromOC= '';
    @api notes = {
        Description: '',
        Regular_note_to_the_driver__c: '',
        Note_for_discharge__c: ''
    }

    @track rec = {
        Description: ''
    }

    @api receiveRec(orderRec) {
        console.log("RAZCHECK, 18 ,receiveRec orderRec ", JSON.stringify(orderRec));
        this.rec = orderRec;
    }

    @api clearScreen() {
        this.rec.Description = '';
        this.notes = {
            Description: '',
            Regular_note_to_the_driver__c: '',
            Note_for_discharge__c: ''
        }
    }

    @api submitFields() {
        console.log("RAZCHECK, 31 ,submitFields,this.notesDescriptionFromOC  ",this.notesDescriptionFromOC);
        if(this.notesDescriptionFromOC != ''){
            console.log("RAZCHECK, 31 ,submitFields,this.notesDescriptionFromOC IF IF IF IF IF IF ");
            console.log("RAZCHECK, 31 ,submitFields,this.notes",JSON.stringify(this.notes));
            console.log("RAZCHECK, 31 ,submitFields,this.notes.Description",this.notes.Description);
            // this.notes.Description = this.notesDescriptionFromOC;
            this.notes= {
                ...this.notes,
                Description:this.notesDescriptionFromOC
            }
            console.log("RAZCHECK, 31 ,submitFields,this.notes.Description",this.notes.Description);
            console.log("RAZCHECK, 31 ,submitFields,this.notes2223",JSON.stringify(this.notes));

        }
        console.log("RAZCHECK, 31 ,submitFields,this.notes.Description  ",this.notes.Description);
        const passEventr = new CustomEvent('submitcomponents', {
            detail: { rec: { ...this.notes, generalOrderNote: this.rec.Description } }
        });
        this.dispatchEvent(passEventr);
    }
    // on aside component onclick-orderNumber view record
    viewRecord(event) {
        event.preventDefault();
        // Navigate to Order record page
        console.log("Click ", event.target.dataset.id)
        window.location.assign(window.open('/lightning/r/Account/' + event.target.dataset.id+ '/edit?count=1'));

    }
    handleNavigate() {
        const config = {
          type: "standard__recordPage",
          attributes: {
            recordId: this.accountId,
            objectApiName: "Account",
            actionName: "edit"
          }
        };
        this[NavigationMixin.Navigate](config);
      }
    changeGeneralOrderNote(event) {
        this.rec.Description = event.detail.value;
    }
    changeCustomerOrderNote(event) {
        console.log("RAZCHECK, 58 ,changeCustomerOrderNote,event.detail.value  ",event.detail.value);
        console.log("RAZCHECK, 58 ,changeCustomerOrderNote,this.notes.Description  ",this.notes.Description);
        this.notesDescriptionFromOC = event.detail.value;
        // this.notes.Description = event.detail.value;
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