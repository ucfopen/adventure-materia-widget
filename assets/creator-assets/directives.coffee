Adventure = angular.module "Adventure"

Adventure.directive "toast", ($timeout) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.toastMessage = ""
		$scope.showToast = false
		$scope.toastActionText = ""
		$scope.toastAction = null
		$scope.showToastActionButton = false

		# Displays a toast with the given message.
		# The autoCancel flag determines if the toast should automatically expire after 5 seconds
		# If false, the toast will remain until clicked or disabled manually in code
		$scope.toast = (message, autoCancel = true) ->
			$scope.toastMessage = message
			$scope.showToast = true
			$scope.showToastActionButton = false

			if autoCancel
				$timeout (() ->
					$scope.hideToast()
				), 5000

		# Displays a toast with an action button
		# The action button is bound to an anonymous function that's passed as the action parameter
		# Interactive toasts won't time out, so be sure to make a hideToast() call when you no longer need it
		# hideToast() is automaticalfly called when editedNode is reset, when a node creation interface is closed
		$scope.interactiveToast = (message, actionText, action) ->
			$scope.toastMessage = message
			$scope.toastActionText = actionText
			$scope.toastAction = action

			$scope.showToast = true
			$scope.showToastActionButton = true

		$scope.hideToast = () ->
			$scope.showToast = false
			$scope.showToastActionButton = false


Adventure.directive 'enterSubmit', ($compile) ->
	($scope, $element, $attrs) ->
		$element.bind "keydown keypress", (event) ->
			if event.which is 13
				$scope.$apply ->
					$scope.$eval $attrs.enterSubmit

				event.preventDefault()

Adventure.directive "autoSelect", () ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->
		$element.on "click", () ->
			this.select()

