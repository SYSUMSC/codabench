<submission-modal>
    <div class="ui large green pointing menu">
        <div class="active submission-modal item" data-tab="{admin_: submission.admin}downloads">下载</div>
        <div class="submission-modal item" data-tab="{admin_: submission.admin}logs" show="{!opts.hide_output}">日志</div>
        <div class="submission-modal item" data-tab="{admin_: submission.admin}graph" show="{!opts.hide_output && opts.show_visualization}">可视化</div>
        <div class="submission-modal item" data-tab="admin" if="{submission.admin}">管理员</div>
        <div class="submission-modal item" data-tab="{admin_: submission.admin}fact_sheet">事实表答案</div>
    </div>
    <div class="ui tab active modal-tab" data-tab="{admin_: submission.admin}downloads">
        <div class="ui relaxed centered grid">
            <div class="ui fifteen wide column">
                <table class="ui table" id="downloads">
                    <thead>
                        <tr>
                            <th><i class="download icon"></i> 文件</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td class="selectable file-download">
                                <a href="{ data_file }"><i class="file archive outline icon"></i> 提交文件</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="selectable file-download {disabled: !prediction_result}">
                                <a href="{ prediction_result }"><i class="file outline icon"></i>预测步骤的输出</a>
                            </td>
                        </tr>
                        <tr>
                            <td class="selectable file-download {disabled: !scoring_result}">
                                <a href="{ scoring_result }"><i class="file outline icon"></i>评分步骤的输出</a>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    <div class="ui tab modal-tab" data-tab="{admin_: submission.admin}logs" hide="{opts.hide_output}">
        <div class="ui grid">
            <div class="three wide column">
                <div class="ui fluid vertical secondary menu">
                    <div class="active submission-modal item" data-tab="{admin_: submission.admin}prediction">
                        预测日志
                    </div>
                    <div class="submission-modal item" data-tab="{admin_: submission.admin}scoring">
                        评分日志
                    </div>
                </div>
            </div>
            <div class="thirteen wide column">
                <div class="ui active tab" data-tab="{admin_: submission.admin}prediction">
                    <div class="ui top attached inverted pointing menu">
                        <div class="active submission-modal item" data-tab="{admin_: submission.admin}p_stdout">
                            stdout
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}p_stderr">
                            stderr
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}p_ingest_stdout">
                            采集 stdout
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}p_ingest_stderr">
                            采集 stderr
                        </div>
                    </div>

                    <div class="ui active bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}p_stdout">
                        <pre>{ logs.prediction_stdout }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}p_stderr">
                        <pre>{ logs.prediction_stderr }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}p_ingest_stdout">
                        <pre>{ logs.prediction_ingestion_stdout }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}p_ingest_stderr">
                        <pre>{ logs.prediction_ingestion_stderr }</pre>
                    </div>
                </div>
                <div class="ui tab" data-tab="{admin_: submission.admin}scoring">
                    <div class="ui top attached inverted pointing menu">
                        <div class="active submission-modal item" data-tab="{admin_: submission.admin}s_stdout">
                            stdout
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}s_stderr">
                            stderr
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}s_ingest_stdout">
                            采集 stdout
                        </div>
                        <div class="submission-modal item" data-tab="{admin_: submission.admin}s_ingest_stderr">
                            采集 stderr
                        </div>
                    </div>

                    <div class="ui active bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}s_stdout">
                        <pre>{ logs.scoring_stdout }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}s_stderr">
                        <pre>{ logs.scoring_stderr }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}s_ingest_stdout">
                        <pre>{ logs.scoring_ingestion_stdout }</pre>
                    </div>

                    <div class="ui bottom attached inverted segment tab log"
                         data-tab="{admin_: submission.admin}s_ingest_stderr">
                        <pre>{ logs.scoring_ingestion_stderr }</pre>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="ui tab modal-tab" data-tab="{admin_: submission.admin}fact_sheet">
        <div class="ui inverted segment log">
            <textarea name="fact-sheet" id="fact_sheet" ref="fact_sheet_text_area">{ JSON.stringify(fact_sheet_answers, null, 2) }</textarea>
        </div>
        <div class="ui button green" onclick="{update_fact_sheet.bind(this)}">保存</div>
    </div>
    <div class="ui tab modal-tab" data-tab="{admin_: submission.admin}graph" show="{opts.show_visualization && (!opts.hide_output || submission.admin)}">
        <iframe src="{detailed_result}" class="graph-frame" show="{detailed_result}"></iframe>
    </div>
    <div class="ui tab leaderboard-tab" data-tab="admin" if="{submission.admin}">
        <submission-scores leaderboards="{leaderboards}"></submission-scores>
    </div>
    <script>
        var self = this
        self.submission = {}
        self.logs = {}
        self.leaderboards = []
        self.columns = []

        self.get_score_details = function (column) {
            try {
                let score = _.filter(self.submission.scores, (score) => {
                    return score.column_key === column.key
                })[0]
                return [score.score, score.id]
            } catch {
                return ['', '']
            }
        }
        self.update_submission_details = () => {
            CODALAB.api.get_submission_details(self.submission.id)
                .done(function (data) {
                    self.leaderboards = data.leaderboards
                    self.prediction_result = data.prediction_result
                    self.scoring_result = data.scoring_result
                    self.data_file = data.data_file
                    self.detailed_result = data.detailed_result
                    self.fact_sheet_answers = data.fact_sheet_answers

                    _.forEach(data.logs, (item) => {
                        $.get(item.data_file)
                            .done(function (content) {
                                self.logs[item.name] = content
                                self.update()
                            })
                    })
                    if (self.submission.admin) {
                        _.forEach(data.leaderboards, (leaderboard) => {
                            _.map(leaderboard.columns, (column) => {
                                let [score, score_id] = self.get_score_details(column)
                                column.score = score
                                column.score_id = score_id
                                return column
                            })
                        })
                    }
                    self.update()
                })
        }

        self.update_fact_sheet = () => {
            let fact_sheet = self.refs.fact_sheet_text_area.value
            try {
                fact_sheet = JSON.parse(fact_sheet)
            }
            catch (err) {
                toastr.error("无效的 JSON")
                return false
            }
            self.fact_sheet_answers = fact_sheet
            CODALAB.api.update_submission_fact_sheet(self.submission.id, self.fact_sheet_answers)
                .done((data) => {
                    toastr.success('事实表答案已更新')
                    setTimeout(function () {
                        location.reload()
                    }, 1000)
                })
                .fail((response) => {
                    toastr.error(response.responseText)
                })
        }

        CODALAB.events.on('submission_clicked', () => {
            self.submission = opts.submission
            self.update()
            self.update_submission_details()
            let path = self.submission.admin ? 'admin_downloads' : 'downloads'
            $('.menu .submission-modal.item').tab('change tab', path)
        })
    </script>

    <style type="text/stylus">
        .log
            height 465px
            max-height 465px
            overflow auto

        .leaderboard-tab
            height 515px
            overflow auto

        .modal-tab
            height 530px

        .file-download
            margin-top 25px !important
            margin-botton 25px !important

        .graph-frame
            height 100%
            width 100%
            overflow scroll
            border none

        #downloads thead tr th, #downloads tbody tr td
            font-size 16px !important

        .inverted, textarea
            color: white
            background: #1b1c1d
            width: 100%
            height: 98%
    </style>
</submission-modal>
