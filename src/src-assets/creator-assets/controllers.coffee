Adventure = angular.module "Adventure"
Adventure.controller "AdventureCtrl", ['$scope', '$filter', '$compile', '$rootScope', '$timeout', '$sce', '$sanitize', 'treeSrv', 'treeHistorySrv', 'legacyQsetSrv',($scope, $filter, $compile, $rootScope, $timeout, $sce, $sanitize, treeSrv, treeHistorySrv, legacyQsetSrv) ->
	materiaCallbacks = {}

	# Define constants for node screen types
	$scope.BLANK = "blank"
	$scope.MC = "mc"
	$scope.SHORTANS = "shortanswer"
	$scope.HOTSPOT = "hotspot"
	$scope.NARR = "narrative"
	$scope.END = "end"
	$scope.LINK = "link" # Probably not required

	# Define constants for the link mode types
	$scope.NEW = "new"
	$scope.EXISTING = "existing"
	$scope.SELF = "self"

	$scope.NORMAL = "Normal"
	$scope.NONSCORING = "Non-Scoring"

	$scope.scoreMode = $scope.NORMAL
	$scope.internalScoreMessage = ""
	$scope.showImportTypeSelection = false
	$scope.showImage = true
	$scope.urlError = '　'

	# Characters that need to be pre-sanitize before being run through angular's $sanitize directive
	PRESANITIZE_CHARACTERS =
		'>' : '&gt;',
		'<' : '&lt;'

	$scope.title = ""

	$scope.hidePlayerTitle = false

	# NodeTools is an object that holds the parameters for the nodeTools modal, works in tandem with the nodeToolsDialog directive
	$scope.nodeTools =
		show: false
		target: null
		type: null
		x: 0
		y: 0
		showResetWarning: false
		showDeleteWarning: false
		showConvertDialog: false

	# newNodeManager works like nodeTools, holds parameters of the newNodeManager modal and works w/ the directive
	$scope.newNodeManager =
		show: false
		target: null
		answerId: null # alphanumeric hash to identify the exact answer (target can be non-unique)
		x: 0
		y: 0
		linkMode: "new" # options should be "new" | "existing" | "self"

	# Parameters for the answer deletion confirmation dialog
	$scope.deleteDialog =
		show: false
		target: null
		targetIndex: null
		x: 0
		y: 0

	$scope.existingNodeSelectionMode = false
	$scope.existingNodeSelected = null

	$scope.copyNodeMode = false
	$scope.copyNodeTarget = null

	# This instantiation of treeData is required. It populates the "Start" node.
	$scope.treeData =
		name: "Start"
		type: "blank"
		id: 0
		parentId: -1
		contents: []

	# Since the entire tree SVG can be dragged around, we need to track the X & Y offsets representing where the SVG is positioned relative to "normal"
	# These offsets are applied to modals that depend on item locations within the SVG, e.g., the nodeTools dialog and answer-tooltips
	# This object is passed thru to the draggableTree directive when it's added to the tree-svg container that D3 generates
	$scope.treeOffset =
		x: 0
		y: 0
		moving: false
		scale: 1
		scaleXOffset: 0
		scaleYOffset: 0

	# The displayNodeCreation flag controls the visiblity of node creation screens
	$scope.displayNodeCreation = "none"
	# Scope reference for the node currently being edited in a creation screen, updates when displayNodeCreation changes
	$scope.editedNode = null

	$scope.hoveredNode =
		showTooltips: false
		target: null
		tooltips: [] # initially an empty array that's populated on-hover with the target's answerLinks array
		x: 0
		y: 0
		pendingHide: false

	$scope.hoveredLock =
		showItems: false
		target: null
		requiredItems: [] # initially an empty array that's populated on-hover with the answer's required items array
		x: 0
		y: 0
		pendingHide: false

	$scope.validation =
		show: false
		errors: []

	historyActions = treeHistorySrv.getActions()

	$scope.$watch "displayNodeCreation", (newVal, oldVal) ->
		
		# Returning from a suspended node creation screen, don't do anything
		if oldVal is "suspended" then return

		if newVal isnt oldVal and newVal isnt "none" and newVal isnt "suspended"
			$scope.editedNode = treeSrv.findNode $scope.treeData, $scope.nodeTools.target

			if newVal is $scope.END and $scope.editedNode.pendingTarget
				$scope.toast "Can't make an End Point! Move or remove child destinations first."
				$scope.displayNodeCreation = "none"
				return

			$scope.showCreationDialog = false
			if $scope.editedNode.type is $scope.BLANK then $scope.editedNode.type = $scope.displayNodeCreation

			# Inform the edit screens that the edited node has changed
			$rootScope.$broadcast "editedNode.target.changed"
		else if newVal is "suspended"
			$scope.newNodeManager.show = false
		else if newVal is "none"
			$scope.newNodeManager.show = false
			$scope.newNodeManager.target = null

			# start a timer that makes toasts obsolete after 5 seconds
			if $scope.showToast
				if $scope.toastRegister isnt null then $timeout.cancel $scope.toastRegister
				$scope.toastRegister = $timeout (() ->
					$scope.hideToast()
				), 5000

			# If node had a problem, assume user has addressed it and remove the hasProblems flag
			if $scope.editedNode and $scope.editedNode.hasProblem then delete $scope.editedNode.hasProblem

			# Refresh all answerLinks references as some have changed
			treeSrv.updateAllAnswerLinks $scope.treeData

			# Warn the user if a final score hasn't been set upon closing the creation screen
			# TODO there may be more post-creation-exit events required: condense these?
			if $scope.editedNode and $scope.editedNode.type is $scope.END
				if $scope.editedNode.finalScore is null
					$scope.toast "End Point " + $scope.editedNode.name + " is missing a valid final score!"
					$scope.editedNode.hasProblem = true

			# Run the question text through $sanitize to see if it contains invalid HTML
			# If so, warn the user
			if $scope.editedNode and $scope.editedNode.question
				try
					# Run question text thru pre-sanitize routine because $sanitize is fickle about certain characters like >, <
					presanitized = $scope.editedNode.question
					for k, v of PRESANITIZE_CHARACTERS
						presanitized = presanitized.replace k, v

					$sanitize presanitized
				catch e
					$scope.toast "WARNING! " + $scope.editedNode.name + "'s question contains malformed or dangerous HTML!"
					$scope.editedNode.hasProblem = true

			# Handy debugging statement here; keep it commented out unless necessary for testing
			# console.log $scope.editedNode

			# Redraw tree (again) to address any post-edit changes
			treeSrv.set $scope.treeData

			# prevents polluting the action history by comparing the current tree to to the latest snapshot
			# only add the current tree as a snapshot if the tree was actually edited
			if $scope.editedNode
				lastIndex = treeHistorySrv.getHistorySize() - 1
				if lastIndex is -1 then treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_EDITED, "Destination " + $scope.integerToLetters($scope.editedNode.id) + " edited"
				else
					peek = treeHistorySrv.retrieveSnapshot(lastIndex)
					unless treeHistorySrv.compareTrees(peek.tree, $scope.treeData) then treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_EDITED, "Destination " + $scope.integerToLetters($scope.editedNode.id) + " edited"


	$scope.hideCoverAndModals = ->
		$scope.showIntroDialog = false
		$scope.showBackgroundCover = false
		$scope.showInventoryBackgroundCover = false
		$scope.nodeTools.show = false
		$scope.showCreationDialog = false
		$scope.showDeleteWarning = false
		$scope.showTitleEditor = false
		$scope.validation.show = false
		$scope.showScoreModeDialog = false
		$scope.showImportTypeSelection = false
		$scope.showItemSelection = false
		$scope.showRequiredItems = false
		$scope.showItemManager = false
		$scope.showItemIconSelector = false
		$scope.editingIcons = false

		$scope.resetNewNodeManager()

		$scope.displayNodeCreation = "none"

	$scope.loadIcons = () ->
		return new Promise((resolve, reject) -> 
			xhr = new XMLHttpRequest()
			xhr.open("GET", "assets/icons.json", true)
			xhr.responseType = 'json'
			xhr.onload = () ->
				if xhr.status >= 200 && xhr.status < 300
					resolve(xhr.response)
				else
					reject({
						status: xhr.status,
						statusText: xhr.statusText
					})
			xhr.onerror = () ->
				reject({
					status: xhr.status,
					statusText: xhr.statusText
				})
			xhr.send()
		)

	$scope.initIcons = (customIcons = null) ->
		$scope.icons = []

		$scope.loadIcons().then((result) ->
			angular.forEach result.icons, (icon, index) ->
				$scope.icons[index] = {
					name: icon.name,
					url: "assets/icons/#{icon.name}"
				}
		).catch((err) ->
			console.log(err)
		)

		# Initialize the user's uploaded icons
		if customIcons
			for custom_icon in customIcons
				$scope.icons.push(custom_icon)

	materiaCallbacks.initNewWidget = (widget, baseUrl) ->
		$scope.$apply ->
			$scope.title = "My Adventure Widget"

			$scope.showIntroDialog = true
			$scope.showBackgroundCover = true

			$scope.initIcons()

			# Add default items?
			$scope.inventoryItems = []

			treeHistorySrv.addToHistory $scope.treeData, historyActions.WIDGET_INIT, "Widget Initialized"

	materiaCallbacks.initExistingWidget = (title,widget,qset,version,baseUrl) ->
		showIntroDialog = false

		if qset
			# Convert the old qset prior to using it
			if parseInt(version) is 1 then qset = JSON.parse legacyQsetSrv.convertOldQset qset

			$scope.$apply () ->
				$scope.title = title
				$scope.treeData = treeSrv.createTreeDataFromQset qset

				if qset.options.hidePlayerTitle then $scope.hidePlayerTitle = qset.options.hidePlayerTitle

				treeSrv.setInventoryItems qset.options.inventoryItems || []

				$scope.inventoryItems = qset.options.inventoryItems || []

				treeSrv.setCustomIcons qset.options.customIcons || []

				$scope.initIcons(qset.options.customIcons)

				# Optional qset parameters based on score mode
				if qset.options.scoreMode then $scope.scoreMode = qset.options.scoreMode
				if qset.options.internalScoreMessage then $scope.internalScoreMessage = qset.options.internalScoreMessage

				# Check to make sure the tree doesn't have errors
				validation = treeSrv.validateTreeOnStart $scope.treeData
				if validation.length
					$scope.validation.errors = validation
					$rootScope.$broadcast "validation.error"

				treeSrv.set $scope.treeData
				treeSrv.updateAllAnswerLinks $scope.treeData

				treeHistorySrv.addToHistory $scope.treeData, historyActions.EXISTING_WIDGET_INIT, "Existing Widget Initialized"

	materiaCallbacks.onSaveClicked = (mode = 'save') ->
		if mode is "publish" then validation = treeSrv.validateTreeOnSave $scope.treeData
		else validation = []

		# Run the tree validation when save is clicked
		# If errors are found, halt the save and bring up the validation dialog
		if validation.length
			$scope.validation.errors = validation
			$rootScope.$broadcast "validation.error"

			return Materia.CreatorCore.cancelSave ''
		else
			qset = treeSrv.createQSetFromTree $scope.treeData

			console.log(qset)

			qset.options.hidePlayerTitle = $scope.hidePlayerTitle
			qset.options.scoreMode = $scope.scoreMode
			qset.options.internalScoreMessage = $scope.internalScoreMessage
			qset.options.inventoryItems = treeSrv.getInventoryItems()
			qset.options.customIcons = treeSrv.getCustomIcons()
			console.log(qset)
			Materia.CreatorCore.save $scope.title, qset, 2

	materiaCallbacks.onSaveComplete = (title, widget, qset, version) -> true

	# onMediaImportComplete is required by the creator core
	# if editing a node, tie the media to that node
	# if editing icons, add the media to icons
	materiaCallbacks.onMediaImportComplete = (media) ->
		if $scope.editingIcons and $scope.currentItem
			newIcon =
				is_custom: true
				type: "image"
				url: Materia.CreatorCore.getMediaUrl media[0].id
				id: media[0].id
				alt: ""
			$scope.inventoryItems[$scope.inventoryItems.indexOf($scope.currentItem)].icon = newIcon
			$scope.icons.push(newIcon)
			treeSrv.setCustomIcons [
				...treeSrv.getCustomIcons(),
				newIcon
			]
			$scope.$apply()

		else if $scope.editedNode
			$scope.editedNode.media =
				type: "image"
				url: Materia.CreatorCore.getMediaUrl media[0].id
				id: media[0].id
				align: "right"
				alt: ""

			$scope.mediaReady = true
			$scope.showImage = true;

			$rootScope.$broadcast "editedNode.media.updated"


	# handles hover behavior of associated tooltips
	# (associated answer & validation warnings)
	$scope.onNodeHover = (data) ->
		# Required item tooltip
		if data.type is "lock"
			$scope.hoveredLock.pendingHide = false
			if $scope.hoveredLock.target isnt data.id

				$scope.$apply () ->
					$scope.hoveredLock.x = data.x
					$scope.hoveredLock.y = data.y
					$scope.hoveredLock.target = data.id
					$scope.hoveredLock.requiredItems = data.requiredItems
					$scope.hoveredLock.answer = data.answer
			return
		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return
		$scope.hoveredNode.pendingHide = false

		# Node tooltip
		if $scope.hoveredNode.target isnt data.id
			$scope.$apply () ->
				$scope.hoveredNode.x = data.x
				$scope.hoveredNode.y = data.y
				$scope.hoveredNode.target = data.id

	# Handles hover-out behavior of associated tooltips
	# Because hoverout can trigger quite often while mousing over node's dom elements, each time a hoverout happens, a pending flag is set
	# if the flag is reset by another hover event happening, don't hide the tooltip (cursor is still traveling over the node)
	# If it's not reset, go ahead and hide the tooltip
	$scope.onNodeHoverOut = (data) ->
		# Required item tooltip
		if data.type is "lock"
			if $scope.hoveredLock.target is data.id
				if $scope.hoveredLock.showItems is true
					$scope.hoveredLock.pendingHide = true
					$timeout (() ->
						if $scope.hoveredLock.pendingHide is true
							$scope.$apply () ->
								$scope.hoveredLock.showItems = false
								$scope.hoveredLock.target = null
					), 500
			else if $scope.hoveredLock.target isnt data.id
				$scope.hoveredLock.showItems = false
			return
		
		if data.type is "bridge" then return
		if $scope.existingNodeSelectionMode is true then return

		# Node tooltip
		if $scope.hoveredNode.target is data.id
			if $scope.hoveredNode.showTooltips is true
				$scope.hoveredNode.pendingHide = true
				$timeout (() ->
					if $scope.hoveredNode.pendingHide is true
						$scope.$apply () ->
							$scope.hoveredNode.showTooltips = false
							$scope.hoveredNode.target = null
				), 500
		else if $scope.hoveredNode.target isnt data.id
			$scope.hoveredNode.showTooltips = false

	# Controller recipient of the treeViz directive's onClick method
	# data contains the node object
	$scope.nodeSelected = (data) ->

		# If a bridge is clicked, automagically add a node to replace the bridge
		# Creates a node between the bridge link's parent and child
		if data.type is "bridge"
			$scope.addNodeInBetween data
			return

		# If we're in existingNodeSelectionMode, we need to listen for an existing node to be
		# selected to update an answer's target.
		if $scope.existingNodeSelectionMode
			$scope.$apply () ->
				$scope.existingNodeSelected = data
				$scope.existingNodeSelectionMode = false

		# Otherwise, if we're in copyNodeMode, the selected target is considered the copyNodeTarget
		# Kicks off the listener to complete the node copy mode
		else if $scope.copyNodeMode
			$scope.$apply () ->
				$scope.copyNodeTarget = data
				$scope.copyNodeMode = false

		else # Default selection behavior
			$scope.$apply () ->
				$scope.nodeTools.show = !$scope.nodeTools.show
				$scope.nodeTools.x = data.x
				$scope.nodeTools.y = data.y
				$scope.nodeTools.type = data.type
				# nodeTools refresh triggered by change in target property (see nodeToolsDialog directive)
				if $scope.nodeTools.show is false then $scope.nodeTools.target = null else $scope.nodeTools.target = data.id

				$scope.nodeTools.showResetWarning = false
				$scope.nodeTools.showDeleteWarning = false

	# Handles clicks in the negative space of the treeViz svg
	# Used to close the nodeTools popup, or whatever else is needed
	$scope.bgClicked = ->
		$scope.$apply () ->
			$scope.nodeTools.show = false

	# Function that pre-assembles a new node's data, adds it, then kicks off processes that have to happen afterwards
	# TODO this ought to be moved to treeSrv
	$scope.addNode = (parent, type) ->

		newId = treeSrv.getNodeCount()
		treeSrv.incrementNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: parent
			type: type
			contents: []
			items: []

		treeSrv.findAndAdd $scope.treeData, parent, newNode

		treeSrv.set $scope.treeData

		$scope.nodeTools.show = false
		$scope.nodeTools.target = null # forces nodeTools to refresh target data to account for change in parent Y

		# Sometimes getting the id of the newly created node is required, so return it
		newId

	# Function that explicitly adds a node between an existing parent and child
	$scope.addNodeInBetween = (data) ->

		newId = treeSrv.getNodeCount()
		newName = treeSrv.integerToLetters newId

		newNode =
			name: "#{newName}" # name: "Node #{count} (#{type})"
			id: newId
			parentId: data.source
			type: $scope.BLANK
			contents: []
			pendingTarget: data.target
			items: []

		if data.specialCase
			if data.specialCase is "otherNode"
				newNode.hasLinkToOther = true

		treeSrv.findAndAddInBetween $scope.treeData, data.source, data.target, newNode

		treeSrv.incrementNodeCount()
		treeSrv.set $scope.treeData

		treeSrv.updateAllAnswerLinks $scope.treeData

		treeHistorySrv.addToHistory $scope.treeData, historyActions.NODE_ADDED_IN_BETWEEN, "Destination created between " + treeSrv.integerToLetters(data.source) + " and " + treeSrv.integerToLetters(data.target)


	# Reference function so the integerToLetters function from treeSrv can be called using two-way data binding
	$scope.integerToLetters = (val) ->
		return treeSrv.integerToLetters(val)

	$scope.generateDebugQset = ->
		qset = treeSrv.createQSetFromTree $scope.treeData
		qset.options.hidePlayerTitle = $scope.hidePlayerTitle
		qset.options.scoreMode = $scope.scoreMode
		qset.options.internalScoreMessage = $scope.internalScoreMessage
		qset.options.inventoryItems = treeSrv.getInventoryItems()
		qset.options.customIcons = treeSrv.getCustomIcons()

		$scope.showQsetGenerator = true
		$scope.generatedQset = JSON.stringify qset, null, 2


	# Start 'er up!
	Materia.CreatorCore.start materiaCallbacks

]