# The true monster directive; handles the actual tree display for the widget
# Give up all hope, ye who enter here
# (Seriously, sorry in advance, D3 is a clusterf*ck)
Adventure.directive "treeVisualization", (treeSrv, $window, $compile, $rootScope) ->
	restrict: "E",
	scope: {
		data: "=", # binds treeData in a way that's accessible to the directive
		offset:"=", # svg transform values for the whole svg - passed thru draggable tree directive
		nodeClick: "&", # binds a listener so the controller can access the directive's click data
		bgClick: "&",
		onHover: "&",
		onHoverOut: "&"
	},
	link: ($scope, $element, $attrs) ->

		$scope.svg = null
		$scope.copyMode = false

		$scope.windowWidth = document.getElementById("adventure-container").offsetWidth - 15
		$scope.windowHeight = document.getElementById("adventure-container").offsetHeight - 60
		$scope.treeContainerWidth = null

		# Re-render tree whenever the nodes are updated
		$scope.$on "tree.nodes.changed", (evt) ->
			$scope.render treeSrv.get()

		# Re-render the tree with copyMode enabled (highlights blank nodes)
		$scope.$on "mode.copy", (evt) ->
			$scope.copyMode = true
			$scope.render treeSrv.get()

		$scope.render = (data) ->

			unless data? then return false

			# Determine the new nodeXOffset using the half width of the tree container
			if $scope.treeContainerWidth is null then $scope.treeContainerWidth = $scope.windowWidth/2
			else
				treeContainer = angular.element($element)
				$scope.treeContainerWidth = treeContainer[0].offsetWidth

			$scope.nodeXOffset = $scope.treeContainerWidth / 2

			# Init tree data
			tree = d3.layout.tree()
				.sort(null)
				# .size([$scope.windowWidth, adjustedHeight]) # sets size of tree
				.nodeSize([100, 160])
				.children (d) -> # defines accessor function for nodes (e.g., what the "d" object is)
					if !d.contents or d.contents.length is 0 then return null
					else return d.contents

			nodes = tree.nodes data # Setup nodes
			links = tree.links nodes # Setup links
			adjustedLinks = [] # Finalized links array that includes "special" links (loopbacks and bridges)

			angular.forEach nodes, (node, index) ->

				# Static offsets built into every node's X/Y coordinates
				# nodeXOffset centers the tree within the window
				# the Y offset moves the entire tree down slightly to create top padding
				node.x += $scope.nodeXOffset
				node.y += 50

				# the parent attribute isn't needed, and causes deep copy methods to fail since they recurse infinitely
				# best to remove it
				if node.parent then delete node.parent

				# If the node has any non-hierarchical links, have to process them
				# And generate new links that d3 won't create by default
				if node.hasLinkToOther

					# If the node is blank, but still has a non-hierarchical link, deal with it based on the pendingTarget id
					unless node.answers
						target = treeSrv.findNode treeSrv.get(), node.pendingTarget

						newLink = {}
						newLink.source = node
						newLink.target = target
						newLink.specialCase = "otherNode"

						links.push newLink
						return

					sameTargetLinks = []

					angular.forEach node.answers, (answer, index) ->

						if answer.linkMode is "existing"

							# Grab the targeted node for the new link
							target = treeSrv.findNode treeSrv.get(), answer.target

							# Craft the new link and add source & target
							newLink = {}

							newLink.source = node
							newLink.target = target
							newLink.specialCase = "otherNode"

							if sameTargetLinks[answer.target]
								newLink.sameTargetOffset = sameTargetLinks[answer.target]
								sameTargetLinks[answer.target]++
							else
								sameTargetLinks[answer.target] = 1

							links.push newLink

				# Generate "loopback" links that circle back to the same node
				# This link has the same source/target, the node itself
				# We use this info to tell D3 to draw the loopback element & display it (if necessary)
				if node.hasLinkToSelf

					numSelfLinks = 0

					for answer in node.answers

						if answer.linkMode is "self"

							newLink = {}
							newLink.source = node
							newLink.target = node
							newLink.specialCase = "loopBack"

							# Add an increased radius value for every additional loopback this node has
							newLink.radiusOffset = numSelfLinks
							numSelfLinks++

							links.push newLink


			# We need to effectively "filter" each link and create the intermediate nodes
			# The properties of the link and intermediate "bridge" nodes depends on what kind of link we have
			angular.forEach links, (link, index) ->

				source = link.source
				target = link.target

				# Right now, we're disabling bridge nodes on loopbacks
				# Might add them back in later
				if link.specialCase is "loopBack" then return
				else
					intermediate =
						x: source.x + (target.x - source.x)/2
						y: source.y + (target.y - source.y)/2
						type: "bridge"
						source: link.source.id
						target: link.target.id

				# If a link is a special case, the node's position isn't midway between source & target
				# Add a reference to the link's associated bridge node so the node coords can be updated later
				# This is a sort of hackish solution, but I've yet to discover a cleaner method
				if link.specialCase is "otherNode"
					link.bridgeNodeIndex = nodes.length
					intermediate.specialCase = link.specialCase

				nodes.push intermediate

			# Render tree
			if $scope.svg == null
				$scope.svg = d3.select($element[0])
					.append("svg:svg")
					.attr("id", "tree-svg")
					.attr("width", $scope.windowWidth) # Size of actual SVG container
					.attr("height",$scope.windowHeight) # Size of actual SVG container
					.attr("tree-transforms","")
					.attr("ng-model", "offset") # offset is equivalent to $scope.treeOffset, has to be passed to new directive
					.attr("ng-mousedown","selectTree($event)") # addl directives to control dragging behavior
					.attr("ng-mousemove", "moveTree($event)")
					.attr("ng-mouseup", "deselectTree($event)")
					.on("click", () ->
						$scope.bgClick()
					)
					.append("svg:g")
					.attr("id", "tree-container")
					.attr("class", "container")
					.attr("transform", "translate(0,0)") # translates position of overall tree in svg container

				# Since new HTML has been added to the DOM, need to tell Angular to walk through it and identify new directives
				svgDOMObject = document.getElementById("tree-svg")
				$compile(svgDOMObject)($scope)
			else
				$scope.svg.selectAll("*").remove()

				# Somewhat hackish bullshit to update the height attribute of the SVG, since D3 doesn't like changing it
				dimTarget = angular.element($element.children()[0])
				dimTarget.attr("height",$scope.windowHeight)
				dimTarget.attr("width", $scope.windowWidth)

			# Since we're using svg.line() instead of diagonal(), the links must be wrapped in a helper function
			# Hashtag justd3things
			link = d3.svg.line()
				.x( (point) ->
					point.lx
				)
				.y( (point) ->
					point.ly
				)

			# Creates special lx, ly properties so svg.line() knows what to do
			# Don't ask me why #justd3things
			lineData = (d) ->
				points = [
					{lx: d.source.x, ly: d.source.y},
					{lx: d.target.x, ly: d.target.y}
				]

				link(points)

			# defs contains defined things that help prettify the tree
			# Things like arrowheads, gaussian blurs, stuff like that
			defs = $scope.svg.append("defs")

			# Define the arrow markers that will be added to the end vertex of each link path
			defs.append("marker")
				.attr("id", "arrowhead")
				.attr("refX", 10 + 20)
				.attr("refY", 5)
				.attr("markerWidth", 10)
				.attr("markerHeight", 10)
				.attr("orient", "auto")
				.append("path")
					.attr("d","M 0,0 L 0,10 L 10,5 Z")

			# Define gaussian blur outer glow that's applied to node circles
			filter = defs.append("filter")
				.attr("id", "dropshadow")
			filter.append("feGaussianBlur")
					.attr("in", "SourceGraphic")
					.attr("stdDeviation", 1)
					.attr("result", "blur")
			filter.append("feOffset")
					.attr("in", "blur")
					.attr("dx", 0)
					.attr("dy", 0)
					.attr("result", "offsetBlur")

			merge = filter.append("feMerge")
			merge.append("feMergeNode")
				.attr("in", "offsetBlur")
			merge.append("feMergeNode")
				.attr("in", "SourceGraphic")

			linkGroup = $scope.svg.selectAll("path.link")
				.data(links)
				.enter()
				.append("g")

			paths = linkGroup.append("svg:path")
				.attr("class", (d) ->
					if d.specialCase then return "special link"
					else return "link"
				)
				.attr("marker-end", "url(#arrowhead)")

			# Paths come in three flavors:
			# Standard, hierarchical links are straight, end-to-end paths from a parent node to a child
			# Special, non-hierarchical links are curves, so the math for the curve must be computed for each link
			# Also, the position of their associated bridge nodes must be updated to match the midpoint of the curve
			# Loopback paths don't really exist, they're just tiny paths extending out from the node so the endpoint arrow is positioned correctly
			# The actual path is a circle drawn on the link, set to display:none unless it's a loopback link
			angular.forEach paths[0], (path, index) ->

				path = d3.select path

				if links[index].specialCase and links[index].specialCase is "otherNode"

					path.attr("d", (d) ->
						dx = d.target.x - d.source.x
						dy = d.target.y - d.source.y
						dr = Math.sqrt(dx * dx + dy * dy)

						if d.sameTargetOffset then dr = dr + ((dr * 0.25) * d.sameTargetOffset)

						return "M" + d.source.x + "," + d.source.y + "A" + dr + "," + dr + " 0 0,1 " + d.target.x + "," + d.target.y
					)

					# Do some fancy math to find the midpoint of the curve once it's been computed
					# This must happen AFTER the path is generated for the link
					pathNode = path.node()
					midpoint = pathNode.getPointAtLength(pathNode.getTotalLength()/2)
					midX = midpoint.x
					midY = midpoint.y

					# Now find the associated bridge node using the bridgeNodeIndex flag on the given link
					# And update its X,Y coordinates for the new midpoint location
					nodeIndex = links[index].bridgeNodeIndex
					nodes[nodeIndex].x = midX
					nodes[nodeIndex].y = midY


				else if links[index].specialCase and links[index].specialCase is "loopBack"

					path.attr("d", (d) ->
						offsetX = d.source.x + 18
						offsetY = d.source.y - 5
						return "M" + offsetX + "," + offsetY + "L" + d.target.x + "," + d.target.y
					)


				# If it's just a standard link, this part is easy
				else path.attr("d", lineData)


			linkGroup.append("svg:circle")
				.attr("class","loopback")
				.attr("r", (d) ->
					# Increase the radius by a certain amount if there are multiple loopbacks
					if d.radiusOffset then 50 + d.radiusOffset * 5
					else return 50
				)
				.attr("transform", (d) ->

					xOffset = d.source.x + 40
					yOffset = d.source.y + 40

					# Increase the offset based on the increased radius of the circle for multiple loopbacks
					if d.radiusOffset
						xOffset += d.radiusOffset * 3
						yOffset += d.radiusOffset * 3

					"translate(#{xOffset},#{yOffset})"
				)
				.style("display", (d) ->
					if d.specialCase == "loopBack" then return null
					else return "none"
				)

			nodeGroup = $scope.svg.selectAll("g.node")
				.data(nodes)
				.enter()
				.append("svg:g")
				.attr("class", (d) ->
					if d.type is "bridge" then return "bridge"
					else if d.hasTemporaryFocus
						delete d.hasTemporaryFocus
						return "node focused #{d.type}"
					else if $scope.copyMode and d.type is "blank" then return "node copyMode #{d.type}"
					else return "node #{d.type}"
				)
				.on("mouseover", (d, i) ->

					$scope.onHover {data: d}

					#  Animation effects on node mouseover
					d3.select(this).select("circle")
					.transition()
					.attr("r", 30)
				)
				.on("mouseout", (d, i) ->

					# if d.type is "bridge" then return

					$scope.onHoverOut {data: d}

					# Animation effects on node mouseout
					d3.select(this).select("circle")
					.transition()
					.attr("r", 20)
				)
				.on("click", (d, i) ->
					$scope.nodeClick {data: d} # when clicked, we return all of the node's data
					d3.event.stopPropagation()
				)
				.attr("transform", (d) ->
					"translate(#{d.x},#{d.y})"
				)

			nodeGroup.append("svg:circle")
				.attr("class", "node-dot")
				.attr("r", (d) ->
					return 20 # sets size of node bubbles
				)
				.attr("filter", "url(#dropshadow)")

			# Icons displayed inside the node circles
			nodeGroup.append("svg:image")
				.attr("xlink:href", (d) ->
					switch d.type
						when "blank" then return "assets/creator-assets/blank.svg"
						when "mc" then return "assets/creator-assets/mc.svg"
						when "shortanswer" then return "assets/creator-assets/sa.svg"
						when "hotspot" then return "assets/creator-assets/hs.svg"
						when "narrative" then return "assets/creator-assets/narr.svg"
						when "end" then return "assets/creator-assets/end.svg"
						else return ""
				)
				.attr("x", "-18")
				.attr("y", "-18")
				.attr("width","36")
				.attr("height","36")

			# rect that sits behind the node label text to cover the icon art
			nodeGroup.append("svg:rect")
				.attr("width", (d) ->
					unless d.name then return 0

					# Couldn't find a better solution to the rect width than this
					# In the future, someone is welcome to clean this up
					# If someone is getting to node labels with more than 3-4 characters, odds are the've got some other problems too
					if d.name.length > 1 and d.name.length < 5 then return d.name.length * 12
					else if d.name.length >= 5 then return d.name.length * 8
					else return 20
				)
				.attr("height", 19)
				.attr("x", (d) ->
					unless d.name then return 0

					if d.name.length > 1 then return 8
					else return 11
				)
				.attr("y", 0)
				.attr("rx", 3)
				.attr("ry", 3)

			nodeGroup.append("svg:text")
				.attr("text-anchor", (d) ->
					return "start" # sets horizontal alignment of text anchor
					# if d.children then return "end"
					# else return "start"
				)
				.attr("dx", (d) ->
					if d.name
						if d.name.length > 1 then return 10 # -10
						else return 15 # -5
					else return 0
				)

				.attr("dy", 15) # sets Y label offset from node
				.attr("font-family", "Lato")
				.attr("font-size", 14)
				.text (d) ->
					d.name

			# The small warning graphic applied to nodes with validation problems
			warningSymbol = nodeGroup.append("svg:g")
				.attr("class", "warning-symbol")
				.attr("transform","translate(-30,5)")
			warningSymbol.append("polygon")
				.attr("points", "0.8,12.9 7.5,1.2 14.2,12.9")
			warningSymbol.append("polygon")
				.attr("class","exclamation")
				.attr("points","8.1,9.5 6.9,9.5 6.5,5.3 8.5,5.3")
			warningSymbol.append("rect")
				.attr("class","exclamation")
				.attr("x","6.6")
				.attr("y","10")
				.attr("width","1.8")
				.attr("height","1.6")

			warningSymbol.attr("display", (d) ->
				if d.hasProblem then return null
				else return "none"
			)

			# The "+" symbol displayed on bridge nodes (the pseudo-nodes between nodes you can click to add an in-between node)
			nodeGroup.append("path")
				.attr("d", "M -3,12 L -3,3 L -12,3 L -12,-3 L -3,-3 L -3,-12 L 3,-12 L 3,-3 L 12,-3 L 12,3 L 3,3 L 3,12 Z")
				.attr("visibility", (d) ->
					if d.type isnt "bridge" then return "hidden"
				)

			$scope.copyMode = false
			$rootScope.$broadcast "tree.nodes.changed.complete" # inform the tree-transform directive that the tree has been re-rendered

		# Handle resizing of the browser window
		window = angular.element($window)
		window.bind "resize", () ->
			$scope.windowWidth = document.getElementById("adventure-container").offsetWidth - 15
			$scope.windowHeight = document.getElementById("adventure-container").offsetHeight
			$scope.render treeSrv.get()

		# Kick off rendering the tree for the 1st time
		$scope.render treeSrv.get()

