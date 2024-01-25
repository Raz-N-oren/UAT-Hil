import { LightningElement, wire } from 'lwc';
import Utils from "c/utils";
import FORM_FACTOR from '@salesforce/client/formFactor';
import getSubmittedRecords from '@salesforce/apex/MultiRecordsApprovalController.getSubmittedRecords';
import processRecordsDB from '@salesforce/apex/MultiRecordsApprovalController.processRecords';
import getPriceForProduct from '@salesforce/apex/discountDetailsController.getPriceForProduct';

export default class ApprovalComponent extends LightningElement {
accountId;
// productId;

  // סינון תהליך
  relatedTo = [
    { label: "ללא", value: "ללא" },
    { label: "הנחה", value: "הנחה" },
    { label: "הזדמנות", value: "הזדמנות" },
    { label: "מטריצת הנחות", value: "מטריצת הנחות" },
    { label: "בקשה למוצר חדש", value: "בקשה למוצר חדש" },
    { label: "מחירון מיוחד", value: "מחירון מיוחד" }
  ];
  relatedToValue;

  // סינון לקוח
  accountName = [{ label: "ללא", value: "ללא" }];
  accountNameValue;

  // סינון מוצר
  ProductName = [{ label: "ללא", value: "ללא" }];
  productNameValue;

  // סינון נוצר על ידי
  submittedBy = [{ label: "ללא", value: "ללא" }];
  submittedByValue;
  relatedDis=[];

  allApprovals = [];

  loading;
  allChecked = false;
  splitColumns = false;

  // onchange handler for assign value to variable
  relatedToFilterHandler(event) {
    this.relatedToValue = '';
    const val = event.currentTarget.value;
    if (val != 'ללא') {
      this.relatedToValue = val;
    }
  }

  // onchange handler for assign value to variable
  accountNameFilterHandler(event) {
    this.accountNameValue = '';
    const val = event.currentTarget.value;
    if (val != 'ללא') {
      this.accountNameValue = val;
    }
  }

  // onchange handler for assign value to variable
  productNameFilterHandler(event) {
    this.productNameValue = '';
    const val = event.currentTarget.value;
    if (val != 'ללא') {
      this.productNameValue = val;
    }
  }

  // onchange handler for assign value to variable
  submittedByFilterHandler(event) {
    this.submittedByValue = '';
    const val = event.currentTarget.value;
    if (val != 'ללא') {
      this.submittedByValue = val;
    }
  }


  connectedCallback() {
    this.getSubmittedRecords();
  }
  getSubmittedRecords() {
    this.loading = true;
    getSubmittedRecords().then(result => {
      console.log("getSubmittedRecords: ", result)
      result.forEach(res => {
       // console.log(res,"res 70");
        if (!this.submittedBy.find(({ label }) => label === res?.submittedBy)) {
          this.submittedBy.push({ label: res.submittedBy, value: res.submittedBy })
          console.log("submittedBy",this.submittedBy);
        }
        if (res?.accountName && !this.accountName.find(({ label }) => label === res?.accountName)) {
          this.accountName.push({ label: res.accountName, value: res.accountName })
          console.log("accountName",this.accountName);
        }
        if (res?.ProductName && !this.ProductName.find(({ label }) => label === res?.ProductName)) {
          this.ProductName.push({ label: res.ProductName, value: res.ProductName })
          console.log("RAZCHECK, 98, ProductName",this.ProductName);
        }
        // if (res?.relatedDis && !this.relatedDis.find(({ current }) => current === res?.relatedDis)) {
        //   this.relatedDis.push(res.relatedDis)
        //   console.log("relatedDis:",this.relatedDis);
        // }

      })
      console.log("RAZCHECK, 106","acc",this.accountName,"sub",this.submittedBy,"pro",this.ProductName);
      this.allApprovals = result;
      console.log("RACHECK,108, this.allApprovals",this.allApprovals);
      // this.accountId=this.allApprovals.relatedDis?.Account__r.Id;
      // this.productId=this.allApprovals.relatedDis?.Product__c;
      // this.getPriceForProduct();
      console.log("82",this.allApprovals);
      this.loading = false;
    }).catch(err => {
      this.loading = false;
      console.error(err)
    })
  }

  // @wire(getPriceForProduct, { productId: this.productId, accountId: this.accountId })
  // priceCalculation({ data, error }) {
  //     if (data) {
  //         console.log(data,"line 151 data");
  //         this.productPrice = data.Tonnes;
  //         this.totalCubePrice = data.Cubes;
  //         this.totalTonesPrice = data.Tonnes;
  //         console.log("data: ", data);
  //         if (data.Tonnes == -1 && data.Cubes == -1) {
  //             Utils.showToast(this, "שגיאה", 'לא קיים מחירון תקף עבור מוצר זה', "error");
  //         } else {
  //             this.tonnePriceBeforeDiscount = data.Tonnes.toFixed(2);
  //             this.cubePriceBeforeDiscount = data.Cubes.toFixed(2);
  //             this.calculatePricesAfterDiscount(null);
  //         }
  //     }
  //     else if (error) {
  //         this.tonnePriceBeforeDiscount = 0;
  //         this.tonnePriceAfterDiscount = 0;
  //         this.cubePriceBeforeDiscount = 0;
  //         this.cubePriceAfterDiscount = 0;
  //         this.productPrice = 0;
  //         this.totalCubePrice = 0;
  //         this.totalTonesPrice = 0;
  //     }
  // }


