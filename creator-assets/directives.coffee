Adventure = angular.module "AdventureCreator"

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
				.on("mouseover", (d, i) ->
					#  Animation effects on node mouseover
					d3.select(this).select("circle")
					.transition()
					.attr("r", 30)

					d3.select(this).select("text")
					.text( (d) ->
						d.name + " (Click to Edit)"
					)
					.transition()
					.attr("x", 10)
				)
				.on("mouseout", () ->
					# Animation effects on node mouseout
					d3.select(this).select("circle")
					.transition()
					.attr("r", 20)

					d3.select(this).select("text")
					.text( (d) ->
						d.name
					)
					.transition()
					.attr("x", 0)
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
					return "start" # sets horizontal alignment of text anchor
					# if d.children then return "end"
					# else return "start"
				)
				.attr("dx", 25) # sets X label offset from node (negative left, positive right side)
				# .attr("dx", (d) ->
				# 	# if d.children then return -gap
				# 	# else return gap
				# )
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
			treeSrv.findAndRemove $scope.treeData, $scope.nodeTools.target
			$scope.nodeTools.show = false
			treeSrv.set $scope.treeData


Adventure.directive "nodeCreationSelectionDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		$scope.showDialog = false

		$scope.editNode = () ->
			$scope.showCreationDialog = true
			$scope.showBackgroundCover = true

Adventure.directive "nodeCreationMc", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# $scope.question = ""

		$scope.$on "editedNode.target.changed", (evt) ->
			console.log "edited node changed!"

			if $scope.editedNode
				if $scope.editedNode.question then $scope.question = $scope.editedNode.question
				else $scope.question = null

		$scope.$watch "question", (newVal, oldVal) ->
			if newVal
				$scope.editedNode.question = newVal