# Directive that handles all zoom & panning transforms of the tree visualization
# This directive is dynamically applied to the tree-svg element when it's generated by D3 and linked via the $compile function
Adventure.directive "treeTransforms", (treeSrv) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		# flag for whether or not dragging is allowed (when tree extends beyond window in any direction)
		$scope.dragFlag = false

		hasMoved = false # flag for whether the tree actually moved after a selectTree/moveTree/deselectTree event cycle

		originX = 0
		originY = 0

		# updated on mouseDown, used to compute max bounds for dragging
		currWidth = null
		currHeight = null

		# padding for max bounds. Max bounds is twice the width or height, minus this value.
		# prevents the tree from being dragged completely off-screen
		# padding is also affected by the current scale value
		maxBoundPadding = 50

		treeContainer = angular.element document.getElementById("tree-container")

		# When the tree is redrawn, check to see if it extends beyond the current window
		$scope.$on "tree.nodes.changed.complete", (evt) ->

			bounds = treeContainer[0].getBoundingClientRect()

			# Check to see if tree extends beyond the current window
			# Enable dragFlag if it is, updates cursor to move and allows for dragging
			if bounds.left < 0 or bounds.right > $scope.windowWidth or bounds.top < 65 or bounds.bottom > $scope.windowHeight
				unless $element.hasClass "draggable" then $element.addClass "draggable"
				$scope.dragFlag = true

			else
				if $element.hasClass "draggable" then $element.removeClass "draggable"
				$scope.dragFlag = false

		# Mousedown behavior for dragging
		$scope.selectTree = (evt) ->
			if evt.target is $element[0] and $scope.dragFlag
				$scope.offset.moving = true
				originX = evt.clientX
				originY = evt.clientY

				currWidth = treeContainer[0].getBoundingClientRect().width
				currHeight = treeContainer[0].getBoundingClientRect().height

		# Move the tree svg via a transform when the mouse is depressed and dragging conditions are met
		$scope.moveTree = (evt) ->
			if $scope.offset.moving

				dx = evt.clientX - originX
				dy = evt.clientY - originY

				$scope.offset.x += dx
				$scope.offset.y += dy

				originX = evt.clientX
				originY = evt.clientY

				# X offset exceeds max X bounds
				if $scope.offset.x >= (currWidth - (maxBoundPadding * $scope.offset.scale))
					$scope.offset.x = currWidth - (maxBoundPadding * $scope.offset.scale)

				# Y offset exceeds max Y bounds
				if $scope.offset.y >= (currHeight - (maxBoundPadding * $scope.offset.scale))
					$scope.offset.y = currHeight - (maxBoundPadding * $scope.offset.scale)

				# Y offset exceeds min Y bounds
				if $scope.offset.y <= (-currHeight + (maxBoundPadding * $scope.offset.scale))
					$scope.offset.y = -currHeight + (maxBoundPadding * $scope.offset.scale)

				# X offset exceeds min X bounds
				if $scope.offset.x <= (-currWidth + (maxBoundPadding * $scope.offset.scale))
					$scope.offset.x = (-currWidth + (maxBoundPadding * $scope.offset.scale))

				$scope.transformTree()

				hasMoved = true

				return false

		# Mouseup behavior to turn off dragging
		$scope.deselectTree = (evt) ->
			$scope.offset.moving = false
			if hasMoved
				$scope.$broadcast "tree.repositioned"
				hasMoved = false

		# updates the matrix transform with new offset (translation) values & scale values
		# translation combines the X/Y offsets from panning and adjustments made to center the SVG when scaled
		$scope.transformTree = () ->
			transform = "matrix(#{$scope.offset.scale} 0 0 #{$scope.offset.scale} #{($scope.offset.x + $scope.offset.scaleXOffset)} #{($scope.offset.y + $scope.offset.scaleYOffset)})"
			treeContainer.attr "transform", transform

		# Fancy math to scale the SVG tree and offset the transform-origin to the center of the window instead of top-left
		$scope.$on "tree.scaled", (evt) ->

			box = treeContainer[0].getBBox()

			centerX = ($scope.windowWidth / 2)
			centerY = ($scope.windowHeight / 2)

			translateX = -(centerX) * ($scope.offset.scale - 1)
			translateY = -(centerY) * ($scope.offset.scale - 1)

			$scope.offset.scaleXOffset = translateX
			$scope.offset.scaleYOffset = translateY

			$scope.transformTree()
			# Update the tree to get new bounds
			$scope.render treeSrv.get()

			$scope.$broadcast "tree.repositioned"

		# Focus the selected node in the center of the window
		$scope.$on "tree.nodeFocus", (evt) ->
			# Adjust offsets to center the node in the window
			$scope.offset.x = ($scope.offset.x * -1) + $scope.windowWidth/2
			$scope.offset.y = ($scope.offset.y * -1) + $scope.windowHeight/2
			$scope.transformTree()

		# Reset all transforms on the tree
		$scope.$on "tree.reset", (evt) ->

			$scope.offset.scale = 1
			$scope.offset.x = 0
			$scope.offset.y = 0
			$scope.offset.scaleXOffset = 0
			$scope.offset.scaleYOffset = 0

			$scope.transformTree()
			$scope.render treeSrv.get()


Adventure.directive "zoomButtons", ($rootScope) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.zoomTreeOut = () ->
			# set lower zoom limit
			if $scope.treeOffset.scale <= 0.2 then return false

			$scope.treeOffset.scale -= 0.1
			$rootScope.$broadcast "tree.scaled"

		$scope.zoomTreeIn = () ->
			# set upper zoom limit
			if $scope.treeOffset.scale >= 2 then return false

			$scope.treeOffset.scale += 0.1
			$rootScope.$broadcast "tree.scaled"

		$scope.resetZoom = () ->
			$rootScope.$broadcast "tree.reset"

# Self explanatory directive for editing the title
Adventure.directive "titleEditor", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "showTitleEditor", (newVal, oldVal) ->
			if newVal
				$scope.showBackgroundCover = true

# Directive for the small tooltips displaying the answers associated with a given node on mouseover
Adventure.directive "nodeTooltips", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		$scope.$watch "hoveredNode.target", (newVal, oldVal) ->
			if newVal isnt null

				# Update the position of the tooltip container
				# Crazy math is due to ensuring the dialog continues to position properly after panning and/or zooming the tree
				xOffset = ($scope.hoveredNode.x * $scope.treeOffset.scale) + $scope.treeOffset.x + $scope.treeOffset.scaleXOffset + (35 * $scope.treeOffset.scale)
				yOffset = ($scope.hoveredNode.y * $scope.treeOffset.scale) + ($scope.treeOffset.y - 5) + $scope.treeOffset.scaleYOffset
				styles = "left: " + xOffset + "px; top: " + yOffset + "px"
				$attrs.$set "style", styles

				node = treeSrv.findNode $scope.treeData, $scope.hoveredNode.target

				$scope.hoveredNode.tooltips = []

				angular.forEach node.answerLinks, (answer, index) ->
					$scope.hoveredNode.tooltips.push answer

				$scope.hoveredNode.showTooltips = true


