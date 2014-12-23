# Create an angular module to import the animation module and house our controller
Adventure = angular.module "AdventureCreator", ["ngAnimate", "ngSanitize"]

Adventure.service "treeSrv", ($rootScope) ->

	treeData =
		name: "Start"
		type: "blank"
		id: 0
		contents: []

	set = (data) ->
		treeData = data
		$rootScope.$broadcast "tree.nodes.added"

	get = ->
		treeData

	set : set
	get : get

Adventure.directive "treeVisualization", (treeSrv) ->
	restrict: "E",
	scope: {
		data: "=",
		onClick: "&"
	},
	link: ($scope, $element, $attrs) ->

		$scope.svg = null

		console.log "treeVisualization linked!"

		$scope.$on "tree.nodes.added", (evt) ->
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
					.attr("width", 1000)
					.attr("height",650)
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
					$scope.onClick {data: d.id}
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

Adventure.controller "AdventureCtrl", ($scope, $filter, treeSrv) ->

	count = 0

	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.END = "end"

	$scope.title = "My Adventure Widget"

	$scope.treeData =
		name: "Start"
		type: "blank"
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

	$scope.nodeSelected = (data) ->

		# console.log $filter("filter")($scope.treeData, {id: data})[0]
		console.log findAndRemove(data)
		# $scope.treeData.contents.pop()
		treeSrv.set $scope.treeData

	findAndRemove = (id) ->

		# Eventually, this will include a search algorithm to find and remove the node from treeData based on the id.
		for node, index in $scope.treeData.contents
			console.log node

	$scope.addNode = (type) ->
		console.log "adding node of type: " + type

		newNode =
			name: "Node #{count} (#{type})"
			id: count
			type: type
			contents: []

		# $scope.treeData.contents.push { name: "Node #{count}", contents: [] }

		$scope.treeData.contents.push newNode
		count++
		treeSrv.set $scope.treeData

	Materia.CreatorCore.start $scope
