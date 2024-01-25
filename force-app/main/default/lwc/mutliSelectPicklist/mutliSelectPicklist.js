import { LightningElement, track, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class App extends LightningElement {
    
    @api
    values = [];
    
    @track
    selectedValues = [];
    
    @track
    selectedValuesData =[];
    
    @api
    picklistlabel = 'Status';
    
    @api
    required = false;
    
    @api
    disabled = false;
    
    showdropdown;
    
    @api
    placeholder = 'Select an Option';

    handleleave() {
        let sddcheck= this.showdropdown;

        if(sddcheck){
            this.showdropdown = false;
            this.fetchSelectedValues();
        }
    }

    @api styleWidth = '';
    
    connectedCallback(){
        if((!this.selectedValues?.length) && this.values?.length){
            const updateRequestEvent = new CustomEvent("updaterequest");
            this.dispatchEvent(updateRequestEvent);
        }
    }

    @api
    fetchSelectedValues() {
        
        this.selectedValues = [];

        //get all the selected values
        this.template.querySelectorAll('c-picklist-value').forEach(
            element => {
                if(element.selected){
                    this.selectedValues.push(element.value);
                }
            }
        );
        
        this.refreshSelectedValuesData();

        if(typeof this.selectedValues != "undefined"){
            //refresh original list
            this.refreshOrginalList();
            this.updateSelectedValues();
        }
        
    }

    refreshSelectedValuesData(){
        if(this.values?.length){
            this.selectedValuesData = this.selectedValues.map(
                (select) => this.values.filter((option) => option.value == select)[0]
            );
        }
    }

    updateSelectedValues(){
        const selectedValuesEvent = new CustomEvent("selectedvaluesent", {
            detail: { selectedValues: [...this.selectedValues] }
        });
        this.dispatchEvent(selectedValuesEvent);
    }

    refreshOrginalList() {
        //update the original value array to shown after close

        if(this.values?.length){
            const picklistvalues = this.values.map(eachvalue => ({...eachvalue}));

            picklistvalues.forEach((element, index) => {
                // console.log(`**** `);
                if(this.selectedValues.includes(element.value)){
                    picklistvalues[index].selected = true;
                }else{
                    picklistvalues[index].selected = false;
                }
            });

            this.values = picklistvalues;
        }
    }

    handleShowdropdown(){
        let sdd = this.showdropdown;
        if(sdd){
            this.showdropdown = false;
            this.fetchSelectedValues();
        }else{
            this.showdropdown = true;
        }
    }

    closePill(event){
        if(this.disabled) return;
        let selection = event.target.dataset.value;
        let selectedpills = this.selectedValues;
        let pillIndex = selectedpills.indexOf(selection);
        this.selectedValues.splice(pillIndex, 1);
        this.refreshSelectedValuesData();
        this.refreshOrginalList();
        this.updateSelectedValues();
    }

    @api
    clearSelection(){
        this.selectedValuesData =[];
        this.selectedValues = [];
        this.refreshSelectedValuesData();
        this.refreshOrginalList();
        this.updateSelectedValues();
    }
    
    @api
    updateSelectedValuesData(selectedValues, allValues){
        if(selectedValues?.length)
            this.selectedValues = selectedValues;
        if(allValues?.length)
            this.values = allValues;
        this.refreshSelectedValuesData();
        this.refreshOrginalList();
    }

    get pillClass(){
        return this.disabled ? 'slds-pill' : 'slds-pill disabled'
    }
    get pillsDivCss(){
        return this.isDesktop ? "slds-listbox slds-listbox_horizontal pillsDivDesktop" : "slds-listbox slds-listbox_horizontal pillsDiv";
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