# Directive for the node modal dialog (edit the node, copy the node, reset the node, etc)
Adventure.directive "nodeToolsDialog", (treeSrv, $rootScope, $timeout) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# Flags for displaying the reset node confirmation dialog
		hasChildrenFlag = false
		$scope.nodeTools.showResetWarning = false
		$scope.nodeTools.showDeleteWarning = false
		$scope.nodeTools.showConvertDialog = false

		# Helper vars for copying node/child trees, stored up here for scope reasons
		sourceTree = null
		copyTree = null
		targetNode = null

		# When target for the dialog changes, update the position values based on where the new node is
		$scope.$watch "nodeTools.target", (newVals, oldVals) ->
			updatePosition()

			# Reset the visibility of the warning flag
			$scope.nodeTools.showResetWarning = false
			$scope.nodeTools.showDeleteWarning = false
			$scope.nodeTools.showConvertDialog = false

		# update positioning whenever a dialog state changes
		$scope.$watch "nodeTools.showResetWarning", (newVal, oldVal) ->
				$scope.nodeTools.showDeleteWarning = false
				$scope.nodeTools.showConvertDialog = false
				updatePosition()

		$scope.$watch "nodeTools.showDeleteWarning", (newVal, oldVal) ->
				$scope.nodeTools.showResetWarning = false
				$scope.nodeTools.showConvertDialog = false
				updatePosition()

		$scope.$watch "nodeTools.showConvertDialog", (newVal, oldVal) ->
				$scope.nodeTools.showResetWarning = false
				$scope.nodeTools.showDeleteWarning = false
				updatePosition()

		# nodeTools is repositioned fairly often due to changes in size (confirm/warning dialogs) & node repositioning
		# note that the values here are static; I suspect there's an easier way of approaching the positioning logic,
		# especially for repositioning due to resizing events
		updatePosition = ->
			# Crazy math is due to ensuring the dialog continues to position properly after panning and/or zooming the tree
			xOffset = ($scope.nodeTools.x * $scope.treeOffset.scale) + $scope.treeOffset.x + $scope.treeOffset.scaleXOffset
			yOffset = ($scope.nodeTools.y * $scope.treeOffset.scale) + $scope.treeOffset.y + $scope.treeOffset.scaleYOffset

			# Can't rely on computed height of the element at the time this is called, so we have to set bounding box manually
			xBound = xOffset + 200
			yBound = yOffset + 127

			# Adjust expected height of the bounds based on which dialog is open
			if $scope.nodeTools.type isnt $scope.BLANK then yBound += 23

			if $scope.nodeTools.showResetWarning then yBound += 128
			else if $scope.nodeTools.showDeleteWarning then yBound += 143
			else if $scope.nodeTools.showConvertDialog then yBound += 141

			container = document.getElementById("tree-svg").getBoundingClientRect()

			# Check for overflow
			if yBound > container.height
				diffY = yBound - container.height + 35
				yOffset -= diffY

			if xBound > container.width
				diffX = (xBound - container.width) + 35
				xOffset -= diffX

			styles = "left: " + xOffset + "px; top: " + yOffset + "px"
			$attrs.$set "style", styles

		# update nodeTools after tree reposition events
		$scope.$on "tree.repositioned", (evt) ->
			updatePosition()

		$scope.copyNode = () ->

			# Turn on copy mode and broadcast the change so the tree re-renders with copy mode enabled
			# Causes blank nodes to be highlighted so user can select a target to copy to
			$scope.copyNodeMode = true
			$scope.nodeTools.show = false

			$rootScope.$broadcast "mode.copy"

			$scope.toast "Select a blank node to copy this node to.", false

			# Listen for the event associated with the user selecting a node to copy to
			# copyNodeTarget is updated from the nodeSelected method in the controller
			deregister = $scope.$watch "copyNodeTarget", (newVal, oldVal) ->

				$scope.hideToast()

				if newVal
					# Don't copy to the same node, or a not-blank node
					if newVal.type isnt $scope.BLANK or newVal.id is $scope.nodeTools.target
						$scope.toast "Target destination should be blank!"

					else
						# First, grab node to be copied
						sourceTree = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

						# Make a deep copy of this tree that will be altered with values to be copied
						copyTree = angular.copy sourceTree

						# Copy data of nodeTools target to copy target (targetNode is node to be replaced)
						targetNode = treeSrv.findNode $scope.treeData, newVal.id

						# Recursively generate the copied tree
						$scope.recursiveCopy copyTree

						# Update the original tree target with the copy
						result = treeSrv.findAndReplace $scope.treeData, targetNode.id, copyTree

					deregister()

					# Update the tree
					treeSrv.set $scope.treeData

					# Reset all values
					$scope.copyNodeTarget = null
					sourceTree = null
					copyTree = null
					targetNode = null

		# Recursively copies the selected node & child nodes, updating ids, names, parent ids, and answer targets as needed
		# The root node (the actual node being copied/replaced) retains the target node's tree position properties and id, name, and parent id.
		# For all child nodes, new ids and names must be generated, and the parent ids updated with new parent ids
		# The answer targets must be updated with the new ids as well
		$scope.recursiveCopy = (copy, parentId = null) ->

			# If it's the root node, the tree position properties and identity properties remain
			if copy.id is sourceTree.id

				angular.forEach targetNode, (val, key) ->

					switch key
						when "id", "name", "parentId", "depth", "x", "y"
							copy[key] = val
						when "children"
							delete copy[key]

			# Otherwise, if it's a child node, we have to generate new identity properties and link it to the updated parent id
			# tree position properties are removed and re-generated when the tree is re-rendered
			else

				angular.forEach copy, (val, key) ->

					switch key
						when "id"

							copy.formerId = copy.id
							copy.id = treeSrv.getNodeCount()
							treeSrv.incrementNodeCount()

							# If the name attribute has already been passed over, need to go back & update it based on new id
							if copy.updatedName
								copy.name = copy.name = treeSrv.integerToLetters copy.id
								delete copy.updatedName
							# otherwise, leave a flag so it gets updated properly later
							else copy.updatedId = true

						when "name"

							# If flag is set that ID is updated, go ahead and update the name
							if copy.updatedId
								copy.name = treeSrv.integerToLetters copy.id
								delete copy.updatedId
							# Otherwise, leave a flag so it gets updated when the ID is updated
							else copy.updatedName = true

							# copy.name = treeSrv.integerToLetters copy.id
						when "parentId"
							copy.parentId = parentId
						when "depth", "x", "y", "children"
							delete copy[key]

				# Now, grab the parent's node so we can update its associated answer to point to the updated node
				parentNode = treeSrv.findNode copyTree, parentId

				if parentNode.pendingTarget then parentNode.pendingTarget = copy.id

				angular.forEach parentNode.answers, (answer, index) ->
					if answer.target is copy.formerId
						answer.target = copy.id
						delete copy.formerId


			if copy.contents.length is 0 then return

			i = 0

			while i < copy.contents.length

				$scope.recursiveCopy copy.contents[i], copy.id
				i++

			return copy

		# Check to see if the node being reset has any children that aren't blank
		# If so, we should warn the user that resetting the node will delete those children and their children etc
		$scope.resetNodePreCheck = () ->
			hasChildrenFlag = false

			node = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			angular.forEach node.contents, (child, index) ->
				if child.contents.length > 0
					hasChildrenFlag = true
					$scope.nodeTools.showResetWarning = true

			unless hasChildrenFlag then $scope.resetNode()

		# Resetting the node wipes QSet-related data clean, but retains the tree properties relevant to D3
		# The node is returned to a blank node type with no children
		$scope.resetNode = () ->

			target = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			# Remove each answer target
			angular.forEach target.answers, (answer, index) ->
				removed = treeSrv.findAndRemove $scope.treeData, answer.target

				# Recurse through all deleted IDs & fix answer targets for each deleted node
				for id in removed
					treeSrv.findAndFixAnswerTargets $scope.treeData, id

			# Remove all properties of the node except those whitelisted below
			angular.forEach target, (val, key) ->
				switch key
					when "id", "name", "parentId", "x", "y", "depth", "type"
						# do nothing
					else
						delete target[key]

			target.type = $scope.BLANK
			target.contents = []

			# Set the editedNode to an empty object to ensure references to questions & answers aren't retained
			if $scope.editedNode and $scope.editedNode.id is $scope.nodeTools.target
				$scope.editedNode = {}

			# Go ahead and actually replace the existing node on the tree with the blank version
			treeSrv.findAndReplace $scope.treeData, target.id, target
			treeSrv.set $scope.treeData

			$scope.toast "Destination " + target.name + " has been reset."

			$scope.nodeTools.showResetWarning = false
			$scope.nodeTools.show = false
			$scope.nodeTools.target = null

		# Delete the node, and the associated parent's answer
		# Don't delete the node if it's a) a child of a narrative node or b) the associated node of a short answer's unmatched responses
		# Stores the deleted node as a coldStorage object in case the user wants to undo the action
		$scope.deleteNode = () ->

			target = treeSrv.findNode $scope.treeData, $scope.nodeTools.target
			parent = treeSrv.findNode $scope.treeData, target.parentId
			targetAnswerIndex = null
			targetIndexInParent = null

			# Don't delete if it's a child of a narrative node
			if parent.type is $scope.NARR
				$scope.toast "Can't delete Destination " + target.name + "! Try linking " + parent.name + " to an existing destination instead."
				$scope.nodeTools.showDeleteWarning = false
				return

			# Find reference to node in parent's answers
			angular.forEach parent.answers, (answer, index) ->
				if answer.target is target.id and answer.linkMode is $scope.NEW
					targetAnswerIndex = index

			if targetAnswerIndex isnt null

				# Don't delete if it's referenced from an [Unmatched Response] answer of a short answer question.
				if parent.answers[targetAnswerIndex].isDefault and parent.type is $scope.SHORTANS
					$scope.toast "Can't delete Destination " + target.name + "! Unmatched responses need to go somewhere!"
					$scope.nodeTools.showDeleteWarning = false
					return

			# Prep node as a coldStorage object
			coldStorage =
				id: target.id
				answerIndex: targetAnswerIndex
				answer: parent.answers[targetAnswerIndex]
				node: target
				nodeIndex: parent.contents.indexOf target # node index may differ from answer index due to answers with non-traditional links

			# The deletedCache array holds answer/node pairs that have been removed and can be recovered later
			unless parent.deletedCache then parent.deletedCache = []
			parent.deletedCache.push coldStorage

			# Remove the node & grab array of IDs representing deleted node & its children
			removed = treeSrv.findAndRemove $scope.treeData, target.id

			# Recurse through all deleted IDs & fix answer targets for each deleted node
			for id in removed
				treeSrv.findAndFixAnswerTargets $scope.treeData, id

			treeSrv.set $scope.treeData

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

			# Display the interactive toast that provides the Undo option
			# Toast is displayed until clicked or until the node creation screen is closed
			$scope.interactiveToast "Destination " + $scope.integerToLetters(target.id) + " was deleted.", "Undo", ->
				$scope.restoreDeletedNode target.id, parent

			# Cancel out the toast after 8 seconds, enough time for someone to decide they made a mistake hopefully
			$timeout (() ->
				$scope.hideToast()
			), 8000

			$scope.nodeTools.showDeleteWarning = false
			$scope.nodeTools.show = false
			$scope.nodeTools.target = null

			$scope.hoveredNode.showTooltips = false
			$scope.hoveredNode.target = null

		$scope.convertNode = (type) ->

			node = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			# Remove properties related to the former node type
			switch $scope.nodeTools.type
				when $scope.SHORTANS
					angular.forEach node.answers, (answer, index) ->
						delete answer.matches
						if answer.isDefault then delete answer.isDefault

				when $scope.HOTSPOT
					delete node.hotspotVisibility
					angular.forEach node.answers, (answer, index) ->
						delete answer.svg

				when $scope.END
					delete node.finalScore

					newAnswerTarget = $scope.addNode $scope.nodeTools.target, $scope.BLANK

					newAnswer =
						id: treeSrv.generateAnswerHash()
						text: null
						feedback: null
						target: newAnswerTarget
						linkMode: $scope.NEW

					node.answers = []
					node.answers.push newAnswer

				when $scope.NARR
					node.contents = []
					delete node.children
					delete node.answers

					treeSrv.set $scope.treeData

			# Buncha bullshit required to add the default [Unmatched Response] required for shortans
			if type is $scope.SHORTANS

				# Add special matches property for each answer
				angular.forEach node.answers, (answer, index) ->
					answer.text = null
					answer.matches = []

				# Create the new node associated with the [Unmatched Response] answer
				newDefaultId = $scope.addNode $scope.nodeTools.target, $scope.BLANK

				newDefault =
					id: treeSrv.generateAnswerHash()
					text: "[Unmatched Response]"
					feedback: null
					target: newDefaultId
					linkMode: $scope.NEW
					matches: []
					isDefault: true

				# The new answer has to take the 0 index spot in the answers array
				node.answers.splice 0, 0, newDefault

				# Move the newly created node for the default answer to the 0 index spot of the content array
				orphanIndex = node.contents.length - 1
				orphan = node.contents.splice(orphanIndex, 1)[0]
				node.contents.splice 0, 0, orphan

			# Update the node type
			node.type = type

			$scope.nodeTools.showConvertDialog = false
			treeSrv.set $scope.treeData

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

