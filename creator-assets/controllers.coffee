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

	$scope.title = "My Adventure Widget"

	# NodeTools is an object that holds the parameters for the nodeTools modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		x: 0
		y: 0

	$scope.newNodeManager =
		show: false
		target: null
		x: 0
		y: 0
		linkMode: "new" # options should be "new" | "existing" | "self"

	$scope.existingNodeSelectionMode = false
	$scope.existingNodeSelected = null

	# This instantiation of treeData is required. It populates the "Start" node.
	$scope.treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	$scope.displayNodeCreation = "none"
	$scope.editedNode = null # Node being targeted for editing

	$scope.$watch "displayNodeCreation", (newVal, oldVal) ->
		if newVal isnt oldVal and newVal isnt "none" and newVal isnt "suspended"
			$scope.editedNode = treeSrv.findNode $scope.treeData, $scope.nodeTools.target
			$scope.showCreationDialog = false
			# console.log $scope.editedNode
			if $scope.editedNode.type is $scope.BLANK then $scope.editedNode.type = $scope.displayNodeCreation

			# Inform the edit screens that the edited node has changed
			$rootScope.$broadcast "editedNode.target.changed"
		else if newVal is "suspended"
			$scope.newNodeManager.show = false
		else if newVal is "none"
			$scope.newNodeManager.show = false
			$scope.newNodeManager.target = null
			# console.log $scope.treeData

	# treeSrv.set $scope.treeData

	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.step = 1 # what's dis do?
		$scope.hideCover()

	$scope.hideCoverAndModals = ->
		$scope.showBackgroundCover = false
		$scope.nodeTools.show = false
		$scope.showCreationDialog = false

		$scope.displayNodeCreation = "none"
		# $scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.initNewWidget = (widget, baseUrl) ->
		console.log "initNewWidget"
		$scope.$apply ->
			$scope.showIntroDialog = true
			$scope.showBackgroundCover = true

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->

		# Don't do anything if the node is a bridge
		# It's not a -real- node, we don't care about it like that
		if data.type is "bridge" then return

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

	Materia.CreatorCore.start $scope