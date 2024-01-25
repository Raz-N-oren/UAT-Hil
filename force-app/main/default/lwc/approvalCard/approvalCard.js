import { LightningElement, api } from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import { NavigationMixin } from "lightning/navigation";

export default class ApprovalCard extends NavigationMixin(LightningElement) {

  @api approval;
  @api checked = false;
  @api splitColumns;
  showApprovalRecordModal = false;
  message;
  // swipe function for approvals on touch screens
  handleSwipe(event) {
    event.preventDefault()
    // define the minimum distance to trigger the action
    const minDistance = 80;
    const container = this.template.querySelector('.swipe-container');
    // get the distance the user swiped
    console.log(container.scrollLeft)
    const swipeDistance = container.scrollLeft - container.clientWidth;
    if (swipeDistance < minDistance * -1) {
      this.message = 'בקשה נדחתה';
      this.submitApproval('Reject');
    } else if (swipeDistance > minDistance) {
      this.message = 'בקשה אושרה';
      this.submitApproval('Approve');
    } else {
      this.message = `did not swipe ${minDistance}px`;
    }
    console.log(this.message);
  }

  submitApproval(process) {
    console.log("line 34",process,this.approval);
    const passEventr = new CustomEvent('submitapproval', {
      detail: { process: process, approval: this.approval }
    });
    this.dispatchEvent(passEventr);
  }

  rejectPopUp = false;
  handleSubmit(event) {
    // type = "Approve" || "Reject"
    // HTML syntax for dataset = data-type=""
    const processType = event.target.dataset.type;

    // in case of reject open "are you sure?"" pop-up
    if (processType == 'Reject') {
      this.rejectPopUp = true;
    }
    else {
      this.submitApproval('Approve');
    }
  }

  onOpenOppClicked(event){
    console.log("RAZCHECK, 57, event", event.target);
    console.log("RAZCHECK, 57, approval.recordId", this.approval.recordId);
                // redirect to the opportunity record page
                this[NavigationMixin.Navigate]({
                  type: "standard__recordPage",
                  attributes: {
                      recordId: this.approval.recordId,
                      objectApiName: "Opportunity",
                      actionName: "view"
                  }
              });
  }

  handleReject() {
    this.submitApproval('Reject');
    this.rejectPopUp = true;
  }

  closeRejectPopUp() {
    this.rejectPopUp = false;
  }

  checkboxHandler() {
    this.checked = !this.checked;
  }

  @api checkCurrentApproval(boolean) {
    this.checked = boolean;
  }
  handleApprovalEditFormSucces() {

  }

  closeApprovalRecordModal() {
    this.showApprovalRecordModal = false;
  }


  viewRecord(event) {
    event.preventDefault();
    // if (this.isDesktop) {
    //   const recordId = event.target.dataset.id;
    //   window.location.assign(window.open('/' + recordId));
    // }
    // else {
    //   // Mobile!!!
    this.showApprovalRecordModal = true;
    // }
  }

  //change value to change display (according the funxtions below). support EN+HEB
  get objectApiName() {
    switch (this.approval.relatedTo) {
      case 'הנחה':
        return 'Discount__c';
      case 'Discount':
        return 'Discount__c';
      case 'הזדמנות':
        return 'Opportunity';
      case 'Opportunity':
        return 'Opportunity';
      // case "מטריצת הנחות":
      //   return false;
      //   case "בקשה למוצר חדש":
      //     return false;
      case "מחירון מיוחד":
        return 'IL_Price_Book__c';
      case "IL Price Book":
        return 'IL_Price_Book__c';
      default:
    }
  }
  //if הנחה was chosen 
  get isDiscount() {
    return this.objectApiName == 'Discount__c' ? true : false;
  }
  get isOpportunity() {
    return this.objectApiName == 'Opportunity' ? true : false;
  }
  get columns() {
    return !this.isDesktop || this.splitColumns ? '2' : '3';
  }
  get discountApprovalProductName() {
    //DISCOUNT!!!
    // Problem! when the product name is empty, or the key isn't Product_r - the table is NOT DISPLAY!
    //4 situations: if the Product = מוצר/משפחת מוצרים/תת מוצר/לא הגיע שם מוצר
    console.log("this.approval.relatedDis, 129,raz",JSON.stringify(this.approval.relatedDis));
    if (this.approval.relatedDis.hasOwnProperty("Product__r")) {
      return this.approval.relatedDis.Product__r?.Name;
    } if (this.approval.relatedDis.hasOwnProperty("Product_Family_new__r")) {
      return this.approval.relatedDis.Product_Family_new__r?.Name;
    } else if (this.approval.relatedDis.hasOwnProperty("Sub_Product_Family__c")) {
      return this.approval.relatedDis.Sub_Product_Family__c?.Name;
    } else {
      return "";
    }
  }
  get getNotDisText(){
   // approval.recDescription
   const notDisDescription = this.approval.recDescription;
console.log("142",notDisDescription);
   return this.approval.recDescription;
  }
get accountName(){
  return this.approval.relatedDis?.Account__r?.Name;
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