# The "What kind of node do you want to create?" dialog
Adventure.directive "nodeCreationSelectionDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		$scope.showDialog = false

		$scope.editNode = () ->
			# We need the target's node type, so grab it
			targetId = $scope.nodeTools.target
			target = treeSrv.findNode $scope.treeData, targetId

			# if node is blank, launch the node type selection. Otherwise, go right to the editor for that type
			if target.type isnt $scope.BLANK
				$scope.displayNodeCreation = target.type
			else
				$scope.showCreationDialog = true

			$scope.showBackgroundCover = true

# Dialog for selecting what kind of node a given answer should target
# e.g., "new", "existing", "self"
Adventure.directive "newNodeManagerDialog", (treeSrv, $document) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# Watch the newNodeManager target and kick off associated logic when it updates
		# Similar in functionality to the nodeTools dialog
		$scope.$watch "newNodeManager.answerId", (newVal, oldVal) ->
			if newVal isnt null
				$scope.newNodeManager.show = true

				xOffset = $scope.newNodeManager.x - 205
				yOffset = $scope.newNodeManager.y

				yBound = yOffset + 150

				container = document.getElementById("tree-svg").getBoundingClientRect()

				if yBound > container.height
					diffY = yBound - container.height + 10
					yOffset -= diffY

				styles =  "left: " + xOffset + "px; top: " + yOffset + "px"

				$attrs.$set "style", styles

		$scope.selectLinkMode = (mode) ->

			answer = {}

			# Grab the answer object that corresponds with the nodeManager's current target
			i = 0
			while i < $scope.answers.length
				if $scope.answers[i].id is $scope.newNodeManager.answerId then break
				else i++

			# Compare the prior link mode to the new one and deal with the changes
			switch mode
				when "new"

					if $scope.newNodeManager.linkMode is $scope.NEW
						$scope.newNodeManager.target = null
						$scope.newNodeManager.answerId = null
						$scope.newNodeManager.show = false
						return

					## HANDLE PRIOR LINK MODE: SELF
					if $scope.answers[i].linkMode is $scope.SELF

						numSelfLinks = 0

						for answer in $scope.answers
							if answer.linkMode is $scope.SELF then numSelfLinks++

						if $scope.editedNode.hasLinkToSelf and numSelfLinks is 1 then delete $scope.editedNode.hasLinkToSelf

					## HANDLE PRIOR LINK MODE: EXISTING
					else if $scope.answers[i].linkMode is $scope.EXISTING

						numExistingNodeLinks = 0

						for answer in $scope.answers
							if answer.linkMode is $scope.EXISTING then numExistingNodeLinks++

						if $scope.editedNode.hasLinkToOther and numExistingNodeLinks is 1 then delete $scope.editedNode.hasLinkToOther

					# Set updated linkMode flags
					$scope.newNodeManager.linkMode = $scope.NEW
					$scope.answers[i].linkMode = $scope.NEW

					# Create new node and update the answer's target
					targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK
					$scope.answers[i].target = targetId

					$scope.newNodeManager.target = null
					$scope.newNodeManager.answerId = null

					# Refresh all answerLinks references as some have changed
					treeSrv.updateAllAnswerLinks $scope.treeData

				when "existing"

					# Suspend the node creation screen so the user can select an existing node
					$scope.showBackgroundCover = false
					$scope.nodeTools.show = false
					$scope.displayNodeCreation = "suspended"

					# Set the node selection mode so click events are handled differently than normal
					$scope.existingNodeSelectionMode = true

					# Provide interactive toast to cancel the existing link selection mode
					$scope.interactiveToast "Select the destination this answer should link to.", "Cancel", ->
						$scope.existingNodeSelectionMode = false
						$scope.newNodeManager.target = null
						$scope.newNodeManager.answerId = null
						$scope.displayNodeCreation = $scope.editedNode.type
						$scope.showBackgroundCover = true

					# All tasks are on hold until the user selects a node to link to
					# Wait for the node to be selected
					deregister = $scope.$watch "existingNodeSelected", (newVal, oldVal) ->

						if newVal

							$scope.hideToast()

							# If selected node is itself, switch link mode to SELF
							if newVal.id is $scope.editedNode.id
								deregister()
								return $scope.selectLinkMode $scope.SELF

							# Slap the user on the hand if they try to link to the same node
							if newVal.id is $scope.answers[i].target
								$scope.toast "That's already the target destination for this answer!"
								$scope.existingNodeSelectionMode = true
								return

							# Set the answer's new target to the newly selected node
							$scope.answers[i].target = newVal.id

							## HANDLE PRIOR LINK MODE: NEW
							if $scope.answers[i].linkMode is $scope.NEW

								# Scrub the existing child node associated with this answer
								childNode = treeSrv.findNode $scope.treeData, $scope.newNodeManager.target
								if childNode
									removed = treeSrv.findAndRemove $scope.treeData, childNode.id
									# Recurse through all deleted IDs & fix answer targets for each deleted node
									for id in removed
										treeSrv.findAndFixAnswerTargets $scope.treeData, id

							## HANDLE PRIOR LINK MODE: SELF
							if $scope.answers[i].linkMode is $scope.SELF

								numSelfLinks = 0

								for answer in $scope.answers
									if answer.linkMode is $scope.SELF then numSelfLinks++

								if $scope.editedNode.hasLinkToSelf and numSelfLinks is 1 then delete $scope.editedNode.hasLinkToSelf

							# Set updated linkMode flags and redraw tree
							$scope.editedNode.hasLinkToOther = true
							$scope.answers[i].linkMode = $scope.EXISTING

							treeSrv.set $scope.treeData

							# Deregister the watch listener now that it's not needed
							deregister()

							# Cancel out the answer tooltip, or it persists
							$scope.hoveredNode.showTooltips = false
							$scope.hoveredNode.target = null
							# $scope.hoveredNode.targetParent = null

							$scope.existingNodeSelected = null
							$scope.newNodeManager.target = null
							$scope.newNodeManager.answerId = null
							$scope.displayNodeCreation = "none" # displayNodeCreation should be updated from "suspended"

							# Refresh all answerLinks references as some have changed
							treeSrv.updateAllAnswerLinks $scope.treeData


				when "self"

					if $scope.newNodeManager.linkMode is $scope.SELF
						$scope.newNodeManager.target = null
						$scope.newNodeManager.answerId = null
						$scope.newNodeManager.show = false
						return

					# Set answer row's target to the node being edited
					$scope.answers[i].target = $scope.editedNode.id

					## HANDLE PRIOR LINK MODE: NEW
					if $scope.answers[i].linkMode is $scope.NEW

						# Scrub the existing child node associated with this answer
						childNode = treeSrv.findNode $scope.treeData, $scope.newNodeManager.target
						removed = treeSrv.findAndRemove $scope.treeData, childNode.id

						# Recurse through all deleted IDs & fix answer targets for each deleted node
						for id in removed
							treeSrv.findAndFixAnswerTargets $scope.treeData, id

					## HANDLE PRIOR LINK MODE: EXISTING
					else if $scope.answers[i].linkMode is $scope.EXISTING

						numExistingNodeLinks = 0

						for answer in $scope.answers
							if answer.linkMode is $scope.EXISTING then numExistingNodeLinks++

						if $scope.editedNode.hasLinkToOther and numExistingNodeLinks is 1 then delete $scope.editedNode.hasLinkToOther

					# Set updated linkMode flags and redraw the tree
					$scope.editedNode.hasLinkToSelf = true
					$scope.answers[i].linkMode = $scope.SELF

					treeSrv.set $scope.treeData

					$scope.newNodeManager.linkMode = $scope.SELF

					$scope.newNodeManager.target = null
					$scope.newNodeManager.answerId = null

					# Refresh all answerLinks references as some have changed
					treeSrv.updateAllAnswerLinks $scope.treeData


			$scope.newNodeManager.show = false

# Dialog for warning that, oh shit, you're going to delete some child nodes if you decide to do this
Adventure.directive "deleteWarningDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "deleteDialog.target", (newVal, oldVal) ->

			if newVal
				offsetX = $scope.deleteDialog.x + 30
				offsetY = $scope.deleteDialog.y - 3

				xBound = offsetX + 300
				yBound = offsetY + 188

				container = document.getElementById("tree-svg").getBoundingClientRect()

				if yBound > container.height
					diffY = yBound - container.height - 35
					offsetY -= diffY

				if xBound > container.width
					diffX = (xBound - container.width) + 35
					offsetX -= diffX

				styles = "left: " + offsetX + "px; top: " + offsetY + "px"
				$attrs.$set "style", styles

		$scope.dropNodeAndChildren = ->

			$scope.removeAnswer $scope.deleteDialog.targetIndex, $scope.deleteDialog.target

			$scope.deleteDialog.show = false
			$scope.deleteDialog.target = null

		$scope.cancelDeleteDialog = ->
			$scope.deleteDialog.show = false
			$scope.deleteDialog.target = null

