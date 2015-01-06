# Create an angular module to import the animation module and house our controller
Adventure = angular.module "AdventureCreator", ["ngAnimate", "ngSanitize"]

Adventure.service "treeSrv", ($rootScope) ->

	# TreeData is being initialized in -two- places right now.
	# This one may or may not be required.
	# TODO: Find out if it's required.
	treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.changed"

	# Probably unnecessary
	get = ->
		treeData

	set : set
	get : get

Adventure.directive "treeVisualization", (treeSrv) ->
	restrict: "E",
	scope: {
		data: "=", # binds treeData in a way that's accessible to the directive
		onClick: "&" # binds a listener so the controller can access the directive's click data
	},
	link: ($scope, $element, $attrs) ->

		$scope.svg = null

		console.log "treeVisualization linked!"

		# Re-render tree whenever the nodes are updated
		$scope.$on "tree.nodes.changed", (evt) ->
			$scope.render treeSrv.get()

		$scope.render = (data) ->

			unless data? then return false

			# Init tree data
			tree = d3.layout.tree()
				.sort(null)
				.size([900, 350]) # sets size of tree
				.children (d) ->
					if !d.contents or d.contents.length is 0 then return null
					else return d.contents

			nodes = tree.nodes data
			links = tree.links nodes

			# Render tree
			if $scope.svg == null
				$scope.svg = d3.select($element[0])
					.append("svg:svg")
					.attr("width", 1000) # Size of actual SVG container
					.attr("height",650) # Size of actual SVG container
					.append("svg:g")
					.attr("class", "container")
					.attr("transform", "translate(0,50)") # translates position of overall tree in svg container
			else
				$scope.svg.selectAll("*").remove()

			link = d3.svg.diagonal()
				.projection (d) ->
					return [d.x, d.y] # seems to set whether the tree is drawn top-down or left-right
										# ensure the additional references to d.x and d.y are flipped too

			$scope.svg.selectAll("path.link")
				.data(links)
				.enter()
				.append("svg:path")
				.attr("class", "link")
				.attr("d", link)

			nodeGroup = $scope.svg.selectAll("g.node")
				.data(nodes)
				.enter()
				.append("svg:g")
				# .attr("class", "node")
				.attr("class", (d) ->
					"node #{d.type}"
				)
				.on("click", (d, i) ->
					$scope.onClick {data: d} # when clicked, we return all of the node's data
				)
				.attr("transform", (d) ->
					"translate(#{d.x},#{d.y})"
				)

			nodeGroup.append("svg:circle")
				.attr("class", "node-dot")
				.attr("r", 20) 				# sets size of node bubbles

			nodeGroup.append("svg:text")
				.attr("text-anchor", (d) ->
					if d.children then return "end"
					else return "start"
				)
				.attr("dx", (d) ->
					gap = 25
					if d.children then return -gap # sets X label offset from node (negative left, positive right side)
					else return gap
				)
				.attr("dy", 5) # sets Y label offset from node
				.text (d) ->
					d.name

		$scope.render treeSrv.get()

# Directive for the node modal dialog (add child, delete node, etc)
Adventure.directive "nodeToolsDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		# When target for the dialog changes, update the position values based on where the new node is
		$scope.$watch "nodeTools.target", (newVals, oldVals) ->

			xOffset = $scope.nodeTools.x + 10
			yOffset = $scope.nodeTools.y + 70

			styles = "left: " + xOffset + "px; top: " + yOffset + "px"

			$attrs.$set "style", styles

		$scope.addANode = () ->
			$scope.addNode $scope.nodeTools.target, $scope.BLANK

		$scope.dropNode = () ->
			$scope.findAndRemove $scope.treeData, $scope.nodeTools.target
			$scope.nodeTools.show = false
			treeSrv.set $scope.treeData

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
			$scope.nodeTools.show = true
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
