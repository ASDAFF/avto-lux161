/**
 * Catalog Section Edit View
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! \app/view/form-edit : FormEditView


class CatalogSectionEditView extends FormEditView
	initialize: !->
		@options.type = \edit
		@options.id = @get-option \id
		@options\list-page = "\#panel/catalog/section_#{@get-option \id}/"
		@options.section = \catalog_section
		super? ...


module.exports = CatalogSectionEditView
