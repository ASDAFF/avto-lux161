/**
 * App Router Controller
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\backbone : B
	\marionette : M
	\backbone.wreqr : W

	'../ajax-req'

	'../collection/panel-menu' : panel-menu-list
	'../view/login-form' : LoginFormView
	'../view/panel' : PanelView
	'../view/sections/pages/elements-list' : PagesElementsListView
	'../view/sections/catalog/sections-list' : CatalogSectionsListView
	'../view/sections/catalog/elements-list' : CatalogElementsListView
	'../view/sections/redirect/list' : RedirectListView
	'../view/sections/accounts/list' : AccountsListView
}

auth-handler = (obj, store-ref=true)->
	unless obj.get-option \app .is-auth
		obj.store-ref = B.history.fragment if store-ref
		B.history.navigate '#', { trigger: true, replace: true }
		return false
	else if obj.store-ref?
		ref = delete obj.store-ref
		B.history.navigate "##ref", { trigger: true, replace: true }
		return false

	true

class AppRouterController extends M.Controller
	get-option: M.proxy-get-option

	\main : !->
		if @get-option \app .is-auth
			B.history .navigate '#panel', { trigger: true, replace: true }
			return

		login-form-view = new LoginFormView app: @get-option \app
		login-form-view .render!

		@get-option \app .get-region \container .show login-form-view

	\panel : !->
		return unless auth-handler @

		if B.history.fragment is \panel
			# go to first menu item
			first-ref = panel-menu-list.toJSON![0].ref
			B.history .navigate first-ref, { trigger: true, replace: true }
			return

	\pages-elements-list : !->
		return unless auth-handler @

		panel-view = (new PanelView!).render!
		pages-view = (new PagesElementsListView!).render!

		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show pages-view

	\catalog-sections-list : !->
		return unless auth-handler @

		panel-view = (new PanelView!).render!
		catalog-view = (new CatalogSectionsListView!).render!

		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show catalog-view

	\catalog-elements-list : (section-id)!->
		return unless auth-handler @

		panel-view = (new PanelView!).render!
		catalog-view = new CatalogElementsListView \section-id : section-id
		catalog-view.render!

		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show catalog-view

	\redirect-list : !->
		return unless auth-handler @

		panel-view = (new PanelView!).render!
		redirect-view = (new RedirectListView!).render!

		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show redirect-view

	\accounts : !->
		return unless auth-handler @

		panel-view = (new PanelView!).render!
		accounts-view = (new AccountsListView!).render!

		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show accounts-view

	\logout : !->
		return unless auth-handler @, false

		ajax-req {
			url: '/adm/logout'
			success: (json)!~>
				unless json.status is \logout
					W.radio.commands .execute \police, \panic,
						new Error 'Logout error'

				@get-option \app .is-auth = false
				B.history.navigate '#', { trigger: true, replace: true }
		}

	\unknown : !->
		W.radio.commands .execute \police, \panic,
			new Error 'Route not found'

module.exports = AppRouterController
