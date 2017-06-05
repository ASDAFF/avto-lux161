/**
 * Edit/add form field model
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# models
	\app/model/basic                 : { BasicModel }
	\app/model/localization          : { LocalizationModel }
	\app/model/type-validation-mixin : { type-validation-model-mixin }
	
	# helpers
	\app/utils/mixins : { call-class-mixins }
}


export class FormFieldModel
extends BasicModel
implements type-validation-model-mixin
	
	[ type-validation-model-mixin ]
		@_call-class = call-class-mixins ..
	
	initialize: !-> (@@_call-class super::, \initialize) ...
	
	url: null
	
	attributes-typings:
		# view-model stuff
		local: (instanceof LocalizationModel)
		section: \String # for templates
		form_type: (in <[add edit]>) # for templates
		
		# model stuff
		name: \String
		type: null # must be overwritten in type-specific child class
		default_val: \Null # any default value now is null
		value: null # must be overwritten in type-specific child class
