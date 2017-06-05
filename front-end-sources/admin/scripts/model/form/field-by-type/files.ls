/**
 * Files form field model
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# models
	\app/model/basic : { BasicModel }
	\app/collection/basic : { BasicCollection }
	\app/model/localization : { LocalizationModel }
	\app/model/type-validation-mixin : { type-validation-model-mixin }
	\app/model/form/field : { FormFieldModel }
	
	# helpers
	\app/utils/mixins : { call-class-mixins }
	\app/utils/panic-attack : { panic-attack }
	
	# configs
	\app/config.json : { uploaded_file_prefix, upload_file_url }
}


/**
 * Form field parent model.
 */
export class FilesFormFieldModel extends FormFieldModel
	
	(attrs = {}, opts = {})!->
		new-attrs = {}
			<<< attrs
			<<< (switch typeof! attrs.value
				| \Undefined \Null =>
					{ value: new FilesListFormFieldCollection do
						null
						mode: attrs.mode }
				| \String => # got something from server
					{ value: new FilesListFormFieldCollection do
						JSON.parse attrs.value
						mode: attrs.mode }
				| otherwise =>
					if attrs.value instanceof FilesListFormFieldCollection
						{ attrs.value })
		super new-attrs, opts
	
	attributes-typings: {}
		<<< super::attributes-typings
		<<< do
			type: (is \files)
			value: (instanceof FilesListFormFieldCollection)
			mode: (in <[multiple single]>)


/**
 * Files list form field value collection.
 * Collection of files items.
 */
export class FilesListFormFieldCollection extends BasicCollection
	
	initialize: !->
		super? ...
		unless (@get-option \mode) in <[multiple single]>
			panic-attack new Error "
				Incorrect 'mode' option value: '#{@get-option \mode}'.
				\ It must be a 'multiple' or 'single'.
			"
	
	model: -> new FilesListFormFieldItemModel ...
	
	# there's no case for 'fail' for now
	upload: (files, { success = null, fail = null } = {})!->
		
		unless typeof! files is \Array
			panic-attack new Error "Incorrect 'files' argument"
		
		if (@get-option \mode) is \single and files.length > 1
			panic-attack new Error "
				Attempt to upload files more than one when 'mode' is 'single'
			"
		
		data = new FormData!
		for file, i in files
			unless file instanceof File
				panic-attack new Error "
					Files list must contain only instances of File
				"
			data.append "file_#i", file
		
		@sync \create, @, do
			url: upload_file_url
			data: data
			success: (response)!~>
				
				# data from server validation
				if typeof! response.files isnt \Array
				or response.files.some (-> typeof! it.name isnt \String)
					panic-attack new Error "
						Incorrect files list data from server
					"
				
				[filename: ..name for response.files]
					(-> success? it) switch @get-option \mode
					| \single   => @reset ..
					| \multiple => @add ..
					| otherwise => ...
	
	# moves 'target' model at 'move-to' model ordering position
	# only when 'mode' is 'multiple'
	move-to: (target, move-to)!->
		
		if (@get-option \mode) is 'single'
			panic-attack new Error "
				When 'mode' is 'single' it's impossible to reorder anything
			"
		
		return if target is move-to # nothing to do
		
		order = @models.reduce _, [] <| (list, model)~>
			| model is target => list
			| model is move-to => list ++ [target, model]
			| otherwise => list ++ model
		
		old-comparator = @comparator
		@comparator = (a, b)->
			[idx-a, idx-b] = [order.index-of .. for [a, b]]
			switch
			| idx-a < idx-b => -1
			| idx-a > idx-b =>  1
			| otherwise     =>  0
		@sort!
		@comparator = old-comparator


/**
 * Files form field value collection item model.
 * Single item model of files list value collection.
 */
export class FilesListFormFieldItemModel
extends BasicModel
implements type-validation-model-mixin
	
	[ type-validation-model-mixin ]
		@_call-class = call-class-mixins ..
	
	initialize: !-> (@@_call-class super::, \initialize) ...
	
	attributes-typings:
		local: (instanceof LocalizationModel)
		
		filename: \String
	
	get-file-url: -> "#{uploaded_file_prefix}#{@get \filename}"
	
	toJSON: -> {[k, v] for k, v of @attributes when k in <[filename]>}
