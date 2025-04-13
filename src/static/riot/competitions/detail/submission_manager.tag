<submission-manager class="submission-manager">
    <div if="{ opts.admin }" class="admin-buttons">
        <div class="ui dropdown button" ref="rerun_button">
            <i class="icon redo"></i>
            <div class="text">重新运行所有阶段的提交</div>
            <div class="menu">
                <div class="header">选择一个阶段</div>
                <div class="parent-modal item" each="{phase in opts.competition.phases}"
                    onclick="{rerun_phase.bind(this, phase)}">
                    { phase.name }
                </div>
            </div>
        </div>
        <a class="ui button" href="{csv_link}">
            <i class="icon download"></i>下载为 CSV
        </a>

        <select class=" ui dropdown floated right " ref="submission_handling_operation">
            <option value="delete"> 删除选中的提交</option>
            <option value="download">下载选中的提交</option>
            <option value="rerun">重新运行选中的提交</option>
        </select>
        <button type="button" class="ui button right" disabled="{checked_submissions.length === 0}"
            onclick="{submission_handling.bind(this)}">
            应用
        </button>
    </div>
    <div class="ui icon input">
        <input type="text" placeholder="搜索..." ref="search" onkeyup="{ filter }">
        <i class="search icon"></i>
    </div>
    <select if="{opts.admin}" class="ui dropdown" ref="phase" onchange="{ filter }">
        <option value="">阶段</option>
        <option value=" ">-----</option>
        <option each="{ phase in opts.competition.phases }" value="{ phase.id }">{ phase.name }</option>
    </select>
    <select class="ui dropdown" ref="status" onchange="{ filter }">
        <option value="">状态</option>
        <option value=" ">-----</option>
        <option value="Cancelled">已取消</option>
        <option value="Failed">失败</option>
        <option value="Finished">完成</option>
        <option value="Preparing">准备中</option>
        <option value="Running">运行中</option>
        <option value="Scoring">评分中</option>
        <option value="Submitted">已提交</option>
        <option value="Submitting">提交中</option>
    </select>
    <table class="ui celled selectable sortable table" ref="submission_table">
        <thead>
            <tr>
                <th if="{opts.admin}">
                    <div class="ui checkbox" onclick="{select_all_pressed.bind(this)}">
                        <input type="checkbox" name="select_all">
                        <label>全选</label>
                    </div>
                </th>
                <th class="sorted descending collapsing">ID #</th>
                <th>文件名</th>
                <th>提交人</th>
                <th if="{ opts.admin }">阶段</th>
                <th>日期</th>
                <th>状态</th>
                <th>分数</th>
                <th
                    if="{ opts.competition.enable_detailed_results && opts.competition.show_detailed_results_in_submission_panel}">
                    详细结果</th>
                <th class="center aligned {admin-action-column: opts.admin, action-column: !opts.admin}">操作</th>
            </tr>
        </thead>
        <tbody>
            <tr if="{ _.isEmpty(submissions) && !loading }" class="center aligned">
                <td colspan="100%"><em>未找到提交！请进行提交</em></td>
            </tr>
            <tr if="{loading}" class="center aligned">
                <td colspan="100%">
                    <em>加载提交中...</em>
                </td>
            </tr>
            <tr show="{!loading}" each="{ submission, index in filter_children(submissions) }"
                onclick="{ submission_clicked.bind(this, submission) }" class="submission_row">
                <td if="{opts.admin}">
                    <div class="ui checkbox" onclick="{on_submission_checked.bind(this)}">
                        <input type="checkbox" name="{submission.id}">
                        <label></label>
                    </div>
                </td>
                <td>{ submission.id }</td>
                <td>{ submission.filename }</td>
                <td>{ submission.owner }</td>
                <td if="{ opts.admin }">{ submission.phase.name }</td>
                <td>{ pretty_date(submission.created_when) }</td>
                <td class="right aligned collapsing">
                    { submission.status }
                    <sup data-tooltip="{submission.status_details}">
                        <i if="{submission.status === 'Failed'}" class="failed question circle icon"></i>
                    </sup>
                    <sup data-tooltip="队伍者将很快运行您的提交">
                        <i if="{submission.status === 'Submitting' && !submission.auto_run}"
                            class="question circle icon"></i>
                    </sup>
                </td>
                <td>{get_score(submission)}</td>
                <td
                    if="{ opts.competition.enable_detailed_results && opts.competition.show_detailed_results_in_submission_panel }">
                    <a if="{submission.status === 'Finished'}" href="detailed_results/{submission.id}" target="_blank"
                        class="eye-icon-link">
                        <i class="icon grey eye eye-icon"></i>
                    </a>
                </td>
                <td class="center aligned">
                    <virtual if="{ opts.admin }">
                        <!-- 运行/重新运行提交 -->
                        <!-- 运行: 状态 = 提交中 auto_run = false  -->
                        <!-- 重新运行: 否则 -->
                        <span
                            data-tooltip="{ submission.status === 'Submitting' && !submission.auto_run ? '运行提交' : '重新运行提交' }"
                            data-inverted=""
                            onclick="{ submission.status === 'Submitting' && !submission.auto_run ? run_submission.bind(this, submission) : rerun_submission.bind(this, submission) }">
                            <i
                                class="icon { submission.status === 'Submitting' && !submission.auto_run ? 'green play' : 'blue redo' }"></i>
                        </span>
                        <!-- 删除提交 -->
                        <span data-tooltip="删除提交" data-inverted=""
                            onclick="{ delete_submission.bind(this, submission) }">
                            <i class="icon red trash alternate"></i>
                        </span>
                    </virtual>
                    <!-- 取消提交 -->
                    <span if="{!_.includes(['Finished', 'Cancelled', 'Unknown', 'Failed'], submission.status)}"
                        data-tooltip="取消提交" data-inverted=""
                        onclick="{ cancel_submission.bind(this, submission) }">
                        <i class="grey minus circle icon"></i>
                    </span>
                    <!-- 将提交发送到排行榜 -->
                    <span if="{!submission.on_leaderboard && submission.status === 'Finished'}"
                        data-tooltip="添加到排行榜" data-inverted=""
                        onclick="{ add_to_leaderboard.bind(this, submission) }">
                        <i class="icon green columns"></i>
                    </span>
                    <!-- 在排行榜上 -->
                    <span if="{ submission.on_leaderboard }" data-tooltip="在排行榜上" data-inverted=""
                        onclick="{ remove_from_leaderboard.bind(this, submission) }">
                        <i class="icon green check"></i>
                    </span>
                    <!-- 公开 -->
                    <span
                        if="{!submission.is_public && submission.status === 'Finished' && submission.can_make_submissions_public}"
                        data-tooltip="公开" data-inverted=""
                        onclick="{toggle_submission_is_public.bind(this, submission)}">
                        <i class="icon share teal alternate"></i>
                    </span>
                    <!-- 私有 -->
                    <span
                        if="{!!submission.is_public && submission.status === 'Finished' && submission.can_make_submissions_public}"
                        data-tooltip="私有" data-inverted=""
                        onclick="{toggle_submission_is_public.bind(this, submission)}">
                        <i class="icon share grey alternate"></i>
                    </span>
                </td>
            </tr>
        </tbody>
    </table>

    <div class="ui large modal" ref="modal">
        <div class="content">
            <div if="{!!selected_submission && !_.get(selected_submission, 'has_children', false)}">
                <submission-modal hide_output="{selected_phase.hide_output}"
                    show_visualization="{opts.competition.enable_detailed_results}"
                    submission="{selected_submission}"></submission-modal>
            </div>
            <div if="{!!selected_submission && _.get(selected_submission, 'has_children', false)}">
                <div class="ui large green pointing menu">
                    <div each="{child, i in _.get(selected_submission, 'children')}" class="parent-modal item"
                        data-tab="{admin_: is_admin()}child_{i}">
                        任务 {i + 1}
                    </div>

                    <div if="{is_admin()}" data-tab="admin" class="parent-modal item">管理员</div>

                    <!-- 有时提交会处于没有子项的错误状态..  -->
                    <div class="item" if="{_.get(selected_submission, 'children').length === 0}">
                        <i style="padding: 5px;">错误：提交是父项，但没有子项。创建过程中发生错误。</i>
                    </div>
                </div>

                <div each="{child, i in _.get(selected_submission, 'children')}" class="ui tab"
                    data-tab="{admin_: is_admin()}child_{i}">
                    <submission-modal hide_output="{selected_phase.hide_output}"
                        show_visualization="{opts.competition.enable_detailed_results}"
                        submission="{child}"></submission-modal>
                </div>
                <div class="ui tab" style="height: 565px; overflow: auto;" data-tab="admin" if="{is_admin()}">
                    <submission-scores leaderboards="{leaderboards}"></submission-scores>
                </div>
            </div>
        </div>
    </div>

    <script>
        var self = this

        self.selected_phase = undefined
        self.selected_submission = undefined
        self.hide_output = false
        self.leaderboards = {}
        self.loading = true
        self.checked_submissions = []

        self.on("mount", function () {
            $(self.refs.search).dropdown()
            $(self.refs.status).dropdown()
            $(self.refs.phase).dropdown()
            $(self.refs.rerun_button).dropdown()
            $(self.refs.submission_handling_operation).dropdown()
            $(self.refs.submission_table).tablesort()
        })

        self.pretty_date = function (date_string) {
            if (!!date_string) {
                return luxon.DateTime.fromISO(date_string).toFormat('yyyy-MM-dd HH:mm')
            } else {
                return ''
            }
        }

        self.is_admin = () => {
            return _.get(self.selected_submission, 'admin', false)
        }

        self.do_nothing = event => {
            event.stopPropagation()
        }

        self.filter_children = submissions => {
            return _.filter(submissions, sub => !sub.parent)
        }

        self.update_submissions = function (filters) {
            self.loading = true
            self.update()
            if (opts.admin) {
                filters = filters || { phase__competition: opts.competition.id }
            } else {
                filters = filters || { phase: self.selected_phase.id }
            }
            filters = filters || { phase: self.selected_phase.id }
            CODALAB.api.get_submissions(filters)
                .done(function (submissions) {
                    // TODO: 应该能够通过序列化器来完成这个
                    if (opts.admin) {
                        self.submissions = submissions.map((item) => {
                            item.phase = opts.competition.phases.filter((phase) => {
                                return phase.id === item.phase
                            })[0]
                            return item
                        })
                    } else {
                        // No filtering needed - the backend now returns all submissions from the user's organization
                        self.submissions = submissions.map((item) => {
                            item.phase = opts.competition.phases.filter((phase) => {
                                return phase.id === item.phase
                            })[0]
                            return item
                        })
                    }
                    if (!opts.admin) {
                        CODALAB.events.trigger('submissions_loaded', self.submissions)
                    }
                    self.csv_link = CODALAB.api.get_submission_csv_URL(filters)
                    self.update()
                    self.submission_checked()

                    // 这里的超时是为了防止加载器闪烁
                    _.delay(() => {
                        self.loading = false
                        self.update()
                    }, 300)
                })
                .fail(function (response) {
                    toastr.error("获取提交时出错")
                })
        }

        self.add_to_leaderboard = function (submission) {
            CODALAB.api.add_submission_to_leaderboard(submission.id)
                .done(function (data) {
                    self.update_submissions()
                    CODALAB.events.trigger('submission_changed_on_leaderboard')
                })
                .fail(function (response) {
                    toastr.error(response.responseJSON.detail)
                })
            event.stopPropagation()
        }
        self.remove_from_leaderboard = function (submission) {
            CODALAB.api.remove_submission_from_leaderboard(submission.id)
                .done(function (data) {
                    self.update_submissions()
                    CODALAB.events.trigger('submission_changed_on_leaderboard')
                })
                .fail(function (response) {
                    toastr.error(response.responseJSON.detail)
                })
            event.stopPropagation()
        }
        self.rerun_phase = function (phase) {
            if (confirm("您确定吗？这可能需要几个小时.. 您正在重新运行一个阶段的所有提交。")) {
                CODALAB.api.re_run_phase_submissions(phase.id)
                    .done(function (response) {
                        toastr.success(`正在重新运行 ${response.count} 个提交`)
                        self.update_submissions()
                    })
                    .fail(function (response) {
                        toastr.error(response.responseJSON.detail)
                    })
            }
        }
        self.filter = function () {
            delay(() => {
                var filters = {}
                var search = self.refs.search.value
                if (search) {
                    filters['search'] = search
                }
                var status = self.refs.status.value
                if (status !== ' ') {
                    filters['status'] = status
                }
                if (!opts.admin) {
                    filters['phase'] = self.selected_phase.id
                } else {
                    var phase = self.refs.phase.value
                    if (phase && phase !== ' ') {
                        filters['phase'] = phase
                    } else {
                        filters['phase__competition'] = opts.competition.id
                    }
                }
                self.update_submissions(filters)
            }, 100)
        }

        self.run_submission = function (submission) {
            CODALAB.api.run_submission(submission.id)
                .done(function (response) {
                    toastr.success('提交已排队')
                    self.update_submissions()
                })
                .fail(function (response) {
                    if (response.responseJSON.detail) {
                        toastr.error(response.responseJSON.detail)
                    } else {
                        toastr.error(response.responseText)
                    }
                })
            event.stopPropagation()

        }

        self.rerun_submission = function (submission) {
            CODALAB.api.re_run_submission(submission.id)
                .done(function (response) {
                    toastr.success('提交已排队')
                    self.update_submissions()
                })
                .fail(function (response) {
                    if (response.responseJSON.detail) {
                        toastr.error(response.responseJSON.detail)
                    }
                    else if (response.responseJSON.error_msg) {
                        toastr.error(response.responseJSON.error_msg)
                    }
                    else {
                        toastr.error(response.responseText)
                    }
                })
            event.stopPropagation()
        }

        self.rerun_selected_submissions = function () {
            CODALAB.api.re_run_many_submissions(self.checked_submissions)
                .done(function (response) {
                    toastr.success('提交已排队')
                    self.update_submissions()
                })
        }

        self.cancel_submission = function (submission) {
            CODALAB.api.cancel_submission(submission.id)
                .done(function (response) {
                    if (response.canceled === true) {
                        toastr.success('提交已取消')
                        self.update_submissions()
                    } else {
                        toastr.error('无法取消提交')
                    }
                })
            event.stopPropagation()
        }

        self.delete_submission = function (submission) {
            if (confirm(`您确定要删除提交: ${submission.filename} 吗？`)) {
                CODALAB.api.delete_submission(submission.id)
                    .done(function (response) {
                        toastr.success('提交已删除')
                        self.update_submissions()
                    })
            }
            event.stopPropagation()
        }

        self.delete_selected_submissions = function () {
            if (confirm(`您确定要删除选中的提交吗？`)) {
                CODALAB.api.delete_many_submissions(self.checked_submissions)
                    .done(function (response) {
                        toastr.success('提交已删除')
                        self.update_submissions()
                    })
                    .fail(function (response) {
                        toastr.error('发生错误')
                    })
            }
        }

        self.get_score_details = function (submission, column) {
            try {
                let score = _.filter(submission.scores, (score) => {
                    return score.column_key === column.key
                })[0]
                return [score.score, score.id]
            } catch {
                return ['', '']
            }
        }

        self.get_score = function (submission) {
            try {
                return parseFloat(submission.scores[0].score).toFixed(2)

            } catch {
                return ""
            }
        }

        self.toggle_submission_is_public = function (submission) {
            event.stopPropagation()
            let message = submission.is_public
                ? '您确定要将此提交设为私有吗？它将不再对其他用户可见。'
                : '您确定要将此提交设为公开吗？它将对所有人可见'
            if (confirm(message)) {
                CODALAB.api.toggle_submission_is_public(submission.id)
                    .done(data => {
                        toastr.success('提交已更新')
                        self.update_submissions()
                    })
                    .fail(resp => {
                        toastr.error(resp.responseJSON.detail)
                    })
            }
        }

        self.on_submission_checked = function (event) {
            event.stopPropagation()
            self.submission_checked()
        }

        self.submission_checked = function () {
            let inputs = $(self.refs.submission_table).find('input')
            let checked_boxes = inputs.not(':first').filter('input:checked')
            let unchecked_boxes = inputs.not(':first').filter('input:not(:checked)')
            inputs.first().prop('checked', unchecked_boxes.length === 0)
            self.checked_submissions = checked_boxes.serializeArray().map((x) => { return x.name })
        }

        self.select_all_pressed = function () {
            let check_boxes = $(self.refs.submission_table).find('input')
            // 将复选框设置为与全选复选框相等
            check_boxes.prop('checked', check_boxes.first().is(':checked'))


            let inputs = $(self.refs.submission_table).find('input')
            let checked_boxes = inputs.not(':first').filter('input:checked')
            self.checked_submissions = checked_boxes.serializeArray().map((x) => { return x.name })
        }

        self.submission_clicked = function (submission) {
            // 愚蠢的解决方法，不修改原始提交对象
            submission = _.defaultsDeep({}, submission)
            if (submission.has_children) {
                submission.children = _.map(_.sortBy(submission.children), child => {
                    return { id: child }
                })
                CODALAB.api.get_submission_details(submission.id)
                    .done(function (data) {
                        self.leaderboards = data.leaderboards
                        _.forEach(self.leaderboards, (leaderboard) => {
                            _.map(leaderboard.columns, column => {
                                let [score, score_id] = self.get_score_details(submission, column)
                                column.score = score
                                column.score_id = score_id
                                return column
                            })
                        })
                        self.update()
                    })
            }
            if (opts.admin) {
                submission.admin = true
            }
            self.selected_submission = submission
            self.update()
            $(self.refs.modal)
                .modal({
                    onShow: () => {
                        if (_.get(self.selected_submission, 'has_children', false)) {
                            // 仅在存在子项时尝试制表父模态
                            let path = self.is_admin() ? 'admin_child_0' : 'child_0'
                            $('.menu .parent-modal.item')
                                .tab('change tab', path)
                        }
                    }
                })
                .modal('show')
            CODALAB.events.trigger('submission_clicked')
        }

        self.bulk_download = function () {
            CODALAB.api.download_many_submissions(self.checked_submissions)
            .catch(function (error) {
                console.error('错误:', error);
            });
        }

        self.submission_handling = function () {
            // console.log(self.checked_submissions)
            if (self.checked_submissions.length === 0) {
                console.log("没有选择任何提交");
            } else {
                var submission_operation = self.refs.submission_handling_operation.value
                switch (submission_operation) {
                    case "delete":
                        // console.log("删除")
                        self.delete_selected_submissions()
                        break;
                    case "download":
                        // console.log("下载")
                        self.bulk_download()
                        break;
                    case "rerun":
                        // console.log("重新运行")
                        self.rerun_selected_submissions()
                        break
                    default:
                        console.log("不应该处于这个默认状态..")
                }
            }
        }

        CODALAB.events.on('phase_selected', function (selected_phase) {
            self.selected_phase = selected_phase
            self.selected_phase.hide_output = selected_phase.hide_output && !CODALAB.state.user.has_competition_admin_privileges(self.opts.competition)
            self.update_submissions()
        })

        CODALAB.events.on('new_submission_created', function (new_submission_data) {
            self.submissions.unshift(new_submission_data)
            self.update()
        })

        CODALAB.events.on('score_updated', () => {
            $(self.refs.modal).modal('hide')
            self.update_submissions()
        })

        CODALAB.events.on('submission_status_update', data => {
            let sub = _.find(self.submissions, submission => submission.id === data.submission_id)
            if (sub) {
                sub.status = data.status
            }
            self.update()
        })
    </script>

    <style type="text/stylus">
        :scope
            display block
            margin 2em 0
            min-height 90vh

        .admin-buttons
            padding-bottom 20px

        .on-leaderboard
            &:hover
                cursor auto
                background-color #21ba45 !important

        .admin-action-column
            width 200px

        .action-column
            width 100px

        .submission_row
            &:hover
                cursor pointer
            height 52px

        table tbody .center.aligned td
            color #8c8c8c

        .failed.question.circle.icon
            color #2c3f4c
    </style>
</submission-manager>
