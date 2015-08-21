Adventure = angular.module "Adventure"
Adventure.service "legacyQsetSrv", () ->

	legacyScaleFactor = null
	imageOffsetX = null

	# Converts the QSets used by Adventure 1.0 (the flash version) to ones usable by the Adventure 2.0 creator & player
	# If used by the creator, once the widget is re-saved, it'll be saved as an Adventure 2.0 Qset and this won' be needed again for that instance
	# If used by the player, no manipulation is made to the actual QSet, so it must be referenced every time the 1.0 QSet is loaded
	# Because the requirements of the player & creator are nearly identical, the QSet conversion code is located in its own independent service that's imported by both
	convertOldQset = (qset) ->

		items = qset.items[0].items

		parentNodeRefs = []
		nodeCount = 0

		angular.forEach items, (item, index) ->

			item.type = "Adventure"
			item.nodeId = item.options.id

			delete item.assets

			switch item.options.type
				when 1 then item.options.type = "narrative"
				when 2 then item.options.type = "mc"
				when 3 then item.options.type = "hotspot"
				when 4 then item.options.type = "shortanswer"
				when 5 then item.options.type = "end"
				else item.options.type = "blank"

			# TODO still need a catch for -1, e.g., blank

			if item.options.asset
				switch item.options.layout
					when 0 then item.options.asset.align = "image-only"
					when 1 then item.options.asset.align = "text-only"
					when 2 then item.options.asset.align = "right"
					when 3 then item.options.asset.align = "left"
					when 4 then item.options.asset.align = "bottom"
					when 5 then item.options.asset.align = "top"

				unless item.options.layout then item.options.asset.align = "right"
				else delete item.options.layout

				item.options.asset.type ="image"

			if item.options.type is "hotspot"

				item.options.asset.align = "right" # Override asset align
				item.options.legacyScaleMode = true

				switch item.options.visibility
					when 0 then item.options.visibility = "always"
					when 1 then item.options.visibility = "mouseover"
					when 2 then item.options.visibility = "never"
					else item.options.visibility = "always"

			angular.forEach item.answers, (answer, index) ->

				if answer.options.isShortcut and answer.options.link isnt item.options.id
					answer.options.linkMode = "existing"
					item.options.hasLinkToOther = true

					delete answer.options.isShortcut

				else if answer.options.isShortcut and answer.options.link is item.options.id
					answer.options.linkMode = "self"
					item.options.hasLinkToSelf = true

					delete answer.options.isShortcut
				else
					answer.options.linkMode = "new"
					parentNodeRefs[answer.options.link] = item.options.id

				if item.options.type is "shortanswer"
					answer.options.matches = []
					if answer.options.isDefault then answer.text = "[Unmatched Response]"
					else answer.options.matches = answer.text.split ", "

				if answer.options.hotspot

					type = parseInt answer.options.hotspot.substring(0,1)

					answer.options.svg = {}

					switch type
						when 0 # ellipse
							values = answer.options.hotspot.split(",")

							answer.options.svg.type = "ellipse"
							answer.options.svg.x = Math.round values[0].substring(1)
							answer.options.svg.y = Math.round values[1]

							# Normally ellipses start as a circle, where the radius is preset to a default
							# Then the scaleFactor describes changes in rx or ry
							# Here, we cheat and set the radius to the X diameter (values[2])
							# Then set the scaleYFactor to the difference between the X radius & Y radius

							answer.options.svg.r = values[2]/2

							answer.options.svg.scaleXOffset = 0
							answer.options.svg.scaleYOffset = 0
							answer.options.svg.scaleXFactor = 0
							answer.options.svg.scaleYFactor = (values[3] - values[2])/2

						when 2 # rectangle
							values = answer.options.hotspot.split(",")

							answer.options.svg.type = "rect"
							answer.options.svg.x = Math.round values[0].substring(1)
							answer.options.svg.y = Math.round values[1]
							answer.options.svg.width = Math.round values[2]
							answer.options.svg.height = Math.round values[3]
							answer.options.svg.scaleXOffset = 90
							answer.options.svg.scaleYOffset = 65
							answer.options.svg.scaleXFactor = 0
							answer.options.svg.scaleYFactor = 0

						when 1 # polygon
							pattern = /(?:\(x=)(-?[0-9]+\.*[0-9]*)(?:\,[ ]?y=)([0-9]+\.*[0-9]*)/g
							string = answer.options.hotspot.substring 1
							match = pattern.exec string

							coords = ""
							coords += match[1] + "," + match[2] + " "

							while match = pattern.exec string
								coords += match[1] + "," + match[2] + " "

							answer.options.svg.type = "polygon"
							answer.options.svg.stroke = 2
							answer.options.svg.x = 0
							answer.options.svg.y = 0
							answer.options.svg.points = coords

					answer.options.svg.stroke = 2
					unless answer.options.hotspotColor then answer.options.svg.fill = "#7698e2"
					else answer.options.svg.fill = "#" + answer.options.hotspotColor

					delete answer.options.hotspot

			nodeCount++

		angular.forEach items, (item, index) ->
			if parentNodeRefs[item.options.id] isnt undefined then item.options.parentId = parentNodeRefs[item.options.id]
			else if item.options.id is 0 then item.options.parentId = -1

		newQset =
			items: items
			options:
				nodeCount: nodeCount

		console.log newQset

		return JSON.stringify newQset

	# Since Adventure 1.0 QSets scaled the hotspot coordinates to the image's original dimensions, have to transform hotspot properties here
	# The image has to actually be loaded to find the original dimensions and use them to compute the "scale factor",
	# the size ratio of the scaled version relative to the original.
	# To anyone having to use this in the future... I'm so sorry.
	handleLegacyScale = (answers, image) ->
		MAX_WIDTH = 698
		MAX_HEIGHT = 400

		# Compute the scale factor using the original image dimensions vs. the hotspot container dimensions
		legacyScaleFactor = if legacyScaleFactor > 1 then 1 else MAX_HEIGHT / image.height

		# In addition to the scale factor, hotspots have to be translated to account for the image's location
		# Centered within the hotspot container
		imageOffsetX = (MAX_WIDTH / 2) - ((image.width * legacyScaleFactor)/ 2)

		angular.forEach answers, (answer, index) ->

			# The answer object is slightly different depending on whether this function is referenced from the creator or player
			# Creator answer objects have the SVG as a first-level child of the answer object
			# Player answer objects are copied direct from the Qset, so the SVG is nested in the options object of the answer object
			if answer.options then convertSVGValues answer.options.svg
			else convertSVGValues answer.svg

	convertSVGValues = (svg) ->

		switch svg.type

			when "ellipse"
				# yeah this looks insane
				# X has to be transformed by the scale factor, in addition to the X offset (to account for image being centered), as well as the fact that ellipses' X & Y origins are in the center
				svg.x = Math.floor( (svg.x * legacyScaleFactor) + imageOffsetX + (svg.r * legacyScaleFactor))
				svg.y = Math.floor( svg.y * legacyScaleFactor + (svg.r + svg.scaleYFactor) * legacyScaleFactor)
				svg.r = Math.floor(svg.r * legacyScaleFactor)

				svg.scaleYFactor = Math.floor(svg.scaleYFactor * legacyScaleFactor)
				svg.scaleXOffset = svg.r * 0.8
				svg.scaleYOffset = svg.r * 0.8

			when "rect"

				svg.x = Math.floor((svg.x * legacyScaleFactor) + imageOffsetX)
				svg.y = Math.floor(svg.y * legacyScaleFactor)
				svg.width = Math.floor(svg.width * legacyScaleFactor)
				svg.height = Math.floor(svg.height * legacyScaleFactor)

				svg.scaleXOffset = svg.width - 10
				svg.scaleYOffset = svg.height - 10

			when "polygon"

				# Each individual point needs to be adjusted by the legacyScaleFactor, and X values offset to be properly centered
				adjustedPoints = ""
				pairs = svg.points.split " "
				i = 0
				for point in pairs
					unless point.length then continue

					points = point.split ","

					adjustedX = Math.floor(parseInt(points[0]) * legacyScaleFactor + imageOffsetX)
					adjustedY = Math.floor parseInt(points[1]) * legacyScaleFactor

					adjustedPoints += adjustedX + "," + adjustedY + " "
					i++

					svg.points = adjustedPoints

	convertOldQset : convertOldQset
	handleLegacyScale : handleLegacyScale