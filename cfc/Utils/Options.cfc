
component accessors="true" output="false" displayname="Options" hint="Select options"  {

    property name="options" default="";

    public cfc.Utils.Options function init () {
        return this;
    }

    public array function arrayData(from, to, callback, key = '', theForm = {}) {
		var arr = arrayNew(1);
		for (var i=Arguments.from; i LTE Arguments.to; i+=1) {
			arrayAppend(arr, Arguments.callback(i, Arguments.key, Arguments.theForm));
		}
		return arr;
	}

	public struct function options(value, key, theForm) {
		return {
			'selected':(StructKeyExists(Arguments.theForm, Arguments.key) AND Arguments.theForm[Arguments.key] EQ Arguments.value ? 'selected="selected"' : ''),
			'value':Arguments.value
		};
	}

	public struct function optionsWidthId(value, key, idx, theForm) {
		return {
			'idx': arguments.idx,
			'selected':(StructKeyExists(Arguments.theForm, Arguments.key) AND Arguments.theForm[Arguments.key] EQ Arguments.value ? 'selected="selected"' : ''),
			'value':Arguments.value
		};
	}

	public struct function optionsMonth(value, key, theForm) {
		return {
			'selected':(StructKeyExists(Arguments.theForm, Arguments.key) AND Arguments.theForm[Arguments.key] EQ Arguments.value ? 'selected="selected"' : ''),
			'id': Arguments.value,
			'value': MonthAsString(Arguments.value)
		};
	}

	public struct function dob(ctxForm) {
		return {
			'day': This.arrayData(1, 31, This.options, 'dobDay', Arguments.ctxForm),
			'month': This.arrayData(1, 12, This.optionsMonth, 'dobMonth', Arguments.ctxForm),
			'year': This.arrayReverse( This.arrayData(1920, year(now()), This.options, 'dobYear', Arguments.ctxForm) )
		};
	}

	public function optionsGender(ctxForm) {
		var result = arrayNew(1);
		arrayAppend(result, This.optionsWidthId('Select an option', 'question1', '', Arguments.ctxForm));		
		arrayAppend(result, This.optionsWidthId('Female', 'question1', 1, Arguments.ctxForm));
		arrayAppend(result, This.optionsWidthId('Male', 'question1', 2, Arguments.ctxForm));		
		arrayAppend(result, This.optionsWidthId('Other', 'question1', 3, Arguments.ctxForm));
		return result;		
	}

	public function optionsAgeGroup(ctxForm) {
		var result = arrayNew(1);
		arrayAppend(result, This.optionsWidthId('Select an age group', 'question2', '', Arguments.ctxForm));		
		arrayAppend(result, This.optionsWidthId('18-24', 'question2', 1, Arguments.ctxForm));		
		arrayAppend(result, This.optionsWidthId('25-34', 'question2', 2, Arguments.ctxForm));		
		arrayAppend(result, This.optionsWidthId('35-44', 'question2', 3, Arguments.ctxForm));
		arrayAppend(result, This.optionsWidthId('45-54', 'question2', 4, Arguments.ctxForm));
		arrayAppend(result, This.optionsWidthId('55+', 'question2', 5, Arguments.ctxForm));
		return result;		
	}
	
	public array function arrayReverse(arr) {
		var result = arrayNew(1);

		for (var i = arrayLen(arr); i GT 0; i-=1) {
			arrayAppend(result, arr[i]);
		}

		return result;
	}
    
}