  handleApprove(event) {
    const approval = event.detail.approval;
    console.log("Approval,133,approvalcOMPOnent", approval);
    const processType = event.detail.process;
    const strwraprecs = [];
    strwraprecs.push(approval);
    this.processRecords(processType, JSON.stringify(strwraprecs));
  }

  massApprovalHandler(event) {
    console.log("line num 94:", JSON.stringify(event.target.dataset.type));

    //type = "Approve" or "Reject"
    const processType = event.target.dataset.type;
    const strwraprecs = [];
    try {
      //push all checked components to the array strwraprecs
      this.template.querySelectorAll("c-approval-card").forEach(component => {
        if (component.checked) {
          // approval = attribute, assign to the whole object in the current iteration
          strwraprecs.push(component.approval);
        }
      })
      //processType = approved/rejected
      this.processRecords(processType, JSON.stringify(strwraprecs));
    } catch (err) {
      console.error(err);
    }
  }


  // type = approve/reject, wrapper = all approvals after st 
  processRecords(type, wrapper) {
    processRecordsDB({ processType: type, strwraprecs: wrapper }).then(result => {
      try {
        console.log("processRecords success: ", result)
        Utils.showToast(this, 'הצלחה', result, "success");
        // this.getSubmittedRecords();
        let submittedApprovalsArray = JSON.parse(wrapper);
        //filter, return and display all the checked objects 
        submittedApprovalsArray.forEach(submittedApproval => {
          this.allApprovals = this.allApprovals.filter(approval => approval.recordId != submittedApproval.recordId);
        });
        console.log(" this.allApprovals,173,Raz", this.allApprovals);
      } catch (err) {
        console.error(err)

      }
    }).catch(err => {
      console.error(err)
    })
  }

  handleAllChecked(event) {
    if (event.target.checked) {
      console.log("Checked")
      this.allChecked = true;
    }
    else {
      console.log("Not Checked")
      this.allChecked = false;
    }
  }


  handleSplitColumns() {
    this.splitColumns = !this.splitColumns;
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

  //if 1, 2 or 3 items for filter is requested. happens after mounting. if after choosing dd to display, another dd is chosen - it change the display automatically
  get allApprovalsToDisplay() {
    // כאן להוסיף תמיכה למחיר מחירון
    if (this.submittedByValue && this.relatedToValue && this.accountNameValue && this.productNameValue) {
      return this.allApprovals.filter(approval => 
        approval.submittedBy == this.submittedByValue 
        && approval.relatedTo == this.relatedToValue && 
        approval.accountName == this.accountNameValue
        && approval.ProductName == this.productNameValue);
    }
    if (this.submittedByValue && this.relatedToValue) {
      return this.allApprovals.filter(approval => approval.submittedBy == this.submittedByValue && approval.relatedTo == this.relatedToValue);
    }
    if (this.submittedByValue && this.accountNameValue) {
      return this.allApprovals.filter(approval => approval.submittedBy == this.submittedByValue && approval.accountName == this.accountNameValue);
    }
    if (this.relatedToValue && this.accountNameValue) {
      return this.allApprovals.filter(approval => approval.relatedTo == this.relatedToValue && approval.accountName == this.accountNameValue);
    }
    if (this.submittedByValue && this.productNameValue) {
      return this.allApprovals.filter(approval => approval.submittedBy == this.submittedByValue && approval.ProductName == this.productNameValue);
    }
    if (this.relatedToValue && this.productNameValue) {
      return this.allApprovals.filter(approval => approval.relatedTo == this.relatedToValue && approval.ProductName == this.productNameValue);
    }
    if (this.relatedToValue) {
      return this.allApprovals.filter(approval => approval.relatedTo == this.relatedToValue);
    }
    if (this.submittedByValue) {
      return this.allApprovals.filter(approval => approval.submittedBy == this.submittedByValue);
    }
    if (this.accountNameValue) {
      return this.allApprovals.filter(approval => approval.accountName == this.accountNameValue);
    }
    if (this.productNameValue) {
      return this.allApprovals.filter(approval => approval.ProductName == this.productNameValue);
    }
    else return this.allApprovals;
  }

  get submittedByOptions() {
    return this.submittedBy.length > 1 ? this.submittedBy : null;
  }

  get accountNameOptions() {
    console.log("accountName 200:",this.accountName);
    console.log("accountName 200:",this.accountName.length);
    // const testi = this.accountName.map(current=> {return current})
    // console.log("accountName 200:",testi);
    // return testi;
    return this.accountName.length > 1 ? this.accountName : null;

  }

  get productNameOptions() {
    console.log("RAZCHECK, 257:",this.ProductName);
    console.log("RAZCHECK, 257:",this.ProductName.length);

    return this.ProductName.length > 1 ? this.ProductName : null;

  }
  get headerClass() {
    return this.isDesktop ? 'sticky-header' : 'header';
  }

  get headerBodyClass() {
    return this.isDesktop ? "slds-grid slds-wrap slds-p-left_small slds-p-right_small" : "slds-grid slds-wrap slds-p-left_small slds-p-right_small";
  }
  // slds-grid_align-spread
  get cardsContainerClass() {
    return this.splitColumns ? "slds-m-top_small slds-m-bottom_small slds-grid slds-wrap" : "slds-m-top_small slds-m-bottom_small";
  }
  get cardsClass() {
    return this.splitColumns ? "slds-size_1-of-2 slds-p-horizontal_medium" : '';
  }
}