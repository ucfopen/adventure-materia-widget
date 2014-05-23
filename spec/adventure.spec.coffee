# Specs are imported by and run in the test environment
# by Materia's spec/materia.spec.coffee

module.exports = (client) ->
	describe 'Intro page', ->
		it 'should show narration', (done) ->
			client
				.waitFor '.text', 5000
				.getText '.text', (err, text) ->
					expect(err).toBeNull()
					expect(text).toContain "You're a nurse working in the Emergency Room"
				.call(done)
		it 'should have an image asset', (done) ->
			client
				.waitFor 'figure img', 5000
				.call(done)
		it 'should be able to advance to the next page', (done) ->
			client
				.waitFor 'input[type=button]', 5000
				.execute "$('input[type=button]').click()", null, (err) ->
					expect(err).toBeNull()
					client.call(done)
	describe 'Second page', ->
		it 'should show a question', (done) ->
			client
				.waitFor '.text', 5000
				.getText '.text', (err, text) ->
					expect(err).toBeNull()
					expect(text).toContain "After reviewing the patient's chart"
				.call(done)
		it 'should show a dialog when choosing coffee', (done) ->
			client
				.execute "$('.answer[data-index=0]').click()", null, (err) ->
					client
						.waitFor '.feedback.show', 5000
						.getText '.feedback.show', (err, text) ->
							expect(err).toBeNull()
							expect(text).toContain "While a nice thing to do"
						.call(done)
		it 'should be able to close the feedback dialog', (done) ->
			client
				.waitFor '.feedback input', 5000
				.execute "$('.feedback input').click()", null, (err) ->
					expect(err).toBeNull()
					client
						.call(done)
		it 'should be able to choose to interview the mom', (done) ->
			client
				.execute "$('.answer[data-link=3]').click()", null, (err) ->
					expect(err).toBeNull()
					client
						.call(done)
	describe 'Third page', ->
		it 'should show a question', (done) ->
			client
				.waitFor '.text', 5000
				.getText '.text', (err, text) ->
					expect(err).toBeNull()
					expect(text).toContain "You collect the results of your examination"
				.call(done)
		it 'should be able to advance to the next page', (done) ->
			client
				.waitFor 'input[type=button]', 5000
				.execute "$('input[type=button]').click()", null, (err) ->
					expect(err).toBeNull()
					client.call(done)


