<?php

return [
	'Survey Formatting' => function($inst, $semesters_string)
	{
		$results = []

		foreach ($semesters_string as $semester)
		{
			list($year, $term) = explode('-', $semester);

			// Get all scores for each semester
			$logs = $play_logs["{$year} {$term}"] = \Materia\Session_Play::get_by_inst_id($inst->id, $term, $year);

			foreach ($logs as $play)
			{
				// Only report actual user scores, no guests
				if ( ! empty($play['username']))
				{
					if ( ! isset($results[$])) $results[$u] = [];

					$play_events = \Materia\Session_Logger::get_logs($play['id']);
					foreach ($play_events as $play_event)
					{
						$r               = [];
						$r['last_name']  = $play['last'];
						$r['first_name'] = $play['first'];
						$r['playid']     = $play['id'];
						$r['semester']   = $semester;
						$r['type']       = $play_event->type;
						$r['item_id']    = $play_event->item_id;
						$r['text']       = $play_event->text;
						$r['value']      = $play_event->value;
						$r['game_time']  = $play_event->game_time;
						$r['created_at'] = $play_event->created_at;
						$results[$u][]   = $r;
					}
				}
			}

			if ( ! count($results)) return false;

			# Gotta grab the questions
			$inst->get_qset($inst->id);
			$questions = \Materia\Widget_Instance::find_questions($inst->qset->data);

			# Legacy QSets follow the inane [items][items] scheme
			if (isset($questions[0]) && isset($questions[0]['items']))
			{
				$questions = $questions[0]['items'];
			}

			$csv = "User ID, Last Name, First Name, Semester, Game Time,";
			$question_columns = [];

			# Build an array out of all possible questions. Note that not all columns will have an associated response
			foreach ($quesions as $question)
			{
				# TODO: build string of column names based on each question (first X chars of question?), gets appended to $csv var
				# TODO: build array of question IDs to match to log item IDs
			}

			foreach ($results as $userid => $userlog)
			{
				# TODO: create csv row using user data + user responses to each question in question array
				# example: last name, first name, semester, game time, [first response...last response]

				# So create first part of row here using user data

				foreach ($userlog as $r)
				{
					# Append each response to the row here
					# If a response is logged for the same question TWICE, use the last response?
				}
			}

			# return the csv file

			return [$csv, ".csv"];
		}
	},
];
