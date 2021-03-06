/**
 * Text form field model
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\underscore : _
	
	\app/model/form/field : { FormFieldModel }
}


export class TextFormFieldModel extends FormFieldModel
	
	defaults: -> {}
		<<< (_.result super::, \defaults)
		<<< { value: '' }
	
	attributes-typings: {}
		<<< super::attributes-typings
		<<< do
			type: (is \text)
			value: \String
