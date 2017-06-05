/**
 * Form Edit View
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# libs
	\backbone       : { history, Collection }
	\backbone.wreqr : { radio }
	
	# config
	\app/config.json
	
	# models
	\app/model/basic            : { BasicModel }
	\app/collection/form/fields : { FormFieldsCollection }
	\app/model/form/form-vm     : { FormViewModel }
	
	# views
	\app/view/smooth    : SmoothView
	\app/view/loader    : LoaderView
	\app/view/form/form : FormView
	
	# helpers
	\app/utils/panic-attack : { panic-attack }
}


class FormEditView extends SmoothView
	
	initialize: !->
		
		super? ...
		
		
		# validation
		for opt-name in <[section type list-page]>
			if (typeof! @get-option opt-name) isnt \String
			or (@get-option opt-name).trim!.length is 0
				panic-attack new Error "Incorrect '#{opt-name}' option"
		if (@get-option \type) not in <[add edit]>
			panic-attack new Error "Incorrect 'type' option"
		if (@get-option \type) is \edit
		and (typeof! @get-option \id) isnt \Number
			panic-attack new Error "
				Incorrect 'id' option
				\ (it's required when 'type' option value is 'edit')
			"
		if (typeof! @get-option \section-id) not in <[Undefined Number]>
			panic-attack new Error "Incorrect 'section-id' option"
		
		
		@loader-view = new LoaderView! .render!
		
		
		# fields
		
		@form-fields-collection = new FormFieldsCollection null,
			do
				section : @get-option \section
				type    : @get-option \type # 'add' or 'edit'
			<<< (switch @get-option \type | \edit => id: @get-option \id)
			<<< (switch
				| (@get-option \section-id)? =>
					\item-section-id : @get-option \section-id)
		
		@form-fields-view-model = new FormViewModel do
			section : @get-option \section
			type    : @get-option \type # 'add' or 'edit'
		
		@form-fields-view = new FormView do
			model      : @form-fields-view-model
			collection : @form-fields-collection
	
	
	on-destroy: !->
		super? ...
		delete @loader-view
		delete @form-fields-collection
		delete @form-fields-view-model
		delete @form-fields-view
	
	
	on-show: !->
		
		super? ...
		
		@get-region \main .show @loader-view
		@form-fields-collection
			@listen-to-once (..), 'sync reset', !->
				@get-region \main .show @form-fields-view
			..fetch!
		
		@listen-to @form-fields-view, \cancel:form, !~>
			history.navigate (@get-option \list-page), { +trigger }
	
	regions:
		main: \.main
	
	class-name: \v-stretchy
	template: \main
	model: new BasicModel!


module.exports = FormEditView
