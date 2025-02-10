<competition-participation>
    <form class="ui form">
        <div class="field required">
            <label>条款</label>
            <textarea class="markdown-editor" ref="terms" name="terms"></textarea>
        </div>
         <div class="field">
            <div class="ui checkbox">
                <input selenium="auto-approve" type="checkbox" name="registration_auto_approve" ref="registration_auto_approve" onchange="{form_updated}">
                <label>自动批准注册请求
                    <span data-tooltip="如果未勾选，则注册请求必须由基准创建者或协作者手动批准"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i></span>
                </label>
            </div>
        </div>
        <div class="field">
            <div class="ui checkbox">
                <input type="checkbox" name="allow_robot_submissions" ref="allow_robot_submissions" onchange="{form_updated}">
                <label>允许机器人提交
                    <span data-tooltip="如果未勾选，机器人用户必须由基准创建者或协作者手动批准。这可以在以后更改。"
                          data-inverted=""
                          data-position="bottom center">
                    <i class="help icon circle"></i></span>
                </label>
            </div>
        </div>

        <!--  白名单邮箱列表  -->
        <!--  不需要管理员批准即可参加比赛的用户邮箱  -->
        <div class="field">
            <label>白名单邮箱</label>
            <p>用户无需比赛组织者批准即可参加此比赛的邮箱列表（每行一个邮箱）。</p>
            <div class="ui yellow message">
                <span><b>注意：</b></span><br>
                仅允许有效的邮箱<br>
                不允许空行
            </div>
            <textarea class="markdown-editor" ref="whitelist_emails" name="whitelist_emails"></textarea>
            <div class="error-message" style="color: red;"></div>
        </div>
    </form>

    <script>
        let self = this

        self.data = {}

        self.on('mount', () => {
            self.markdown_editor = create_easyMDE(self.refs.terms)
            self.markdown_editor_whitelist = create_easyMDE(self.refs.whitelist_emails, false, false, '200px')

            $(':input', self.root).not('[type="file"]').not('button').not('[readonly]').each(function (i, field) {
                this.addEventListener('keyup', self.form_updated)
            })
        })

        self.form_updated = () => {
            self.data.registration_auto_approve = $(self.refs.registration_auto_approve).prop('checked')
            self.data.allow_robot_submissions = $(self.refs.allow_robot_submissions).prop('checked')
            self.data.terms = self.markdown_editor.value()

            // 获取白名单邮箱的内容，并将其分割为邮箱地址数组
            let whitelist_emails_content = self.markdown_editor_whitelist.value()
            let email_addresses = whitelist_emails_content.trim() === '' ? [] : whitelist_emails_content.split('\n').map(email => email.trim())

            // 检查存在问题的邮箱
            let problematicEmailIndexes = []
            email_addresses.forEach((email, index) => {
                if (!self.isValidEmail(email)) {
                    // 如果邮箱无效，记录其索引
                    problematicEmailIndexes.push(index);
                }
            })

            // 显示邮箱错误信息
            const errorDiv = self.root.querySelector('.error-message')
            if (problematicEmailIndexes.length > 0) {
                // 如果有无效邮箱，显示错误消息
                errorDiv.classList.add('ui', 'red', 'message')

                const errorMessage = document.createElement('strong')
                errorMessage.textContent = '一个或多个邮箱地址无效'
                errorDiv.innerHTML = '' // 清空现有内容
                errorDiv.appendChild(errorMessage)

                // 创建一个无序列表用于显示错误详情
                const errorList = document.createElement('ul')

                problematicEmailIndexes.forEach((index) => {
                    const problematicEmail = email_addresses[index]
                    // 为每个问题邮箱创建一个列表项
                    const listItem = document.createElement('li')
                    listItem.textContent = `${problematicEmail}`
                    errorList.appendChild(listItem)
                })

                // 将错误详情（无序列表）添加到 'error-message' div 中
                errorDiv.appendChild(errorList)
            } else {
                // 如果所有邮箱有效，清空错误消息并移除样式
                errorDiv.classList.remove('ui', 'red', 'message')
                errorDiv.textContent = ''
            }

            // 如果所有邮箱地址都有效，则加入 whitelist_emails
            if(problematicEmailIndexes.length == 0){
                self.data.whitelist_emails = email_addresses
            }

            // 设置布尔值，判断邮箱和条款是否有效
            let is_valid_emails = problematicEmailIndexes.length == 0
            let is_valid_terms = !!self.data.terms

            // 当邮箱和条款都有效时设置整体有效状态
            is_valid = is_valid_terms && is_valid_emails

            CODALAB.events.trigger('competition_is_valid_update', 'participation', is_valid)

            if (is_valid) {
                CODALAB.events.trigger('competition_data_update', self.data)
            }
        }

        // 验证邮箱地址的函数
        self.isValidEmail = function (email) {
            // 匹配有效邮箱地址的正则表达式
            const emailPattern = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/

            // 测试邮箱地址是否匹配正则表达式并返回结果（布尔值）
            return emailPattern.test(email)
}

        CODALAB.events.on('competition_loaded', function (competition) {
            self.refs.registration_auto_approve.checked = competition.registration_auto_approve
            self.refs.allow_robot_submissions.checked = competition.allow_robot_submissions
            self.markdown_editor.value(competition.terms || '')
            // 在文本区域设置白名单邮箱
            self.markdown_editor_whitelist.value(Array.isArray(competition.whitelist_emails) && competition.whitelist_emails.length > 0 ? competition.whitelist_emails.join('\n') : '')
            self.markdown_editor.codemirror.refresh()
            self.update()
            self.form_updated()
        })

        CODALAB.events.on('update_codemirror', () => {
            self.markdown_editor.codemirror.refresh()
        })
    </script>
</competition-participation>
