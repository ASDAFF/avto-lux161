/**
 * Table List View
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\backbone.marionette : { CompositeView }
	
	\app/model/basic     : { BasicModel }
}


class TableListView extends CompositeView
	
	class-name: 'panel panel-default'
	child-view-container: \tbody
	
	model: new BasicModel!
	
	ui:
		\refresh : \.refresh
	events:
		'click @ui.refresh' : \refresh-list
	
	\refresh-list : (e)!->
		e.prevent-default!
		@trigger \refresh:list


module.exports = TableListView
