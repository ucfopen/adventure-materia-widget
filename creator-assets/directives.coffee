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
		# hideToast() is automatically called when editedNode is reset, when a node creation interface is closed
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

Adventure.directive "treeVisualization", (treeSrv) ->
	restrict: "E",
	scope: {
		data: "=", # binds treeData in a way that's accessible to the directive
		onClick: "&" # binds a listener so the controller can access the directive's click data
	},
	link: ($scope, $element, $attrs) ->

		$scope.svg = null

		# Re-render tree whenever the nodes are updated
		$scope.$on "tree.nodes.changed", (evt) ->
			$scope.render treeSrv.get()

		$scope.render = (data) ->

			unless data? then return false

			# Modify height of tree based on max depth
			# Keeps initial tree from being absurdly sized
			depth = treeSrv.getMaxDepth()
			adjustedHeight = 200 + (depth * 50)

			# Compute SVG width based on window width
			windowWidth = document.getElementById("adventure-container").offsetWidth

			# Init tree data
			tree = d3.layout.tree()
				.sort(null)
				.size([windowWidth, adjustedHeight]) # sets size of tree
				.children (d) -> # defines accessor function for nodes (e.g., what the "d" object is)
					if !d.contents or d.contents.length is 0 then return null
					else return d.contents

			nodes = tree.nodes data # Setup nodes
			links = tree.links nodes # Setup links
			adjustedLinks = [] # Finalized links array that includes "special" links (loopbacks and bridges)

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

				# if link.specialCase is "otherNode"
				# 	source = link.source
				# 	target = link.target
				# 	intermediate =
				# 		x: source.x + (target.x - source.x)/2
				# 		y: (source.y + (target.y - source.y)/2) + 25
				# 		type: "bridge"

				# 	adjustedLinks.push {source: source, target: intermediate}, {source: intermediate, target: target}

				# else if link.specialCase is "loopBack"

				# 	intermediate =
				# 		x: link.source.x + 75
				# 		y: link.source.y + 75
				# 		type: "bridge"

				# 	adjustedLinks.push link

				# else
				source = link.source
				target = link.target
				intermediate =
					x: source.x + (target.x - source.x)/2
					y: source.y + (target.y - source.y)/2
					type: "bridge"
					source: link.source.id
					target: link.target.id

				# adjustedLinks.push link

				nodes.push intermediate

			# Render tree
			if $scope.svg == null
				$scope.svg = d3.select($element[0])
					.append("svg:svg")
					.attr("width", windowWidth) # Size of actual SVG container
					.attr("height",650) # Size of actual SVG container
					.append("svg:g")
					.attr("class", "container")
					.attr("transform", "translate(0,50)") # translates position of overall tree in svg container
			else
				$scope.svg.selectAll("*").remove()

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
			lineData = (d) ->
				points = [
					{lx: d.source.x, ly: d.source.y},
					{lx: d.target.x, ly: d.target.y}
				]

				link(points)

			# link = d3.svg.diagonal (d) ->
			# 	return [d.x, d.y]

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

			linkGroup.append("svg:path")
				.attr("class", "link")
				.attr("marker-end", "url(#arrowhead)")
				.attr("d", lineData)

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
				# .attr("class", "node")
				.attr("class", (d) ->
					if d.type is "bridge" then return "bridge"
					else return "node #{d.type}"
				)
				.on("mouseover", (d, i) ->

					# if d.type is "bridge" then return

					#  Animation effects on node mouseover
					d3.select(this).select("circle")
					.transition()
					.attr("r", 30)

					# d3.select(this).select("text")
					# .text( (d) ->
					# 	d.name + " (Click to Edit)"
					# )
					# .transition()
					# .attr("x", 10)
				)
				.on("mouseout", (d, i) ->

					# if d.type is "bridge" then return

					# Animation effects on node mouseout
					d3.select(this).select("circle")
					.transition()
					.attr("r", 20)

					d3.select(this).select("text")
					.text( (d) ->
						d.name
					)
					# .transition()
					# .attr("x", 0)
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
					return 20 # sets size of node bubbles
					# if d.type is "bridge" then return 20
					# else return 20
				)
				.attr("filter", "url(#dropshadow)")

			nodeGroup.append("svg:rect")
				.attr("width", (d) ->
					if d.name then return 10 * d.name.length
					else return 0
				)
				.attr("height", 16)
				.attr("x", -10)
				.attr("y", -8)

			nodeGroup.append("svg:text")
				.attr("text-anchor", (d) ->
					return "start" # sets horizontal alignment of text anchor
					# if d.children then return "end"
					# else return "start"
				)
				.attr("dx", (d) ->
					if d.name
						if d.name.length > 1 then return -10
						else return -5
					else return 0
				)

				# sets X label offset from node (negative left, positive right side)
				# .attr("dx", (d) ->
				# 	# if d.children then return -gap
				# 	# else return gap
				# )

				.attr("dy", 5) # sets Y label offset from node
				.attr("font-family", "Lato")
				.attr("font-size", 16)
				.text (d) ->
					d.name

			nodeGroup.append("path")
				.attr("d", "M -3,12 L -3,3 L -12,3 L -12,-3 L -3,-3 L -3,-12 L 3,-12 L 3,-3 L 12,-3 L 12,3 L 3,3 L 3,12 Z")
				.attr("visibility", (d) ->
					if d.type isnt "bridge" then return "hidden"
				)

		$scope.render treeSrv.get()

