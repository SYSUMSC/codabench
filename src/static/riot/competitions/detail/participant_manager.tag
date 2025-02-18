<participant-manager>
    <div show="{participants}">
        <div class="ui icon input">
            <input type="text" placeholder="搜索..." ref="participant_search" onkeyup="{ search_participants }">
            <i class="search icon"></i>
        </div>
        <select ref="participant_status" class="ui dropdown" onchange="{ update_participants.bind(this, undefined) }">
            <option value="">状态</option>
            <option value="-">----</option>
            <option value="approved">已批准</option>
            <option value="pending">待处理</option>
            <option value="denied">已拒绝</option>
            <option value="unknown">未知</option>
        </select>
        <div class="ui checkbox">
            <input type="checkbox" ref="participant_show_deleted" onchange="{ update_participants.bind(this, undefined) }">
            <label>显示已删除账户</label>
        </div>
        <div class="ui blue icon button" onclick="{show_email_modal.bind(this, undefined)}"><i class="envelope icon"></i> 向所有参与者发送邮件</div>
        <table class="ui celled striped table">
            <thead>
            <tr>
                <th>用户名</th>
                <th>邮箱</th>
                <th>是机器人吗？</th>
                <th>状态</th>
                <th class="center aligned">操作</th>
            </tr>
            </thead>
            <tbody>
            <tr each="{participants}">
                <td><a href="/profiles/user/{username}" target="_BLANK">{username}</a></td>
                <td>{email}</td>
                <td>{is_bot}</td>
                <td>{is_deleted ? "账户已删除" : _.startCase(status)}</td>
                <td class="right aligned">
                    <button class="mini ui red button icon"
                            show="{status !== 'denied'}"
                            onclick="{ revoke_permission.bind(this, id) }"
                            data-tooltip="撤销"
                            data-inverted=""
                            data-position="bottom center"
                            disabled="{is_deleted}">
                        <i class="close icon"></i>
                    </button>
                    <button class="mini ui green button icon"
                            show="{status !== 'approved'}"
                            onclick="{ approve_permission.bind(this, id) }"
                            data-tooltip="批准"
                            data-inverted=""
                            data-position="bottom center"
                            disabled="{is_deleted}"
                            >
                            <i class="checkmark icon"></i>
                    </button>
                    <button class="mini ui blue button icon"
                            data-tooltip="发送消息"
                            data-inverted=""
                            data-position="bottom center"
                            onclick="{show_email_modal.bind(this, id)}"
                            disabled="{is_deleted}"
                            >
                        <i class="envelope icon"></i>
                    </button>
                </td>
            </tr>
            </tbody>
        </table>
    </div>

    <div class="ui modal" ref="email_modal">
        <div class="header">
            发送邮件
        </div>
        <div class="content">
            <div class="ui form">
                <div class="field">
                    <label>主题</label>
                    <input type="text" value="来自{competition_title}管理员的消息" disabled>
                </div>
                <div class="field">
                    <label>内容</label>
                    <textarea class="markdown-editor" ref="email_content" name="content"></textarea>
                </div>
            </div>
        </div>
        <div class="actions">
            <div class="ui cancel icon red small button"><i class="trash alternate icon"></i></div>
            <div class="ui icon small button" onclick="{send_email}"><i class="paper plane icon"></i></div>
        </div>
    </div>

    <script>
        let self = this
        self.competition_id = undefined
        self.selected_participant = undefined
        self.competition_title = undefined

        self.on('mount', () => {
            $(self.refs.participant_status).dropdown()
            self.markdown_editor = create_easyMDE(self.refs.email_content)
            $(self.refs.email_modal).modal({
                onHidden: self.clear_form,
                onShow: () => {
                    _.delay(() => {self.markdown_editor.codemirror.refresh()}, 5)
                }
            })
        })

        self.clear_form = function () {
            self.markdown_editor.value('')
            self.update()
        }

        CODALAB.events.on('competition_loaded', function(competition) {
            self.competition_title = competition.title
            self.competition_id = competition.id
            self.update_participants()
        })

        self.send_email = function () {
            let content = render_markdown(self.refs.email_content.value)
            let func = self.selected_participant
                ? _.partial(CODALAB.api.email_participant, self.selected_participant)
                : _.partial(CODALAB.api.email_all_participants, self.competition_id)
            func(content)
                .done(() => {
                    toastr.success('发送成功')
                    self.close_email_modal()
                })
                .fail((resp) => {
                    toastr.error('发送邮件时出错')
                })
        }

        self.update_participants = filters => {
            if (!CODALAB.state.user.logged_in) {
                return
            }
            filters = filters || {}
            filters.competition = self.competition_id
            let status = self.refs.participant_status.value
            if (status && status !== '-') {
                filters.status = status
            }

            let show_deleted_users = self.refs.participant_show_deleted.checked
            if (show_deleted_users !== null && show_deleted_users === false) {
                filters.user__is_deleted = show_deleted_users
            }

            CODALAB.api.get_participants(filters)
                .done(participants => {
                    self.participants = participants
                    self.update()
                })
                .fail(() => {
                    toastr.error('返回比赛参与者时出错')
                })
        }

        self._update_status = (id, status) => {
            CODALAB.api.update_participant_status(id, {status: status})
                .done(() => {
                    if(status === 'denied'){
                        toastr.success('撤销成功')
                    }else{
                        toastr.success('批准成功')
                    }
                    self.update_participants()
                })
        }

        self.revoke_permission = id => {
            if (confirm("您确定要撤销该用户的权限吗？")) {
                self._update_status(id, 'denied')
            }
        }

        self.approve_permission = id => {
            self._update_status(id, 'approved')
        }

        self.search_participants = () => {
            let filter = self.refs.participant_search.value
            delay(() => self.update_participants({search: filter}), 100)
        }

        self.show_email_modal = (participant_pk) => {
            self.selected_participant = participant_pk
            $(self.refs.email_modal).modal('show')
        }

        self.close_email_modal = () => {
            $(self.refs.email_modal).modal('hide')
        }

    </script>
</participant-manager>
