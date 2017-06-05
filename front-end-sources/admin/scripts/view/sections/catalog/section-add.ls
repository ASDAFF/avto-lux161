/**
 * Catalog Section Add View
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! \app/view/form-edit : FormEditView


class CatalogSectionAddView extends FormEditView
	initialize: !->
		@options.type = \add
		@options\list-page = \#panel/catalog
		@options.section = \catalog_section
		super? ...


module.exports = CatalogSectionAddView
