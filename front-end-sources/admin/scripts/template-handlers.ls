/**
 * template handlers
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\jquery              : $
	\backbone.marionette : { TemplateCache }
	\jade/jade
}

static-url = $ \html .attr \data-templates-path

# let webpack deal with it
templates-bundle =
	\accounts/list-item           : require \tpl/accounts/list-item.jade
	\accounts/list                : require \tpl/accounts/list.jade
	\catalog/elements-list-header : require \tpl/catalog/elements-list-header.jade
	\catalog/elements-list-item   : require \tpl/catalog/elements-list-item.jade
	\catalog/elements-list-main   : require \tpl/catalog/elements-list-main.jade
	\catalog/elements-list        : require \tpl/catalog/elements-list.jade
	\catalog/sections-list-item   : require \tpl/catalog/sections-list-item.jade
	\catalog/sections-list        : require \tpl/catalog/sections-list.jade
	\data/list-item               : require \tpl/data/list-item.jade
	\data/list                    : require \tpl/data/list.jade
	\form/data-fields/add         : require \tpl/form/data-fields/add.jade
	\form/data-fields/field       : require \tpl/form/data-fields/field.jade
	\form/data-fields/text        : require \tpl/form/data-fields/text.jade
	\form/data-fields/textarea    : require \tpl/form/data-fields/textarea.jade
	\form/data-fields             : require \tpl/form/data-fields.jade
	\form/files                   : require \tpl/form/files.jade
	\form/files/file-list-item    : require \tpl/form/files/file-list-item.jade
	\form/files/image-list-item   : require \tpl/form/files/image-list-item.jade
	\form/checkbox                : require \tpl/form/checkbox.jade
	\form/form                    : require \tpl/form/form.jade
	\form/error                   : require \tpl/form/error.jade
	\form/html                    : require \tpl/form/html.jade
	\form/password                : require \tpl/form/password.jade
	\form/select                  : require \tpl/form/select.jade
	\form/text                    : require \tpl/form/text.jade
	\pages/list-item              : require \tpl/pages/list-item.jade
	\pages/list                   : require \tpl/pages/list.jade
	\redirect/list-item           : require \tpl/redirect/list-item.jade
	\redirect/list                : require \tpl/redirect/list.jade
	\ask-sure                     : require \tpl/ask-sure.jade
	\err-msg                      : require \tpl/err-msg.jade
	\fatal-error                  : require \tpl/fatal-error.jade
	\loader                       : require \tpl/loader.jade
	\login-form                   : require \tpl/login-form.jade
	\main                         : require \tpl/main.jade
	\menu-item                    : require \tpl/menu-item.jade
	\panel                        : require \tpl/panel.jade
	\panel-username               : require \tpl/panel-username.jade

compiled-templates = {[k, jade.compile v] for k, v of templates-bundle}

export load = (template-id)->
	if compiled-templates.has-own-property template-id
		then compiled-templates[template-id]
		else throw new Error "Template '#{template-id}' isn't declared"

export compile = (raw-template)-> raw-template
export render = (template, data)-> TemplateCache .get template <| data
