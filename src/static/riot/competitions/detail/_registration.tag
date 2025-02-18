<registration>
    <!-- 如果未注册（status为假），显示以下内容 -->
    <div if="{!status}" class="ui grid">
        <div class="row">
            <div class="column">
                <p>
                    您尚未注册此项竞赛。
                </p>
                <p>
                    要参加此项竞赛，您必须接受其特定的
                    <a href="" onclick="{show_modal}">条款和条件</a>。
                    <span if="{registration_auto_approve}">此项竞赛 <strong>无需</strong> 审批，一旦注册，您将立即能够参赛。</span>
                </p>

                <p if="{!registration_auto_approve}">
                    此项竞赛 <strong>需要</strong> 竞赛组织者的审批。提交注册申请后，将向竞赛组织者发送一封电子邮件，通知他们您的申请。在他们批准或拒绝之前，您的申请将一直处于待处理状态。
                </p>
            </div>
        </div>
        <!-- 如果用户已登录（CODALAB.state.user.logged_in为真），显示以下内容 -->
        <virtual if="{CODALAB.state.user.logged_in}">
            <div class="row">
                <div class="ui checkbox">
                    <input type="checkbox" id="accept-terms" onclick="{accept_toggle}">
                    <label for="accept-terms">我接受竞赛的条款和条件。</label>
                </div>
            </div>
            <div class="row">
                <button class="ui primary button {disabled:!accepted}" onclick="{submit_registration}">
                    注册
                </button>
            </div>
        </virtual>
        <!-- 如果用户未登录（CODALAB.state.user.logged_in为假），显示以下内容 -->
        <div class="row" if="{!CODALAB.state.user.logged_in}">
            <div class="column">
                <a href="{URLS.LOGIN}?next={location.pathname}">登录</a> 或
                <a href="{URLS.SIGNUP}" target="_blank">注册</a> 以报名参加此项竞赛。
            </div>
        </div>
    </div>

    <!-- 如果已注册（status为真），显示以下内容 -->
    <div if="{status}">
        <!-- 如果注册状态为“pending”（待处理），显示以下内容 -->
        <div if="{status === 'pending'}" class="ui yellow message">
            <h3>注册状态：{_.startCase(status)}</h3>
            您参加此项竞赛的申请正在等待竞赛组织者的审批。
        </div>
        <!-- 如果注册状态为“denied”（被拒绝），显示以下内容 -->
        <div if="{status === 'denied'}" class="ui red message">
            <h3>注册状态：{_.startCase(status)}</h3>
            您参加此项竞赛的申请被拒绝。请联系竞赛组织者了解更多详情。
        </div>
    </div>

    <!-- 条款和条件模态框 -->
    <div ref="terms_modal" class="ui modal">
        <div class="header">
            条款和条件
        </div>
        <div ref="terms_content" class="content">

        </div>
        <div class="actions">
            <div class="ui cancel button">
                关闭
            </div>
        </div>
    </div>

    <script>
        // 将this赋值给self
        let self = this
        // 组件挂载时执行以下函数
        self.on('mount', () => {
            self.accepted = false
        })

        // 当“competition_loaded”事件触发时执行以下函数
        CODALAB.events.on('competition_loaded', (competition) => {
            self.competition_id = competition.id
            if (self.refs.terms_content) {
                // 使用renderMarkdownWithLatex函数渲染竞赛条款
                const rendered_content = renderMarkdownWithLatex(competition.terms)
                self.refs.terms_content.innerHTML = ""
                // 将渲染后的每个节点克隆并追加到terms_content中
                rendered_content.forEach(node => {
                    self.refs.terms_content.appendChild(node.cloneNode(true));
                });
            }
            self.registration_auto_approve = competition.registration_auto_approve
            self.status = competition.participant_status
            self.update()
        })

        // 切换接受条款的状态
        self.accept_toggle = () => {
            self.accepted =!self.accepted
        }

        // 显示条款和条件模态框
        self.show_modal = (e) => {
            if (e) {
                e.preventDefault()
            }
            $(self.refs.terms_modal).modal('show')
        }

        // 提交注册申请
        self.submit_registration = () => {

            // 从URL中获取“secret_key”参数的值
            const url = new URL(window.location.href)
            const searchParams = new URLSearchParams(url.search)
            const secretKey = searchParams.get('secret_key')

            // 调用CODALAB.api.submit_competition_registration方法提交注册申请
            CODALAB.api.submit_competition_registration(self.competition_id, secretKey)
               .done(response => {
                    self.status = response.participant_status
                    if (self.status === 'approved') {
                        // 注册成功提示
                        toastr.success('您已成功注册！')
                        // 获取竞赛信息
                        CODALAB.api.get_competition(self.competition_id)
                           .done(competition => {
                                // 触发“competition_loaded”事件
                                CODALAB.events.trigger('competition_loaded', competition)
                            })
                    } else {
                        // 注册申请正在处理提示
                        toastr.success('您的注册申请正在处理中！')
                    }
                    self.update()
                })
               .fail(response => {
                    // 注册申请失败提示
                    toastr.error('提交注册申请时出错。')
                })
        }
    </script>
</registration>