/**
 * App Router Controller
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\backbone                                : { history }
	\backbone.marionette                     : { Controller, proxy-get-option }
	\backbone.wreqr                          : { radio }
	
	\app/collection/panel-menu               : { panel-menu-list }
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


# semaphore {{{

stop-counter = 0
stop-last-page = null

police.commands.set-handler \request-stop, !->
	stop-counter++
	if stop-counter is 1
		stop-last-page := history.fragment

police.commands.set-handler \request-free, !->
	stop-counter--
	if stop-counter is 0
		stop-last-page := null
	if stop-counter < 0
		throw new Error 'stop-counter cannot be less than zero'

restore-last-page = ->
	return true if stop-counter <= 0
	unless stop-last-page?
		throw new Error 'stop-last-page must be a string'
	history.navigate "\##stop-last-page", { +replace }
	false

# semaphore }}}


class AppRouterController extends Controller
	
	get-option: proxy-get-option
	
	\main : !->
		
		return unless restore-last-page!
		
		if @get-option \app .auth-model .get \is_authorized
			history.navigate \#panel, { +trigger, +replace }
			return
		
		model = @get-option \app .auth-model
		login-form-view = new LoginFormView { model } .render!
		
		@get-option \app .get-region \container .show login-form-view
	
	\panel : !->
		
		return if not restore-last-page! or not @auth-handler!
		
		if history.fragment is \panel
			# go to first menu item
			first-ref = panel-menu-list.toJSON!.0.ref
			history.navigate first-ref, { +trigger, +replace }
	
	\pages-list : !->
		@panel-page-handler <| new PagesListView! .render!
	\add-page : !->
		@panel-page-handler <| new AddPageView! .render!
	\edit-page : (id)!->
		@panel-page-handler <| new EditPageView { id } .render!
	
	\catalog-sections-list : !->
		@panel-page-handler <| new CatalogSectionsListView! .render!
	\catalog-section-add : !->
		@panel-page-handler <| new CatalogSectionAddView! .render!
	\catalog-section-edit : (sid)!->
		new CatalogSectionEditView { \section-id : sid, id: sid } .render!
		|> @panel-page-handler
	
	\catalog-elements-list : (sid)!->
		new CatalogElementsListView { \section-id : sid } .render!
		|> @panel-page-handler
	\catalog-element-add : (sid)!->
		new CatalogElementAddView { \section-id : sid } .render!
		|> @panel-page-handler
	\catalog-element-edit : (sid, eid)!->
		new CatalogElementEditView { \section-id : sid, id: eid } .render!
		|> @panel-page-handler
	
	\redirect-list : !->
		@panel-page-handler <| new RedirectListView! .render!
	\add-redirect : !->
		@panel-page-handler <| new AddRedirectView! .render!
	\edit-redirect : (id)!->
		@panel-page-handler <| new EditRedirectView { id } .render!
	
	\data-list : !->
		@panel-page-handler <| new DataListView! .render!
	\add-data : !->
		@panel-page-handler <| new AddDataView! .render!
	\edit-data : (id)!->
		@panel-page-handler <| new EditDataView { id } .render!
	
	\accounts : !->
		@panel-page-handler <| new AccountsListView! .render!
	\account-add : !->
		@panel-page-handler <| new AddAccountView! .render!
	\account-edit : (id)!->
		@panel-page-handler <| new EditAccountView { id } .render!
	
	\logout : !->
		return if not restore-last-page! or not @auth-handler false
		@get-option \app .auth-model .logout success: !~>
			history.navigate \#, { +trigger, +replace }
	
	\unknown : !->
		return unless restore-last-page!
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
		
		return if not restore-last-page! or not @auth-handler!
		
		panel-view = new PanelView! .render!
		
		@get-option \app .get-region \container .show panel-view
		panel-view.get-option \work-area .show view


module.exports = AppRouterController
