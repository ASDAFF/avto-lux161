/**
 * App Router Controller
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# libs
	\backbone                                : { history }
	\backbone.marionette                     : { Controller, proxy-get-option }
	\backbone.wreqr                          : { radio }
	
	# models
	\app/collection/panel-menu               : { panel-menu-list }
	
	# views
	\app/view/login-form                     : LoginFormView
	\app/view/panel                          : PanelView
	\app/view/sections/pages/list            : PagesListView
	\app/view/sections/pages/add             : AddPageView
	\app/view/sections/pages/edit            : EditPageView
	\app/view/sections/catalog/sections-list : CatalogSectionsListView
	\app/view/sections/catalog/section-add   : CatalogSectionAddView
	\app/view/sections/catalog/section-edit  : CatalogSectionEditView
	\app/view/sections/catalog/elements-list : CatalogElementsListView
	\app/view/sections/catalog/element-add   : CatalogElementAddView
	\app/view/sections/catalog/element-edit  : CatalogElementEditView
	\app/view/sections/redirect/list         : RedirectListView
	\app/view/sections/redirect/add          : AddRedirectView
	\app/view/sections/redirect/edit         : EditRedirectView
	\app/view/sections/data/list             : DataListView
	\app/view/sections/data/add              : AddDataView
	\app/view/sections/data/edit             : EditDataView
	\app/view/sections/accounts/list         : AccountsListView
	\app/view/sections/accounts/add          : AddAccountView
	\app/view/sections/accounts/edit         : EditAccountView
}


police = radio.channel \police


class AppRouterController extends Controller
	
	get-option: proxy-get-option
	
	\main : !->
		
		if @get-option \app .auth-model .get \is_authorized
			history.navigate \#panel, { +trigger, +replace }
			return
		
		model = @get-option \app .auth-model
		login-form-view = new LoginFormView { model } .render!
		
		@get-option \app .get-region \container .show login-form-view
	
	\panel : !->
		
		return unless @auth-handler!
		
		if history.fragment is \panel
			# go to first menu item
			first-ref = panel-menu-list.toJSON!.0.ref
			history.navigate first-ref, { +trigger, +replace }
	
	\pages-list : !->
		@panel-page-handler <| new PagesListView! .render!
	\add-page : !->
		@panel-page-handler <| new AddPageView! .render!
	\edit-page : (id)!->
		@panel-page-handler <| new EditPageView { id: Number id } .render!
	
	\catalog-sections-list : !->
		@panel-page-handler <| new CatalogSectionsListView! .render!
	\catalog-section-add : !->
		@panel-page-handler <| new CatalogSectionAddView! .render!
	\catalog-section-edit : (sid)!->
		new CatalogSectionEditView {
			\section-id : Number sid
			id: Number sid
		}
			..render!
			@panel-page-handler ..
	
	\catalog-elements-list : (sid)!->
		new CatalogElementsListView { \section-id : Number sid } .render!
		|> @panel-page-handler
	\catalog-element-add : (sid)!->
		new CatalogElementAddView { \section-id : Number sid } .render!
		|> @panel-page-handler
	\catalog-element-edit : (sid, eid)!->
		new CatalogElementEditView {
			\section-id : Number sid
			id: Number eid
		}
			..render!
			@panel-page-handler ..
	
	\redirect-list : !->
		@panel-page-handler <| new RedirectListView! .render!
	\add-redirect : !->
		@panel-page-handler <| new AddRedirectView! .render!
	\edit-redirect : (id)!->
		@panel-page-handler <| new EditRedirectView { id: Number id } .render!
	
	\data-list : !->
		@panel-page-handler <| new DataListView! .render!
	\add-data : !->
		@panel-page-handler <| new AddDataView! .render!
	\edit-data : (id)!->
		@panel-page-handler <| new EditDataView { id: Number id } .render!
	
	\accounts : !->
		@panel-page-handler <| new AccountsListView! .render!
	\account-add : !->
		@panel-page-handler <| new AddAccountView! .render!
	\account-edit : (id)!->
		@panel-page-handler <| new EditAccountView { id: Number id } .render!
	
	\logout : !->
		return unless @auth-handler false
		@get-option \app .auth-model .logout success: !~>
			history.navigate \#, { +trigger, +replace }
	
	\unknown : !->
		police.commands.execute \panic, new Error 'Route not found'
	
	
	auth-handler: (store-ref=true)->
		| not @get-option \app .auth-model .get \is_authorized =>
			@store-ref = history.fragment if store-ref
			history.navigate \#, { +trigger, +replace }
			false
		| @store-ref? =>
			ref = delete @store-ref
			history.navigate "##ref", { +trigger, +replace }
			false
		| otherwise => true
	
	panel-page-handler: (view)!->
		
		return unless @auth-handler!
		
		panel-view = new PanelView! .render!
		
		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show view


module.exports = AppRouterController
