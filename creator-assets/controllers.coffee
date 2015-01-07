Adventure = angular.module "AdventureCreator"
Adventure.controller "AdventureCtrl", ($scope, $filter, $compile, treeSrv) ->

	# Iterator that generates node IDs
	count = 1

	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
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

	# treeSrv.set $scope.treeData

	$scope.setTitle = ->
		$scope.title = $scope.introTitle or $scope.title
		$scope.step = 1 # what's dis do?
		$scope.hideCover()

	$scope.hideCover = ->
		$scope.showTitleDialog = $scope.showIntroDialog = false

	$scope.initNewWidget = (widget, baseUrl) ->
		console.log "initNewWidget"
		$scope.$apply ->
			$scope.showIntroDialog = true

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->
		$scope.$apply () ->
			$scope.nodeTools.show = !$scope.nodeTools.show
			$scope.nodeTools.target = data.id
			$scope.nodeTools.x = data.x
			$scope.nodeTools.y = data.y

	# Recursive function for finding a node and removing it
	# parent: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# id: the id the node to be removed
	$scope.findAndRemove = (parent, id) ->

		if !parent.children then return

		# iterator required instead of using angular.forEach
		i = 0

		while i < parent.children.length

			child = parent.children[i]

			if child.id == id
				parent.children.splice i, 1
			else
				$scope.findAndRemove parent.children[i], id
				i++

		parent

	# Recursive function for adding a node to a specified parent node
	# tree: the tree structure to be iterated. Should initially reference the root node (treeData object)
	# parentId: the ID of the node to append the new node to
	# node: the data of the new node
	$scope.findAndAdd = (tree, parentId, node) ->

		if tree.id == parentId
			tree.contents.push node
			tree

		if !tree.children then return

		i = 0

		while i < tree.children.length

			child = tree.children[i]

			if child.id == parentId
				child.contents.push node
				return
			else
				$scope.findAndAdd tree.children[i], parentId, node
				i++

		tree

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	$scope.addNode = (parent, type) ->
		newNode =
			name: "Node #{count} (#{type})"
			id: count
			parentId: parent
			type: type
			contents: []

		$scope.findAndAdd $scope.treeData, parent, newNode

		count++
		treeSrv.set $scope.treeData
		$scope.nodeTools.show = false

	Materia.CreatorCore.start $scope