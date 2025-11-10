from core.models import Log
from scoring.module import ScoreModule


class Adventure(ScoreModule):

    def __init__(self, play):
        super().__init__(play)
        options = self.qset.get("options", {})
        if isinstance(options, dict):
            self.scoreMode = options.get("scoreMode", "Normal")
        else:
            self.scoreMode = "Normal"

    def check_answer(self, log):
        if log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:

            if self.scoreMode == "Non-Scoring":
                return 100

            for question in self.questions:

                if (
                    question.data.get("options").get("type") != "end" and
                    int(question.data.get("options").get("type")) != 5
                ):
                    continue

                if log.item_id:

                    if int(log.item_id) == int(
                        question.data.get("options")
                        .get("id")
                    ):
                        return int(
                            question.data.get("options")
                            .get("finalScore", 0)
                        )

                else:
                    if (
                        log.text == question.data
                        .get("questions")[0]
                        .get("text", "")
                    ):
                        return int(
                            question.data.get("options")
                            .get("finalScore")
                        )

        else:
            return -1

    def handle_log_question_answered(self, log):
        pass

    def handle_log_client_final_score(self, log):
        self.verified_score = 0
        self.total_questions = 0
        val = self.check_answer(log)
        self.global_modifiers.append(val)

    def calculate_score(self):
        points = self.verified_score + sum(self.global_modifiers)
        self.calculated_percent = round(points)
        if self.calculated_percent < 0:
            self.calculated_percent = 0
        if self.calculated_percent > 100:
            self.calculated_percent = 100

    def details_for_question_answered(self, log):
        question = self.get_question_by_item_id(log.item_id)
        score = self.check_answer(log)

        return {
            "id": log.item_id,
            "data": [
                self.get_ss_question(log, question),
                self.get_ss_answer(log, question),
                log.value,
            ],
            "data_style": ["question", "response"],
            "score": score,
            "feedback": None,
            "type": log.log_type,
            "style": self.get_detail_style(score),
            "symbol": "%",
            "graphic": "score",
            "display_score": False,
        }

    def get_score_details(self):

        details = []

        blank_node_str = ("Blank Destination! Be sure to edit "
                          "or remove this node before publishing.")

        for log in self.logs:

            if log.log_type == Log.LogType.SCORE_QUESTION_ANSWERED:
                question = self.get_question_by_item_id(log.item_id)
                if question is None:
                    break

                details.append(self.details_for_question_answered(log))

            elif log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:
                details.append({
                    "node_id": log.item_id,
                    "data": [log.text, self.check_answer(log)],
                    "data_style": ["text", "score"],
                    "score": self.check_answer(log),
                    "type": log.log_type,
                    "style": "final_score",
                    "symbol": "%",
                    "graphic": "score",
                    "display_score": False,
                    "older_qset": (
                        log.item_id == 0 and log.text != blank_node_str
                    ),
                    "blank_node": (
                        log.item_id == 0 and log.text == blank_node_str
                    ),
                })

        return [
            {
                "title": self._ss_table_title,
                "header": ['Question Score', 'The Question', 'Your Response'],
                "table": details,
            }
        ]