# The actual node creation screen
# Functions related to features unique to individual node types (Short answer sets, hotspots, etc) are relegated to their own directives
# The ones here are "universal" and apply to all new nodes
Adventure.directive "nodeCreation", (treeSrv, legacyQsetSrv, $rootScope, $timeout) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$on "editedNode.target.changed", (evt) ->

			if $scope.editedNode
				# Initialize the node edit screen with the node's info. If info doesn't exist yet, init properties
				if $scope.editedNode.question then $scope.question = $scope.editedNode.question
				else $scope.question = null

				if $scope.editedNode.answers then $scope.answers = $scope.editedNode.answers
				else
					switch $scope.editedNode.type
						when $scope.HOTSPOT
							$scope.answers = []
							treeSrv.set $scope.treeData # Manually redraw tree to reflect status change as hotspot node

						when $scope.END
							treeSrv.set $scope.treeData # Manually redraw tree to reflect status change as end type node

						when $scope.SHORTANS
							$scope.answers = []

							# Create answer to pair with the "Unmatched Answers" option
							$scope.newAnswer "[Unmatched Response]"
							$scope.answers[0].isDefault = true

							# Now create the first empty answer set
							$scope.newAnswer()

						else
							$scope.answers = []
							$scope.newAnswer()

				if $scope.editedNode.media
					$scope.image = new Image()
					$scope.image.src = $scope.editedNode.media.url
					$scope.mediaReady = true
					$scope.image.onload = ->
						# If the QSet is an old one, have to apply scaling to the hotspot only after the image is loaded
						# This is due to the old hotspot coordinate system relying on the hotspot's original image dimensions
						# Once the scaling is done, the flag is removed so the hotspot is "normal" from that point on
						if $scope.editedNode.type is $scope.HOTSPOT and $scope.editedNode.legacyScaleMode
							legacyQsetSrv.handleLegacyScale $scope.answers, $scope.image
							delete $scope.editedNode.legacyScaleMode
							$scope.$apply()

				else $scope.mediaReady = false

				if $scope.editedNode.type is $scope.MC
					unless $scope.editedNode.randomizeAnswers then $scope.editedNode.randomizeAnswers = false

				if $scope.editedNode.type is $scope.HOTSPOT
					unless $scope.editedNode.hotspotVisibility then $scope.editedNode.hotspotVisibility = "always"


				if $scope.editedNode.type is $scope.END

					if typeof $scope.editedNode.finalScore is 'undefined'
						$scope.finalScore = 100
					else
						$scope.finalScore = $scope.editedNode.finalScore

			# Update question placeholder text based on the node creation type.
			# TODO should this be included in the DOM instead through ng-if or a conditional in the attribute?
			if $scope.editedNode.type is $scope.MC or $scope.editedNode.type is $scope.SHORTANS
				$scope.questionPlaceholder = "Enter question here."
			else if $scope.editedNode.type is $scope.HOTSPOT
				$scope.questionPlaceholder = "Enter an optional question here."
			else if $scope.editedNode.type is $scope.NARR
				$scope.questionPlaceholder = "Enter some narrative text here."
			else if $scope.editedNode.type is $scope.END
				$scope.questionPlaceholder = "Enter a conclusion here for this decision tree or path."


		# Update the node's properties when the associated input models change
		$scope.$watch "question", (newVal, oldVal) ->
			if newVal isnt null and $scope.editedNode
				$scope.editedNode.question = newVal

		$scope.$watch "answers", ((newVal, oldVal) ->
			if newVal isnt null and $scope.editedNode
				$scope.editedNode.answers = $scope.answers
		), true

		# Since media isn't bound to a model like answers and questions, listen for update broadcasts
		$scope.$on "editedNode.media.updated", (evt) ->
				$scope.image = new Image()
				$scope.image.src = $scope.editedNode.media.url
				$scope.image.onload = ->

					# Handle legacyScaleMode if it's a hotspot
					if $scope.editedNode.type is $scope.HOTSPOT and $scope.editedNode.legacyScaleMode
						legacyQsetSrv.handleLegacyScale $scope.answers, $scope.image
						delete $scope.editedNode.legacyScaleMode

					$scope.$apply ->
						$scope.mediaReady = true

		$scope.newAnswer = (text = null) ->

			# If the editedNode has a pending target, the new answer's target will be set to it
			# pendingTarget is used for adding in-between nodes or linking orphaned nodes
			if $scope.editedNode.pendingTarget
				targetId = $scope.editedNode.pendingTarget

				if $scope.editedNode.hasLinkToOther then linkMode = $scope.EXISTING
				else linkMode = $scope.NEW

				delete $scope.editedNode.pendingTarget

				# manually redraw the tree, since the newly created node won't be updated otherwise
				# Have to call this in a $timeout to wait for $scope.answers' $watch cycle to complete
				$timeout ->
					treeSrv.set $scope.treeData
			else
				# We create the new node first, so we can grab the new node's generated id
				targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK
				linkMode = $scope.NEW

			newAnswer =
				text: text
				feedback: null
				target: targetId
				linkMode: linkMode
				id: treeSrv.generateAnswerHash()

			# Add a matches property to the answer object if it's a short answer question.
			if $scope.editedNode.type is $scope.SHORTANS
				newAnswer.matches = []
			$scope.answers.push newAnswer

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

			# Inform the answers-container auto-scroll-and-focus directive that a new answer is added
			$rootScope.$broadcast "editedNode.answers.added"


		# Check to see if removing this answer will delete any child nodes of the selected answer's node
		# If there are child nodes present, bring up the warning dialog
		# Otherwise, go ahead and remove the answer (and associated node, if applicable)
		$scope.removeAnswerPreCheck = (index, evt) ->

			# Grab node id of answer node to be removed
			targetId = $scope.answers[index].target

			targetNode = treeSrv.findNode $scope.treeData, targetId

			if targetNode.contents.length > 0 and $scope.answers[index].linkMode is $scope.NEW
				$scope.deleteDialog.x = evt.currentTarget.getBoundingClientRect().left
				$scope.deleteDialog.y = evt.currentTarget.getBoundingClientRect().top
				$scope.deleteDialog.targetIndex = index
				$scope.deleteDialog.target = targetId # necessary?
				$scope.deleteDialog.show = true
			else
				$scope.removeAnswer index, targetId


		$scope.removeAnswer = (index, targetId) ->

			# hold onto the answer's unique id
			answerId = $scope.answers[index].id

			# Remove the answer's associated node if it's an actual child of the parent
			if $scope.answers[index].linkMode is $scope.NEW

				# Grab the node associated with the answer being removed and prep it for cold storage
				removedNode = treeSrv.findNode $scope.treeData, targetId
				coldStorage =
					id: targetId
					answerIndex: index
					answer: $scope.answers[index]
					node: removedNode
					nodeIndex: $scope.editedNode.contents.indexOf removedNode # node index may differ from answer index due to answers with non-traditional links

				# The deletedCache array holds answer/node pairs that have been removed and can be recovered later
				unless $scope.editedNode.deletedCache then $scope.editedNode.deletedCache = []
				$scope.editedNode.deletedCache.push coldStorage

				# Go ahead and actually remove the node
				removed = treeSrv.findAndRemove $scope.treeData, targetId

				# Recurse through all deleted IDs & fix answer targets for each deleted node
				for id in removed
					treeSrv.findAndFixAnswerTargets $scope.treeData, id

				# Display the interactive toast that provides the Undo option
				# Toast is displayed until clicked or until the node creation screen is closed
				$scope.interactiveToast "Destination " + $scope.integerToLetters(targetId) + " was deleted.", "Undo", ->
					$scope.restoreDeletedNode targetId, $scope.editedNode
			else
				# Just remove it from answers array, no further action required
				$scope.answers.splice index, 1

			# Update tree to reflect new state
			treeSrv.set $scope.treeData

			# If the node manager modal is open for this answer, close it
			if answerId is $scope.newNodeManager.answerId
				$scope.newNodeManager.show = false
				$scope.newNodeManager.target = null
				$scope.newNodeManager.answerId = null

			# If it's a hotspot, let the manager know it's time to reset and close
			# (Since the manager is defined in another directive, it needs to be broadcast)
			if $scope.editedNode.type is $scope.HOTSPOT
				$rootScope.$broadcast "editedNode.hotspotAnswerManager.reset"

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData


		$scope.manageNewNode = ($event, target, id, mode) ->

			if $scope.newNodeManager.show is true
				$scope.newNodeManager.show = false
				$scope.newNodeManager.target = null
				$scope.newNodeManager.answerId = null
			else
				$scope.newNodeManager.x = $event.currentTarget.getBoundingClientRect().left
				$scope.newNodeManager.y = $event.currentTarget.getBoundingClientRect().top
				$scope.newNodeManager.linkMode = mode
				$scope.newNodeManager.target = target
				$scope.newNodeManager.answerId = id

		$scope.beginMediaImport = () ->
			Materia.CreatorCore.showMediaImporter()

		$scope.removeMedia = ->
			$scope.mediaReady = false
			$scope.image = null
			delete $scope.editedNode.media

		$scope.changeMedia = ->
			$scope.beginMediaImport()

		$scope.swapMediaAndQuestion = ->
			switch $scope.editedNode.media.align
				when "left" then $scope.editedNode.media.align = "right"
				when "right" then $scope.editedNode.media.align = "left"
				when "top" then $scope.editedNode.media.align = "bottom"
				when "bottom" then $scope.editedNode.media.align = "top"

		$scope.swapMediaOrientation = ->
			if $scope.editedNode.media.align is "left" or $scope.editedNode.media.align is "right" then $scope.editedNode.media.align = "top"
			else $scope.editedNode.media.align = "right"

		$scope.saveAndClose = ->
			$scope.hideCoverAndModals()
			# auto-hide set to false here because the timer in the displayNodeCreation $watch will handle it
			$scope.toast "Destination " + $scope.editedNode.name + " saved!", false

