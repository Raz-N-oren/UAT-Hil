import { LightningElement, api, track } from 'lwc';
import getLastViewRecords from '@salesforce/apex/CustomLookUpController.getLastViewRecords';
import fetchExtendedLookUpValues from '@salesforce/apex/CustomLookUpController.fetchExtendedLookUpValues';

export default class CustomLookupField extends LightningElement {
    @api objectApiName;
    @api label = 'Lookup Field';
    @api placeholder = 'placeholder'
    // @api selectedRecord = false;
    // @api isInputRequired = false;
    @api fields;
    @track results;
    message;
    searchKey;
    isfocused = false; // is rhe uxDebouncedInput is focused
    scrollBarClicked = false;
    showSpinner = false;

    constructor() {
        super();
        this.switchResult(false);
    }

    handleFocus(event){
        this.isfocused = true;
        // console.log('001. Handling focuse in CustomLookupField - searchKey: ' + this.searchKey);
        if(!this.searchKey){
            this.dispatchEvent(new CustomEvent('lastviewed'));
        }
    }

    handleBlure(event){
       if (this.scrollBarClicked) { // prevents results element from hiding when clicking on the scrollbar
           this.template.querySelector('.debounced').focus(); // preserve focus on uxDebounced as long as the user is 'clicking' inside the element 
           return;
       }
       this.isfocused = false;
    }

    renderedCallback(){
        // listerns for mouse up and down events prevents results element from hiding when clicking on the scrollbar
        this.template.querySelector('ul.products-results').addEventListener('mousedown', e => {
            this.scrollBarClicked = true;
        });
        this.template.querySelector('ul.products-results').addEventListener('mouseup', e => {
            this.scrollBarClicked = false;
        });
    }

    @api refreshProductLookupResults(extraWhereClause){
        if(this.searchKey){
            let searchParams = { 
                searchKeyWord: this.searchKey,
                objectName: this.objectApiName,
                extraWhereClause : extraWhereClause
            };
            
            if (this.fields) {
                this.addFieldsToParam(searchParams);
                fetchExtendedLookUpValues(searchParams)
                .then(result => this.setResult(result))
                .catch(error => this.handleError(error));
            } else {
                fetchLookUpValues(searchParams)
                .then(result => this.setResult(result))
                .catch(error => this.handleError(error));
            }
        }
        else {
            console.log('004. Fetching the last viewed records.');
            console.log('With fields: ' + JSON.stringify(this.fields));
            this.showValidationError("");
            let mappedFields = this.fields.map( field => field.fieldApiName).join(', ');
            console.log('006. after mapping filds: ' + mappedFields);
            getLastViewRecords({objectName: this.objectApiName, fieldsToQuery: mappedFields, extraWhereClause: ''})
                .then(result => this.setResult(result))
                .catch(error => this.handleError(error));
        }
    }

    /* Ensure we always have Name and Id in the query */
    addFieldsToParam(searchParam) {
        let allFields = this.fields.split(',');
        allFields.push('Id');
        allFields.push('Name');
        let cleanFields = this.dedupeArray(allFields).join(', ');
        searchParam.fieldsToQuery = cleanFields;
    }

    dedupeArray(incoming) {
        var uniqEs6 = arrArg => {
            return arrArg.filter((elem, pos, arr) => {
                return arr.indexOf(elem) === pos;
            });
        };
        return uniqEs6(incoming);
    }

    setResult(newValues) {
        console.log('002. In setResult - newValues: ' + JSON.stringify(newValues));
        this.showValidationError("");
        this.showSpinner = false;
        if (newValues && newValues.length > 0) {
            this.message = null;
            this.switchResult(true);
            this.results = newValues;
        } else {
            this.message = 'לא נמצאו תוצאות מתאימות';
            this.results = null;
        }
    }

    handleRecordSelect(event) {
        this.selectedRecord = event.detail;
        // this.dispatchSelectionResult();
        this.switchResult(false);
        this.sendSelected();
        this.isSecondSearch = false;
    }

    /* Shows and hides the result area */
    switchResult(on) {
        this.resultClass = on
        ? 'slds-form-element slds-lookup slds-is-open'
        : 'slds-form-element slds-lookup slds-is-close';
    }

    handleKeyChange(event) {
        const searchKey = event.target.value;
        console.log('003. In handleKeyChange - val: ' + searchKey);
        this.searchKey = searchKey;
        this.refreshProductLookupResults("");
    }

    sendSelected(){
        const selectedEvent = new CustomEvent('lookupselectdevent', {
            detail: this.selectedRecord
        });
        this.dispatchEvent(selectedEvent);
    }

    handleError(error) {
        console.log("005. In handleError: " + JSON.stringify(error));
        this.showSpinner = false;
        this.message = "Sorry didn't work";
        // let errorDispatch = new CustomEvent('failure', { detail: error });
        // this.dispatchEvent(errorDispatch);
    }

    showValidationError(message) {
        let valErrElement = this.template.querySelector('.debounced').validationError();
        valErrElement.setCustomValidity(message);
        valErrElement.reportValidity();
    }

    onRecordSelection(){
        console.log('onRecordSelection');
    }
}