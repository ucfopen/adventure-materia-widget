Adventure = angular.module "AdventureCreator"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, $rootScope, $timeout, treeSrv) ->

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

	# NodeTools is an object that holds the parameters for the nodeTools modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		type: null
		x: 0
		y: 0
		showResetWarning: false

	# newNodeManager works like nodeTools, holds parameters of the newNodeManager modal and works w/ the directive
	$scope.newNodeManager =
		show: false
		target: null
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

	# The displayNodeCreation flag controls the visiblity of node creation screens
	$scope.displayNodeCreation = "none"
	# Scope reference for the node currently being edited in a creation screen, updates when displayNodeCreation changes
	$scope.editedNode = null

	$scope.hoveredNode =
		showTooltip: false
		target: null
		targetParent: null
		x: 0
		y: 0
		text: null
		pendingHide: false

	$scope.$watch "displayNodeCreation", (newVal, oldVal) ->
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

			# Make any existing toasts obsolete
			$scope.hideToast()

			console.log $scope.treeData

			# Warn the user if a final score hasn't been set upon closing the creation screen
			# TODO there may be more post-creation-exit events required: condense these?
			if $scope.editedNode and $scope.editedNode.type is $scope.END
				if $scope.editedNode.finalScore is null
					$scope.toast "End Point " + $scope.editedNode.name + " is missing a valid final score!"


	$scope.hideCoverAndModals = ->
		$scope.showBackgroundCover = false
		$scope.nodeTools.show = false
		$scope.showCreationDialog = false
		$scope.showDeleteWarning = false
		$scope.showTitleEditor = false

		$scope.displayNodeCreation = "none"

	$scope.initNewWidget = (widget, baseUrl) ->
		console.log "initNewWidget"
		$scope.$apply ->
			$scope.title = "My Adventure Widget"

			$scope.showIntroDialog = true
			$scope.showBackgroundCover = true

	$scope.initExistingWidget = (title,widget,qset,version,baseUrl) ->


		if qset
			$scope.$apply () ->
				$scope.title = title
				$scope.treeData = treeSrv.createTreeDataFromQset qset
				treeSrv.set $scope.treeData

	$scope.onSaveClicked = (mode = 'save') ->
		qset = treeSrv.createQSetFromTree $scope.treeData
		Materia.CreatorCore.save $scope.title, qset

	$scope.onSaveComplete = (title, widget, qset, version) -> true

	# handles hover behavior of associated tooltips
	# (associated answer & validation warnings)
	$scope.onNodeHover = (data) ->
		if data.type is "bridge" then return
		$scope.hoveredNode.pendingHide = false
		if $scope.hoveredNode.target isnt data.id and data.parentId isnt -1

			$scope.$apply () ->
				$scope.hoveredNode.x = data.x
				$scope.hoveredNode.y = data.y
				$scope.hoveredNode.targetParent = data.parentId
				$scope.hoveredNode.target = data.id

	# Handles hover-out behavior of associated tooltips
	# Because hoverout can trigger quite often while mousing over node's dom elements, each time a hoverout happens, a pending flag is set
	# if the flag is reset by another hover event happening, don't hide the tooltip (cursor is still traveling over the node)
	# If it's not reset, go ahead and hide the tooltip
	$scope.onNodeHoverOut = (data) ->
		if data.type is "bridge" then return
		if $scope.hoveredNode.target is data.id and data.parentId isnt -1
			if $scope.hoveredNode.showTooltip is true
				$scope.hoveredNode.pendingHide = true
				$timeout (() ->
					if $scope.hoveredNode.pendingHide is true
						$scope.$apply () ->
							$scope.hoveredNode.showTooltip = false
							$scope.hoveredNode.target = null
							$scope.hoveredNode.targetParent = null
				), 500
		else if $scope.hoveredNode.target isnt data.id
			$scope.hoveredNode.showTooltip = false

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->

		# Don't do anything if the node is a bridge
		# It's not a -real- node, we don't care about it like that
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
				$scope.nodeTools.target = data.id # nodeTools refresh triggered by change in target property
										# (see nodeToolsDialog directive)
				$scope.nodeTools.showResetWarning = false

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

		treeSrv.findAndAddInBetween $scope.treeData, data.source, data.target, newNode

		treeSrv.incrementNodeCount()
		treeSrv.set $scope.treeData

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

		console.log media

		$scope.editedNode.media =
			type: "image"
			url: Materia.CreatorCore.getMediaUrl media[0].id
			id: media[0].id
			align: "right"

		$rootScope.$broadcast "editedNode.media.updated"

	$scope.generateDebugQset = ->
		qset = treeSrv.createQSetFromTree $scope.treeData

		console.log JSON.stringify(qset, null, 2)


	# Start 'er up!
	Materia.CreatorCore.start $scope