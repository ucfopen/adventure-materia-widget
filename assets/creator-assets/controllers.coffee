Adventure = angular.module "Adventure"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, $rootScope, $timeout, treeSrv, legacyQsetSrv) ->

	# Define constants for node screen types
	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.NARR = "narrative"
	$scope.END = "end"
	$scope.LINK = "link" # Probably not required

	# Define constants for the link mode types
	$scope.NEW = "new"
	$scope.EXISTING = "existing"
	$scope.SELF = "self"

	$scope.title = ""

	$scope.hidePlayerTitle = false

	# NodeTools is an object that holds the parameters for the nodeTools modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		type: null
		x: 0
		y: 0
		showResetWarning: false
		showDeleteWarning: false
		showConvertDialog: false

	# newNodeManager works like nodeTools, holds parameters of the newNodeManager modal and works w/ the directive
	$scope.newNodeManager =
		show: false
		target: null
		answerId: null # alphanumeric hash to identify the exact answer (target can be non-unique)
		x: 0
		y: 0
		linkMode: "new" # options should be "new" | "existing" | "self"

	# Parameters for the answer deletion confirmation dialog
	$scope.deleteDialog =
		show: false
		target: null
		targetIndex: null
		x: 0
		y: 0

	$scope.existingNodeSelectionMode = false
	$scope.existingNodeSelected = null

	$scope.copyNodeMode = false
	$scope.copyNodeTarget = null

	# This instantiation of treeData is required. It populates the "Start" node.
	$scope.treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	# Since the entire tree SVG can be dragged around, we need to track the X & Y offsets representing where the SVG is positioned relative to "normal"
	# These offsets are applied to modals that depend on item locations within the SVG, e.g., the nodeTools dialog and answer-tooltips
	# This object is passed thru to the draggableTree directive when it's added to the tree-svg container that D3 generates
	$scope.treeOffset =
		x: 0
		y: 0
		moving: false
		scale: 1
		scaleXOffset: 0
		scaleYOffset: 0

	# The displayNodeCreation flag controls the visiblity of node creation screens
	$scope.displayNodeCreation = "none"
	# Scope reference for the node currently being edited in a creation screen, updates when displayNodeCreation changes
	$scope.editedNode = null

	$scope.hoveredNode =
		showTooltips: false
		target: null
		tooltips: [] # initially an empty array that's populated on-hover with the target's answerLinks array
		x: 0
		y: 0
		pendingHide: false

	$scope.validation =
		show: false
		errors: []

	$scope.$watch "displayNodeCreation", (newVal, oldVal) ->

		# Returning from a suspended node creation screen, don't do anything
		if oldVal is "suspended" then return

		if newVal isnt oldVal and newVal isnt "none" and newVal isnt "suspended"
			$scope.editedNode = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			if newVal is $scope.END and $scope.editedNode.pendingTarget
				$scope.toast "Can't make an End Point! Move or remove child destinations first."
				$scope.displayNodeCreation = "none"
				return

			$scope.showCreationDialog = false
			if $scope.editedNode.type is $scope.BLANK then $scope.editedNode.type = $scope.displayNodeCreation

			# Inform the edit screens that the edited node has changed
			$rootScope.$broadcast "editedNode.target.changed"
		else if newVal is "suspended"
			$scope.newNodeManager.show = false
		else if newVal is "none"
			$scope.newNodeManager.show = false
			$scope.newNodeManager.target = null

			# start a timer that makes toasts obsolete after 5 seconds
			if $scope.showToast
				$timeout (() ->
					$scope.hideToast()
				), 5000

			console.log $scope.editedNode

			if $scope.editedNode and $scope.editedNode.hasProblem
				delete $scope.editedNode.hasProblem
				treeSrv.set $scope.treeData

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

			# Warn the user if a final score hasn't been set upon closing the creation screen
			# TODO there may be more post-creation-exit events required: condense these?
			if $scope.editedNode and $scope.editedNode.type is $scope.END
				if $scope.editedNode.finalScore is null
					$scope.toast "End Point " + $scope.editedNode.name + " is missing a valid final score!"


	$scope.hideCoverAndModals = ->
		$scope.showIntroDialog = false
		$scope.showBackgroundCover = false
		$scope.nodeTools.show = false
		$scope.showCreationDialog = false
		$scope.showDeleteWarning = false
		$scope.showTitleEditor = false
		$scope.validation.show = false

		$scope.displayNodeCreation = "none"

	$scope.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.title = "My Adventure Widget"

			$scope.showIntroDialog = true
			$scope.showBackgroundCover = true

	$scope.initExistingWidget = (title,widget,qset,version,baseUrl) ->

		showIntroDialog = false

		if qset
			# Convert the old qset prior to using it
			if parseInt(version) is 1 then qset = JSON.parse legacyQsetSrv.convertOldQset qset

			$scope.$apply () ->
				$scope.title = title
				$scope.treeData = treeSrv.createTreeDataFromQset qset

				if qset.options.hidePlayerTitle then $scope.hidePlayerTitle = qset.options.hidePlayerTitle

				# Check to make sure the tree doesn't have errors
				validation = treeSrv.validateTreeOnStart $scope.treeData
				if validation.length
					$scope.validation.errors = validation
					$rootScope.$broadcast "validation.error"

				treeSrv.set $scope.treeData
				treeSrv.updateAllAnswerLinks $scope.treeData

	$scope.onSaveClicked = (mode = 'save') ->
		if mode is "publish" then validation = treeSrv.validateTreeOnSave $scope.treeData
		else validation = []

		# Run the tree validation when save is clicked
		# If errors are found, halt the save and bring up the validation dialog
		if validation.length
			$scope.validation.errors = validation
			$rootScope.$broadcast "validation.error"

			return Materia.CreatorCore.cancelSave ''
		else
			qset = treeSrv.createQSetFromTree $scope.treeData
			qset.options.hidePlayerTitle = $scope.hidePlayerTitle
			Materia.CreatorCore.save $scope.title, qset, 2

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	# handles hover behavior of associated tooltips
	# (associated answer & validation warnings)
	$scope.onNodeHover = (data) ->
		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return
		$scope.hoveredNode.pendingHide = false
		if $scope.hoveredNode.target isnt data.id

			$scope.$apply () ->
				$scope.hoveredNode.x = data.x
				$scope.hoveredNode.y = data.y
				$scope.hoveredNode.target = data.id

	# Handles hover-out behavior of associated tooltips
	# Because hoverout can trigger quite often while mousing over node's dom elements, each time a hoverout happens, a pending flag is set
	# if the flag is reset by another hover event happening, don't hide the tooltip (cursor is still traveling over the node)
	# If it's not reset, go ahead and hide the tooltip
	$scope.onNodeHoverOut = (data) ->
		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return
		if $scope.hoveredNode.target is data.id
			if $scope.hoveredNode.showTooltips is true
				$scope.hoveredNode.pendingHide = true
				$timeout (() ->
					if $scope.hoveredNode.pendingHide is true
						$scope.$apply () ->
							$scope.hoveredNode.showTooltips = false
							$scope.hoveredNode.target = null
				), 500
		else if $scope.hoveredNode.target isnt data.id
			$scope.hoveredNode.showTooltips = false

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->

		# If a bridge is clicked, automagically add a node to replace the bridge
		# Creates a node between the bridge link's parent and child
		if data.type is "bridge"
			$scope.addNodeInBetween data
			return

		# If we're in existingNodeSelectionMode, we need to listen for an existing node to be
		# selected to update an answer's target.
		if $scope.existingNodeSelectionMode
			$scope.$apply () ->
				$scope.existingNodeSelected = data
				$scope.existingNodeSelectionMode = false

		# Otherwise, if we're in copyNodeMode, the selected target is considered the copyNodeTarget
		# Kicks off the listener to complete the node copy mode
		else if $scope.copyNodeMode
			$scope.$apply () ->
				$scope.copyNodeTarget = data
				$scope.copyNodeMode = false

		else # Default selection behavior
			$scope.$apply () ->
				$scope.nodeTools.show = !$scope.nodeTools.show
				$scope.nodeTools.x = data.x
				$scope.nodeTools.y = data.y
				$scope.nodeTools.type = data.type
				# nodeTools refresh triggered by change in target property (see nodeToolsDialog directive)
				if $scope.nodeTools.show is false then $scope.nodeTools.target = null else $scope.nodeTools.target = data.id

				$scope.nodeTools.showResetWarning = false
				$scope.nodeTools.showDeleteWarning = false

	# Handles clicks in the negative space of the treeViz svg
	# Used to close the nodeTools popup, or whatever else is needed
	$scope.bgClicked = ->
		$scope.$apply () ->
			$scope.nodeTools.show = false

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	# TODO this ought to be moved to treeSrv
	$scope.addNode = (parent, type) ->

		newId = treeSrv.getNodeCount()
		treeSrv.incrementNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: parent
			type: type
			contents: []

		treeSrv.findAndAdd $scope.treeData, parent, newNode

		treeSrv.set $scope.treeData

		$scope.nodeTools.show = false
		$scope.nodeTools.target = null # forces nodeTools to refresh target data to account for change in parent Y

		# Sometimes getting the id of the newly created node is required, so return it
		newId

	# Function that explicitly adds a node between an existing parent and child
	$scope.addNodeInBetween = (data) ->

		newId = treeSrv.getNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: data.source
			type: $scope.BLANK
			contents: []
			pendingTarget: data.target

		if data.specialCase
			if data.specialCase is "otherNode"
				newNode.hasLinkToOther = true

		treeSrv.findAndAddInBetween $scope.treeData, data.source, data.target, newNode

		treeSrv.incrementNodeCount()
		treeSrv.set $scope.treeData

		treeSrv.updateAllAnswerLinks $scope.treeData

	# Restores an answer/node pair that's been deleted, formatted as a "cold storage" object
	# target is the id of the node to be restored
	# parent is a reference to the node that's storing the deleted node in its deletedCache array
	$scope.restoreDeletedNode = (target, parent) ->

		# Assume deletedCache exists on the editedNode - if not, something's wrong
		unless parent.deletedCache then return

		angular.forEach parent.deletedCache, (item, index) ->

			if item.id is target
				# Splice the answer and node back into their respective arrays at their previous index positions
				parent.answers.splice item.answerIndex, 0, item.answer
				parent.contents.splice item.nodeIndex, 0, item.node
				parent.deletedCache.splice index, 1

				# Update the tree to display the restored node
				treeSrv.set $scope.treeData

				# Refresh all answerLinks references as some have changed
				treeSrv.updateAllAnswerLinks $scope.treeData

				return

	# Reference function so the integerToLetters function from treeSrv can be called using two-way data binding
	$scope.integerToLetters = (val) ->
		return treeSrv.integerToLetters(val)

	# onMediaImportComplete is required by the creator core
	# Since it's not intrinsically tied to any one dom element, and does no dom manipulation,
	# we just update the editedNode object and kick off a broadcast that directives will listen for
	$scope.onMediaImportComplete = (media) ->

		unless $scope.editedNode
			console.log "Uh oh, media import doesn't have a target node"
			return

		$scope.editedNode.media =
			type: "image"
			url: Materia.CreatorCore.getMediaUrl media[0].id
			id: media[0].id
			align: "right"

		$rootScope.$broadcast "editedNode.media.updated"

	$scope.generateDebugQset = ->
		qset = treeSrv.createQSetFromTree $scope.treeData
		qset.options.hidePlayerTitle = $scope.hidePlayerTitle

		$scope.showQsetGenerator = true
		$scope.generatedQset = JSON.stringify qset, null, 2


	# Start 'er up!
	Materia.CreatorCore.start $scope