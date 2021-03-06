/**
 * Redirect List View
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# views
	\app/view/list                      : ListView
	\app/view/elements-table/list/index : TableListView
	\app/view/elements-table/item/index : TableItemView
}


class ItemView extends TableItemView
	template: \redirect/list-item


class CompositeListView extends TableListView
	template: \redirect/list
	child-view: ItemView


class RedirectListView extends ListView
	
	initialize: !->
		super? ...
		@init-table-list CompositeListView
	
	on-show: !->
		super? ...
		@update-list !~> @get-region \main .show @table-view
	
	update-list: (cb)!->
		
		(data-arr)<~! @get-list action: \get_redirect_list
		
		new-data-list = []
		for item in data-arr
			new-data-list.push do
				id: item.id
				ref: "\#panel/redirect/edit_#{item.id}.html"
				old_url: item.old_url
				new_url: item.new_url
				status: item.status
		
		@table-list.reset new-data-list
		cb! if cb?


module.exports = RedirectListView
