/**
 * @displayname Validator
 * @hint ValidationHandler for any model with validate
 * @author judachury
 */
component accessors="true" output="true" {

    property name="stack" default="";
    property name="errors" default="";

    include '/i18n/system/en-gb.cfm';

    /**
     * Constructor
     * 
     * @models an array with the models to validate
     */
    public cfc.Utils.Validator function init (models = ArrayNew(1)) {
        This.setStack(StructNew('ordered'));
        for (model in arguments.models) {
            var metadata = getMetadata(model);
            var temp = structNew('ordered');
            temp[metadata.displayname] = model;
            This.addModel(temp);
        }
        This.setErrors(StructNew('ordered'));
        return this;
    }
    
    /**
     * Add a model to validate
     * @hint the model you wish to validate
     */
	public void function addModel(required model) {
        StructAppend(variables.stack, arguments.model);
    }

    /**
     * get a model
     * @prop the property to get the desired model
     */
    public function getModel(required string prop) {
        if (structKeyExists(variables.stack, prop)) {
            return variables.stack[arguments.prop];
        } else {
            throw(resource.exceptions.validatorInvalidModel, 'ValidatorModelNoFound');
        }        
    }
    
    /**
     * @hint execute validate function on a model
     */
    public void function execute() {        
        for (model in variables.stack) {
            var temp = variables.stack[model].validate();
            if (NOT temp.valid) {
                structAppend(variables.errors, temp.errors);
            }
        }
    }

    /**
     * @hint check if execute produced any errors
     */
    public boolean function isValid() {
        return ( StructCount(This.getErrors()) ? false : true );
    }
    
}