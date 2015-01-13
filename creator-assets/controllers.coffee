Adventure = angular.module "AdventureCreator"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, treeSrv) ->

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
			console.log $scope.editedNode

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
			$scope.nodeTools.target = data.id
			$scope.nodeTools.x = data.x
			$scope.nodeTools.y = data.y

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	# TODO this ought to be moved to treeSrv
	$scope.addNode = (parent, type) ->
		newNode =
			name: "Node #{count} (#{type})"
			id: count
			parentId: parent
			type: type
			contents: []

		treeSrv.findAndAdd $scope.treeData, parent, newNode

		count++
		treeSrv.set $scope.treeData
		$scope.nodeTools.show = false

	Materia.CreatorCore.start $scope