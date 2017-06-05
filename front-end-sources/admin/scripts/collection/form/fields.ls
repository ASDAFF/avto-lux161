/**
 * Edit/add form fields collection
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# config
	\app/config.json
	
	# models
	\app/collection/basic : { BasicCollection }
	
	# fields models
	\app/model/form/field-by-type/checkbox : { CheckboxFormFieldModel }
	\app/model/form/field-by-type/text     : { TextFormFieldModel }
	\app/model/form/field-by-type/html     : { HtmlFormFieldModel }
	\app/model/form/field-by-type/password : { PasswordFormFieldModel }
	\app/model/form/field-by-type/files    : { FilesFormFieldModel }
	\app/model/form/field-by-type/select   : { SelectFormFieldModel }
	
	# helpers
	\app/utils/panic-attack : { panic-attack }
}


export class FormFieldsCollection extends BasicCollection
	
	initialize: (models = [], opts = {})!->
		super? models, opts
		if typeof! opts.section isnt \String or opts.section.length is 0
			panic-attack new Error "
				Incorrect 'section' option for FormFieldsCollection
			"
		if opts.type not in <[add edit]>
			panic-attack new Error "
				Incorrect 'type' option for FormFieldsCollection
			"
		if opts.type is \edit and typeof! opts.id isnt \Number
			panic-attack new Error "
				Incorrect 'id' option for FormFieldsCollection
				\ which is required when 'type' option is 'edit'
			"
		if opts.type is \add and typeof! opts.id isnt \Undefined
			panic-attack new Error "
				Do not set 'id' option for FormFieldsCollection
				\ when 'type' option is 'add'
			"
		if typeof! opts.\item-section-id not in <[Undefined Number]>
			panic-attack new Error "
				Incorrect 'item-section-id' option for FormFieldsCollection
			"
	
	model: (attrs = {}, opts = {})->
		
		section = opts.collection.get-option \section
		
		# validation of types
		switch section
		| \data =>
			unless attrs.type in <[text data_fields]>
				panic-attack new Error "
					Unexpected type ('#{attrs.type}') for '#section' section
				"
		| otherwise => # other sections
			unless attrs.type in <[checkbox text html files password select]>
				panic-attack new Error "Unexpected type: '#{attrs.type}'"
		
		attrs =
			{ section, form_type: opts.collection.get-option \type }
			<<< attrs
		
		new (
			# model pattern matching
			switch attrs.type
			| \checkbox => CheckboxFormFieldModel
			| \text     => TextFormFieldModel
			| \html     => HtmlFormFieldModel
			| \password => PasswordFormFieldModel
			| \files    => FilesFormFieldModel
			| \select   => SelectFormFieldModel
			| otherwise => panic-attack new Error "
				There is no model for form field type: '#{attrs.type}'
			"
		) attrs, opts
			..check-if-is-valid!
	
	fetch: (opts = {})!->
		try
			type = @get-option \type # 'edit' or 'add'
			section = @get-option \section
			
			unless (typeof! section) is \String
				throw new Error '@section must be overwritten'
			
			data = {
				action: \get_fields
				args: JSON.stringify \
					{ section }
					<<< (switch
						| type is \edit => { +edit, id: @get-option \id })
			} <<< (opts.data ? void)
			
			super {} <<< opts <<< { data }
		catch
			panic-attack e
	
	parse: (response)->
		try
			[{ ..name, ..type, ..default_val } <<< (
				switch @get-option \type
					| \add =>
						switch ..type
						| \select => options: ..list_values
						| \files  => mode: ..mode
					| \edit =>
						switch ..type
						| \password => void
						| \select   =>
							options: ..list_values
							value: response.values_list[..name]
						| \files    =>
							mode: ..mode
							value: response.values_list[..name]
						| otherwise => value: response.values_list[..name]
			) for response.fields_list]
		catch
			panic-attack e
	
	comparator: ->
		config.sections[@get-option \section]
			.fields_sort
			.index-of it.get \name
	
	save: ({ success = null, fail = null } = {})!->
		
		@trigger \reset:error_message_code
		
		section = @get-option \section
		type = @get-option \type # 'add' or 'edit'
		
		url =
			| section is \accounts =>
				switch type
				| \add  => config.create_account_url
				| \edit => config.update_account_url
			| otherwise => null # use default @url
		
		crud-action = switch type
			| \add  => \create
			| \edit => \update
		
		get-serialized-field-value = ({ value: v })->
			| v is on                      => \on
			| v instanceof BasicCollection => JSON.stringify v.toJSON!
			| otherwise                    => v
		
		args = {}
			<<< (switch | section isnt \accounts => { section })
			<<< (switch | type is \edit => { id: @get-option \id })
			<<< (switch
				| (@get-option \item-section-id)? =>
					{ section_id: @get-option \item-section-id })
			<<< { \
				[..name, get-serialized-field-value ..] for @toJSON!
				when typeof! ..value isnt \Boolean or ..value is on }
		
		req-opts = {}
			<<< (switch | url? => { url })
			<<< do
				data:
					| section is \accounts => args
					| otherwise =>
						action: (switch type | \add => \add | \edit => \update)
						args: JSON.stringify args
				success: (response)!~>
					switch response.status
					| \error =>
						switch response.error_code
						| \unique_key_exist \incorrect_data =>
							@trigger \error_message_code, response.error_code
							fail? @, response
						| _ => panic-attack new Error 'Incorrect server data'
					| \success => success? @, response
					| _ => panic-attack new Error 'Incorrect server data'
					
		
		@sync crud-action, @, req-opts
