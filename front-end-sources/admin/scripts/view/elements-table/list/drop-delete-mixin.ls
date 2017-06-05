/**
 * Drag'n'drop detele mixin for TableListView
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	\./drag-row-mixin : { DragBreak }
	
	\app/utils/panic-attack : { panic-attack }
}


# required to be used with drag-row-table-list-view-mixin
# it's senseless without '.js-drop-delete-zone' block in template
export drop-delete-table-list-view-mixin =
	
	ui:
		\drop-delete-zone : \.js-drop-delete-zone
	
	events:
		'drop      @ui.drop-delete-zone' : \on-delete-drop
		'dragover  @ui.drop-delete-zone' : \on-delete-drop-over
		'dragleave @ui.drop-delete-zone' : \on-delete-drop-leave
		'dragend   @ui.drop-delete-zone' : \on-delete-drop-end
	
	\on-delete-drop : !-> @on-delete-drop ...
	on-delete-drop: (e)!->
		
		try { model-id } = @extract-drag-data e
		catch then if e instanceof DragBreak then return else throw e
		
		e.prevent-default!
		e.stop-propagation!
		
		<~! @delete-by-model-id model-id
		
		@ui.'drop-delete-zone'?remove-class \drop-over
	
	# can be overwritten to put some middleware
	delete-by-model-id: (model-id, cb = null)!->
		@collection.get model-id
			unless ..?
				panic-attack new Error "Model by id '#model-id' not found"
			..destroy!
		cb?!
	
	\on-delete-drop-over : !-> @on-delete-drop-over ...
	on-delete-drop-over: (e)!->
		
		try @extract-drag-data e
		catch then if e instanceof DragBreak then return else throw e
		
		e.prevent-default!
		e.original-event.data-transfer.drop-effect = \copy
		@ui.\drop-delete-zone .add-class \drop-over
	
	\on-delete-drop-leave : !-> @on-delete-drop-leave ...
	on-delete-drop-leave: (e)!->
		
		try @extract-drag-data e
		catch then if e instanceof DragBreak then return else throw e
		
		@ui.\drop-delete-zone .remove-class \drop-over
