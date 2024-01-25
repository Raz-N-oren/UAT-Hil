import { LightningElement, api } from 'lwc';

export default class UxDebouncedInput extends LightningElement {
    @api label = 'Lookup';
    @api placeholder ='';
    @api delay = 300;
    @api value;
    @api fieldName = null;
    @api isRequired = false;
    isfocused = false;
    // exposes the lwc-input focus() for using in the parent element
    @api focus(){ this.template.querySelector('.input').focus(); }
    @api validationError(){ return this.template.querySelector('.input') }

    constructor() {
        super();
        this.timeout = null;
    }

    handleFocus(event){
         this.isfocused = true;
         this.dispatchEvent(new CustomEvent('focus'));
         this.handleChange(event);
    }

    handleBlur(event){
        this.isfocused = false;
        this.dispatchEvent(new CustomEvent('blure'));
        this.handleChange(event);
    }

    /* Bubbles change event up after debouncing */
    handleChange(event) {
        event.stopPropagation();
        window.clearTimeout(this.timeout);
        let searchTerm = event.target.value;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.timeout = window.setTimeout(() => {
            this.fireChange(searchTerm);
        }, this.delay);
    }

    /* Sends changes back compatible to extended form when
       the fieldName has been set */
    // Fire the change up to uxQuickLookup
    fireChange(changedValue) {
        let eventName = this.fieldName ? 'valueChanged' : 'change';
        let payload = this.fieldName
            ? { name: this.fieldName, value: this.changedValue }
            : changedValue;

        let customChange = new CustomEvent(eventName, {
            detail: payload,
            bubbles: true,
            cancelable: true
        });
        this.dispatchEvent(customChange);
    }
}