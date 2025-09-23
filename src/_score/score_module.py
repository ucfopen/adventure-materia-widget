from core.models import Log
from scoring.module import ScoreModule

class Adventure(ScoreModule):

    #helpter methods to assist v1 and v2 qset handling
    def _qset_dict(self):
        q = getattr(self.qset, "data", self.qset)
        if isinstance(q, list):
            q = next((x for x in q if isinstance(x, dict)), {})
        return q if isinstance(q, dict) else {}

    def _iter_nodes(self, items):
        stack = list(items or [])
        while stack:
            it = stack.pop()
            if not isinstance(it, dict):
                continue
            if "items" in it and not any(k in it for k in ("type", "questions", "answers")):
                kids = it.get("items") or []
                if isinstance(kids, list):
                    stack.extend(kids)
                continue
            yield it

    def _items_list(self):
        q = self._qset_dict()
        if q.get("version") == 1:
            lst = q.get("items") or []
            return (lst[0].get("items") or []) if lst and isinstance(lst[0], dict) else []
        return q.get("items") or []

    def _match_end_node(self, log):
        for item in self._iter_nodes(self._items_list()):
            opts = item.get("options") or {}
            if not isinstance(opts, dict):
                continue
            is_end = (opts.get("type") in ("end", "5")) or ("finalScore" in opts)
            if not is_end:
                continue
            if getattr(log, "item_id", None) and log.item_id == opts.get("id"):
                return item
            if not getattr(log, "item_id", None):
                #for older qsets match with text
                qs = item.get("questions") or []
                q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
                if (getattr(log, "text", "") or "").strip() == (q0.get("text", "") or "").strip():
                    return item
        return None

    def _final_text_for_log(self, log):
        node = self._match_end_node(log)
        if node:
            qs = node.get("questions") or []
            q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
            return (q0.get("text", "") or "").strip()
        return (getattr(log, "text", "") or "").strip()


    def __init__(self, play):
        super().__init__(play)
        raw_qset = getattr(self.qset, "data", self.qset)

        if isinstance(raw_qset, list):
            #sometimes it is not a dict in the demo
            raw = raw[0] if raw and isinstance(raw[0], dict) else {}

        self.scoreMode = (self.qset.get("options") or {}).get("scoreMode", "Normal")

        self._ss_table_title = "Responses:"
        self._ss_table_headers = ["Question Score", "The Question", "Your Response"]

    #looks complicated, attempts to match php check answer where
    #it rebuilds the path after getting the end node and assigning -1 to everything else
    def check_answer(self, log):
        if self.scoreMode == "Normal":
            if getattr(log, "log_type", None) != Log.LogType.SCORE_FINAL_FROM_CLIENT:
                print("not a final score log so we return -1 and early")
                return -1

            qset_data = getattr(self.qset, "data", self.qset)
            if isinstance(qset_data, list):
                qset_data = next((x for x in qset_data if isinstance(x, dict)), {})
            #v1 vs v2
            if qset_data.get("version") == 1:
                items_list = qset_data.get('items', [])
                items = (items_list[0].get('items', []) if items_list and isinstance(items_list[0], dict) else [])
            else:
                items = qset_data.get('items', [])

            if (isinstance(items, list) and items and isinstance(items[0], dict)
                    and "items" in items[0] and not any(k in items[0] for k in ("type", "questions", "answers"))):
                items = items[0].get("items", [])

            for item in items:
                if not isinstance(item, dict):
                    continue
                opts = item.get("options") or {}
                if not isinstance(opts, dict):
                    continue
                if opts.get('type') not in ('end', '5'):
                    continue

                if log.item_id:
                    if log.item_id == opts.get('id'):
                        return 100 if self.scoreMode == 'Non-Scoring' else int(opts.get('finalScore', 0))
                else:
                    qs = item.get('questions') or []
                    q0 = qs[0] if qs and isinstance(qs[0], dict) else {}
                    if (log.text or "").strip() == (q0.get('text', "") or "").strip():
                        return 100 if self.scoreMode == 'Non-Scoring' else int(opts.get('finalScore', 0))

            return int(getattr(log, "value", 0))


    #need to ignore this method
    def handle_log_question_answered(self, log):
        pass

    def handle_log_client_final_score(self, log) -> None:
        self.verified_score = 0
        self.total_questions = 0
        print(f"we are checking answer for log: {log} and log type is {log.log_type}")
        final_val = self.check_answer(log)
        self.global_modifiers.append(final_val)

    def calculate_score(self):
        #php does verified + sum(modifiers) then round and clamp
        points = self.verified_score + sum(self.global_modifiers)
        self.calculated_percent = round(points)
        if self.calculated_percent < 0:
            self.calculated_percent = 0
        if self.calculated_percent > 100:
            self.calculated_percent = 100


    def get_score_overview(self):
        return {
            "complete": getattr(self.play, "is_complete", False),
            "score": self.calculated_percent,
            "table": self.get_overview_items(),
            "referrer_url": "",
            "created_at": "",
            "auth": "",
        }



    def details_for_question_answered(self, log):
        question = self.get_question_by_item_id(log.item_id)
        if not isinstance(question, dict):
            return None

        answers = question.get("answers") or []
        if not isinstance(answers, list):
            answers = []

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
            "feedback": self.get_feedback(log, answers),
            "type": log.log_type,
            "style": self.get_detail_style(score),
            "symbol": "%",
            "graphic": "score",
            "display_score": False,
        }


    def get_score_details(self):
        details_rows = []

        for log in self.logs:
            print(f"our log is {log} and the log type is {log.log_type}")
            if log.log_type == Log.LogType.SCORE_QUESTION_ANSWERED:
                if log is None:
                    print("dont want to blow up")
                    continue
                question = self.get_question_by_item_id(log.item_id)
                # print(f"question is {question}")

                if question is not None:
                    # print("our question is not none")
                    row = self.details_for_question_answered(log)
                    details_rows.append(row)
                else:
                    print("our question is none")

            if log.log_type == Log.LogType.SCORE_FINAL_FROM_CLIENT:
                score = self.check_answer(log)
                log_text = self._final_text_for_log(log)
                item_id = getattr(log, "item_id", 0)

                older_qset = (item_id == 0 and log_text != "Blank Destination! Be sure to edit or remove this node before publishing.")
                blank_node = (item_id == 0 and log_text == "Blank Destination! Be sure to edit or remove this node before publishing.")

                details_rows.append({
                    "node_id": item_id,
                    "data": [log_text, score],
                    "data_style": ["text", "score"],
                    "score": score,
                    "type": log.log_type,
                    "style": "final_score",
                    "symbol": "%",
                    "graphic": "score",
                    "display_score": False,
                    "older_qset": older_qset,
                    "blank_node": blank_node,
                })

                # print(f"[DETAILS] built {len(details_rows)} rows")
                # print(f"[OVERVIEW] table rows = {len(self.get_overview_items())} (should be 2)")

        headers = self._ss_table_headers

        return [
            {
                "title": self._ss_table_title,
                "headers": headers, # usually we go by headers in base score module
                "header": headers, # adventure goes by headers for some reason?? legacy compatibility, harmless
                "table": details_rows,
            }
        ]

    def get_question_by_item_id(self, item_id):
        if item_id is None:
            return None
        target = str(item_id)
        for node in self._iter_nodes(self._items_list()):
            opts = node.get("options") or {}
            cand_ids = [opts.get("id"), node.get("id")]  # v1 vs v2
            if any(str(cid) == target for cid in cand_ids if cid is not None):
                return node
        return None