Adventure.directive "titleEditor", () ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->

		$scope.$watch "showTitleEditor", (newVal, oldVal) ->
			if newVal
				$scope.showBackgroundCover = true

# Directive for the node modal dialog (add child, delete node, etc)
Adventure.directive "nodeToolsDialog", (treeSrv) ->
	restrict: "E",
	link: ($scope, $element, $attrs) ->
		# When target for the dialog changes, update the position values based on where the new node is
		$scope.$watch "nodeTools.target", (newVals, oldVals) ->

			xOffset = $scope.nodeTools.x + 15
			yOffset = $scope.nodeTools.y + 50

			styles = "left: " + xOffset + "px; top: " + yOffset + "px"

			$attrs.$set "style", styles

		$scope.copyNode = () ->
			console.log "Copying NYI!"


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

			$scope.newNodeManager.show = false

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
					if $scope.editedNode.type isnt $scope.END and $scope.editedNode.type isnt $scope.HOTSPOT
						$scope.answers = []
						$scope.newAnswer()

					else if $scope.editedNode.type is $scope.HOTSPOT
						$scope.answers = []
					else
						# Manually redraw tree to reflect status change as end type node
						treeSrv.set $scope.treeData

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

		$scope.newAnswer = () ->

			# If the editedNode has a pending target, the new answer's target will be set to it
			# pendingTarget is used for adding in-between nodes or linking orphaned nodes
			if $scope.editedNode.pendingTarget
				targetId = $scope.editedNode.pendingTarget
				delete $scope.editedNode.pendingTarget
			else
				# We create the new node first, so we can grab the new node's generated id
				targetId = $scope.addNode $scope.editedNode.id, $scope.BLANK

			newAnswer =
				text: null
				feedback: null
				target: targetId
				linkMode: $scope.NEW

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

			console.log "targetNode has " + targetNode.contents.length + " content nodes!"

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

# Directive for each short answer set. Contains logic for adding and removing individual answer matches.
Adventure.directive "shortAnswerSet", (treeSrv) ->
	restrict: "A",
	link: ($scope, $element, $attrs) ->

		$scope.addAnswerMatch = (index) ->

			# Don't do anything if there isn't anything actually submitted
			unless $scope.newMatch.length then return

			# first check to see if the entry already exists
			i = 0

			unless $scope.answers[index].matches.length
				$scope.answers[index].matches.push $scope.newMatch
				$scope.newMatch = ""
				return

			while i < $scope.answers[index].matches.length

				matchTo = $scope.answers[index].matches[i].toLowerCase()

				if matchTo.localeCompare($scope.newMatch.toLowerCase()) is 0
					$scope.toast "This match already exists!"
					return

				i++

			$scope.answers[index].matches.push $scope.newMatch
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

