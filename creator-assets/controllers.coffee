Adventure = angular.module "AdventureCreator"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, $rootScope, treeSrv) ->

	# Iterator that generates node IDs
	count = 1

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
		x: 0
		y: 0

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
		else # Default selection behavior
			$scope.$apply () ->
				$scope.nodeTools.show = !$scope.nodeTools.show
				$scope.nodeTools.x = data.x
				$scope.nodeTools.y = data.y
				$scope.nodeTools.target = data.id # nodeTools refresh triggered by change in target property
										# (see nodeToolsDialog directive)

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	# TODO this ought to be moved to treeSrv
	$scope.addNode = (parent, type) ->

		newId = count
		newName = $scope.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: parent
			type: type
			contents: []

		treeSrv.findAndAdd $scope.treeData, parent, newNode

		count++
		treeSrv.set $scope.treeData

		$scope.nodeTools.show = false
		$scope.nodeTools.target = null # forces nodeTools to refresh target data to account for change in parent Y

		# Sometimes getting the id of the newly created node is required, so return it
		newId

	# Function that explicitly adds a node between an existing parent and child
	$scope.addNodeInBetween = (data) ->

		newId = count
		newName = $scope.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: data.source
			type: $scope.BLANK
			contents: []
			pendingTarget: data.target

		treeSrv.findAndAddInBetween $scope.treeData, data.source, data.target, newNode

		count++
		treeSrv.set $scope.treeData

	# Helper function that converts node IDs to their respective alphabetical counterparts
	# e.g., 1 is "A", 2 is "B", 26 is "Z", 27 is "AA", 28 is "AB"
	$scope.integerToLetters = (val) ->

		if val is 0 then return "Start"

		iteration = 0
		prefix = ""

		while val > 26
			iteration++
			val -= 26

		if iteration > 0 then prefix = String.fromCharCode 64 + iteration

		chars = prefix + String.fromCharCode 64 + val

		chars

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
		qset = treeSrv.generateQSetFromTree $scope.treeData

		console.log JSON.stringify(qset, null, 2)


	# Start 'er up!
	Materia.CreatorCore.start $scope