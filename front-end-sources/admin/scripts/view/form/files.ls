/**
 * FilesItemView of FormView
 *
 * @author Viacheslav Lotsmanov
 * @author Andrew Fatkulin
 */

require! {
	# libs
	\jquery              : $
	\backbone.marionette : { ItemView, CollectionView, LayoutView }
	\backbone.wreqr      : { radio }
	
	# config
	\app/config.json
	
	# utils
	\app/utils/dashes : { camelize: cm }
}



# files field parent view
class FilesItemView extends LayoutView
	
	tag-name: \div
	class-name: \files
	template: \form/files
	
	ui:
		file            : 'input[type=file]'
		\uploaded-block : \.js-uploaded-earlier-block
	
	events:
		'change @ui.file' : cm \on-add-files
	
	regions:
		\uploaded-list  : \.js-uploaded-earlier-list-region
	
	initialize: !->
		
		super? ...
		
		ValuesView = switch @model.get \name
			| \images \main_image => FilesValuesListImagesView
			| otherwise           => FilesValuesListView
		
		@values-list-view = new ValuesView collection: @model.get \value
			..render!
	
	on-destroy: !->
		super? ...
		delete @values-list-view
	
	on-show: !->
		super? ...
		@get-region \uploaded-list .show @values-list-view
		@listen-to (@model.get \value), 'reset add remove', @update-title-state
		@update-title-state!
	
	update-title-state: !->
		if (@model.get \value).length > 0
		then @ui.'uploaded-block'.show!
		else @ui.'uploaded-block'.hide!
	
	on-add-files: (ev)!->
		ev.prevent-default!
		ev.stop-propagation!
		@ui.file.prop \disabled, yes
		@model.get \value
			..upload [ .. for @ui.file.get 0 .files ], do
				success: !~> @ui?file?prop? \disabled, no
				fail:    !~> @ui?file?prop? \disabled, no



# files field values list child view
class FilesValuesListView extends CollectionView
	
	tag-name: \ul
	class-name: 'list-group files-values-list'
	get-child-view: -> FilesValueListItemView
	
	ui: -> switch @collection.get-option \mode
		| \single   => {}
		| \multiple => drag-row: \li
		| otherwise => ...
	events: -> switch @collection.get-option \mode
		| \single   => {}
		| \multiple =>
			"dragstart @ui.#{cm \drag-row}" : cm \on-drag-start
			"dragend   @ui.#{cm \drag-row}" : cm \on-drag-end
			
			# hover stuff
			"dragenter @ui.#{cm \drag-row}" : cm \on-drag-enter
			"dragover  @ui.#{cm \drag-row}" : cm \on-drag-over
			"dragleave @ui.#{cm \drag-row}" : cm \on-drag-leave
			
			# do stuff after dropped
			"drop      @ui.#{cm \drag-row}" : cm \on-drop
		| otherwise => ...
	
	initialize: !->
		
		super? ...
		
		@_drag-data = null
		
		@listen-to @collection, \view:drag-start, !->
			@$el.add-class \files-values-list--dragging
		@listen-to @collection, \view:drag-end, !->
			@$el.remove-class \files-values-list--dragging
	
	
	# kinda decorator
	# only when 'mode' is 'multiple'
	@extract-drag-data = (f, ev)-->
		
		return unless @_drag-data?
		
		{ collection-cid, model-cid } = @_drag-data
		
		model = @collection.get model-cid
		unless model?
			throw new Error "Cannot get model by cid: '#model-cid'"
		
		hover-model = @collection.get <| @$ ev.current-target .data \model-cid
		
		f.call @, { collection-cid, model-cid, model, hover-model }, ev
	
	# only when 'mode' is 'multiple'
	on-drag-start: (ev)!->
		
		model = @collection.get <| @$ ev.current-target .data \model-cid
		return unless model?
		
		ev.original-event.data-transfer
			..effect-allowed = \move
			..set-data \text/plain, '' # make drag works
		@_drag-data =
			collection-cid : @collection.cid
			model-cid      : model.cid
		
		@collection.trigger \view:drag-start
		model.trigger \view:drag-start
	
	# only when 'mode' is 'multiple'
	on-drag-end: @extract-drag-data ({ model }, ev)!->
		model.trigger \view:drag-end
		@collection.trigger \view:drag-end
		@_drag-data = null
	
	# only when 'mode' is 'multiple'
	on-drag-enter: @extract-drag-data ({ model, hover-model }, ev)!->
		hover-model.trigger \view:drag-enter
		@collection.trigger \view:drag-enter-only, hover-model
	
	# only when 'mode' is 'multiple'
	on-drag-over: @extract-drag-data (, ev)!->
		ev.prevent-default!
		ev.original-event.data-transfer.drop-effect = \move
	
	# only when 'mode' is 'multiple'
	on-drag-leave: @extract-drag-data ({ model, hover-model }, ev)!->
		hover-model.trigger \view:drag-leave
	
	# only when 'mode' is 'multiple'
	on-drop: @extract-drag-data ({ model, hover-model }, ev)!->
		ev.prevent-default!
		ev.stop-propagation!
		@collection.move-to model, hover-model
		@on-drag-end ...


# files field values (images) list child view
class FilesValuesListImagesView extends FilesValuesListView
	get-child-view: -> FilesValueListItemImageView
	class-name: "#{super::class-name ? ''} files-images-values-list"



# files field value list item child view
class FilesValueListItemView extends ItemView
	
	tag-name: \li
	class-name: 'list-group-item files-value-item'
	template: \form/files/file-list-item
	attributes: -> switch @model.collection.get-option \mode
		| \single   => {}
		| \multiple => draggable: true
		| otherwise => ...
	
	initialize: !->
		super? ...
		@$el.data \model-cid, @model.cid
		@listen-to @model,            \view:drag-start,      @on-drag-start
		@listen-to @model,            \view:drag-end,        @on-drag-end
		@listen-to @model,            \view:drag-enter,      @on-drag-enter
		@listen-to @model,            \view:drag-leave,      @on-drag-leave
		@listen-to @model.collection, \view:drag-end,        @on-drag-leave
		@listen-to @model.collection, \view:drag-enter-only, @on-drag-enter-only
	
	serialize-model: (model)->
		{ [.., model.get ..] for <[local filename]> }
		<<< { file-url: model.get-file-url! }
	
	ui:
		input  : \.js-file-input-field
		delete : \.js-delete-file-button
	events:
		'focus @ui.input'  : cm \on-input-field-focus
		'click @ui.delete' : cm \on-delete-button-pressed
	
	on-input-field-focus: (ev)!->
		ev.prevent-default!
		@ui.input.select!
	
	on-delete-button-pressed: (ev)!->
		ev.prevent-default!
		@model.destroy!
	
	on-drag-start: !-> @$el.add-class \files-value-item--drag-hold
	on-drag-end: !-> @$el.remove-class \files-value-item--drag-hold
	
	on-drag-enter: !-> @$el.add-class \files-value-item--drag-over
	on-drag-leave: !-> @$el.remove-class \files-value-item--drag-over
	
	on-drag-enter-only: (hover-model)!->
		if hover-model isnt @model
			@$el.remove-class \files-value-item--drag-over


# files field value (image) list item child view
class FilesValueListItemImageView extends FilesValueListItemView
	template: \form/files/image-list-item



module.exports = FilesItemView
