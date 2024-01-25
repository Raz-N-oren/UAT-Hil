import { LightningElement, api, track, wire } from "lwc";


export default class YearlyPlanClone extends LightningElement {

  isLoading = false;
  @api oppIdToClone ="";
  @api accountId = "";
  @api accountName = '';
  //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded
  @track isModalOpen = false;
  isFirstTime = true;
  disableButton = false;


  renderedCallback(){
    if(this.isFirstTime && this.isModalOpen){
      let predefinedAccount = {Id: this.accountId, Name: this.accountName};   
      if(this.template.querySelector('.account-lookup') != null)
        this.template.querySelector('.account-lookup').preDefineSelectedRecord(predefinedAccount);
      this.isFirstTime = false;

    }
  }
  openModal() {    
    // to open modal set isModalOpen tarck value as true
    this.isModalOpen = true;
   
  }
  closeModal() {
    // to close modal set isModalOpen tarck value as false
    this.isModalOpen = false;
    
  }
  submitDetails() {
    this.isLoading = true;
    this.template.querySelector('c-plots-list-box').cloneOpp(this.oppIdToClone, this.isNewCloneTypeValue);       
  }

  toggleButton(event){
    this.disableButton = event.detail.State && !this.isNewCloneTypeValue;
  }


  fetchPlots(event) {        
    this.accountId = event.detail == null ? '' : event.detail['Id'];
  }

  cloneTypeValue = 'new';

  get cloneTypeOptions() {
    return [
        { label: 'שכפול', value: 'new' },
        { label: 'שכפול ועדכון', value: 'newAndUpdate' },
    ];
  }
  get isNewCloneTypeValue(){
    return this.cloneTypeValue == 'new';
  }
  handleCloneTypChange(event) {
    this.cloneTypeValue = event.detail.value;
    this.disableButton = !this.isNewCloneTypeValue;
  }
  get cloneTypeClass(){
    return this.isNewCloneTypeValue ? 'slds-hidden' : '';
  }
}