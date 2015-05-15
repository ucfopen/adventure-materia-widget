Adventure = angular.module "AdventureCreator"

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
Adventure.directive "treeVisualization", (treeSrv, $window, $timeout) ->
	restrict: "E",
	scope: {
		data: "=", # binds treeData in a way that's accessible to the directive
		nodeClick: "&", # binds a listener so the controller can access the directive's click data
		bgClick: "&",
		onHover: "&",
		onHoverOut: "&"
	},
	link: ($scope, $element, $attrs) ->

		$scope.svg = null
		$scope.copyMode = false

		$scope.windowWidth = document.getElementById("adventure-container").offsetWidth - 15

		# Re-render tree whenever the nodes are updated
		$scope.$on "tree.nodes.changed", (evt) ->
			$scope.render treeSrv.get()

		# Re-render the tree with copyMode enabled (highlights blank nodes)
		$scope.$on "mode.copy", (evt) ->
			$scope.copyMode = true
			$scope.render treeSrv.get()

		$scope.render = (data) ->

			unless data? then return false

			# Modify height of tree based on max depth
			# Keeps initial tree from being absurdly sized
			# Note that this will NOT take into account newly created nodes! As such, depth is likely to be off by +/- 1
			depth = treeSrv.getMaxDepth()
			adjustedHeight = 250 + (depth * 75)

			# Init tree data
			tree = d3.layout.tree()
				.sort(null)
				.size([$scope.windowWidth, adjustedHeight]) # sets size of tree
				.children (d) -> # defines accessor function for nodes (e.g., what the "d" object is)
					if !d.contents or d.contents.length is 0 then return null
					else return d.contents

			nodes = tree.nodes data # Setup nodes
			links = tree.links nodes # Setup links
			adjustedLinks = [] # Finalized links array that includes "special" links (loopbacks and bridges)

			angular.forEach nodes, (node, index) ->

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

					angular.forEach node.answers, (answer, index) ->

						if answer.linkMode is "existing"

							# Grab the targeted node for the new link
							target = treeSrv.findNode treeSrv.get(), answer.target

							# Craft the new link and add source & target
							newLink = {}

							newLink.source = node
							newLink.target = target
							newLink.specialCase = "otherNode"

							links.push newLink

				# Generate "loopback" links that circle back to the same node
				# This link has the same source/target, the node itself;
				# It's just a formality really, so D3 -knows- a link exists here
				if node.hasLinkToSelf

					newLink = {}
					newLink.source = node
					newLink.target = node
					newLink.specialCase = "loopBack"

					links.push newLink


			# We need to effectively "filter" each link and create the intermediate nodes
			# The properties of the link and intermediate "bridge" nodes depends on what kind of link we have
			angular.forEach links, (link, index) ->

				# else if link.specialCase is "loopBack"

				# 	intermediate =
				# 		x: link.source.x + 75
				# 		y: link.source.y + 75
				# 		type: "bridge"

				# 	adjustedLinks.push link

				source = link.source
				target = link.target
				intermediate =
					x: source.x + (target.x - source.x)/2
					y: source.y + (target.y - source.y)/2
					type: "bridge"
					source: link.source.id
					target: link.target.id

				# If a link is a special case, the node's position isn't midway between source & target
				# Add a reference to the link's associated bridge node so the node coords can be updated later
				# This is a sort of hackish solution, but I've yet to discover a cleaner method
				if link.specialCase
					link.bridgeNodeIndex = nodes.length
					intermediate.specialCase = link.specialCase

				nodes.push intermediate

			# "post" depth accurately reads the new depth of the tree with any freshly created/deleted nodes
			# Now that we have it, we can set the height of the tree's parent SVG
			postDepth = treeSrv.getMaxDepth()
			postAdjustedHeight = 250 + (postDepth * 75)
			if postAdjustedHeight < 615 then svgHeight = 615 else svgHeight = postAdjustedHeight

			# Render tree
			if $scope.svg == null
				$scope.svg = d3.select($element[0])
					.append("svg:svg")
					.attr("width", $scope.windowWidth) # Size of actual SVG container
					.attr("height",svgHeight) # Size of actual SVG container
					.on("click", () ->
						$scope.bgClick()
					)
					.append("svg:g")
					.attr("class", "container")
					.attr("transform", "translate(0,50)") # translates position of overall tree in svg container
			else
				$scope.svg.selectAll("*").remove()

				# Somewhat hackish bullshit to update the height attribute of the SVG, since D3 doesn't like changing it
				dimTarget = angular.element($element.children()[0])
				dimTarget.attr("height",svgHeight)
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

			# Paths come in two flavors:
			# Standard, hierarchical links are straight, end-to-end paths from a parent node to a child
			# Special, non-hierarchical links are curves, so the math for the curve must be computed for each link
			# Also, the position of their associated bridge nodes must be updated to match the midpoint of the curve
			angular.forEach paths[0], (path, index) ->

				path = d3.select path

				if links[index].specialCase

					path.attr("d", (d) ->
						dx = d.target.x - d.source.x
						dy = d.target.y - d.source.y
						dr = Math.sqrt(dx * dx + dy * dy)
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

				# If it's just a standard link, this part is easy
				else path.attr("d", lineData)


			linkGroup.append("svg:circle")
				.attr("class","loopback")
				.attr("r", 50)
				.attr("transform", (d) ->

					xOffset = d.source.x + 40
					yOffset = d.source.y + 40

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
					# if d.type is "bridge" then return 20
					# else return 20
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

					if d.name.length > 1 then return 9 * d.name.length
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

				# sets X label offset from node (negative left, positive right side)
				# .attr("dx", (d) ->
				# 	# if d.children then return -gap
				# 	# else return gap
				# )

				.attr("dy", 15) # sets Y label offset from node
				.attr("font-family", "Lato")
				.attr("font-size", 14)
				.text (d) ->
					d.name

			# The "+" symbol displayed on bridge nodes (the pseudo-nodes between nodes you can click to add an in-between node)
			nodeGroup.append("path")
				.attr("d", "M -3,12 L -3,3 L -12,3 L -12,-3 L -3,-3 L -3,-12 L 3,-12 L 3,-3 L 12,-3 L 12,3 L 3,3 L 3,12 Z")
				.attr("visibility", (d) ->
					if d.type isnt "bridge" then return "hidden"
				)

			$scope.copyMode = false

		# Handle resizing of the browser window
		window = angular.element($window)
		window.bind "resize", () ->
			$scope.windowWidth = document.getElementById("adventure-container").offsetWidth - 15
			$scope.render treeSrv.get()

		# Kick off rendering the tree for the 1st time
		$scope.render treeSrv.get()

# Self explanatory directive for editing the title
Adventure.directive "titleEditor", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "showTitleEditor", (newVal, oldVal) ->
			if newVal
				$scope.showBackgroundCover = true

# Directive for the small tooltip displaying the answer associated with a given node on mouseover
Adventure.directive "answerTooltip", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		$scope.$watch "hoveredNode.target", (newVal, oldVal) ->
			if newVal isnt null

				# Update the position of the tooltip
				xOffset = $scope.hoveredNode.x + 35
				yOffset = $scope.hoveredNode.y + 45
				styles = "left: " + xOffset + "px; top: " + yOffset + "px"
				$attrs.$set "style", styles

				# Grab the parent node so we can find the associated answer text
				parent = treeSrv.findNode $scope.treeData, $scope.hoveredNode.targetParent

				# Find the answer and update the tooltip text appropriately
				angular.forEach parent.answers, (answer, index) ->
					if answer.target is $scope.hoveredNode.target
						if answer.text isnt null
							$scope.hoveredNode.text = answer.text
						else
							$scope.hoveredNode.text = "[No Answer Text]"

				$scope.hoveredNode.showTooltip = true

# Directive for the node modal dialog (edit the node, copy the node, reset the node, etc)
Adventure.directive "nodeToolsDialog", (treeSrv, $rootScope) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# Flags for displaying the reset node confirmation dialog
		hasChildrenFlag = false
		$scope.nodeTools.showResetWarning = false
		$scope.nodeTools.showDeleteWarning = false

		# Helper vars for copying node/child trees, stored up here for scope reasons
		sourceTree = null
		copyTree = null
		targetNode = null

		# When target for the dialog changes, update the position values based on where the new node is
		$scope.$watch "nodeTools.target", (newVals, oldVals) ->

			xOffset = $scope.nodeTools.x + 0
			yOffset = $scope.nodeTools.y + 50

			styles = "left: " + xOffset + "px; top: " + yOffset + "px"

			$attrs.$set "style", styles

			# Reset the visibility of the warning flag
			$scope.nodeTools.showResetWarning = false

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

				if newVal
					$scope.hideToast()
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

				angular.forEach parentNode.answers, (answer, index) ->
					if answer.target is copy.formerId
						console.log "Located answer pointing to former id " + copy.formerId + ", updating to " + copy.id
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
				treeSrv.findAndRemove $scope.treeData, answer.target

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
			if $scope.editedNode.id is $scope.nodeTools.target
				$scope.editedNode = {}

			# Go ahead and actually replace the existing node on the tree with the blank version
			treeSrv.findAndReplace $scope.treeData, target.id, target
			treeSrv.set $scope.treeData

			$scope.toast "Node " + target.name + " has been reset."

			$scope.nodeTools.showResetWarning = false
			$scope.nodeTools.show = false
			$scope.nodeTools.target = null

		# Delete the node, and the associated parent's answer
		# Don't delete the node if it's a) a child of a narrative node or b) the associated node of a short answer's unmatched responses
		$scope.deleteNode = () ->

			target = treeSrv.findNode $scope.treeData, $scope.nodeTools.target
			parent = treeSrv.findNode $scope.treeData, target.parentId
			targetAnswerIndex = null

			if parent.type is $scope.NARR
				$scope.toast "Can't delete Destination " + target.name + "! Try linking " + parent.name + " to an existing destination instead."
				$scope.nodeTools.showDeleteWarning = false
				return

			angular.forEach parent.answers, (answer, index) ->
				if answer.target is target.id
					targetAnswerIndex = index

			if targetAnswerIndex isnt null

				if parent.answers[targetAnswerIndex].isDefault and parent.type is $scope.SHORTANS
					$scope.toast "Can't delete Destination " + target.name + "! Unmatched responses need to go somewhere!"
					$scope.nodeTools.showDeleteWarning = false
					return

			treeSrv.findAndRemove $scope.treeData, target.id

			treeSrv.findAndFixAnswerTargets $scope.treeData, target.id

			treeSrv.set $scope.treeData

			$scope.nodeTools.showDeleteWarning = false
			$scope.nodeTools.show = false
			$scope.nodeTools.target = null

			$scope.hoveredNode.showTooltip = false
			$scope.hoveredNode.target = null
			$scope.hoveredNode.targetParent = null

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
		$scope.$watch "newNodeManager.target", (newVal, oldVal) ->
			if newVal isnt null
				$scope.newNodeManager.show = true

				xOffset = $scope.newNodeManager.x - 205
				yOffset = $scope.newNodeManager.y - 60

				styles =  "left: " + xOffset + "px; top: " + yOffset + "px"

				$attrs.$set "style", styles

		$scope.selectLinkMode = (mode) ->

			answer = {}

			# Grab the answer object that corresponds with the nodeManager's current target
			i = 0
			while i < $scope.answers.length
				if $scope.answers[i].target is $scope.newNodeManager.target then break
				else i++

			console.log "new mode: " + mode + " existing mode: " + $scope.newNodeManager.linkMode

			# Compare the prior link mode to the new one and deal with the changes
			if mode != $scope.newNodeManager.linkMode
				switch mode
					when "new"

						## HANDLE PRIOR LINK MODE: SELF
						if $scope.answers[i].linkMode is $scope.SELF

							if $scope.editedNode.hasLinkToSelf
								delete $scope.editedNode.hasLinkToSelf

						## HANDLE PRIOR LINK MODE: EXISTING
						else if $scope.answers[i].linkMode is $scope.EXISTING

							if $scope.editedNode.hasLinkToOther
								delete $scope.editedNode.hasLinkToOther


						# Create new node and update the answer's target
						targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK
						$scope.answers[i].target = targetId

						# Set updated linkMode flags
						$scope.newNodeManager.linkMode = $scope.NEW
						$scope.answers[i].linkMode = $scope.NEW
						console.log "New mode selected: NEW"

						$scope.newNodeManager.target = null

					when "existing"

						# Suspend the node creation screen so the user can select an existing node
						$scope.showBackgroundCover = false
						$scope.nodeTools.show = false
						$scope.displayNodeCreation = "suspended"

						# Set the node selection mode so click events are handled differently than normal
						$scope.existingNodeSelectionMode = true

						$scope.toast "Select the point this answer should link to.", false

						# All tasks are on hold until the user selects a node to link to
						# Wait for the node to be selected
						deregister = $scope.$watch "existingNodeSelected", (newVal, oldVal) ->

							if newVal

								$scope.hideToast()

								# Set the answer's new target to the newly selected node
								$scope.answers[i].target = newVal.id

								## HANDLE PRIOR LINK MODE: NEW
								if $scope.answers[i].linkMode is $scope.NEW

									# Scrub the existing child node associated with this answer
									childNode = treeSrv.findNode $scope.treeData, $scope.newNodeManager.target
									if childNode then treeSrv.findAndRemove $scope.treeData, childNode.id

								## HANDLE PRIOR LINK MODE: SELF
								if $scope.answers[i].linkMode is $scope.SELF

									if $scope.editedNode.hasLinkToSelf
										delete $scope.editedNode.hasLinkToSelf

								# Set updated linkMode flags and redraw tree
								$scope.editedNode.hasLinkToOther = true
								$scope.answers[i].linkMode = $scope.EXISTING

								treeSrv.set $scope.treeData

								# $scope.newNodeManager.linkMode = $scope.EXISTING
								console.log "New mode selected: EXISTING"

								# Deregister the watch listener now that it's not needed
								deregister()

								$scope.existingNodeSelected = null
								$scope.newNodeManager.target = null
								$scope.displayNodeCreation = "none" # displayNodeCreation should be updated from "suspended"


					when "self"

						# Set answer row's target to the node being edited
						$scope.answers[i].target = $scope.editedNode.id

						## HANDLE PRIOR LINK MODE: NEW
						if $scope.answers[i].linkMode is $scope.NEW

							# Scrub the existing child node associated with this answer
							childNode = treeSrv.findNode $scope.treeData, $scope.newNodeManager.target
							treeSrv.findAndRemove $scope.treeData, childNode.id

						## HANDLE PRIOR LINK MODE: EXISTING
						else if $scope.answers[i].linkMode is $scope.EXISTING

							if $scope.editedNode.hasLinkToOther
								delete $scope.editedNode.hasLinkToOther

						# Set updated linkMode flags and redraw the tree
						$scope.editedNode.hasLinkToSelf = true
						$scope.answers[i].linkMode = $scope.SELF

						treeSrv.set $scope.treeData

						$scope.newNodeManager.linkMode = $scope.SELF
						console.log "New mode selected: SELF"

						$scope.newNodeManager.target = null

			else $scope.newNodeManager.target = null


			$scope.newNodeManager.show = false

# Dialog for warning that, oh shit, you're going to delete some child nodes if you decide to do this
Adventure.directive "deleteWarningDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "deleteDialog.target", (newVal, oldVal) ->

			if newVal
				offsetX = $scope.deleteDialog.x + 30
				offsetY = $scope.deleteDialog.y - 56

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
Adventure.directive "nodeCreation", (treeSrv, $rootScope) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$on "editedNode.target.changed", (evt) ->

			console.log "editedNode updated! Type is now: " + $scope.editedNode.type

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
					# TODO add type check for media here
					$scope.image = new Image()
					$scope.image.src = $scope.editedNode.media.url
					$scope.mediaReady = true
					$scope.image.onload = ->
						console.log "image upload via stored editedNode media data complete!"
				else $scope.mediaReady = false

				if $scope.editedNode.type is $scope.HOTSPOT
					unless $scope.editedNode.hotspotVisibility then $scope.editedNode.hotspotVisibility = "always"


				if $scope.editedNode.type is $scope.END
					if $scope.editedNode.finalScore then $scope.finalScore = $scope.editedNode.finalScore
					else $scope.finalScore = null

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
			if newVal
				$scope.editedNode.question = newVal

		$scope.$watch "answers", ((newVal, oldVal) ->
			if newVal
				$scope.editedNode.answers = $scope.answers
		), true

		# Since media isn't bound to a model like answers and questions, listen for update broadcasts
		$scope.$on "editedNode.media.updated", (evt) ->
			if $scope.editedNode.type isnt $scope.HOTSPOT
				$scope.image = new Image()
				$scope.image.src = $scope.editedNode.media.url
				$scope.image.onload = ->
					$scope.$apply ->
						$scope.mediaReady = true
						console.log "image upload via media.updated broadcast complete!"

		$scope.newAnswer = (text = null) ->

			# If the editedNode has a pending target, the new answer's target will be set to it
			# pendingTarget is used for adding in-between nodes or linking orphaned nodes
			if $scope.editedNode.pendingTarget
				targetId = $scope.editedNode.pendingTarget
				linkMode = $scope.EXISTING
				delete $scope.editedNode.pendingTarget
			else
				# We create the new node first, so we can grab the new node's generated id
				targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK
				linkMode = $scope.NEW

			newAnswer =
				text: text
				feedback: null
				target: targetId
				linkMode: linkMode

			# Add a matches property to the answer object if it's a short answer question.
			if $scope.editedNode.type is $scope.SHORTANS
				newAnswer.matches = []
			$scope.answers.push newAnswer

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
				treeSrv.findAndRemove treeSrv.get(), targetId

				# Display the interactive toast that provides the Undo option
				# Toast is displayed until clicked or until the node creation screen is closed
				$scope.interactiveToast "Node " + $scope.integerToLetters(targetId) + " was deleted.", "Undo", ->
					$scope.restoreDeletedNode targetId
			else
				# Just remove it from answers array, no further action required
				$scope.answers.splice index, 1

			# Update tree to reflect new state
			treeSrv.set $scope.treeData

			# If the node manager modal is open for this answer, close it
			if targetId is $scope.newNodeManager.target
				$scope.newNodeManager.show = false
				$scope.newNodeManager.target = null

			# If it's a hotspot, let the manager know it's time to reset and close
			# (Since the manager is defined in another directive, it needs to be broadcast)
			if $scope.editedNode.type is $scope.HOTSPOT
				$rootScope.$broadcast "editedNode.hotspotAnswerManager.reset"

		# Restores an answer/node pair that's been deleted, formatted as a "cold storage" object
		# The anwer/node pair must be a child of the current editedNode
		$scope.restoreDeletedNode = (target) ->

			# Assume deletedCache exists on the editedNode - if not, something's wrong
			unless $scope.editedNode.deletedCache then return

			angular.forEach $scope.editedNode.deletedCache, (item, index) ->

				if item.id is target
					# Splice the answer and node back into their respective arrays at their previous index positions
					$scope.answers.splice item.answerIndex, 0, item.answer
					$scope.editedNode.contents.splice item.nodeIndex, 0, item.node
					$scope.editedNode.deletedCache.splice index, 1

					# Update the tree to display the restored node
					treeSrv.set $scope.treeData
					return


		$scope.manageNewNode = ($event, target, mode) ->

			if $scope.newNodeManager.show is true
				$scope.newNodeManager.show = false
				$scope.newNodeManager.target = null
			else
				$scope.newNodeManager.x = $event.currentTarget.getBoundingClientRect().left
				$scope.newNodeManager.y = $event.currentTarget.getBoundingClientRect().top
				$scope.newNodeManager.linkMode = mode
				$scope.newNodeManager.target = target

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
			$scope.toast "Node " + $scope.editedNode.name + " saved!", false

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

Adventure.directive "hotspotManager", () ->
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
		# Attempts to nest these properties inside an svg-specific directive unsuccessful
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

		# Listener for updating the hotspot node's image once it's ready
		$scope.$on "editedNode.media.updated", (evt) ->

			$scope.image = new Image()
			$scope.image.src = $scope.editedNode.media.url
			$scope.image.onload = ->
				$scope.$apply ->
					$scope.mediaReady = true

		$scope.selectSVG = (evt) ->
			# console.log "SELECTED"

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
					$scope.hotspotAnswerManager.x = $scope.answers[index].svg.x
					$scope.hotspotAnswerManager.y = $scope.answers[index].svg.y
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
			console.log "Starting an elliptical hotspot!"
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
			console.log "Starting a square hotspot!"

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
			console.log "Starting a polygonal hotspot!"
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

				xOffset = $scope.hotspotAnswerManager.x + 25
				yOffset = $scope.hotspotAnswerManager.y + 15

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

# MEANT FOR DEBUG PURPOSES ONLY
Adventure.directive "debugQsetLoader", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.debugQset = ""

		$scope.loadDebugQset = ->

			try
				qset = JSON.parse $scope.debugQset
				$scope.treeData = treeSrv.createTreeDataFromQset qset
				console.log $scope.treeData
			catch err
				console.log err
				$scope.showQsetLoader = false
				return

			treeSrv.set $scope.treeData
			$scope.showQsetLoader = false


