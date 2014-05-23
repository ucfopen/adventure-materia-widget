# Specs are imported by and run in the test environment
# by Materia's spec/materia.spec.coffee

client = {}

describe 'Testing framework', ->
	it 'should load widget', (done) ->
		require('./widgets.coffee') 'adventure', ->
			client = this
			done()
	,15000

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
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)
describe 'Fourth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "After reviewing your findings"
			.call(done)
	it 'should be able to choose influenza', (done) ->
		client
			.execute "$('.answer[data-link=7]').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
describe 'Fifth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "Your next step is to contact"
			.call(done)
	it 'should be able to input "nurse practitioner"', (done) ->
		client
			.waitFor '.short-answer'
			.setValue '.short-answer', 'nurse practitioner'
			.execute "$('.sa .trans-button').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
	it 'should give full credit and feedback', (done) ->
		client
			.waitFor '.feedback.show'
			.getText '.feedback.show', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("Correct")
				client.call(done)
	it 'should be able to close the feedback dialog', (done) ->
		client
			.waitFor '.feedback input', 5000
			.execute "$('.feedback input').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
describe 'Sixth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "After reviewing the child's symptoms"
			.call(done)
	it 'should be able to advance to the next page', (done) ->
		client
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)
describe 'Seventh page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "Which part of the chart do you think"
			.call(done)
	it 'should be able to choose lethargia', (done) ->
		client
			.waitFor 'path', 5000
			.execute "$('path:eq(1)').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)
describe 'Eighth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "While lethargy is also a sign"
			.call(done)
	it 'should be able to advance to the next page', (done) ->
		client
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)
describe 'Ninth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "After reviewing your findings"
			.call(done)
	it 'should be able to choose dehydration', (done) ->
		client
			.execute "$('.answer[data-link=6]').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
describe 'Tenth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "Your next step is to contact"
			.call(done)
	it 'should be able to input "nurse"', (done) ->
		client
			.waitFor '.short-answer'
			.setValue '.short-answer', 'nurse'
			.execute "$('.sa .trans-button').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
	it 'should get it wrong', (done) ->
		client
			.waitFor '.feedback.show'
			.getText '.feedback.show', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("Incorrect")
				client.call(done)
	it 'should be able to close the feedback dialog', (done) ->
		client
			.waitFor '.feedback input', 5000
			.execute "$('.feedback input').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)

describe 'Eleventh page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "You're ready to contact"
			.call(done)
	it 'should be able to choose diarrhea', (done) ->
		client
			.execute "$('.answer[data-link=10]').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
	it 'should get feedback', (done) ->
		client
			.waitFor '.feedback.show'
			.getText '.feedback.show', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("Correct")
				client.call(done)
	it 'should be able to close the feedback dialog', (done) ->
		client
			.waitFor '.feedback input', 5000
			.execute "$('.feedback input').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)

describe 'Twelfth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "The Healthcare Provider has returned"
			.call(done)
	it 'should be able to advance to the next page', (done) ->
		client
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)

describe 'Thirteenth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "greatly improved"
			.call(done)
	it 'should be able to choose to leave immediately', (done) ->
		client
			.execute "$('.answer[data-link=13]').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)
	it 'should get feedback', (done) ->
		client
			.waitFor '.feedback.show'
			.getText '.feedback.show', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain("Not quite!")
				client.call(done)
	it 'should be able to close the feedback dialog', (done) ->
		client
			.waitFor '.feedback input', 5000
			.execute "$('.feedback input').click()", null, (err) ->
				expect(err).toBeNull()
				client
					.call(done)

describe 'Fourteenth page', ->
	it 'should show a question', (done) ->
		client
			.waitFor '.text', 5000
			.getText '.text', (err, text) ->
				expect(err).toBeNull()
				expect(text).toContain "Great work!"
			.call(done)
	it 'should be able to advance to the next page', (done) ->
		client
			.waitFor '.trans input', 5000
			.execute "$('.trans input').click()", null, (err) ->
				expect(err).toBeNull()
				client.call(done)

describe 'Score page', ->
	it 'should get a 90', (done) ->
		client.pause(2000)
		client.getTitle (err, title) ->
			expect(err).toBeNull()
			expect(title).toBe('Score Results | Materia')
			client
				.waitFor('.overall_score')
				.getText '.overall_score', (err, text) ->
					expect(err).toBeNull()
					expect(text).toBe('90%')
					client.call(done)
					client.end()

