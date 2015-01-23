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
				.children (d) -> # defines accessor function for nodes (e.g., what the "d" object is)
					if !d.contents or d.contents.length is 0 then return null
					else return d.contents

			nodes = tree.nodes data # Setup nodes
			links = tree.links nodes # Setup links
			adjustedLinks = [] # Alternate links array that includes bridges (see forEach links below)

			angular.forEach nodes, (node, index) ->

				# If the node has any non-hierarchical links, have to process them
				# And generate new links that d3 won't create by default
				if node.hasLinkToOther

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

				if node.hasLinkToSelf

					newLink = {}

					newLink.source = node
					newLink.target = node
					newLink.specialCase = "loopBack"
					# newLink.target = nodes[index - 1]

					console.log "Hey! Generating pseudo link!"
					# console.log nodes[index - 1]

					links.push newLink

			angular.forEach links, (link, index) ->

				if link.specialCase is "otherNode"
					source = link.source
					target = link.target
					intermediate =
						x: source.x + (target.x - source.x)/2
						y: (source.y + (target.y - source.y)/2) + 25
						type: "bridge"

					adjustedLinks.push {source: source, target: intermediate}, {source: intermediate, target: target}

				else
					source = link.source
					target = link.target
					intermediate =
						x: source.x + (target.x - source.x)/2
						y: source.y + (target.y - source.y)/2
						type: "bridge"

					adjustedLinks.push link

				nodes.push intermediate

				# adjustedLinks.push {source: source, target: intermediate}, {source: intermediate, target: target}
				# links.push {source: source, target: intermediate}, {source: intermediate, target: target}
				# bilinks.push {source: source, target: intermediate}, {source: intermediate, target: target}

			# console.log links

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

			link = d3.svg.diagonal (d) ->
				return [d.x, d.y]

			# link = d3.svg.diagonal()
			# 	.projection (d) ->
			# 		return [d.x, d.y] # seems to set whether the tree is drawn top-down or left-right
			# 							# ensure the additional references to d.x and d.y are flipped too

			$scope.svg.selectAll("path.link")
				.data(adjustedLinks)
				.enter()
				.append("svg:path")
				.attr("class", "link")
				.attr("class", (d) ->
					if d.specialCase == "bridge" then return "link bridge"
					else return "link"
				)
				.attr("d", link)

				# .attr("d", (d) ->
				# 	unless d.specialCase
				# 		return link

				# 	bridgeLink = d3.svg.diagonal().projection (d) ->

				# )

			nodeGroup = $scope.svg.selectAll("g.node")
				.data(nodes)
				.enter()
				.append("svg:g")
				# .attr("class", "node")
				.attr("class", (d) ->
					if d.type is "bridge" then return "bridge"
					else return "node #{d.type}"
				)
				.on("mouseover", (d, i) ->

					if d.type is "bridge" then return

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
				.on("mouseout", (d, i) ->

					if d.type is "bridge" then return

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
				.attr("r", (d) ->
					if d.type is "bridge" then return 4
					else return 20
				) 				# sets size of node bubbles

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

		$scope.copyNode = () ->
			console.log "Copying NYI!"

		$scope.dropNode = () ->
			treeSrv.findAndRemove $scope.treeData, $scope.nodeTools.target
			$scope.nodeTools.show = false
			treeSrv.set $scope.treeData


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

Adventure.directive "nodeCreationMc", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# $scope.question = ""

		$scope.$on "editedNode.target.changed", (evt) ->
			console.log "edited node changed!"

			# Initialize the node edit screen with the node's info. If info doesn't exist yet, init properties
			if $scope.editedNode
				if $scope.editedNode.question then $scope.question = $scope.editedNode.question
				else $scope.question = null

				if $scope.editedNode.answers then $scope.answers = $scope.editedNode.answers
				else
					$scope.answers = []
					$scope.newAnswer()

				# Update the node type
				$scope.editedNode.type = $scope.MC

		# Update the node's properties when the associated input models change
		$scope.$watch "question", (newVal, oldVal) ->
			if newVal
				$scope.editedNode.question = newVal

		$scope.$watch "answers", ((newVal, oldVal) ->
			if newVal
				$scope.editedNode.answers = $scope.answers
		), true

		$scope.newAnswer = () ->

			# We create the new node first, so we can grab the new node's generated id
			targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK

			newAnswer =
				text: null
				feedback: null
				target: targetId
				linkMode: $scope.NEW

			$scope.answers.push newAnswer

		$scope.removeAnswer = (index) ->

			# Grab node id of answer node to be removed
			targetId = $scope.answers[index].target

			# Remove it from answers array
			$scope.answers.splice index, 1

			# Remove the node from the tree
			treeSrv.findAndRemove $scope.treeData, targetId
			treeSrv.set $scope.treeData

			# If the node manager modal is open for this answer, close it
			if targetId is $scope.newNodeManager.target
				$scope.newNodeManager.show = false
				$scope.newNodeManager.target = null

		$scope.manageNewNode = ($event, target, mode) ->
			$scope.newNodeManager.x = $event.currentTarget.getBoundingClientRect().left
			$scope.newNodeManager.y = $event.currentTarget.getBoundingClientRect().top
			$scope.newNodeManager.linkMode = mode
			$scope.newNodeManager.target = target

Adventure.directive "newNodeManagerDialog", (treeSrv, $document) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		# Watch the newNodeManager target and kick off associated logic when it updates
		# Similar in functionality to the nodeTools dialog
		$scope.$watch "newNodeManager.target", (newVal, oldVal) ->
			if newVal isnt null
				$scope.newNodeManager.show = true

				xOffset = $scope.newNodeManager.x - 205
				yOffset = $scope.newNodeManager.y - 10

				styles =  "left: " + xOffset + "px; top: " + yOffset + "px"

				$attrs.$set "style", styles

		$scope.selectLinkMode = (mode) ->

			answer = {}

			# Grab the answer object that corresponds with the nodeManager's current target
			i = 0
			while i < $scope.answers.length
				if $scope.answers[i].target is $scope.newNodeManager.target then break
				else i++


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

					when "existing"

						# First, set the new answer's target to the selected node's target
						# This prevents the row from being removed

						## TEMP: ANSWER TARGET SHOULD BE SELECTED VIA GUI ##
						$scope.answers[i].target = $scope.editedNode.id - 1

						## HANDLE PRIOR LINK MODE: NEW
						if $scope.answers[i].linkMode is $scope.NEW

							# Scrub the existing child node associated with this answer
							childNode = treeSrv.findNode $scope.treeData, $scope.newNodeManager.target
							treeSrv.findAndRemove $scope.treeData, childNode.id

						## HANDLE PRIOR LINK MODE: SELF
						if $scope.answers[i].linkMode is $scope.SELF

							if $scope.editedNode.hasLinkToSelf
								delete $scope.editedNode.hasLinkToSelf

						# Set updated linkMode flags and redraw tree
						$scope.editedNode.hasLinkToOther = true
						$scope.answers[i].linkMode = $scope.EXISTING

						treeSrv.set $scope.treeData

						$scope.newNodeManager.linkMode = $scope.EXISTING
						console.log "New mode selected: EXISTING"

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

			$scope.newNodeManager.show = false
			$scope.newNodeManager.target = null

		# $scope.closeModal = () ->
		# 	console.log "Modal closed!"

		# 	$scope.newNodeManager.show = false
		# 	$scope.newNodeManager.target = null

