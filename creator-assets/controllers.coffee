Adventure = angular.module "AdventureCreator"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, $rootScope, treeSrv) ->

	# Iterator that generates node IDs
	count = 1

	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.NARR = "narrative"
	$scope.END = "end"

	$scope.title = "My Adventure Widget"

	# NodeTools is an object that holds the parameters for the node modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		x: 0
		y: 0

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
		if newVal isnt oldVal and newVal isnt "none"
			console.log "displayNodeCreation updated to: " + newVal
			$scope.editedNode = treeSrv.findNode $scope.treeData, $scope.nodeTools.target
			# console.log $scope.editedNode

			# Inform the edit screens that the edited node has changed
			$rootScope.$broadcast "editedNode.target.changed"

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

		newNode =
			name: "Node #{count} (#{type})"
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

	Materia.CreatorCore.start $scope