# Directive for each short answer set. Contains logic for adding and removing individual answer matches.
Adventure.directive "shortAnswerSet", (treeSrv) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.addAnswerMatch = (index) ->

			# Don't do anything if there isn't anything actually submitted
			unless $scope.newMatch.length then return

			# first check to see if the entry already exists
			i = 0

			while i < $scope.answers.length

				j = 0

				while j < $scope.answers[i].matches.length

					matchTo = $scope.answers[i].matches[j].toLowerCase()

					if matchTo.localeCompare($scope.newMatch.toLowerCase()) is 0
						$scope.toast "This match already exists!"
						return

					j++

				i++

			# If we're all clear, go ahead and add it
			$scope.answers[index].matches.push $scope.newMatch
			$scope.answers[index].text = $scope.answers[index].matches.join ", "
			$scope.newMatch = ""

		$scope.removeAnswerMatch = (matchIndex, answerIndex) ->

			$scope.answers[answerIndex].matches.splice matchIndex, 1

Adventure.directive "finalScoreBox", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "finalScore", (newVal, oldVal) ->
			if $scope.finalScoreForm.finalScoreInput.$valid
				$scope.editedNode.finalScore = newVal

Adventure.directive "hotspotManager", (legacyQsetSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.ALWAYS = "always"
		$scope.MOUSEOVER = "mouseover"
		$scope.NEVER = "never"

		# Default X,Y coords of SVGs when they're added. Represents the center of the image.
		$scope.DEFAULTX = 349
		$scope.DEFAULTY = 200

		# The selectedSVG object holds the temporary properties of the selected SVG hotspot
		# Works in a similar way to the nodeTools and nodeManager objects
		# Attempts to nest these properties inside an svg-specific directive were unsuccessful
		$scope.selectedSVG =
			target: null
			selected: false
			hasMoved: false # determines whether or not to display the manager screen when a mouseup occurs
			originX: null
			originY: null
			matrix: null

		# Holds temporary properties of selected SVG scale tool
		$scope.selectedSVGScale =
			target: null
			selected: false
			originX: null
			originY: null

		# Holds properties for the hotspot answer manager, the small modal for configuring a hotspot
		$scope.hotspotAnswerManager =
			show: false
			target: null
			answerIndex: null
			x: null
			y: null

		$scope.visibilityManagerOpen = false

		$scope.selectSVG = (evt) ->

			# Update selectedSVG property with necessary event information
			$scope.selectedSVG.selected = true
			$scope.selectedSVG.target = angular.element(evt.target).parent() # wrap event target in jqLite (targets g node, parent of svg)
			$scope.selectedSVG.originX = evt.clientX
			$scope.selectedSVG.originY = evt.clientY

		# If SVG is deselected (or mouse moves away from SVG), clear the object
		$scope.deselectSVG = (evt) ->

			$scope.selectedSVG =
			target: null
			selected: false
			hasMoved : $scope.selectedSVG.hasMoved # carry hasMoved value over, since the click event needs to know what it is
			originX: null
			originY: null

		# Update selected SVG's position information as it moves based on cursor position
		$scope.moveSVG = (index, evt) ->
			if $scope.selectedSVG.selected is true
				$scope.selectedSVG.hasMoved = true

				dx = evt.clientX - $scope.selectedSVG.originX
				dy = evt.clientY - $scope.selectedSVG.originY

				$scope.answers[index].svg.x += dx
				$scope.answers[index].svg.y += dy

				$scope.selectedSVG.originX = evt.clientX
				$scope.selectedSVG.originY = evt.clientY

		# If the scale tool of a given SVG hotspot is selected, have to handle it similarly
		$scope.startSVGScale = (evt) ->

			$scope.selectedSVGScale.selected = true
			$scope.selectedSVGScale.target = angular.element evt.target
			$scope.selectedSVGScale.originX = evt.clientX
			$scope.selectedSVGScale.originY = evt.clientY

		# Scale tool deselected
		$scope.endSVGScale = (evt) ->

			$scope.selectedSVGScale =
				target: null
				selected: false
				originX: null
				originY: null

		# Change X & Y scale factors of given SVG hotspot based on changes in mouse movement
		# Only while the associated scale tool is selected, of course
		$scope.scaleSVG = (index, evt) ->
			if $scope.selectedSVGScale.selected is true

				dx = evt.clientX - $scope.selectedSVGScale.originX
				dy = evt.clientY - $scope.selectedSVGScale.originY

				# Impose limits on how small the SVGs can be scaled
				switch $scope.answers[index].svg.type
					when "ellipse"
						if ($scope.answers[index].svg.r + $scope.answers[index].svg.scaleXFactor + dx) >= 20
							$scope.answers[index].svg.scaleXFactor += dx

						if ($scope.answers[index].svg.r + $scope.answers[index].svg.scaleYFactor + dy) >= 20
							$scope.answers[index].svg.scaleYFactor += dy

					when "rect"
						if ($scope.answers[index].svg.width + $scope.answers[index].svg.scaleXFactor + dx) >= 30
							$scope.answers[index].svg.scaleXFactor += dx

						if ($scope.answers[index].svg.height + $scope.answers[index].svg.scaleYFactor + dy) >= 30
							$scope.answers[index].svg.scaleYFactor += dy


				$scope.selectedSVGScale.originX = evt.clientX
				$scope.selectedSVGScale.originY = evt.clientY

		# If a mousedown/mouseup event pair occurs and the SVG HAS NOT moved, we can assume it's a click
		# Opens or closes the hotspotmanager and sets the properties as required
		$scope.manageSVG = (index, evt) ->
			unless $scope.selectedSVG.hasMoved

				if $scope.hotspotAnswerManager.show is true
					$scope.hotspotAnswerManager.show = false
					$scope.hotspotAnswerManager.target = null
					$scope.hotspotAnswerManager.answerIndex = null
				else
					$scope.hotspotAnswerManager.show = true

					# The hotspot answer manager will appear adjacent to the cursor
					# Pass it the cursor location, which is tweaked in the answer manager's directive before being applied
					$scope.hotspotAnswerManager.x = evt.clientX
					$scope.hotspotAnswerManager.y = evt.clientY

					$scope.hotspotAnswerManager.answerIndex = index
					$scope.hotspotAnswerManager.target = $scope.answers[index].target

			$scope.selectedSVG.hasMoved = false # once the click event has checked on hasMoved, we can reset it

		# Broadcast listener to reset the hotspotAnswerManager
		$scope.$on "editedNode.hotspotAnswerManager.reset", (evt) ->
			$scope.hotspotAnswerManager.show = false
			$scope.hotspotAnswerManager.target = null
			$scope.hotspotAnswerManager.answerIndex = null


Adventure.directive "hotspotToolbar", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# Notes on SVG properties..
		# -------------------------
		# x:  X position of SVG, defaulted to DEFAULTX
		# y:  Y position of SVG, defaulted to DEFAULTY
		# r: initial radius of ellipse, altered by scaleXFactor & scaleYFactor (ellipse only)
		# width: self explanatory, altered by scaleXFactor (rect only)
		# height: self explanatory, altered by scaleYFactor (rect only)
		# fill: fill color
		# stroke: stroke width
		# points: a string of X,Y coordinates for drawing a polygon (polygon only)
		# scaleXOffset: X Offset of scale tool icon relative to center of the SVG object, differs based on SVG type
		# scaleYOffset: Y Offset of scale tool, same as above
		# scaleXFactor: How much to scale SVG on the X axis
		# scaleYFactor: How much to scale SVG on the Y axis

		$scope.startEllipticalHotspot = ->
			$scope.newAnswer()

			answerIndex = $scope.answers.length - 1

			$scope.answers[answerIndex].svg =
				type: "ellipse"
				x: $scope.DEFAULTX
				y: $scope.DEFAULTY
				r: 50
				fill: "blue"
				stroke: 2
				scaleXOffset: 30
				scaleYOffset: 30
				scaleXFactor: 0
				scaleYFactor: 0

		$scope.startSquareHotspot = ->
			$scope.newAnswer()

			answerIndex = $scope.answers.length - 1

			$scope.answers[answerIndex].svg =
				type: "rect"
				x: $scope.DEFAULTX
				y: $scope.DEFAULTY
				width: 100
				height: 75
				fill: "green"
				stroke: 2
				scaleXOffset: 90
				scaleYOffset: 65
				scaleXFactor: 0
				scaleYFactor: 0

		# making a polygon is a little more complex, we don't actually create the new answer yet
		# Instead, it activates the drawMode flag and enables the polygon drawing canvas
		$scope.startPolygonHotspot = ->
			$scope.polygonDrawMode = true

			$scope.toast "Click anywhere to start drawing a polygon."

		# When the polygon drawing mode is complete, we can actually create the polygon using the defined points
		# And the associated answer of course
		$scope.$on "editedNode.polygon.complete", (evt) ->

			$scope.newAnswer()

			answerIndex = $scope.answers.length - 1

			$scope.answers[answerIndex].svg =
				type: "polygon"
				x: 0
				y: 0
				fill: "red"
				stroke: 2
				points: $scope.polygonPoints

Adventure.directive "hotspotAnswerManager", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.colors = [
			"blue",
			"red",
			"green",
			"aliceblue",
			"coral",
			"indigo",
			"lightgreen",
			"slategrey",
			"yellow",
			"teal",
			"darkred",
			"blueviolet",
			"cyan",
			"goldenrod"
		]

		$scope.$watch "hotspotAnswerManager.target", (newVal, oldVal) ->

			if newVal isnt null and newVal isnt undefined

				xOffset = $scope.hotspotAnswerManager.x
				yOffset = $scope.hotspotAnswerManager.y

				# Get bounds of the answerManager and the entire tree container to check if the manager is off-screen
				bounds = angular.element($element)[0].getBoundingClientRect()
				container = document.getElementById("tree-svg").getBoundingClientRect()

				# Move the manager so its back into frame if it's out of bounds
				if (yOffset + bounds.height) > container.height
					diffY = (yOffset + bounds.height) - container.height - 5
					yOffset -= diffY

				if (xOffset + bounds.width) > container.width
					diffX = (xOffset + bounds.width) - container.width - 5
					xOffset -= diffX

				# Finally, update the position of the manager so the X/Y coords properly align with the hotspot canvas
				managerBounds = document.getElementById("hotspot-manager").getBoundingClientRect()

				xOffset -= managerBounds.left
				yOffset -= managerBounds.top

				styles = "left: " + xOffset + "px; top: " + yOffset + "px"

				$attrs.$set "style", styles

		$scope.closeManager = (evt) ->

			target = angular.element evt.target

			# Whitelist elements that shouldn't close the hotspotAnswerManager
			prop = angular.element(evt.target).prop("tagName").toLowerCase()
			if prop is "ellipse" or prop is "rect" or prop is "polygon" then return

			$scope.colorDrawerOpen = false

			$scope.hotspotAnswerManager.show = false
			$scope.hotspotAnswerManager.target = null

		# Updates the currently managed polygon with the selected color
		$scope.updatePolygonColor = (evt) ->
			color = angular.element(evt.target).attr("data-color")

			$scope.answers[$scope.hotspotAnswerManager.answerIndex].svg.fill = color

			$scope.colorDrawerOpen = false

		# Alters the order of the answers array so the selected SVG has a lower Z-index
		# Answers closer to the end of the array are rendered above answers before them
		$scope.moveAnswerBack = ->

			oldIndex = $scope.hotspotAnswerManager.answerIndex

			orphan = $scope.answers.splice(oldIndex, 1)[0]

			$scope.answers.splice oldIndex - 1, 0, orphan

			$scope.hotspotAnswerManager.answerIndex--

		# Alters the order of the answers array so the selected SVG has a higher Z-index
		# Answers closer to the front of the array are rendered below answers after them
		$scope.moveAnswerForward = ->

			oldIndex = $scope.hotspotAnswerManager.answerIndex

			orphan = $scope.answers.splice(oldIndex, 1)[0]

			$scope.answers.splice oldIndex + 1, 0, orphan

			$scope.hotspotAnswerManager.answerIndex++

# The artboard is displayed over the hotspot image and allows the user to "draw" the polygon by generating new polylines when/where a click occurs
# When a click occurs in proximity to the original click point, the polygon is considered "closed" and the points are used to generate an actual polygon hotspot
Adventure.directive "polygonArtboard", ($rootScope) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.polygonDrawMode = false
		$scope.clickLocations = null
		$scope.boundings = null
		$scope.polygonPoints = null

		$scope.lastClicked =
			x : null
			y : null

		$scope.cursorPoint =
			x : null
			y : null

		$scope.$watch "polygonDrawMode", (newVal, oldVal) ->
			if newVal is true
				$scope.clickLocations = []
			else if newVal is false
				$scope.clickLocations = null

		# Each click on the artboard becomes a new point of the polygon
		# When a click is registered in proximity to the first point, it's assumed the polygon is being completed
		# The array of points is then used to define the actual polygon SVG for the hotspot
		$scope.recordClicks = (evt) ->
			if $scope.polygonDrawMode is true

				# For whatever reason, the BoundingClientRect hasn't been updated prior to this point
				if $scope.boundings is null
					$scope.boundings = $element[0].getBoundingClientRect()

				# Convert event X and Y coords into coords for the SVG
				xPos = evt.clientX - $scope.boundings.left
				yPos = evt.clientY - $scope.boundings.top

				# If a click event happens within close (+/- 15px X & Y) proximity of the first point, complete the shape
				# This can only occur when there are a minimum of three sides to the polygon, for obvious reasons
				if $scope.clickLocations.length > 3

					if xPos < ($scope.clickLocations[0][0] + 15) and xPos > ($scope.clickLocations[0][0] - 15) and yPos < ($scope.clickLocations[0][1] + 15) and yPos > ($scope.clickLocations[0][1] - 15)
						return completePolygon()

				# Update the lastClicked and cursorPoint locations for the guide line
				$scope.lastClicked.x = $scope.cursorPoint.x = xPos
				$scope.lastClicked.y = $scope.cursorPoint.y = yPos

				$scope.clickLocations.push [xPos, yPos]

				# Rebuild the string describing all the points of the polygon
				$scope.polygonPoints = $scope.renderPoints()

		$scope.updateCursorPoint = (evt) ->
			if $scope.clickLocations.length > 0
				$scope.cursorPoint.x = evt.clientX - $scope.boundings.left
				$scope.cursorPoint.y = evt.clientY - $scope.boundings.top

		# Converts all the point pairs in the clickLocations array into the string used to draw the polyline
		$scope.renderPoints = ->
			pointsStr = ""

			angular.forEach $scope.clickLocations, (point, index) ->

				pointsStr += point[0] + "," + point[1] + " "

			pointsStr

		completePolygon = ->

			$rootScope.$broadcast "editedNode.polygon.complete"

			# Reset state for polygon scope variables
			$scope.polygonDrawMode = false
			$scope.clickLocations = null
			$scope.boundings = null
			$scope.polygonPoints = null

			$scope.lastClicked =
				x : null
				y : null

			$scope.cursorPoint =
				x : null
				y : null

# A rather straightforward little directive to ensure the answer container auto-scrolls to the newest row and focuses it when a new answer is added
Adventure.directive "autoScrollAndSelect", ($timeout) ->
	restrict: "A",
	link: ($scope,$element, $attrs) ->

		# Listen for when a new answer is added
		$scope.$on "editedNode.answers.added", (evt) ->
			if $scope.editedNode.type is $scope.MC or $scope.editedNode.type is $scope.SHORTANS

				# need to delay execution of this code so the DOM has time to render the new HTML associated with the answer
				# OH GOD THIS IS SO DIRTY
				# Angular doesn't have an effective callback for post- DOM renders, stuck with $timeout for now
				$timeout (() ->
					# Auto-scroll to the bottom
					$element[0].scrollTop = $element[0].scrollHeight

					# Find the answer input box and focus it
					list = angular.element($element.children()[0]).children()
					if list.length > 0
						row = angular.element list[list.length - 1]
						# children()[1] references the answer text input box
						row.children()[1].focus()
				), 100

# The validation dialog is linked to two validation events:
# - when the qset is loaded and a problem is detected (node doesn't exist)
# - when the widget is published and problems are detected
# The dialog pulls the error data from the $scope.validation object, and operates on each
# Each problem can be selected to visit the node in question (using the errorFollowUp function)
Adventure.directive "validationDialog", (treeSrv, $rootScope) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$on "validation.error", (evt) ->
			if $scope.validation.errors and $scope.validation.errors.length > 0
				$scope.validation.show = true
				$scope.showBackgroundCover = true

				angular.forEach $scope.validation.errors, (error, index) ->

					switch error.type
						# For missing answers, we generate a blank node and link the answer to it
						when "missing_answer_node"
							node = treeSrv.findNode $scope.treeData, error.node

							node.hasProblem = true

							answerIndex = null
							angular.forEach node.answers, (answer, index) ->
								if answer.target is error.target
									answerIndex = index

							newTarget = $scope.addNode node.id, $scope.BLANK

							node.answers[answerIndex].target = newTarget
							node.answers[answerIndex].linkMode = $scope.NEW

							treeSrv.set $scope.treeData
							treeSrv.updateAllAnswerLinks $scope.treeData

							error.correctedTarget = newTarget

						# For other error types, simply indicate there's a problem
						when "blank_node", "has_no_answers", "has_no_final_score", "has_bad_html"
							node = treeSrv.findNode $scope.treeData, error.node

							node.hasProblem = true

							treeSrv.set $scope.treeData


		# Provide temporary focus to the selected node and translate the tree so it's centered in the window
		$scope.errorFollowUp = (errorIndex) ->
			error = $scope.validation.errors[errorIndex]

			node = treeSrv.findNode $scope.treeData, error.node

			node.hasTemporaryFocus = true

			$scope.treeOffset.x = (node.x * $scope.treeOffset.scale) + $scope.treeOffset.scaleXOffset
			$scope.treeOffset.y = (node.y * $scope.treeOffset.scale) + $scope.treeOffset.scaleYOffset

			$rootScope.$broadcast "tree.nodeFocus"

			treeSrv.set $scope.treeData
			$scope.hideCoverAndModals()



# MEANT FOR DEBUG PURPOSES ONLY
Adventure.directive "debugQsetLoader", (treeSrv, legacyQsetSrv, $rootScope) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.debugQset = ""

		$scope.loadOldDebugQset = ->
			try
				$scope.debugQset = JSON.parse $scope.debugQset
				$scope.debugQset = legacyQsetSrv.convertOldQset $scope.debugQset
			catch err
				alert "Uh oh! There was a problem loading this widget."
				$scope.showQsetLoader = false
				return

			$scope.loadDebugQset()

		$scope.loadDebugQset = ->

			try
				qset = JSON.parse $scope.debugQset
				$scope.treeData = treeSrv.createTreeDataFromQset qset
			catch err
				alert "Uh oh! There was a problem loading this widget."
				$scope.showQsetLoader = false
				return

			validation = treeSrv.validateTreeOnStart $scope.treeData
			if validation.length
				$scope.validation.errors = validation
				$rootScope.$broadcast "validation.error"

			treeSrv.set $scope.treeData
			treeSrv.updateAllAnswerLinks $scope.treeData
			$scope.showQsetLoader = false


