/**
 * Text form field model
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# models
	\app/model/form/field : { FormFieldModel }
	
	# helpers
	\app/utils/objects : { has-own-prop }
}


export class SelectFormFieldModel extends FormFieldModel
	
	(attrs = {}, opts = {})!->
		new-attrs = {}
			<<< attrs
			<<< (switch typeof! attrs.value
				| \Undefined \Null =>
					{ value: attrs.options?0?value ? null }
				| \String \Number => # got something from server
					{ attrs.value })
		super new-attrs, opts
	
	attributes-typings: {}
		<<< super::attributes-typings
		<<< do
			type: (is \select)
			
			# 'value' must have same type as in 'options' items
			# 'set' method checks it
			value: (typeof!) >> (in <[Number String]>)
			
			options: ->
				| typeof! it isnt \Array => false
				| it.length is 0 => false
				| not it.every (->
					typeof! it is \Object
					and typeof! it.value in <[Number String]>
					and typeof! it.title is \String) => false
				| otherwise => true
	
	set: (key, val, opts)->
		if typeof! key is \Object
			attrs = key
			opts  = val
			delete! [key, val]
			if has-own-prop attrs, \value and (@get \options)?
			and not @get \options .some (.value is attrs.value)
				throw new Error "
					Error while setting new value.
					\ Value '#{attrs.value}' not found in options list.
				"
			super attrs, opts
		else
			if key is \value and (@get \options)?
			and not @get \options .some (.value is val)
				throw new Error "
					Error while setting new value.
					\ Value '#val' not found in options list.
				"
			super key, val, opts
